# Camera Server Mode Guide

## Overview

The Camera Control Screen now supports **Server Mode**, allowing your device to act as a camera server that other devices can connect to.

## Features

### 🎥 Server Mode

Transform your device into a camera streaming server:

- Uses device's built-in camera
- Runs HTTP server on port 8080
- Generates QR code for easy client connection
- Shows server IP address and port

### 📱 Client Mode (Default)

Connect to external camera streams:

- Manual IP input
- QR code scanning
- VR mode support
- Full-screen viewing

## How to Use Server Mode

### Starting the Server

1. Open the Camera Control screen
2. Tap the **camera icon** (📹) in the app bar
3. Grant camera permissions when prompted
4. The device will:
   - Initialize the camera
   - Start HTTP server on port 8080
   - Display local camera preview
   - Show server IP in status bar

### Sharing Connection Info

1. Tap the **QR code icon** in the app bar (only visible in server mode)
2. A dialog will show:
   - QR code containing server URL
   - Server IP address
   - Port number (8080)
   - Selectable text URL

### Connecting from Client

**Option 1: Scan QR Code**

1. On client device, open Camera Control
2. Tap settings icon (⚙️)
3. Tap "Scan QR" button
4. Scan the QR code from the server device

**Option 2: Manual Entry**

1. On client device, tap settings icon (⚙️)
2. Enter server's IP address
3. Enter port: 8080
4. Tap "Save"

### Stopping the Server

1. Tap the **camera off icon** (📹🚫) in the app bar
2. Server will stop and camera will be released
3. App returns to client mode

## Technical Details

### Server Configuration

- **Port**: 8080 (configurable)
- **Protocol**: HTTP
- **Camera Resolution**: Medium (640x480)
- **Audio**: Disabled

### Network Requirements

- Both devices must be on the same network
- Firewall must allow connections on port 8080
- Server device needs WiFi connection

### Permissions Required

- **Camera**: For capturing video stream
- **Network**: For determining device IP address

## Features by Mode

### Client Mode

- ✅ Manual IP input
- ✅ QR code scanning
- ✅ VR mode
- ✅ Full-screen mode
- ✅ Stream refresh
- ✅ Settings dialog

### Server Mode

- ✅ Live camera preview
- ✅ QR code generation
- ✅ IP address display
- ✅ Server status indicator
- ❌ VR mode (not available)
- ❌ Full-screen (not available)

## Status Indicators

| Color     | Status            | Mode        |
| --------- | ----------------- | ----------- |
| 🟢 Green  | Connected/Running | Both        |
| 🟠 Orange | Connecting        | Client only |
| 🔴 Red    | Error             | Client only |

## Troubleshooting

### Server won't start

- Check camera permissions in device settings
- Ensure no other app is using the camera
- Verify network connectivity

### Client can't connect

- Verify both devices are on same network
- Check firewall settings on server device
- Confirm IP address and port are correct
- Try pinging server IP from client device

### QR code won't scan

- Ensure good lighting
- Keep camera steady
- Make sure QR code is fully visible
- Grant camera permission to scanner

### Poor performance

- Reduce number of connected clients
- Check network bandwidth
- Use wired connection for server if possible
- Close other apps using network/camera

## Use Cases

1. **Remote Monitoring**: Use old phone as security camera
2. **Telescope Viewing**: Share telescope view with multiple observers
3. **Field Work**: Stream live observations to team
4. **Education**: Show demonstrations to multiple students
5. **Collaboration**: Share live view during remote troubleshooting

## Notes

- Server mode automatically saves preference
- App remembers last selected mode between launches
- Camera stream is not encrypted (use on trusted networks)
- Only one server instance per device
- Multiple clients can connect to one server
- Server continues running until explicitly stopped
