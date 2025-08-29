# Network Configuration Guide

This guide helps you configure the Flutter app to connect to your backend server on different devices and platforms.

## ⚡ Quick Setup with .env File (Recommended)

The app now uses a `.env` file for easy configuration. This is the preferred method for all developers.

### 1. Copy the example file:
```bash
cp env.example.txt .env
```

### 2. Edit the `.env` file with your backend configuration:
```env
# For iOS Simulator
BACKEND_URL=http://127.0.0.1:5000

# For Android Emulator  
BACKEND_URL=http://10.0.2.2:5000

# For Physical Devices (replace with your computer's IP)
BACKEND_URL=http://192.168.1.158:5000
```

### 3. Configuration Options:
| Variable | Description | Example |
|----------|-------------|---------|
| `BACKEND_URL` | Full backend URL including protocol and port | `http://192.168.1.158:5000` |
| `BACKEND_HOST` | Just the host IP (app will add port 5000) | `192.168.1.158` |
| `WEBSOCKET_URL` | WebSocket URL (optional, auto-generated if empty) | `ws://192.168.1.158:5000` |
| `DEV_MODE` | Enable development mode | `true` |
| `AUTO_DETECT_BACKEND` | Try to automatically find backend | `false` |

## 🔧 Manual Configuration (Deprecated - Use .env file instead)

> **Note:** This manual configuration method is deprecated. Use the `.env` file method above for easier setup.

### 1. For iOS Simulator
- The app should work automatically with `http://127.0.0.1:5000`
- If not, edit `lib/config.dart` and set:
  ```dart
  static const String backendUrl = 'http://127.0.0.1:5000';
  ```

### 2. For Android Emulator
- The app should work automatically with `http://10.0.2.2:5000`
- If not, edit `lib/config.dart` and set:
  ```dart
  static const String backendUrl = 'http://10.0.2.2:5000';
  ```

### 3. For Physical Devices (Android/iOS)
This is where the "loadcell offline" issue typically occurs on Android devices.

#### Step 1: Find Your Computer's IP Address

**On Windows:**
```cmd
ipconfig
```
Look for "IPv4 Address" (usually starts with 192.168.x.x or 10.0.x.x)

**On Mac/Linux:**
```bash
ifconfig
# or
ip addr show
```
Look for "inet" address (usually starts with 192.168.x.x or 10.0.x.x)

#### Step 2: Configure the App
Edit `lib/config.dart` and set your computer's IP:
```dart
static const String backendUrl = 'http://YOUR_IP_ADDRESS:5000';
```

For example:
```dart
static const String backendUrl = 'http://192.168.1.100:5000';
```

#### Step 3: Make Sure Your Backend is Accessible
Your Flask backend needs to be running and accessible from other devices on your network:

```python
# In your Flask app, make sure it's running on all interfaces:
app.run(host='0.0.0.0', port=5000, debug=True)
```

## 📍 Finding Your Computer's IP Address

### macOS/Linux
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1
```

### Windows
```cmd
ipconfig
```
Look for "IPv4 Address" under your network adapter.

**Common IP ranges:**
- `192.168.x.x` - Most home networks
- `10.0.x.x` - Some home/office networks  
- `172.16.x.x` - Corporate networks

## Configuration File

The main configuration is in `lib/config.dart`:

```dart
class AppConfig {
  // Set this to your backend URL for manual configuration
  static const String backendUrl = '';
  
  // Alternative: set just the host, port will be added automatically
  static const String backendHost = '';
  
  // Enable/disable automatic backend detection
  static const bool autoDetectBackend = true;
  
  // Backend port (default: 5000)
  static const int backendPort = 5000;
}
```

## Troubleshooting

### 1. Use the Network Debug Screen
The app includes a built-in network debug tool:
1. Go to Admin Dashboard
2. Click "NETWORK DEBUG"
3. Click "TEST CONNECTION"
4. Check the connection information

### 2. Common Issues

**"loadcell offline" on Android device:**
- Make sure you're using your computer's actual IP address, not localhost/127.0.0.1
- Check that your computer and phone are on the same WiFi network
- Verify the backend is running with `host='0.0.0.0'`

**Connection works on emulator but not physical device:**
- Emulators use special networking (10.0.2.2 for Android, 127.0.0.1 for iOS)
- Physical devices need your actual network IP address

**Backend not found during auto-detection:**
- The app tries multiple IP addresses automatically
- For faster connection, set the exact IP in `config.dart`
- Check firewall settings on your computer

### 3. Network Requirements
- Both your computer (running backend) and mobile device must be on the same network
- Port 5000 should be accessible (check firewall settings)
- Backend should be running with `host='0.0.0.0'` not just `localhost`

## Example Configurations

### Development on localhost (iOS Simulator)
```dart
static const String backendUrl = 'http://127.0.0.1:5000';
static const bool autoDetectBackend = false;
```

### Android Emulator
```dart
static const String backendUrl = 'http://10.0.2.2:5000';
static const bool autoDetectBackend = false;
```

### Physical Device (replace with your IP)
```dart
static const String backendUrl = 'http://192.168.1.100:5000';
static const bool autoDetectBackend = false;
```

### Auto-detection (tries multiple IPs)
```dart
static const String backendUrl = '';
static const bool autoDetectBackend = true;
```

## Environment Setup for Other Developers

1. Copy `env.example.txt` to understand the configuration options
2. Edit `lib/config.dart` with your specific network setup
3. Use the Network Debug screen to test and troubleshoot connections
4. Share your working configuration with team members working on the same network

## Advanced Configuration

The app automatically detects:
- Platform (iOS/Android)
- Emulator vs physical device
- Local network IP addresses
- Common development machine IPs

It tries connections in this order:
1. Configured `backendUrl` (if set)
2. Configured `backendHost` (if set)
3. Platform-specific defaults (127.0.0.1, 10.0.2.2)
4. Detected local IP addresses
5. Common network gateways

For production or specific network configurations, disable auto-detection and set exact URLs.
