#!/system/bin/sh

##########################################################################################
# WebServer Guard - Uninstall Script
# Cleanup when module is removed
##########################################################################################

LOGFILE="/data/local/tmp/webserver_module.log"

echo "========================================" >> "$LOGFILE"
echo "$(date): UNINSTALL STARTED" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"

##########################################################################################
# Stop Running Services
##########################################################################################

# Kill web server
killall httpd 2>/dev/null

# Kill daemon processes
pkill -f "protection_daemon.sh" 2>/dev/null
pkill -f "webserver_watchdog.sh" 2>/dev/null
pkill -f "logcat_monitor.sh" 2>/dev/null

echo "$(date): Services stopped" >> "$LOGFILE"

##########################################################################################
# Remove iptables Rules
##########################################################################################

if command -v iptables >/dev/null 2>&1; then
    iptables -t nat -D OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 8080 2>/dev/null
    iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080 2>/dev/null
    echo "$(date): iptables rules removed" >> "$LOGFILE"
fi

##########################################################################################
# Cleanup Files
##########################################################################################

# Remove PID files
rm -rf /data/local/tmp/webserver_pids 2>/dev/null

# Remove ZRAM flag
rm -f /data/local/tmp/.zram_enabled 2>/dev/null

# Optionally remove logs (commented out to preserve for debugging)
# rm -rf /data/local/tmp/webserver_logs 2>/dev/null
# rm -f "$LOGFILE" 2>/dev/null

echo "$(date): Cleanup completed" >> "$LOGFILE"

##########################################################################################
# Reset System Properties
##########################################################################################

resetprop --delete ro.webserver.guard.active 2>/dev/null
resetprop --delete ro.webserver.guard.running 2>/dev/null
resetprop --delete persist.webserver.guard.enabled 2>/dev/null

echo "$(date): System properties reset" >> "$LOGFILE"

##########################################################################################
# Restore OOM Scores (Optional)
##########################################################################################

# Note: OOM scores will be reset automatically on next boot
# No need to manually restore them

##########################################################################################
# Uninstall Complete
##########################################################################################

echo "$(date): UNINSTALL COMPLETED" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"
echo "" >> "$LOGFILE"

# Note: Module directory will be removed automatically by Magisk
