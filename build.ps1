# WebServer Guard Module Builder for Windows
Write-Host "Building WebServer Guard Module..." -ForegroundColor Cyan

$OUTPUT_ZIP = "WebServerGuard_v1.0.0.zip"

$FILES = @(
    "META-INF/com/google/android/updater-script",
    "module.prop",
    "customize.sh",
    "post-fs-data.sh",
    "service.sh",
    "uninstall.sh",
    "system.prop",
    "sepolicy.rule",
    "webui.json",
    "scripts/webserver_watchdog.sh",
    "scripts/protection_daemon.sh",
    "scripts/logcat_monitor.sh",
    "scripts/protect_manager.sh",
    "webroot/index.html",
    "webroot/manage.html",
    "webroot/cgi-bin/status.sh",
    "webroot/cgi-bin/api.sh"
)

Write-Host "Validating files..."
foreach ($file in $FILES) {
    if (-not (Test-Path $file)) {
        Write-Host "Missing: $file" -ForegroundColor Red
        exit 1
    }
}

if (Test-Path $OUTPUT_ZIP) {
    Remove-Item $OUTPUT_ZIP -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipFile = [System.IO.Path]::GetFullPath($OUTPUT_ZIP)
$zip = [System.IO.Compression.ZipFile]::Open($zipFile, 'Create')

try {
    foreach ($file in $FILES) {
        $fullPath = Join-Path (Get-Location) $file
        $entryName = $file -replace '\\', '/'
        Write-Host "Adding: $entryName"
        $entry = $zip.CreateEntry($entryName, 'Optimal')
        $entryStream = $entry.Open()
        $fileStream = [System.IO.File]::OpenRead($fullPath)
        $fileStream.CopyTo($entryStream)
        $fileStream.Close()
        $entryStream.Close()
    }
} finally {
    $zip.Dispose()
}

$zipSize = (Get-Item $OUTPUT_ZIP).Length / 1KB
Write-Host ""
Write-Host "Build complete: $OUTPUT_ZIP ($([math]::Round($zipSize, 2)) KB)" -ForegroundColor Green
