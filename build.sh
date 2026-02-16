#!/bin/bash

##########################################################################################
# WebServer Guard Module - Build Script
# Creates installable Magisk module ZIP
##########################################################################################

set -e  # Exit on error

MODULE_NAME="WebServerGuard"
VERSION=$(grep "^version=" module.prop | cut -d'=' -f2)
OUTPUT_ZIP="${MODULE_NAME}_v${VERSION}.zip"

echo "=========================================="
echo "  Building WebServer Guard Module"
echo "=========================================="
echo ""
echo "Version: $VERSION"
echo "Output: $OUTPUT_ZIP"
echo ""

##########################################################################################
# Validate Files
##########################################################################################

echo "[1/5] Validating files..."

REQUIRED_FILES=(
    "module.prop"
    "customize.sh"
    "post-fs-data.sh"
    "service.sh"
    "uninstall.sh"
    "system.prop"
    "sepolicy.rule"
    "META-INF/com/google/android/updater-script"
    "scripts/webserver_watchdog.sh"
    "scripts/protection_daemon.sh"
    "scripts/logcat_monitor.sh"
    "scripts/protect_manager.sh"
    "webroot/index.html"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "ERROR: Missing required file: $file"
        exit 1
    fi
done

echo "✓ All required files present"

##########################################################################################
# Check Line Endings
##########################################################################################

echo "[2/5] Checking line endings..."

# Ensure Unix line endings (LF) for critical files
for file in module.prop customize.sh post-fs-data.sh service.sh uninstall.sh; do
    if file "$file" | grep -q "CRLF"; then
        echo "WARNING: $file has Windows line endings (CRLF)"
        echo "Converting to Unix line endings (LF)..."
        
        # Convert CRLF to LF
        if command -v dos2unix >/dev/null 2>&1; then
            dos2unix "$file"
        else
            sed -i 's/\r$//' "$file"
        fi
    fi
done

echo "✓ Line endings verified"

##########################################################################################
# Set Permissions
##########################################################################################

echo "[3/5] Setting permissions..."

chmod 644 module.prop
chmod 644 system.prop
chmod 644 sepolicy.rule
chmod 755 customize.sh
chmod 755 post-fs-data.sh
chmod 755 service.sh
chmod 755 uninstall.sh
chmod 755 scripts/*.sh
chmod 644 webroot/index.html

echo "✓ Permissions set"

##########################################################################################
# Create ZIP
##########################################################################################

echo "[4/5] Creating ZIP archive..."

# Remove old ZIP if exists
rm -f "$OUTPUT_ZIP"

# Create ZIP with proper structure
zip -r "$OUTPUT_ZIP" \
    META-INF/ \
    module.prop \
    customize.sh \
    post-fs-data.sh \
    service.sh \
    uninstall.sh \
    system.prop \
    sepolicy.rule \
    scripts/ \
    webroot/ \
    README.md \
    INSTALLATION.md \
    TECHNICAL.md \
    -x "*.git*" "*.DS_Store" "*build.sh" "*docs.md"

echo "✓ ZIP created: $OUTPUT_ZIP"

##########################################################################################
# Verify ZIP
##########################################################################################

echo "[5/5] Verifying ZIP contents..."

# Check ZIP structure
if ! unzip -l "$OUTPUT_ZIP" | grep -q "module.prop"; then
    echo "ERROR: module.prop not found in ZIP"
    exit 1
fi

if ! unzip -l "$OUTPUT_ZIP" | grep -q "META-INF/com/google/android/updater-script"; then
    echo "ERROR: updater-script not found in ZIP"
    exit 1
fi

# Show ZIP contents
echo ""
echo "ZIP Contents:"
unzip -l "$OUTPUT_ZIP" | head -30

# Get ZIP size
ZIP_SIZE=$(du -h "$OUTPUT_ZIP" | cut -f1)

echo ""
echo "✓ ZIP verified"

##########################################################################################
# Build Complete
##########################################################################################

echo ""
echo "=========================================="
echo "  Build Complete!"
echo "=========================================="
echo ""
echo "Module: $MODULE_NAME v$VERSION"
echo "File: $OUTPUT_ZIP"
echo "Size: $ZIP_SIZE"
echo ""
echo "Installation:"
echo "  1. Push to device: adb push $OUTPUT_ZIP /sdcard/"
echo "  2. Install via Magisk Manager"
echo "  3. Reboot device"
echo ""
echo "Or install via ADB:"
echo "  adb shell su -c \"magisk --install-module /sdcard/$OUTPUT_ZIP\""
echo ""
