#!/system/bin/sh

##########################################################################################
# WebServer Guard - Status CGI Script
# Returns real-time system status as JSON
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
PROTECTED_LIST="$MODDIR/protected.list"

# HTTP headers
echo "Content-Type: application/json"
echo "Cache-Control: no-cache"
echo ""

# Get httpd PID
HTTPD_PID=$(pgrep httpd | head -n 1)

# Get uptime
UPTIME=$(uptime | awk '{print $3" "$4}' | sed 's/,//')

# Count protected processes
if [ -f "$PROTECTED_LIST" ]; then
    PROTECTED_COUNT=$(cat "$PROTECTED_LIST" | grep -v "^#" | grep -v "^$" | wc -l)
else
    PROTECTED_COUNT=0
fi

# Get memory info
MEMORY=$(free -h | grep Mem | awk '{print $3"/"$2}')

# Get daemon status
if pgrep -f "protection_daemon.sh" >/dev/null 2>&1; then
    DAEMON_STATUS="running"
else
    DAEMON_STATUS="stopped"
fi

# Get watchdog status
if pgrep -f "webserver_watchdog.sh" >/dev/null 2>&1; then
    WATCHDOG_STATUS="running"
else
    WATCHDOG_STATUS="stopped"
fi

# Output JSON
cat << EOF
{
  "status": "running",
  "pid": "${HTTPD_PID:-unknown}",
  "uptime": "${UPTIME:-unknown}",
  "protected": "${PROTECTED_COUNT}",
  "memory": "${MEMORY:-unknown}",
  "daemon": "${DAEMON_STATUS}",
  "watchdog": "${WATCHDOG_STATUS}",
  "timestamp": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF
