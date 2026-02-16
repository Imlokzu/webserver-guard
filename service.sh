#!/system/bin/sh

##########################################################################################
# WebServer Guard - Service Script
# Runs after boot completion (non-blocking)
##########################################################################################

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/webserver_module.log"
BUSYBOX="/data/adb/magisk/busybox"

echo "========================================" >> "$LOGFILE"
echo "$(date): SERVICE SCRIPT STARTED" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"

##########################################################################################
# Wait for Boot Completion
##########################################################################################

echo "$(date): Waiting for boot completion..." >> "$LOGFILE"

# Wait for boot to complete
BOOT_WAIT=0
while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 2
    BOOT_WAIT=$((BOOT_WAIT + 2))
    if [ $BOOT_WAIT -ge 120 ]; then
        echo "$(date): Boot wait timeout after 120s" >> "$LOGFILE"
        break
    fi
done

echo "$(date): Boot completed (waited ${BOOT_WAIT}s)" >> "$LOGFILE"

# Additional wait for system stabilization
sleep 5

##########################################################################################
# Disable Battery Optimization for Termux
##########################################################################################

echo "$(date): Configuring battery optimizations..." >> "$LOGFILE"

# Disable Doze for Termux
dumpsys deviceidle whitelist +com.termux >> "$LOGFILE" 2>&1

# Disable battery optimization via settings
pm grant com.termux android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS 2>/dev/null

echo "$(date): Battery optimizations configured" >> "$LOGFILE"

##########################################################################################
# Configure Network for Port 80
##########################################################################################

echo "$(date): Configuring network for port 80..." >> "$LOGFILE"

# Option 1: Try to bind directly to port 80 (requires CAP_NET_BIND_SERVICE)
# Option 2: Redirect port 80 to 8080 using iptables

# Check if we can use iptables
if command -v iptables >/dev/null 2>&1; then
    # Clear any existing rules for port 80
    iptables -t nat -D OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8080 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080 2>/dev/null
    
    # Add redirect rules (80 -> 8080)
    iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8080
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080
    
    echo "$(date): iptables redirect configured (80 -> 8080)" >> "$LOGFILE"
    WEB_PORT=8080
else
    echo "$(date): iptables not available, using port 8080 directly" >> "$LOGFILE"
    WEB_PORT=8080
fi

##########################################################################################
# Start Web Server
##########################################################################################

echo "$(date): Starting web server..." >> "$LOGFILE"

# Kill any existing httpd instances
killall httpd 2>/dev/null
sleep 1

# Start BusyBox httpd
if [ -f "$BUSYBOX" ]; then
    # Start httpd on port 8080 (or 80 if capable)
    $BUSYBOX httpd -p $WEB_PORT -h "$MODDIR/webroot" -f >> "$LOGFILE" 2>&1 &
    HTTPD_PID=$!
    
    # Save PID
    echo "$HTTPD_PID" > /data/local/tmp/webserver_pids/httpd.pid
    
    echo "$(date): Web server started on port $WEB_PORT (PID: $HTTPD_PID)" >> "$LOGFILE"
else
    echo "$(date): ERROR - BusyBox not found at $BUSYBOX" >> "$LOGFILE"
fi

##########################################################################################
# Start Process Protection Engine
##########################################################################################

echo "$(date): Starting process protection engine..." >> "$LOGFILE"

# Launch protection daemon in background
"$MODDIR/scripts/protection_daemon.sh" >> "$LOGFILE" 2>&1 &
DAEMON_PID=$!

echo "$(date): Protection daemon started (PID: $DAEMON_PID)" >> "$LOGFILE"

##########################################################################################
# Start Web Server Watchdog
##########################################################################################

echo "$(date): Starting web server watchdog..." >> "$LOGFILE"

# Launch watchdog in background
"$MODDIR/scripts/webserver_watchdog.sh" >> "$LOGFILE" 2>&1 &
WATCHDOG_PID=$!

echo "$(date): Watchdog started (PID: $WATCHDOG_PID)" >> "$LOGFILE"

##########################################################################################
# Apply Advanced System Tweaks
##########################################################################################

echo "$(date): Applying system tweaks..." >> "$LOGFILE"

# Adjust LMK (Low Memory Killer) parameters to be less aggressive
if [ -f /sys/module/lowmemorykiller/parameters/minfree ]; then
    # Make LMK less aggressive (values in pages, 1 page = 4KB)
    echo "1024,2048,4096,8192,12288,16384" > /sys/module/lowmemorykiller/parameters/minfree 2>/dev/null
    echo "$(date): LMK parameters adjusted" >> "$LOGFILE"
fi

# Enable ZRAM if available and not already enabled
if [ -b /dev/block/zram0 ] && [ ! -f /data/local/tmp/.zram_enabled ]; then
    # Check if ZRAM is not already set up
    ZRAM_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null)
    if [ "$ZRAM_SIZE" = "0" ] || [ -z "$ZRAM_SIZE" ]; then
        # Set ZRAM size to 512MB
        echo 536870912 > /sys/block/zram0/disksize 2>/dev/null
        mkswap /dev/block/zram0 2>/dev/null
        swapon /dev/block/zram0 2>/dev/null
        touch /data/local/tmp/.zram_enabled
        echo "$(date): ZRAM enabled (512MB)" >> "$LOGFILE"
    fi
fi

# Adjust swappiness for better memory management
if [ -f /proc/sys/vm/swappiness ]; then
    echo 100 > /proc/sys/vm/swappiness 2>/dev/null
    echo "$(date): Swappiness set to 100" >> "$LOGFILE"
fi

##########################################################################################
# Protect Termux Process
##########################################################################################

echo "$(date): Protecting Termux process..." >> "$LOGFILE"

# Find Termux process and protect it
TERMUX_PID=$(pgrep -f com.termux | head -n 1)

if [ -n "$TERMUX_PID" ]; then
    # Set OOM score to minimum (most protected)
    echo -1000 > /proc/$TERMUX_PID/oom_score_adj 2>/dev/null
    echo "$(date): Termux protected (PID: $TERMUX_PID, OOM: -1000)" >> "$LOGFILE"
else
    echo "$(date): Termux not running yet" >> "$LOGFILE"
fi

##########################################################################################
# Service Script Complete
##########################################################################################

echo "$(date): SERVICE SCRIPT COMPLETED" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Module is now fully active
resetprop -n ro.webserver.guard.running 1
