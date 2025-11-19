const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 81 });
console.log("=== Telescope Simulator WebSocket ===");
console.log("Running on ws://0.0.0.0:81");
console.log("Listening on all network interfaces");
console.log("Connect from Flutter app using your computer's IP address");
console.log("=====================================\n");

wss.on('connection', (ws) => {
  console.log("✅ Flutter app connected");

  // Telescope state
  let currentAzimuth = 0;
  let currentElevation = 45;
  let targetAzimuth = null;
  let targetElevation = null;
  let moving = false;
  let speed = 1.0; // degrees per update

  // Send welcome message
  ws.send(JSON.stringify({
    type: "info",
    message: "Telescope Simulator Ready"
  }));

  // Position update interval
  const interval = setInterval(() => {
    // If moving to target, interpolate position
    if (moving && targetAzimuth !== null && targetElevation !== null) {
      const azDiff = targetAzimuth - currentAzimuth;
      const elDiff = targetElevation - currentElevation;
      
      // Calculate shortest path for azimuth (handle 360° wrap)
      let azDelta = azDiff;
      if (Math.abs(azDiff) > 180) {
        azDelta = azDiff > 0 ? azDiff - 360 : azDiff + 360;
      }

      // Move towards target
      if (Math.abs(azDelta) > 0.5) {
        currentAzimuth += Math.sign(azDelta) * Math.min(speed, Math.abs(azDelta));
        currentAzimuth = (currentAzimuth + 360) % 360;
      }
      
      if (Math.abs(elDiff) > 0.5) {
        currentElevation += Math.sign(elDiff) * Math.min(speed, Math.abs(elDiff));
        currentElevation = Math.max(0, Math.min(90, currentElevation));
      }

      // Check if reached target
      if (Math.abs(azDelta) <= 0.5 && Math.abs(elDiff) <= 0.5) {
        moving = false;
        targetAzimuth = null;
        targetElevation = null;
        console.log(`✓ Reached target position: Az=${currentAzimuth.toFixed(2)}° El=${currentElevation.toFixed(2)}°`);
      }
    }

    // Send position update to Flutter
    ws.send(JSON.stringify({
      type: "position",
      azimuth: parseFloat(currentAzimuth.toFixed(2)),
      elevation: parseFloat(currentElevation.toFixed(2)),
      moving: moving
    }));

  }, 100); // Update every 100ms

  // Handle incoming commands from Flutter
  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      console.log(`📨 Received command:`, data.command || data.type);

      switch (data.command) {
        case 'goto':
          targetAzimuth = data.azimuth;
          targetElevation = data.elevation;
          moving = true;
          console.log(`  → Moving to Az=${targetAzimuth}° El=${targetElevation}°`);
          ws.send(JSON.stringify({
            type: "response",
            command: "goto",
            status: "moving",
            message: `Moving to Az=${targetAzimuth}° El=${targetElevation}°`
          }));
          break;

        case 'slew':
          const stepSize = data.steps || 10;
          const direction = data.direction;
          std
          switch (direction) {
            case 'up':
              currentElevation = Math.min(90, currentElevation + stepSize);
              break;
            case 'down':
              currentElevation = Math.max(0, currentElevation - stepSize);
              break;
            case 'left':
              currentAzimuth = (currentAzimuth - stepSize + 360) % 360;
              break;
            case 'right':
              currentAzimuth = (currentAzimuth + stepSize) % 360;
              break;
          }
          console.log(`  → Slewed ${direction} by ${stepSize}°`);
          ws.send(JSON.stringify({
            type: "response",
            command: "slew",
            status: "completed",
            direction: direction,
            steps: stepSize
          }));
          break;

        case 'stop':
          moving = false;
          targetAzimuth = null;
          targetElevation = null;
          console.log(`  → Emergency stop`);
          ws.send(JSON.stringify({
            type: "response",
            command: "stop",
            status: "stopped"
          }));
          break;

        case 'emergency_stop':
          moving = false;
          targetAzimuth = null;
          targetElevation = null;
          console.log(`  → ⚠️  EMERGENCY STOP`);
          ws.send(JSON.stringify({
            type: "response",
            command: "emergency_stop",
            status: "stopped"
          }));
          break;

        case 'home':
          targetAzimuth = 0;
          targetElevation = 45;
          moving = true;
          console.log(`  → Going home position`);
          ws.send(JSON.stringify({
            type: "response",
            command: "home",
            status: "moving"
          }));
          break;

        case 'calibrate':
          currentAzimuth = 0;
          currentElevation = 45;
          moving = false;
          console.log(`  → Calibrated to home position`);
          ws.send(JSON.stringify({
            type: "response",
            command: "calibrate",
            status: "calibrated",
            message: "Telescope calibrated to home position"
          }));
          break;

        case 'set_speed':
          speed = data.rpm || 1.0;
          console.log(`  → Speed set to ${speed} deg/update`);
          ws.send(JSON.stringify({
            type: "response",
            command: "set_speed",
            status: "updated",
            speed: speed
          }));
          break;

        case 'get_position':
          console.log(`  → Position query: Az=${currentAzimuth.toFixed(2)}° El=${currentElevation.toFixed(2)}°`);
          ws.send(JSON.stringify({
            type: "position",
            azimuth: parseFloat(currentAzimuth.toFixed(2)),
            elevation: parseFloat(currentElevation.toFixed(2)),
            moving: moving
          }));
          break;

        case 'handshake':
          console.log(`  → Handshake from ${data.client}`);
          ws.send(JSON.stringify({
            type: "handshake_response",
            status: "connected",
            server: "telescope_simulator",
            version: "1.0.0"
          }));
          break;

        default:
          console.log(`  → Unknown command: ${data.command}`);
          ws.send(JSON.stringify({
            type: "error",
            message: `Unknown command: ${data.command}`
          }));
      }
    } catch (e) {
      console.error(`❌ Error parsing message:`, e.message);
    }
  });

  ws.on('close', () => {
    clearInterval(interval);
    console.log("❌ Flutter app disconnected\n");
  });

  ws.on('error', (error) => {
    console.error('WebSocket error:', error.message);
  });
});
