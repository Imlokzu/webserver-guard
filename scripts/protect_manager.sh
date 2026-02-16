#!/system/bin/sh

##########################################################################################
# Process Protection Manager
# CLI tool for managing protected processes
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
PROTECTED_LIST="$MODDIR/protected.list"
BUSYBOX="/data/adb/magisk/busybox"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

##########################################################################################
# Helper Functions
##########################################################################################

print_header() {
    echo ""
    echo "=========================================="
    echo "  WebServer Guard - Protection Manager"
    echo "=========================================="
    echo ""
}

print_menu() {
    echo "Options:"
    echo "  1) List currently protected processes"
    echo "  2) Add process to protection list"
    echo "  3) Remove process from protection list"
    echo "  4) Show running processes"
    echo "  5) Protect running process by PID"
    echo "  6) View protection status"
    echo "  7) Clear all protections"
    echo "  0) Exit"
    echo ""
}

list_protected() {
    echo ""
    echo "Protected Processes:"
    echo "--------------------"
    
    if [ ! -f "$PROTECTED_LIST" ] || [ ! -s "$PROTECTED_LIST" ]; then
        echo "  (none)"
    else
        cat "$PROTECTED_LIST" | grep -v "^#" | grep -v "^$" | while read -r proc; do
            # Check if process is running
            if pgrep -f "$proc" >/dev/null 2>&1; then
                echo "  ✓ $proc (running)"
            else
                echo "  ✗ $proc (not running)"
            fi
        done
    fi
    echo ""
}

add_protection() {
    echo ""
    echo "Enter process name or package to protect:"
    echo "(Examples: com.termux, httpd, nginx, python)"
    read -r PROC_NAME
    
    if [ -z "$PROC_NAME" ]; then
        echo "Error: Process name cannot be empty"
        return
    fi
    
    # Check if already protected
    if grep -q "^$PROC_NAME$" "$PROTECTED_LIST" 2>/dev/null; then
        echo "Process '$PROC_NAME' is already protected"
        return
    fi
    
    # Add to list
    echo "$PROC_NAME" >> "$PROTECTED_LIST"
    echo "✓ Added '$PROC_NAME' to protection list"
    
    # Try to protect immediately if running
    PIDS=$(pgrep -f "$PROC_NAME")
    if [ -n "$PIDS" ]; then
        for PID in $PIDS; do
            echo -1000 > /proc/$PID/oom_score_adj 2>/dev/null
            echo "  Protected PID: $PID"
        done
    else
        echo "  (Process not currently running)"
    fi
    echo ""
}

remove_protection() {
    echo ""
    list_protected
    echo "Enter process name to remove from protection:"
    read -r PROC_NAME
    
    if [ -z "$PROC_NAME" ]; then
        echo "Error: Process name cannot be empty"
        return
    fi
    
    # Remove from list
    if [ -f "$PROTECTED_LIST" ]; then
        grep -v "^$PROC_NAME$" "$PROTECTED_LIST" > "$PROTECTED_LIST.tmp"
        mv "$PROTECTED_LIST.tmp" "$PROTECTED_LIST"
        echo "✓ Removed '$PROC_NAME' from protection list"
    else
        echo "Error: Protection list not found"
    fi
    echo ""
}

show_processes() {
    echo ""
    echo "Running Processes (top 20 by memory):"
    echo "--------------------------------------"
    ps -A -o PID,NAME,RSS | sort -k3 -rn | head -n 21
    echo ""
}

protect_by_pid() {
    echo ""
    echo "Enter PID to protect:"
    read -r PID
    
    if [ -z "$PID" ]; then
        echo "Error: PID cannot be empty"
        return
    fi
    
    # Check if PID exists
    if [ ! -d "/proc/$PID" ]; then
        echo "Error: Process $PID not found"
        return
    fi
    
    # Get process name
    PROC_NAME=$(cat /proc/$PID/cmdline 2>/dev/null | tr '\0' ' ')
    
    # Protect
    echo -1000 > /proc/$PID/oom_score_adj 2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "✓ Protected PID $PID ($PROC_NAME)"
        echo "  OOM score: -1000"
    else
        echo "✗ Failed to protect PID $PID"
    fi
    echo ""
}

show_status() {
    echo ""
    echo "Protection Status:"
    echo "------------------"
    
    # Check if daemon is running
    if pgrep -f "protection_daemon.sh" >/dev/null 2>&1; then
        echo "  Protection Daemon: ✓ Running"
    else
        echo "  Protection Daemon: ✗ Not Running"
    fi
    
    # Check if watchdog is running
    if pgrep -f "webserver_watchdog.sh" >/dev/null 2>&1; then
        echo "  Web Server Watchdog: ✓ Running"
    else
        echo "  Web Server Watchdog: ✗ Not Running"
    fi
    
    # Check web server
    if pgrep httpd >/dev/null 2>&1; then
        HTTPD_PID=$(pgrep httpd | head -n 1)
        HTTPD_OOM=$(cat /proc/$HTTPD_PID/oom_score_adj 2>/dev/null)
        echo "  Web Server: ✓ Running (PID: $HTTPD_PID, OOM: $HTTPD_OOM)"
    else
        echo "  Web Server: ✗ Not Running"
    fi
    
    # Check Termux
    if pgrep -f com.termux >/dev/null 2>&1; then
        TERMUX_PID=$(pgrep -f com.termux | head -n 1)
        TERMUX_OOM=$(cat /proc/$TERMUX_PID/oom_score_adj 2>/dev/null)
        echo "  Termux: ✓ Running (PID: $TERMUX_PID, OOM: $TERMUX_OOM)"
    else
        echo "  Termux: ✗ Not Running"
    fi
    
    # Count protected processes
    PROTECTED_COUNT=$(cat "$PROTECTED_LIST" 2>/dev/null | grep -v "^#" | grep -v "^$" | wc -l)
    echo "  Protected Processes: $PROTECTED_COUNT"
    
    echo ""
}

clear_protections() {
    echo ""
    echo "Are you sure you want to clear all protections? (y/n)"
    read -r CONFIRM
    
    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
        > "$PROTECTED_LIST"
        echo "✓ All protections cleared"
    else
        echo "Cancelled"
    fi
    echo ""
}

##########################################################################################
# Main Menu Loop
##########################################################################################

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root"
    echo "Usage: su -c $0"
    exit 1
fi

# Create protected list if it doesn't exist
touch "$PROTECTED_LIST"

# Interactive mode
if [ "$1" = "" ]; then
    while true; do
        print_header
        print_menu
        
        echo -n "Select option: "
        read -r CHOICE
        
        case $CHOICE in
            1) list_protected ;;
            2) add_protection ;;
            3) remove_protection ;;
            4) show_processes ;;
            5) protect_by_pid ;;
            6) show_status ;;
            7) clear_protections ;;
            0) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option" ;;
        esac
        
        echo "Press Enter to continue..."
        read -r
    done
else
    # Command-line mode
    case "$1" in
        list) list_protected ;;
        status) show_status ;;
        add)
            if [ -n "$2" ]; then
                echo "$2" >> "$PROTECTED_LIST"
                echo "Added $2 to protection list"
            else
                echo "Usage: $0 add <process_name>"
            fi
            ;;
        remove)
            if [ -n "$2" ]; then
                grep -v "^$2$" "$PROTECTED_LIST" > "$PROTECTED_LIST.tmp"
                mv "$PROTECTED_LIST.tmp" "$PROTECTED_LIST"
                echo "Removed $2 from protection list"
            else
                echo "Usage: $0 remove <process_name>"
            fi
            ;;
        *)
            echo "Usage: $0 [list|status|add|remove]"
            exit 1
            ;;
    esac
fi
