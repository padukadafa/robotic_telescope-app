import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:robotic_telescope/core/models/astronomical_detection_result.dart';
import 'package:robotic_telescope/core/services/astronomical_detection_service.dart';
import 'package:robotic_telescope/core/di/service_locator.dart';

/// Provider for managing hybrid astronomical detection state
class AstronomicalDetectionProvider extends ChangeNotifier {
  // Service
  late AstronomicalDetectionService _detectionService;

  // State
  bool _isInitialized = false;
  bool _isDetecting = false;
  List<AstronomicalDetectionResult> _currentDetections = [];
  String? _errorMessage;
  String? _sunWarning;

  // Camera state - supports both device camera and IP camera
  CameraController? _cameraController;
  double _frameCenterX = 0.0;
  double _frameCenterY = 0.0;

  // IP Camera support
  bool _useIPCamera = true; // Default to IP camera
  String _ipCameraUrl = 'http://192.168.4.50:81/stream';

  // Location state
  double? _latitude;
  double? _longitude;
  bool _locationInitialized = false;

  // Telescope position (should be updated from TelescopeProvider)
  double _telescopeAltitude = 0.0;
  double _telescopeAzimuth = 0.0;

  // Performance metrics
  double _fps = 0.0;
  int _frameCount = 0;
  int _detectionCount = 0;

  // Safety settings
  bool _sunDetectionEnabled = true;
  bool _requireSolarFilterConfirmation = true;
  bool _solarFilterConfirmed = false;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isDetecting => _isDetecting;
  List<AstronomicalDetectionResult> get currentDetections => _currentDetections;
  AstronomicalDetectionResult? get currentDetection =>
      _currentDetections.isNotEmpty
      ? _currentDetections.first
      : null; // Backward compatibility
  String? get errorMessage => _errorMessage;
  String? get sunWarning => _sunWarning;
  double get fps => _fps;
  int get frameCount => _frameCount;
  int get detectionCount => _detectionCount;
  CameraController? get cameraController => _cameraController;
  bool get locationInitialized => _locationInitialized;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get sunDetectionEnabled => _sunDetectionEnabled;
  bool get solarFilterConfirmed => _solarFilterConfirmed;
  double get telescopeAltitude => _telescopeAltitude;
  double get telescopeAzimuth => _telescopeAzimuth;
  bool get useIPCamera => _useIPCamera;
  String get ipCameraUrl => _ipCameraUrl;

  /// Initialize the astronomical detection system
  Future<void> initialize() async {
    try {
      _errorMessage = null;

      // Get detection service from DI
      _detectionService = Services.astronomicalDetection;

      // Set up callbacks
      _detectionService.onDetectionResult = _handleDetectionResult;
      _detectionService.onError = _handleError;
      _detectionService.onFpsUpdate = _handleFpsUpdate;
      _detectionService.onSunWarning = _handleSunWarning;

      _isInitialized = true;
      notifyListeners();

      print('✅ Astronomical detection system initialized');
    } catch (e) {
      _errorMessage = 'Failed to initialize detection: $e';
      _isInitialized = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Initialize location
  Future<void> initializeLocation() async {
    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationInitialized = true;

      notifyListeners();
      print('✅ Location initialized: ($_latitude, $_longitude)');
    } catch (e) {
      _errorMessage = 'Failed to get location: $e';
      _locationInitialized = false;
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

  /// Update telescope position (should be called when telescope moves)
  void updateTelescopePosition({
    required double altitude,
    required double azimuth,
  }) {
    _telescopeAltitude = altitude;
    _telescopeAzimuth = azimuth;

    // Update the detection service with new position
    _detectionService.updateTelescopePosition(
      altitude: altitude,
      azimuth: azimuth,
    );
  }

  /// Start astronomical detection
  Future<void> startDetection() async {
    if (!_isInitialized) {
      throw Exception('Detection system not initialized');
    }

    if (!_locationInitialized) {
      throw Exception('Location not initialized');
    }

    if (_isDetecting) {
      print('⚠️ Detection already running');
      return;
    }

    try {
      if (_useIPCamera) {
        // Use IP camera stream
        await _detectionService.startDetectionFromIPCamera(
          _ipCameraUrl,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      } else {
        // Use device camera
        if (_cameraController == null ||
            !_cameraController!.value.isInitialized) {
          throw Exception('Camera not initialized');
        }

        await _detectionService.startDetection(
          _cameraController!,
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      _isDetecting = true;
      _errorMessage = null;
      _sunWarning = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to start detection: $e';
      _isDetecting = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Stop astronomical detection
  Future<void> stopDetection() async {
    if (!_isDetecting) return;

    try {
      if (_useIPCamera) {
        await _detectionService.stopIPCameraDetection();
      } else {
        await _detectionService.stopDetection(_cameraController!);
      }

      _isDetecting = false;
      _currentDetections = [];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop detection: $e';
      notifyListeners();
    }
  }

  /// Handle detection results (multiple detections)
  void _handleDetectionResult(List<AstronomicalDetectionResult> detections) {
    _currentDetections = detections;
    if (detections.isNotEmpty) {
      _detectionCount = _detectionService.detectionCount;
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
    _frameCount = _detectionService.frameCount;
    // Don't notify listeners for FPS updates to avoid excessive rebuilds
  }

  /// Handle Sun warning
  void _handleSunWarning(String warning) {
    _sunWarning = warning;
    notifyListeners();

    // Optionally stop detection if sun is detected and filter not confirmed
    if (_requireSolarFilterConfirmation && !_solarFilterConfirmed) {
      print(
        '⚠️ Sun detected without solar filter confirmation - stopping detection',
      );
      stopDetection();
    }
  }

  /// Set IP camera URL
  void setIPCameraUrl(String url) {
    _ipCameraUrl = url;
    notifyListeners();
    print('🎥 IP Camera URL set to: $url');
  }

  /// Toggle between device camera and IP camera
  void setUseIPCamera(bool useIP) {
    _useIPCamera = useIP;
    notifyListeners();
    print('🎥 Camera mode: ${useIP ? "IP Camera" : "Device Camera"}');
  }

  /// Confirm solar filter is in place
  void confirmSolarFilter() {
    _solarFilterConfirmed = true;
    _sunWarning = null;
    notifyListeners();
  }

  /// Reset solar filter confirmation
  void resetSolarFilterConfirmation() {
    _solarFilterConfirmed = false;
    notifyListeners();
  }

  /// Toggle sun detection
  void toggleSunDetection() {
    _sunDetectionEnabled = !_sunDetectionEnabled;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear sun warning
  void clearSunWarning() {
    _sunWarning = null;
    notifyListeners();
  }

  /// Get pointing error for primary detection
  Map<String, double>? getPointingError() {
    if (_currentDetections.isEmpty) return null;
    final primaryDetection = _currentDetections.first;
    return primaryDetection.calculatePointingError(
      _frameCenterX,
      _frameCenterY,
    );
  }

  /// Get correction data for WebSocket (for primary detection)
  Map<String, dynamic>? getCorrectionData() {
    if (_currentDetections.isEmpty) return null;
    final primaryDetection = _currentDetections.first;

    final error = getPointingError();
    if (error == null) return null;

    return {
      'command': 'astronomical_correction',
      'object': primaryDetection.objectName,
      'type': primaryDetection.type,
      'confidence': primaryDetection.confidence,
      'dx': error['dx'],
      'dy': error['dy'],
      'delta_sun': primaryDetection.deltaSun,
      'delta_moon': primaryDetection.deltaMoon,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Check if correction is needed (within 10 pixels of center)
  bool needsCorrection({double threshold = 10.0}) {
    final error = getPointingError();
    if (error == null) return false;

    final dx = error['dx']!;
    final dy = error['dy']!;
    final distance = (dx * dx + dy * dy);

    return distance > (threshold * threshold);
  }

  @override
  void dispose() {
    if (_isDetecting) {
      _detectionService.stopDetection(_cameraController!);
    }
    _cameraController?.dispose();
    super.dispose();
  }
}
