# 🔭 Robotic Telescope Control App

Flutter application untuk mengontrol robotic telescope dengan ESP32 controller.

## 🌟 Features

- 📡 WiFi connection ke telescope
- 🎯 Object selection (planets, stars, DSO)
- 🕹️ Manual telescope control
- 📊 Real-time monitoring
- 🎮 Fine-tuning mode
- 🧪 **Development simulator** (BARU!)

## 🚀 Quick Start

### Development Mode (No Hardware Needed!)

```bash
# 1. Clone & install dependencies
flutter pub get

# 2. Run the app
flutter run

# 3. Click "Start Dummy" button
# That's it! Test semua fitur tanpa hardware.
```

### Production Mode (With Real Hardware)

```bash
# Connect to ESP32 telescope via WiFi
# App akan auto-scan & connect
```

## 🧪 Testing & Development

### Mode 1: Dummy Mode ⚡ (Recommended)

- One-click testing tanpa setup
- Perfect untuk UI development
- No network needed
- Instant feedback

**Cara pakai:**

1. Buka app
2. Klik "Start Dummy" di Connection screen
3. Done! 🎉

### Mode 2: WebSocket Simulator 🌐

- More realistic testing dengan network
- Real WebSocket communication
- Server logging

**Cara pakai:**

```bash
# Terminal 1 - Start server
cd simulation
npm install
node server.js

# Terminal 2 - Run app
flutter run

# Connect dengan IP komputer Anda
```

**Dokumentasi lengkap:**

- 📖 [Quick Start Guide](QUICK_START.md)
- 📚 [Simulator Guide](SIMULATOR_GUIDE.md)
- 📋 [Implementation Summary](IMPLEMENTATION_SUMMARY.md)

## 📁 Project Structure

```
lib/
├── core/
│   ├── models/          # Data models
│   ├── providers/       # State management
│   ├── services/        # Business logic
│   │   ├── telescope_dummy_service.dart  # 🆕 Simulator
│   │   ├── telescope_websocket_manager.dart
│   │   └── stepper_motor_controller.dart
│   └── widgets/         # Reusable widgets
├── features/
│   ├── connection/      # WiFi & Connection
│   ├── object_selection/ # Target selection
│   ├── telescope_control/ # Manual control
│   └── monitoring/      # Status monitoring
└── main.dart

hardware/
├── esp32_telescope_controller/  # Arduino code
└── ...

simulation/
├── server.js           # 🆕 WebSocket simulator
├── package.json
└── README.md

test/
└── telescope_dummy_service_test.dart  # 🆕 Unit tests
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run specific test
flutter test test/telescope_dummy_service_test.dart

# Current status: ✅ 13/13 tests passed
```

## 🎯 Development Workflow

1. **UI Development** → Use Dummy Mode
2. **Feature Testing** → Use Dummy Mode
3. **Integration Testing** → Use Server Mode
4. **Hardware Testing** → Use Real ESP32

## 📊 Features Status

| Feature          | Dummy Mode | Server Mode | Hardware |
| ---------------- | ---------- | ----------- | -------- |
| Connection       | ✅         | ✅          | ✅       |
| Position Updates | ✅         | ✅          | ✅       |
| Go To Target     | ✅         | ✅          | ✅       |
| Manual Slew      | ✅         | ✅          | ✅       |
| Stop/Emergency   | ✅         | ✅          | ✅       |
| Calibration      | ✅         | ✅          | ✅       |
| Home Position    | ✅         | ✅          | ✅       |
| Speed Control    | ✅         | ✅          | ✅       |
| Fine-tuning      | ✅         | ✅          | ✅       |

## 🔧 Configuration

### Hardware Configuration

```cpp
// hardware/esp32_telescope_controller/config.h
#define WIFI_SSID "Telescope_AP"
#define WIFI_PASSWORD "your_password"
#define WEBSOCKET_PORT 81
```

### App Configuration

```dart
// lib/core/providers/telescope_provider.dart
String _wsUrl = 'ws://192.168.4.1:81'; // Default ESP32 IP
```

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **State Management:** Provider
- **Communication:** WebSocket
- **Hardware:** ESP32 + Stepper Motors
- **Simulator:** Node.js + ws package

## 📝 TODO

- [ ] Add IP input field in UI
- [ ] Implement auto-discovery for ESP32
- [ ] Add connection timeout & retry
- [ ] Add GPS/Compass integration
- [ ] Add star catalog database
- [ ] Add image capture support
- [ ] Add tracking mode

## 🤝 Contributing

1. Fork the project
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Daniel**

---

**Happy Stargazing!** 🌟🔭
