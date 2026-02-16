#!/system/bin/sh

##########################################################################################
# WebServer Guard API
# CGI script for web management interface
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
PROTECTED_LIST="$MODDIR/protected.list"
LOG_FILE="/data/local/tmp/webserver_module.log"

# Parse query string
parse_query() {
    echo "$QUERY_STRING" | tr '&' '\n' | while IFS='=' read -r key value; do
        case "$key" in
            action) ACTION=$(echo "$value" | sed 's/%20/ /g') ;;
            process) PROCESS=$(echo "$value" | sed 's/%20/ /g; s/%2F/\//g') ;;
        esac
    done
}

# Get action from query string
ACTION=$(echo "$QUERY_STRING" | grep -o 'action=[^&]*' | cut -d= -f2)
PROCESS=$(echo "$QUERY_STRING" | grep -o 'process=[^&]*' | cut -d= -f2 | sed 's/%20/ /g; s/%2F/\//g; s/%2E/./g')

# HTTP headers
echo "Content-Type: application/json"
echo "Access-Control-Allow-Origin: *"
echo ""

##########################################################################################
# API Actions
##########################################################################################

case "$ACTION" in
    status)
        # Get system status
        DAEMON_RUNNING=false
        WATCHDOG_RUNNING=false
        HTTPD_RUNNING=false
        TERMUX_RUNNING=false
        HTTPD_PID=""
        TERMUX_PID=""
        PROTECTED_COUNT=0
        
        if pgrep -f "protection_daemon.sh" >/dev/null 2>&1; then
            DAEMON_RUNNING=true
        fi
        
        if pgrep -f "webserver_watchdog.sh" >/dev/null 2>&1; then
            WATCHDOG_RUNNING=true
        fi
        
        if pgrep httpd >/dev/null 2>&1; then
            HTTPD_RUNNING=true
            HTTPD_PID=$(pgrep httpd | head -n 1)
        fi
        
        if pgrep -f com.termux >/dev/null 2>&1; then
            TERMUX_RUNNING=true
            TERMUX_PID=$(pgrep -f com.termux | head -n 1)
        fi
        
        if [ -f "$PROTECTED_LIST" ]; then
            PROTECTED_COUNT=$(cat "$PROTECTED_LIST" | grep -v "^#" | grep -v "^$" | wc -l)
        fi
        
        cat <<EOF
{
    "daemon": $DAEMON_RUNNING,
    "watchdog": $WATCHDOG_RUNNING,
    "httpd": $HTTPD_RUNNING,
    "httpd_pid": "$HTTPD_PID",
    "termux": $TERMUX_RUNNING,
    "termux_pid": "$TERMUX_PID",
    "protected_count": $PROTECTED_COUNT
}
EOF
        ;;
        
    list)
        # List protected processes
        echo '{"processes":['
        
        if [ -f "$PROTECTED_LIST" ]; then
            FIRST=true
            cat "$PROTECTED_LIST" | grep -v "^#" | grep -v "^$" | while read -r proc; do
                if [ "$FIRST" = true ]; then
                    FIRST=false
                else
                    echo ","
                fi
                
                RUNNING=false
                if pgrep -f "$proc" >/dev/null 2>&1; then
                    RUNNING=true
                fi
                
                echo -n "{\"name\":\"$proc\",\"running\":$RUNNING}"
            done
        fi
        
        echo ']}'
        ;;
        
    add)
        # Add process to protection list
        if [ -z "$PROCESS" ]; then
            echo '{"success":false,"message":"Process name is required"}'
            exit 0
        fi
        
        # Check if already protected
        if grep -q "^$PROCESS$" "$PROTECTED_LIST" 2>/dev/null; then
            echo '{"success":false,"message":"Process already protected"}'
            exit 0
        fi
        
        # Add to list
        echo "$PROCESS" >> "$PROTECTED_LIST"
        
        # Try to protect immediately if running
        PIDS=$(pgrep -f "$PROCESS")
        if [ -n "$PIDS" ]; then
            for PID in $PIDS; do
                echo -1000 > /proc/$PID/oom_score_adj 2>/dev/null
            done
        fi
        
        echo '{"success":true,"message":"Process added to protection list"}'
        ;;
        
    remove)
        # Remove process from protection list
        if [ -z "$PROCESS" ]; then
            echo '{"success":false,"message":"Process name is required"}'
            exit 0
        fi
        
        if [ ! -f "$PROTECTED_LIST" ]; then
            echo '{"success":false,"message":"Protection list not found"}'
            exit 0
        fi
        
        # Remove from list
        grep -v "^$PROCESS$" "$PROTECTED_LIST" > "$PROTECTED_LIST.tmp"
        mv "$PROTECTED_LIST.tmp" "$PROTECTED_LIST"
        
        echo '{"success":true,"message":"Process removed from protection list"}'
        ;;
        
    logs)
        # Get module logs
        if [ -f "$LOG_FILE" ]; then
            # Get last 500 lines
            LOGS=$(tail -n 500 "$LOG_FILE" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
            echo "{\"success\":true,\"logs\":\"$LOGS\"}"
        else
            echo '{"success":false,"logs":"Log file not found"}'
        fi
        ;;
        
    *)
        echo '{"success":false,"message":"Invalid action"}'
        ;;
esac
