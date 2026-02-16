# Contributing to WebServer Guard

Thank you for considering contributing to WebServer Guard! This document provides guidelines for contributing to the project.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Device information**: Model, Android version, Magisk version
- **Module version**: Which version of WebServer Guard
- **Steps to reproduce**: Clear steps to reproduce the issue
- **Expected behavior**: What you expected to happen
- **Actual behavior**: What actually happened
- **Logs**: Output from `/data/local/tmp/webserver_module.log`

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear description**: What enhancement you'd like to see
- **Use case**: Why this enhancement would be useful
- **Possible implementation**: If you have ideas on how to implement it

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly on your device
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Code Style

- Use 4 spaces for indentation in shell scripts
- Add comments for complex logic
- Follow existing code style
- Test on multiple architectures if possible

### Testing

Before submitting a PR:

1. Test installation via Magisk Manager
2. Test on at least one device
3. Verify logs show no errors
4. Test process protection functionality
5. Test web server functionality
6. Run the test suite: `test_module.sh`

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit first line to 72 characters
- Reference issues and pull requests

Example:
```
Add HTTPS support for web server

- Implement SSL certificate loading
- Add iptables rules for port 443
- Update documentation

Fixes #123
```

## Development Setup

### Prerequisites

- Rooted Android device with Magisk
- ADB tools
- Text editor
- Basic shell scripting knowledge

### Building

```bash
# Make build script executable
chmod +x build.sh

# Build the module
./build.sh
```

### Testing

```bash
# Install on device
adb push WebServerGuard_v1.0.0.zip /sdcard/
adb shell su -c "magisk --install-module /sdcard/WebServerGuard_v1.0.0.zip"
adb reboot

# Run tests
adb shell su -c "/data/adb/modules/android.webserver.guard/test_module.sh"
```

## Project Structure

```
webserver-guard/
├── META-INF/              # Magisk installer
├── scripts/               # Helper scripts
├── webroot/              # Web server content
├── module.prop           # Module metadata
├── customize.sh          # Installation script
├── post-fs-data.sh      # Early boot script
├── service.sh           # Late boot script
├── uninstall.sh         # Cleanup script
├── system.prop          # System properties
├── sepolicy.rule        # SELinux rules
└── README.md            # Documentation
```

## Questions?

Feel free to open an issue for any questions about contributing!

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
