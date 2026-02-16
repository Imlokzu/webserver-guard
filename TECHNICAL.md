# Technical Documentation - WebServer Guard Module

## Architecture Overview

### Component Hierarchy

```
Magisk Boot Sequence
    ↓
post-fs-data.sh (Blocking, Early Boot)
    ├── Initialize logging
    ├── Set system properties (resetprop)
    ├── Prepare directories
    └── Free port 80
    ↓
Module System Mount
    ↓
service.sh (Non-blocking, Late Boot)
    ├── Wait for boot completion
    ├── Configure battery optimizations
    ├── Setup iptables (80 → 8080)
    ├── Start BusyBox httpd
    ├── Launch protection_daemon.sh
    ├── Launch webserver_watchdog.sh
    ├── Apply system tweaks (LMK, ZRAM)
    └── Protect Termux
    ↓
Background Services Running
    ├── httpd (web server)
    ├── protection_daemon.sh (process monitor)
    └── webserver_watchdog.sh (httpd monitor)
```

## Process Protection Engine

### How OOM Protection Works

Android uses the Out-Of-Memory (OOM) killer to free memory when system resources are low. Each process has an `oom_score_adj` value:

- **Range**: -1000 to +1000
- **-1000**: Never kill (kernel processes)
- **0**: Normal priority
- **+1000**: Kill first

#### Protection Mechanism

```bash
# Set process to maximum protection
echo -1000 > /proc/<PID>/oom_score_adj
```

This tells the kernel to never kill this process unless absolutely necessary.

### Protection Daemon Logic

```
Every 30 seconds:
    ↓
Read protected.list
    ↓
For each protected process:
    ├── Find PID(s) using pgrep
    ├── Check if /proc/<PID> exists
    ├── Read current oom_score_adj
    ├── If not -1000, set to -1000
    ├── Add to Doze whitelist (if app package)
    └── Log protection status
    ↓
Also protect Termux continuously
    ↓
Sleep 30 seconds
    ↓
Repeat
```

### Watchdog Logic

```
Every 15 seconds:
    ↓
Check if httpd is running:
    ├── Method 1: Check PID file
    ├── Method 2: Check port binding
    └── Method 3: Check process list
    ↓
If NOT running:
    ├── Kill stale httpd processes
    ├── Start new httpd instance
    ├── Save new PID
    ├── Set OOM score to -1000
    └── Log restart
    ↓
If running:
    └── Ensure OOM score is -1000
    ↓
Sleep 15 seconds
    ↓
Repeat
```

## Web Server Implementation

### Port Binding Strategy

Android restricts binding to privileged ports (< 1024) without `CAP_NET_BIND_SERVICE` capability.

#### Solution: iptables NAT

```bash
# Redirect incoming port 80 to 8080
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

# Redirect outgoing port 80 to 8080 (for localhost)
iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8080
```

#### BusyBox httpd

```bash
/data/adb/magisk/busybox httpd -p 8080 -h /path/to/webroot -f
```

Options:
- `-p 8080`: Listen on port 8080
- `-h /path/to/webroot`: Document root
- `-f`: Run in foreground (allows process monitoring)

### Network Flow

```
Client Request (port 80)
    ↓
iptables NAT (PREROUTING)
    ↓
Redirect to port 8080
    ↓
BusyBox httpd (listening on 8080)
    ↓
Serve file from webroot/
    ↓
Response to client
```

## Memory Management Tweaks

### Low Memory Killer (LMK) Tuning

```bash
# Default aggressive values (in pages, 1 page = 4KB)
# 18432,23040,27648,32256,36864,46080
# = 72MB, 90MB, 108MB, 126MB, 144MB, 180MB

# Our less aggressive values
echo "1024,2048,4096,8192,12288,16384" > /sys/module/lowmemorykiller/parameters/minfree
# = 4MB, 8MB, 16MB, 32MB, 48MB, 64MB
```

This makes Android less likely to kill background processes.

### ZRAM Configuration

ZRAM creates a compressed block device in RAM for swap:

```bash
# Set ZRAM size to 512MB
echo 536870912 > /sys/block/zram0/disksize

# Format as swap
mkswap /dev/block/zram0

# Enable swap
swapon /dev/block/zram0
```

Benefits:
- Compressed memory = more effective RAM
- Reduces need to kill processes
- Improves multitasking

### Swappiness Tuning

```bash
# Set swappiness to 100 (aggressive swap usage)
echo 100 > /proc/sys/vm/swappiness
```

This tells the kernel to prefer swapping to ZRAM over killing processes.

## Battery Optimization Bypass

### Doze Mode Whitelist

```bash
# Add package to Doze whitelist
dumpsys deviceidle whitelist +com.termux
```

This prevents Android from putting the app into Doze mode, which would:
- Restrict network access
- Defer background jobs
- Limit wake locks

### Battery Optimization Disable

```bash
# Grant permission to ignore battery optimizations
pm grant com.termux android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
```

This allows the app to run unrestricted in the background.

## SELinux Policy

### Key Policy Rules

```
# Allow shell to execute module files
allow shell module_file { file dir } *

# Allow shell to write to proc oom_score_adj
allow shell proc { file } { write open }

# Allow shell to modify process scheduling
allow shell domain { process } { setsched }

# Allow httpd to bind to privileged ports
allow shell port { tcp_socket } { name_bind }

# Allow shell to use iptables
allow shell iptables_exec { file } { execute execute_no_trans }
```

### SELinux Contexts

Module files are automatically labeled as `module_file` by Magisk. Our policy rules grant necessary permissions to this context.

## Magisk Integration

### Module Directory Structure

```
/data/adb/modules/android.webserver.guard/
├── module.prop              # Module metadata
├── post-fs-data.sh         # Early boot script
├── service.sh              # Late boot script
├── uninstall.sh            # Cleanup script
├── system.prop             # System properties
├── sepolicy.rule           # SELinux rules
├── protected.list          # Protected processes
├── scripts/                # Helper scripts
│   ├── webserver_watchdog.sh
│   ├── protection_daemon.sh
│   ├── logcat_monitor.sh
│   └── protect_manager.sh
└── webroot/                # Web server content
    └── index.html
```

### Boot Script Execution Order

1. **post-fs-data.sh**: Runs before `/data` is mounted
   - Blocking (delays boot)
   - Use for critical early setup
   - Avoid heavy operations

2. **service.sh**: Runs after boot completion
   - Non-blocking (doesn't delay boot)
   - Use for starting services
   - Can run long operations

### System Properties

```bash
# Use resetprop instead of setprop in post-fs-data.sh
resetprop -n ro.webserver.guard.active 1

# -n flag: Don't trigger property change events (avoids deadlocks)
```

## BusyBox Standalone Mode

### Why Standalone Mode?

Magisk scripts run in BusyBox ash shell with standalone mode enabled:

```bash
ASH_STANDALONE=1
```

This means:
- All commands use BusyBox applets
- System binaries are ignored
- Consistent behavior across devices
- No PATH dependency

### Accessing System Binaries

If you need system binaries:

```bash
# Use full path
/system/bin/ls

# Or disable standalone mode temporarily
ASH_STANDALONE=0 ls
```

## Performance Considerations

### CPU Usage

- **protection_daemon.sh**: Wakes every 30s, runs ~0.1s
- **webserver_watchdog.sh**: Wakes every 15s, runs ~0.1s
- **httpd**: Idle until request, minimal CPU

Total overhead: < 1% CPU on average

### Memory Usage

- **httpd**: ~2-4 MB
- **protection_daemon.sh**: ~1-2 MB
- **webserver_watchdog.sh**: ~1-2 MB
- **ZRAM**: 512 MB (compressed, ~200-300 MB actual)

Total overhead: ~5-10 MB + ZRAM

### Battery Impact

Estimated battery drain:
- **Continuous monitoring**: ~1-2% per hour
- **Web server (idle)**: ~0.5% per hour
- **Web server (active)**: ~5-10% per hour

## Security Considerations

### Attack Surface

1. **Web Server**: Exposed on port 80/8080
   - Risk: Unauthorized access to web content
   - Mitigation: Use firewall rules, authentication

2. **Protected Processes**: Cannot be killed
   - Risk: Malicious process protection
   - Mitigation: Manual review of protected.list

3. **Root Access**: Module runs as root
   - Risk: Privilege escalation if compromised
   - Mitigation: Code review, minimal permissions

### Hardening Recommendations

```bash
# 1. Restrict web server to localhost only
iptables -A INPUT -p tcp --dport 8080 ! -s 127.0.0.1 -j DROP

# 2. Enable authentication (if BusyBox supports)
# Add .htpasswd to webroot/

# 3. Monitor protected.list for unauthorized entries
su -c "cat /data/adb/modules/android.webserver.guard/protected.list"

# 4. Review logs regularly
su -c "tail -f /data/local/tmp/webserver_module.log"
```

## Debugging

### Enable Verbose Logging

Edit scripts to add:

```bash
set -x  # Enable command tracing
```

### Monitor in Real-Time

```bash
# Follow main log
su -c "tail -f /data/local/tmp/webserver_module.log"

# Follow logcat
su -c "logcat -s webserver:* Magisk:*"

# Monitor process protection
su -c "watch -n 5 'cat /proc/\$(pgrep httpd)/oom_score_adj'"
```

### Common Issues

#### Issue: httpd keeps dying

**Diagnosis**:
```bash
# Check OOM score
cat /proc/$(pgrep httpd)/oom_score_adj

# Check memory pressure
cat /proc/meminfo | grep -E "MemAvailable|MemFree"

# Check LMK events
dmesg | grep lowmemorykiller
```

**Solution**:
- Increase ZRAM size
- Reduce LMK aggressiveness
- Free up memory

#### Issue: iptables rules not working

**Diagnosis**:
```bash
# Check NAT table
iptables -t nat -L -n -v

# Check if iptables is available
which iptables

# Check kernel support
cat /proc/net/ip_tables_names
```

**Solution**:
- Verify kernel has iptables support
- Check if another module conflicts
- Use direct port 8080 without redirect

#### Issue: SELinux denials

**Diagnosis**:
```bash
# Check denials
dmesg | grep denied | grep webserver

# Check SELinux mode
getenforce
```

**Solution**:
- Add missing rules to sepolicy.rule
- Temporarily use permissive mode for testing
- Check if Magisk SELinux patch is active

## Advanced Customization

### Custom Web Server

Replace BusyBox httpd with another server:

```bash
# In service.sh, replace:
$BUSYBOX httpd -p 8080 -h "$MODDIR/webroot" -f

# With (example: lighttpd):
/data/local/bin/lighttpd -f /path/to/lighttpd.conf -D
```

### Process Auto-Restart

Add to protection_daemon.sh:

```bash
# After detecting process not running
if [ -z "$PIDS" ]; then
    # Restart logic here
    case "$PROC_NAME" in
        "my_service")
            /path/to/my_service &
            ;;
    esac
fi
```

### Custom OOM Scores

Different protection levels:

```bash
# Maximum protection (never kill)
echo -1000 > /proc/$PID/oom_score_adj

# High protection (kill last)
echo -500 > /proc/$PID/oom_score_adj

# Normal protection
echo 0 > /proc/$PID/oom_score_adj

# Low protection (kill first)
echo 500 > /proc/$PID/oom_score_adj
```

## Testing

### Unit Tests

```bash
# Test 1: Web server responds
curl -I http://localhost:8080
# Expected: HTTP/1.0 200 OK

# Test 2: Process protection
TERMUX_PID=$(pgrep -f com.termux | head -n 1)
cat /proc/$TERMUX_PID/oom_score_adj
# Expected: -1000

# Test 3: Auto-restart
kill -9 $(pgrep httpd)
sleep 20
pgrep httpd
# Expected: New PID

# Test 4: iptables redirect
iptables -t nat -L OUTPUT -n -v | grep 8080
# Expected: REDIRECT rule present
```

### Stress Tests

```bash
# Test 1: Memory pressure
# Fill memory and verify processes survive
stress-ng --vm 4 --vm-bytes 90% --timeout 60s

# Test 2: Process kill loop
# Repeatedly kill and verify auto-restart
for i in {1..10}; do
    kill -9 $(pgrep httpd)
    sleep 5
done

# Test 3: Web server load
# Concurrent requests
ab -n 1000 -c 10 http://localhost:8080/
```

## Performance Tuning

### Reduce Monitoring Overhead

```bash
# Increase check intervals
# In protection_daemon.sh:
sleep 60  # Instead of 30

# In webserver_watchdog.sh:
sleep 30  # Instead of 15
```

### Optimize ZRAM

```bash
# Larger ZRAM for more memory
echo 1073741824 > /sys/block/zram0/disksize  # 1GB

# Different compression algorithm (if supported)
echo lz4 > /sys/block/zram0/comp_algorithm
```

### Reduce Logging

```bash
# Comment out verbose logs in scripts
# echo "$(date): ..." >> "$LOGFILE"
```

## References

- [Magisk Module Developer Guide](https://topjohnwu.github.io/Magisk/guides.html)
- [Android Low Memory Killer](https://source.android.com/devices/tech/perf/lmkd)
- [BusyBox Documentation](https://busybox.net/downloads/BusyBox.html)
- [iptables NAT Tutorial](https://www.netfilter.org/documentation/HOWTO/NAT-HOWTO.html)
- [SELinux Policy Language](https://selinuxproject.org/page/PolicyLanguage)

---

**Last Updated**: 2024  
**Module Version**: 1.0.0
