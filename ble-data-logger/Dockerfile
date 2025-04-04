# Use an official Node.js runtime as a parent image (choose version)
FROM node:18-slim

# Install Bluetooth dependencies AND build tools required by @abandonware/noble
# Using Debian/Ubuntu package names. Adjust if using a different base image (e.g., Alpine).
RUN apt-get update && apt-get install -y --no-install-recommends \
    bluetooth \
    bluez \
    libbluetooth-dev \
    libudev-dev \
    python3 \
    build-essential \
    && rm -rf /var/lib/apt/lists/* # Clean up apt cache

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install app dependencies using npm ci for potentially faster/more reliable builds
# Use --production flag if you don't need devDependencies in the final image
# RUN npm ci --production
RUN npm install # Now node-gyp should find Python and build tools

# Bundle app source inside the Docker image
COPY . .

# Define environment variables for BLE config (can be overridden at runtime)
ENV BLE_DEVICE_NAME="ESP32_Nano_Sensor"
ENV BLE_SERVICE_UUID="4fafc201-1fb5-459e-8fcc-c5c9c331914b"
ENV BLE_CHARACTERISTIC_UUID="beb5483e-36e1-4688-b7f5-ea07361b26a8"
ENV PORT=3000

# Express app listens on port 3000 - not strictly needed with network_mode: host
# EXPOSE 3000

# Define the command to run your app
CMD ["node", "server.js"]
