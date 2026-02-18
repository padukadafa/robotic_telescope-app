const net = require("net");

const PORT = 10001;

// Konstanta
const TWO_POW_32 = 0x100000000;
const DEC_SCALE = 0x40000000;

// Konversi RA jam → uint32
function raToUint32(raHours) {
  return Math.floor((raHours / 24) * TWO_POW_32) >>> 0;
}

// Konversi DEC derajat → int32
function decToInt32(decDeg) {
  return Math.floor((decDeg / 90) * DEC_SCALE);
}

// Membuat pesan posisi teleskop
function createPositionMessage(raHours, decDeg) {
  const buffer = Buffer.alloc(24);

  const length = 24;
  const type = 0;
  const time = BigInt(Date.now()) * 1000n; // mikrodetik
  const ra = raToUint32(raHours);
  const dec = decToInt32(decDeg);
  const status = 0;

  buffer.writeUInt16LE(length, 0);
  buffer.writeUInt16LE(type, 2);
  buffer.writeBigUInt64LE(time, 4);
  buffer.writeUInt32LE(ra, 12);
  buffer.writeInt32LE(dec, 16);
  buffer.writeInt32LE(status, 20);

  return buffer;
}

// Buat server
const server = net.createServer((socket) => {
  console.log("Stellarium connected");

  let ra = 5.0; // mulai dari RA 5 jam
  const dec = 20.0; // DEC tetap 20°

  const interval = setInterval(() => {
    // gerakan objek perlahan
    ra += 0.01;
    if (ra >= 24) ra = 0;

    const msg = createPositionMessage(ra, dec);
    socket.write(msg);
  }, 1000);

  socket.on("data", (data) => {
    console.log("Received from Stellarium:", data);
  });

  socket.on("close", () => {
    console.log("Client disconnected");
    clearInterval(interval);
  });

  socket.on("error", (err) => {
    console.error("Socket error:", err);
    clearInterval(interval);
  });
});

server.listen(PORT, () => {
  console.log(`Stellarium telescope simulator running on port ${PORT}`);
});
