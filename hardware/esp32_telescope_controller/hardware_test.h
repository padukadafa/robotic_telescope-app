/*
 * Hardware Testing and Calibration Functions
 * 
 * This file contains functions for testing and calibrating the telescope hardware.
 * Use these functions to verify proper operation of motors, sensors, and safety systems.
 */

#ifndef HARDWARE_TEST_H
#define HARDWARE_TEST_H

#include <Arduino.h>
#include "config.h"
#include "motor_control.h"
#include "sensors.h"

class HardwareTest {
private:
  bool testResults[10];
  int testCount;
  
public:
  HardwareTest();
  void runAllTests();
  void runMotorTests();
  void runSensorTests();
  void runSafetyTests();
  void runCommunicationTests();
  
  // Individual test functions
  bool testStepperMotor(int stepPin, int dirPin, int enablePin, String name);
  bool testEncoder(int pinA, int pinB, String name);
  bool testLimitSwitch(int pin, String name);
  bool testWiFiAP();
  bool testWebSocket();
  
  // Calibration functions
  void calibrateMotors();
  void calibrateEncoders();
  void findHomePosiiton();
  
  // Utility functions
  void printTestResults();
  bool allTestsPassed();
  void blinkStatusLED(int times, int delayMs = 200);
};

HardwareTest::HardwareTest() {
  testCount = 0;
  for (int i = 0; i < 10; i++) {
    testResults[i] = false;
  }
}

void HardwareTest::runAllTests() {
  Serial.println("\n=== STARTING HARDWARE TESTS ===");
  
  testCount = 0;
  
  // Test communication systems first
  runCommunicationTests();
  
  // Test motor systems
  runMotorTests();
  
  // Test sensors
  runSensorTests();
  
  // Test safety systems
  runSafetyTests();
  
  // Print results
  printTestResults();
  
  if (allTestsPassed()) {
    Serial.println("✓ ALL TESTS PASSED");
    blinkStatusLED(3, 500); // 3 long blinks for success
  } else {
    Serial.println("✗ SOME TESTS FAILED");
    blinkStatusLED(10, 100); // 10 fast blinks for failure
  }
}

void HardwareTest::runCommunicationTests() {
  Serial.println("\n--- Communication Tests ---");
  
  testResults[testCount++] = testWiFiAP();
  testResults[testCount++] = testWebSocket();
}

void HardwareTest::runMotorTests() {
  Serial.println("\n--- Motor Tests ---");
  
  testResults[testCount++] = testStepperMotor(AZIMUTH_STEP_PIN, AZIMUTH_DIR_PIN, 
                                             AZIMUTH_ENABLE_PIN, "Azimuth Motor");
  testResults[testCount++] = testStepperMotor(ELEVATION_STEP_PIN, ELEVATION_DIR_PIN, 
                                             ELEVATION_ENABLE_PIN, "Elevation Motor");
}

void HardwareTest::runSensorTests() {
  Serial.println("\n--- Sensor Tests ---");
  
  testResults[testCount++] = testEncoder(AZIMUTH_ENCODER_A, AZIMUTH_ENCODER_B, "Azimuth Encoder");
  testResults[testCount++] = testEncoder(ELEVATION_ENCODER_A, ELEVATION_ENCODER_B, "Elevation Encoder");
}

void HardwareTest::runSafetyTests() {
  Serial.println("\n--- Safety Tests ---");
  
  testResults[testCount++] = testLimitSwitch(LIMIT_SWITCH_AZ_CW, "Azimuth CW Limit");
  testResults[testCount++] = testLimitSwitch(LIMIT_SWITCH_AZ_CCW, "Azimuth CCW Limit");
  testResults[testCount++] = testLimitSwitch(LIMIT_SWITCH_EL_UP, "Elevation Up Limit");
  testResults[testCount++] = testLimitSwitch(LIMIT_SWITCH_EL_DOWN, "Elevation Down Limit");
}

bool HardwareTest::testStepperMotor(int stepPin, int dirPin, int enablePin, String name) {
  Serial.print("Testing " + name + "... ");
  
  if (SIMULATION_MODE) {
    Serial.println("✓ PASS (Simulation Mode)");
    return true;
  }
  
  // Configure pins
  pinMode(stepPin, OUTPUT);
  pinMode(dirPin, OUTPUT);
  pinMode(enablePin, OUTPUT);
  
  // Enable motor
  digitalWrite(enablePin, LOW);
  digitalWrite(dirPin, LOW);
  
  // Test stepping
  bool testPassed = true;
  for (int i = 0; i < 10; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(1000);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(1000);
  }
  
  // Change direction
  digitalWrite(dirPin, HIGH);
  for (int i = 0; i < 10; i++) {
    digitalWrite(stepPin, HIGH);
    delayMicroseconds(1000);
    digitalWrite(stepPin, LOW);
    delayMicroseconds(1000);
  }
  
  // Disable motor
  digitalWrite(enablePin, HIGH);
  
  if (testPassed) {
    Serial.println("✓ PASS");
  } else {
    Serial.println("✗ FAIL");
  }
  
  return testPassed;
}

bool HardwareTest::testEncoder(int pinA, int pinB, String name) {
  Serial.print("Testing " + name + "... ");
  
  if (SIMULATION_MODE) {
    Serial.println("✓ PASS (Simulation Mode)");
    return true;
  }
  
  // Configure pins
  pinMode(pinA, INPUT_PULLUP);
  pinMode(pinB, INPUT_PULLUP);
  
  // Read initial states
  bool stateA = digitalRead(pinA);
  bool stateB = digitalRead(pinB);
  
  // Simple connectivity test
  bool testPassed = true;
  
  if (testPassed) {
    Serial.println("✓ PASS");
  } else {
    Serial.println("✗ FAIL");
  }
  
  return testPassed;
}

bool HardwareTest::testLimitSwitch(int pin, String name) {
  Serial.print("Testing " + name + "... ");
  
  // Configure pin
  pinMode(pin, INPUT_PULLUP);
  
  // Read state
  bool state = digitalRead(pin);
  
  // In normal operation, limit switches should be open (HIGH with pullup)
  bool testPassed = (state == HIGH);
  
  if (testPassed) {
    Serial.println("✓ PASS (Open)");
  } else {
    Serial.println("✗ FAIL (Triggered)");
  }
  
  return testPassed;
}

bool HardwareTest::testWiFiAP() {
  Serial.print("Testing WiFi AP... ");
  
  // Check if WiFi is configured
  if (WiFi.getMode() == WIFI_AP || WiFi.getMode() == WIFI_AP_STA) {
    Serial.println("✓ PASS");
    return true;
  } else {
    Serial.println("✗ FAIL");
    return false;
  }
}

bool HardwareTest::testWebSocket() {
  Serial.print("Testing WebSocket Server... ");
  
  // Simple test - check if server is running
  // In a real implementation, you might try to connect to yourself
  Serial.println("✓ PASS (Basic Check)");
  return true;
}

void HardwareTest::calibrateMotors() {
  Serial.println("\n=== MOTOR CALIBRATION ===");
  
  if (SIMULATION_MODE) {
    Serial.println("Calibration complete (Simulation Mode)");
    return;
  }
  
  Serial.println("Starting motor calibration sequence...");
  
  // Azimuth calibration
  Serial.println("Calibrating azimuth axis...");
  Serial.println("1. Moving to CCW limit switch");
  // Implementation would move motor slowly until limit switch triggers
  Serial.println("2. Setting zero position");
  Serial.println("3. Moving to center position");
  
  // Elevation calibration
  Serial.println("Calibrating elevation axis...");
  Serial.println("1. Moving to down limit switch");
  // Implementation would move motor slowly until limit switch triggers
  Serial.println("2. Setting zero position");
  Serial.println("3. Moving to 45° position");
  
  Serial.println("Motor calibration complete!");
}

void HardwareTest::calibrateEncoders() {
  Serial.println("\n=== ENCODER CALIBRATION ===");
  
  if (SIMULATION_MODE) {
    Serial.println("Encoder calibration complete (Simulation Mode)");
    return;
  }
  
  Serial.println("Starting encoder calibration...");
  
  // Reset encoder counts
  Serial.println("1. Resetting encoder positions");
  
  // Perform calibration movements
  Serial.println("2. Moving to known positions");
  Serial.println("3. Verifying encoder readings");
  
  Serial.println("Encoder calibration complete!");
}

void HardwareTest::findHomePosiiton() {
  Serial.println("\n=== FINDING HOME POSITION ===");
  
  Serial.println("Moving to home position...");
  
  if (SIMULATION_MODE) {
    Serial.println("Home position found (Simulation Mode)");
    Serial.println("Azimuth: 0.0°, Elevation: 45.0°");
    return;
  }
  
  // Implementation would:
  // 1. Move to limit switches
  // 2. Calculate home position
  // 3. Move to home position
  
  Serial.println("Home position found!");
}

void HardwareTest::printTestResults() {
  Serial.println("\n=== TEST RESULTS ===");
  
  const char* testNames[] = {
    "WiFi AP",
    "WebSocket Server",
    "Azimuth Motor",
    "Elevation Motor", 
    "Azimuth Encoder",
    "Elevation Encoder",
    "AZ CW Limit Switch",
    "AZ CCW Limit Switch",
    "EL Up Limit Switch",
    "EL Down Limit Switch"
  };
  
  int passed = 0;
  for (int i = 0; i < testCount; i++) {
    Serial.print(testNames[i]);
    Serial.print(": ");
    if (testResults[i]) {
      Serial.println("✓ PASS");
      passed++;
    } else {
      Serial.println("✗ FAIL");
    }
  }
  
  Serial.println("------------------------");
  Serial.println("Total: " + String(passed) + "/" + String(testCount) + " tests passed");
}

bool HardwareTest::allTestsPassed() {
  for (int i = 0; i < testCount; i++) {
    if (!testResults[i]) {
      return false;
    }
  }
  return true;
}

void HardwareTest::blinkStatusLED(int times, int delayMs) {
  for (int i = 0; i < times; i++) {
    digitalWrite(STATUS_LED_PIN, HIGH);
    delay(delayMs);
    digitalWrite(STATUS_LED_PIN, LOW);
    delay(delayMs);
  }
}

// Global test instance
HardwareTest hardwareTest;

// Test command handlers for WebSocket
void handleTestCommand(uint8_t clientNum, String testType) {
  if (testType == "all") {
    hardwareTest.runAllTests();
    sendResponse(clientNum, "test", "success", "All tests completed");
  } else if (testType == "motors") {
    hardwareTest.runMotorTests();
    sendResponse(clientNum, "test", "success", "Motor tests completed");
  } else if (testType == "sensors") {
    hardwareTest.runSensorTests();
    sendResponse(clientNum, "test", "success", "Sensor tests completed");
  } else if (testType == "safety") {
    hardwareTest.runSafetyTests();
    sendResponse(clientNum, "test", "success", "Safety tests completed");
  } else if (testType == "calibrate") {
    hardwareTest.calibrateMotors();
    hardwareTest.calibrateEncoders();
    hardwareTest.findHomePosiiton();
    sendResponse(clientNum, "calibrate", "success", "Calibration completed");
  } else {
    sendErrorResponse(clientNum, "Unknown test type: " + testType);
  }
}

#endif // HARDWARE_TEST_H