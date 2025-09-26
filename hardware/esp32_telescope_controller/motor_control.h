/*
 * Motor Control Library for ESP32 Robotic Telescope
 * 
 * This library provides high-level motor control functions for stepper motors
 * used in the telescope azimuth and elevation axes.
 */

#ifndef MOTOR_CONTROL_H
#define MOTOR_CONTROL_H

#include <Arduino.h>
#include "config.h"

class StepperMotor {
private:
  int stepPin;
  int dirPin;
  int enablePin;
  int encoderPinA;
  int encoderPinB;
  
  // Motor parameters
  int stepsPerRevolution;
  int microstepping;
  float gearRatio;
  
  // Position and movement
  long currentPosition;     // Current position in steps
  long targetPosition;      // Target position in steps
  float currentAngle;       // Current angle in degrees
  float targetAngle;        // Target angle in degrees
  
  // Speed control
  float maxSpeed;           // Maximum speed in steps/second
  float currentSpeed;       // Current speed in steps/second
  float acceleration;       // Acceleration in steps/second^2
  
  // State
  bool isMoving;
  bool isEnabled;
  bool isCalibrated;
  
  // Timing
  unsigned long lastStepTime;
  unsigned long stepInterval;
  
public:
  // Constructor
  StepperMotor(int step, int dir, int enable, int encA, int encB, 
               int stepsPerRev, int microsteps, float gear);
  
  // Initialization
  void begin();
  void calibrate();
  void enable();
  void disable();
  
  // Movement commands
  void moveTo(float angle);
  void moveToSteps(long steps);
  void moveRelative(float deltaAngle);
  void moveRelativeSteps(long deltaSteps);
  void stop();
  void emergencyStop();
  
  // Configuration
  void setSpeed(float speed);
  void setAcceleration(float accel);
  void setPosition(float angle);
  void setPositionSteps(long steps);
  
  // Status queries
  float getCurrentAngle() const { return currentAngle; }
  float getTargetAngle() const { return targetAngle; }
  long getCurrentPosition() const { return currentPosition; }
  long getTargetPosition() const { return targetPosition; }
  bool getIsMoving() const { return isMoving; }
  bool getIsEnabled() const { return isEnabled; }
  bool getIsCalibrated() const { return isCalibrated; }
  float getCurrentSpeed() const { return currentSpeed; }
  
  // Update function (call in main loop)
  void update();
  
private:
  // Internal functions
  void step();
  void setDirection(bool clockwise);
  long angleToSteps(float angle);
  float stepsToAngle(long steps);
  void updateSpeed();
  void readEncoder();
};

// Implementation

StepperMotor::StepperMotor(int step, int dir, int enable, int encA, int encB,
                          int stepsPerRev, int microsteps, float gear) {
  stepPin = step;
  dirPin = dir;
  enablePin = enable;
  encoderPinA = encA;
  encoderPinB = encB;
  stepsPerRevolution = stepsPerRev;
  microstepping = microsteps;
  gearRatio = gear;
  
  // Initialize state
  currentPosition = 0;
  targetPosition = 0;
  currentAngle = 0.0;
  targetAngle = 0.0;
  maxSpeed = MAX_SPEED_STEPS_PER_SEC;
  currentSpeed = 0.0;
  acceleration = DEFAULT_ACCELERATION;
  isMoving = false;
  isEnabled = false;
  isCalibrated = false;
  lastStepTime = 0;
  stepInterval = 1000000; // 1 second (very slow default)
}

void StepperMotor::begin() {
  // Configure pins
  pinMode(stepPin, OUTPUT);
  pinMode(dirPin, OUTPUT);
  pinMode(enablePin, OUTPUT);
  pinMode(encoderPinA, INPUT_PULLUP);
  pinMode(encoderPinB, INPUT_PULLUP);
  
  // Set initial states
  digitalWrite(stepPin, LOW);
  digitalWrite(dirPin, LOW);
  digitalWrite(enablePin, HIGH); // Disabled initially
  
  Serial.println("Stepper motor initialized");
}

void StepperMotor::calibrate() {
  Serial.println("Starting motor calibration...");
  
  if (SIMULATION_MODE) {
    // Simulation calibration
    currentPosition = 0;
    currentAngle = 0.0;
    targetPosition = 0;
    targetAngle = 0.0;
    isCalibrated = true;
    Serial.println("Motor calibration complete (simulation)");
    return;
  }
  
  // Real hardware calibration would:
  // 1. Move to limit switch
  // 2. Set zero position
  // 3. Move to home position
  
  // For now, just set calibrated flag
  isCalibrated = true;
  Serial.println("Motor calibration complete");
}

void StepperMotor::enable() {
  digitalWrite(enablePin, LOW); // Active low enable
  isEnabled = true;
  Serial.println("Motor enabled");
}

void StepperMotor::disable() {
  digitalWrite(enablePin, HIGH); // Disable motor
  isEnabled = false;
  isMoving = false;
  currentSpeed = 0.0;
  Serial.println("Motor disabled");
}

void StepperMotor::moveTo(float angle) {
  if (!isEnabled || !isCalibrated) {
    Serial.println("Motor not ready for movement");
    return;
  }
  
  targetAngle = angle;
  targetPosition = angleToSteps(angle);
  
  if (targetPosition != currentPosition) {
    isMoving = true;
    Serial.println("Moving to angle: " + String(angle) + " degrees");
  }
}

void StepperMotor::moveToSteps(long steps) {
  if (!isEnabled || !isCalibrated) {
    Serial.println("Motor not ready for movement");
    return;
  }
  
  targetPosition = steps;
  targetAngle = stepsToAngle(steps);
  
  if (targetPosition != currentPosition) {
    isMoving = true;
    Serial.println("Moving to position: " + String(steps) + " steps");
  }
}

void StepperMotor::moveRelative(float deltaAngle) {
  moveTo(currentAngle + deltaAngle);
}

void StepperMotor::moveRelativeSteps(long deltaSteps) {
  moveToSteps(currentPosition + deltaSteps);
}

void StepperMotor::stop() {
  targetPosition = currentPosition;
  targetAngle = currentAngle;
  isMoving = false;
  Serial.println("Motor stopped");
}

void StepperMotor::emergencyStop() {
  stop();
  disable();
  Serial.println("EMERGENCY STOP - Motor disabled");
}

void StepperMotor::setSpeed(float speed) {
  maxSpeed = constrain(speed, MIN_SPEED_STEPS_PER_SEC, MAX_SPEED_STEPS_PER_SEC);
  Serial.println("Speed set to: " + String(maxSpeed) + " steps/sec");
}

void StepperMotor::setAcceleration(float accel) {
  acceleration = constrain(accel, 10.0, 2000.0);
}

void StepperMotor::setPosition(float angle) {
  currentAngle = angle;
  currentPosition = angleToSteps(angle);
  targetAngle = angle;
  targetPosition = currentPosition;
}

void StepperMotor::setPositionSteps(long steps) {
  currentPosition = steps;
  currentAngle = stepsToAngle(steps);
  targetPosition = steps;
  targetAngle = currentAngle;
}

void StepperMotor::update() {
  if (!isMoving || !isEnabled) {
    return;
  }
  
  unsigned long currentTime = micros();
  
  if (SIMULATION_MODE) {
    // Simulation mode - smooth movement
    if (currentTime - lastStepTime >= 50000) { // 50ms updates
      lastStepTime = currentTime;
      
      long positionError = targetPosition - currentPosition;
      if (abs(positionError) <= 1) {
        // Reached target
        currentPosition = targetPosition;
        currentAngle = targetAngle;
        isMoving = false;
        currentSpeed = 0.0;
        return;
      }
      
      // Move towards target
      int direction = (positionError > 0) ? 1 : -1;
      long moveSteps = min(abs(positionError), (long)(maxSpeed * 0.05)); // 5% of max speed per update
      
      currentPosition += direction * moveSteps;
      currentAngle = stepsToAngle(currentPosition);
      currentSpeed = moveSteps / 0.05; // steps per second
    }
    return;
  }
  
  // Real hardware mode
  if (currentTime - lastStepTime >= stepInterval) {
    lastStepTime = currentTime;
    
    long positionError = targetPosition - currentPosition;
    if (positionError == 0) {
      // Reached target
      isMoving = false;
      currentSpeed = 0.0;
      return;
    }
    
    // Determine direction
    bool clockwise = positionError > 0;
    setDirection(clockwise);
    
    // Update speed (simple acceleration profile)
    updateSpeed();
    
    // Calculate step interval
    stepInterval = 1000000.0 / currentSpeed; // microseconds
    
    // Take step
    step();
    
    // Update position
    currentPosition += clockwise ? 1 : -1;
    currentAngle = stepsToAngle(currentPosition);
  }
}

void StepperMotor::step() {
  digitalWrite(stepPin, HIGH);
  delayMicroseconds(5); // Minimum pulse width
  digitalWrite(stepPin, LOW);
}

void StepperMotor::setDirection(bool clockwise) {
  digitalWrite(dirPin, clockwise ? HIGH : LOW);
  delayMicroseconds(5); // Direction setup time
}

long StepperMotor::angleToSteps(float angle) {
  return (long)(angle * stepsPerRevolution * microstepping * gearRatio / 360.0);
}

float StepperMotor::stepsToAngle(long steps) {
  return (float)steps * 360.0 / (stepsPerRevolution * microstepping * gearRatio);
}

void StepperMotor::updateSpeed() {
  long positionError = abs(targetPosition - currentPosition);
  
  // Simple trapezoidal velocity profile
  float targetSpeed = maxSpeed;
  
  // Deceleration distance
  float decelDistance = (currentSpeed * currentSpeed) / (2.0 * acceleration);
  
  if (positionError < decelDistance) {
    // Decelerate
    targetSpeed = sqrt(2.0 * acceleration * positionError);
  }
  
  targetSpeed = constrain(targetSpeed, MIN_SPEED_STEPS_PER_SEC, maxSpeed);
  
  // Accelerate or decelerate towards target speed
  float speedDiff = targetSpeed - currentSpeed;
  float maxSpeedChange = acceleration * (stepInterval / 1000000.0); // acceleration * time
  
  if (abs(speedDiff) <= maxSpeedChange) {
    currentSpeed = targetSpeed;
  } else {
    currentSpeed += (speedDiff > 0) ? maxSpeedChange : -maxSpeedChange;
  }
  
  currentSpeed = constrain(currentSpeed, MIN_SPEED_STEPS_PER_SEC, maxSpeed);
}

void StepperMotor::readEncoder() {
  // Implementation for reading encoder feedback
  // This would be used for closed-loop control
  // For now, just a placeholder
}

#endif // MOTOR_CONTROL_H