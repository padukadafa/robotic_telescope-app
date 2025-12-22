/*
 * Simple ESP32 Telescope Motor Controller
 * Control 2 NEMA 17 stepper motors via WebSocket
 * 
 * Hardware:
 * - ESP32
 * - 2x NEMA 17 Stepper Motors
 * - 2x Stepper Motor Drivers (A4988/DRV8825)
 * 
 * Pin Configuration:
 * Azimuth Motor:  DIR=25, STEP=27
 * Elevation Motor: DIR=26, STEP=28
 * 
 * Library Required:
 * - WebSockets by Markus Sattler (v2.3.6+)
 * - ArduinoJson by Benoit Blanchon (v6.x)
 */

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

// WiFi Configuration
const char* ssid = "RoboticTelescope";
const char* password = "telescope123";

// Network settings
IPAddress local_IP(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

// Motor Pin Definitions
#define AZIMUTH_DIR_PIN 25
#define AZIMUTH_STEP_PIN 27
#define ELEVATION_DIR_PIN 26
#define ELEVATION_STEP_PIN 28

// Motor Parameters
#define STEPS_PER_REVOLUTION 200
#define MICROSTEPPING 16
#define STEPS_PER_DEGREE ((STEPS_PER_REVOLUTION * MICROSTEPPING) / 360.0)

// WebSocket
WebSocketsServer webSocket = WebSocketsServer(81);

// Current positions (in degrees)
float currentAzimuth = 0.0;
float currentElevation = 0.0;

// Target positions
float targetAzimuth = 0.0;
float targetElevation = 0.0;

// Movement state
bool isMoving = false;
unsigned long lastUpdateTime = 0;

void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n\n=== Simple Telescope Motor Controller ===");
  
  // Setup motor pins
  pinMode(AZIMUTH_DIR_PIN, OUTPUT);
  pinMode(AZIMUTH_STEP_PIN, OUTPUT);
  pinMode(ELEVATION_DIR_PIN, OUTPUT);
  pinMode(ELEVATION_STEP_PIN, OUTPUT);
  
  // Initialize pins to LOW
  digitalWrite(AZIMUTH_DIR_PIN, LOW);
  digitalWrite(AZIMUTH_STEP_PIN, LOW);
  digitalWrite(ELEVATION_DIR_PIN, LOW);
  digitalWrite(ELEVATION_STEP_PIN, LOW);
  
  // Setup WiFi as Access Point with fixed IP
  Serial.println("Setting up WiFi AP...");
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(local_IP, gateway, subnet);
  
  bool apStarted = WiFi.softAP(ssid, password, 1, 0, 4);
  
  if (apStarted) {
    Serial.println("✓ WiFi AP started successfully");
    IPAddress IP = WiFi.softAPIP();
    Serial.print("  AP IP address: ");
    Serial.println(IP);
    Serial.print("  SSID: ");
    Serial.println(ssid);
    Serial.print("  Password: ");
    Serial.println(password);
  } else {
    Serial.println("✗ Failed to start WiFi AP!");
  }
  
  // Start WebSocket server
  delay(500);
void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("❌ [Client %u] Disconnected\n", num);
      break;
      
    case WStype_CONNECTED:
      {
        IPAddress ip = webSocket.remoteIP(num);
        Serial.printf("✓ [Client %u] Connected from %d.%d.%d.%d\n", num, ip[0], ip[1], ip[2], ip[3]);
        
        // Send welcome message
        StaticJsonDocument<256> doc;
        doc["type"] = "connected";
        doc["message"] = "Telescope controller ready";
        doc["version"] = "1.0";
        doc["azimuth"] = currentAzimuth;
        doc["elevation"] = currentElevation;
        
        String output;
        serializeJson(doc, output);
        webSocket.sendTXT(num, output);
        Serial.printf("   Sent welcome: %s\n", output.c_str());
      }
      break;
      
    case WStype_TEXT:
      Serial.printf("📩 [Client %u] Received: %s\n", num, payload);
      handleCommand((char*)payload, num);
      break;
      
    case WStype_BIN:
      Serial.printf("⚠️  [Client %u] Received binary data (not supported)\n", num);
      break;
      
    case WStype_ERROR:
      Serial.printf("❌ [Client %u] Error occurred\n", num);
      break;
      
    case WStype_FRAGMENT_TEXT_START:
    case WStype_FRAGMENT_BIN_START:
    case WStype_FRAGMENT:
    case WStype_FRAGMENT_FIN:
      Serial.printf("⚠️  [Client %u] Fragment received (not supported)\n", num);
      break;
  }
}
void handleCommand(char* payload, uint8_t clientNum) {
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, payload);
  
  if (error) {
    Serial.printf("❌ JSON parse error: %s\n", error.c_str());
    String errorMsg = "{\"type\":\"error\",\"message\":\"Invalid JSON\"}";
    webSocket.sendTXT(clientNum, errorMsg);
    return;
  }
  
  const char* command = doc["command"];
  
  if (command == nullptr) {
    Serial.println("❌ No command field in JSON");
    String errorMsg = "{\"type\":\"error\",\"message\":\"Missing command field\"}";
    webSocket.sendTXT(clientNum, errorMsg);
    return;
  }
  
  Serial.printf("⚙️  Processing command: %s\n", command);
  
  if (strcmp(command, "goto") == 0) {
        String msg = "{\"type\":\"connected\",\"message\":\"Telescope controller ready\"}";
        webSocket.sendTXT(num, msg);
      }
      break;
      
    case WStype_TEXT:
      Serial.printf("[%u] Received: %s\n", num, payload);
      handleCommand((char*)payload);
      break;
  }
}

void handleCommand(char* payload) {
  StaticJsonDocument<512> doc;
  DeserializationError error = deserializeJson(doc, payload);
  
  if (error) {
    Serial.println("JSON parse error!");
    return;
  }
  
  const char* command = doc["command"];
  
  if (strcmp(command, "goto") == 0) {
    // Move to absolute position
    targetAzimuth = doc["azimuth"] | currentAzimuth;
    targetElevation = doc["elevation"] | currentElevation;
    isMoving = true;
    
    Serial.printf("GOTO command: Az=%.2f, El=%.2f\n", targetAzimuth, targetElevation);
    sendResponse("moving", "Moving to target position");
  }
  else if (strcmp(command, "slew") == 0) {
    // Continuous movement
    float azSpeed = doc["azimuth"] | 0.0;
    float elSpeed = doc["elevation"] | 0.0;
    
    // Simple slew: add to current target
    targetAzimuth = currentAzimuth + azSpeed;
    targetElevation = currentElevation + elSpeed;
    isMoving = true;
    
    Serial.printf("SLEW command: Az speed=%.2f, El speed=%.2f\n", azSpeed, elSpeed);
    sendResponse("slewing", "Slewing telescope");
  }
  else if (strcmp(command, "stop") == 0) {
    // Stop all movement
    targetAzimuth = currentAzimuth;
    targetElevation = currentElevation;
    isMoving = false;
    
    Serial.println("STOP command");
    sendResponse("stopped", "Motors stopped");
  }
  else if (strcmp(command, "status") == 0) {
    // Send current status
    sendPositionUpdate();
  }
  else if (strcmp(command, "calibrate") == 0) {
    // Reset position to 0,0
    currentAzimuth = 0.0;
    currentElevation = 0.0;
    targetAzimuth = 0.0;
    targetElevation = 0.0;
    
    Serial.println("CALIBRATE command - Position reset to 0,0");
    sendResponse("calibrated", "Position calibrated to 0,0");
  }
}

void moveMotors() {
  bool azReached = false;
  bool elReached = false;
  
  // Move Azimuth
  float azDiff = targetAzimuth - currentAzimuth;
  if (abs(azDiff) > 0.1) {
    // Determine direction
    digitalWrite(AZIMUTH_DIR_PIN, azDiff > 0 ? HIGH : LOW);
    
    // Take one step
    digitalWrite(AZIMUTH_STEP_PIN, HIGH);
    delayMicroseconds(500);
    digitalWrite(AZIMUTH_STEP_PIN, LOW);
    delayMicroseconds(500);
    
    // Update position
    currentAzimuth += (azDiff > 0 ? 0.05 : -0.05);
  } else {
    azReached = true;
  }
  
  // Move Elevation
  float elDiff = targetElevation - currentElevation;
  if (abs(elDiff) > 0.1) {
    // Determine direction
    digitalWrite(ELEVATION_DIR_PIN, elDiff > 0 ? HIGH : LOW);
    
    // Take one step
    digitalWrite(ELEVATION_STEP_PIN, HIGH);
    delayMicroseconds(500);
    digitalWrite(ELEVATION_STEP_PIN, LOW);
    delayMicroseconds(500);
    
    // Update position
    currentElevation += (elDiff > 0 ? 0.05 : -0.05);
  } else {
    elReached = true;
  }
  
  // Check if target reached
  if (azReached && elReached) {
    isMoving = false;
    currentAzimuth = targetAzimuth;
    currentElevation = targetElevation;
    sendResponse("target_reached", "Target position reached");
  }
}

void sendPositionUpdate() {
  StaticJsonDocument<256> doc;
  doc["type"] = "position";
  doc["azimuth"] = currentAzimuth;
  doc["elevation"] = currentElevation;
  doc["moving"] = isMoving;
  
  String output;
  serializeJson(doc, output);
  webSocket.broadcastTXT(output);
}

void sendResponse(const char* status, const char* message) {
  StaticJsonDocument<256> doc;
  doc["type"] = "response";
  doc["status"] = status;
  doc["message"] = message;
  doc["azimuth"] = currentAzimuth;
  doc["elevation"] = currentElevation;
  
  String output;
  serializeJson(doc, output);
  webSocket.broadcastTXT(output);
}
