#!/system/bin/sh

##########################################################################################
# WebServer Guard Module - Test Script
# Comprehensive testing suite for module functionality
##########################################################################################

MODDIR="/data/adb/modules/android.webserver.guard"
LOGFILE="/data/local/tmp/webserver_module.log"
BUSYBOX="/data/adb/magisk/busybox"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

##########################################################################################
# Helper Functions
##########################################################################################

print_header() {
    echo ""
    echo "=========================================="
    echo "  WebServer Guard - Test Suite"
    echo "=========================================="
    echo ""
}

test_pass() {
    echo "  ✓ $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo "  ✗ $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_info() {
    echo "  ℹ $1"
}

##########################################################################################
# Test 1: Module Installation
##########################################################################################

test_module_installation() {
    echo ""
    echo "[Test 1] Module Installation"
    echo "----------------------------"
    
    # Check if module directory exists
    if [ -d "$MODDIR" ]; then
        test_pass "Module directory exists"
    else
        test_fail "Module directory not found"
        return
    fi
    
    # Check if module is enabled
    if [ ! -f "$MODDIR/disable" ]; then
        test_pass "Module is enabled"
    else
        test_fail "Module is disabled"
    fi
    
    # Check module.prop
    if [ -f "$MODDIR/module.prop" ]; then
        test_pass "module.prop exists"
        VERSION=$(grep "^version=" "$MODDIR/module.prop" | cut -d'=' -f2)
        test_info "Version: $VERSION"
    else
        test_fail "module.prop not found"
    fi
    
    # Check required scripts
    for script in post-fs-data.sh service.sh uninstall.sh; do
        if [ -f "$MODDIR/$script" ]; then
            test_pass "$script exists"
            
            # Check if executable
            if [ -x "$MODDIR/$script" ]; then
                test_pass "$script is executable"
            else
                test_fail "$script is not executable"
            fi
        else
            test_fail "$script not found"
        fi
    done
}

##########################################################################################
# Test 2: Web Server
##########################################################################################

test_web_server() {
    echo ""
    echo "[Test 2] Web Server"
    echo "-------------------"
    
    # Check if httpd is running
    if pgrep httpd >/dev/null 2>&1; then
        HTTPD_PID=$(pgrep httpd | head -n 1)
        test_pass "Web server is running (PID: $HTTPD_PID)"
        
        # Check OOM score
        if [ -f "/proc/$HTTPD_PID/oom_score_adj" ]; then
            OOM_SCORE=$(cat /proc/$HTTPD_PID/oom_score_adj)
            if [ "$OOM_SCORE" = "-1000" ]; then
                test_pass "Web server is protected (OOM: $OOM_SCORE)"
            else
                test_fail "Web server not protected (OOM: $OOM_SCORE, expected: -1000)"
            fi
        fi
    else
        test_fail "Web server is not running"
    fi
    
    # Check port binding
    if $BUSYBOX netstat -tlnp 2>/dev/null | grep -q ":8080 "; then
        test_pass "Port 8080 is bound"
    else
        test_fail "Port 8080 is not bound"
    fi
    
    # Test HTTP request
    if command -v curl >/dev/null 2>&1; then
        HTTP_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)
        if [ "$HTTP_RESPONSE" = "200" ]; then
            test_pass "HTTP request successful (200 OK)"
        else
            test_fail "HTTP request failed (code: $HTTP_RESPONSE)"
        fi
    else
        test_info "curl not available, skipping HTTP test"
    fi
    
    # Check web root
    if [ -d "$MODDIR/webroot" ]; then
        test_pass "Web root directory exists"
        
        if [ -f "$MODDIR/webroot/index.html" ]; then
            test_pass "index.html exists"
        else
            test_fail "index.html not found"
        fi
    else
        test_fail "Web root directory not found"
    fi
}

##########################################################################################
# Test 3: Process Protection
##########################################################################################

test_process_protection() {
    echo ""
    echo "[Test 3] Process Protection"
    echo "---------------------------"
    
    # Check if protection daemon is running
    if pgrep -f "protection_daemon.sh" >/dev/null 2>&1; then
        DAEMON_PID=$(pgrep -f "protection_daemon.sh" | head -n 1)
        test_pass "Protection daemon is running (PID: $DAEMON_PID)"
    else
        test_fail "Protection daemon is not running"
    fi
    
    # Check if watchdog is running
    if pgrep -f "webserver_watchdog.sh" >/dev/null 2>&1; then
        WATCHDOG_PID=$(pgrep -f "webserver_watchdog.sh" | head -n 1)
        test_pass "Watchdog is running (PID: $WATCHDOG_PID)"
    else
        test_fail "Watchdog is not running"
    fi
    
    # Check protected.list
    if [ -f "$MODDIR/protected.list" ]; then
        test_pass "protected.list exists"
        
        PROTECTED_COUNT=$(cat "$MODDIR/protected.list" | grep -v "^#" | grep -v "^$" | wc -l)
        test_info "Protected processes: $PROTECTED_COUNT"
    else
        test_fail "protected.list not found"
    fi
    
    # Check Termux protection
    if pgrep -f com.termux >/dev/null 2>&1; then
        TERMUX_PID=$(pgrep -f com.termux | head -n 1)
        TERMUX_OOM=$(cat /proc/$TERMUX_PID/oom_score_adj 2>/dev/null)
        
        if [ "$TERMUX_OOM" = "-1000" ]; then
            test_pass "Termux is protected (PID: $TERMUX_PID, OOM: $TERMUX_OOM)"
        else
            test_fail "Termux not protected (OOM: $TERMUX_OOM, expected: -1000)"
        fi
    else
        test_info "Termux is not running"
    fi
}

##########################################################################################
# Test 4: Network Configuration
##########################################################################################

test_network_configuration() {
    echo ""
    echo "[Test 4] Network Configuration"
    echo "------------------------------"
    
    # Check iptables rules
    if command -v iptables >/dev/null 2>&1; then
        test_pass "iptables is available"
        
        # Check NAT rules
        if iptables -t nat -L OUTPUT 2>/dev/null | grep -q "redir ports 8080"; then
            test_pass "iptables OUTPUT rule exists (80 -> 8080)"
        else
            test_fail "iptables OUTPUT rule not found"
        fi
        
        if iptables -t nat -L PREROUTING 2>/dev/null | grep -q "redir ports 8080"; then
            test_pass "iptables PREROUTING rule exists (80 -> 8080)"
        else
            test_fail "iptables PREROUTING rule not found"
        fi
    else
        test_info "iptables not available"
    fi
    
    # Check if port 80 redirects to 8080
    if command -v curl >/dev/null 2>&1; then
        HTTP_80=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:80 2>/dev/null)
        if [ "$HTTP_80" = "200" ]; then
            test_pass "Port 80 is accessible (redirects to 8080)"
        else
            test_info "Port 80 not accessible (code: $HTTP_80)"
        fi
    fi
}

##########################################################################################
# Test 5: System Properties
##########################################################################################

test_system_properties() {
    echo ""
    echo "[Test 5] System Properties"
    echo "--------------------------"
    
    # Check module properties
    PROP_ACTIVE=$(getprop ro.webserver.guard.active)
    if [ "$PROP_ACTIVE" = "1" ]; then
        test_pass "ro.webserver.guard.active = 1"
    else
        test_fail "ro.webserver.guard.active not set"
    fi
    
    PROP_RUNNING=$(getprop ro.webserver.guard.running)
    if [ "$PROP_RUNNING" = "1" ]; then
        test_pass "ro.webserver.guard.running = 1"
    else
        test_fail "ro.webserver.guard.running not set"
    fi
    
    PROP_ENABLED=$(getprop persist.webserver.guard.enabled)
    if [ "$PROP_ENABLED" = "1" ]; then
        test_pass "persist.webserver.guard.enabled = 1"
    else
        test_fail "persist.webserver.guard.enabled not set"
    fi
}

##########################################################################################
# Test 6: Logging
##########################################################################################

test_logging() {
    echo ""
    echo "[Test 6] Logging"
    echo "----------------"
    
    # Check if log file exists
    if [ -f "$LOGFILE" ]; then
        test_pass "Log file exists"
        
        # Check log size
        LOG_SIZE=$(du -h "$LOGFILE" | cut -f1)
        test_info "Log size: $LOG_SIZE"
        
        # Check for recent entries
        RECENT_ENTRIES=$(tail -10 "$LOGFILE" | wc -l)
        if [ "$RECENT_ENTRIES" -gt 0 ]; then
            test_pass "Log has recent entries"
        else
            test_fail "Log has no recent entries"
        fi
        
        # Check for errors
        ERROR_COUNT=$(grep -c "ERROR" "$LOGFILE" 2>/dev/null || echo 0)
        if [ "$ERROR_COUNT" -eq 0 ]; then
            test_pass "No errors in log"
        else
            test_fail "Found $ERROR_COUNT errors in log"
        fi
    else
        test_fail "Log file not found"
    fi
    
    # Check log directory
    if [ -d "/data/local/tmp/webserver_logs" ]; then
        test_pass "Log directory exists"
    else
        test_info "Log directory not found"
    fi
}

##########################################################################################
# Test 7: Memory Management
##########################################################################################

test_memory_management() {
    echo ""
    echo "[Test 7] Memory Management"
    echo "--------------------------"
    
    # Check LMK parameters
    if [ -f "/sys/module/lowmemorykiller/parameters/minfree" ]; then
        LMK_PARAMS=$(cat /sys/module/lowmemorykiller/parameters/minfree)
        test_pass "LMK parameters: $LMK_PARAMS"
    else
        test_info "LMK parameters not available"
    fi
    
    # Check ZRAM
    if [ -b "/dev/block/zram0" ]; then
        ZRAM_SIZE=$(cat /sys/block/zram0/disksize 2>/dev/null)
        if [ "$ZRAM_SIZE" -gt 0 ]; then
            ZRAM_SIZE_MB=$((ZRAM_SIZE / 1024 / 1024))
            test_pass "ZRAM enabled (${ZRAM_SIZE_MB}MB)"
        else
            test_info "ZRAM not enabled"
        fi
    else
        test_info "ZRAM not available"
    fi
    
    # Check swappiness
    if [ -f "/proc/sys/vm/swappiness" ]; then
        SWAPPINESS=$(cat /proc/sys/vm/swappiness)
        test_info "Swappiness: $SWAPPINESS"
    fi
}

##########################################################################################
# Test 8: SELinux
##########################################################################################

test_selinux() {
    echo ""
    echo "[Test 8] SELinux"
    echo "----------------"
    
    # Check SELinux status
    if command -v getenforce >/dev/null 2>&1; then
        SELINUX_MODE=$(getenforce)
        test_info "SELinux mode: $SELINUX_MODE"
        
        # Check for denials
        DENIAL_COUNT=$(dmesg 2>/dev/null | grep -c "avc.*denied.*webserver" || echo 0)
        if [ "$DENIAL_COUNT" -eq 0 ]; then
            test_pass "No SELinux denials found"
        else
            test_fail "Found $DENIAL_COUNT SELinux denials"
        fi
    else
        test_info "SELinux tools not available"
    fi
}

##########################################################################################
# Test 9: Auto-Restart
##########################################################################################

test_auto_restart() {
    echo ""
    echo "[Test 9] Auto-Restart (Destructive)"
    echo "-----------------------------------"
    
    echo "  This test will kill the web server and verify auto-restart"
    echo "  Press Enter to continue, or Ctrl+C to skip..."
    read -r
    
    # Get current PID
    OLD_PID=$(pgrep httpd | head -n 1)
    if [ -z "$OLD_PID" ]; then
        test_fail "Web server not running, cannot test auto-restart"
        return
    fi
    
    test_info "Current httpd PID: $OLD_PID"
    
    # Kill web server
    kill -9 "$OLD_PID"
    test_info "Killed httpd (PID: $OLD_PID)"
    
    # Wait for watchdog to restart (max 20 seconds)
    test_info "Waiting for auto-restart (max 20s)..."
    WAIT_COUNT=0
    while [ $WAIT_COUNT -lt 20 ]; do
        sleep 1
        WAIT_COUNT=$((WAIT_COUNT + 1))
        
        NEW_PID=$(pgrep httpd | head -n 1)
        if [ -n "$NEW_PID" ] && [ "$NEW_PID" != "$OLD_PID" ]; then
            test_pass "Web server auto-restarted (new PID: $NEW_PID) after ${WAIT_COUNT}s"
            return
        fi
    done
    
    test_fail "Web server did not auto-restart within 20 seconds"
}

##########################################################################################
# Test 10: Management Tools
##########################################################################################

test_management_tools() {
    echo ""
    echo "[Test 10] Management Tools"
    echo "--------------------------"
    
    # Check if protect_manager.sh exists
    if [ -f "$MODDIR/scripts/protect_manager.sh" ]; then
        test_pass "protect_manager.sh exists"
        
        # Check if executable
        if [ -x "$MODDIR/scripts/protect_manager.sh" ]; then
            test_pass "protect_manager.sh is executable"
        else
            test_fail "protect_manager.sh is not executable"
        fi
    else
        test_fail "protect_manager.sh not found"
    fi
    
    # Check other scripts
    for script in webserver_watchdog.sh protection_daemon.sh logcat_monitor.sh; do
        if [ -f "$MODDIR/scripts/$script" ]; then
            test_pass "$script exists"
        else
            test_fail "$script not found"
        fi
    done
}

##########################################################################################
# Main Test Execution
##########################################################################################

# Check if running as root
if [ "$(id -u)" != "0" ]; then
    echo "Error: This script must be run as root"
    echo "Usage: su -c $0"
    exit 1
fi

print_header

# Run all tests
test_module_installation
test_web_server
test_process_protection
test_network_configuration
test_system_properties
test_logging
test_memory_management
test_selinux
test_auto_restart
test_management_tools

##########################################################################################
# Test Summary
##########################################################################################

echo ""
echo "=========================================="
echo "  Test Summary"
echo "=========================================="
echo ""
echo "  Tests Passed: $TESTS_PASSED"
echo "  Tests Failed: $TESTS_FAILED"
echo "  Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "  ✓ All tests passed!"
    echo ""
    exit 0
else
    echo "  ✗ Some tests failed"
    echo ""
    echo "  Check logs: $LOGFILE"
    echo "  Review failed tests above"
    echo ""
    exit 1
fi
