import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:robotic_telescope/core/models/detection_result.dart';
import 'package:robotic_telescope/core/services/tflite_service.dart';

/// Manages real-time object detection from camera stream
class ObjectDetector {
  final TFLiteService _tfliteService;

  bool _isDetecting = false;
  bool _isProcessing = false;
  int _frameCount = 0;
  int _detectionCount = 0;

  // Performance metrics
  double _averageFps = 0.0;
  final List<double> _fpsHistory = [];
  static const int _fpsHistorySize = 30;

  // Detection callback
  Function(List<DetectionResult>)? onDetectionResult;
  Function(String)? onError;
  Function(double)? onFpsUpdate;

  ObjectDetector({required TFLiteService tfliteService})
    : _tfliteService = tfliteService;

  bool get isDetecting => _isDetecting;
  double get averageFps => _averageFps;
  int get frameCount => _frameCount;
  int get detectionCount => _detectionCount;

  /// Start object detection from camera stream
  Future<void> startDetection(CameraController cameraController) async {
    if (!_tfliteService.isInitialized) {
      throw Exception(
        'TFLite service must be initialized before starting detection',
      );
    }

    if (_isDetecting) {
      print('⚠️ Detection already running');
      return;
    }

    _isDetecting = true;
    _frameCount = 0;
    _detectionCount = 0;
    print('🎥 Starting object detection...');

    try {
      await cameraController.startImageStream((CameraImage image) async {
        if (!_isDetecting) return;

        // Skip if already processing a frame (throttling mechanism)
        if (_isProcessing) return;

        _processFrame(image);
      });
    } catch (e) {
      print('❌ Error starting image stream: $e');
      _isDetecting = false;
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Stop object detection
  Future<void> stopDetection(CameraController cameraController) async {
    if (!_isDetecting) return;

    _isDetecting = false;
    _isProcessing = false;

    try {
      await cameraController.stopImageStream();
      print('🛑 Object detection stopped');
      print('   Total frames processed: $_frameCount');
      print('   Total detections: $_detectionCount');
      print('   Average FPS: ${_averageFps.toStringAsFixed(1)}');
    } catch (e) {
      print('⚠️ Error stopping image stream: $e');
    }
  }

  /// Process a single camera frame
  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing) return;

    _isProcessing = true;
    _frameCount++;

    final startTime = DateTime.now();

    try {
      // Convert CameraImage to RGB bytes
      final imageBytes = _convertCameraImage(image);

      // Run detection with raw RGB bytes
      final detections = await _tfliteService.detectObjectsFromRGB(
        image.width,
        image.height,
        Uint8List.fromList(imageBytes),
      );

      // Update metrics
      _updatePerformanceMetrics(startTime);

      // Filter for astronomical objects only
      final filteredDetections = _filterAstronomicalObjects(detections);

      if (filteredDetections.isNotEmpty) {
        _detectionCount++;
      }

      // Callback with results
      onDetectionResult?.call(filteredDetections);
    } catch (e) {
      print('❌ Error processing frame: $e');
      onError?.call(e.toString());
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to Uint8List
  List<int> _convertCameraImage(CameraImage image) {
    try {
      // Handle different image formats
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420ToBytes(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return image.planes[0].bytes;
      } else {
        throw Exception('Unsupported image format: ${image.format.group}');
      }
    } catch (e) {
      print('❌ Error converting camera image: $e');
      rethrow;
    }
  }

  /// Convert YUV420 to RGB bytes
  List<int> _convertYUV420ToBytes(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final List<int> rgb = List.filled(width * height * 3, 0);

    for (int row = 0; row < height; row++) {
      for (int col = 0; col < width; col++) {
        final int yIndex = row * width + col;
        final int uvIndex =
            uvPixelStride * (col / 2).floor() + uvRowStride * (row / 2).floor();

        final int y = image.planes[0].bytes[yIndex];
        final int u = image.planes[1].bytes[uvIndex];
        final int v = image.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        int r = (y + v * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (y + u * 1814 / 1024 - 227).round().clamp(0, 255);

        final int rgbIndex = yIndex * 3;
        rgb[rgbIndex] = r;
        rgb[rgbIndex + 1] = g;
        rgb[rgbIndex + 2] = b;
      }
    }

    return rgb;
  }

  /// Filter detections to only include astronomical objects
  List<DetectionResult> _filterAstronomicalObjects(
    List<DetectionResult> detections,
  ) {
    return detections.where((detection) {
      final object = AstronomicalObject.fromLabel(detection.objectName);
      return object != AstronomicalObject.unknown;
    }).toList();
  }

  /// Update performance metrics (FPS tracking)
  void _updatePerformanceMetrics(DateTime startTime) {
    final processingTime = DateTime.now().difference(startTime);
    final fps = 1000 / processingTime.inMilliseconds;

    _fpsHistory.add(fps);
    if (_fpsHistory.length > _fpsHistorySize) {
      _fpsHistory.removeAt(0);
    }

    _averageFps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;

    // Callback with FPS update
    onFpsUpdate?.call(_averageFps);
  }

  /// Get the best (highest confidence) detection
  DetectionResult? getBestDetection(List<DetectionResult> detections) {
    if (detections.isEmpty) return null;

    return detections.reduce((a, b) => a.confidence > b.confidence ? a : b);
  }

  /// Dispose resources
  void dispose() {
    _isDetecting = false;
    _isProcessing = false;
    print('🧹 ObjectDetector disposed');
  }
}
