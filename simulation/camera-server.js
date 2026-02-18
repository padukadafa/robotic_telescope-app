const express = require("express");
const { spawn } = require("child_process");

const app = express();

app.get("/", (req, res) => {
  res.send('<img src="/stream">');
});

app.get("/stream", (req, res) => {
  const ffmpeg = spawn("ffmpeg", [
    "-f",
    "avfoundation",
    "-video_size",
    "1920x1080",
    "-framerate",
    "60",
    "-i",
    "0", // OBS camera

    "-vf",
    "scale=640:320", // resize di sini

    "-f",
    "mpjpeg",
    "-q:v",
    "5",
    "-",
  ]);

  res.writeHead(200, {
    "Content-Type": "multipart/x-mixed-replace; boundary=ffmpeg",
  });

  ffmpeg.stdout.pipe(res);

  ffmpeg.stderr.on("data", (data) => {
    console.log(data.toString());
  });

  req.on("close", () => {
    ffmpeg.kill("SIGKILL");
  });
});

app.listen(3000, "0.0.0.0", () => {
  console.log("http://localhost:3000");
});
