#!/system/bin/sh

##########################################################################################
# WebServer Guard - Post FS Data Script
# Runs BEFORE module system folder is mounted (blocking)
##########################################################################################

MODDIR=${0%/*}
LOGFILE="/data/local/tmp/webserver_module.log"

# Initialize log
mkdir -p /data/local/tmp
echo "========================================" >> "$LOGFILE"
echo "$(date): POST-FS-DATA STARTED" >> "$LOGFILE"
echo "========================================" >> "$LOGFILE"

##########################################################################################
# Set System Properties (using resetprop to avoid deadlocks)
##########################################################################################

# Mark module as active
resetprop -n ro.webserver.guard.active 1
resetprop -n persist.webserver.guard.enabled 1

echo "$(date): System properties set" >> "$LOGFILE"

##########################################################################################
# Prepare Directories
##########################################################################################

# Create log directory
mkdir -p /data/local/tmp/webserver_logs

# Create PID tracking directory
mkdir -p /data/local/tmp/webserver_pids

echo "$(date): Directories prepared" >> "$LOGFILE"

##########################################################################################
# Early Network Configuration
##########################################################################################

# Ensure port 80 is available (kill any existing process on port 80)
# This runs early to free up the port before service.sh starts the web server

BUSYBOX="/data/adb/magisk/busybox"

if [ -f "$BUSYBOX" ]; then
    # Find process using port 80 and kill it
    PORT80_PID=$($BUSYBOX netstat -tlnp 2>/dev/null | $BUSYBOX grep ":80 " | $BUSYBOX awk '{print $7}' | $BUSYBOX cut -d'/' -f1)
    
    if [ -n "$PORT80_PID" ]; then
        echo "$(date): Found process $PORT80_PID on port 80, terminating..." >> "$LOGFILE"
        kill -9 "$PORT80_PID" 2>/dev/null
        sleep 1
    fi
fi

##########################################################################################
# SELinux Context Preparation
##########################################################################################

# Set SELinux contexts for module files (if SELinux is enforcing)
if [ -f /sys/fs/selinux/enforce ]; then
    SELINUX_MODE=$(cat /sys/fs/selinux/enforce)
    echo "$(date): SELinux mode: $SELINUX_MODE" >> "$LOGFILE"
fi

##########################################################################################
# Post-FS-Data Complete
##########################################################################################

echo "$(date): POST-FS-DATA COMPLETED" >> "$LOGFILE"
echo "" >> "$LOGFILE"
