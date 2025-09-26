/*
 * Configuration file for ESP32 Robotic Telescope Controller
 * 
 * This file contains all the configurable parameters for the telescope system.
 * Modify these values according to your hardware setup and requirements.
 */

#ifndef CONFIG_H
#define CONFIG_H

// WiFi Configuration
#define WIFI_SSID "RoboticTelescope"
#define WIFI_PASSWORD "telescope123"
#define WIFI_CHANNEL 1

// Network Configuration
#define AP_IP_ADDRESS "192.168.4.1"
#define AP_GATEWAY "192.168.4.1"
#define AP_SUBNET "255.255.255.0"
#define WEBSOCKET_PORT 81

// Hardware Pin Definitions
// Azimuth Motor (Horizontal Movement)
#define AZIMUTH_STEP_PIN 2
#define AZIMUTH_DIR_PIN 3
#define AZIMUTH_ENABLE_PIN 4
#define AZIMUTH_ENCODER_A 5
#define AZIMUTH_ENCODER_B 6

// Elevation Motor (Vertical Movement)
#define ELEVATION_STEP_PIN 7
#define ELEVATION_DIR_PIN 8
#define ELEVATION_ENABLE_PIN 9
#define ELEVATION_ENCODER_A 10
#define ELEVATION_ENCODER_B 11

// Limit Switches
#define LIMIT_SWITCH_AZ_CW 12      // Azimuth Clockwise limit
#define LIMIT_SWITCH_AZ_CCW 13     // Azimuth Counter-clockwise limit
#define LIMIT_SWITCH_EL_UP 14      // Elevation Up limit
#define LIMIT_SWITCH_EL_DOWN 15    // Elevation Down limit

// Control Pins
#define STATUS_LED_PIN 2
#define EMERGENCY_STOP_PIN 0
#define BUZZER_PIN 16

// Motor Specifications
#define STEPS_PER_REVOLUTION 200   // Standard NEMA 17 stepper motor
#define MICROSTEPPING 16           // Microstepping setting on driver
#define AZIMUTH_GEAR_RATIO 100.0   // Gear reduction for azimuth axis
#define ELEVATION_GEAR_RATIO 80.0  // Gear reduction for elevation axis

// Movement Parameters
#define MAX_SPEED_STEPS_PER_SEC 1000.0
#define DEFAULT_ACCELERATION 500.0
#define MIN_SPEED_STEPS_PER_SEC 10.0
#define POSITION_TOLERANCE 0.1     // Degrees

// Timing Configuration
#define POSITION_UPDATE_INTERVAL 50    // milliseconds
#define STATUS_BROADCAST_INTERVAL 100  // milliseconds
#define WATCHDOG_TIMEOUT 5000          // milliseconds

// Safety Limits
#define AZIMUTH_MIN_ANGLE 0.0      // Minimum azimuth angle (degrees)
#define AZIMUTH_MAX_ANGLE 360.0    // Maximum azimuth angle (degrees)
#define ELEVATION_MIN_ANGLE 0.0    // Minimum elevation angle (degrees)
#define ELEVATION_MAX_ANGLE 90.0   // Maximum elevation angle (degrees)

// Communication Settings
#define SERIAL_BAUD_RATE 115200
#define JSON_BUFFER_SIZE 1024
#define MAX_WEBSOCKET_CLIENTS 4

// Simulation Settings (for development)
#define SIMULATION_MODE true       // Set to false for real hardware
#define SIMULATION_MOVE_RATE 2.0   // degrees per second in simulation

// Debug Settings
#define DEBUG_SERIAL true
#define DEBUG_WEBSOCKET true
#define DEBUG_MOTORS true

#endif // CONFIG_H