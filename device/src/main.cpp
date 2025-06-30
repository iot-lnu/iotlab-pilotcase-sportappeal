#include <SPI.h>
#include "Protocentral_ADS1220.h"
#include <task.h>
#include <queue.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <LittleFS.h>
#include <FS.h>
#include <ESPAsyncWebServer.h>
#include <AsyncWebSocket.h>
#include <AsyncTCP.h>



// --- Constants ---
#define PGA 128
#define VREF 3.300
#define LEFT_OFFSET -12700 //moved responsibility to backend
#define RIGHT_OFFSET -17500 //moved responsibility to backend
#define COUNTS_TO_NEWTONS_LEFT 0.001095f //moved responsibility to backend
#define COUNTS_TO_NEWTONS_RIGHT 0.0008938f //moved responsibility to backend

// --- Pin Config ---
#define LEFT_ADS1220_CS_PIN     8
#define LEFT_ADS1220_DRDY_PIN   4
#define RIGHT_ADS1220_CS_PIN    7
#define RIGHT_ADS1220_DRDY_PIN  2

Protocentral_ADS1220 pc_ads1220right;
Protocentral_ADS1220 pc_ads1220left;

// --- FreeRTOS ---
#define ADC_QUEUE_LENGTH    120000
#define SAMPLING_INTERVAL 1 // in milliseconds
#define SENDER_BATCH_SIZE   50
#define SAMPLER_TASK_PRIORITY (configMAX_PRIORITIES - 1)
#define SENDER_TASK_PRIORITY  (tskIDLE_PRIORITY + 2)
#define SAMPLER_STACK_SIZE   (configMINIMAL_STACK_SIZE * 8)
#define SENDER_STACK_SIZE    (configMINIMAL_STACK_SIZE * 10)
#define JSON_BUFFER_SIZE     5000

typedef struct {
    float right;
    float left;
    uint32_t timestamp;
} Sample_t;

QueueHandle_t xAdcQueue;
Sample_t* sampleBuffer = nullptr;
int sampleIndex = 0;//_
TaskHandle_t xSamplerTaskHandle = NULL;
TaskHandle_t xSenderTaskHandle = NULL;
SemaphoreHandle_t xAdcMutex;
enum SystemState{//_
    Sampling_state,
    Sending_state,
    Idle_state
};
volatile SystemState systemState = Idle_state;//_

File csvFile; // File for storing CSV data
const char* CSV_PATH = "/samples.csv";

// --- WiFi ---
const char* ssid = "***REMOVED***";
const char* password = "***REMOVED***";
// --- MQTT --- no longer needed can be removed
const char* mqtt_server = "***REMOVED***";
const int mqtt_port = ***REMOVED***;
const char* mqtt_user = "***REMOVED***"; 
const char* mqtt_key  = "***REMOVED***";
const char* mqtt_data_topic = "loadcells"; 
WiFiClient espClient;
PubSubClient client(espClient);

AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

void handleWebSocketMessage(void *arg, uint8_t *data, size_t len) {
  AsyncWebSocketClient *client = (AsyncWebSocketClient *)arg;
  if (len == 0) return;

  String message = String((char *)data);
  Serial.printf("WebSocket message received: %s\n", message.c_str());
  if (message == "start") {
    // Erase previous file
    LittleFS.remove(CSV_PATH);
    csvFile = LittleFS.open(CSV_PATH, FILE_WRITE);
    if (!csvFile) {
        Serial.println("Failed to create CSV file.");
    } else {
        csvFile.println("timestamp,left,right");  // optional CSV header
        csvFile.flush();
    }
    sampleIndex = 0; // Reset sample index
    systemState = Sampling_state;
    Serial.println("Sampling started");
  } else if (message == "stop" || message == "stopt") {
    csvFile.flush(); // Ensure all data is written
    csvFile.close(); // Close the file when sampling stops
    systemState = Sending_state;
    Serial.println("Sampling stopped. Sending data...");
  } 
}

// --- Handle WebSocket Event ---
void onEvent(AsyncWebSocket *server, AsyncWebSocketClient *client,
             AwsEventType type, void *arg, uint8_t *data, size_t len) {
  if (type == WS_EVT_DATA) {
    handleWebSocketMessage(client, data, len);
  }
}


// --- Sender Task ---
static void sendDataBatch(Sample_t *dataBuffer, size_t count) {//no longer needed can be removed
    StaticJsonDocument<JSON_BUFFER_SIZE> doc;
    JsonArray dataArray = doc.createNestedArray("data");

    for (size_t i = 0; i < count; i++) {
        JsonObject obj = dataArray.createNestedObject();
        obj["Time"] = dataBuffer[i].timestamp;
        obj["left"] = dataBuffer[i].left;
        obj["right"] = dataBuffer[i].right;
    }

    char payload[JSON_BUFFER_SIZE];
    size_t len = serializeJson(doc, payload, sizeof(payload));
    if (client.connected()) {
        client.publish(mqtt_data_topic, payload);
        /*Serial.printf("Published %d samples to MQTT.\n", count);
        Serial.println(millis());//debug*/
    } else {
        Serial.println("MQTT not connected. Skipping publish.");
    }
}

// --- Polling Sampler Task ---
void vSamplerTask(void *pvParameters) {
    sampleIndex = 0;//_

    for(;;){
        if (systemState != Sampling_state) {//_
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        bool gotLeft = false, gotRight = false;
        Sample_t sample;
        uint32_t now = millis();

        while (!gotLeft || !gotRight) {
            if (!gotLeft && digitalRead(LEFT_ADS1220_DRDY_PIN) == LOW) {
                int32_t raw_left = pc_ads1220left.Read_Data_Samples();
                gotLeft = true;
                sample.left = raw_left;
                //Serial.print("L");
                //Serial.println(raw_left);
            }

            if (!gotRight && digitalRead(RIGHT_ADS1220_DRDY_PIN) == LOW) {
                int32_t raw_right = pc_ads1220right.Read_Data_Samples();
                gotRight = true;
                sample.right = raw_right;
                //Serial.print("R");
                //Serial.println(raw_right);
            }
            
            //vTaskDelay(pdMS_TO_TICKS(1)); // Short delay to avoid tight loop
            delayMicroseconds(10);
        }
        
            if (sampleIndex%1000 == 0) {//_
                Serial.print("Sampled 1000 pairs: ");
                Serial.println(millis());
            }

        sample.timestamp = now;
        if (csvFile) {
            csvFile.printf("%lu,%.2f,%.2f\n", sample.timestamp, sample.left, sample.right);
            sampleIndex++;
            if (sampleIndex % 1000 == 0) {
                csvFile.flush();  // optional, but safer if power loss risk
            }
        } else {
            Serial.println("CSV file not open");
        }

        if (sampleIndex >= ADC_QUEUE_LENGTH) {
            sampleIndex = 0; // Reset index if buffer is full
            Serial.println("Sampler: Buffer full, resetting index.");
            systemState = Sending_state; // Switch to sending state
            Serial.println(millis());
        }
        /*if (xQueueSend(xAdcQueue, &sample, 0) != pdPASS) {
            Serial.println("Sampler: Queue full!");
        }*/
    }
}

// --- Sender Task ---
void vSenderTask(void *pvParameters) {
    for (;;) {
        if (systemState != Sending_state) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        File f = LittleFS.open(CSV_PATH, FILE_READ);
        if (!f) {
            Serial.println("Failed to open CSV file for sending.");
            systemState = Idle_state;
            continue;
        }

        while (f.available()) {
            String line = f.readStringUntil('\n');
            ws.textAll(line);
            vTaskDelay(pdMS_TO_TICKS(1));  // yield to WiFi
        }

        f.close();
        ws.textAll("Download complete");
        Serial.println("Finished sending CSV file.");
        systemState = Idle_state;
    }
}


// --- MQTT ---
void reconnectMQTT() {// no longer needed can be removed
    static unsigned long lastAttempt = 0;
    const unsigned long retryInterval = 5000;
    if (millis() - lastAttempt < retryInterval) return;
    lastAttempt = millis();

    if (client.connect(mqtt_user, mqtt_user, mqtt_key)) {
        Serial.println("MQTT connected.");
    } else {
        Serial.print("MQTT failed. State: ");
        Serial.println(client.state());
    }
}

void vMqttLoopTask(void *pvParameters) {// no longer needed can be removed
    for (;;) {
        client.loop();
        if (!client.connected()) {
            reconnectMQTT();
        }
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

// --- Setup ---
void setup() {
    Serial.begin(115200);
    while (!Serial);
    Serial.println("--- ADS1220 Dual Polling Sampler ---");
    SPI.begin(13,12,11); // SCK, MISO, MOSI pins 
    // Connect WiFi
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println(" WiFi connected.");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    // Initialize LittleFS
    if (!LittleFS.begin(true)) {
        Serial.println("LittleFS Mount Failed");
        return;
    }

    Serial.println("Listing files in LittleFS:");
    File root = LittleFS.open("/");
    File file = root.openNextFile();
    while (file) {
        Serial.printf("  %s - size: %d\n", file.name(), file.size());
        file = root.openNextFile();
    }

    // Setup WebSocket
    ws.onEvent(onEvent);
    server.addHandler(&ws);
    server.serveStatic("/", LittleFS, "/").setDefaultFile("index.html");
    server.onNotFound([](AsyncWebServerRequest *request){
        request->send(404, "text/plain", "Not Found");
    });
    server.begin();
    Serial.println("Web server started.");
    delay(500);

    File f = LittleFS.open("/index.html", "r");
    while (f.available()) {
        Serial.write(f.read());  // Print file content to serial monitor
    }
    f.close();

    // Init pins
    pinMode(LEFT_ADS1220_DRDY_PIN, INPUT_PULLUP);
    pinMode(RIGHT_ADS1220_DRDY_PIN, INPUT_PULLUP);

    // Init ADS1220 Left
    pc_ads1220left.begin(LEFT_ADS1220_CS_PIN, LEFT_ADS1220_DRDY_PIN);
    pc_ads1220left.set_pga_gain(PGA_GAIN_128);
    pc_ads1220left.set_OperationMode(MODE_NORMAL);
    pc_ads1220left.set_data_rate(DR_1000SPS);
    pc_ads1220left.set_conv_mode_continuous();
    pc_ads1220left.select_mux_channels(MUX_AIN0_AIN1);
    pc_ads1220left.Start_Conv();
    delayMicroseconds(50); // Allow time for ADS1220 to stabilize
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG0_ADDRESS), HEX);
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG1_ADDRESS), HEX);
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG2_ADDRESS), HEX);
    Serial.println(pc_ads1220left.readRegister(CONFIG_REG3_ADDRESS), HEX);
    // Init ADS1220 Right
    pc_ads1220right.begin(RIGHT_ADS1220_CS_PIN, RIGHT_ADS1220_DRDY_PIN);
    pc_ads1220right.set_pga_gain(PGA_GAIN_128);
    pc_ads1220right.set_OperationMode(MODE_NORMAL);
    pc_ads1220right.set_data_rate(DR_1000SPS);
    pc_ads1220right.set_conv_mode_continuous();
    pc_ads1220right.select_mux_channels(MUX_AIN0_AIN1);
    pc_ads1220right.Start_Conv();
    delayMicroseconds(50); // Allow time for ADS1220 to stabilize
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG0_ADDRESS), HEX);
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG1_ADDRESS), HEX);
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG2_ADDRESS), HEX);
    Serial.println(pc_ads1220right.readRegister(CONFIG_REG3_ADDRESS), HEX);
    Serial.println("ADS1220 initialized.");
    

    // MQTT setup no longer needed can be removed
    /*client.setServer(mqtt_server, mqtt_port);
    client.setKeepAlive(60);
    client.setBufferSize(5120);
    client.connect(mqtt_user, mqtt_user, mqtt_key);
    if (!client.connected()) {
        Serial.println("MQTT connection failed!");
    } else {
        Serial.println("MQTT connected successfully.");
    }*/



    // Queues and tasks
    xAdcQueue = xQueueCreate(ADC_QUEUE_LENGTH, sizeof(Sample_t));
    xAdcMutex = xSemaphoreCreateMutex();
    sampleBuffer = (Sample_t*)ps_malloc(sizeof(Sample_t) * ADC_QUEUE_LENGTH);//_
    if (!sampleBuffer) {
    Serial.println("ERROR: Failed to allocate sample buffer in PSRAM.");
    while (1);  // halt
    }
    //xTaskCreate(vMqttLoopTask, "MQTTLoop", configMINIMAL_STACK_SIZE * 4, NULL, tskIDLE_PRIORITY + 1, NULL);
    xTaskCreate(vSamplerTask, "SamplerTask", SAMPLER_STACK_SIZE, NULL, SAMPLER_TASK_PRIORITY, &xSamplerTaskHandle);
    xTaskCreate(vSenderTask, "SenderTask", SENDER_STACK_SIZE, NULL, SENDER_TASK_PRIORITY, &xSenderTaskHandle);
}

void loop() {
    vTaskDelay(pdMS_TO_TICKS(1000));
    Serial.println(systemState);
}
