#!/system/bin/sh

##########################################################################################
# Web Server Watchdog
# Monitors web server and restarts if killed
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
LOGFILE="/data/local/tmp/webserver_module.log"
BUSYBOX="/data/adb/magisk/busybox"
PID_FILE="/data/local/tmp/webserver_pids/httpd.pid"

echo "$(date): [WATCHDOG] Web server watchdog started" >> "$LOGFILE"

# Determine web port (check iptables rules)
if iptables -t nat -L OUTPUT 2>/dev/null | grep -q "redir ports 8080"; then
    WEB_PORT=8080
else
    WEB_PORT=8080
fi

##########################################################################################
# Watchdog Loop
##########################################################################################

while true; do
    # Check if httpd is running
    HTTPD_RUNNING=0
    
    # Method 1: Check PID file
    if [ -f "$PID_FILE" ]; then
        HTTPD_PID=$(cat "$PID_FILE")
        if [ -d "/proc/$HTTPD_PID" ]; then
            # Check if it's actually httpd
            if cat "/proc/$HTTPD_PID/cmdline" 2>/dev/null | grep -q "httpd"; then
                HTTPD_RUNNING=1
                
                # Protect the web server process
                echo -1000 > /proc/$HTTPD_PID/oom_score_adj 2>/dev/null
            fi
        fi
    fi
    
    # Method 2: Check by port
    if [ $HTTPD_RUNNING -eq 0 ]; then
        if $BUSYBOX netstat -tlnp 2>/dev/null | grep -q ":$WEB_PORT "; then
            HTTPD_RUNNING=1
        fi
    fi
    
    # Restart if not running
    if [ $HTTPD_RUNNING -eq 0 ]; then
        echo "$(date): [WATCHDOG] Web server not running, restarting..." >> "$LOGFILE"
        
        # Kill any stale httpd processes
        killall httpd 2>/dev/null
        sleep 2
        
        # Start new instance
        if [ -f "$BUSYBOX" ]; then
            $BUSYBOX httpd -p $WEB_PORT -h "$MODDIR/webroot" -f >> "$LOGFILE" 2>&1 &
            NEW_PID=$!
            
            # Save new PID
            echo "$NEW_PID" > "$PID_FILE"
            
            # Protect immediately
            sleep 1
            if [ -d "/proc/$NEW_PID" ]; then
                echo -1000 > /proc/$NEW_PID/oom_score_adj 2>/dev/null
            fi
            
            echo "$(date): [WATCHDOG] Web server restarted (PID: $NEW_PID)" >> "$LOGFILE"
        else
            echo "$(date): [WATCHDOG] ERROR - BusyBox not found" >> "$LOGFILE"
        fi
    fi
    
    # Check every 15 seconds
    sleep 15
    
done
