import 'dart:async';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img_lib;
import 'package:robotic_telescope/core/services/astronomical_calculator.dart';
import 'package:robotic_telescope/core/services/brightness_detector.dart';
import 'package:robotic_telescope/core/services/hybrid_classifier.dart';
import 'package:robotic_telescope/core/models/astronomical_detection_result.dart';

/// Input data for detection isolate
class _DetectionIsolateInput {
  final int width;
  final int height;
  final Uint8List rgbBytes;
  final double telescopeAltitude;
  final double telescopeAzimuth;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final SendPort sendPort;

  _DetectionIsolateInput({
    required this.width,
    required this.height,
    required this.rgbBytes,
    required this.telescopeAltitude,
    required this.telescopeAzimuth,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.sendPort,
  });
}

/// Main service for hybrid astronomical detection
class AstronomicalDetectionService {
  bool _isRunning = false;
  bool _isProcessing = false;
  int _frameCount = 0;
  int _detectionCount = 0;

  // IP Camera support
  http.Client? _httpClient;
  StreamSubscription? _mjpegSubscription;
  String? _cameraUrl;

  // Telescope position (should be updated externally)
  double _currentTelescopeAltitude = 0.0;
  double _currentTelescopeAzimuth = 0.0;

  // Performance metrics
  double _averageFps = 0.0;
  final List<double> _fpsHistory = [];
  static const int _fpsHistorySize = 30;

  // Callbacks
  Function(List<AstronomicalDetectionResult>)? onDetectionResult;
  Function(String)? onError;
  Function(double)? onFpsUpdate;
  Function(String)? onSunWarning;

  bool get isRunning => _isRunning;
  double get averageFps => _averageFps;
  int get frameCount => _frameCount;
  int get detectionCount => _detectionCount;

  /// Update telescope position (call this when telescope moves)
  void updateTelescopePosition({
    required double altitude,
    required double azimuth,
  }) {
    _currentTelescopeAltitude = altitude;
    _currentTelescopeAzimuth = azimuth;
  }

  /// Start astronomical detection from camera stream
  Future<void> startDetection(
    CameraController cameraController, {
    required double latitude,
    required double longitude,
  }) async {
    if (_isRunning) {
      print('⚠️ Detection already running');
      return;
    }

    _isRunning = true;
    _frameCount = 0;
    _detectionCount = 0;
    print('🔭 Starting astronomical detection...');
    print('   Location: ($latitude, $longitude)');

    try {
      await cameraController.startImageStream((CameraImage image) async {
        if (!_isRunning) return;

        // Skip if already processing (throttling)
        if (_isProcessing) return;

        _processFrame(image, latitude: latitude, longitude: longitude);
      });
    } catch (e) {
      print('❌ Error starting image stream: $e');
      _isRunning = false;
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Stop astronomical detection
  Future<void> stopDetection(CameraController cameraController) async {
    if (!_isRunning) return;

    _isRunning = false;
    _isProcessing = false;

    try {
      await cameraController.stopImageStream();
      print('🛑 Astronomical detection stopped');
      print('   Total frames: $_frameCount');
      print('   Total detections: $_detectionCount');
      print('   Average FPS: ${_averageFps.toStringAsFixed(1)}');
    } catch (e) {
      print('⚠️ Error stopping image stream: $e');
    }
  }

  /// Start astronomical detection from IP camera (MJPEG stream)
  Future<void> startDetectionFromIPCamera(
    String cameraUrl, {
    required double latitude,
    required double longitude,
  }) async {
    if (_isRunning) {
      print('⚠️ Detection already running');
      return;
    }

    _isRunning = true;
    _frameCount = 0;
    _detectionCount = 0;
    _cameraUrl = cameraUrl;
    print('🔭 Starting astronomical detection from IP camera...');
    print('   Camera URL: $cameraUrl');
    print('   Location: ($latitude, $longitude)');

    try {
      final stream = _getMjpegStream(cameraUrl);
      _mjpegSubscription = stream.listen(
        (jpegBytes) {
          if (!_isRunning) return;
          if (_isProcessing) return;

          _processJpegFrame(
            jpegBytes,
            latitude: latitude,
            longitude: longitude,
          );
        },
        onError: (error) {
          print('❌ Error in MJPEG stream: $error');
          onError?.call(error.toString());
        },
        cancelOnError: false,
      );
    } catch (e) {
      print('❌ Error starting IP camera stream: $e');
      _isRunning = false;
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Stop IP camera detection
  Future<void> stopIPCameraDetection() async {
    if (!_isRunning) return;

    _isRunning = false;
    _isProcessing = false;

    await _mjpegSubscription?.cancel();
    _mjpegSubscription = null;

    _httpClient?.close();
    _httpClient = null;

    print('🛑 IP camera detection stopped');
    print('   Total frames: $_frameCount');
    print('   Total detections: $_detectionCount');
    print('   Average FPS: ${_averageFps.toStringAsFixed(1)}');
  }

  /// Get MJPEG stream from IP camera
  Stream<Uint8List> _getMjpegStream(String url) async* {
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient!
          .send(request)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Failed to connect: ${response.statusCode}');
      }

      print('✅ Connected to IP camera stream');

      final List<int> buffer = [];
      const jpegStart = [0xFF, 0xD8]; // JPEG start marker
      const jpegEnd = [0xFF, 0xD9]; // JPEG end marker

      await for (var chunk in response.stream) {
        if (!_isRunning) break;

        buffer.addAll(chunk);

        // Parse JPEG frames from buffer
        while (true) {
          // Find JPEG start
          int startIndex = -1;
          for (int i = 0; i < buffer.length - 1; i++) {
            if (buffer[i] == jpegStart[0] && buffer[i + 1] == jpegStart[1]) {
              startIndex = i;
              break;
            }
          }

          if (startIndex == -1) {
            if (buffer.length > 1) {
              buffer.removeRange(0, buffer.length - 1);
            }
            break;
          }

          // Find JPEG end
          int endIndex = -1;
          for (int i = startIndex + 2; i < buffer.length - 1; i++) {
            if (buffer[i] == jpegEnd[0] && buffer[i + 1] == jpegEnd[1]) {
              endIndex = i + 1;
              break;
            }
          }

          if (endIndex == -1) {
            if (startIndex > 0) {
              buffer.removeRange(0, startIndex);
            }
            break;
          }

          // Extract JPEG frame
          final frame = Uint8List.fromList(
            buffer.sublist(startIndex, endIndex + 1),
          );
          yield frame;

          // Remove processed frame
          buffer.removeRange(0, endIndex + 1);
        }
      }
    } catch (e) {
      print('❌ MJPEG stream error: $e');
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Process JPEG frame from IP camera
  Future<void> _processJpegFrame(
    Uint8List jpegBytes, {
    required double latitude,
    required double longitude,
  }) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _frameCount++;

    final startTime = DateTime.now();

    try {
      // Decode JPEG to image
      final image = img_lib.decodeImage(jpegBytes);
      if (image == null) {
        throw Exception('Failed to decode JPEG frame');
      }

      final width = image.width;
      final height = image.height;

      // Convert to RGB bytes
      final rgbBytes = Uint8List(width * height * 3);
      int pixelIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final pixel = image.getPixel(x, y);
          rgbBytes[pixelIndex++] = pixel.r.toInt();
          rgbBytes[pixelIndex++] = pixel.g.toInt();
          rgbBytes[pixelIndex++] = pixel.b.toInt();
        }
      }

      // Get telescope position
      final telescopeAltitude = _currentTelescopeAltitude;
      final telescopeAzimuth = _currentTelescopeAzimuth;

      // Process in isolate
      final dynamic result = await _detectInIsolate(
        width: width,
        height: height,
        rgbBytes: rgbBytes,
        telescopeAltitude: telescopeAltitude,
        telescopeAzimuth: telescopeAzimuth,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      );

      // Update metrics
      final processingTime = DateTime.now().difference(startTime);
      final fps = 1000.0 / processingTime.inMilliseconds;
      _updateFps(fps);

      // Handle results (same as before)
      if (result == null || result is NoDetectionResult) {
        onDetectionResult?.call([]);
      } else if (result is List) {
        final results = <AstronomicalDetectionResult>[];
        for (dynamic item in result) {
          if (item is AstronomicalDetectionResult) {
            results.add(item);
          }
        }

        if (results.isNotEmpty) {
          _detectionCount++;
          onDetectionResult?.call(results);

          final hasSun = results.any((r) => r.isSun);
          if (hasSun) {
            onSunWarning?.call(
              '⚠️ SUN DETECTED! Verify solar filter is in place.',
            );
          }
        } else {
          onDetectionResult?.call([]);
        }
      } else if (result is AstronomicalDetectionResult) {
        _detectionCount++;
        onDetectionResult?.call([result]);

        if (result.isSun) {
          onSunWarning?.call(
            '⚠️ SUN DETECTED! Verify solar filter is in place.',
          );
        }
      }
    } catch (e) {
      print('❌ Error processing JPEG frame: $e');
      onError?.call(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  /// Process a single camera frame
  Future<void> _processFrame(
    CameraImage image, {
    required double latitude,
    required double longitude,
  }) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _frameCount++;

    final startTime = DateTime.now();

    try {
      // Get telescope position from external source (should be passed in)
      // For now, using placeholders - should be updated via updateTelescopePosition()
      final telescopeAltitude = _currentTelescopeAltitude;
      final telescopeAzimuth = _currentTelescopeAzimuth;

      // Convert CameraImage to RGB bytes
      final imageData = await _convertCameraImageToRGB(image);

      // Process in isolate for better performance
      final dynamic result = await _detectInIsolate(
        width: imageData['width'] as int,
        height: imageData['height'] as int,
        rgbBytes: imageData['bytes'] as Uint8List,
        telescopeAltitude: telescopeAltitude,
        telescopeAzimuth: telescopeAzimuth,
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
      );

      // Update metrics
      final processingTime = DateTime.now().difference(startTime);
      final fps = 1000.0 / processingTime.inMilliseconds;
      _updateFps(fps);

      // Handle result(s) - support both single and multiple detections
      if (result == null || result is NoDetectionResult) {
        // No detection
        onDetectionResult?.call([]);
      } else if (result is List) {
        // Multiple detections - result is already a List
        final results = <AstronomicalDetectionResult>[];
        for (dynamic item in result) {
          if (item is AstronomicalDetectionResult) {
            results.add(item);
          }
        }

        if (results.isNotEmpty) {
          _detectionCount++;
          onDetectionResult?.call(results);

          // Safety warning for Sun
          final hasSun = results.any((r) => r.isSun);
          if (hasSun) {
            onSunWarning?.call(
              '⚠️ SUN DETECTED! Verify solar filter is in place before tracking.',
            );
          }
        } else {
          onDetectionResult?.call([]);
        }
      } else if (result is AstronomicalDetectionResult) {
        // Single detection (backward compatibility)
        _detectionCount++;
        onDetectionResult?.call([result]);

        if (result.isSun) {
          onSunWarning?.call(
            '⚠️ SUN DETECTED! Verify solar filter is in place before tracking.',
          );
        }
      }
    } catch (e) {
      print('❌ Error processing frame: $e');
      onError?.call(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to RGB bytes
  Future<Map<String, dynamic>> _convertCameraImageToRGB(
    CameraImage image,
  ) async {
    final width = image.width;
    final height = image.height;

    // Convert YUV to RGB bytes
    final rgbBytes = _convertYUVtoRGBBytes(image);

    return {'width': width, 'height': height, 'bytes': rgbBytes};
  }

  /// Convert YUV420 to RGB bytes (more efficient)
  Uint8List _convertYUVtoRGBBytes(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final rgbBytes = Uint8List(width * height * 3);

    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * image.planes[0].bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uvRowStride + (x ~/ 2) * uvPixelStride;

        final yValue = image.planes[0].bytes[yIndex];
        final uValue = image.planes[1].bytes[uvIndex];
        final vValue = image.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        rgbBytes[pixelIndex++] = (yValue + 1.370705 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        rgbBytes[pixelIndex++] =
            (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128))
                .clamp(0, 255)
                .toInt();
        rgbBytes[pixelIndex++] = (yValue + 1.732446 * (uValue - 128))
            .clamp(0, 255)
            .toInt();
      }
    }

    return rgbBytes;
  }

  /// Perform detection in isolate
  Future<dynamic> _detectInIsolate({
    required int width,
    required int height,
    required Uint8List rgbBytes,
    required double telescopeAltitude,
    required double telescopeAzimuth,
    required double latitude,
    required double longitude,
    required DateTime timestamp,
  }) async {
    final receivePort = ReceivePort();

    final input = _DetectionIsolateInput(
      width: width,
      height: height,
      rgbBytes: rgbBytes,
      telescopeAltitude: telescopeAltitude,
      telescopeAzimuth: telescopeAzimuth,
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_detectionIsolateEntry, input);

    // Wait for result (can be List<AstronomicalDetectionResult>, single result, or null)
    final result = await receivePort.first;
    return result; // Return as dynamic - caller handles List or single result
  }

  /// Isolate entry point for detection
  static Future<void> _detectionIsolateEntry(
    _DetectionIsolateInput input,
  ) async {
    try {
      // Step 1: Calculate Sun and Moon positions
      final sunAltAz = AstronomicalCalculator.calculateSunAltAz(
        latitude: input.latitude,
        longitude: input.longitude,
        dateTime: input.timestamp,
      );

      final moonAltAz = AstronomicalCalculator.calculateMoonAltAz(
        latitude: input.latitude,
        longitude: input.longitude,
        dateTime: input.timestamp,
      );

      // Step 2: Calculate angular distances
      final deltaSun = AstronomicalCalculator.calculateAngularDistance(
        alt1: input.telescopeAltitude,
        az1: input.telescopeAzimuth,
        alt2: sunAltAz['altitude']!,
        az2: sunAltAz['azimuth']!,
      );

      final deltaMoon = AstronomicalCalculator.calculateAngularDistance(
        alt1: input.telescopeAltitude,
        az1: input.telescopeAzimuth,
        alt2: moonAltAz['altitude']!,
        az2: moonAltAz['azimuth']!,
      );

      // Step 3: Detect bright blobs using computer vision
      final blobs = await BrightnessDetector.detectBrightObjectsFromRGB(
        input.width,
        input.height,
        input.rgbBytes,
      );

      // Step 4: Classify ALL detected blobs (multiple stars/objects)
      if (blobs.isEmpty) {
        // No detection
        input.sendPort.send(
          NoDetectionResult(deltaSun: deltaSun, deltaMoon: deltaMoon),
        );
        return;
      }

      // Step 5: Hybrid classification for ALL blobs
      final results = <AstronomicalDetectionResult>[];

      for (final blob in blobs) {
        final classificationInput = ClassificationInput(
          blob: blob,
          telescopeAltitude: input.telescopeAltitude,
          telescopeAzimuth: input.telescopeAzimuth,
          sunAltitude: sunAltAz['altitude']!,
          sunAzimuth: sunAltAz['azimuth']!,
          moonAltitude: moonAltAz['altitude']!,
          moonAzimuth: moonAltAz['azimuth']!,
          deltaSun: deltaSun,
          deltaMoon: deltaMoon,
        );

        final result = HybridClassifier.classify(classificationInput);
        results.add(result);
      }

      // Send all results as a list
      input.sendPort.send(results);
    } catch (e) {
      print('❌ Error in detection isolate: $e');
      input.sendPort.send(null);
    }
  }

  /// Update FPS metrics
  void _updateFps(double fps) {
    _fpsHistory.add(fps);
    if (_fpsHistory.length > _fpsHistorySize) {
      _fpsHistory.removeAt(0);
    }

    _averageFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    onFpsUpdate?.call(_averageFps);
  }

  /// Perform single frame detection (for testing)
  Future<AstronomicalDetectionResult?> detectSingleFrame({
    required int width,
    required int height,
    required Uint8List rgbBytes,
    required double telescopeAltitude,
    required double telescopeAzimuth,
    required double latitude,
    required double longitude,
  }) async {
    return await _detectInIsolate(
      width: width,
      height: height,
      rgbBytes: rgbBytes,
      telescopeAltitude: telescopeAltitude,
      telescopeAzimuth: telescopeAzimuth,
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
    );
  }
}
