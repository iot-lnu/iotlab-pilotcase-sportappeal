# ESP32 ADS1220 Load Cell Logger - FreeRTOS PlatformIO Project

## Complete PlatformIO Project Structure

This is a complete PlatformIO project with **FreeRTOS multi-tasking architecture** for real-time load cell data logging. Can be used with **Visual Studio Code extension** or **command-line interface (CLI)**.

## Main Files:

- **`src/main.cpp`** - Your main ESP32 code with FreeRTOS multi-tasking
- **`platformio.ini`** - Project configuration with all required libraries
- **`.vscode/extensions.json`** - VS Code extension recommendations

## Setup Methods:

### **Method 1: Visual Studio Code Extension**

If you prefer using VSCode with a graphical interface:

1. **Install PlatformIO Extension:**
   - Open VSCode
   - Go to Extensions (Ctrl+Shift+X)
   - Search for "PlatformIO IDE"
   - Install the official PlatformIO extension
2. **Open Project:**
   - File → Open Folder → Select this `ESP32_PlatformIO_Project` folder
   - Wait for PlatformIO to initialize
3. **Upload Code:**
   - Connect ESP32 via USB-C
   - Click "Upload" button in PlatformIO toolbar

### **Method 2: Command Line Interface (CLI) - For Any Terminal**

If you want to use PlatformIO from any terminal (Terminal, Command Prompt, SSH, etc.):

#### **Install Dependencies:**

**Option A: Using pipx**
```bash
# Install pipx (if not already installed)
# On macOS with Homebrew:
brew install pipx

# On Linux/WSL:
sudo apt install pipx
# or
pip3 install --user pipx

# Install PlatformIO
pipx install platformio

# Add to PATH
pipx ensurepath

# Restart terminal or reload shell
source ~/.bashrc   # or ~/.zshrc on macOS
```

**Option B: Using pip3**
```bash
# Install PlatformIO globally
pip3 install platformio

# Or install for current user only
pip3 install --user platformio
```

**Option C: Using package managers**
```bash
# On macOS with Homebrew:
brew install platformio

# On Ubuntu/Debian:
sudo apt install platformio

# On Arch Linux:
sudo pacman -S platformio
```

#### **CLI Commands:**

```bash
# Navigate to project directory
cd ESP32_PlatformIO_Project

# Build project
pio run

# Upload to ESP32 (connect via USB first)
pio run --target upload

# Monitor serial output
pio device monitor --baud 115200

# Build + Upload + Monitor in one command
pio run -t upload -t monitor

# List connected devices
pio device list

# Clean build files
pio run -t clean

# Update libraries
pio pkg update
```

#### **Quick CLI Workflow!!:**
```bash
# 1. Build and upload
pio run -t upload

# 2. Monitor output (Ctrl+C to exit)
pio device monitor

# 3. Or do both at once!
pio run -t upload -t monitor
```

## Configuration Required:

Edit `src/main.cpp` and update these lines:
```cpp
const char* ssid = "YOUR_WIFI_SSID";                    // Your WiFi network name
const char* password = "YOUR_WIFI_PASSWORD";             // Your WiFi password
const char* websocket_host = "YOUR_COMPUTER_IP_ADDRESS"; // Your computer's network IP address
```

### Finding Your Backend Server IP Address:

**On macOS/Linux:**
```bash
# Find your computer's IP address on the network
ifconfig | grep "inet " | grep -v 127.0.0.1
```

**On Windows:**
```cmd
ipconfig | findstr "IPv4"
```

**Important:** Make sure ESP32 and backend server are on the same WiFi network!

## Hardware Connections:

```
ESP32          Left HX711       Right HX711
────────────   ─────────────    ──────────────
3.3V     ───── VCC         ───── VCC
GND      ───── GND         ───── GND
GPIO 2   ───── DT          
GPIO 4   ───── SCK         
GPIO 5   ─────              ───── DT
GPIO 18  ─────              ───── SCK
```

## Libraries Included:

The following libraries are automatically installed via `platformio.ini`:
- **WebSockets@^2.4.0** (for backend communication)
- **ArduinoJson@^6.21.3** (for data formatting)
- **ProtoCentral ADS1220 24-bit ADC Library@^1.2.1** (for high-precision ADC)

## FreeRTOS Architecture Benefits:

- **Real-time sampling**: 1000 Hz continuous sampling without interruption
- **Multi-tasking**: Separate tasks for sampling and data transmission
- **High performance**: No missed samples during network operations
- **Professional reliability**: Industrial-grade timing and memory management
- **Scalable**: Easy to add more sensors or processing tasks

## Connection Details:

- **Backend URL**: `ws://192.168.1.158:5000/ws`
- **Sample Rate**: 1000 Hz (1ms intervals - real-time performance!)
- **Batch Size**: 100 samples per transmission
- **Buffer Size**: 120,000 samples (PSRAM allocation)
- **Protocol**: WebSocket with JSON batching
- **Architecture**: FreeRTOS multi-tasking (separate sampling and sending tasks)

## Expected Output:

```
============================================================
ESP32 LOAD CELL DATA LOGGER
Optimized for Flutter Mobile Application
PlatformIO Version
============================================================
Device: ESP32 Load Cell Monitor
Backend: ws://192.168.1.158:5000/ws
Sample Rate: 10 Hz
Batch Size: 10 samples
============================================================
Initializing HX711 Load Cell Amplifiers...
Waiting for load cells to stabilize...
Performing initial tare...
Load cells initialized successfully!

Connecting to WiFi network: YourNetwork
WiFi connected successfully!
ESP32 IP Address: 192.168.1.xxx

Initializing WebSocket connection...
Target: ws://192.168.1.158:5000/ws
WebSocket connected to: 192.168.1.158:5000/ws
Registering device with backend server...
Registration message sent to server
Device registration completed!

ESP32 Load Cell Logger ready!
Starting data collection...

Sample 1/10: Left=0.00, Right=0.00
Transmitting data batch (10 samples)...
Data batch transmitted successfully (xxx bytes)
```

## Customization:

### **Change Sample Rate:**
```cpp
#define SAMPLING_INTERVAL 1;   // 1ms = 1000Hz (current setting)
#define SAMPLING_INTERVAL 2;   // 2ms = 500Hz
#define SAMPLING_INTERVAL 5;   // 5ms = 200Hz
```

### **Change Batch Size:**
```cpp
#define SENDER_BATCH_SIZE 100;  // 100 samples per transmission (current)
#define SENDER_BATCH_SIZE 50;   // 50 samples per transmission
#define SENDER_BATCH_SIZE 200;  // 200 samples per transmission
```

### **Change Buffer Size:**
```cpp
#define ADC_QUEUE_LENGTH 120000;  // 120,000 samples (current)
#define ADC_QUEUE_LENGTH 60000;   // 60,000 samples
#define ADC_QUEUE_LENGTH 240000;  // 240,000 samples
```

### **Calibration:**
```cpp
const float CALIBRATION_LEFT = -7050.0f;   // Left sensor calibration
const float CALIBRATION_RIGHT = -7050.0f;  // Right sensor calibration
```

## Troubleshooting:

### **VSCode Extension Issues:**
1. **PlatformIO not working?** - Install PlatformIO extension in VS Code
2. **Extension not loading?** - Restart VSCode and wait for initialization

### **CLI Issues:**
1. **`pio` command not found?** - Ensure PlatformIO is in your PATH
2. **Permission errors?** - Use `sudo` or install with `--user` flag
3. **Virtual environment issues?** - Use `pipx` for isolated installation

### **Hardware Issues:**
1. **Upload failed?** - Check USB-C cable and ESP32 connection
2. **Device not detected?** - Try different USB port or cable
3. **WiFi won't connect?** - Verify credentials and 2.4GHz network
4. **No sensor data?** - Check HX711 wiring and 3.3V power supply

### **Common CLI Solutions:**
```bash
# Fix permission issues (Linux/macOS)
pip3 install --user platformio

# Check if device is detected
pio device list

# Force clean rebuild
pio run -t clean && pio run

# Specify upload port manually
pio run -t upload --upload-port /dev/ttyUSB0

# Monitor with specific port
pio device monitor --port /dev/ttyUSB0 --baud 115200
```

## Quick Start Guide:

### **For VSCode Users:**
1. Install PlatformIO extension
2. Open this folder in VSCode
3. Update WiFi credentials in `src/main.cpp`
4. Connect ESP32 and click Upload

### **For CLI Users:**
1. Install PlatformIO: `pipx install platformio`
2. Build project: `pio run`
3. Upload to ESP32: `pio run -t upload`
4. Monitor output: `pio device monitor`

## Integration:

Once uploaded, your ESP32 will automatically:
1. Connect to your WiFi network
2. Connect to your Flask backend via WebSocket
3. Register as an ESP32 device
4. **Stream real-time sensor data at 1000 Hz** to your Flutter app
5. **Continuously sample** while simultaneously transmitting data

Your Flutter app will show "Loadcell Connected" and display **real-time data with professional-grade performance**!

## Tips:

- **Use CLI for automation** - Perfect for CI/CD and scripting
- **Use VSCode for development** - Better for coding and debugging
- **Both methods use the same code** - Switch between them anytime
- **CLI works anywhere** - SSH, remote servers, minimal environments