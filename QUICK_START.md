# 🔭 Quick Start Guide - Telescope Simulator

## ✅ Setup Lengkap!

Simulator telescope sudah siap digunakan untuk development. Ada **2 mode** yang bisa digunakan:

---

## 🚀 Mode 1: Dummy Mode (Recommended untuk Quick Testing)

**Langkah:**

1. Jalankan aplikasi Flutter
2. Di layar **Connection**, klik tombol **"Start Dummy"**
3. Aplikasi langsung terhubung ke simulator lokal
4. Langsung bisa test semua fitur!

**Keuntungan:**

- ⚡ Instant, tidak perlu setup apapun
- 🔄 Tidak butuh koneksi jaringan
- 📱 Bisa di emulator atau device
- 🎯 Perfect untuk UI testing

---

## 🌐 Mode 2: WebSocket Server (Untuk Testing yang Lebih Realistis)

**Server sudah running di:** `ws://0.0.0.0:81` ✅

### Cara Koneksi dari Flutter App:

#### Option A: Dari Device Fisik

1. Cari IP komputer Anda:
   ```bash
   ifconfig | grep "inet " | grep -v 127.0.0.1
   ```
2. Update kode untuk testing (temporary):

   ```dart
   // Di telescope_provider.dart atau connection_provider.dart
   await connectToTelescope('192.168.1.xxx'); // IP komputer Anda
   ```

3. Jalankan app di device, lihat log di terminal server

#### Option B: Dari Emulator/Localhost

```dart
await connectToTelescope('localhost'); // atau '127.0.0.1'
```

---

## 📋 Fitur Yang Tersedia

### ✅ Movement Commands

- **Go To** - Move ke koordinat target
- **Slew** - Manual control (↑↓←→)
- **Stop** - Stop pergerakan
- **Home** - Kembali ke home position
- **Calibrate** - Reset posisi

### ✅ Real-time Updates

- Position streaming (azimuth, elevation)
- Movement status
- Smooth interpolation

### ✅ Advanced Features

- Speed control
- Fine-tuning mode
- 360° azimuth handling
- Elevation limits (0°-90°)

---

## 🎯 Testing Workflow

### Test 1: Basic Connection

1. ✅ Start Dummy Mode
2. ✅ Check status "Connected to dummy telescope"
3. ✅ Lihat position updates di monitoring

### Test 2: Object Selection

1. ✅ Pilih object (e.g., Mars)
2. ✅ Klik "Go to Target"
3. ✅ Watch telescope bergerak smooth

### Test 3: Manual Control

1. ✅ Gunakan arrow buttons
2. ✅ Test slew up/down/left/right
3. ✅ Test fine-tuning

### Test 4: Emergency Stop

1. ✅ Start movement
2. ✅ Klik emergency stop
3. ✅ Verify langsung berhenti

---

## 🐛 Troubleshooting

### Server tidak jalan?

```bash
# Check port 81
lsof -i :81

# Kill jika ada process lain
kill -9 <PID>

# Restart server
cd simulation
node server.js
```

### Dummy mode tidak konek?

- Hot restart aplikasi Flutter
- Check apakah TelescopeProvider sudah initialized
- Pastikan klik "Start Dummy" button

---

## 📝 Command Log Example

Ketika Anda menggunakan server mode, log akan muncul seperti ini:

```
✅ Flutter app connected
📨 Received command: goto
  → Moving to Az=180° El=45°
✓ Reached target position: Az=180.00° El=45.00°
📨 Received command: slew
  → Slewed up by 10°
📨 Received command: stop
  → Emergency stop
❌ Flutter app disconnected
```

---

## 🔧 Development Notes

### Current Implementation:

- ✅ TelescopeDummyService - Local simulator
- ✅ WebSocket Server - Network simulator
- ✅ TelescopeProvider - Supports both modes
- ✅ ConnectionProvider - Dummy mode integration
- ✅ UI Button - One-click dummy mode

### File Locations:

```
lib/core/services/telescope_dummy_service.dart    # Dummy mode
lib/core/providers/telescope_provider.dart        # Main provider
lib/core/providers/connection_provider.dart       # Connection logic
simulation/server.js                               # WebSocket server
```

---

## 🎉 Ready to Test!

Server sudah running ✅  
Dummy mode ready ✅  
Documentation lengkap ✅

**Sekarang tinggal:**

1. Run Flutter app
2. Klik "Start Dummy"
3. Enjoy testing! 🚀

---

**Tips:** Untuk production nanti, tinggal ganti dengan IP ESP32 yang real. Interface-nya sudah sama! 🔭
