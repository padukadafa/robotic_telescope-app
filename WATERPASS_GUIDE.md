# Panduan Implementasi Waterpass (Level Monitor) dengan MPU6050

## Overview

Fitur waterpass telah ditambahkan ke aplikasi robotic telescope untuk membantu user memonitor apakah teleskop sudah berada dalam posisi datar. Fitur ini menampilkan visualisasi bubble level real-time yang memudahkan user untuk menyesuaikan posisi mounting tripod secara manual.

## Cara Akses Fitur

1. Buka aplikasi Flutter
2. Tekan icon **Settings** (⚙️) di pojok kanan atas AppBar
3. Pilih menu **"Lihat Waterpass"**
4. Lihat visualisasi bubble level real-time
5. Sesuaikan tripod hingga bubble berada di zona hijau (tengah)
6. Indikator "LEVEL" berwarna hijau muncul saat teleskop sudah datar (roll & pitch < 2°)

## Fitur yang Ditambahkan

### 1. Di Flutter App (✅ Sudah Selesai)

#### TelescopeProvider (`lib/core/providers/telescope_provider.dart`)

- **Field baru:**

  - `double roll`: Roll angle dalam derajat dari sensor MPU6050
  - `double pitch`: Pitch angle dalam derajat dari sensor MPU6050
  - `bool isLevel`: Getter untuk cek apakah teleskop sudah level (roll & pitch < 2°)

- **WebSocket handling:**
  - Menangani message type `"level"` untuk update roll dan pitch secara real-time

#### Settings Screen (`lib/features/settings/settings_screen.dart`)

- Menu pengaturan aplikasi
- Navigasi ke Kalibrasi Sensor
- Navigasi ke Waterpass Viewer

#### Waterpass Screen (`lib/features/waterpass/waterpass_screen.dart`)

- **Visualisasi Bubble Level:**

  - Bubble yang bergerak berdasarkan data roll dan pitch
  - Safe zone (lingkaran hijau) untuk toleransi ±2°
  - Crosshair dan reference circles
  - Indikator status "LEVEL" saat sudah datar
  - Real-time display nilai roll dan pitch dalam derajat
  - Warna hijau untuk level, orange untuk warning

- **Status Card:**

  - Indikator visual dengan dot hijau/orange
  - Pesan status "Teleskop sudah datar" atau "Sesuaikan posisi teleskop"

- **Instructions Card:**
  - Panduan penggunaan untuk user

## Implementasi di ESP32 (⚠️ Perlu Dilakukan)

### 1. Hardware Setup

#### Pin Connection MPU6050

```cpp
// Tambahkan ke config.h
#define MPU6050_SDA_PIN 21  // Default I2C SDA
#define MPU6050_SCL_PIN 22  // Default I2C SCL
```

#### Library yang Diperlukan

```cpp
// Tambahkan ke esp32_telescope_controller.ino
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>

// Library: https://github.com/adafruit/Adafruit_MPU6050
// Install via Arduino Library Manager: "Adafruit MPU6050"
```

### 2. Implementasi Sensor Class

#### Tambahkan ke `sensors.h`:

```cpp
// MPU6050 Level Sensor Class
class LevelSensor {
private:
  Adafruit_MPU6050 mpu;
  float roll;
  float pitch;
  bool isInitialized;
  unsigned long lastReading;
  unsigned long readingInterval;

public:
  LevelSensor() {
    roll = 0.0;
    pitch = 0.0;
    isInitialized = false;
    lastReading = 0;
    readingInterval = 50; // Update setiap 50ms (20Hz)
  }

  void begin() {
    Serial.println("Initializing MPU6050...");

    if (!mpu.begin()) {
      Serial.println("Failed to find MPU6050 chip");
      isInitialized = false;
      return;
    }

    Serial.println("MPU6050 Found!");

    // Set accelerometer range (±2g cukup untuk level sensing)
    mpu.setAccelerometerRange(MPU6050_RANGE_2_G);

    // Set gyroscope range
    mpu.setGyroRange(MPU6050_RANGE_250_DEG);

    // Set filter bandwidth
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

    isInitialized = true;
    Serial.println("MPU6050 initialized successfully");
  }

  void update() {
    if (!isInitialized) return;

    if (millis() - lastReading < readingInterval) {
      return;
    }

    lastReading = millis();

    // Read sensor data
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // Calculate roll and pitch from accelerometer
    // Roll: rotation around X-axis (kiri-kanan)
    roll = atan2(a.acceleration.y, a.acceleration.z) * 180.0 / PI;

    // Pitch: rotation around Y-axis (depan-belakang)
    pitch = atan2(-a.acceleration.x, sqrt(a.acceleration.y * a.acceleration.y +
                                          a.acceleration.z * a.acceleration.z)) * 180.0 / PI;
  }

  float getRoll() const { return roll; }
  float getPitch() const { return pitch; }
  bool isLevel() const {
    return (abs(roll) < 2.0 && abs(pitch) < 2.0);
  }
  bool isReady() const { return isInitialized; }
};
```

#### Update SensorManager class:

```cpp
// Tambahkan ke SensorManager class di sensors.h
class SensorManager {
private:
  // ... existing sensors ...
  LevelSensor* levelSensor;  // Tambah ini

public:
  SensorManager() {
    // ... existing code ...
    levelSensor = new LevelSensor();
  }

  ~SensorManager() {
    // ... existing code ...
    delete levelSensor;
  }

  void begin() {
    Serial.println("Initializing sensor manager...");
    // ... existing sensors ...
    levelSensor->begin();
    Serial.println("All sensors initialized");
  }

  void update() {
    // ... existing sensors ...
    levelSensor->update();
  }

  LevelSensor* getLevelSensor() { return levelSensor; }
};
```

### 3. Main Loop - Periodic Updates

#### Tambahkan ke file utama (contoh: `esp32_telescope_controller_v2.ino`):

```cpp
// Variabel global untuk tracking update terakhir
unsigned long lastLevelUpdate = 0;
const unsigned long LEVEL_UPDATE_INTERVAL = 100; // Update setiap 100ms (10Hz)

void loop() {
  // ... existing code ...

  // Update sensors
  sensors.update();

  // Send periodic level updates
  sendLevelUpdates();

  // ... existing code ...
}

void sendLevelUpdates() {
  if (millis() - lastLevelUpdate < LEVEL_UPDATE_INTERVAL) {
    return;
  }

  lastLevelUpdate = millis();

  LevelSensor* level = sensors.getLevelSensor();

  if (!level->isReady()) {
    return;
  }

  // Kirim data level ke semua client yang terhubung
  DynamicJsonDocument doc(256);
  doc["type"] = "level";
  doc["roll"] = level->getRoll();
  doc["pitch"] = level->getPitch();
  doc["isLevel"] = level->isLevel();
  doc["timestamp"] = millis();

  String response;
  serializeJson(doc, response);

  // Broadcast ke semua connected clients
  webSocket.broadcastTXT(response);
}
```

### 4. Format Data WebSocket

#### Response dari ESP32 ke Flutter (periodic, ~10Hz):

```json
{
  "type": "level",
  "roll": 1.23, // degrees (positif = miring ke kanan)
  "pitch": -0.45, // degrees (positif = miring ke depan)
  "isLevel": false, // true jika roll & pitch < 2°
  "timestamp": 1234567890
}
```

## Testing & Debugging

### 1. Test MPU6050 Connection

```cpp
void setup() {
  // ... existing setup ...

  // Test MPU6050
  Serial.println("\n=== Testing MPU6050 ===");
  if (sensors.getLevelSensor()->isReady()) {
    Serial.println("✓ MPU6050 OK");
  } else {
    Serial.println("✗ MPU6050 FAILED");
    Serial.println("Check:");
    Serial.println("- I2C wiring (SDA, SCL, VCC, GND)");
    Serial.println("- I2C address (default 0x68)");
    Serial.println("- Power supply (3.3V)");
  }
}
```

### 2. Monitor Serial Output untuk Debug

```cpp
void loop() {
  // ... existing code ...

  // Optional: Print level data untuk debugging
  static unsigned long lastDebugPrint = 0;
  if (millis() - lastDebugPrint > 1000) { // Print setiap 1 detik
    lastDebugPrint = millis();
    LevelSensor* level = sensors.getLevelSensor();
    if (level->isReady()) {
      Serial.printf("Level: Roll=%.2f° Pitch=%.2f° [%s]\n",
                    level->getRoll(),
                    level->getPitch(),
                    level->isLevel() ? "LEVEL" : "NOT LEVEL");
    }
  }
}
```

### 3. Test dengan Flutter App

1. Upload kode ESP32
2. Sambungkan Flutter app ke teleskop
3. Buka Settings → Lihat Waterpass
4. Miringkan teleskop, verify bubble bergerak
5. Ratakan teleskop, verify indikator hijau muncul

### 4. I2C Scanner (jika MPU6050 tidak terdeteksi)

```cpp
void scanI2C() {
  Wire.begin(21, 22); // SDA, SCL
  Serial.println("\nScanning I2C bus...");

  for (byte address = 1; address < 127; address++) {
    Wire.beginTransmission(address);
    byte error = Wire.endTransmission();

    if (error == 0) {
      Serial.print("I2C device found at 0x");
      if (address < 16) Serial.print("0");
      Serial.println(address, HEX);
    }
  }
  Serial.println("Scan complete");
}

// Call in setup:
// scanI2C();
```

## Troubleshooting

### MPU6050 Tidak Terdeteksi

- ✅ Check koneksi I2C: SDA ke pin 21, SCL ke pin 22
- ✅ Check power: VCC ke 3.3V, GND ke GND
- ✅ Check I2C address: default 0x68 (jika AD0 = LOW)
- ✅ Gunakan I2C scanner untuk memverifikasi
- ✅ Pastikan tidak ada pull-up resistor conflict

### Pembacaan Tidak Akurat

- ✅ Pastikan sensor terpasang dengan orientasi yang benar
- ✅ Kalibrasi ulang dengan meletakkan di permukaan datar
- ✅ Hindari getaran saat membaca data
- ✅ Gunakan filter (sudah diimplementasi di kode)

### Koneksi WebSocket Terputus

- ✅ Pastikan update interval tidak terlalu cepat (100ms OK)
- ✅ Check buffer size untuk JSON (256 bytes cukup)
- ✅ Verify broadcast tidak mengirim ke client yang sudah disconnect

### Performa Lambat

- ✅ Reduce update rate jika perlu (200ms masih smooth)
- ✅ Optimize JSON serialization
- ✅ Gunakan RTOS tasks untuk sensor reading (opsional)

## Orientasi Sensor MPU6050

```
         MPU6050 Module
    ┌─────────────────────┐
    │                     │
    │    •••    •••       │  ← Component side (atas)
    │   [MPU]             │
    │                     │
    └─────────────────────┘

Mounting position:
- Component side menghadap KE ATAS
- X-axis: kiri-kanan (Roll)
- Y-axis: depan-belakang (Pitch)
- Z-axis: atas-bawah (vertikal)

Roll = 0°, Pitch = 0° → Teleskop datar
Roll > 0° → Miring ke kanan
Roll < 0° → Miring ke kiri
Pitch > 0° → Miring ke depan
Pitch < 0° → Miring ke belakang
```

## Wiring Diagram

```
ESP32              MPU6050
─────              ───────
3.3V    ────────── VCC
GND     ────────── GND
GPIO 21 ────────── SDA
GPIO 22 ────────── SCL
        (optional) INT → GPIO 19
```

## Referensi

- **Adafruit MPU6050 Library**: https://github.com/adafruit/Adafruit_MPU6050
- **MPU6050 Datasheet**: https://invensense.tdk.com/wp-content/uploads/2015/02/MPU-6000-Datasheet1.pdf
- **I2C Communication**: https://www.arduino.cc/en/Reference/Wire
- **Tutorial MPU6050**: https://learn.adafruit.com/mpu6050-6-dof-accelerometer-and-gyro

## Fitur Masa Depan (Opsional)

1. **Auto-Leveling**: Motor control untuk otomatis menyesuaikan level
2. **Gyroscope Integration**: Gunakan gyro untuk motion tracking
3. **Calibration Storage**: Simpan calibration offset di EEPROM
4. **Vibration Detection**: Alert saat deteksi getaran berlebih
5. **Temperature Compensation**: Koreksi drift sensor karena temperature
6. **Multi-point Level**: Display level di beberapa posisi tripod
7. **History Graph**: Grafik perubahan level dari waktu ke waktu
8. **Audio Feedback**: Beep saat sudah level
