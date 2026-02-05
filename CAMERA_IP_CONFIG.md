# Camera IP Configuration Guide

## Overview

The Camera Control Screen now supports flexible IP configuration through two methods:

1. **Manual IP Input** - Enter camera IP address and port manually
2. **QR Code Scanner** - Scan QR code containing camera IP information

## Features

### 1. Manual IP Input

- Click the settings icon (⚙️) in the Camera Control screen
- Enter IP address (e.g., `192.168.4.50`)
- Enter port number (e.g., `81`)
- Click "Save" to update the camera URL
- The new configuration is automatically saved and persists across app restarts

### 2. QR Code Scanner

- Click the settings icon (⚙️) in the Camera Control screen
- Click the "Scan QR" button in the dialog
- Point your camera at a QR code containing the camera IP information
- The app automatically parses the QR code and updates the camera URL

### QR Code Formats Supported

The QR scanner supports multiple formats:

- **Full URL**: `http://192.168.4.50:81`
- **IP:Port**: `192.168.4.50:81`
- **IP Only**: `192.168.4.50` (defaults to port 81)

## Generating QR Codes

You can generate QR codes for your ESP32-CAM IP address using:

- Online QR code generators (e.g., qr-code-generator.com)
- Command line tools
- Or print a QR code containing your camera's IP address

Example QR code content:

```
192.168.4.50:81
```

## Technical Details

### Dependencies Added

- `qr_code_scanner: ^1.0.1` - For QR code scanning functionality
- `shared_preferences: ^2.2.2` - For persisting camera IP settings

### Permissions Required

- **Android**: Camera permission for QR scanning
- **iOS**: Camera usage description for QR scanning

### Implementation

- Camera URL is stored using SharedPreferences
- Automatically loads saved URL on app start
- Validates QR code format before applying
- Provides user feedback via SnackBar messages

## Usage Tips

1. **First Time Setup**: On first launch, the app uses the default IP `192.168.4.50:81`
2. **Changing Networks**: When switching to a different ESP32-CAM, use the settings to update the IP
3. **QR Codes**: Keep QR codes with camera IPs handy for quick configuration
4. **Connection Status**: The colored dot indicator shows connection status:
   - 🟢 Green: Connected
   - 🟠 Orange: Connecting
   - 🔴 Red: Error

## Troubleshooting

- **Can't scan QR code**: Ensure camera permissions are granted in device settings
- **Connection failed**: Verify the IP address is correct and the camera is accessible
- **Settings not saving**: Check app permissions for storage access
