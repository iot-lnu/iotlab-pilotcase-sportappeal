#include <SPI.h>
#include "Protocentral_ADS1220.h"
#include <task.h>
#include <WiFi.h>
#include <ArduinoJson.h>
#include <WebSocketsClient.h>

// ============================================================================
// ADS1220 CONFIGURATION 
// ============================================================================

// Constants 
#define PGA 128
#define VREF 3.300
#define LEFT_OFFSET -12700 
#define RIGHT_OFFSET -17500 
#define COUNTS_TO_NEWTONS_LEFT 0.001095f 
#define COUNTS_TO_NEWTONS_RIGHT 0.0008938f

// Pin Config
#define LEFT_ADS1220_CS_PIN     8
#define LEFT_ADS1220_DRDY_PIN   4
#define RIGHT_ADS1220_CS_PIN    7
#define RIGHT_ADS1220_DRDY_PIN  2

// ADS1220 instances
Protocentral_ADS1220 pc_ads1220right;
Protocentral_ADS1220 pc_ads1220left;

// ============================================================================
// FREERTOS MULTI-TASKING CONFIGURATION
// ============================================================================

#define ADC_QUEUE_LENGTH    120000          // 120,000 samples buffer
#define SAMPLING_INTERVAL   1               // 1ms = 1000 Hz sampling
#define SENDER_BATCH_SIZE   100             // 100 samples per transmission
#define SAMPLER_TASK_PRIORITY (configMAX_PRIORITIES - 1)
#define SENDER_TASK_PRIORITY  (tskIDLE_PRIORITY + 2)
#define SAMPLER_STACK_SIZE   (configMINIMAL_STACK_SIZE * 16)
#define SENDER_STACK_SIZE    (configMINIMAL_STACK_SIZE * 10)
#define JSON_BUFFER_SIZE     5000

typedef struct {
    float right;
    float left;
    uint32_t timestamp;
} Sample_t;

// Dynamic buffer allocation in PSRAM
Sample_t* sampleBuffer = nullptr;
int sampleIndex = 0;
TaskHandle_t xSamplerTaskHandle = NULL;
TaskHandle_t xSenderTaskHandle = NULL;

// System state 
enum SystemState {
    Idle_state,
    Sampling_state,
    Sending_state
};
volatile SystemState systemState = Idle_state;

// ============================================================================
// WIFI AND WEBSOCKET CONFIGURATION
// ============================================================================

// WiFi credentials
const char* ssid = "***REMOVED***";
const char* password = "***REMOVED***";

// Socket.IO configuration  
const char* websocket_host = "192.168.1.158";  // Change this to your computer's network IP
const uint16_t websocket_port = 5000;           // Backend port
const char* websocket_path = "/ws";  // Raw WebSocket path

WebSocketsClient webSocket;

// ============================================================================
// WEBSOCKET EVENT HANDLER
// ============================================================================

void onWebSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
    switch(type) {
        case WStype_DISCONNECTED:
            Serial.println("Disconnected from backend");
            systemState = Idle_state;
            break;

        case WStype_CONNECTED:
            Serial.println("Connected to backend server (Raw WebSocket)");
            // Send simple registration message
            webSocket.sendTXT("{\"type\":\"esp32\"}");
            // Wait for start command from frontend
            systemState = Idle_state;
            sampleIndex = 0;
            Serial.println("Waiting for frontend to start test");
            break;

        case WStype_TEXT: {
            String msg = String((char*)payload).substring(0, length);
            
            // Handle registration confirmation
            if (msg.indexOf("registered") > 0) {
                Serial.println("Registration confirmed by backend");
                break;
            }

            // Handle pong responses
            if (msg.indexOf("pong") > 0) {
                break; // Ignore pong responses
            }

            // Parse JSON commands (simple format)
            JsonDocument doc;
            DeserializationError error = deserializeJson(doc, msg);
            if (error) {
                break;
            }

            String cmd = "";
            if (doc["cmd"].is<String>()) {
                cmd = doc["cmd"].as<String>();
            } else if (doc["command"].is<String>()) {
                cmd = doc["command"].as<String>();
            }

            if (cmd == "start") {
                sampleIndex = 0;
                systemState = Sampling_state;
                Serial.println("Backend commanded: START");
            } else if (cmd == "stop") {
                systemState = Idle_state;
                Serial.println("Backend commanded: STOP - Sampling paused");
            }
            break;
        }

        case WStype_ERROR:
            Serial.printf("WebSocket Error: %s\n", payload);
            break;

        default:
            break;
    }
}

// ============================================================================
// FREERTOS SAMPLING TASK
// ============================================================================

void vSamplerTask(void *pvParameters) {
    sampleIndex = 0;

    for(;;) {
        if (systemState != Sampling_state) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        bool gotLeft = false, gotRight = false;
        Sample_t sample;
        uint32_t now = millis();

        // Poll both sensors until we get readings
        while (!gotLeft || !gotRight) {
            if (!gotLeft && digitalRead(LEFT_ADS1220_DRDY_PIN) == LOW) {
                int32_t raw_left = pc_ads1220left.Read_Data_Samples();
                gotLeft = true;
                sample.left = raw_left;
            }

            if (!gotRight && digitalRead(RIGHT_ADS1220_DRDY_PIN) == LOW) {
                int32_t raw_right = pc_ads1220right.Read_Data_Samples();
                gotRight = true;
                sample.right = raw_right;
            }
            
            delayMicroseconds(10); // Short delay to avoid tight loop
        }

        sample.timestamp = now;

        // Store sample in buffer if space available
        if (sampleIndex < ADC_QUEUE_LENGTH) {
            sampleBuffer[sampleIndex++] = sample;
        } else {
            Serial.println("Sampler: Buffer full, switching to sending state");
            systemState = Sending_state;
            Serial.println(millis());
        }

        // Auto-send every 100 samples for real-time streaming
        if (sampleIndex % 100 == 0) {
            systemState = Sending_state; // Auto-send every 100 samples
            vTaskDelay(5); // Yield to other tasks
        }

        // Wait for next sampling interval
        vTaskDelay(pdMS_TO_TICKS(SAMPLING_INTERVAL));
    }
}

// ============================================================================
// FREERTOS SENDING TASK
// ============================================================================

void vSenderTask(void *pvParameters) {
    JsonDocument doc;

    for (;;) {
        if (systemState != Sending_state) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        size_t i = 0;
        while (i < sampleIndex) {
            doc.clear();
            JsonArray batch = doc["samples"].to<JsonArray>();

            // Send batches of SENDER_BATCH_SIZE samples
            for (int j = 0; j < SENDER_BATCH_SIZE && i < sampleIndex; ++j, ++i) {
                JsonObject obj = batch.add<JsonObject>();
                obj["t"] = sampleBuffer[i].timestamp;
                obj["l"] = sampleBuffer[i].left;
                obj["r"] = sampleBuffer[i].right;
            }

            String payload;
            serializeJson(doc, payload);
            // Send data via Raw WebSocket (optimal for Flutter)
            webSocket.sendTXT(payload);
            vTaskDelay(pdMS_TO_TICKS(1)); // Minimal delay for real-time streaming
        }
        
        // Reset sample index and restart sampling for continuous operation
        sampleIndex = 0;
        systemState = Sampling_state;
    }
}

// ============================================================================
// ADS1220 INITIALIZATION 
// ============================================================================

void initializeADS1220() {
    Serial.println("Initializing ADS1220 modules ...");
    
    SPI.begin(13, 12, 11); 

    pinMode(LEFT_ADS1220_DRDY_PIN, INPUT_PULLUP);
    pinMode(RIGHT_ADS1220_DRDY_PIN, INPUT_PULLUP);

    // Initialize left ADS1220 
    pc_ads1220left.begin(LEFT_ADS1220_CS_PIN, LEFT_ADS1220_DRDY_PIN);
    pc_ads1220left.set_pga_gain(PGA_GAIN_128);
    pc_ads1220left.set_OperationMode(MODE_NORMAL);
    pc_ads1220left.set_data_rate(DR_1000SPS);
    pc_ads1220left.set_conv_mode_continuous();
    pc_ads1220left.select_mux_channels(MUX_AIN0_AIN1);
    pc_ads1220left.Start_Conv();
    delayMicroseconds(50); // Allow time for ADS1220 to stabilize

    // Print left registers for verification
    Serial.println("Left ADS1220 registers:");
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG0_ADDRESS), HEX);
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG1_ADDRESS), HEX);
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG2_ADDRESS), HEX);
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG3_ADDRESS), HEX);

    // Initialize right ADS1220 
    pc_ads1220right.begin(RIGHT_ADS1220_CS_PIN, RIGHT_ADS1220_DRDY_PIN);
    pc_ads1220right.set_pga_gain(PGA_GAIN_128);
    pc_ads1220right.set_OperationMode(MODE_NORMAL);
    pc_ads1220right.set_data_rate(DR_1000SPS);
    pc_ads1220right.set_conv_mode_continuous();
    pc_ads1220right.select_mux_channels(MUX_AIN0_AIN1);
    pc_ads1220right.Start_Conv();
    delayMicroseconds(50); // Allow time for ADS1220 to stabilize

    // Print right registers for verification 
    Serial.println("Right ADS1220 registers:");
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG0_ADDRESS), HEX);
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG1_ADDRESS), HEX);
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG2_ADDRESS), HEX);
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG3_ADDRESS), HEX);

    Serial.println("ADS1220 modules initialized");
}

// ============================================================================
// MAIN SETUP 
// ============================================================================

void setup() {
    Serial.begin(115200);
    while (!Serial);
    Serial.println("--- ADS1220 Dual Polling Sampler ---");
    Serial.println("FreeRTOS Multi-Tasking Architecture");
    Serial.println("=====================================================================");
    
    // Initialize ADS1220
    initializeADS1220();

    // Initialize FreeRTOS buffer in PSRAM
    sampleBuffer = (Sample_t*)ps_malloc(sizeof(Sample_t) * ADC_QUEUE_LENGTH);
    if (!sampleBuffer) {
        Serial.println("ERROR: Failed to allocate sample buffer in PSRAM.");
        while (1);  // halt
    }

    // Connect WiFi 
    Serial.printf("Connecting to WiFi: %s\n", ssid);
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println();
    Serial.printf("WiFi connected! IP: %s\n", WiFi.localIP().toString().c_str());

    // Setup Raw WebSocket connection  
    Serial.printf("Connecting to Raw WebSocket: %s:%d%s\n", websocket_host, websocket_port, websocket_path);
    webSocket.begin(websocket_host, websocket_port, websocket_path);
    webSocket.onEvent(onWebSocketEvent);
    webSocket.setReconnectInterval(2000); // Fast reconnection for real-time

    // Memory info
    Serial.printf("Free heap: %u bytes\n", ESP.getFreeHeap());
    Serial.printf("Free PSRAM: %u bytes\n", ESP.getFreePsram());

    // Create FreeRTOS tasks
    xTaskCreate(vSamplerTask, "SamplerTask", SAMPLER_STACK_SIZE, NULL, SAMPLER_TASK_PRIORITY, &xSamplerTaskHandle);
    xTaskCreate(vSenderTask, "SenderTask", SENDER_STACK_SIZE, NULL, SENDER_TASK_PRIORITY, &xSenderTaskHandle);
    
    Serial.println("Setup complete. FreeRTOS tasks created.");
    Serial.println("Waiting for WebSocket connection...");
    Serial.println();
    Serial.println("=== REAL-TIME DATA STREAMING ===");
    Serial.println("Sampling at 1000 Hz, sending to backend in batches");
    Serial.println("==================================");
}

// ============================================================================
// MAIN LOOP 
// ============================================================================

void loop() {
    // Handle WebSocket communication (real-time)
    webSocket.loop();
    
    // Send periodic ping to keep connection alive (Raw WebSocket format)
    static unsigned long lastPing = 0;
    if (millis() - lastPing > 25000) { // Every 25 seconds
        webSocket.sendTXT("{\"ping\":true}"); // Simple JSON ping
        lastPing = millis();
    }
    
    // Minimal delay for real-time performance
    vTaskDelay(pdMS_TO_TICKS(10));
}