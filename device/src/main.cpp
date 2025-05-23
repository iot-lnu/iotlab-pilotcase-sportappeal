#include <SPI.h>
#include "Protocentral_ADS1220.h"
#include <task.h>
#include <queue.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

#define DEBUG 0
#define PGA 128
#define VREF 3.300
#define VFSR VREF/PGA
#define FSR (((long int)1<<23)-1)
#define LEFT_OFFSET 14900
#define RIGHT_OFFSET 16800
#define COUNTS_TO_NEWTONS_LEFT 0.001095f
#define COUNTS_TO_NEWTONS_RIGHT 0.0008938f
#define MV_TO_NEWTONS 294.3f // 294.3 mV/N

#define ADS1220_CS_PIN    7
#define ADS1220_DRDY_PIN  2

Protocentral_ADS1220 pc_ads1220;

#define MQTT_MAX_PACKET_SIZE 5120

#define ADC_QUEUE_LENGTH    50000
#define SENDER_BATCH_SIZE   100
#define SAMPLER_TASK_PRIORITY (configMAX_PRIORITIES - 1)
#define SENDER_TASK_PRIORITY  (tskIDLE_PRIORITY + 2)
#define SAMPLER_STACK_SIZE   (configMINIMAL_STACK_SIZE * 8)
#define SENDER_STACK_SIZE    (configMINIMAL_STACK_SIZE * 10)
#define JSON_BUFFER_SIZE     5000 //1024

typedef struct {
    float right;
    float left;
    uint32_t timestamp;
} Sample_t;

QueueHandle_t xAdcQueue;
TaskHandle_t xSamplerTaskHandle = NULL;
TaskHandle_t xSenderTaskHandle = NULL;
SemaphoreHandle_t xAdcMutex;

// WiFi credentials 
const char* ssid = "***REMOVED***";
const char* password = "***REMOVED***";

// MQTT server details
const char* mqtt_server = "***REMOVED***";
const int mqtt_port = ***REMOVED***;
const char* mqtt_user = "***REMOVED***"; 
const char* mqtt_key  = "***REMOVED***";
const char* mqtt_data_topic = "loadcells"; 
WiFiClient espClient;
PubSubClient client(espClient);


// --- Sampler Task ---
void vSamplerTask(void *pvParameters) {
    Sample_t sample;

    for (;;) {
       /* Serial.println(isPaused ? "Paused" : "Running");
        if (isPaused) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }*/ // Debugging

        uint32_t now = millis();
        xSemaphoreTake(xAdcMutex, portMAX_DELAY);

        // --- Left Sensor (AIN0–AIN1) ---
        pc_ads1220.select_mux_channels(MUX_AIN0_AIN1);
        pc_ads1220.set_conv_mode_single_shot();
        pc_ads1220.Start_Conv();
        while (digitalRead(ADS1220_DRDY_PIN) == HIGH);
        int32_t raw_left = pc_ads1220.Read_Data_Samples();
        float force_left = (raw_left - LEFT_OFFSET) * COUNTS_TO_NEWTONS_LEFT;

        // --- Right Sensor (AIN2–AIN3) ---
        pc_ads1220.select_mux_channels(MUX_AIN2_AIN3);
        pc_ads1220.set_conv_mode_single_shot();
        pc_ads1220.Start_Conv();
        while (digitalRead(ADS1220_DRDY_PIN) == HIGH);
        int32_t raw_right = pc_ads1220.Read_Data_Samples();
        float force_right = (raw_right - RIGHT_OFFSET) * COUNTS_TO_NEWTONS_RIGHT;

        xSemaphoreGive(xAdcMutex);

        sample.timestamp = now;
        sample.left = force_left;   
        //sample.left = raw_left; //debugging
        sample.right = force_right; 
        //sample.right = raw_right; //debugging
        Serial.printf("Left: %.2f N, Right: %.2f N\n", force_left, force_right);
        if (xQueueSend(xAdcQueue, &sample, 10) != pdPASS) {
            Serial.println("Sampler: Queue full!");
        }

        vTaskDelay(pdMS_TO_TICKS(2)); // ~500 Hz
    }
}

static void sendDataBatch(Sample_t *dataBuffer, size_t count) {
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
        Serial.printf("Published %d samples to MQTT.\n", count);
        //client.publish(mqtt_topic, "hello", 5);// debugging
        //const char* testPayload = "{\"sensor_id\":1,\"value\":123}";
        //client.publish(mqtt_topic, testPayload);
        //Serial.println(payload); // Debugging
        Serial.println(len);  // Debugging
        Serial.println(millis()); // Debugging
    } else {
        Serial.println("MQTT not connected. Skipping publish.");
    }
}

void flushSampleQueue() {
    Sample_t dataBuffer[SENDER_BATCH_SIZE];
    int bufferIndex = 0;

    Serial.println("Flushing ADC queue...");

    while (uxQueueMessagesWaiting(xAdcQueue) > 0) {
        if (xQueueReceive(xAdcQueue, &dataBuffer[bufferIndex], 0) == pdPASS) {
            bufferIndex++;
            if (bufferIndex >= SENDER_BATCH_SIZE) {
                sendDataBatch(dataBuffer, bufferIndex);
                bufferIndex = 0;
            }
        } else {
            break;
        }
    }

    // Send any remaining partial batch
    if (bufferIndex > 0) {
        sendDataBatch(dataBuffer, bufferIndex);
    }

    Serial.println("ADC queue flushed.");
}

// --- Sender Task ---
void vSenderTask(void *pvParameters) {
    static Sample_t dataBuffer[SENDER_BATCH_SIZE];
    int bufferIndex = 0;
    BaseType_t xResult;

    Serial.println("Sender task started, waiting for MQTT...");

    // Wait until MQTT is connected before publishing hello
    while (!client.connected()) {
        vTaskDelay(pdMS_TO_TICKS(500));
    }

    for (;;) {
        xResult = xQueueReceive(xAdcQueue, &dataBuffer[bufferIndex], portMAX_DELAY);
        if (xResult == pdPASS) {
            bufferIndex++;
            if (bufferIndex >= SENDER_BATCH_SIZE) {
                sendDataBatch(dataBuffer, SENDER_BATCH_SIZE);
                bufferIndex = 0;
            }
        }
    }
}

// --- MQTT reconnect function ---
void reconnectMQTT() {
    static unsigned long lastAttempt = 0;
    const unsigned long retryInterval = 5000; // ms

    if (millis() - lastAttempt < retryInterval) return; // Skip if too soon
    lastAttempt = millis();

    Serial.print("Attempting MQTT connection...");
    if (client.connect(mqtt_user, mqtt_user, mqtt_key)) {
        Serial.println("connected");
    } else {
        Serial.print("failed, rc=");
        Serial.print(client.state());
        Serial.println(" try again later");
    }
}


// --- MQTT loop handler (FreeRTOS task) ---
void vMqttLoopTask(void *pvParameters) {
    for (;;) {
        client.loop();
        
        if (!client.connected()) {
            Serial.print("MQTT disconnected, state: ");
            Serial.println(client.state());
            reconnectMQTT();
        }

        vTaskDelay(pdMS_TO_TICKS(100));
    }
}


// --- Setup ---
void setup() {
    Serial.begin(115200);
    while (!Serial);
    Serial.println("--- FreeRTOS ADS1220 MQTT Sampler ---");

    // Setup WiFi
    Serial.print("Connecting to WiFi...");
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println("Connected.");

    // Initialize ADS1220
    pc_ads1220.begin(ADS1220_CS_PIN, ADS1220_DRDY_PIN);
    pc_ads1220.set_pga_gain(PGA_GAIN_128);
    pc_ads1220.set_OperationMode(MODE_NORMAL);
    pc_ads1220.set_data_rate(DR_1000SPS); 
    
    pinMode(ADS1220_DRDY_PIN, INPUT_PULLUP);

    // Setup MQTT
    client.setServer(mqtt_server, mqtt_port);
    client.setKeepAlive(60);
    client.setBufferSize(MQTT_MAX_PACKET_SIZE);
    
    // Create ADC sample queue
    xAdcQueue = xQueueCreate(ADC_QUEUE_LENGTH, sizeof(Sample_t));
    if (xAdcQueue == NULL) {
        Serial.println("Error creating ADC queue!");
        while (1);
    }

    // Create ADC mutex
    xAdcMutex = xSemaphoreCreateMutex();
    if (xAdcMutex == NULL) {
        Serial.println("Error creating mutex!");
        while (1);
    }

    // Create FreeRTOS tasks
    xTaskCreate(vMqttLoopTask, "MQTTLoop", configMINIMAL_STACK_SIZE * 4, NULL, tskIDLE_PRIORITY + 1, NULL);
    xTaskCreate(vSamplerTask, "SamplerTask", SAMPLER_STACK_SIZE, NULL, SAMPLER_TASK_PRIORITY, &xSamplerTaskHandle);
    xTaskCreate(vSenderTask, "SenderTask", SENDER_STACK_SIZE, NULL, SENDER_TASK_PRIORITY, &xSenderTaskHandle);
    

    // Manually kick off the first conversion to start the interrupt-sampling loop
    pc_ads1220.select_mux_channels(MUX_AIN0_AIN1); // Start with channel 1
    pc_ads1220.set_conv_mode_single_shot();
    pc_ads1220.Start_Conv();

    Serial.println("Setup complete.");
}


void loop() {
    vTaskDelay(pdMS_TO_TICKS(100)); // Minimal loop use
}

