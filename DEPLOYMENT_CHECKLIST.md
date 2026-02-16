# WebServer Guard Module - Deployment Checklist

## Pre-Build Checklist

### File Validation
- [ ] All required files present
- [ ] module.prop has correct metadata
- [ ] Version numbers match across files
- [ ] No syntax errors in shell scripts
- [ ] Line endings are Unix (LF, not CRLF)
- [ ] File permissions are correct

### Script Validation
- [ ] customize.sh is executable (755)
- [ ] post-fs-data.sh is executable (755)
- [ ] service.sh is executable (755)
- [ ] uninstall.sh is executable (755)
- [ ] All scripts in scripts/ are executable (755)
- [ ] All scripts use proper shebang (#!/system/bin/sh)

### Content Validation
- [ ] webroot/index.html exists and is valid HTML
- [ ] META-INF/com/google/android/updater-script contains #MAGISK
- [ ] sepolicy.rule has valid SELinux rules
- [ ] system.prop has valid properties
- [ ] No hardcoded paths (use MODDIR=${0%/*})

## Build Process

### Build Steps
- [ ] Run build.sh script
- [ ] Build completes without errors
- [ ] ZIP file created successfully
- [ ] ZIP file size is reasonable (~50-100 KB)

### ZIP Validation
- [ ] Verify ZIP structure with `unzip -l`
- [ ] module.prop is in root of ZIP
- [ ] META-INF structure is correct
- [ ] All scripts are included
- [ ] webroot directory is included
- [ ] Documentation files are included

### Build Output
- [ ] WebServerGuard_v1.0.0.zip created
- [ ] File size noted
- [ ] Build log reviewed for warnings

## Pre-Installation Testing

### Device Preparation
- [ ] Device is rooted
- [ ] Magisk is installed (v20.4+)
- [ ] Android version is 5.0+ (API 21+)
- [ ] ADB is connected (if using ADB method)
- [ ] Device has sufficient storage

### Backup
- [ ] Backup current Magisk modules
- [ ] Backup important data
- [ ] Note current system state

## Installation

### Installation Method
- [ ] Choose installation method (Magisk Manager or ADB)
- [ ] Push ZIP to device
- [ ] Install module
- [ ] Check for installation errors
- [ ] Reboot device

### Post-Reboot Verification
- [ ] Device boots successfully
- [ ] Magisk is still working
- [ ] Module appears in Magisk Manager
- [ ] Module is enabled (no disable flag)

## Functional Testing

### Module Status
- [ ] Module directory exists: `/data/adb/modules/android.webserver.guard/`
- [ ] All files are present
- [ ] Permissions are correct
- [ ] Logs are being created

### Web Server
- [ ] httpd process is running
- [ ] Port 8080 is bound
- [ ] HTTP request to localhost works
- [ ] Web page displays correctly
- [ ] Port 80 redirects to 8080 (if iptables available)

### Process Protection
- [ ] protection_daemon.sh is running
- [ ] webserver_watchdog.sh is running
- [ ] Termux is protected (OOM: -1000)
- [ ] protected.list file exists

### System Integration
- [ ] System properties are set
- [ ] iptables rules are applied (if available)
- [ ] SELinux is not blocking (check denials)
- [ ] Logs show no errors

## Advanced Testing

### Auto-Restart Test
- [ ] Kill httpd process
- [ ] Wait 20 seconds
- [ ] Verify httpd restarted automatically
- [ ] Check new PID is different
- [ ] Verify OOM score is -1000

### Process Protection Test
- [ ] Add test process to protected.list
- [ ] Verify process gets protected
- [ ] Check OOM score is -1000
- [ ] Remove process from list
- [ ] Verify protection removed

### Memory Management
- [ ] LMK parameters are adjusted
- [ ] ZRAM is enabled (if available)
- [ ] Swappiness is set to 100
- [ ] No memory-related errors in logs

### Network Testing
- [ ] Test from localhost: `curl http://localhost`
- [ ] Test from network: `curl http://<device-ip>`
- [ ] Test port 80: `curl http://localhost:80`
- [ ] Test port 8080: `curl http://localhost:8080`

## Management Tools

### CLI Manager
- [ ] protect_manager.sh is executable
- [ ] Interactive mode works
- [ ] Can list protected processes
- [ ] Can add process protection
- [ ] Can remove process protection
- [ ] Can view status
- [ ] Command-line mode works

### Logging
- [ ] Main log exists: `/data/local/tmp/webserver_module.log`
- [ ] Log has recent entries
- [ ] No ERROR messages in log
- [ ] Log rotation works (if implemented)

## Performance Testing

### Resource Usage
- [ ] CPU usage is < 1% average
- [ ] Memory usage is reasonable (~10 MB)
- [ ] Battery drain is acceptable
- [ ] No performance degradation

### Stress Testing
- [ ] Multiple HTTP requests handled
- [ ] Process kill/restart loop works
- [ ] Memory pressure test (if possible)
- [ ] Long-term stability (24+ hours)

## Documentation Review

### User Documentation
- [ ] README.md is complete and accurate
- [ ] INSTALLATION.md has clear instructions
- [ ] QUICKSTART.md is easy to follow
- [ ] All examples work as documented

### Technical Documentation
- [ ] TECHNICAL.md is accurate
- [ ] STRUCTURE.txt matches actual structure
- [ ] PROJECT_SUMMARY.md is up to date
- [ ] Code comments are clear

## Security Review

### Security Checks
- [ ] No hardcoded credentials
- [ ] No sensitive information in logs
- [ ] SELinux rules are minimal and necessary
- [ ] File permissions are restrictive
- [ ] No unnecessary root access

### Attack Surface
- [ ] Web server only serves intended content
- [ ] No directory traversal vulnerabilities
- [ ] Protected processes are legitimate
- [ ] No privilege escalation risks

## Compatibility Testing

### Architecture Testing
- [ ] Test on ARM device (if available)
- [ ] Test on ARM64 device (if available)
- [ ] Test on x86 device (if available)
- [ ] Verify architecture detection works

### Android Version Testing
- [ ] Test on Android 5.0 (API 21) if possible
- [ ] Test on Android 8.0 (API 26)
- [ ] Test on Android 10 (API 29)
- [ ] Test on Android 11+ (API 30+)

### Device Testing
- [ ] Test on stock Android
- [ ] Test on custom ROM (if available)
- [ ] Test on different OEMs (Samsung, Xiaomi, etc.)

## Uninstallation Testing

### Uninstall Process
- [ ] Remove module from Magisk Manager
- [ ] Reboot device
- [ ] Verify module directory removed
- [ ] Verify services stopped
- [ ] Verify iptables rules removed
- [ ] Verify system properties reset
- [ ] Verify no leftover files (except logs)

### Clean State
- [ ] Device boots normally
- [ ] No errors in logcat
- [ ] Magisk still works
- [ ] Can reinstall module

## Final Checks

### Pre-Release
- [ ] All tests passed
- [ ] No critical issues found
- [ ] Documentation is complete
- [ ] Version numbers are correct
- [ ] Changelog is updated

### Release Package
- [ ] ZIP file is final version
- [ ] MD5/SHA256 checksum generated
- [ ] Release notes prepared
- [ ] Installation instructions ready

### Distribution
- [ ] Upload to distribution platform
- [ ] Verify download link works
- [ ] Test installation from download
- [ ] Announce release (if applicable)

## Post-Release Monitoring

### User Feedback
- [ ] Monitor for installation issues
- [ ] Track reported bugs
- [ ] Collect feature requests
- [ ] Respond to support questions

### Issue Tracking
- [ ] Document known issues
- [ ] Prioritize bug fixes
- [ ] Plan updates
- [ ] Maintain changelog

## Rollback Plan

### If Issues Found
- [ ] Document the issue
- [ ] Determine severity
- [ ] Prepare hotfix if critical
- [ ] Notify users if necessary
- [ ] Provide uninstall instructions

### Emergency Procedures
- [ ] How to disable module without uninstall
- [ ] How to boot to safe mode
- [ ] How to remove module manually
- [ ] How to restore system state

## Success Criteria

### Must Have (Critical)
- [x] Module installs without errors
- [x] Device boots successfully
- [x] Web server runs and is accessible
- [x] Process protection works
- [x] No system instability
- [x] Clean uninstallation

### Should Have (Important)
- [x] Auto-restart works
- [x] Management tools work
- [x] Documentation is complete
- [x] Logging is comprehensive
- [x] Performance is acceptable

### Nice to Have (Optional)
- [ ] Works on all architectures
- [ ] Works on all Android versions
- [ ] No SELinux denials
- [ ] Perfect battery efficiency
- [ ] Zero resource overhead

## Sign-Off

### Developer Sign-Off
- [ ] Code reviewed
- [ ] Tests passed
- [ ] Documentation complete
- [ ] Ready for release

### Tester Sign-Off
- [ ] Installation tested
- [ ] Functionality verified
- [ ] Performance acceptable
- [ ] No critical issues

### Release Manager Sign-Off
- [ ] Package validated
- [ ] Distribution ready
- [ ] Support prepared
- [ ] Approved for release

---

## Notes

Use this checklist for every release:
1. Print or copy this checklist
2. Check off items as you complete them
3. Don't skip items marked as critical
4. Document any issues found
5. Only release when all critical items are checked

## Version History

- v1.0.0 (2024) - Initial checklist

---

**Checklist Status**: Ready for use
**Last Updated**: 2024
