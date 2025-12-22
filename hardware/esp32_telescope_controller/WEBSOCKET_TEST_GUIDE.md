# ESP32 WebSocket Connection Guide

## 🔧 Troubleshooting Koneksi WebSocket

### 1. Upload Code ke ESP32

- Pastikan library sudah terinstall:
  - **WebSockets** by Markus Sattler (v2.3.6+)
  - **ArduinoJson** v6.x
- Upload code `simple_controller.ino`
- Buka Serial Monitor (115200 baud)
- Pastikan muncul pesan:
  ```
  === Simple Telescope Motor Controller ===
  ✓ WiFi AP started successfully
  AP IP address: 192.168.4.1
  ✓ WebSocket server started on port 81
  === READY ===
  ```

### 2. Connect ke WiFi ESP32

**Windows:**

1. Buka Settings → Network & Internet → WiFi
2. Pilih network: **RoboticTelescope**
3. Password: **telescope123**
4. Tunggu sampai connected

**MacOS:**

1. Klik WiFi icon di menu bar
2. Pilih: **RoboticTelescope**
3. Masukkan password: **telescope123**

**Android/iOS:**

1. Settings → WiFi
2. Connect ke: **RoboticTelescope**
3. Password: **telescope123**

### 3. Test Koneksi dengan Ping

Buka terminal/command prompt:

```bash
ping 192.168.4.1
```

Jika berhasil, akan muncul reply. Jika **Request timeout**, cek:

- ESP32 sudah booting sempurna? (tunggu 5 detik)
- Sudah connect ke WiFi ESP32?
- Firewall tidak memblokir?

### 4. Test dengan Postman

**PENTING:** Postman **tidak support WebSocket test** di versi lama. Gunakan Postman v9.0+

#### Setup WebSocket di Postman:

1. **Buat New Request**
   - Klik **New** → **WebSocket Request** (bukan HTTP!)
2. **Masukkan URL**

   ```
   ws://192.168.4.1:81
   ```

3. **Click Connect**

   - Jika berhasil: Status = **Connected** (hijau)
   - Jika gagal: Lihat troubleshooting di bawah

4. **Kirim Command**

   Tab **Message**, ketik JSON lalu **Send**:

   ```json
   { "command": "status" }
   ```

   ```json
   { "command": "goto", "azimuth": 90.0, "elevation": 45.0 }
   ```

   ```json
   { "command": "stop" }
   ```

#### Response yang Diharapkan:

Saat connect pertama:

```json
{
  "type": "connected",
  "message": "Telescope controller ready",
  "version": "1.0",
  "azimuth": 0.0,
  "elevation": 0.0
}
```

Setiap 100ms (auto update):

```json
{
  "type": "position",
  "azimuth": 90.5,
  "elevation": 45.2,
  "moving": true
}
```

### 5. Alternative: Test dengan Browser

Jika Postman tidak bisa, gunakan HTML test client:

**test_websocket.html:**

```html
<!DOCTYPE html>
<html>
  <head>
    <title>ESP32 WebSocket Test</title>
    <style>
      body {
        font-family: Arial;
        padding: 20px;
      }
      button {
        margin: 5px;
        padding: 10px;
        font-size: 14px;
      }
      #log {
        border: 1px solid #ccc;
        padding: 10px;
        height: 300px;
        overflow-y: scroll;
        background: #f5f5f5;
        font-family: monospace;
        font-size: 12px;
      }
      .connected {
        color: green;
        font-weight: bold;
      }
      .disconnected {
        color: red;
        font-weight: bold;
      }
      .status {
        padding: 10px;
        background: #e8f4f8;
        margin: 10px 0;
        border-radius: 5px;
      }
    </style>
  </head>
  <body>
    <h1>🔭 ESP32 Telescope WebSocket Test</h1>

    <div class="status">
      <strong>Status:</strong>
      <span id="status" class="disconnected">Not Connected</span><br />
      <strong>Position:</strong> <span id="position">Az: 0.0°, El: 0.0°</span>
    </div>

    <h3>Commands:</h3>
    <button onclick="sendCommand({command: 'status'})">📊 Get Status</button>
    <button onclick="sendCommand({command: 'calibrate'})">
      🎯 Calibrate (0,0)
    </button>
    <button onclick="sendCommand({command: 'stop'})">⛔ STOP</button>
    <br />
    <button onclick="sendGoto(45, 30)">→ GOTO (45°, 30°)</button>
    <button onclick="sendGoto(90, 45)">→ GOTO (90°, 45°)</button>
    <button onclick="sendGoto(180, 60)">→ GOTO (180°, 60°)</button>

    <h3>Custom Command:</h3>
    <input
      type="number"
      id="azInput"
      placeholder="Azimuth"
      value="0"
      style="width:100px;"
    />
    <input
      type="number"
      id="elInput"
      placeholder="Elevation"
      value="0"
      style="width:100px;"
    />
    <button onclick="sendCustomGoto()">📍 GO</button>

    <h3>Message Log:</h3>
    <div id="log"></div>

    <script>
      let ws;
      const WS_URL = "ws://192.168.4.1:81";

      function connect() {
        log("🔌 Connecting to " + WS_URL + "...", "info");

        ws = new WebSocket(WS_URL);

        ws.onopen = function () {
          log("✅ Connected successfully!", "success");
          document.getElementById("status").textContent = "Connected";
          document.getElementById("status").className = "connected";
        };

        ws.onmessage = function (event) {
          log("📨 Received: " + event.data, "receive");

          try {
            const data = JSON.parse(event.data);

            if (data.type === "position") {
              document.getElementById(
                "position"
              ).textContent = `Az: ${data.azimuth.toFixed(
                2
              )}°, El: ${data.elevation.toFixed(2)}° ${
                data.moving ? "(Moving...)" : ""
              }`;
            }
          } catch (e) {
            log("⚠️ Failed to parse JSON: " + e, "error");
          }
        };

        ws.onclose = function () {
          log("❌ Disconnected", "error");
          document.getElementById("status").textContent = "Disconnected";
          document.getElementById("status").className = "disconnected";

          log("🔄 Reconnecting in 3 seconds...", "info");
          setTimeout(connect, 3000);
        };

        ws.onerror = function (error) {
          log("❌ WebSocket Error: " + error, "error");
        };
      }

      function sendCommand(cmd) {
        if (ws && ws.readyState === WebSocket.OPEN) {
          const json = JSON.stringify(cmd);
          ws.send(json);
          log("📤 Sent: " + json, "send");
        } else {
          log("❌ Not connected! Cannot send command.", "error");
        }
      }

      function sendGoto(az, el) {
        sendCommand({
          command: "goto",
          azimuth: parseFloat(az),
          elevation: parseFloat(el),
        });
      }

      function sendCustomGoto() {
        const az = parseFloat(document.getElementById("azInput").value);
        const el = parseFloat(document.getElementById("elInput").value);
        sendGoto(az, el);
      }

      function log(message, type) {
        const logDiv = document.getElementById("log");
        const time = new Date().toLocaleTimeString();
        const color =
          {
            info: "#666",
            success: "green",
            error: "red",
            send: "blue",
            receive: "purple",
          }[type] || "black";

        logDiv.innerHTML += `<div style="color:${color}">[${time}] ${message}</div>`;
        logDiv.scrollTop = logDiv.scrollHeight;
      }

      // Auto connect on load
      window.onload = connect;
    </script>
  </body>
</html>
```

**Cara Pakai:**

1. Save file di atas sebagai `test_websocket.html`
2. Connect ke WiFi ESP32
3. Buka file dengan browser
4. Otomatis connect ke ESP32

### 6. Common Issues & Solutions

#### ❌ "Connection Timeout" atau "Failed to connect"

**Solusi:**

1. **Cek WiFi Connection**

   ```bash
   # Windows
   netsh wlan show interfaces

   # Mac/Linux
   ifconfig | grep -A 10 "wlan0"
   ```

   Pastikan connected ke `RoboticTelescope`

2. **Ping Test**

   ```bash
   ping 192.168.4.1
   ```

   Harus dapat reply

3. **Restart ESP32**

   - Tekan tombol RESET di ESP32
   - Tunggu 5 detik
   - Coba lagi

4. **Firewall**
   - Windows: Matikan Windows Firewall sementara
   - Mac: System Preferences → Security → Firewall → Turn Off

#### ❌ "WebSocket not supported" di Postman

**Solusi:**

- Update Postman ke versi terbaru (v9.0+)
- Atau gunakan browser test (test_websocket.html)

#### ❌ Serial Monitor menunjukkan "AP failed"

**Solusi:**

```cpp
// Coba ubah channel WiFi di code:
WiFi.softAP(ssid, password, 6, 0, 4);  // Channel 6
```

### 7. Test dengan curl (Linux/Mac)

```bash
# Install wscat
npm install -g wscat

# Connect
wscat -c ws://192.168.4.1:81

# Kirim command
> {"command":"status"}
> {"command":"goto","azimuth":90,"elevation":45}
> {"command":"stop"}
```

### 8. Monitor Serial Output

Saat testing, buka Serial Monitor untuk melihat:

- ✓ Client connected
- 📩 Command received
- 📤 Response sent
- ⚙️ Motor status

Contoh output yang benar:

```
=== READY ===
✓ [Client 0] Connected from 192.168.4.2
   Sent welcome: {"type":"connected",...}
📩 [Client 0] Received: {"command":"goto","azimuth":90,"elevation":45}
⚙️  Processing command: goto
```

## ✅ Checklist Troubleshooting

- [ ] ESP32 uploaded dan running (cek Serial Monitor)
- [ ] WiFi connected ke "RoboticTelescope"
- [ ] Ping 192.168.4.1 berhasil
- [ ] Postman/Browser sudah connect (status: Connected)
- [ ] JSON format benar (gunakan validator)
- [ ] Serial Monitor menunjukkan "Client connected"

Jika semua checklist ✅, WebSocket pasti bisa konek! 🚀
