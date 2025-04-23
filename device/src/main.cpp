#include <SPI.h>
#include "Protocentral_ADS1220.h"
#include <task.h>
#include <queue.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

#define DEBUG 0
#define PGA 1
#define VREF 3.300
#define VFSR VREF/PGA
#define FSR (((long int)1<<23)-1)

#define ADS1220_CS_PIN    7
#define ADS1220_DRDY_PIN  2

Protocentral_ADS1220 pc_ads1220;

#define ADC_QUEUE_LENGTH    50000
#define SENDER_BATCH_SIZE   1000 // How many samples per batch *logic*
#define SAMPLER_TASK_PRIORITY (configMAX_PRIORITIES - 1)
#define SENDER_TASK_PRIORITY  (tskIDLE_PRIORITY + 2)
#define SAMPLER_STACK_SIZE   (configMINIMAL_STACK_SIZE * 8)
#define SENDER_STACK_SIZE    (configMINIMAL_STACK_SIZE * 10) // Increased stack for BLE potentially

typedef struct {
    uint32_t value;
    uint8_t source;
}tagged_adc_sample_t

QueueHandle_t xAdcQueue;
TaskHandle_t xSamplerTaskHandle = NULL;
TaskHandle_t xSenderTaskHandle = NULL;
SemaphoreHandle_t xAdcMutex;

// --- BLE Configuration ---
BLEServer* pServer = NULL;
BLECharacteristic* pDataCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false; // To detect connection changes

// https://www.uuidgenerator.net/
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b" 
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8" 

#define BLE_CHUNK_SIZE 20 

// --- BLE Connection Callbacks ---
class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
      Serial.println("BLE Client Connected");
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
      Serial.println("BLE Client Disconnected");

      BLEDevice::startAdvertising();
      Serial.println("Restart Advertising");
    }
};


// --- Interrupt Service Routine ---
void IRAM_ATTR drdyInterruptHndlr() {
    BaseType_t xHigherPriorityTaskWoken = pdFALSE;
    vTaskNotifyGiveFromISR(xSamplerTaskHandle, &xHigherPriorityTaskWoken);
    if (xHigherPriorityTaskWoken) {
        portYIELD_FROM_ISR();
    }
}

// --- FreeRTOS Tasks ---
void vSamplerTask1(void *pvParameters) {
    tagged_adc_sample_t sample;
    BaseType_t xResult;

    Serial.println("Sampler Task 1 (AIN0-AIN1) started.");

    for (;;) {
        if (xSemaphoreTake(xAdcMutex, portMAX_DELAY)) {
            pc_ads1220.select_mux_channels(MUX_AIN0_AIN1);
            pc_ads1220.set_conv_mode_single_shot();
            pc_ads1220.Start_Conv();

            while (digitalRead(ADS1220_DRDY_PIN) == HIGH);

            sample.value = pc_ads1220.Read_Data_Samples();
            sample.source = 0;  // Tag for sensor 1

            xSemaphoreGive(xAdcMutex);

            xResult = xQueueSend(xAdcQueue, &sample, 10);
            if (xResult != pdPASS) {
                Serial.println("Task1: Queue full!");
            }

            vTaskDelay(pdMS_TO_TICKS(10)); // Sampling interval
        }
    }
}

void vSamplerTask2(void *pvParameters) {
    tagged_adc_sample_t sample;
    BaseType_t xResult;

    Serial.println("Sampler Task 2 (AIN2-AIN3) started.");

    for (;;) {
        if (xSemaphoreTake(xAdcMutex, portMAX_DELAY)) {
            pc_ads1220.select_mux_channels(MUX_AIN2_AIN3);
            pc_ads1220.set_conv_mode_single_shot();
            pc_ads1220.Start_Conv();

            while (digitalRead(ADS1220_DRDY_PIN) == HIGH);

            sample.value = pc_ads1220.Read_Data_Samples();
            sample.source = 1;  // Tag for sensor 2

            xSemaphoreGive(xAdcMutex);

            xResult = xQueueSend(xAdcQueue, &sample, 10);
            if (xResult != pdPASS) {
                Serial.println("Task2: Queue full!");
            }

            vTaskDelay(pdMS_TO_TICKS(10)); // Sampling interval
        }
    }
}

static void sendDataBatch(int32_t *dataBuffer, size_t count) {
    Serial.printf("Processing batch of %d samples...\n", count);

    // Check if a BLE client is connected
    if (!deviceConnected) {
        Serial.println("No BLE client connected. Skipping send.");
        return;
    }

    Serial.println("Sending data over BLE...");

    // Calculate total bytes to send
    size_t totalBytes = count * sizeof(int32_t);
    uint8_t* bytePtr = (uint8_t*)dataBuffer;

    // Send data in chunks
    for (size_t i = 0; i < totalBytes; i += BLE_CHUNK_SIZE) {
        size_t bytesToSend = BLE_CHUNK_SIZE;
        // Check if this is the last chunk and adjust size if necessary
        if (i + BLE_CHUNK_SIZE > totalBytes) {
            bytesToSend = totalBytes - i;
        }

        // Set the characteristic value to the current chunk
        pDataCharacteristic->setValue(&bytePtr[i], bytesToSend);

        // Notify the connected client
        pDataCharacteristic->notify();

        // IMPORTANT: Add a small delay. Sending notifications too fast can overwhelm
        // the BLE stack or the client.
        vTaskDelay(pdMS_TO_TICKS(2));

        if (!deviceConnected) {
             Serial.println("BLE client disconnected during send!");
             break; // Stop sending this batch
        }
    }

    if (deviceConnected) {
      Serial.println("Batch sent over BLE.");
    }
    // --- End BLE Send ---

    #ifdef DEBUG
    Serial.println("--- Serial Data Dump (First 10) ---");
    for (size_t i = 0; i < count && i < 10; i++) {
        float Vout = (float)((dataBuffer[i] * VFSR * 1000.0) / FSR);
        Serial.print(Vout);
        if ((i + 1) % 10 == 0) {
            Serial.println();
        } else {
            Serial.print(", ");
        }
    }
    if (count > 0 && count % 10 != 0) Serial.println();
    Serial.println("--- End Serial Dump ---");
    #endif
}


void vSenderTask(void *pvParameters) {

    static int32_t dataBuffer[SENDER_BATCH_SIZE];
    int bufferIndex = 0;
    BaseType_t xResult;

    Serial.println("Sender Task started.");

    for (;;) {
        xResult = xQueueReceive(xAdcQueue, &dataBuffer[bufferIndex], portMAX_DELAY);

        if (xResult == pdPASS) {
            bufferIndex++;
            if (bufferIndex >= SENDER_BATCH_SIZE) {
                // Buffer is full, send the batch
                sendDataBatch(dataBuffer, SENDER_BATCH_SIZE);
                bufferIndex = 0;
            }
        }

        if (deviceConnected != oldDeviceConnected) {
           oldDeviceConnected = deviceConnected;
           Serial.printf("Connection status changed: %s\n", deviceConnected ? "Connected" : "Disconnected");
        }
    }
}

// --- Setup Function ---
void setup() {
    Serial.begin(115200);
    while (!Serial);
    Serial.println("--- FreeRTOS ADS1220 BLE Sampler ---");

    // Initialize ADS1220
    Serial.println("Initializing ADS1220...");
    pc_ads1220.begin(ADS1220_CS_PIN, ADS1220_DRDY_PIN);
    pc_ads1220.set_data_rate(DR_1000SPS);
    pc_ads1220.set_pga_gain(PGA_GAIN_1);
    pc_ads1220.select_mux_channels(MUX_AIN0_AIN1);
    pc_ads1220.set_conv_mode_continuous();
    Serial.println("ADS1220 Configured.");
    pinMode(ADS1220_DRDY_PIN, INPUT_PULLUP);

    // --- Initialize BLE ---
    Serial.println("Initializing BLE...");
    BLEDevice::init("ESP32_Nano_Sensor"); // Set your BLE device name

    // Create the BLE Server
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new MyServerCallbacks()); // Set connection callbacks

    // Create the BLE Service
    BLEService *pService = pServer->createService(SERVICE_UUID);

    // Create a BLE Characteristic for data
    pDataCharacteristic = pService->createCharacteristic(
                                         CHARACTERISTIC_UUID,
                                         BLECharacteristic::PROPERTY_READ   | 
                                         BLECharacteristic::PROPERTY_NOTIFY  
                                       );

    // Add a descriptor to the characteristic to enable notifications (standard 0x2902)
    pDataCharacteristic->addDescriptor(new BLE2902());

    // Start the service
    pService->start();

    // Start advertising
    BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
    pAdvertising->addServiceUUID(SERVICE_UUID);
    pAdvertising->setScanResponse(true);
    pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
    pAdvertising->setMinPreferred(0x12);
    BLEDevice::startAdvertising();
    Serial.println("BLE Advertising started. Waiting for client connection...");

    // Create the Queue
    xAdcQueue = xQueueCreate(ADC_QUEUE_LENGTH, sizeof(tagged_adc_sample_t));
    if (xAdcQueue == NULL) {
        Serial.println("Error creating ADC queue!");
        while(1);
    } else {
         Serial.println("ADC Queue created.");
    }

    // Create the mutex
    xAdcMutex = xSemaphoreCreateMutex();

    if (xAdcMutex == NULL) {Serial.println("Error creating mutex!"); while (1);} else {Serial.println("Mutex created.");}

    // Create Tasks
    BaseType_t taskResult;
    taskResult = xTaskCreate(vSamplerTask, "SamplerTask", SAMPLER_STACK_SIZE, NULL, SAMPLER_TASK_PRIORITY, &xSamplerTaskHandle);
    if (taskResult != pdPASS) { Serial.println("Error creating Sampler task!"); while(1); } else { Serial.println("Sampler Task created."); }

    taskResult = xTaskCreate(vSenderTask, "SenderTask", SENDER_STACK_SIZE, NULL, SENDER_TASK_PRIORITY, &xSenderTaskHandle);
    if (taskResult != pdPASS) { Serial.println("Error creating Sender task!"); while(1); } else { Serial.println("Sender Task created."); }

    Serial.println("Setup complete.");
}

void loop() {
    vTaskDelay(pdMS_TO_TICKS(1000));
}