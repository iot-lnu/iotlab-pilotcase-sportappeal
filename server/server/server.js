const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const path = require('path');
const { InfluxDB, Point } = require('@influxdata/influxdb-client');

// InfluxDB setup
const influxURL = 'http://influxdb:8086';
const influxToken = 't0k3n_s3cr3t_fX4Y7uQqL2hNc89WzVaPdRm1EjKg5BsT';
const influxOrg = 'sport-appeal';
const influxBucket = 'loadcell-bucket';

const influxDB = new InfluxDB({ url: influxURL, token: influxToken });
const writeApi = influxDB.getWriteApi(influxOrg, influxBucket, 'ns');

const app = express();
const server = http.createServer(app);

// ✅ WebSocket server on `/ws`
const wss = new WebSocket.Server({ server, path: '/ws' });

let espClients = new Set();
let browserClients = new Set();

// ✅ Serve static files (HTML/CSS/JS) from ./public
app.use(express.static(path.join(__dirname, 'public')));

// Optional root route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ✅ WebSocket connection logic
wss.on('connection', (ws, req) => {
  console.log('New WebSocket connection');

  ws.once('message', (msg) => {
    console.log('Initial message:', msg.toString());
    let obj;
    try {
      obj = JSON.parse(msg);
    } catch (e) {
      console.log('Invalid initial message - closing');
      ws.close();
      return;
    }

    if (obj.type === 'esp') {
      espClients.add(ws);
      console.log('ESP32 connected');
    } else if (obj.type === 'browser') {
      browserClients.add(ws);
      console.log('Browser connected');
    } else {
      ws.close();
      return;
    }

    ws.on('message', (message) => {
      try {
        const data = JSON.parse(message);

        // Browser commands (start/stop)
        if (obj.type === 'browser' && data.cmd) {
          espClients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify(data));
            }
          });
          console.log(`Forwarded ${data.cmd} command to ESP`);
        }

        // ESP data forwarding + storage
        if (obj.type === 'esp' && data.samples) {
          console.log(`📥 Received ${data.samples.length} samples from ESP`);

          // Forward to browsers
          browserClients.forEach((client) => {
            if (client.readyState === WebSocket.OPEN) {
              client.send(JSON.stringify(data));
            }
          });

          // Optionally log first few samples
          data.samples.slice(0, 3).forEach((s, idx) => {
            console.log(`Sample ${idx + 1}: time=${s.t}, left=${s.l}, right=${s.r}`);
          });

          // Write to InfluxDB
          data.samples.forEach(sample => {
            const point = new Point('loadcell')
            .intField('left', sample.l)
            .intField('right', sample.r)
            .intField('timestamp', sample.t);
            writeApi.writePoint(point);
          });

          writeApi.flush().catch(e => console.error("Influx flush error:", e));
        }

      } catch (e) {
        console.error('Error processing message:', e);
      }
    });

    ws.on('close', () => {
      if (obj.type === 'esp') espClients.delete(ws);
      if (obj.type === 'browser') browserClients.delete(ws);
      console.log(`${obj.type} disconnected`);
    });
  });
});

// Start server
const PORT = 3000;
server.listen(PORT, () => {
  console.log(`✅ Server running on http://localhost:${PORT}`);
});