import 'package:flutter/foundation.dart';

class TelescopeProvider extends ChangeNotifier {
  double _azimuth = 0.0; // 0-360 degrees
  double _elevation = 45.0; // 0-90 degrees
  bool _isMoving = false;
  String _status = 'Ready';

  double get azimuth => _azimuth;
  double get elevation => _elevation;
  bool get isMoving => _isMoving;
  String get status => _status;

  void moveTo(double targetAzimuth, double targetElevation) {
    _isMoving = true;
    _status = 'Moving to target';
    notifyListeners();

    // Simulate movement (in real app, this would send commands to telescope)
    Future.delayed(const Duration(seconds: 3), () {
      _azimuth = targetAzimuth;
      _elevation = targetElevation;
      _isMoving = false;
      _status = 'Target reached';
      notifyListeners();

      // Reset status after a moment
      Future.delayed(const Duration(seconds: 2), () {
        _status = 'Ready';
        notifyListeners();
      });
    });
  }

  void slewUp() {
    if (_elevation < 90.0) {
      _elevation = (_elevation + 1.0).clamp(0.0, 90.0);
      _isMoving = true;
      _status = 'Moving up';
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () {
        _isMoving = false;
        _status = 'Ready';
        notifyListeners();
      });
    }
  }

  void slewDown() {
    if (_elevation > 0.0) {
      _elevation = (_elevation - 1.0).clamp(0.0, 90.0);
      _isMoving = true;
      _status = 'Moving down';
      notifyListeners();

      Future.delayed(const Duration(milliseconds: 500), () {
        _isMoving = false;
        _status = 'Ready';
        notifyListeners();
      });
    }
  }

  void slewLeft() {
    _azimuth = (_azimuth - 1.0) % 360.0;
    if (_azimuth < 0) _azimuth += 360.0;
    _isMoving = true;
    _status = 'Moving left';
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isMoving = false;
      _status = 'Ready';
      notifyListeners();
    });
  }

  void slewRight() {
    _azimuth = (_azimuth + 1.0) % 360.0;
    _isMoving = true;
    _status = 'Moving right';
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      _isMoving = false;
      _status = 'Ready';
      notifyListeners();
    });
  }

  void stop() {
    _isMoving = false;
    _status = 'Stopped';
    notifyListeners();

    Future.delayed(const Duration(seconds: 1), () {
      _status = 'Ready';
      notifyListeners();
    });
  }

  void setPosition(double azimuth, double elevation) {
    _azimuth = azimuth.clamp(0.0, 360.0);
    _elevation = elevation.clamp(0.0, 90.0);
    notifyListeners();
  }
}
