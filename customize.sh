#!/system/bin/sh

##########################################################################################
# WebServer Guard & Process Protector - Installation Script
# Magisk Module Installer
##########################################################################################

# SKIPUNZIP=1  # Let Magisk handle extraction automatically

ui_print "=========================================="
ui_print "  WebServer Guard & Process Protector"
ui_print "=========================================="
ui_print ""
ui_print "Installing module..."
ui_print "Architecture: $ARCH"
ui_print "API Level: $API"
ui_print "Magisk Version: $MAGISK_VER ($MAGISK_VER_CODE)"
ui_print ""

##########################################################################################
# Architecture Detection
##########################################################################################

case $ARCH in
    arm|arm64|x86|x64|riscv64)
        ui_print "✓ Supported architecture: $ARCH"
        ;;
    *)
        abort "✗ Unsupported architecture: $ARCH"
        ;;
esac

##########################################################################################
# API Level Check
##########################################################################################

if [ "$API" -lt 21 ]; then
    abort "✗ Android 5.0+ (API 21+) required. Current: API $API"
fi

ui_print "✓ API level check passed"

##########################################################################################
# Create Directory Structure
##########################################################################################

ui_print "Creating module directories..."

mkdir -p "$MODPATH/system/bin"
mkdir -p "$MODPATH/scripts"
mkdir -p "$MODPATH/webroot"

##########################################################################################
# Set Permissions
##########################################################################################

ui_print "Setting permissions..."

# Module scripts
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

# Helper scripts (will be created by module)
set_perm_recursive "$MODPATH/scripts" 0 0 0755 0644

##########################################################################################
# Create Initial Configuration
##########################################################################################

ui_print "Creating default configuration..."

# Create protected process list (empty by default)
touch "$MODPATH/protected.list"
set_perm "$MODPATH/protected.list" 0 0 0644

# Create default web root index
cat > "$MODPATH/webroot/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>WebServer Guard Active</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; background: #f0f0f0; }
        .container { background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #4CAF50; }
        .status { color: #2196F3; font-weight: bold; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🛡️ WebServer Guard Active</h1>
        <p class="status">✓ Web server is running</p>
        <p>This device is protected by WebServer Guard module.</p>
        <p><small>Powered by Magisk + BusyBox</small></p>
    </div>
</body>
</html>
EOF

set_perm "$MODPATH/webroot/index.html" 0 0 0644

##########################################################################################
# Installation Complete
##########################################################################################

ui_print ""
ui_print "=========================================="
ui_print "  Installation Complete!"
ui_print "=========================================="
ui_print ""
ui_print "Module features:"
ui_print "  • Web server on port 80"
ui_print "  • Process protection engine"
ui_print "  • Termux protection"
ui_print "  • OOM score adjustment"
ui_print "  • Battery optimization bypass"
ui_print ""
ui_print "After reboot:"
ui_print "  1. Check logs: /data/local/tmp/webserver_module.log"
ui_print "  2. Manage protected processes:"
ui_print "     su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh"
ui_print "  3. Test web server: http://localhost"
ui_print ""
ui_print "Reboot required to activate module."
ui_print ""
