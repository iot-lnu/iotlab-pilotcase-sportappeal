const express = require('express');
const noble = require('@abandonware/noble');

const app = express();
const port = process.env.PORT || 3000;

// --- Configuration ---
// !! IMPORTANT: Replace these with your ESP32's actual UUIDs and name !!
const DEVICE_NAME = process.env.BLE_DEVICE_NAME || 'ESP32_Nano_Sensor'; // Name of your ESP32 device
const SERVICE_UUID = process.env.BLE_SERVICE_UUID || '4fafc201-1fb5-459e-8fcc-c5c9c331914b'; // Your Service UUID
const CHARACTERISTIC_UUID = process.env.BLE_CHARACTERISTIC_UUID || 'beb5483e-36e1-4688-b7f5-ea07361b26a8'; // Your Characteristic UUID
// --- End Configuration ---

let targetPeripheral = null;
let dataCharacteristic = null;
let isScanning = false;
let isConnected = false;
const discoveredDevices = new Set(); // Keep track of printed devices to avoid duplicates

// Simple Express route
app.get('/', (req, res) => {
  res.send(`BLE Data Logger: Scanning: ${isScanning}, Connected: ${isConnected ? targetPeripheral.advertisement.localName : 'No'}`);
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
  console.log(`--- Target Device Name: ${DEVICE_NAME} ---`); // Log target name
  startBleProcess(); // Start BLE operations when server starts
});

// --- BLE Logic ---

function startBleProcess() {
  console.log('Initializing BLE...');

  noble.on('stateChange', handleStateChange);
  noble.on('discover', handleDiscover); // This event fires for EACH discovered device
  // noble.on('scanStart', () => { console.log('Scan started.'); isScanning = true; });
  // noble.on('scanStop', () => { console.log('Scan stopped.'); isScanning = false; });
  // noble.on('warning', (message) => console.warn('Noble Warning:', message));
}

async function handleStateChange(state) {
  console.log(`BLE Adapter State: ${state}`);
  if (state === 'poweredOn') {
    discoveredDevices.clear(); // Clear list on new scan start
    await startScanningAndDiscover(); // Changed function name for clarity
  } else {
    console.log('BLE Adapter not powered on. Stopping scan.');
    isScanning = false;
    await noble.stopScanningAsync();
  }
}

async function startScanningAndDiscover() { // Renamed function
  if (isScanning || isConnected) {
    console.log('Already scanning or connected.');
    return;
  }
  console.log(`Starting scan for ALL devices...`);
  isScanning = true;
  try {
    // Start scanning for *all* devices, don't filter by service UUID here
    // Allow duplicates (true) to see RSSI updates, or use false to see each device once
    await noble.startScanningAsync([], false); // Empty array scans for all, false = no duplicates
    console.log(`Scanning started. Listening for devices...`);

  } catch (error) {
    console.error('Error starting scan:', error);
    isScanning = false;
  }
}

async function handleDiscover(peripheral) {
  // --- Print details of EVERY discovered device ---
  const deviceId = peripheral.address || peripheral.id; // Use address (Linux/Win) or id (macOS)
  const localName = peripheral.advertisement.localName || 'N/A';
  const rssi = peripheral.rssi;
  const serviceUuids = peripheral.advertisement.serviceUuids || [];

  // Print only once per device unless allowing duplicates in scan
  if (!discoveredDevices.has(deviceId)) {
    console.log('--------------------------------------------------');
    console.log(`[Device Found]`);
    console.log(`  Name:    ${localName}`);
    console.log(`  ID/Addr: ${deviceId}`); // On macOS this is a UUID, not MAC Address
    console.log(`  RSSI:    ${rssi} dBm`);
    console.log(`  Services:${serviceUuids.length > 0 ? ` ${serviceUuids.join(', ')}` : ' (None Advertised)'}`);
    discoveredDevices.add(deviceId); // Mark as printed
  }
  // --- End printing all devices ---


  // --- Check if this discovered device is our target ---
  if (!targetPeripheral && localName === DEVICE_NAME) {
    console.log(`*** Found TARGET device by name: ${localName} (${deviceId}) ***`);
    targetPeripheral = peripheral; // Assign the found peripheral as our target
    await connectToPeripheral(); // Attempt to connect ONLY to the target
  }
  // Optionally add a check for service UUID if name isn't reliable
  // else if (!targetPeripheral && serviceUuids.includes(SERVICE_UUID.replace(/-/g, ''))) {
  //      console.log(`*** Found TARGET device by service UUID: ${localName} (${deviceId}) ***`);
  //      targetPeripheral = peripheral;
  //      await connectToPeripheral();
  // }
}


async function connectToPeripheral() {
  // This function remains largely the same, but now it's only called
  // when the target device is found in handleDiscover.

  if (!targetPeripheral || isConnected) return;

  console.log(`>>> Stopping scan and attempting to connect to target: ${targetPeripheral.advertisement.localName}...`);
  isScanning = false; // Set scanning flag to false as we are stopping
  await noble.stopScanningAsync(); // Stop scanning explicitly
  console.log('Scan stopped.');

  targetPeripheral.once('disconnect', handleDisconnect);

  try {
    console.log('Connecting...');
    await targetPeripheral.connectAsync();
    console.log(`Connected to ${targetPeripheral.advertisement.localName}`);
    isConnected = true;
    await discoverServicesAndCharacteristics();
  } catch (error) {
    console.error(`Failed to connect to ${targetPeripheral.advertisement.localName}:`, error);
    targetPeripheral = null; // Clear target so we can scan again if needed
    isConnected = false;
    // Optionally restart scanning after a delay ONLY if connection fails
    console.log('Connection failed. Restarting scan in 10 seconds...');
    setTimeout(startScanningAndDiscover, 10000); // Retry scan after 10s
  }
}

async function discoverServicesAndCharacteristics() {
  if (!targetPeripheral || !isConnected) return;

  console.log('Discovering services and characteristics...');
  try {
    const services = await targetPeripheral.discoverServicesAsync([SERVICE_UUID]);
    if (services.length === 0) {
      console.error(`Target Service ${SERVICE_UUID} not found on connected device.`);
      await disconnectAndReset();
      return;
    }
    const service = services[0];
    console.log(`Discovered target service: ${service.uuid}`);

    const characteristics = await service.discoverCharacteristicsAsync([CHARACTERISTIC_UUID]);
    if (characteristics.length === 0) {
      console.error(`Target Characteristic ${CHARACTERISTIC_UUID} not found.`);
      await disconnectAndReset();
      return;
    }
    dataCharacteristic = characteristics[0];
    console.log(`Discovered target characteristic: ${dataCharacteristic.uuid}`);

    await subscribeToNotifications();

  } catch (error) {
    console.error('Error discovering services/characteristics:', error);
    await disconnectAndReset();
  }
}

async function subscribeToNotifications() {
  if (!dataCharacteristic) return;

  console.log('Subscribing to notifications...');
  try {
    dataCharacteristic.on('data', handleData); // Attach listener FIRST
    await dataCharacteristic.subscribeAsync();
    console.log('Subscribed successfully. Waiting for data...');
  } catch (error) {
    console.error('Error subscribing to notifications:', error);
    await disconnectAndReset();
  }
}

function handleData(data, isNotification) {
  // This function remains the same
  console.log(`Received notification (${data.length} bytes): ${data.toString('hex')}`);
  if (data.length % 4 !== 0) {
    console.warn(`Received data length (${data.length}) is not a multiple of 4. Skipping interpretation.`);
    return;
  }
  const values = [];
  for (let i = 0; i < data.length; i += 4) {
    const value = data.readInt32LE(i);
    values.push(value);
  }
  console.log('>>> Interpreted int32 values:', values);
}

async function handleDisconnect() {
  const deviceName = targetPeripheral?.advertisement?.localName || 'device'; // Capture name before clearing
  console.log(`Disconnected from ${deviceName}`);
  isConnected = false;
  targetPeripheral?.removeAllListeners(); // Clean up listeners
  dataCharacteristic?.removeAllListeners();
  targetPeripheral = null;
  dataCharacteristic = null;
  discoveredDevices.clear(); // Clear discovered list so we see devices again on next scan

  // Attempt to reconnect by restarting the scanning process after a short delay
  console.log('Will attempt to find device and reconnect in 10 seconds...');
  setTimeout(startScanningAndDiscover, 10000);
}

async function disconnectAndReset() {
  // This function remains largely the same
  if (targetPeripheral && isConnected) {
    console.log('Disconnecting due to error...');
    try {
      await targetPeripheral.disconnectAsync();
    } catch (disconnectError) {
      console.error('Error during disconnection:', disconnectError);
    }
  } else {
    isConnected = false;
    targetPeripheral = null;
    dataCharacteristic = null;
    discoveredDevices.clear();
    console.log('Resetting state. Will attempt to scan again in 10 seconds...');
    setTimeout(startScanningAndDiscover, 10000);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log("\nCaught interrupt signal (Ctrl+C)");
  isScanning = false;
  // Wrap stopScanning in try-catch as it might throw if adapter is off
  try {
    await noble.stopScanningAsync();
    console.log("Scan stopped on exit.");
  } catch (scanStopError) {
    console.warn("Could not stop scanning on exit:", scanStopError.message)
  }

  if (targetPeripheral && isConnected) {
    console.log('Disconnecting peripheral...');
    try {
      // Unsubscribe might be good practice, but often disconnect handles it
      // if (dataCharacteristic) await dataCharacteristic.unsubscribeAsync();
      await targetPeripheral.disconnectAsync();
      console.log('Disconnected.');
    } catch (err) {
      console.error("Error during cleanup disconnection:", err);
    }
  }
  process.exit(0);
});
