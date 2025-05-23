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
#define LEFT_OFFSET 14900 //offset for left sensor found through measurements
#define RIGHT_OFFSET 16800 //offset for right sensor found through measurements
#define COUNTS_TO_NEWTONS_LEFT 0.001095f // conversion factor for left sensor
#define COUNTS_TO_NEWTONS_RIGHT 0.0008938f // conversion factor for right sensor
#define MV_TO_NEWTONS 294.3f // 294.3 mV/N

#define ADS1220_CS_PIN    7
#define ADS1220_DRDY_PIN  2

Protocentral_ADS1220 pc_ads1220;

#define MQTT_MAX_PACKET_SIZE 5120

#define ADC_QUEUE_LENGTH    50000
#define SENDER_BATCH_SIZE   100 // Number of samples to send in one batch
#define SAMPLER_TASK_PRIORITY (configMAX_PRIORITIES - 1)
#define SENDER_TASK_PRIORITY  (tskIDLE_PRIORITY + 2)
#define SAMPLER_STACK_SIZE   (configMINIMAL_STACK_SIZE * 8)
#define SENDER_STACK_SIZE    (configMINIMAL_STACK_SIZE * 10)
#define JSON_BUFFER_SIZE     5000 //Maximum size of JSON payload

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
const char* mqtt_server = "***REMOVED***"; // MQTT server IP address
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
        sample.right = force_right; 
        //Serial.printf("Left: %.2f N, Right: %.2f N\n", force_left, force_right); // Debugging
        if (xQueueSend(xAdcQueue, &sample, 10) != pdPASS) {
            Serial.println("Sampler: Queue full!");
        }

        vTaskDelay(pdMS_TO_TICKS(2)); // ~500 Hz set to 1 for 1000 Hz 
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
    } else {
        Serial.println("MQTT not connected. Skipping publish.");
    }
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

