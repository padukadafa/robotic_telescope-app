# ESP32 Robotic Telescope Controller

This Arduino project provides the firmware for controlling a robotic telescope using an ESP32 microcontroller. The system is designed to integrate seamlessly with the Flutter mobile application.

## Features

- **WiFi Access Point**: Creates a dedicated network for telescope control
- **WebSocket Server**: Real-time bidirectional communication with the Flutter app
- **Stepper Motor Control**: Precise positioning for azimuth and elevation axes
- **Safety Systems**: Limit switches, emergency stop, and position monitoring
- **Sensor Integration**: Encoders, environmental sensors, and GPS support
- **Simulation Mode**: Development and testing without physical hardware

## Hardware Requirements

### Core Components

- ESP32 DevKit V1 or compatible
- 2x NEMA 17 Stepper Motors (200 steps/revolution)
- 2x Stepper Motor Drivers (A4988 or DRV8825)
- 12V Power Supply (minimum 3A)

### Optional Components

- 2x Rotary Encoders (for position feedback)
- 4x Limit Switches (safety stops)
- BME280 Environmental Sensor
- NEO-8M GPS Module
- Emergency Stop Button
- Status LED and Buzzer

## Pin Configuration

```
// Azimuth Motor (Horizontal)
#define AZIMUTH_STEP_PIN 2
#define AZIMUTH_DIR_PIN 3
#define AZIMUTH_ENABLE_PIN 4

// Elevation Motor (Vertical)
#define ELEVATION_STEP_PIN 7
#define ELEVATION_DIR_PIN 8
#define ELEVATION_ENABLE_PIN 9

// Encoders
#define AZIMUTH_ENCODER_A 5
#define AZIMUTH_ENCODER_B 6
#define ELEVATION_ENCODER_A 10
#define ELEVATION_ENCODER_B 11

// Safety
#define EMERGENCY_STOP_PIN 0
#define STATUS_LED_PIN 2
```

## Software Setup

### Arduino IDE Configuration

1. Install ESP32 board support:

   - Add `https://dl.espressif.com/dl/package_esp32_index.json` to Additional Board Manager URLs
   - Install "ESP32 by Espressif Systems"

2. Install required libraries:

   ```
   WebSocketsServer by Markus Sattler
   ArduinoJson by Benoit Blanchon
   ESP32Servo (if using servo motors)
   ```

3. Select board: "ESP32 Dev Module"

### Project Structure

```
esp32_telescope_controller/
├── esp32_telescope_controller.ino  // Main firmware file
├── config.h                        // Configuration settings
├── motor_control.h                  // Motor control library
├── sensors.h                        // Sensor interface library
└── README.md                        // This file
```

## Configuration

Edit `config.h` to customize your setup:

```cpp
// WiFi Settings
#define WIFI_SSID "RoboticTelescope"
#define WIFI_PASSWORD "telescope123"

// Motor Settings
#define STEPS_PER_REVOLUTION 200
#define MICROSTEPPING 16
#define AZIMUTH_GEAR_RATIO 100.0
#define ELEVATION_GEAR_RATIO 80.0

// Enable/Disable Simulation Mode
#define SIMULATION_MODE true
```

## API Commands

The ESP32 accepts JSON commands via WebSocket:

### Movement Commands

```json
// Move to specific position
{
  "action": "moveTo",
  "azimuth": 180.0,
  "elevation": 45.0
}

// Incremental movement
{
  "action": "slew",
  "direction": "up",
  "steps": 50
}

// Stop movement
{
  "action": "stop"
}
```

### System Commands

```json
// Calibrate telescope
{
  "action": "calibrate"
}

// Go to home position
{
  "action": "home"
}

// Emergency stop
{
  "action": "emergencyStop"
}

// Get current status
{
  "action": "getStatus"
}

// Set motor speed
{
  "action": "setSpeed",
  "speed": 500.0
}
```

## Status Updates

The ESP32 continuously broadcasts position updates:

```json
{
  "type": "position",
  "azimuth": 180.0,
  "elevation": 45.0,
  "targetAzimuth": 180.0,
  "targetElevation": 45.0,
  "moving": false,
  "calibrated": true,
  "status": "Ready",
  "emergencyStop": false,
  "timestamp": 12345678
}
```

## Safety Features

- **Limit Switches**: Prevent mechanical damage by stopping movement at limits
- **Emergency Stop**: Immediate halt of all operations
- **Position Validation**: Ensures commands are within safe ranges
- **Watchdog Timer**: Automatic system reset if communication fails
- **Soft Limits**: Software-based position constraints

## Simulation Mode

For development and testing without hardware:

1. Set `SIMULATION_MODE` to `true` in `config.h`
2. The system will simulate motor movements and sensor readings
3. All commands work the same way as with real hardware
4. Useful for app development and testing

## Integration with Flutter App

The ESP32 is designed to work with the robotic telescope Flutter application:

1. **Connection**: App scans for "RoboticTelescope" WiFi network
2. **Control**: WebSocket connection to `ws://192.168.4.1:81`
3. **Commands**: JSON-based command protocol
4. **Feedback**: Real-time position updates and status

## Troubleshooting

### Common Issues

1. **WiFi Connection Failed**

   - Check SSID and password in config.h
   - Ensure ESP32 is powered properly
   - Try resetting the ESP32

2. **Motors Not Moving**

   - Verify pin connections
   - Check motor driver power supply
   - Ensure ENABLE pins are connected and working

3. **Erratic Movement**

   - Check for loose connections
   - Verify step/direction timing
   - Ensure adequate power supply

4. **WebSocket Connection Issues**
   - Confirm IP address (default: 192.168.4.1)
   - Check firewall settings
   - Try connecting with a WebSocket test client

### Debug Mode

Enable debug output by setting `DEBUG_SERIAL` to `true` in config.h. This will provide detailed logging via the serial monitor.

## Customization

### Adding New Sensors

1. Define pins in `config.h`
2. Add sensor class to `sensors.h`
3. Initialize in `setup()` function
4. Update sensor readings in main loop

### Modifying Movement Parameters

Edit the motor configuration in `config.h`:

- `MAX_SPEED_STEPS_PER_SEC`: Maximum motor speed
- `DEFAULT_ACCELERATION`: Acceleration/deceleration rate
- `POSITION_TOLERANCE`: Position accuracy threshold

### Custom Commands

Add new commands in the `handleCommand()` function:

```cpp
else if (action == "myCustomCommand") {
  // Your custom implementation
  sendResponse(clientNum, "myCustomCommand", "success", "Command executed");
}
```

## License

This project is provided as-is for educational and research purposes. Feel free to modify and adapt for your specific telescope setup.

## Support

For questions and issues:

1. Check the troubleshooting section
2. Review the Flutter app documentation
3. Verify hardware connections and power supply
