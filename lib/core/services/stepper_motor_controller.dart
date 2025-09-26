// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

class StepperMotorController {
  WebSocket? _webSocket;
  String _wsUrl = 'ws://192.168.4.1:81';

  // Stepper motor configuration
  static const int STEPS_PER_REVOLUTION = 200; // NEMA 17 typical
  static const double DEGREES_PER_STEP = 360.0 / STEPS_PER_REVOLUTION;
  static const int MICROSTEPPING = 16; // Common microstepping value

  Future<void> connect(String ip) async {
    try {
      _wsUrl = 'ws://$ip:81';
      _webSocket = await WebSocket.connect(_wsUrl);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_webSocket != null) {
      await _webSocket!.close();
      _webSocket = null;
    }
  }

  // Send stepper motor commands
  Future<void> _sendCommand(String command, Map<String, dynamic> params) async {
    if (_webSocket == null) {
      throw Exception('Not connected to stepper motor controller');
    }

    try {
      var message = {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...params,
      };

      _webSocket!.add(jsonEncode(message));
    } catch (e) {
      rethrow;
    }
  }

  // Movement commands
  Future<void> moveTo(double targetAzimuth, double targetElevation) async {
    await _sendCommand('goto', {
      'azimuth': targetAzimuth,
      'elevation': targetElevation,
    });
  }

  Future<void> slewUp({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'up', 'steps': steps});
  }

  Future<void> slewDown({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'down', 'steps': steps});
  }

  Future<void> slewLeft({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'left', 'steps': steps});
  }

  Future<void> slewRight({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'right', 'steps': steps});
  }

  Future<void> stop() async {
    await _sendCommand('stop', {});
  }

  Future<void> calibrate() async {
    await _sendCommand('calibrate', {});
  }

  Future<void> goHome() async {
    await _sendCommand('home', {});
  }

  Future<void> setSpeed(double rpm) async {
    await _sendCommand('set_speed', {'rpm': rpm});
  }

  Future<void> setMicrostepping(int mode) async {
    await _sendCommand('set_microstepping', {'mode': mode});
  }

  Future<void> getStepperPosition() async {
    await _sendCommand('get_position', {});
  }

  Future<void> emergencyStop() async {
    await _sendCommand('emergency_stop', {});
  }
}
