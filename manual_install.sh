#!/system/bin/sh

##########################################################################################
# WebServer Guard - Manual Installation from Termux
##########################################################################################

echo "=========================================="
echo "  WebServer Guard - Manual Install"
echo "=========================================="
echo ""

# Check root
if [ "$(id -u)" != "0" ]; then
    echo "ERROR: Must run as root"
    echo "Run: su"
    echo "Then: sh /sdcard/manual_install.sh"
    exit 1
fi

MODDIR="/data/adb/modules/android.webserver.guard"

echo "[1/5] Creating module directory..."
mkdir -p "$MODDIR/scripts"
mkdir -p "$MODDIR/webroot/cgi-bin"

echo "[2/5] Copying files from /sdcard/module_files/..."
if [ ! -d "/sdcard/module_files" ]; then
    echo "ERROR: /sdcard/module_files not found"
    echo "Please extract the ZIP to /sdcard/module_files first"
    exit 1
fi

cp /sdcard/module_files/module.prop "$MODDIR/"
cp /sdcard/module_files/post-fs-data.sh "$MODDIR/"
cp /sdcard/module_files/service.sh "$MODDIR/"
cp /sdcard/module_files/uninstall.sh "$MODDIR/"
cp /sdcard/module_files/system.prop "$MODDIR/"
cp /sdcard/module_files/sepolicy.rule "$MODDIR/"
cp /sdcard/module_files/scripts/*.sh "$MODDIR/scripts/"
cp /sdcard/module_files/webroot/index.html "$MODDIR/webroot/"
cp /sdcard/module_files/webroot/cgi-bin/status.sh "$MODDIR/webroot/cgi-bin/"

echo "[3/5] Setting permissions..."
chmod 755 "$MODDIR/post-fs-data.sh"
chmod 755 "$MODDIR/service.sh"
chmod 755 "$MODDIR/uninstall.sh"
chmod 755 "$MODDIR/scripts"/*.sh
chmod 755 "$MODDIR/webroot/cgi-bin/status.sh"
chmod 644 "$MODDIR/module.prop"
chmod 644 "$MODDIR/system.prop"
chmod 644 "$MODDIR/sepolicy.rule"

echo "[4/5] Creating protected.list..."
touch "$MODDIR/protected.list"
echo "com.termux" > "$MODDIR/protected.list"

echo "[5/5] Protecting Termux NOW..."
TERMUX_PID=$(pgrep -f com.termux | head -n 1)
if [ -n "$TERMUX_PID" ]; then
    echo -1000 > /proc/$TERMUX_PID/oom_score_adj 2>/dev/null
    echo "✓ Termux protected (PID: $TERMUX_PID, OOM: -1000)"
else
    echo "! Termux not running"
fi

# Disable battery optimization
dumpsys deviceidle whitelist +com.termux

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Module installed to: $MODDIR"
echo "Termux is now protected from being killed"
echo ""
echo "Reboot to activate full module features:"
echo "  - Web server on port 80"
echo "  - Automatic protection daemon"
echo "  - Watchdog auto-restart"
echo ""
echo "Or manually start services now:"
echo "  $MODDIR/service.sh"
echo ""
