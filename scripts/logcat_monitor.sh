#!/system/bin/sh

##########################################################################################
# Logcat Monitor
# Monitors logcat for lowmemorykiller events and restarts killed processes
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
PROTECTED_LIST="$MODDIR/protected.list"
LOGFILE="/data/local/tmp/webserver_module.log"

echo "$(date): [LOGCAT] Logcat monitor started" >> "$LOGFILE"

##########################################################################################
# Monitor Loop
##########################################################################################

# Clear logcat buffer
logcat -c 2>/dev/null

# Monitor for lowmemorykiller events
logcat -v time | while read -r line; do
    # Check for LMK (Low Memory Killer) events
    if echo "$line" | grep -qi "lowmemorykiller"; then
        echo "$(date): [LOGCAT] LMK event detected: $line" >> "$LOGFILE"
        
        # Extract PID from log line
        KILLED_PID=$(echo "$line" | grep -oE "pid [0-9]+" | grep -oE "[0-9]+")
        
        if [ -n "$KILLED_PID" ]; then
            echo "$(date): [LOGCAT] Process killed by LMK: PID $KILLED_PID" >> "$LOGFILE"
            
            # Check if this was a protected process
            # (This is informational - the protection daemon will handle restart)
        fi
    fi
    
    # Check for OOM (Out of Memory) events
    if echo "$line" | grep -qi "out of memory"; then
        echo "$(date): [LOGCAT] OOM event detected: $line" >> "$LOGFILE"
    fi
    
done
