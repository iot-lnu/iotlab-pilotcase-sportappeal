#include <SPI.h>
#include "Protocentral_ADS1220.h"
#include <task.h>
#include <queue.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// --- Constants ---
#define PGA 128
#define VREF 3.300
#define LEFT_OFFSET 14900
#define RIGHT_OFFSET 16800
#define COUNTS_TO_NEWTONS_LEFT 0.001095f
#define COUNTS_TO_NEWTONS_RIGHT 0.0008938f

// --- Pin Config ---
#define LEFT_ADS1220_CS_PIN     7
#define LEFT_ADS1220_DRDY_PIN   2
#define RIGHT_ADS1220_CS_PIN    8
#define RIGHT_ADS1220_DRDY_PIN  4

Protocentral_ADS1220 pc_ads1220right;
Protocentral_ADS1220 pc_ads1220left;

// --- FreeRTOS ---
#define ADC_QUEUE_LENGTH    50000
#define SENDER_BATCH_SIZE   100
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
TaskHandle_t xSamplerTaskHandle = NULL;
TaskHandle_t xSenderTaskHandle = NULL;
SemaphoreHandle_t xAdcMutex;

// --- WiFi / MQTT ---
const char* ssid = "***REMOVED***";
const char* password = "***REMOVED***";
const char* mqtt_server = "***REMOVED***";
const int mqtt_port = ***REMOVED***;
const char* mqtt_user = "***REMOVED***"; 
const char* mqtt_key  = "***REMOVED***";
const char* mqtt_data_topic = "loadcells"; 
WiFiClient espClient;
PubSubClient client(espClient);

// --- Sender Task ---
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

// --- Polling Sampler Task ---
void vSamplerTask(void *pvParameters) {
    Sample_t sample;

    for (;;) {
        // Wait for both DRDY pins to go LOW
        while (digitalRead(LEFT_ADS1220_DRDY_PIN) == HIGH ||
               digitalRead(RIGHT_ADS1220_DRDY_PIN) == HIGH) {
            vTaskDelay(pdMS_TO_TICKS(1));  // Avoid tight polling loop
        }

        xSemaphoreTake(xAdcMutex, portMAX_DELAY);

        uint32_t now = millis();
        int32_t raw_left = pc_ads1220left.Read_Data_Samples();
        float force_left = (raw_left - LEFT_OFFSET) * COUNTS_TO_NEWTONS_LEFT;

        int32_t raw_right = pc_ads1220right.Read_Data_Samples();
        float force_right = (raw_right - RIGHT_OFFSET) * COUNTS_TO_NEWTONS_RIGHT;

        xSemaphoreGive(xAdcMutex);

        sample.timestamp = now;
        sample.left = force_left;
        sample.right = force_right;

        if (xQueueSend(xAdcQueue, &sample, 0) != pdPASS) {
            Serial.println("Sampler: Queue full!");
        }
    }
}

// --- Sender Task ---
void vSenderTask(void *pvParameters) {
    static Sample_t dataBuffer[SENDER_BATCH_SIZE];
    int bufferIndex = 0;
    BaseType_t xResult;

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

// --- MQTT ---
void reconnectMQTT() {
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

void vMqttLoopTask(void *pvParameters) {
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

    // Connect WiFi
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println(" WiFi connected.");

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

    // Init ADS1220 Right
    pc_ads1220right.begin(RIGHT_ADS1220_CS_PIN, RIGHT_ADS1220_DRDY_PIN);
    pc_ads1220right.set_pga_gain(PGA_GAIN_128);
    pc_ads1220right.set_OperationMode(MODE_NORMAL);
    pc_ads1220right.set_data_rate(DR_1000SPS);
    pc_ads1220right.set_conv_mode_continuous();
    pc_ads1220right.select_mux_channels(MUX_AIN0_AIN1);
    pc_ads1220right.Start_Conv();

    // MQTT setup
    client.setServer(mqtt_server, mqtt_port);
    client.setKeepAlive(60);
    client.setBufferSize(5120);

    // Queues and tasks
    xAdcQueue = xQueueCreate(ADC_QUEUE_LENGTH, sizeof(Sample_t));
    xAdcMutex = xSemaphoreCreateMutex();

    xTaskCreate(vMqttLoopTask, "MQTTLoop", configMINIMAL_STACK_SIZE * 4, NULL, tskIDLE_PRIORITY + 1, NULL);
    xTaskCreate(vSamplerTask, "SamplerTask", SAMPLER_STACK_SIZE, NULL, SAMPLER_TASK_PRIORITY, &xSamplerTaskHandle);
    xTaskCreate(vSenderTask, "SenderTask", SENDER_STACK_SIZE, NULL, SENDER_TASK_PRIORITY, &xSenderTaskHandle);
}

void loop() {
    vTaskDelay(pdMS_TO_TICKS(100));
}
