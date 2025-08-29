#include <SPI.h>
#include "Protocentral_ADS1220.h"
#include <task.h>
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>
#include <WebSocketsClient.h>



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
#define SENDER_BATCH_SIZE   100
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

Sample_t* sampleBuffer = nullptr;
int sampleIndex = 0;//_
TaskHandle_t xSamplerTaskHandle = NULL;
TaskHandle_t xSenderTaskHandle = NULL;

enum SystemState{//_
    Sampling_state,
    Sending_state,
    Idle_state
};
volatile SystemState systemState = Idle_state;//_

// --- WiFi ---
#include "wifi.env" //Add your wifi credentials here see format in wifi.env.example
const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;
// --- Web Server ---
#include "ip.env" //Add your ip credentials here see format in ip.env.example
const char* websocket_host = ip;
const uint16_t websocket_port = 3000;

WebSocketsClient webSocket;

void onWebSocketEvent(WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.println("[WS] Disconnected");
      break;

    case WStype_CONNECTED:
      Serial.println("[WS] Connected to server");
      webSocket.sendTXT("{\"type\":\"esp\"}");
      break;

    case WStype_TEXT: {
      // Convert payload to String
      String msg = String((char*)payload).substring(0, length);
      Serial.printf("[WS] Message: %s\n", msg.c_str());

      // Parse JSON message
      StaticJsonDocument<200> doc;
      DeserializationError error = deserializeJson(doc, msg);
      if (error) {
        Serial.print("JSON parse failed: ");
        Serial.println(error.c_str());
        break;
      }

      // Check for 'cmd' key
      if (doc.containsKey("cmd")) {
        String cmd = doc["cmd"].as<String>();

        if (cmd == "start") {
          sampleIndex = 0;
          systemState = Sampling_state;
          Serial.println("Sampler: Starting sampling.");
        } else if (cmd == "stop") {
          systemState = Sending_state;
          Serial.println("Sampler: Stopping sampling, switching to sending state.");
          Serial.printf("Sampled %d pairs.\n", sampleIndex);
        } else {
          Serial.print("Unknown command: ");
          Serial.println(cmd);
        }
      } else {
        Serial.println("No cmd key in message");
      }

      break;
    }

    default:
      break;
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

        sample.timestamp = now;

       /* if (csvFile) {
            csvFile.printf("%lu,%.2f,%.2f\n", sample.timestamp, sample.left, sample.right);
            sampleIndex++;
            if (sampleIndex % 1000 == 0) {
                csvFile.flush();  // optional, but safer if power loss risk
            }
        } else {
            Serial.println("CSV file not open");
        }*/
        
        if (sampleIndex < ADC_QUEUE_LENGTH) {
            sampleBuffer[sampleIndex++] = sample; // Store sample in buffer
        }
        else {
            Serial.println("Sampler: Buffer full, switching to sending state.");
            systemState = Sending_state; // Switch to sending state
            Serial.println(millis());
        }
        /*if (xQueueSend(xAdcQueue, &sample, 0) != pdPASS) {
            Serial.println("Sampler: Queue full!");
        }*/

        if(sampleIndex % 1000 == 0) {
            Serial.print("Sampled 1000 pairs: ");
            Serial.println(millis());
            vTaskDelay(5); // Yield to other tasks
        }   
    }
}

// --- Sender Task ---
void vSenderTask(void *pvParameters) {
  StaticJsonDocument<4096> doc;

  for (;;) {
    if (systemState != Sending_state) {
      vTaskDelay(pdMS_TO_TICKS(100));
      continue;
    }

    size_t i = 0;
    while (i < sampleIndex) {
      doc.clear();
      JsonArray batch = doc.createNestedArray("samples");

      for (int j = 0; j < SENDER_BATCH_SIZE && i < sampleIndex; ++j, ++i) {
        JsonObject obj = batch.createNestedObject();
        obj["t"] = sampleBuffer[i].timestamp;
        obj["l"] = sampleBuffer[i].left;
        obj["r"] = sampleBuffer[i].right;
      }

      String payload;
      serializeJson(doc, payload);
      webSocket.sendTXT(payload);
      vTaskDelay(pdMS_TO_TICKS(10));
      Serial.printf("Sent batch of %d samples, total sent: %d\n", SENDER_BATCH_SIZE, i);
    }

    webSocket.sendTXT("{\"done\":true}");
    Serial.println("Finished sending data");
    systemState = Idle_state;
  }
}

// --- Setup ---
void setup() {
    Serial.begin(115200);
    while (!Serial);
    Serial.println("--- ADS1220 Dual Polling Sampler ---");
    SPI.begin(13,12,11); // SCK, MISO, MOSI pins 

    // Initialize FreeRTOS queue
    sampleBuffer = (Sample_t*)ps_malloc(sizeof(Sample_t) * ADC_QUEUE_LENGTH);//_
    if (!sampleBuffer) {
    Serial.println("ERROR: Failed to allocate sample buffer in PSRAM.");
    while (1);  // halt
    }

    // Connect WiFi
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED) {
        delay(1000);
        Serial.print(".");
    }
    Serial.println(" WiFi connected.");
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());

    // Setup WebSocket
    webSocket.begin(websocket_host, websocket_port, "/ws");
    webSocket.onEvent(onWebSocketEvent);
    webSocket.setReconnectInterval(5000);

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



    // monitor memory
    Serial.printf("Free heap: %u\n", ESP.getFreeHeap());
    Serial.printf("Free PSRAM: %u\n", ESP.getFreePsram());

    // Create tasks
    xTaskCreate(vSamplerTask, "SamplerTask", SAMPLER_STACK_SIZE, NULL, SAMPLER_TASK_PRIORITY, &xSamplerTaskHandle);
    xTaskCreate(vSenderTask, "SenderTask", SENDER_STACK_SIZE, NULL, SENDER_TASK_PRIORITY, &xSenderTaskHandle);
    
    Serial.println("Setup complete.");
}

void loop() {
    webSocket.loop();
    vTaskDelay(pdMS_TO_TICKS(100));
    //Serial.println(systemState);
}
