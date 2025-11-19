import 'dart:async';
import 'dart:math';

/// Dummy telescope service for testing without hardware
/// Simulates telescope behavior locally without WebSocket connection
class TelescopeDummyService {
  // Current position
  double _currentAzimuth = 0.0;
  double _currentElevation = 45.0;

  // Target position
  double? _targetAzimuth;
  double? _targetElevation;

  // State
  bool _isMoving = false;
  bool _isCalibrated = true;
  double _speed = 2.0; // degrees per second

  // Stream controllers
  final _positionController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  Timer? _simulationTimer;

  // Getters
  Stream<Map<String, dynamic>> get positionStream => _positionController.stream;
  Stream<String> get statusStream => _statusController.stream;
  double get currentAzimuth => _currentAzimuth;
  double get currentElevation => _currentElevation;
  bool get isMoving => _isMoving;
  bool get isCalibrated => _isCalibrated;

  void start() {
    // Start simulation loop
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updatePosition();
      _sendPositionUpdate();
    });
    _statusController.add('Dummy telescope simulator started');
  }

  void dispose() {
    _simulationTimer?.cancel();
    _positionController.close();
    _statusController.close();
  }

  void _updatePosition() {
    if (!_isMoving || _targetAzimuth == null || _targetElevation == null) {
      return;
    }

    // Calculate difference
    double azDiff = _targetAzimuth! - _currentAzimuth;
    double elDiff = _targetElevation! - _currentElevation;

    // Handle azimuth wrap-around (shortest path)
    if (azDiff > 180) azDiff -= 360;
    if (azDiff < -180) azDiff += 360;

    // Calculate movement step (speed * time interval)
    double stepSize = _speed * 0.1; // 0.1 second interval

    // Move towards target
    if (azDiff.abs() > 0.5) {
      _currentAzimuth += azDiff.sign * min(stepSize, azDiff.abs());
      _currentAzimuth = (_currentAzimuth % 360 + 360) % 360;
    }

    if (elDiff.abs() > 0.5) {
      _currentElevation += elDiff.sign * min(stepSize, elDiff.abs());
      _currentElevation = _currentElevation.clamp(0.0, 90.0);
    }

    // Check if reached target
    if (azDiff.abs() <= 0.5 && elDiff.abs() <= 0.5) {
      _currentAzimuth = _targetAzimuth!;
      _currentElevation = _targetElevation!;
      _isMoving = false;
      _targetAzimuth = null;
      _targetElevation = null;
      _statusController.add(
        'Target reached: Az=${_currentAzimuth.toStringAsFixed(2)}° El=${_currentElevation.toStringAsFixed(2)}°',
      );
    }
  }

  void _sendPositionUpdate() {
    _positionController.add({
      'type': 'position',
      'azimuth': double.parse(_currentAzimuth.toStringAsFixed(2)),
      'elevation': double.parse(_currentElevation.toStringAsFixed(2)),
      'moving': _isMoving,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Command methods
  Future<Map<String, dynamic>> moveTo(double azimuth, double elevation) async {
    if (!_isCalibrated) {
      return {
        'status': 'error',
        'message': 'Telescope not calibrated. Please calibrate first.',
      };
    }

    _targetAzimuth = azimuth.clamp(0.0, 360.0);
    _targetElevation = elevation.clamp(0.0, 90.0);
    _isMoving = true;

    _statusController.add(
      'Moving to Az=${_targetAzimuth!.toStringAsFixed(2)}° El=${_targetElevation!.toStringAsFixed(2)}°',
    );

    return {
      'status': 'success',
      'command': 'goto',
      'targetAzimuth': _targetAzimuth,
      'targetElevation': _targetElevation,
    };
  }

  Future<Map<String, dynamic>> slew(String direction, {int steps = 10}) async {
    double stepSize = steps.toDouble();

    switch (direction) {
      case 'up':
        _currentElevation = (_currentElevation + stepSize).clamp(0.0, 90.0);
        break;
      case 'down':
        _currentElevation = (_currentElevation - stepSize).clamp(0.0, 90.0);
        break;
      case 'left':
        _currentAzimuth = (_currentAzimuth - stepSize % 360 + 360) % 360;
        break;
      case 'right':
        _currentAzimuth = (_currentAzimuth + stepSize) % 360;
        break;
    }

    _statusController.add('Slewed $direction by $steps steps');
    _sendPositionUpdate();

    return {
      'status': 'success',
      'command': 'slew',
      'direction': direction,
      'steps': steps,
    };
  }

  Future<Map<String, dynamic>> stop() async {
    _isMoving = false;
    _targetAzimuth = null;
    _targetElevation = null;
    _statusController.add('Telescope stopped');

    return {'status': 'success', 'command': 'stop'};
  }

  Future<Map<String, dynamic>> emergencyStop() async {
    _isMoving = false;
    _targetAzimuth = null;
    _targetElevation = null;
    _statusController.add('⚠️ EMERGENCY STOP');

    return {'status': 'success', 'command': 'emergency_stop'};
  }

  Future<Map<String, dynamic>> goHome() async {
    return await moveTo(0, 45);
  }

  Future<Map<String, dynamic>> calibrate() async {
    _currentAzimuth = 0.0;
    _currentElevation = 45.0;
    _targetAzimuth = null;
    _targetElevation = null;
    _isMoving = false;
    _isCalibrated = true;
    _statusController.add('Telescope calibrated to home position');

    _sendPositionUpdate();

    return {
      'status': 'success',
      'command': 'calibrate',
      'message': 'Telescope calibrated to home position',
    };
  }

  Future<Map<String, dynamic>> setSpeed(double speed) async {
    _speed = speed.clamp(0.1, 10.0);
    _statusController.add('Speed set to ${_speed.toStringAsFixed(1)} deg/s');

    return {'status': 'success', 'command': 'set_speed', 'speed': _speed};
  }

  Map<String, dynamic> getPosition() {
    return {
      'azimuth': double.parse(_currentAzimuth.toStringAsFixed(2)),
      'elevation': double.parse(_currentElevation.toStringAsFixed(2)),
      'moving': _isMoving,
      'calibrated': _isCalibrated,
    };
  }

  Map<String, dynamic> getStatus() {
    return {
      'connected': true,
      'calibrated': _isCalibrated,
      'moving': _isMoving,
      'mode': 'dummy',
      'position': {'azimuth': _currentAzimuth, 'elevation': _currentElevation},
      'target': _targetAzimuth != null
          ? {'azimuth': _targetAzimuth, 'elevation': _targetElevation}
          : null,
    };
  }
}
