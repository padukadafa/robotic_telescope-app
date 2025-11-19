# Telescope Simulator - Development Guide

## Overview

Simulator ini memungkinkan Anda untuk testing aplikasi robotic telescope tanpa perlu hardware fisik. Ada 2 mode simulator yang tersedia:

## 1. Dummy Mode (Lokal - Tanpa Server)

Mode ini menjalankan simulator langsung di aplikasi Flutter tanpa perlu koneksi jaringan.

### Cara Menggunakan:

1. Jalankan aplikasi Flutter
2. Di layar Connection, klik tombol **"Start Dummy"** di bagian "Development Mode"
3. Aplikasi akan langsung terhubung ke simulator lokal
4. Semua fitur telescope (move, slew, calibrate, dll) akan berfungsi dengan simulasi

### Keuntungan Dummy Mode:

- ✅ Tidak perlu koneksi jaringan
- ✅ Sangat cepat untuk testing
- ✅ Ideal untuk UI development
- ✅ Bisa dijalankan di emulator tanpa konfigurasi tambahan

---

## 2. WebSocket Simulator (Server Mode)

Mode ini menjalankan server WebSocket yang mensimulasikan perilaku ESP32 telescope controller.

### Cara Menggunakan:

#### Setup (Pertama Kali):

```bash
cd simulation
npm install
```

#### Jalankan Server:

```bash
cd simulation
node server.js
```

Server akan berjalan di `ws://0.0.0.0:81` dan menampilkan:

```
=== Telescope Simulator WebSocket ===
Running on ws://0.0.0.0:81
Listening on all network interfaces
Connect from Flutter app using your computer's IP address
=====================================
```

#### Konfigurasi di Aplikasi:

1. Cari IP address komputer Anda:
   - macOS/Linux: `ifconfig | grep inet`
   - Windows: `ipconfig`
2. Update connection provider atau hardcode IP untuk testing:

   ```dart
   // Di connection_provider.dart atau telescope_provider.dart
   await connectToTelescope('192.168.1.xxx'); // Ganti dengan IP komputer Anda
   ```

3. Atau tambahkan field input IP di UI untuk lebih fleksibel

### Keuntungan Server Mode:

- ✅ Simulasi yang lebih realistis (dengan network latency)
- ✅ Bisa testing dari device fisik
- ✅ Log command real-time di console
- ✅ Cocok untuk testing WebSocket communication

---

## Fitur Yang Tersimulasi

Kedua mode simulator mendukung semua command telescope:

### Movement Commands:

- ✅ `goto` - Move ke posisi target (azimuth, elevation)
- ✅ `slew` - Manual control (up, down, left, right)
- ✅ `stop` - Stop pergerakan
- ✅ `home` - Kembali ke home position (0°, 45°)
- ✅ `calibrate` - Reset ke home position

### Status Updates:

- ✅ Position updates (azimuth, elevation)
- ✅ Movement status (moving/stopped)
- ✅ Real-time position streaming

### Advanced:

- ✅ Speed control
- ✅ Smooth interpolation ke target position
- ✅ 360° azimuth wrap-around handling
- ✅ Elevation limits (0° - 90°)

---

## Testing Scenarios

### Skenario 1: Basic Movement

1. Connect ke dummy atau simulator
2. Pilih object di Object Selection
3. Klik "Go to Target"
4. Lihat telescope bergerak smooth ke target

### Skenario 2: Manual Control

1. Connect ke dummy atau simulator
2. Di Telescope Control, gunakan arrow buttons
3. Test slew up/down/left/right
4. Test fine-tuning mode

### Skenario 3: Emergency Stop

1. Start movement ke target jauh
2. Klik emergency stop
3. Verify telescope langsung berhenti

---

## Development Tips

### Dummy Mode:

```dart
// Connect ke dummy mode
final telescopeProvider = context.read<TelescopeProvider>();
await telescopeProvider.connectToDummy();
```

### Server Mode:

```dart
// Connect ke WebSocket simulator
final telescopeProvider = context.read<TelescopeProvider>();
await telescopeProvider.connectToTelescope('192.168.1.xxx');
```

### Check Mode:

```dart
if (telescopeProvider.isDummyMode) {
  print('Running in dummy mode');
} else {
  print('Connected to real/simulated telescope');
}
```

---

## Troubleshooting

### Server Mode tidak konek:

1. **Check firewall** - Pastikan port 81 tidak diblock
2. **Check IP** - Pastikan IP address benar
3. **Check network** - Device dan komputer harus di network yang sama
4. **Restart server** - Ctrl+C lalu jalankan ulang `node server.js`

### Dummy Mode tidak jalan:

1. **Check provider** - Pastikan TelescopeProvider sudah di-initialize
2. **Check connection** - Pastikan klik "Start Dummy" di Connection screen
3. **Hot restart** - Coba hot restart aplikasi Flutter

---

## Next Steps

### Untuk Production:

- [ ] Ganti dummy mode dengan real ESP32 connection
- [ ] Tambah input IP address di UI
- [ ] Tambah auto-discovery untuk ESP32 di network lokal
- [ ] Tambah error handling yang lebih baik
- [ ] Tambah connection timeout & retry logic

### Untuk Development:

- [ ] Tambah more realistic simulation (acceleration, deceleration)
- [ ] Tambah sensor simulation (temperature, GPS, compass)
- [ ] Tambah obstacle detection simulation
- [ ] Tambah weather condition simulation

---

## Commands Reference

### WebSocket Message Format:

**Command Request:**

```json
{
  "command": "goto",
  "azimuth": 180.0,
  "elevation": 45.0,
  "timestamp": 1234567890
}
```

**Position Update:**

```json
{
  "type": "position",
  "azimuth": 180.0,
  "elevation": 45.0,
  "moving": true
}
```

**Command Response:**

```json
{
  "type": "response",
  "command": "goto",
  "status": "moving",
  "message": "Moving to Az=180° El=45°"
}
```

---

## Contact & Support

Jika ada pertanyaan atau bug, silakan buat issue di repository atau contact maintainer.

Happy Testing! 🔭✨
