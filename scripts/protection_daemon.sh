#!/system/bin/sh

##########################################################################################
# Process Protection Daemon
# Monitors and protects processes from being killed by Android
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
PROTECTED_LIST="$MODDIR/protected.list"
LOGFILE="/data/local/tmp/webserver_module.log"
BUSYBOX="/data/adb/magisk/busybox"

echo "$(date): [DAEMON] Protection daemon started" >> "$LOGFILE"

##########################################################################################
# Protection Loop
##########################################################################################

while true; do
    # Check if protected list exists
    if [ ! -f "$PROTECTED_LIST" ]; then
        sleep 10
        continue
    fi
    
    # Read protected processes
    while IFS= read -r PROC_NAME; do
        # Skip empty lines and comments
        [ -z "$PROC_NAME" ] && continue
        echo "$PROC_NAME" | grep -q "^#" && continue
        
        # Find process by name
        PIDS=$(pgrep -f "$PROC_NAME")
        
        if [ -n "$PIDS" ]; then
            # Process is running - protect it
            for PID in $PIDS; do
                # Check if process still exists
                if [ -d "/proc/$PID" ]; then
                    # Set OOM score to minimum
                    CURRENT_OOM=$(cat /proc/$PID/oom_score_adj 2>/dev/null)
                    
                    if [ "$CURRENT_OOM" != "-1000" ]; then
                        echo -1000 > /proc/$PID/oom_score_adj 2>/dev/null
                        
                        if [ $? -eq 0 ]; then
                            echo "$(date): [DAEMON] Protected $PROC_NAME (PID: $PID, OOM: -1000)" >> "$LOGFILE"
                        fi
                    fi
                    
                    # Disable battery optimization if it's an app package
                    if echo "$PROC_NAME" | grep -q "\."; then
                        dumpsys deviceidle whitelist +$PROC_NAME 2>/dev/null
                    fi
                fi
            done
        else
            # Process not running - check if it should be restarted
            # (Only for services, not apps)
            echo "$(date): [DAEMON] Process $PROC_NAME not found" >> "$LOGFILE"
        fi
        
    done < "$PROTECTED_LIST"
    
    # Also protect Termux continuously
    TERMUX_PIDS=$(pgrep -f com.termux)
    for PID in $TERMUX_PIDS; do
        if [ -d "/proc/$PID" ]; then
            echo -1000 > /proc/$PID/oom_score_adj 2>/dev/null
        fi
    done
    
    # Check every 30 seconds
    sleep 30
    
done
