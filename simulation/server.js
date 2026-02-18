const WebSocket = require("ws");
const net = require("net");

const wss = new WebSocket.Server({
  port: 80,
  host: "0.0.0.0",
  path: "/ws",
});
console.log("=== Telescope Simulator WebSocket ===");
console.log("Running on ws://0.0.0.0:80");
console.log("Listening on all network interfaces");
console.log("To connect, use ws://192.168.4.1:80/ws or your computer's IP");
console.log("=====================================\n");

// Stellarium TCP Server (Stellarium connects to us, not we connect to Stellarium!)
let stellariumSocket = null;
let stellariumConnected = false;
const STELLARIUM_PORT = 10001;
const STELLARIUM_HOST = "0.0.0.0"; // Listen on all interfaces

console.log("💡 Starting Stellarium TCP Server...");

// Create TCP server for Stellarium to connect to
const stellariumServer = net.createServer((socket) => {
  console.log(
    `🌟 Stellarium connected from ${socket.remoteAddress}:${socket.remotePort}`,
  );

  stellariumSocket = socket;
  stellariumConnected = true;

  socket.on("close", () => {
    console.log("❌ Stellarium disconnected");
    stellariumConnected = false;
    stellariumSocket = null;
  });

  socket.on("error", (err) => {
    console.error(`⚠️  Stellarium socket error: ${err.message}`);
    stellariumConnected = false;
    stellariumSocket = null;
  });

  // Stellarium may send commands - handle them here if needed
  socket.on("data", (data) => {
    // Stellarium can send GOTO commands in some configurations
    console.log("📨 Received data from Stellarium:", data.length, "bytes");
  });
});

stellariumServer.listen(STELLARIUM_PORT, STELLARIUM_HOST, () => {
  console.log(
    `🚀 Stellarium TCP Server listening on ${STELLARIUM_HOST}:${STELLARIUM_PORT}`,
  );
  console.log("   Configure Stellarium to connect to this address");
  console.log("   In Stellarium: Configuration → Plugins → Telescope Control");
  console.log(
    `   Add Telescope → Type: External → Host: localhost → Port: ${STELLARIUM_PORT}\n`,
  );
});

stellariumServer.on("error", (err) => {
  console.error(`❌ Stellarium server error: ${err.message}`);
  if (err.code === "EADDRINUSE") {
    console.log(`   Port ${STELLARIUM_PORT} is already in use`);
    console.log("   Stop other telescope simulators or change the port");
  }
});

// Function to send position to Stellarium
function sendPositionToStellarium(ra, dec) {
  if (!stellariumConnected || !stellariumSocket) {
    return;
  }

  try {
    // Stellarium telescope protocol format
    // Total 24 bytes: length(2) + time(8) + RA(4) + DEC(4) + status(4)
    const buffer = Buffer.alloc(24);

    // Message length (24 bytes total)
    buffer.writeUInt16LE(24, 0);

    // Current time in microseconds since epoch
    const microtime = BigInt(Date.now()) * BigInt(1000);
    buffer.writeBigInt64LE(microtime, 2);

    // RA in radians * 2^32 / (2*PI) = radians * 2^31 / PI
    const raInt = Math.round((ra * Math.pow(2, 31)) / Math.PI);
    buffer.writeUInt32LE(raInt >>> 0, 10); // Use unsigned int

    // DEC in radians * 2^31 / PI
    const decInt = Math.round((dec * Math.pow(2, 31)) / Math.PI);
    buffer.writeInt32LE(decInt, 14);

    // Status (0 = ok)
    buffer.writeInt32LE(0, 18);

    stellariumSocket.write(buffer);
  } catch (err) {
    console.error(`❌ Error sending to Stellarium: ${err.message}`);
    stellariumConnected = false;
  }
}

// Function to convert Alt/Az to RA/Dec (simplified approximation)
function altAzToRaDec(azimuth, elevation, latitude = 0, longitude = 0) {
  // Convert to radians
  const az = (azimuth * Math.PI) / 180;
  const alt = (elevation * Math.PI) / 180;
  const lat = (latitude * Math.PI) / 180;

  // Local Sidereal Time (simplified - using current time)
  const now = new Date();
  const hours = now.getUTCHours() + now.getUTCMinutes() / 60;
  const lst = ((hours + longitude / 15) * 15 * Math.PI) / 180;

  // Convert Alt/Az to HA/Dec
  const sinDec =
    Math.sin(alt) * Math.sin(lat) +
    Math.cos(alt) * Math.cos(lat) * Math.cos(az);
  const dec = Math.asin(sinDec);

  const cosHA =
    (Math.sin(alt) - Math.sin(dec) * Math.sin(lat)) /
    (Math.cos(dec) * Math.cos(lat));
  let ha = Math.acos(Math.max(-1, Math.min(1, cosHA)));

  if (Math.sin(az) > 0) {
    ha = -ha;
  }

  // RA = LST - HA
  let ra = lst - ha;
  if (ra < 0) ra += 2 * Math.PI;
  if (ra >= 2 * Math.PI) ra -= 2 * Math.PI;

  return { ra, dec };
}

// Telescope state
let currentAzimuth = 0;
let currentElevation = 45;
let targetAzimuth = null;
let targetElevation = null;
let moving = false;
let speed = 1.0; // degrees per update
let manualSlewDirection = null;
let manualStep = 0.5;

// Continuous position updates to Stellarium (independent of Flutter connection)
setInterval(() => {
  if (stellariumConnected) {
    const { ra, dec } = altAzToRaDec(currentAzimuth, currentElevation);
    sendPositionToStellarium(ra, dec);
  }
}, 200); // Send position every 200ms to Stellarium

wss.on("connection", (ws) => {
  console.log("✅ Flutter app connected");

  // Send welcome message
  ws.send(
    JSON.stringify({
      type: "info",
      message: "Telescope Simulator Ready",
    }),
  );

  // Position update interval
  const interval = setInterval(() => {
    // If moving to target, interpolate position
    if (moving && targetAzimuth !== null && targetElevation !== null) {
      const azDiff = targetAzimuth - currentAzimuth;
      const elDiff = targetElevation - currentElevation;

      // Calculate shortest path for azimuth (handle 360° wrap)
      let azDelta = azDiff;
      if (azDelta > 0) {
        azDelta -= 360;
      }

      // Move towards target
      if (Math.abs(azDelta) > 0.5) {
        currentAzimuth +=
          Math.sign(azDelta) * Math.min(speed, Math.abs(azDelta));
        currentAzimuth = (currentAzimuth + 360) % 360;
      }

      if (Math.abs(elDiff) > 0.5) {
        currentElevation +=
          Math.sign(elDiff) * Math.min(speed, Math.abs(elDiff));
        currentElevation = Math.max(0, Math.min(90, currentElevation));
      }

      // Check if reached target
      if (Math.abs(azDelta) <= 0.5 && Math.abs(elDiff) <= 0.5) {
        moving = false;
        targetAzimuth = null;
        targetElevation = null;
        console.log(
          `✓ Reached target position: Az=${currentAzimuth.toFixed(
            2,
          )}° El=${currentElevation.toFixed(2)}°`,
        );
      }
    }

    // Continuous manual slewing while button is held
    if (manualSlewDirection) {
      switch (manualSlewDirection) {
        case "up":
          currentElevation = Math.min(90, currentElevation + manualStep);
          break;
        case "down":
          currentElevation = Math.max(0, currentElevation - manualStep);
          break;
        case "left":
          currentAzimuth = (currentAzimuth - manualStep + 360) % 360;
          break;
        case "right":
          currentAzimuth = (currentAzimuth + manualStep) % 360;
          break;
      }
    }

    // Send position update to Flutter
    ws.send(
      JSON.stringify({
        type: "position",
        azimuth: parseFloat(currentAzimuth.toFixed(2)),
        elevation: parseFloat(currentElevation.toFixed(2)),
        moving: moving,
      }),
    );
  }, 300); // Update every 300ms

  // Handle incoming commands from Flutter
  ws.on("message", (message) => {
    try {
      const data = JSON.parse(message);
      console.log(`📨 Received command:`, data.command || data.type);

      switch (data.command) {
        case "goto":
          targetAzimuth = data.azimuth;
          targetElevation = data.elevation;
          moving = true;
          console.log(
            `  → Moving to Az=${targetAzimuth}° El=${targetElevation}°`,
          );
          ws.send(
            JSON.stringify({
              type: "response",
              command: "goto",
              status: "moving",
              message: `Moving to Az=${targetAzimuth}° El=${targetElevation}°`,
            }),
          );
          break;

        case "slew": {
          const direction = data.direction;
          manualStep = ((data.steps || 10) * 360) / 1000 / 200 || 0.5;
          manualSlewDirection = direction;
          targetAzimuth = null;
          targetElevation = null;
          moving = true;
          console.log(
            `  → Continuous slewing ${direction} @ ${manualStep}°/tick`,
          );
          ws.send(
            JSON.stringify({
              type: "response",
              command: "slew",
              status: "moving",
              direction: direction,
              stepPerTick: manualStep,
            }),
          );
          break;
        }

        case "stop":
          moving = false;
          manualSlewDirection = null;
          targetAzimuth = null;
          targetElevation = null;
          console.log(`  → Emergency stop`);
          ws.send(
            JSON.stringify({
              type: "response",
              command: "stop",
              status: "stopped",
            }),
          );
          break;

        case "emergency_stop":
          moving = false;
          manualSlewDirection = null;
          targetAzimuth = null;
          targetElevation = null;
          console.log(`  → ⚠️  EMERGENCY STOP`);
          ws.send(
            JSON.stringify({
              type: "response",
              command: "emergency_stop",
              status: "stopped",
            }),
          );
          break;

        case "home":
          targetAzimuth = 0;
          targetElevation = 45;
          moving = true;
          manualSlewDirection = null;
          console.log(`  → Going home position`);
          ws.send(
            JSON.stringify({
              type: "response",
              command: "home",
              status: "moving",
            }),
          );
          break;

        case "calibrate":
          currentAzimuth = 0;
          currentElevation = 45;
          moving = false;
          manualSlewDirection = null;
          console.log(`  → Calibrated to home position`);
          ws.send(
            JSON.stringify({
              type: "response",
              command: "calibrate",
              status: "calibrated",
              message: "Telescope calibrated to home position",
            }),
          );
          break;

        case "set_speed":
          speed = data.rpm || 1.0;
          console.log(`  → Speed set to ${speed} deg/update`);
          ws.send(
            JSON.stringify({
              type: "response",
              command: "set_speed",
              status: "updated",
              speed: speed,
            }),
          );
          break;

        case "get_position":
          console.log(
            `  → Position query: Az=${currentAzimuth.toFixed(
              2,
            )}° El=${currentElevation.toFixed(2)}°`,
          );
          ws.send(
            JSON.stringify({
              type: "position",
              azimuth: parseFloat(currentAzimuth.toFixed(2)),
              elevation: parseFloat(currentElevation.toFixed(2)),
              moving: moving,
            }),
          );
          break;

        case "handshake":
          console.log(`  → Handshake from ${data.client}`);
          ws.send(
            JSON.stringify({
              type: "handshake_response",
              status: "connected",
              server: "telescope_simulator",
              version: "1.0.0",
              stellarium_connected: stellariumConnected,
            }),
          );
          break;

        case "stellarium_status":
          ws.send(
            JSON.stringify({
              type: "response",
              command: "stellarium_status",
              connected: stellariumConnected,
              server_listening: true,
              port: STELLARIUM_PORT,
              host: STELLARIUM_HOST,
              message: stellariumConnected
                ? "Stellarium is connected"
                : "Waiting for Stellarium to connect. Configure Stellarium Telescope Control to connect to localhost:10001",
            }),
          );
          break;

        default:
          console.log(`  → Unknown command: ${data.command}`);
          ws.send(
            JSON.stringify({
              type: "error",
              message: `Unknown command: ${data.command}`,
            }),
          );
      }
    } catch (e) {
      console.error(`❌ Error parsing message:`, e.message);
    }
  });

  ws.on("close", () => {
    clearInterval(interval);
    console.log("❌ Flutter app disconnected\n");
  });

  ws.on("error", (error) => {
    console.error("WebSocket error:", error.message);
  });
});
