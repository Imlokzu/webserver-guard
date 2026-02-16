# 🛡️ WebServer Guard - Magisk Module

[![Magisk](https://img.shields.io/badge/Magisk-20.4%2B-00B39B?style=flat-square&logo=magisk)](https://github.com/topjohnwu/Magisk)
[![Android](https://img.shields.io/badge/Android-5.0%2B-3DDC84?style=flat-square&logo=android)](https://www.android.com/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-brightgreen?style=flat-square)](https://github.com/imlokzu/webserver-guard/releases)

Transform your rooted Android device into a **persistent web server host** with advanced process protection. Prevents Android from killing Termux and other critical processes, while hosting a web server on port 80.

## ✨ Features

### 🌐 Web Server
- Persistent web server on port 80 (with automatic 8080 fallback)
- Auto-restart watchdog monitors and restarts killed processes
- BusyBox httpd with custom web root
- iptables port forwarding (80 → 8080)
- Real-time status dashboard

### 🛡️ Process Protection Engine
- Protects any process from Android's Low Memory Killer
- Automatic Termux protection
- OOM score adjustment (-1000 = maximum protection)
- Battery optimization bypass
- Doze mode whitelist
- Continuous monitoring and re-protection (every 30s)
- CLI management tool

### ⚙️ Advanced Features
- Low Memory Killer (LMK) parameter tuning
- ZRAM activation (512MB compressed swap)
- Swappiness optimization
- Logcat monitoring for kill events
- Multi-architecture support (arm, arm64, x86, x64, riscv64)
- SELinux compatible
- Comprehensive logging

## 📦 Installation

### Method 1: Via Magisk Manager (Recommended)

1. Download `WebServerGuard_v1.0.0.zip` from [Releases](https://github.com/imlokzu/webserver-guard/releases)
2. Open Magisk Manager
3. Go to **Modules** → **Install from storage**
4. Select the ZIP file
5. Reboot device

### Method 2: Via ADB

```bash
adb push WebServerGuard_v1.0.0.zip /sdcard/
adb shell su -c "magisk --install-module /sdcard/WebServerGuard_v1.0.0.zip"
adb reboot
```

### Method 3: Via Termux

```bash
su
magisk --install-module /sdcard/WebServerGuard_v1.0.0.zip
reboot
```

## 🚀 Quick Start

After installation and reboot:

### Access Web Server

```bash
# From device
curl http://localhost

# From network
curl http://YOUR_DEVICE_IP
```

### Manage Protected Processes

```bash
# Interactive CLI
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh

# View status
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh status

# Add process protection
su -c /data/adb/modules/android.webserver.guard/scripts/protect_manager.sh add com.example.app
```

### Check Logs

```bash
su -c cat /data/local/tmp/webserver_module.log
```

## 📖 Documentation

- [Installation Guide](INSTALLATION.md) - Detailed installation instructions
- [Technical Documentation](TECHNICAL.md) - Architecture and internals
- [Quick Start Guide](QUICKSTART.md) - 5-minute setup
- [Deployment Checklist](DEPLOYMENT_CHECKLIST.md) - Pre-release testing

## 🎯 Use Cases

- **Persistent Web Hosting**: Host websites directly from your Android device
- **Development Server**: Run Node.js, Python, or other web servers 24/7
- **SSH Server**: Keep SSH sessions alive indefinitely
- **Background Tasks**: Run scripts and services without interruption
- **Termux Protection**: Prevent Android from killing Termux processes
- **API Hosting**: Host REST APIs on your phone

## 🔧 How It Works

### Process Protection

1. Sets `/proc/<pid>/oom_score_adj` to `-1000` (maximum protection)
2. Monitors processes every 30 seconds
3. Adds processes to Doze whitelist
4. Disables battery optimization
5. Adjusts LMK parameters to be less aggressive

### Web Server

```
Port 80 Request
    ↓
iptables NAT (80 → 8080)
    ↓
BusyBox httpd (port 8080)
    ↓
Serves: /data/adb/modules/android.webserver.guard/webroot/
    ↓
Watchdog monitors every 15s
    ↓
Auto-restart if killed
```

## 📊 Performance

- **CPU Usage**: < 1% average
- **Memory Usage**: ~10 MB + 512 MB ZRAM (compressed)
- **Battery Impact**: ~1-2% per hour (idle), ~5-10% (active)

## 🔒 Security

- Module requires root access
- Web server accessible to all apps on device
- Protected processes cannot be killed by normal means
- Use firewall rules to restrict network access if needed

## 🐛 Troubleshooting

### Web Server Not Accessible

```bash
# Check if httpd is running
su -c "ps -A | grep httpd"

# Check port binding
su -c "netstat -tlnp | grep 8080"

# Check logs
su -c "cat /data/local/tmp/webserver_module.log"
```

### Process Still Being Killed

```bash
# Verify OOM score
PID=$(pgrep -f <process_name>)
su -c "cat /proc/$PID/oom_score_adj"
# Should show: -1000

# Check if daemon is running
su -c "ps -A | grep protection_daemon"
```

### Module Not Loading

```bash
# Check module status
su -c "ls -la /data/adb/modules/android.webserver.guard/"

# Check for disable flag
su -c "ls /data/adb/modules/android.webserver.guard/disable"
# Should not exist
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Changelog

### v1.0.0 (2024)
- Initial release
- Web server on port 80
- Process protection engine
- Termux protection
- OOM score management
- Battery optimization bypass
- LMK tuning
- ZRAM support
- CLI management tool

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Credits

- [Magisk](https://github.com/topjohnwu/Magisk) by topjohnwu
- [BusyBox](https://busybox.net/) project
- Android root community
- XDA Developers

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/imlokzu/webserver-guard/issues)
- **Discussions**: [GitHub Discussions](https://github.com/imlokzu/webserver-guard/discussions)
- **XDA Thread**: [Link to XDA thread]

## ⚠️ Disclaimer

This module requires root access and modifies system behavior. Use at your own risk. Always backup your data before installing any Magisk module.

## 🌟 Star History

If this module helped you, please consider giving it a star! ⭐

---

**Made with ❤️ for the Android root community**
