import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:robotic_telescope/core/models/detection_result.dart';
import 'package:robotic_telescope/core/services/tflite_service.dart';
import 'package:robotic_telescope/core/services/object_detector.dart';

/// Provider for managing AI object detection state
class DetectionProvider extends ChangeNotifier {
  // Services
  late TFLiteService _tfliteService;
  late ObjectDetector _objectDetector;

  // State
  bool _isInitialized = false;
  bool _isDetecting = false;
  List<DetectionResult> _currentDetections = [];
  DetectionResult? _bestDetection;
  PointingError? _pointingError;
  String? _errorMessage;

  // Camera state
  CameraController? _cameraController;
  double _frameCenterX = 0.0;
  double _frameCenterY = 0.0;

  // Performance metrics
  double _fps = 0.0;
  int _frameCount = 0;
  int _detectionCount = 0;

  // Auto-correction settings
  bool _autoCorrection = false;
  double _correctionThreshold = 50.0; // pixels

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDetecting => _isDetecting;
  List<DetectionResult> get currentDetections => _currentDetections;
  DetectionResult? get bestDetection => _bestDetection;
  PointingError? get pointingError => _pointingError;
  String? get errorMessage => _errorMessage;
  double get fps => _fps;
  int get frameCount => _frameCount;
  int get detectionCount => _detectionCount;
  bool get autoCorrection => _autoCorrection;
  double get correctionThreshold => _correctionThreshold;
  CameraController? get cameraController => _cameraController;

  /// Initialize the detection system
  /// NOTE: TFLite ML detection is DISABLED - use AstronomicalDetectionProvider for bright point detection
  Future<void> initialize({
    required String modelPath,
    required String labelsPath,
  }) async {
    try {
      _errorMessage = null;

      // TFLite ML detection - DISABLED by user request
      // Only using bright point detection now (AstronomicalDetectionProvider)
      throw Exception(
        'TFLite ML detection is disabled. Use AstronomicalDetectionProvider for bright point detection.',
      );

      /* COMMENTED OUT - TFLite ML detection disabled
      // Initialize TFLite service
      _tfliteService = TFLiteService();
      await _tfliteService.initialize(
        modelPath: modelPath,
        labelsPath: labelsPath,
      );

      // Initialize object detector
      _objectDetector = ObjectDetector(tfliteService: _tfliteService);

      // Set up callbacks
      _objectDetector.onDetectionResult = _handleDetectionResult;
      _objectDetector.onError = _handleError;
      _objectDetector.onFpsUpdate = _handleFpsUpdate;

      _isInitialized = true;
      notifyListeners();

      print('✅ Detection system initialized');
      */
    } catch (e) {
      _errorMessage = 'Failed to initialize detection: $e';
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Initialize camera
  Future<void> initializeCamera({CameraDescription? camera}) async {
    try {
      // Get available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Use provided camera or default to first camera
      final selectedCamera = camera ?? cameras.first;

      // Initialize camera controller
      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Set frame center
      _frameCenterX = _cameraController!.value.previewSize!.width / 2;
      _frameCenterY = _cameraController!.value.previewSize!.height / 2;

      notifyListeners();
      print('✅ Camera initialized: ${_cameraController!.value.previewSize}');
    } catch (e) {
      _errorMessage = 'Failed to initialize camera: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Start object detection
  Future<void> startDetection() async {
    if (!_isInitialized) {
      throw Exception('Detection system not initialized');
    }

    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      throw Exception('Camera not initialized');
    }

    if (_isDetecting) {
      print('⚠️ Detection already running');
      return;
    }

    try {
      await _objectDetector.startDetection(_cameraController!);
      _isDetecting = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start detection: $e';
      _isDetecting = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Stop object detection
  Future<void> stopDetection() async {
    if (!_isDetecting) return;

    try {
      await _objectDetector.stopDetection(_cameraController!);
      _isDetecting = false;
      _currentDetections = [];
      _bestDetection = null;
      _pointingError = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop detection: $e';
      notifyListeners();
    }
  }

  /// Handle detection results
  void _handleDetectionResult(List<DetectionResult> detections) {
    _currentDetections = detections;
    _detectionCount = _objectDetector.detectionCount;

    // Get best detection
    _bestDetection = _objectDetector.getBestDetection(detections);

    // Calculate pointing error if object detected
    if (_bestDetection != null) {
      _pointingError = _bestDetection!.calculatePointingError(
        _frameCenterX,
        _frameCenterY,
      );
    } else {
      _pointingError = null;
    }

    notifyListeners();
  }

  /// Handle detection errors
  void _handleError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// Handle FPS updates
  void _handleFpsUpdate(double fps) {
    _fps = fps;
    _frameCount = _objectDetector.frameCount;
    notifyListeners();
  }

  /// Toggle auto-correction
  void toggleAutoCorrection() {
    _autoCorrection = !_autoCorrection;
    notifyListeners();
  }

  /// Set correction threshold
  void setCorrectionThreshold(double threshold) {
    _correctionThreshold = threshold;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get correction data for WebSocket
  Map<String, dynamic>? getCorrectionData() {
    if (_pointingError == null || _bestDetection == null) {
      return null;
    }

    return {
      'command': 'pointing_correction',
      'object': _bestDetection!.objectName,
      'confidence': _bestDetection!.confidence,
      'error': _pointingError!.toNormalized(
        _cameraController?.value.previewSize?.width ?? 1.0,
        _cameraController?.value.previewSize?.height ?? 1.0,
      ),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if correction is needed
  bool needsCorrection() {
    if (_pointingError == null) return false;
    return !_pointingError!.isWithinThreshold(_correctionThreshold);
  }

  @override
  void dispose() {
    _objectDetector.dispose();
    _tfliteService.dispose();
    _cameraController?.dispose();
    super.dispose();
  }
}
