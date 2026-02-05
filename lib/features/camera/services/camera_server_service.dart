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
    _serverIpAddress = await info.getWifiIP();

    if (_serverIpAddress == null) {
      _serverIpAddress = '0.0.0.0';
    }

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
    print(
      'Camera server listening on http://${_httpServer!.address.host}:${_httpServer!.port}',
    );
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    if (request.url.path == 'stream') {
      return shelf.Response.ok(
        'Camera streaming at http://$_serverIpAddress:$serverPort\n'
        'Note: MJPEG streaming requires native implementation',
        headers: {'Content-Type': 'text/plain'},
      );
    }

    return shelf.Response.ok('Camera Server - Use /stream endpoint');
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
