/*
 * ESP32 Robotic Telescope Controller
 * 
 * This code provides WiFi AP, WebSocket server, and telescope control functionality
 * for integration with the Flutter robotic telescope application.
 * 
 * Features:
 * - WiFi Access Point mode
 * - WebSocket server for real-time communication
 * - Stepper motor control simulation (azimuth & elevation)
 * - Position feedback simulation
 * - JSON command parsing
 * 
 * Hardware Setup (Future Implementation):
 * - ESP32 DevKit V1
 * - 2x NEMA 17 Stepper Motors (Azimuth & Elevation)
 * - 2x A4988/DRV8825 Stepper Drivers
 * - Rotary Encoders for position feedback
 * - Limit switches for safety
 * 
 * Author: Generated for Robotic Telescope Project
 * Date: September 2025
 */

#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ArduinoJson.h>
#include <ESP32Servo.h>

// WiFi Configuration
const char* ssid = "RoboticTelescope";
const char* password = "telescope123";

// Network Configuration
IPAddress local_IP(192, 168, 4, 1);
IPAddress gateway(192, 168, 4, 1);
IPAddress subnet(255, 255, 255, 0);

// WebSocket Server
WebSocketsServer webSocket = WebSocketsServer(81);

// Telescope State Variables
struct TelescopeState {
  float azimuth = 0.0;        // Current azimuth angle (0-360 degrees)
  float elevation = 45.0;     // Current elevation angle (0-90 degrees)
  float targetAzimuth = 0.0;  // Target azimuth angle
  float targetElevation = 45.0; // Target elevation angle
  bool isMoving = false;      // Movement status
  bool isCalibrated = false;  // Calibration status
  bool emergencyStop = false; // Emergency stop flag
  String status = "Ready";    // Current status message
};

TelescopeState telescope;

// Motor Control Variables
struct MotorConfig {
  // Stepper Motor Specifications
  int stepsPerRevolution = 200;   // Standard NEMA 17
  int microstepping = 16;         // Microstepping setting
  float gearRatio = 100.0;        // Gear reduction ratio
  
  // Speed Control
  float maxSpeed = 1000.0;        // Maximum steps per second
  float acceleration = 500.0;     // Steps per second^2
  float currentSpeed = 0.0;       // Current speed
  
  // Position
  long currentPosition = 0;       // Current position in steps
  long targetPosition = 0;        // Target position in steps
};

MotorConfig azimuthMotor;
MotorConfig elevationMotor;

// Timing Variables
unsigned long lastPositionUpdate = 0;
unsigned long lastStatusBroadcast = 0;
const unsigned long POSITION_UPDATE_INTERVAL = 50;   // 50ms for smooth movement
const unsigned long STATUS_BROADCAST_INTERVAL = 100; // 100ms for status updates

// Pin Definitions (for future hardware implementation)
const int AZIMUTH_STEP_PIN = 2;
const int AZIMUTH_DIR_PIN = 3;
const int AZIMUTH_ENABLE_PIN = 4;

const int ELEVATION_STEP_PIN = 7;
const int ELEVATION_DIR_PIN = 8;
const int ELEVATION_ENABLE_PIN = 9;

const int LIMIT_SWITCH_AZ_CW = 12;
const int LIMIT_SWITCH_AZ_CCW = 13;
const int LIMIT_SWITCH_EL_UP = 14;
const int LIMIT_SWITCH_EL_DOWN = 15;

const int STATUS_LED = 2;
const int EMERGENCY_STOP_PIN = 0;

void setup() {
  Serial.begin(115200);
  Serial.println("ESP32 Robotic Telescope Controller Starting...");
  
  // Initialize hardware pins
  initializeHardware();
  
  // Setup WiFi Access Point
  setupWiFiAP();
  
  // Initialize WebSocket server
  setupWebSocket();
  
  // Initialize telescope systems
  initializeTelescope();
  
  Serial.println("System Ready!");
  Serial.println("WiFi AP: " + String(ssid));
  Serial.println("Password: " + String(password));
  Serial.println("WebSocket Server: ws://192.168.4.1:81");
}

void loop() {
  // Handle WebSocket connections
  webSocket.loop();
  
  // Update telescope position simulation
  updateTelescopePosition();
  
  // Broadcast status updates
  broadcastStatus();
  
  // Check for emergency conditions
  checkEmergencyConditions();
  
  // Small delay to prevent watchdog issues
  delay(10);
}

void initializeHardware() {
  // Configure GPIO pins for future hardware
  pinMode(STATUS_LED, OUTPUT);
  pinMode(EMERGENCY_STOP_PIN, INPUT_PULLUP);
  
  // Stepper motor pins
  pinMode(AZIMUTH_STEP_PIN, OUTPUT);
  pinMode(AZIMUTH_DIR_PIN, OUTPUT);
  pinMode(AZIMUTH_ENABLE_PIN, OUTPUT);
  
  pinMode(ELEVATION_STEP_PIN, OUTPUT);
  pinMode(ELEVATION_DIR_PIN, OUTPUT);
  pinMode(ELEVATION_ENABLE_PIN, OUTPUT);
  
  // Encoder pins diabaikan (tidak digunakan)
  
  // Limit switch pins
  pinMode(LIMIT_SWITCH_AZ_CW, INPUT_PULLUP);
  pinMode(LIMIT_SWITCH_AZ_CCW, INPUT_PULLUP);
  pinMode(LIMIT_SWITCH_EL_UP, INPUT_PULLUP);
  pinMode(LIMIT_SWITCH_EL_DOWN, INPUT_PULLUP);
  
  // Initialize motors (disabled initially)
  digitalWrite(AZIMUTH_ENABLE_PIN, HIGH);  // Disable
  digitalWrite(ELEVATION_ENABLE_PIN, HIGH); // Disable
  
  Serial.println("Hardware initialized");
}

void setupWiFiAP() {
  // Configure Access Point
  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(local_IP, gateway, subnet);
  WiFi.softAP(ssid, password);
  
  Serial.println("WiFi AP started");
  Serial.print("AP IP address: ");
  Serial.println(WiFi.softAPIP());
}

void setupWebSocket() {
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  Serial.println("WebSocket server started on port 81");
}

void initializeTelescope() {
  // Initialize telescope to default position
  telescope.azimuth = 0.0;
  telescope.elevation = 45.0;
  telescope.targetAzimuth = 0.0;
  telescope.targetElevation = 45.0;
  telescope.isMoving = false;
  telescope.isCalibrated = false;
  telescope.emergencyStop = false;
  telescope.status = "System Initialized";
  
  Serial.println("Telescope initialized to home position");
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t length) {
  switch(type) {
    case WStype_DISCONNECTED:
      Serial.printf("[%u] Disconnected!\n", num);
      break;
      
    case WStype_CONNECTED: {
      IPAddress ip = webSocket.remoteIP(num);
      Serial.printf("[%u] Connected from %d.%d.%d.%d\n", num, ip[0], ip[1], ip[2], ip[3]);
      
      // Send initial status
      sendPositionUpdate(num);
      break;
    }
    
    case WStype_TEXT:
      Serial.printf("[%u] Received: %s\n", num, payload);
      handleCommand(num, (char*)payload);
      break;
      
    default:
      break;
  }
}

void handleCommand(uint8_t clientNum, String command) {
  DynamicJsonDocument doc(1024);
  DeserializationError error = deserializeJson(doc, command);
  
  if (error) {
    Serial.println("JSON parsing failed");
    sendErrorResponse(clientNum, "Invalid JSON format");
    return;
  }
  
  String action = doc["action"];
  
  if (action == "moveTo") {
    float azimuth = doc["azimuth"];
    float elevation = doc["elevation"];
    moveTo(azimuth, elevation);
    sendResponse(clientNum, "moveTo", "success", "Moving to target position");
    
  } else if (action == "slew") {
    String direction = doc["direction"];
    int steps = doc["steps"] | 50; // Default 50 steps
    slew(direction, steps);
    sendResponse(clientNum, "slew", "success", "Slewing " + direction);
    
  } else if (action == "stop") {
    stopMovement();
    sendResponse(clientNum, "stop", "success", "Movement stopped");
    
  } else if (action == "calibrate") {
    calibrate();
    sendResponse(clientNum, "calibrate", "success", "Calibration started");
    
  } else if (action == "home") {
    goHome();
    sendResponse(clientNum, "home", "success", "Going to home position");
    
  } else if (action == "emergencyStop") {
    emergencyStop();
    sendResponse(clientNum, "emergencyStop", "success", "Emergency stop activated");
    
  } else if (action == "getStatus") {
    sendPositionUpdate(clientNum);
    
  } else if (action == "setSpeed") {
    float speed = doc["speed"];
    setSpeed(speed);
    sendResponse(clientNum, "setSpeed", "success", "Speed updated");
    
  } else {
    sendErrorResponse(clientNum, "Unknown command: " + action);
  }
}

// Movement Commands Implementation

void moveTo(float targetAz, float targetEl) {
  // Validate input ranges
  targetAz = constrain(targetAz, 0.0, 360.0);
  targetEl = constrain(targetEl, 0.0, 90.0);
  
  telescope.targetAzimuth = targetAz;
  telescope.targetElevation = targetEl;
  telescope.isMoving = true;
  telescope.status = "Moving to target";
  
  Serial.println("MoveTo command: Az=" + String(targetAz) + " El=" + String(targetEl));
  
  // In real implementation, calculate step positions and start motors
  calculateTargetPositions();
  startMotorMovement();
}

void slew(String direction, int steps) {
  if (telescope.emergencyStop) {
    Serial.println("Emergency stop active - slew command ignored");
    return;
  }
  
  float stepSize = steps * 0.1; // Convert steps to degrees (simulation)
  
  if (direction == "up") {
    telescope.targetElevation = constrain(telescope.elevation + stepSize, 0.0, 90.0);
  } else if (direction == "down") {
    telescope.targetElevation = constrain(telescope.elevation - stepSize, 0.0, 90.0);
  } else if (direction == "left") {
    telescope.targetAzimuth = fmod(telescope.azimuth - stepSize + 360.0, 360.0);
  } else if (direction == "right") {
    telescope.targetAzimuth = fmod(telescope.azimuth + stepSize, 360.0);
  }
  
  telescope.isMoving = true;
  telescope.status = "Slewing " + direction;
  
  Serial.println("Slew command: " + direction + " steps=" + String(steps));
  
  startMotorMovement();
}

void stopMovement() {
  telescope.isMoving = false;
  telescope.targetAzimuth = telescope.azimuth;
  telescope.targetElevation = telescope.elevation;
  telescope.status = "Stopped";
  
  // In real implementation, stop stepper motors immediately
  stopMotors();
  
  Serial.println("Movement stopped");
}

void calibrate() {
  telescope.isMoving = true;
  telescope.status = "Calibrating";
  
  // Simulation: Reset to known position
  telescope.azimuth = 0.0;
  telescope.elevation = 45.0;
  telescope.targetAzimuth = 0.0;
  telescope.targetElevation = 45.0;
  telescope.isCalibrated = true;
  telescope.isMoving = false;
  telescope.status = "Calibration complete";
  
  Serial.println("Calibration completed");
}

void goHome() {
  moveTo(0.0, 45.0);
  telescope.status = "Going home";
  Serial.println("Going to home position");
}

void emergencyStop() {
  telescope.emergencyStop = true;
  telescope.isMoving = false;
  telescope.status = "EMERGENCY STOP";
  
  // In real implementation, immediately stop all motors
  stopMotors();
  digitalWrite(AZIMUTH_ENABLE_PIN, HIGH);  // Disable motors
  digitalWrite(ELEVATION_ENABLE_PIN, HIGH);
  
  Serial.println("EMERGENCY STOP ACTIVATED");
}

void setSpeed(float speed) {
  speed = constrain(speed, 10.0, 1000.0); // Reasonable speed limits
  azimuthMotor.maxSpeed = speed;
  elevationMotor.maxSpeed = speed;
  
  Serial.println("Speed set to: " + String(speed));
}

// Motor Control Functions (Simulation)

void calculateTargetPositions() {
  // Convert degrees to steps
  long azSteps = (telescope.targetAzimuth / 360.0) * azimuthMotor.stepsPerRevolution * azimuthMotor.microstepping * azimuthMotor.gearRatio;
  long elSteps = (telescope.targetElevation / 90.0) * elevationMotor.stepsPerRevolution * elevationMotor.microstepping * elevationMotor.gearRatio;
  
  azimuthMotor.targetPosition = azSteps;
  elevationMotor.targetPosition = elSteps;
}

void startMotorMovement() {
  // In real implementation, this would configure stepper motor controllers
  // For simulation, we just set the moving flag
  digitalWrite(AZIMUTH_ENABLE_PIN, LOW);   // Enable motors
  digitalWrite(ELEVATION_ENABLE_PIN, LOW);
}

void stopMotors() {
  // In real implementation, stop stepper motor pulses immediately
  azimuthMotor.currentSpeed = 0.0;
  elevationMotor.currentSpeed = 0.0;
}

void updateTelescopePosition() {
  if (millis() - lastPositionUpdate < POSITION_UPDATE_INTERVAL) {
    return;
  }
  
  lastPositionUpdate = millis();
  
  if (!telescope.isMoving || telescope.emergencyStop) {
    return;
  }
  
  // Simulate smooth movement to target position
  float azError = telescope.targetAzimuth - telescope.azimuth;
  float elError = telescope.targetElevation - telescope.elevation;
  
  // Handle azimuth wrap-around
  if (azError > 180.0) azError -= 360.0;
  if (azError < -180.0) azError += 360.0;
  
  // Simple proportional movement simulation
  float moveRate = 2.0; // degrees per second
  float deltaTime = POSITION_UPDATE_INTERVAL / 1000.0; // seconds
  float maxMove = moveRate * deltaTime;
  
  // Move azimuth
  if (abs(azError) > 0.1) {
    float azMove = constrain(azError, -maxMove, maxMove);
    telescope.azimuth = fmod(telescope.azimuth + azMove + 360.0, 360.0);
  }
  
  // Move elevation
  if (abs(elError) > 0.1) {
    float elMove = constrain(elError, -maxMove, maxMove);
    telescope.elevation = constrain(telescope.elevation + elMove, 0.0, 90.0);
  }
  
  // Check if reached target
  if (abs(azError) <= 0.1 && abs(elError) <= 0.1) {
    telescope.isMoving = false;
    telescope.status = "Target reached";
    stopMotors();
  }
}

void broadcastStatus() {
  if (millis() - lastStatusBroadcast < STATUS_BROADCAST_INTERVAL) {
    return;
  }
  
  lastStatusBroadcast = millis();
  
  // Broadcast to all connected clients
  for (uint8_t i = 0; i < webSocket.connectedClients(); i++) {
    sendPositionUpdate(i);
  }
  
  // Blink status LED
  static bool ledState = false;
  ledState = !ledState;
  digitalWrite(STATUS_LED, ledState);
}

void checkEmergencyConditions() {
  // Check emergency stop button
  if (digitalRead(EMERGENCY_STOP_PIN) == LOW) {
    if (!telescope.emergencyStop) {
      emergencyStop();
    }
  }
  
  // Check limit switches (for future implementation)
  // if (checkLimitSwitches()) {
  //   emergencyStop();
  // }
}

// Communication Functions

void sendPositionUpdate(uint8_t clientNum) {
  DynamicJsonDocument doc(1024);
  
  doc["type"] = "position";
  doc["azimuth"] = telescope.azimuth;
  doc["elevation"] = telescope.elevation;
  doc["targetAzimuth"] = telescope.targetAzimuth;
  doc["targetElevation"] = telescope.targetElevation;
  doc["moving"] = telescope.isMoving;
  doc["calibrated"] = telescope.isCalibrated;
  doc["status"] = telescope.status;
  doc["emergencyStop"] = telescope.emergencyStop;
  doc["timestamp"] = millis();
  
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
}

// Hardware Interface Functions (for future implementation)

void moveStepperMotor(int stepPin, int dirPin, bool direction, int steps, float speed) {
  // Implementation for actual stepper motor control
  digitalWrite(dirPin, direction);
  
  float delayTime = 1000000.0 / (speed * 2.0); // microseconds
  
  for (int i = 0; i < steps; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(delayTime);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(delayTime);
    
    // Check for stop conditions
    if (telescope.emergencyStop || !telescope.isMoving) {
      break;
    }
  }
}

bool checkLimitSwitches() {
  // Check all limit switches
  bool azCW = digitalRead(LIMIT_SWITCH_AZ_CW) == LOW;
  bool azCCW = digitalRead(LIMIT_SWITCH_AZ_CCW) == LOW;
  bool elUp = digitalRead(LIMIT_SWITCH_EL_UP) == LOW;
  bool elDown = digitalRead(LIMIT_SWITCH_EL_DOWN) == LOW;
  
  if (azCW || azCCW || elUp || elDown) {
    Serial.println("Limit switch triggered!");
    return true;
  }
  
  return false;
}

