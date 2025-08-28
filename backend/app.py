import os
import json
import time
import threading
import csv
from datetime import datetime
from flask import Flask, request, jsonify, render_template, send_file

from flask_sock import Sock
from flask_cors import CORS
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Variable to store original werkzeug logger level
_original_werkzeug_level = None

def set_quiet_mode(quiet=True):
    """Enable or disable quiet mode for werkzeug logs when not testing"""
    global _original_werkzeug_level
    werkzeug_logger = logging.getLogger('werkzeug')
    
    if quiet and _original_werkzeug_level is None:
        # Store original level and set to ERROR to suppress INFO logs
        _original_werkzeug_level = werkzeug_logger.level
        werkzeug_logger.setLevel(logging.ERROR)
    elif not quiet and _original_werkzeug_level is not None:
        # Restore original level
        werkzeug_logger.setLevel(_original_werkzeug_level)
        _original_werkzeug_level = None

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your-secret-key-here'
CORS(app, origins="*")

# Initialize Raw WebSocket support
sock = Sock(app)

# Global variables to track WebSocket connections and state
esp_clients = set()  # ESP32 WebSocket clients
flutter_clients = set()  # Flutter WebSocket clients
websocket_clients = set()  # All WebSocket clients
sensor_data = []
is_testing = False
current_session_data = []
simulation_active = False
session_start_time = None
sample_counter = 0

# Store the latest sensor readings
latest_readings = {
    'left': 0,
    'right': 0,
    'timestamp': None
}

# Data storage
DATA_FOLDER = 'test_data'
current_csv_file = None

def ensure_data_folder():
    """Ensure the data folder exists"""
    if not os.path.exists(DATA_FOLDER):
        os.makedirs(DATA_FOLDER)
        logger.info(f"Created data folder: {DATA_FOLDER}")

def create_csv_file():
    """Create a new CSV file for the current test session"""
    global current_csv_file
    ensure_data_folder()
    
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"imtp_test_{timestamp}.csv"
    current_csv_file = os.path.join(DATA_FOLDER, filename)
    
    # Create CSV with headers
    with open(current_csv_file, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(['timestamp', 'left_sensor', 'right_sensor', 'esp32_time_ms'])
    
    logger.info(f"Created CSV file: {current_csv_file}")
    return current_csv_file

def save_to_csv(sample_data):
    """Save sensor data to CSV file with precise timestamp"""
    if current_csv_file and os.path.exists(current_csv_file):
        try:
            with open(current_csv_file, 'a', newline='') as csvfile:
                writer = csv.writer(csvfile)
                # Create precise ISO timestamp with microseconds
                precise_timestamp = datetime.now().isoformat() + 'Z'
                writer.writerow([
                    precise_timestamp,
                    sample_data.get('left', 0),
                    sample_data.get('right', 0),
                    sample_data.get('esp32_time', sample_data.get('t', 0))  # ESP32 internal time
                ])
        except Exception as e:
            logger.error(f"Error saving to CSV: {e}")

def get_csv_files():
    """Get list of all CSV test files"""
    ensure_data_folder()
    try:
        files = []
        for filename in os.listdir(DATA_FOLDER):
            if filename.endswith('.csv'):
                filepath = os.path.join(DATA_FOLDER, filename)
                stat = os.stat(filepath)
                files.append({
                    'filename': filename,
                    'filepath': filepath,
                    'size': stat.st_size,
                    'created': datetime.fromtimestamp(stat.st_ctime).isoformat(),
                    'modified': datetime.fromtimestamp(stat.st_mtime).isoformat()
                })
        return sorted(files, key=lambda x: x['created'], reverse=True)
    except Exception as e:
        logger.error(f"Error reading CSV files: {e}")
        return []

@app.route('/')
def index():
    """Serve the main dashboard page"""
    return render_template('index.html')

@app.route('/api/status')
def get_status():
    """Get current system status"""
    return jsonify({
        'esp_connected': len(esp_clients) > 0,
        'is_testing': is_testing,
        'connected_devices': {
            'esp': len(esp_clients),
            'flutter': len(flutter_clients)
        },
        'latest_readings': latest_readings,
        'session_sample_count': len(current_session_data)
    })

@app.route('/api/start_test', methods=['POST'])
def start_test():
    """Start a new test session"""
    global is_testing, current_session_data, session_start_time, sample_counter
    
    if len(esp_clients) == 0:
        return jsonify({'error': 'No ESP32 device connected'}), 400
    
    is_testing = True
    current_session_data = []
    session_start_time = datetime.now()
    sample_counter = 0
    
    # Enable verbose logging when testing starts
    set_quiet_mode(False)
    
    # Create new CSV file for this test session
    csv_file = create_csv_file()
    
    # Send start command to ESP32 devices via Raw WebSocket
    send_command_to_esp32('start')
    
    logger.info(f"Test started via API - CSV file: {csv_file}")
    print(f"\n=== LOAD CELL TEST STARTED ===")
    print(f"Start Time: {session_start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"CSV File: {os.path.basename(csv_file)}")
    print("=====================================\n")
    
    # Note: WebSocket clients get data automatically via raw WebSocket
    
    return jsonify({
        'message': 'Test started successfully', 
        'status': 'started',
        'csv_file': os.path.basename(csv_file)
    })

@app.route('/api/stop_test', methods=['POST'])
def stop_test():
    """Stop the current test session"""
    global is_testing, session_start_time
    
    if len(esp_clients) == 0:
        return jsonify({'error': 'No ESP32 device connected'}), 400
    
    is_testing = False
    
    # Enable quiet mode when testing stops (suppress status/reading logs)
    set_quiet_mode(True)
    
    # Send stop command to ESP32 devices via Raw WebSocket
    send_command_to_esp32('stop')
    
    # Show final session info
    if session_start_time:
        from datetime import datetime
        session_end_time = datetime.now()
        duration = session_end_time - session_start_time
        
        print(f"\n=== LOAD CELL TEST STOPPED ===")
        print(f"End Time: {session_end_time.strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"Duration: {duration}")
        print(f"Total Samples: {sample_counter}")
        if current_csv_file:
            print(f"CSV File: {os.path.basename(current_csv_file)}")
        print("===============================\n")
    
    logger.info(f"Test stopped via API - Samples collected: {len(current_session_data)}")
    
    # Note: WebSocket clients get updates automatically via raw WebSocket
    
    return jsonify({
        'message': 'Test stopped successfully', 
        'status': 'stopped',
        'sample_count': len(current_session_data),
        'csv_file': os.path.basename(current_csv_file) if current_csv_file else None
    })

@app.route('/api/session_data')
def get_session_data():
    """Get current session data"""
    return jsonify({
        'is_testing': is_testing,
        'sample_count': len(current_session_data),
        'data': current_session_data[-100:] if len(current_session_data) > 100 else current_session_data
    })

@app.route('/api/latest_reading')
def get_latest_reading():
    """Get the most recent sensor reading"""
    return jsonify(latest_readings)

@app.route('/api/current_reading')
def get_current_reading():
    """Get the current sensor reading for real-time updates"""
    if latest_readings and latest_readings.get('timestamp'):
        return jsonify({
            'timestamp': latest_readings.get('timestamp'),
            'left': latest_readings.get('left', 0),
            'right': latest_readings.get('right', 0),
            'updated_at': datetime.now().isoformat() + 'Z'
        })
    return jsonify({'error': 'No sensor data available'}), 404

@app.route('/api/raw_data')
def get_raw_data():
    """Get raw sensor data in timestamp,value1,value2,value3 format"""
    if latest_readings and latest_readings.get('timestamp'):
        # Format: timestamp,left_value,right_value,esp32_time
        raw_data = {
            'timestamp': latest_readings.get('timestamp'),
            'left': latest_readings.get('left', 0),
            'right': latest_readings.get('right', 0),
            'esp32_time': latest_readings.get('esp32_time', latest_readings.get('timestamp', 0))
        }
        return jsonify(raw_data)
    return jsonify({'error': 'No sensor data available'}), 404

@app.route('/api/raw_data_csv')
def get_raw_data_csv():
    """Get raw sensor data in CSV format for Flutter app"""
    if latest_readings and latest_readings.get('timestamp'):
        # Create CSV-like response
        timestamp = latest_readings.get('timestamp', 0)
        left_val = latest_readings.get('left', 0)
        right_val = latest_readings.get('right', 0)
        
        # Format: timestamp,left,right
        csv_data = f"{timestamp},{left_val},{right_val}"
        return csv_data, 200, {'Content-Type': 'text/plain'}
    return "No data available", 404

@app.route('/api/csv_files')
def get_csv_files_api():
    """Get list of CSV files"""
    return jsonify({'files': get_csv_files()})

@app.route('/api/download/<filename>')
def download_csv(filename):
    """Download a specific CSV file"""
    filepath = os.path.join(DATA_FOLDER, filename)
    if os.path.exists(filepath) and filename.endswith('.csv'):
        return send_file(filepath, as_attachment=True)
    return jsonify({'error': 'File not found'}), 404

@app.route('/api/delete/<filename>', methods=['DELETE'])
def delete_csv(filename):
    """Delete a specific CSV file"""
    filepath = os.path.join(DATA_FOLDER, filename)
    if os.path.exists(filepath) and filename.endswith('.csv'):
        try:
            os.remove(filepath)
            logger.info(f"Deleted CSV file: {filename}")
            return jsonify({'message': f'File {filename} deleted successfully'})
        except Exception as e:
            logger.error(f"Error deleting file {filename}: {e}")
            return jsonify({'error': f'Failed to delete file: {e}'}), 500
    return jsonify({'error': 'File not found'}), 404

@app.route('/api/simulate_esp32', methods=['POST'])
def simulate_esp32():
    """Simulate ESP32 connection for testing without physical device"""
    global simple_ws_clients, latest_readings, simulation_active
    
    # Add a fake ESP32 client
    class FakeWSClient:
        def __init__(self):
            self.connected = True
            
        def send(self, data):
            logger.info(f"Fake ESP32 received command: {data}")
            
        def close(self):
            self.connected = False
    
    fake_client = FakeWSClient()
    simple_ws_clients.add(fake_client)
    
    # Start continuous simulation
    simulation_active = True
    start_simulation_thread()
    
    logger.info("Simulated ESP32 connected with continuous data generation")
    return jsonify({
        'message': 'ESP32 simulation enabled',
        'esp_connected': True,
        'simulation_active': True
    })

def start_simulation_thread():
    """Start background thread for continuous data simulation"""
    import threading
    import time
    import random
    
    def generate_data():
        global latest_readings, simulation_active
        while simulation_active and simple_ws_clients:
            # Generate realistic sensor data
            latest_readings = {
                'left': random.randint(100, 1000),
                'right': random.randint(100, 1000),
                'timestamp': int(time.time() * 1000)
            }
            time.sleep(0.1)  # Update every 100ms
    
    if not hasattr(start_simulation_thread, 'thread_started'):
        thread = threading.Thread(target=generate_data, daemon=True)
        thread.start()
        start_simulation_thread.thread_started = True

@app.route('/api/disable_simulation', methods=['POST'])
def disable_simulation():
    """Disable ESP32 simulation to wait for real device"""
    global simple_ws_clients, simulation_active, latest_readings
    
    # Clear fake clients
    simple_ws_clients.clear()
    simulation_active = False
    
    # Reset readings to show offline state
    latest_readings = {'left': 0, 'right': 0, 'timestamp': None}
    
    logger.info("ESP32 simulation disabled - waiting for real device")
    return jsonify({
        'message': 'ESP32 simulation disabled',
        'esp_connected': False,
        'waiting_for_real_device': True
    })

@sock.route('/ws')
def websocket_handler(ws):
    """Handle raw WebSocket connections (optimal for ESP32 and Flutter)"""
    logger.info("WebSocket client connected")
    websocket_clients.add(ws)
    
    client_type = None
    
    try:
        while True:
            message = ws.receive()
            if not message:
                break
                

            
            try:
                data = json.loads(message)
                
                # Handle registration
                if 'type' in data:
                    client_type = data['type']
                    if client_type == 'esp32':
                        esp_clients.add(ws)
                        logger.info("ESP32 connected - Waiting for frontend to start test")
                        
                        # Don't create CSV file yet - wait for frontend command
                        global session_start_time, sample_counter, current_csv_file
                        session_start_time = None
                        sample_counter = 0
                        current_csv_file = None
                        
                        print(f"\n=== ESP32 CONNECTED ===")
                        print(f"Device: ESP32 Load Cell (ADS1220)")
                        print(f"Status: Waiting for frontend to start test")
                        print(f"=====================================\n")
                        
                        ws.send('{"status":"registered","type":"esp32","message":"Waiting for test start command"}')
                    elif client_type == 'flutter':
                        flutter_clients.add(ws)
                        logger.info("Flutter connected") 
                        ws.send('{"status":"registered","type":"flutter"}')
                        
                # Handle sensor data from ESP32
                elif 'samples' in data:
                    handle_esp32_data(data, ws)
                    
                # Handle ping
                elif 'ping' in data:
                    ws.send('{"pong":true}')
                    
                # Handle commands from Flutter
                elif 'cmd' in data:
                    command = data['cmd']
                    logger.info(f"Command: {command}")
                    send_command_to_esp32_websocket(command)
                    ws.send(f'{{"command_ack":"{command}","success":true}}')
                    
            except json.JSONDecodeError:
                logger.error(f"Invalid JSON: {message}")
                
    except Exception as e:
        logger.info(f"WebSocket disconnected: {e}")
    finally:
        # Clean up connections
        was_esp32 = ws in esp_clients
        websocket_clients.discard(ws)
        esp_clients.discard(ws)
        flutter_clients.discard(ws)
        
        # Show session end info if ESP32 disconnected
        if was_esp32 and session_start_time:
            from datetime import datetime
            session_end_time = datetime.now()
            duration = session_end_time - session_start_time
            
            print(f"\n=== LOAD CELL SESSION ENDED ===")
            print(f"End Time: {session_end_time.strftime('%Y-%m-%d %H:%M:%S')}")
            print(f"Duration: {duration}")
            print(f"Total Samples: {sample_counter}")
            if current_csv_file:
                print(f"CSV File: {os.path.basename(current_csv_file)}")
                print(f"CSV Path: {current_csv_file}")
            print("===============================\n")
        
        logger.info("WebSocket cleaned up")

def send_command_to_esp32_websocket(command):
    """Send command to ESP32 via Raw WebSocket"""
    cmd_msg = json.dumps({'command': command})
    
    # Send to ESP32 WebSocket clients
    for client in list(websocket_clients):
        if client in esp_clients:
            try:
                client.send(cmd_msg)
                logger.info(f"Command sent to ESP32: {command}")
            except Exception as e:
                logger.error(f"Failed to send command: {e}")
                websocket_clients.discard(client)
                esp_clients.discard(client)


# Old WebSocket handlers removed - using Socket.IO exclusively

def handle_esp32_data(data, ws):
    """Handle sensor data from ESP32"""
    global latest_readings, current_session_data, sample_counter
    
    try:
        if 'samples' in data:
            # Handle batch of samples
            samples = data['samples']
            
            for sample in samples:
                # Update latest readings
                latest_readings = {
                    'left': sample.get('l', 0),
                    'right': sample.get('r', 0),
                    'timestamp': sample.get('t', int(time.time() * 1000))
                }
                
                # Create individual sample data for CSV
                sample_for_csv = {
                    'left': sample.get('l', 0),
                    'right': sample.get('r', 0),
                    't': sample.get('t', 0),  # ESP32 internal timestamp
                    'esp32_time': sample.get('t', 0)  # Alternative key for consistency
                }
                
                # Only save to CSV and session data when test is running
                if is_testing and current_csv_file:
                    save_to_csv(sample_for_csv)
                    current_session_data.append(latest_readings.copy())
                    sample_counter += 1
                else:
                    # Just update latest readings for display
                    pass
            
            # Forward to Raw WebSocket Flutter clients ONLY when test is running
            if is_testing:
                forward_to_websocket_clients(data, exclude_sender=ws)
                
                # Show data in same format as CSV file
                if samples:
                    from datetime import datetime
                    for sample in samples[:5]:  # Show first 5 samples like CSV format
                        precise_timestamp = datetime.now().isoformat() + 'Z'
                        left_value = sample.get('l', 0)
                        right_value = sample.get('r', 0)
                        esp32_time = sample.get('t', 0)
                        print(f"{precise_timestamp},{left_value},{right_value},{esp32_time}")
                
                
        elif 'done' in data:
            logger.info("ESP32 batch complete")
            
    except Exception as e:
        logger.error(f"Error processing ESP32 data: {e}")

def send_command_to_esp32(command):
    """Send command to ESP32 via Raw WebSocket"""
    send_command_to_esp32_websocket(command)
    logger.info(f"Sent command '{command}' to ESP32")

def forward_to_websocket_clients(data, exclude_sender=None):
    """Forward data to WebSocket Flutter clients"""
    message = json.dumps(data)
    
    for client in list(websocket_clients):
        if client != exclude_sender and client in flutter_clients:
            try:
                client.send(message)
            except Exception as e:
                logger.error(f"Failed to forward data: {e}")
                websocket_clients.discard(client)
                flutter_clients.discard(client)

@app.route('/api/esp32/status', methods=['GET'])
def esp32_status():
    """Get ESP32 connection status and latest readings"""
    return jsonify({
        'esp32_connected': len(esp_clients) > 0,
        'num_connections': len(esp_clients),
        'latest_readings': latest_readings,
        'is_testing': is_testing,
        'server_time': int(time.time() * 1000)
    })

@app.route('/api/esp32/command', methods=['POST'])
def send_esp32_command():
    """Send command to ESP32"""
    data = request.get_json()
    if not data or 'command' not in data:
        return jsonify({'error': 'Command is required'}), 400
    
    command = data['command']
    send_command_to_esp32(command)
    
    return jsonify({
        'success': True,
        'command': command,
        'esp32_connected': len(esp_clients) > 0
    })

@app.route('/api/esp32/register', methods=['POST'])
def esp32_register():
    """Register ESP32 device via HTTP"""
    data = request.get_json()
    device_type = data.get('type', 'unknown')
    device_id = data.get('device_id', 'unknown')
    
    # Add ESP32 to connected devices list
    esp_clients.add(device_id)
    
    logger.info(f"ESP32 registered via HTTP: {device_id}")
    
    return jsonify({
        'success': True,
        'device_id': device_id,
        'message': 'ESP32 registered successfully'
    })

@app.route('/api/esp32/data', methods=['POST'])
def esp32_data():
    """Receive sensor data from ESP32 via HTTP"""
    try:
        data = request.get_json()
        
        # Process the sensor data
        if 'samples' in data:
            samples = data['samples']
            logger.info(f"Received {len(samples)} samples from ESP32 via HTTP")
            
            # Handle the data same as WebSocket
            handle_esp32_data(data, None)
            
            return jsonify({
                'success': True,
                'samples_received': len(samples)
            })
        else:
            return jsonify({'error': 'No samples in data'}), 400
            
    except Exception as e:
        logger.error(f"Error processing ESP32 HTTP data: {e}")
        return jsonify({'error': str(e)}), 500



# Create templates directory and index.html
def create_templates():
    """Create the templates directory and files if they don't exist"""
    templates_dir = os.path.join(os.path.dirname(__file__), 'templates')
    if not os.path.exists(templates_dir):
        os.makedirs(templates_dir)
    
    index_html = '''<!DOCTYPE html>
<html>
<head>
    <title>IoT Loadcell Dashboard</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/socket.io/4.0.1/socket.io.js"></script>
    <style>
        body { 
            font-family: sans-serif; 
            padding: 1rem; 
            background-color: #1e1e1e; 
            color: white; 
        }
        .container { max-width: 800px; margin: 0 auto; }
        .status { 
            padding: 1rem; 
            border-radius: 8px; 
            margin: 1rem 0; 
            background-color: #2a2a2a; 
        }
        .connected { border-left: 4px solid #4CAF50; }
        .disconnected { border-left: 4px solid #f44336; }
        button { 
            margin: 0.5rem; 
            padding: 0.75rem 1.5rem; 
            border: none; 
            border-radius: 4px; 
            cursor: pointer; 
            font-size: 16px; 
        }
        .start-btn { background-color: #4CAF50; color: white; }
        .stop-btn { background-color: #f44336; color: white; }
        .disabled { background-color: #666; cursor: not-allowed; }
        #output { 
            background: #333; 
            padding: 1rem; 
            height: 300px; 
            overflow: auto; 
            white-space: pre-wrap; 
            border-radius: 4px; 
            margin: 1rem 0; 
        }
        .readings { 
            display: grid; 
            grid-template-columns: 1fr 1fr; 
            gap: 1rem; 
            margin: 1rem 0; 
        }
        .reading-card { 
            background: #2a2a2a; 
            padding: 1rem; 
            border-radius: 8px; 
            text-align: center; 
        }
        .reading-value { 
            font-size: 2rem; 
            font-weight: bold; 
            color: #75F94C; 
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>IoT Loadcell Dashboard</h1>
        
        <div id="status" class="status disconnected">
            <h3>Connection Status: <span id="connection-status">Disconnected</span></h3>
            <p>ESP32 Connected: <span id="esp-status">No</span></p>
            <p>Test Status: <span id="test-status">Idle</span></p>
        </div>
        
        <div>
            <button id="start-btn" class="start-btn" onclick="sendCommand('start')">Start Test</button>
            <button id="stop-btn" class="stop-btn disabled" onclick="sendCommand('stop')">Stop Test</button>
        </div>
        
        <div class="readings">
            <div class="reading-card">
                <h4>L</h4>
                <div class="reading-value" id="left-reading">0</div>
            </div>
            <div class="reading-card">
                <h4>R</h4>
                <div class="reading-value" id="right-reading">0</div>
            </div>
        </div>
        
        <h3>Data Log</h3>
        <div id="output">Waiting for connection...</div>
    </div>

    <script>
        const socket = io();
        const output = document.getElementById('output');
        const connectionStatus = document.getElementById('connection-status');
        const espStatus = document.getElementById('esp-status');
        const testStatus = document.getElementById('test-status');
        const statusDiv = document.getElementById('status');
        const startBtn = document.getElementById('start-btn');
        const stopBtn = document.getElementById('stop-btn');
        const leftReading = document.getElementById('left-reading');
        const rightReading = document.getElementById('right-reading');
        
        let isConnected = false;
        let isTesting = false;

        socket.on('connect', () => {
            output.textContent += 'Connected to server\\n';
            connectionStatus.textContent = 'Connected';
            statusDiv.className = 'status connected';
            isConnected = true;
            
            // Register as browser client
            socket.emit('register', { type: 'browser' });
            updateButtons();
        });

        socket.on('disconnect', () => {
            output.textContent += 'Disconnected from server\\n';
            connectionStatus.textContent = 'Disconnected';
            statusDiv.className = 'status disconnected';
            isConnected = false;
            updateButtons();
        });

        socket.on('sensor_data', (data) => {
            if (data.samples) {
                const samples = data.samples;
                output.textContent += `Received ${samples.length} samples\\n`;
                
                // Update latest readings with the last sample
                if (samples.length > 0) {
                    const lastSample = samples[samples.length - 1];
                    leftReading.textContent = lastSample.l || 0;
                    rightReading.textContent = lastSample.r || 0;
                }
                
                // Scroll to bottom
                output.scrollTop = output.scrollHeight;
            }
        });

        socket.on('test_status', (data) => {
            testStatus.textContent = data.status.charAt(0).toUpperCase() + data.status.slice(1);
            isTesting = data.status === 'started';
            updateButtons();
            output.textContent += `Test ${data.status}\\n`;
        });

        socket.on('registration_response', (data) => {
            output.textContent += `Registered as ${data.type} client\\n`;
        });

        // Update system status periodically
        setInterval(() => {
            if (isConnected) {
                fetch('/api/status')
                    .then(response => response.json())
                    .then(data => {
                        espStatus.textContent = data.esp_connected ? 'Yes' : 'No';
                        isTesting = data.is_testing;
                        updateButtons();
                    })
                    .catch(err => console.error('Error fetching status:', err));
            }
        }, 2000);

        function sendCommand(cmd) {
            if (!isConnected) {
                output.textContent += 'Not connected to server\\n';
                return;
            }
            
            socket.emit('browser_command', { cmd: cmd });
            output.textContent += `Sent command: ${cmd}\\n`;
        }

        function updateButtons() {
            if (!isConnected) {
                startBtn.className = 'start-btn disabled';
                stopBtn.className = 'stop-btn disabled';
                startBtn.disabled = true;
                stopBtn.disabled = true;
            } else if (isTesting) {
                startBtn.className = 'start-btn disabled';
                stopBtn.className = 'stop-btn';
                startBtn.disabled = true;
                stopBtn.disabled = false;
            } else {
                startBtn.className = 'start-btn';
                stopBtn.className = 'stop-btn disabled';
                startBtn.disabled = false;
                stopBtn.disabled = true;
            }
        }
    </script>
</body>
</html>'''
    
    index_path = os.path.join(templates_dir, 'index.html')
    with open(index_path, 'w') as f:
        f.write(index_html)

if __name__ == '__main__':
    create_templates()
    
    # Start in quiet mode (suppress repetitive API logs when not testing)
    set_quiet_mode(True)
    
    logger.info("Starting Flask server with Raw WebSocket support...")
    logger.info("Dashboard available at: http://localhost:5000")
    logger.info("Raw WebSocket endpoint: ws://localhost:5000/ws")
    logger.info("API endpoints:")
    logger.info("  GET  /api/status - Get system status")
    logger.info("  POST /api/start_test - Start test session")
    logger.info("  POST /api/stop_test - Stop test session")
    logger.info("  GET  /api/session_data - Get current session data")
    logger.info("  GET  /api/latest_reading - Get latest sensor reading")
    logger.info("Note: API request logs are suppressed when not testing to reduce noise")
    
    # Use Flask app with Raw WebSocket support
    app.run(host='0.0.0.0', port=5000, debug=True)
