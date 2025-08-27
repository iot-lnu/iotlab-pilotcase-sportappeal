# IoT Sports App - Flutter Mobile Application

Flutter mobile application for sports performance tracking and loadcell sensor monitoring.

## Architecture

This Flutter app is part of a larger IoT system:
- **Backend**: Python Flask server with WebSocket support (../backend/)
- **ESP32**: Loadcell sensor data collection
- **Mobile App**: This Flutter application

## Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / Xcode for device testing
- Backend server running (see ../backend/README.md)

### Installation
```bash
# Install dependencies
flutter pub get

# Run on device/simulator
flutter run

# Build for production
flutter build apk  # Android
flutter build ios  # iOS
```

## Features

### User Management
- Login/Register screens
- User profiles with personal information
- Admin dashboard for user management
- Multiple user types support

### Testing & Monitoring
- Multiple test types (IMTP, Iso squat, Bench press, Custom)
- **Start/Stop test controls** (NEW)
- **Real-time loadcell sensor readings** (NEW)
- **Connection status indicators** (NEW)
- Session data visualization
- Historical data charts

### Sensors Integration
- MQTT sensor support (temperature, humidity)
- **Loadcell sensor integration via REST API** (NEW)
- Real-time data updates
- Error handling and reconnection

## Configuration

### Backend Connection
Edit `lib/services/loadcell_api_service.dart`:
```dart
static const String _baseUrl = 'http://YOUR_SERVER_IP:5000';
```

### MQTT Settings
Edit `lib/services/mqtt_service.dart`:
```dart
final String _topic = 'data/1dv027';
_client = MqttServerClient('YOUR_MQTT_SERVER', _clientId);
```

## New Loadcell Integration

### Start/Stop Testing
The app now includes loadcell sensor integration:

1. **Connection Status**: Visual indicators show loadcell connection
2. **Start Test**: Begin data collection from ESP32 sensors
3. **Stop Test**: End session and view sample count
4. **Real-time Readings**: Display left/right sensor values
5. **Session Management**: Track testing sessions with timestamps

### API Integration
- Uses `LoadcellApiService` for HTTP communication
- Periodic status updates every 2 seconds
- Error handling with user feedback
- Connection retry logic

## Usage Flow

### For Testing (IMTP Screen)
1. Select user from user profile
2. Choose "IMTP" test type
3. Navigate to test dashboard
4. Check loadcell connection status (green = connected)
5. Click **"START TEST"** to begin
6. Monitor real-time sensor readings
7. Click **"STOP TEST"** to end session
8. View session summary

### Status Indicators
- **Green "Loadcell Connected"**: ESP32 is connected to backend
- **Orange "Testing..."**: Test session in progress
- **Blue "Ready"**: Connected and ready to start test
- **Red "Loadcell Offline"**: No ESP32 connection

## Data Flow

### Current Implementation
```
ESP32 → Backend → REST API (2s polling) → Flutter App
```

### How It Works
1. ESP32 sends sensor data to Python backend via WebSocket
2. Flutter app polls backend every 2 seconds via REST API
3. Latest readings displayed in real-time
4. Start/stop commands sent via HTTP POST requests

## Development

### Key Files
- `lib/services/loadcell_api_service.dart` - Backend API communication
- `lib/services/mqtt_service.dart` - MQTT sensor integration  
- `lib/screens/user_test_dashboard.dart` - Main testing interface
- `lib/main.dart` - App configuration and providers

### Adding Features
1. **New API endpoints**: Update `LoadcellApiService`
2. **UI changes**: Modify screens in `lib/screens/`
3. **Data models**: Add/update models in `lib/models/`
4. **Styling**: Update theme files in `lib/theme/`

### Testing
```bash
# Run tests
flutter test

# Run on specific device
flutter run -d YOUR_DEVICE_ID

# Debug mode with hot reload
flutter run --debug
```

## Dependencies

### Core Flutter Packages
- `provider` - State management
- `http` - HTTP API calls
- `fl_chart` - Data visualization
- `google_fonts` - Custom fonts

### IoT & Communication
- `mqtt_client` - MQTT sensor integration

### Platform Support
- Android
- iOS
- Web (disabled for IoT features)

## Troubleshooting

### Connection Issues
1. **Loadcell shows offline**: Check backend server is running
2. **API calls fail**: Verify IP address in `loadcell_api_service.dart`
3. **MQTT not connecting**: Check MQTT broker settings

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Common Fixes
- Update Flutter SDK to latest stable
- Check network permissions in AndroidManifest.xml
- Verify Info.plist settings for iOS

## Future Enhancements

### Planned Features
- [ ] WebSocket streaming for true real-time data
- [ ] Data export functionality
- [ ] Advanced analytics and reports
- [ ] Push notifications for test completion
- [ ] Offline mode support

### Performance Improvements
- [ ] Optimize chart rendering for large datasets
- [ ] Implement data caching
- [ ] Reduce API polling frequency when inactive

---

**Note**: This Flutter app works in conjunction with the Python backend in `../backend/`. Make sure the backend server is running before using the loadcell features.


