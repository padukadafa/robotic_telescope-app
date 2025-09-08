import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

class TelescopeProvider extends ChangeNotifier {
  double _azimuth = 0.0; // Current azimuth from WebSocket
  double _elevation = 45.0; // Current elevation from WebSocket
  bool _isMoving = false;
  String _status = 'Ready';
  bool _isConnected = false;

  // WebSocket connection
  WebSocket? _webSocket;
  String _wsUrl = 'ws://192.168.4.1:81'; // Default telescope IP

  // Stepper motor configuration
  static const int STEPS_PER_REVOLUTION = 200; // NEMA 17 typical
  static const double DEGREES_PER_STEP = 360.0 / STEPS_PER_REVOLUTION;
  static const int MICROSTEPPING = 16; // Common microstepping value

  double get azimuth => _azimuth;
  double get elevation => _elevation;
  bool get isMoving => _isMoving;
  String get status => _status;
  bool get isConnected => _isConnected;

  // Connect to telescope WebSocket
  Future<void> connectToTelescope(String ip) async {
    try {
      _wsUrl = 'ws://$ip:81';
      _webSocket = await WebSocket.connect(_wsUrl);
      _isConnected = true;
      _status = 'Connected to telescope';
      notifyListeners();

      // Listen for position updates from telescope
      _webSocket!.listen(
        (data) {
          try {
            var message = jsonDecode(data);
            if (message['type'] == 'position') {
              _azimuth = message['azimuth'] ?? _azimuth;
              _elevation = message['elevation'] ?? _elevation;
              _isMoving = message['moving'] ?? false;
              notifyListeners();
            }
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onDone: () {
          _isConnected = false;
          _status = 'Disconnected';
          notifyListeners();
        },
        onError: (error) {
          _isConnected = false;
          _status = 'Connection error';
          notifyListeners();
        },
      );
    } catch (e) {
      _isConnected = false;
      _status = 'Failed to connect';
      print('WebSocket connection error: $e');
      notifyListeners();
    }
  }

  // Disconnect from telescope
  Future<void> disconnect() async {
    if (_webSocket != null) {
      await _webSocket!.close();
      _webSocket = null;
    }
    _isConnected = false;
    _status = 'Disconnected';
    notifyListeners();
  }

  // Send stepper motor commands to telescope
  Future<void> _sendCommand(String command, Map<String, dynamic> params) async {
    if (!_isConnected || _webSocket == null) {
      _status = 'Not connected to telescope';
      notifyListeners();
      return;
    }

    try {
      var message = {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...params
      };

      _webSocket!.add(jsonEncode(message));
      _isMoving = true;
      _status = 'Sending command...';
      notifyListeners();
    } catch (e) {
      _status = 'Command failed';
      print('Error sending command: $e');
      notifyListeners();
    }
  }

  // Move telescope to specific position (angle-based)
  void moveTo(double targetAzimuth, double targetElevation) {
    if (!_isConnected) {
      _status = 'Not connected to telescope';
      notifyListeners();
      return;
    }

    _sendCommand('goto', {
      'azimuth': targetAzimuth,
      'elevation': targetElevation
    });

    _status = 'Moving to target';
    notifyListeners();
  }

  // Manual control - move in specific direction by steps
  void slewUp({int steps = 10}) {
    _sendCommand('slew', {
      'direction': 'up',
      'steps': steps
    });
    _status = 'Moving up';
    notifyListeners();
  }

  void slewDown({int steps = 10}) {
    _sendCommand('slew', {
      'direction': 'down',
      'steps': steps
    });
    _status = 'Moving down';
    notifyListeners();
  }

  void slewLeft({int steps = 10}) {
    _sendCommand('slew', {
      'direction': 'left',
      'steps': steps
    });
    _status = 'Moving left';
    notifyListeners();
  }

  void slewRight({int steps = 10}) {
    _sendCommand('slew', {
      'direction': 'right',
      'steps': steps
    });
    _status = 'Moving right';
    notifyListeners();
  }

  // Stop all movement
  void stop() {
    _sendCommand('stop', {});
    _isMoving = false;
    _status = 'Stopped';
    notifyListeners();
  }

  // Calibrate telescope position
  void calibrate() {
    _sendCommand('calibrate', {});
    _status = 'Calibrating...';
    notifyListeners();
  }

  // Home position
  void goHome() {
    _sendCommand('home', {});
    _status = 'Going home';
    notifyListeners();
  }

  // Set stepper motor speed (RPM)
  void setSpeed(double rpm) {
    _sendCommand('set_speed', {
      'rpm': rpm
    });
  }

  // Set microstepping mode
  void setMicrostepping(int mode) {
    _sendCommand('set_microstepping', {
      'mode': mode
    });
  }

  // Get current stepper position in steps
  void getStepperPosition() {
    _sendCommand('get_position', {});
  }

  // Emergency stop
  void emergencyStop() {
    _sendCommand('emergency_stop', {});
    _isMoving = false;
    _status = 'Emergency stop activated';
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
