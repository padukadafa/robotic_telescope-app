import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

class CameraServerService {
  CameraController? _cameraController;
  HttpServer? _httpServer;
  String? _serverIpAddress;
  final int serverPort;
  bool _isCameraInitialized = false;

  CameraServerService({this.serverPort = 8080});

  bool get isCameraInitialized => _isCameraInitialized;
  String? get serverIpAddress => _serverIpAddress;
  CameraController? get cameraController => _cameraController;

  Future<void> startServer() async {
    // Get available cameras
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception('No cameras available');
    }

    // Initialize camera controller
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    _isCameraInitialized = true;

    // Get device IP address
    final info = NetworkInfo();
    _serverIpAddress = await info.getWifiIP() ?? 'localhost';

    print('Device IP: $_serverIpAddress');

    // Start HTTP server
    await _startHttpServer();
  }

  Future<void> _startHttpServer() async {
    final handler = const shelf.Pipeline()
        .addMiddleware(shelf.logRequests())
        .addHandler(_handleRequest);

    _httpServer = await shelf_io.serve(
      handler,
      InternetAddress.anyIPv4,
      serverPort,
    );
    print('Camera streaming at http://$_serverIpAddress:${_httpServer!.port}');
    print('Stream URL: http://$_serverIpAddress:${_httpServer!.port}/stream');
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    // Root endpoint - info
    if (request.url.path == '' || request.url.path == '/') {
      return shelf.Response.ok(
        'Camera Server Running\n'
        'Access MJPEG stream at: http://$_serverIpAddress:$serverPort/stream\n'
        'Status: ${_isCameraInitialized ? "Camera Ready" : "Camera Initializing"}',
        headers: {'Content-Type': 'text/plain'},
      );
    }

    // Stream endpoint - MJPEG stream
    if (request.url.path == 'stream') {
      if (!_isCameraInitialized || _cameraController == null) {
        return shelf.Response.internalServerError(
          body: 'Camera not initialized',
        );
      }

      final controller = StreamController<List<int>>();

      // Start streaming images
      _streamMJPEG(controller);

      return shelf.Response.ok(
        controller.stream,
        headers: {
          'Content-Type': 'multipart/x-mixed-replace; boundary=frame',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      );
    }

    return shelf.Response.notFound(
      'Endpoint not found. Use /stream for MJPEG stream',
    );
  }

  Future<void> _streamMJPEG(StreamController<List<int>> controller) async {
    try {
      // Stream frames continuously
      while (!controller.isClosed && _isCameraInitialized) {
        try {
          final image = await _cameraController!.takePicture();
          final bytes = await image.readAsBytes();

          // Send MJPEG frame
          final frame = [
            ...('--frame\r\n').codeUnits,
            ...('Content-Type: image/jpeg\r\n').codeUnits,
            ...('Content-Length: ${bytes.length}\r\n\r\n').codeUnits,
            ...bytes,
            ...('\r\n').codeUnits,
          ];

          controller.add(frame);

          // Control frame rate (adjust as needed)
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          print('Error capturing frame: $e');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    } catch (e) {
      print('Stream error: $e');
    } finally {
      controller.close();
    }
  }

  Future<void> stopServer() async {
    await _httpServer?.close(force: true);
    _httpServer = null;

    await _cameraController?.dispose();
    _cameraController = null;

    _isCameraInitialized = false;
  }

  void dispose() {
    stopServer();
  }
}
