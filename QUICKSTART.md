# Quick Start Guide

## 5-Minute Setup

### 1. Install Module (30 seconds)

```bash
# Download WebServerGuard.zip to your device
# Open Magisk Manager → Modules → Install from storage
# Select WebServerGuard.zip → Reboot
```

### 2. Verify Installation (1 minute)

```bash
# After reboot, check if web server is running
curl http://localhost

# Expected output: HTML page with "WebServer Guard Active"
```

### 3. Protect Your Processes (2 minutes)

```bash
# Open protection manager
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh

# Select option 2 (Add process)
# Enter: com.termux
# Done! Termux is now protected
```

### 4. Check Status (30 seconds)

```bash
# View protection status
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh status

# Should show:
# ✓ Protection Daemon: Running
# ✓ Web Server: Running
# ✓ Termux: Protected (OOM: -1000)
```

### 5. View Logs (1 minute)

```bash
# Check module logs
su -c cat /data/local/tmp/webserver_module.log

# Follow logs in real-time
su -c tail -f /data/local/tmp/webserver_module.log
```

## Common Tasks

### Add Process Protection

```bash
# Method 1: Interactive
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh
# Select option 2, enter process name

# Method 2: Command line
su -c "echo 'com.example.app' >> /data/adb/modules/android.webserver.guard/protected.list"
```

### Remove Process Protection

```bash
# Method 1: Interactive
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh
# Select option 3, enter process name

# Method 2: Manual edit
su -c nano /data/adb/modules/android.webserver.guard/protected.list
# Delete the line, save
```

### Change Web Content

```bash
# Replace index.html
su -c "echo '<h1>My Page</h1>' > /data/adb/modules/android.webserver.guard/webroot/index.html"

# Restart web server
su -c killall httpd
# Watchdog will auto-restart it
```

### Check Web Server Status

```bash
# Check if running
su -c "ps -A | grep httpd"

# Check port binding
su -c "netstat -tlnp | grep 8080"

# Test from device
curl http://localhost

# Test from network (replace IP)
curl http://192.168.1.100
```

### View Protected Processes

```bash
# List all protected
su -c cat /data/adb/modules/android.webserver.guard/protected.list

# Check OOM score of a process
PID=$(pgrep -f com.termux | head -n 1)
su -c "cat /proc/$PID/oom_score_adj"
# Should show: -1000
```

## Troubleshooting

### Web Server Not Working

```bash
# Check logs
su -c cat /data/local/tmp/webserver_module.log | grep ERROR

# Manually start
su -c /data/adb/magisk/busybox httpd -p 8080 -h /data/adb/modules/android.webserver.guard/webroot -f &

# Check port conflict
su -c "netstat -tlnp | grep 8080"
```

### Process Still Being Killed

```bash
# Verify protection
PID=$(pgrep -f <process_name>)
su -c "cat /proc/$PID/oom_score_adj"
# Should be -1000

# Check if daemon is running
su -c "ps -A | grep protection_daemon"

# Manually protect
su -c "echo -1000 > /proc/$PID/oom_score_adj"
```

### Module Not Loading

```bash
# Check module status
su -c "ls -la /data/adb/modules/android.webserver.guard/"

# Check for disable flag
su -c "ls /data/adb/modules/android.webserver.guard/disable"
# Should not exist

# Re-enable if disabled
su -c "rm /data/adb/modules/android.webserver.guard/disable"
su -c reboot
```

## One-Liners

```bash
# Quick status check
su -c "/data/adb/modules/android.webserver.guard/scripts/protect_manager.sh status"

# Add Termux protection
su -c "echo 'com.termux' >> /data/adb/modules/android.webserver.guard/protected.list"

# Test web server
curl -I http://localhost

# View last 20 log lines
su -c "tail -20 /data/local/tmp/webserver_module.log"

# Restart web server
su -c "killall httpd"

# Check all protected processes
su -c "cat /data/adb/modules/android.webserver.guard/protected.list | grep -v '^#' | grep -v '^$'"

# Find process PID
pgrep -f <process_name>

# Check process OOM score
su -c "cat /proc/\$(pgrep -f <process_name> | head -n 1)/oom_score_adj"
```

## Tips

1. **Always use `su -c`** for root commands
2. **Check logs first** when troubleshooting
3. **Reboot after changes** to module files
4. **Use protection manager** instead of manual edits
5. **Monitor battery drain** with persistent services
6. **Test web server** from both localhost and network
7. **Backup protected.list** before updates

## Next Steps

- Read full documentation: `README.md`
- Learn technical details: `TECHNICAL.md`
- Installation guide: `INSTALLATION.md`

---

**Need Help?** Check logs at `/data/local/tmp/webserver_module.log`
