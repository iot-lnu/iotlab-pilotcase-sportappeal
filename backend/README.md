# IoT Loadcell Backend

Python Flask backend for the IoT loadcell system, replacing the original JavaScript implementation.

## Features

- **WebSocket Support**: Real-time communication with ESP32 devices and clients
- **REST API**: HTTP endpoints for Flutter app integration
- **Multi-client Support**: Handles ESP32, browser, and Flutter clients simultaneously
- **Data Management**: Stores and manages sensor data sessions
- **Web Dashboard**: Built-in HTML dashboard for monitoring and control

## Installation

1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Run the server:
```bash
python app.py
```

The server will start on `http://localhost:5000`

## API Endpoints

### REST API
- `GET /api/status` - Get current system status
- `POST /api/start_test` - Start a new test session
- `POST /api/stop_test` - Stop the current test session
- `GET /api/session_data` - Get current session data
- `GET /api/latest_reading` - Get the most recent sensor reading

### WebSocket Events

#### Client Registration
Send on connect to register client type:
```json
{
  "type": "esp|browser|flutter"
}
```

#### ESP32 → Server
```json
{
  "samples": [
    {"t": timestamp, "l": left_value, "r": right_value},
    ...
  ]
}
```

#### Browser/Flutter → Server
```json
{
  "cmd": "start|stop"
}
```

#### Server → Clients
- `sensor_data`: Real-time sensor data
- `test_status`: Test status updates
- `data_complete`: Data transmission complete signal

## Configuration

The server is configured to:
- Listen on all interfaces (`0.0.0.0`)
- Use port 5000
- Support CORS for all origins
- Enable debug mode

## Integration with ESP32

The ESP32 code needs to be updated to connect to this Python server instead of the Node.js server. Change the WebSocket connection to:
- Host: Your server IP
- Port: 5000
- Path: `/socket.io/`

## Web Dashboard

Access the web dashboard at `http://localhost:5000` to:
- Monitor connection status
- Start/stop tests
- View real-time sensor readings
- See data transmission logs

## Test Data Management

Delete CSV files from test_data directory:

```bash
# Delete all CSV files
rm -rf test_data/*.csv

# Delete specific CSV file
rm test_data/imtp_test_20250822_102524.csv
```
