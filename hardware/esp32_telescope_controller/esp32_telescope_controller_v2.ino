/*
 * Updated ESP32 Robotic Telescope Controller
 * 
 * This is the updated main file that includes all the new libraries and features.
 * It integrates motor control, sensors, and hardware testing capabilities.
 */

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>

// Include our custom libraries
#include "config.h"
#include "motor_control.h"
#include "sensors.h"
#include "hardware_test.h"

// WiFi and WebSocket
WebSocketsServer webSocket = WebSocketsServer(WEBSOCKET_PORT);

// Motor instances
StepperMotor azimuthMotor(AZIMUTH_STEP_PIN, AZIMUTH_DIR_PIN, AZIMUTH_ENABLE_PIN,
                         AZIMUTH_ENCODER_A, AZIMUTH_ENCODER_B,
                         STEPS_PER_REVOLUTION, MICROSTEPPING, AZIMUTH_GEAR_RATIO);

StepperMotor elevationMotor(ELEVATION_STEP_PIN, ELEVATION_DIR_PIN, ELEVATION_ENABLE_PIN,
                           ELEVATION_ENCODER_A, ELEVATION_ENCODER_B,
                           STEPS_PER_REVOLUTION, MICROSTEPPING, ELEVATION_GEAR_RATIO);

// Sensor manager
SensorManager sensors;

// Telescope state
struct TelescopeSystem {
  bool isInitialized = false;
  bool isCalibrated = false;
  bool emergencyStop = false;
  String status = "Initializing";
  unsigned long lastStatusUpdate = 0;
  unsigned long lastHeartbeat = 0;
} telescopeSystem;

// Timing variables
unsigned long lastMainLoopTime = 0;
const unsigned long MAIN_LOOP_INTERVAL = 20; // 50Hz main loop

void setup() {
  Serial.begin(SERIAL_BAUD_RATE);
  delay(1000);
  
  Serial.println("\n╔══════════════════════════════════════╗");
  Serial.println("║     ESP32 Robotic Telescope          ║");
  Serial.println("║         Controller v2.0              ║");
  Serial.println("╚══════════════════════════════════════╝");
  
  // Initialize hardware
  initializeGPIO();
  
  // Setup communication
  setupWiFiAP();
  setupWebSocket();
  
  // Initialize motors
  initializeMotors();
  
  // Initialize sensors
  initializeSensors();
  
  // Run initial hardware tests
  if (DEBUG_SERIAL) {
    Serial.println("\nRunning initial hardware verification...");
    hardwareTest.runAllTests();
  }
  
  // System ready
  telescopeSystem.isInitialized = true;
  telescopeSystem.status = "System Ready";
  
  Serial.println("\n🚀 System initialized successfully!");
  Serial.println("📡 WiFi Network: " + String(WIFI_SSID));
  Serial.println("🔌 WebSocket Server: ws://" + String(AP_IP_ADDRESS) + ":" + String(WEBSOCKET_PORT));
  Serial.println("⚙️  Simulation Mode: " + String(SIMULATION_MODE ? "ON" : "OFF"));
  
  // Indicate ready status
  blinkStatusLED(5, 200);
}

void loop() {
  unsigned long currentTime = millis();
  
  // Main loop timing control
  if (currentTime - lastMainLoopTime < MAIN_LOOP_INTERVAL) {
    return;
  }
  lastMainLoopTime = currentTime;
  
  // Handle WebSocket connections
  webSocket.loop();
  
  // Update motor positions
  updateMotors();
  
  // Update sensors
  updateSensors();
  
  // Check safety conditions
  checkSafetyConditions();
  
  // Send periodic status updates
  sendPeriodicUpdates();
  
  // Handle emergency conditions
  handleEmergencyConditions();
  
  // System heartbeat
  updateHeartbeat();
  
  // Watchdog reset (if enabled)
  // esp_task_wdt_reset();
}

void initializeGPIO() {
  Serial.println("Initializing GPIO pins...");
  
  // Status LED
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);
  
  // Emergency stop button
  pinMode(EMERGENCY_STOP_PIN, INPUT_PULLUP);
  
  // Buzzer (if connected)
  if (BUZZER_PIN > 0) {
    pinMode(BUZZER_PIN, OUTPUT);
    digitalWrite(BUZZER_PIN, LOW);
  }
  
  Serial.println("✓ GPIO initialized");
}

void setupWiFiAP() {
  Serial.println("Setting up WiFi Access Point...");
  
  // Configure AP
  WiFi.mode(WIFI_AP);
  
  IPAddress local_IP, gateway, subnet;
  local_IP.fromString(AP_IP_ADDRESS);
  gateway.fromString(AP_GATEWAY);
  subnet.fromString(AP_SUBNET);
  
  WiFi.softAPConfig(local_IP, gateway, subnet);
  bool apStarted = WiFi.softAP(WIFI_SSID, WIFI_PASSWORD, WIFI_CHANNEL);
  
  if (apStarted) {
    Serial.println("✓ WiFi AP started successfully");
    Serial.println("   SSID: " + String(WIFI_SSID));
    Serial.println("   IP: " + WiFi.softAPIP().toString());
  } else {
    Serial.println("✗ Failed to start WiFi AP");
    telescopeSystem.status = "WiFi Failed";
  }
}

void setupWebSocket() {
  Serial.println("Starting WebSocket server...");
  
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  
  Serial.println("✓ WebSocket server started on port " + String(WEBSOCKET_PORT));
}

void initializeMotors() {
  Serial.println("Initializing motors...");
  
  azimuthMotor.begin();
  elevationMotor.begin();
  
  // Set initial speeds
  azimuthMotor.setSpeed(MAX_SPEED_STEPS_PER_SEC * 0.5); // 50% of max speed
  elevationMotor.setSpeed(MAX_SPEED_STEPS_PER_SEC * 0.5);
  
  Serial.println("✓ Motors initialized");
}

void initializeSensors() {
  Serial.println("Initializing sensors...");
  
  sensors.begin();
  
  Serial.println("✓ Sensors initialized");
}

void updateMotors() {
  azimuthMotor.update();
  elevationMotor.update();
  
  // Update telescope system status based on motor states
  bool anyMotorMoving = azimuthMotor.getIsMoving() || elevationMotor.getIsMoving();
  
  if (anyMotorMoving && telescopeSystem.status == "System Ready") {
    telescopeSystem.status = "Moving";
  } else if (!anyMotorMoving && telescopeSystem.status == "Moving") {
    telescopeSystem.status = "Target Reached";
  }
}

void updateSensors() {
  sensors.update();
  
  // Update motor positions from encoders (if available and not in simulation)
  if (!SIMULATION_MODE && sensors.getAzimuthEncoder() && sensors.getElevationEncoder()) {
    float azEncoderAngle = sensors.getAzimuthEncoder()->getAngle();
    float elEncoderAngle = sensors.getElevationEncoder()->getAngle();
    
    // Update motor positions with encoder feedback
    azimuthMotor.setPosition(azEncoderAngle);
    elevationMotor.setPosition(elEncoderAngle);
  }
}

void checkSafetyConditions() {
  // Check if system is in safe state
  if (!sensors.isSystemSafe()) {
    if (!telescopeSystem.emergencyStop) {
      Serial.println("⚠️  Safety violation detected - initiating emergency stop");
      activateEmergencyStop();
    }
  }
  
  // Check emergency stop button
  if (digitalRead(EMERGENCY_STOP_PIN) == LOW) {
    if (!telescopeSystem.emergencyStop) {
      Serial.println("🚨 Emergency stop button pressed");
      activateEmergencyStop();
    }
  }
}

void sendPeriodicUpdates() {
  unsigned long currentTime = millis();
  
  if (currentTime - telescopeSystem.lastStatusUpdate >= STATUS_BROADCAST_INTERVAL) {
    telescopeSystem.lastStatusUpdate = currentTime;
    broadcastSystemStatus();
  }
}

void handleEmergencyConditions() {
  if (telescopeSystem.emergencyStop) {
    // Stop all motors
    azimuthMotor.emergencyStop();
    elevationMotor.emergencyStop();
    
    // Flash status LED rapidly
    static unsigned long lastFlash = 0;
    if (millis() - lastFlash > 100) {
      lastFlash = millis();
      digitalWrite(STATUS_LED_PIN, !digitalRead(STATUS_LED_PIN));
    }
  }
}

void updateHeartbeat() {
  unsigned long currentTime = millis();
  
  if (currentTime - telescopeSystem.lastHeartbeat >= 1000) { // 1 second heartbeat
    telescopeSystem.lastHeartbeat = currentTime;
    
    if (!telescopeSystem.emergencyStop) {
      // Normal heartbeat - slow blink
      static bool heartbeatState = false;
      heartbeatState = !heartbeatState;
      digitalWrite(STATUS_LED_PIN, heartbeatState);
    }
  }
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      if (DEBUG_WEBSOCKET) {
        Serial.printf("[%u] Client disconnected\n", num);
      }
      break;
      
    case WStype_CONNECTED: {
      IPAddress ip = webSocket.remoteIP(num);
      if (DEBUG_WEBSOCKET) {
        Serial.printf("[%u] Client connected from %d.%d.%d.%d\n", num, ip[0], ip[1], ip[2], ip[3]);
      }
      
      // Send initial system status
      sendSystemStatus(num);
      break;
    }
    
    case WStype_TEXT:
      if (DEBUG_WEBSOCKET) {
        Serial.printf("[%u] Received: %s\n", num, payload);
      }
      handleWebSocketCommand(num, (char*)payload);
      break;
      
    case WStype_ERROR:
      Serial.printf("[%u] WebSocket Error\n", num);
      break;
      
    default:
      break;
  }
}

void handleWebSocketCommand(uint8_t clientNum, String command) {
  DynamicJsonDocument doc(JSON_BUFFER_SIZE);
  DeserializationError error = deserializeJson(doc, command);
  
  if (error) {
    Serial.println("❌ JSON parsing failed: " + String(error.c_str()));
    sendErrorResponse(clientNum, "Invalid JSON format");
    return;
  }
  
  String action = doc["action"];
  
  if (DEBUG_WEBSOCKET) {
    Serial.println("📨 Command: " + action);
  }
  
  // Check if system is ready for commands
  if (!telescopeSystem.isInitialized && action != "getStatus") {
    sendErrorResponse(clientNum, "System not initialized");
    return;
  }
  
  if (telescopeSystem.emergencyStop && action != "resetEmergencyStop" && action != "getStatus") {
    sendErrorResponse(clientNum, "Emergency stop active - reset required");
    return;
  }
  
  // Handle commands
  if (action == "moveTo") {
    handleMoveToCommand(clientNum, doc);
  } else if (action == "slew") {
    handleSlewCommand(clientNum, doc);
  } else if (action == "stop") {
    handleStopCommand(clientNum);
  } else if (action == "calibrate") {
    handleCalibrateCommand(clientNum);
  } else if (action == "home") {
    handleHomeCommand(clientNum);
  } else if (action == "emergencyStop") {
    handleEmergencyStopCommand(clientNum);
  } else if (action == "resetEmergencyStop") {
    handleResetEmergencyStopCommand(clientNum);
  } else if (action == "getStatus") {
    sendSystemStatus(clientNum);
  } else if (action == "setSpeed") {
    handleSetSpeedCommand(clientNum, doc);
  } else if (action == "test") {
    handleTestCommand(clientNum, doc["type"] | "all");
  } else {
    sendErrorResponse(clientNum, "Unknown command: " + action);
  }
}

void handleMoveToCommand(uint8_t clientNum, DynamicJsonDocument& doc) {
  float azimuth = doc["azimuth"];
  float elevation = doc["elevation"];
  
  // Validate ranges
  if (azimuth < AZIMUTH_MIN_ANGLE || azimuth > AZIMUTH_MAX_ANGLE ||
      elevation < ELEVATION_MIN_ANGLE || elevation > ELEVATION_MAX_ANGLE) {
    sendErrorResponse(clientNum, "Target position out of range");
    return;
  }
  
  // Execute movement
  azimuthMotor.moveTo(azimuth);
  elevationMotor.moveTo(elevation);
  
  telescopeSystem.status = "Moving to target";
  
  sendResponse(clientNum, "moveTo", "success", 
               "Moving to Az:" + String(azimuth) + "° El:" + String(elevation) + "°");
}

void handleSlewCommand(uint8_t clientNum, DynamicJsonDocument& doc) {
  String direction = doc["direction"];
  int steps = doc["steps"] | 50; // Default 50 steps
  
  float stepSize = steps * 0.1; // Convert to degrees
  
  if (direction == "up") {
    float newElevation = elevationMotor.getCurrentAngle() + stepSize;
    if (newElevation <= ELEVATION_MAX_ANGLE) {
      elevationMotor.moveRelative(stepSize);
    }
  } else if (direction == "down") {
    float newElevation = elevationMotor.getCurrentAngle() - stepSize;
    if (newElevation >= ELEVATION_MIN_ANGLE) {
      elevationMotor.moveRelative(-stepSize);
    }
  } else if (direction == "left") {
    azimuthMotor.moveRelative(-stepSize);
  } else if (direction == "right") {
    azimuthMotor.moveRelative(stepSize);
  } else {
    sendErrorResponse(clientNum, "Invalid direction: " + direction);
    return;
  }
  
  telescopeSystem.status = "Slewing " + direction;
  sendResponse(clientNum, "slew", "success", "Slewing " + direction + " " + String(steps) + " steps");
}

void handleStopCommand(uint8_t clientNum) {
  azimuthMotor.stop();
  elevationMotor.stop();
  telescopeSystem.status = "Stopped";
  
  sendResponse(clientNum, "stop", "success", "Movement stopped");
}

void handleCalibrateCommand(uint8_t clientNum) {
  telescopeSystem.status = "Calibrating";
  
  azimuthMotor.calibrate();
  elevationMotor.calibrate();
  
  telescopeSystem.isCalibrated = true;
  telescopeSystem.status = "Calibration complete";
  
  sendResponse(clientNum, "calibrate", "success", "Calibration completed");
}

void handleHomeCommand(uint8_t clientNum) {
  azimuthMotor.moveTo(0.0);
  elevationMotor.moveTo(45.0);
  telescopeSystem.status = "Going home";
  
  sendResponse(clientNum, "home", "success", "Moving to home position");
}

void handleEmergencyStopCommand(uint8_t clientNum) {
  activateEmergencyStop();
  sendResponse(clientNum, "emergencyStop", "success", "Emergency stop activated");
}

void handleResetEmergencyStopCommand(uint8_t clientNum) {
  resetEmergencyStop();
  sendResponse(clientNum, "resetEmergencyStop", "success", "Emergency stop reset");
}

void handleSetSpeedCommand(uint8_t clientNum, DynamicJsonDocument& doc) {
  float speed = doc["speed"];
  
  azimuthMotor.setSpeed(speed);
  elevationMotor.setSpeed(speed);
  
  sendResponse(clientNum, "setSpeed", "success", "Speed set to " + String(speed));
}

void activateEmergencyStop() {
  telescopeSystem.emergencyStop = true;
  telescopeSystem.status = "EMERGENCY STOP";
  
  azimuthMotor.emergencyStop();
  elevationMotor.emergencyStop();
  
  // Sound buzzer if available
  if (BUZZER_PIN > 0) {
    for (int i = 0; i < 5; i++) {
      digitalWrite(BUZZER_PIN, HIGH);
      delay(100);
      digitalWrite(BUZZER_PIN, LOW);
      delay(100);
    }
  }
  
  Serial.println("🚨 EMERGENCY STOP ACTIVATED");
}

void resetEmergencyStop() {
  if (digitalRead(EMERGENCY_STOP_PIN) == LOW) {
    Serial.println("❌ Cannot reset - emergency stop button still pressed");
    return;
  }
  
  telescopeSystem.emergencyStop = false;
  telescopeSystem.status = "Emergency stop reset";
  
  // Re-enable motors
  azimuthMotor.enable();
  elevationMotor.enable();
  
  Serial.println("✅ Emergency stop reset");
}

void broadcastSystemStatus() {
  for (uint8_t i = 0; i < webSocket.connectedClients(); i++) {
    sendSystemStatus(i);
  }
}

void sendSystemStatus(uint8_t clientNum) {
  DynamicJsonDocument doc(JSON_BUFFER_SIZE);
  
  doc["type"] = "position";
  doc["azimuth"] = azimuthMotor.getCurrentAngle();
  doc["elevation"] = elevationMotor.getCurrentAngle();
  doc["targetAzimuth"] = azimuthMotor.getTargetAngle();
  doc["targetElevation"] = elevationMotor.getTargetAngle();
  doc["moving"] = azimuthMotor.getIsMoving() || elevationMotor.getIsMoving();
  doc["calibrated"] = telescopeSystem.isCalibrated;
  doc["status"] = telescopeSystem.status;
  doc["emergencyStop"] = telescopeSystem.emergencyStop;
  doc["timestamp"] = millis();
  
  // Add sensor data if available
  if (sensors.getEnvSensor()) {
    doc["temperature"] = sensors.getEnvSensor()->getTemperature();
    doc["humidity"] = sensors.getEnvSensor()->getHumidity();
  }
  
  if (sensors.getGPSSensor() && sensors.getGPSSensor()->isPositionValid()) {
    doc["latitude"] = sensors.getGPSSensor()->getLatitude();
    doc["longitude"] = sensors.getGPSSensor()->getLongitude();
  }
  
  String response;
  serializeJson(doc, response);
  webSocket.sendTXT(clientNum, response);
}

void sendResponse(uint8_t clientNum, String action, String result, String message) {
  DynamicJsonDocument doc(512);
  
  doc["type"] = "response";
  doc["action"] = action;
  doc["result"] = result;
  doc["message"] = message;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  webSocket.sendTXT(clientNum, response);
}

void sendErrorResponse(uint8_t clientNum, String error) {
  DynamicJsonDocument doc(512);
  
  doc["type"] = "error";
  doc["message"] = error;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  webSocket.sendTXT(clientNum, response);
  
  if (DEBUG_WEBSOCKET) {
    Serial.println("❌ Error sent: " + error);
  }
}

void blinkStatusLED(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(STATUS_LED_PIN, HIGH);
    delay(delayMs);
    digitalWrite(STATUS_LED_PIN, LOW);
    delay(delayMs);
  }
}