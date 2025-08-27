# Flutter Device Setup Guide

Comprehensive guide for running the Flutter app on different devices and simulators.

## Important: WiFi Requirements

**For wireless connections:** Your laptop and mobile device **MUST be on the same WiFi network**.

| Connection Type | WiFi Required | Notes |
|----------------|---------------|-------|
| **iOS Simulator** | No | Runs locally on your laptop |
| **Android USB** | No | Direct cable connection |
| **iPhone USB** | No | Direct cable connection |
| **Android WiFi** | **Same WiFi** | Laptop + Android on same network |
| **iPhone WiFi** | **Same WiFi** | Laptop + iPhone on same network |

**Tip:** Use USB connections for reliable development. Use WiFi for cable-free convenience.

## Quick Start

Choose your preferred setup method:

- **[iOS Simulator](#ios-simulator)** - Fastest for UI development
- **[Physical Devices](#physical-devices)** - Best for testing performance and hardware features
- **[Troubleshooting](#troubleshooting)** - Solutions for common issues

## iOS Simulator

### Start iOS Simulator
```bash
# Step 1: Start iOS simulator
flutter emulators --launch apple_ios_simulator
# If Flutter can’t find the emulator, run 'open -a Simulator'

# Step 2: List available devices to get device ID
flutter devices
# Example output: iPhone 16 Pro Max (mobile) • 40570266-8531-471B-8515-D889A7A6E2DF • ios

# Step 3: Run with specific device ID  
flutter run -d 40570266-8531-471B-8515-D889A7A6E2DF (Change to your devices ID)
```

## Physical Devices

### 1. Device Preparation (First Time Setup Only)

#### Android Phone (One-time configuration)
- **Settings** → **About phone** → Tap **"Build number"** 7 times
- Enable **"USB debugging"** in **Developer options**
- **For wireless:** Also enable **"Wireless debugging"** in **Developer options**

#### iPhone (One-time configuration)
- Enable **Developer Mode** (iOS 16+): **Settings** → **Privacy & Security** → **Developer Mode**

### 2. Wired Connection (Recommended)

#### Android (USB-C)
```bash
# 1. Connect USB-C cable, list available android device ID
flutter devices
# Example output: EB2103 (mobile) • 13da7b17 • android-arm64 • Android 13 (API 33)

# 2. Run with specific device ID
flutter run -d 13da7b17
```

#### iPhone (Lightning/USB-C)
```bash
# FIRST TIME ONLY: Code signing and Xcode required for physical iphone devices! See "IOS_CODE_SIGNING.md" guide, iOS Simulator doesn't require code signing.

# 1. Connect Lightning/USB-C cable, list available iPhone device ID
flutter devices
# Example output: XXX – iPhone (mobile) • 00008110-001830342EBA301A • ios • iOS 18.3.1 22D72

# 2. Run with specific device ID
flutter run -d 00008110-001830342EBA301A
```

### 3. Wireless Connection (Advanced)

#### Android WiFi Debugging

##### Initial Setup (First Time Only) - Configure Wireless Debugging

```bash
# 1. Connect USB-C cable first → accept debugging on phone
adb devices  # Verify phone is visible

# 2. Enable TCP/IP mode (enables wireless debugging)
adb tcpip 5555

# 3. Find phone's IP address:
# Phone: Settings → WiFi → Tap network → Check IP

# 4. Connect wirelessly (replace with your IP)
adb connect [YOUR-IP-ADDRESS]:5555
# Example: adb connect 192.168.68.100:5555

# 5. Disconnect USB-C cable

# 6. Verify wireless connection
flutter devices
# Example output: EB2103 (mobile)           • 192.168.1.139:5555        • android-arm64 • Android 13 (API 33)

# 7. Run with specific device ID
flutter run -d 192.168.1.139:5555
```

##### When You Need to Run Commands Again

**YES - `adb connect` needed often:**
- **Different WiFi networks** → New IP address → Run `adb connect [NEW-IP]:5555`
- **Computer goes to sleep** → Connection breaks → Run `adb connect [IP]:5555`
- **After inactivity (10-15 min)** → Timeout → Run `adb connect [IP]:5555`
- **Phone in deep sleep** → Connection breaks → Run `adb connect [IP]:5555`
- **Phone restarts** → Connection breaks → Run `adb connect [IP]:5555`

**NO - DON'T need to run `adb tcpip 5555` again:**
- Setting is saved until phone restarts
- Only `adb connect` needed for all other reconnections

**IMPORTANT:** WiFi connection breaks easily, so `adb connect` is needed often - this is normal!

##### Reliable WiFi Development Process (use every time)

```bash
# 1. Find IP address on phone:
# Phone: Settings → WiFi → Tap network → Check IP

# 2. Connect wirelessly:
adb connect [IP-ADDRESS]:5555

# 3. Run app:
flutter run -d "[IP-ADDRESS]:5555"

# Example complete workflow:
# adb connect 192.168.68.100:5555
# flutter run -d "192.168.68.100:5555"
```

**Best Practice:** Always use this 3-step process instead of relying on history or cache.

##### When Phone Restarts

If phone restarts, you need to do the COMPLETE process again:
```bash
# 1. Connect USB first
adb tcpip 5555

# 2. Disconnect USB, find IP

# 3. Connect wirelessly
adb connect [IP]:5555
```

##### Tips for Smooth WiFi Development
- **Same WiFi** → IP address usually stays the same, but check anyway
- **Different networks** → IP always changes, find new IP on phone
- **Check `adb devices`** → See if connection still exists before flutter run
- **On timeout** → Just run `adb connect` again, no complex troubleshooting

#### iPhone WiFi (Xcode Required)

```bash
# FIRST TIME ONLY: Code signing + Xcode required! See "IOS_CODE_SIGNING.md" guide
# 1. Connect iPhone with Lightning/USB-C cable first
# 2. Open Xcode → Window → Devices and Simulators
# 3. Select iPhone → check "Connect via network"

# THEN (daily use):
flutter devices  # iPhone shows as wireless
# Example output:   XXX – iPhone (mobile) • 00008110-001830342EBA301A • ios          • iOS 18.3.1 22D72

flutter run -d  00008110-001830342EBA301A
```

## iPhone Code Signing Setup

**Required for physical iPhone devices only** (iOS Simulator doesn't need code signing)

For complete iOS code signing setup instructions, see the dedicated guide:

**[IOS_CODE_SIGNING.md](IOS_CODE_SIGNING.md)**

### Quick Summary:
- **One-time setup** per device/project
- Requires Apple ID (free works)
- Configure Bundle ID in Xcode
- Enable Developer Mode on iPhone
- After setup: just run `flutter run -d "iPhone-ID"`

### Common Issues:
- **"Unable to install app"** → See code signing guide
- **"Provisioning profile expired"** → Run `flutter run` again (7-day renewal for free Apple ID)
- **"Developer Mode disabled"** → Re-enable in iPhone Settings

## Troubleshooting

### Check Connected Devices
```bash
flutter devices
# List all available devices

flutter doctor
# Check Flutter setup
```

### Android-Specific Commands
```bash
adb devices
# List Android devices

adb kill-server && adb start-server
# Restart ADB on problems
```

### iOS-Specific Commands
```bash
xcrun simctl list devices
# List iOS simulators

idevice_id -l
# List connected iPhones (requires libimobiledevice)
```

### Clear Cache on Problems
```bash
flutter clean
flutter pub get
flutter run
```

### Common Issues

#### Android: "INSTALL_FAILED_USER_RESTRICTED"
```bash
# Check device permission settings
# Look for "Install via USB" options in Settings → Apps → Permissions
# Different manufacturers place these settings in various locations
```

#### Android: Device Not Showing
```bash
# 1. Ensure USB debugging is enabled
# 2. Try different USB cable or port
# 3. Install appropriate USB drivers for your device
# 4. Restart both computer and device
```

#### WiFi Connection Issues
```bash
# Ensure computer and phone are on SAME WiFi network
# Different WiFi networks typically have separate subnets and firewalls
# Corporate networks may block device communication
```

## Recommended Workflows

### For Daily Development
```bash
# 1. iOS Simulator (fastest for UI development)
flutter run -d "simulator-id"

# 2. Android physical via USB (for performance testing)
flutter run -d "android-device-id"
```

### For Testing on Multiple Devices
```bash
# Test on multiple devices simultaneously:
flutter run -d "device-1" &
flutter run -d "device-2" &
```

### For Wireless Development
```bash
# Android: Setup once, then just:
adb connect [IP-ADDRESS]:5555
flutter run -d "[IP-ADDRESS]:5555"

# iPhone: After Xcode setup:
flutter run -d "iPhone-wireless-id"
```

## Alternative IP Discovery Methods

### Android IP Address Discovery
```bash
# Method 1: Via ADB shell
adb shell ip route | grep wlan

# Method 2: Direct IP command
adb shell ip addr show wlan0 | grep "inet " | cut -d' ' -f6 | cut -d'/' -f1

# Method 3: Check on phone manually
# Settings → WiFi → Tap network name → View IP
```

## Quick Reference

### Essential Commands
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d "device-id"

# Clean and rebuild
flutter clean && flutter pub get && flutter run

# Android wireless setup
adb tcpip 5555
adb connect [IP-ADDRESS]:5555

# Check ADB devices
adb devices
```

### Device ID Examples
```bash
# USB Android: a1b2c3d4
# Wireless Android: 192.168.1.100:5555
# iPhone: 00001111-AAAA2222
# iOS Simulator: 40570266-8531-471B-8515-D889A7A6E2DF
```

---

## Complete Development Setup

For full functionality with IoT features:

```bash
# 1. Start any backend services first (if applicable)
# cd backend && make run

# 2. Run Flutter on desired device (in new terminal)
cd idrott-app
flutter run -d "device-id"
```

---

*For more information about the app itself, see the main [README.md](README.md)*
