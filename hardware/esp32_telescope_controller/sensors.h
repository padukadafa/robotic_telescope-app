/*
 * Sensor Interface Library for ESP32 Robotic Telescope
 * 
 * This library provides interfaces for various sensors used in the telescope system
 * including encoders, limit switches, and environmental sensors.
 */

#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>
#include "config.h"

// Encoder class for position feedback
class RotaryEncoder {
private:
  int pinA;
  int pinB;
  volatile long position;
  volatile int lastEncoded;
  int pulsesPerRevolution;
  float gearRatio;
  
public:
  RotaryEncoder(int pA, int pB, int ppr, float gear);
  void begin();
  void update();
  long getPosition() const { return position; }
  float getAngle() const;
  void setPosition(long pos) { position = pos; }
  void reset() { position = 0; }
  
  // Interrupt service routine (must be static)
  static void IRAM_ATTR handleInterrupt();
};

// Limit Switch class for safety
class LimitSwitch {
private:
  int pin;
  bool lastState;
  bool currentState;
  unsigned long lastDebounceTime;
  unsigned long debounceDelay;
  bool normallyOpen;
  
public:
  LimitSwitch(int p, bool no = true);
  void begin();
  void update();
  bool isTriggered() const { return currentState; }
  bool wasJustTriggered();
};

// Environmental sensor class (temperature, humidity, etc.)
class EnvironmentalSensor {
private:
  float temperature;
  float humidity;
  float pressure;
  unsigned long lastReading;
  unsigned long readingInterval;
  
public:
  EnvironmentalSensor();
  void begin();
  void update();
  float getTemperature() const { return temperature; }
  float getHumidity() const { return humidity; }
  float getPressure() const { return pressure; }
  bool isDataValid() const;
};

// GPS sensor for precise positioning
class GPSSensor {
private:
  float latitude;
  float longitude;
  float altitude;
  bool isValid;
  unsigned long lastUpdate;
  
public:
  GPSSensor();
  void begin();
  void update();
  float getLatitude() const { return latitude; }
  float getLongitude() const { return longitude; }
  float getAltitude() const { return altitude; }
  bool isPositionValid() const { return isValid; }
};

// Implementations

RotaryEncoder::RotaryEncoder(int pA, int pB, int ppr, float gear) {
  pinA = pA;
  pinB = pB;
  pulsesPerRevolution = ppr;
  gearRatio = gear;
  position = 0;
  lastEncoded = 0;
}

void RotaryEncoder::begin() {
  pinMode(pinA, INPUT_PULLUP);
  pinMode(pinB, INPUT_PULLUP);
  
  // Attach interrupts for quadrature decoding
  attachInterrupt(digitalPinToInterrupt(pinA), handleInterrupt, CHANGE);
  attachInterrupt(digitalPinToInterrupt(pinB), handleInterrupt, CHANGE);
  
  Serial.println("Encoder initialized");
}

void RotaryEncoder::update() {
  // Position is updated in interrupt handler
  // This function can be used for additional processing
}

float RotaryEncoder::getAngle() const {
  // Convert encoder position to angle in degrees
  return (float)position * 360.0 / (pulsesPerRevolution * gearRatio);
}

void IRAM_ATTR RotaryEncoder::handleInterrupt() {
  // This would be implemented for actual encoder reading
  // For simulation, we'll just use a placeholder
}

LimitSwitch::LimitSwitch(int p, bool no) {
  pin = p;
  normallyOpen = no;
  lastState = false;
  currentState = false;
  lastDebounceTime = 0;
  debounceDelay = 50; // 50ms debounce
}

void LimitSwitch::begin() {
  pinMode(pin, INPUT_PULLUP);
  
  // Read initial state
  bool reading = digitalRead(pin) == LOW;
  currentState = normallyOpen ? reading : !reading;
  lastState = currentState;
  
  Serial.println("Limit switch initialized on pin " + String(pin));
}

void LimitSwitch::update() {
  bool reading = digitalRead(pin) == LOW;
  bool switchState = normallyOpen ? reading : !reading;
  
  // Debounce the switch
  if (switchState != lastState) {
    lastDebounceTime = millis();
  }
  
  if ((millis() - lastDebounceTime) > debounceDelay) {
    if (switchState != currentState) {
      currentState = switchState;
      if (currentState) {
        Serial.println("Limit switch triggered on pin " + String(pin));
      }
    }
  }
  
  lastState = switchState;
}

bool LimitSwitch::wasJustTriggered() {
  static bool lastTriggered = false;
  bool justTriggered = currentState && !lastTriggered;
  lastTriggered = currentState;
  return justTriggered;
}

EnvironmentalSensor::EnvironmentalSensor() {
  temperature = 20.0; // Default values
  humidity = 50.0;
  pressure = 1013.25;
  lastReading = 0;
  readingInterval = 5000; // 5 seconds
}

void EnvironmentalSensor::begin() {
  // Initialize sensor (e.g., BME280, DHT22)
  Serial.println("Environmental sensor initialized");
}

void EnvironmentalSensor::update() {
  if (millis() - lastReading < readingInterval) {
    return;
  }
  
  lastReading = millis();
  
  if (SIMULATION_MODE) {
    // Simulate environmental readings
    temperature = 20.0 + sin(millis() / 10000.0) * 5.0; // 15-25°C
    humidity = 50.0 + cos(millis() / 15000.0) * 20.0;   // 30-70%
    pressure = 1013.25 + sin(millis() / 20000.0) * 50.0; // 963-1063 hPa
  } else {
    // Read actual sensor
    // Implementation would depend on specific sensor used
    // Example for BME280:
    // temperature = bme.readTemperature();
    // humidity = bme.readHumidity();
    // pressure = bme.readPressure() / 100.0F;
  }
}

bool EnvironmentalSensor::isDataValid() const {
  return (temperature > -40.0 && temperature < 85.0 &&
          humidity >= 0.0 && humidity <= 100.0 &&
          pressure > 300.0 && pressure < 1100.0);
}

GPSSensor::GPSSensor() {
  latitude = 0.0;
  longitude = 0.0;
  altitude = 0.0;
  isValid = false;
  lastUpdate = 0;
}

void GPSSensor::begin() {
  // Initialize GPS module (e.g., NEO-8M)
  Serial.println("GPS sensor initialized");
  
  if (SIMULATION_MODE) {
    // Set simulated location (example: Jakarta, Indonesia)
    latitude = -6.2088;
    longitude = 106.8456;
    altitude = 8.0;
    isValid = true;
  }
}

void GPSSensor::update() {
  if (SIMULATION_MODE) {
    // GPS position is static in simulation
    return;
  }
  
  // Read GPS data
  // Implementation would depend on GPS module used
  // Example for software serial GPS:
  /*
  while (gpsSerial.available() > 0) {
    if (gps.encode(gpsSerial.read())) {
      if (gps.location.isValid()) {
        latitude = gps.location.lat();
        longitude = gps.location.lng();
        altitude = gps.altitude.meters();
        isValid = true;
        lastUpdate = millis();
      }
    }
  }
  
  // Check if data is stale
  if (millis() - lastUpdate > 10000) { // 10 seconds
    isValid = false;
  }
  */
}

// Sensor Manager class to handle all sensors
class SensorManager {
private:
  RotaryEncoder* azimuthEncoder;
  RotaryEncoder* elevationEncoder;
  LimitSwitch* limitSwitches[4];
  EnvironmentalSensor* envSensor;
  GPSSensor* gpsSensor;
  
public:
  SensorManager();
  ~SensorManager();
  void begin();
  void update();
  
  // Accessor methods
  RotaryEncoder* getAzimuthEncoder() { return azimuthEncoder; }
  RotaryEncoder* getElevationEncoder() { return elevationEncoder; }
  LimitSwitch* getLimitSwitch(int index) { return limitSwitches[index]; }
  EnvironmentalSensor* getEnvSensor() { return envSensor; }
  GPSSensor* getGPSSensor() { return gpsSensor; }
  
  // Safety checks
  bool checkLimitSwitches();
  bool isSystemSafe();
};

SensorManager::SensorManager() {
  // Create sensor instances
  azimuthEncoder = new RotaryEncoder(AZIMUTH_ENCODER_A, AZIMUTH_ENCODER_B, 1000, AZIMUTH_GEAR_RATIO);
  elevationEncoder = new RotaryEncoder(ELEVATION_ENCODER_A, ELEVATION_ENCODER_B, 1000, ELEVATION_GEAR_RATIO);
  
  limitSwitches[0] = new LimitSwitch(LIMIT_SWITCH_AZ_CW);
  limitSwitches[1] = new LimitSwitch(LIMIT_SWITCH_AZ_CCW);
  limitSwitches[2] = new LimitSwitch(LIMIT_SWITCH_EL_UP);
  limitSwitches[3] = new LimitSwitch(LIMIT_SWITCH_EL_DOWN);
  
  envSensor = new EnvironmentalSensor();
  gpsSensor = new GPSSensor();
}

SensorManager::~SensorManager() {
  delete azimuthEncoder;
  delete elevationEncoder;
  for (int i = 0; i < 4; i++) {
    delete limitSwitches[i];
  }
  delete envSensor;
  delete gpsSensor;
}

void SensorManager::begin() {
  Serial.println("Initializing sensor manager...");
  
  azimuthEncoder->begin();
  elevationEncoder->begin();
  
  for (int i = 0; i < 4; i++) {
    limitSwitches[i]->begin();
  }
  
  envSensor->begin();
  gpsSensor->begin();
  
  Serial.println("All sensors initialized");
}

void SensorManager::update() {
  // Update all sensors
  azimuthEncoder->update();
  elevationEncoder->update();
  
  for (int i = 0; i < 4; i++) {
    limitSwitches[i]->update();
  }
  
  envSensor->update();
  gpsSensor->update();
}

bool SensorManager::checkLimitSwitches() {
  for (int i = 0; i < 4; i++) {
    if (limitSwitches[i]->isTriggered()) {
      return true;
    }
  }
  return false;
}

bool SensorManager::isSystemSafe() {
  // Check all safety conditions
  if (checkLimitSwitches()) {
    Serial.println("Safety violation: Limit switch triggered");
    return false;
  }
  
  if (!envSensor->isDataValid()) {
    Serial.println("Warning: Environmental sensor data invalid");
    // Don't stop system for environmental sensor issues
  }
  
  // Add more safety checks as needed
  return true;
}

#endif // SENSORS_H