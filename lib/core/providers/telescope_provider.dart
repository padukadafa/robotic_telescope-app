import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

class TelescopeProvider extends ChangeNotifier {
  TelescopeProvider();

  num azimuth = 0.0;
  String compassCalibrationStatus =
      "done"; // statusnya ada "done", "in_progress", "not_started"

  num elevation = 0.0;
  String gyroCalibrationStatus =
      "done"; // statusnya ada "done", "in_progress", "not_started"

  bool isMoving = false;
  double pitch = 0.0; // Pitch angle in degrees
  // Level/Waterpass data from MPU6050
  double roll = 0.0; // Roll angle in degrees

  WebSocket? webSocket;

  bool _isConnected = false;
  String? _lastIp;

  bool get isCallibrated =>
      compassCalibrationStatus == "done" && gyroCalibrationStatus == "done";

  bool get isLevel => roll.abs() < 2.0 && pitch.abs() < 2.0;

  bool get isConnected => _isConnected;

  void updateConnectionStatus(bool status) {
    _isConnected = status;
    notifyListeners();
  }

  Future<void> slewUp({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'up', 'steps': steps});
  }

  Future<void> slewLeft({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'left', 'steps': steps});
  }

  Future<void> slewRight({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'right', 'steps': steps});
  }

  Future<void> slewDown({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'down', 'steps': steps});
  }

  Future<void> goToAzEl({
    required double azimuth,
    required double elevation,
  }) async {
    await _sendCommand('goto', {'azimuth': azimuth, 'elevation': elevation});
  }

  Future<void> goto({
    required double ra,
    required double dec,
    required ObjectType objectType,
    int? planetIndex,
  }) async {
    if (objectType == ObjectType.planet) {
      _sendCommand("goto-planet", {'planetIndex': planetIndex});
    } else if (objectType == ObjectType.moon) {
      _sendCommand("goto-moon", {});
    } else if (objectType == ObjectType.sun) {
      _sendCommand("goto-sun", {});
    } else if (objectType == ObjectType.star) {
      await _sendCommand('goto-star', {'ra': ra, 'dec': dec});
    } else {
      await _sendCommand('goto', {'ra': ra, 'dec': dec});
    }
  }

  Future<void> goToObject(AstronomicalObject object) async {
    await goto(ra: object.ra, dec: object.dec, objectType: object.objectType);
  }

  Future<void> stop() async {
    await _sendCommand('stop', {});
  }

  Future<void> calibrateCompass() async {
    compassCalibrationStatus = "in_progress";
    notifyListeners();
    await _sendCommand('calibrateCompass', {});
  }

  Future<void> calibrateGyro() async {
    notifyListeners();
    await _sendCommand('calibrateGyro', {});
  }

  void connect(String ip) async {
    try {
      _lastIp = ip;
      final wsUrl = 'ws://$ip:80/ws';
      debugPrint('Connecting to $wsUrl');
      debugPrint('Current connection status: $isConnected');
      if (webSocket != null) {
        await _cleanupConnection();
      }
      debugPrint('Attempting to connect to WebSocket at $wsUrl');
      webSocket = await WebSocket.connect(wsUrl);
      webSocket?.listen(
        (data) {
          final jsonData = jsonDecode(data);
          if (jsonData['type'] == 'status') {
            azimuth = jsonData['azimuth'] ?? azimuth;
            elevation = jsonData['elevation'] ?? elevation;
            isMoving = jsonData['moving'] ?? isMoving;
            roll = (jsonData['roll'] ?? roll).toDouble();
            pitch = (jsonData['pitch'] ?? pitch).toDouble();
          } else if (jsonData['type'] == 'calibrate') {
            if (jsonData['sensor'] == 'compass') {
              compassCalibrationStatus =
                  jsonData['status'] ?? compassCalibrationStatus;
            } else if (jsonData['sensor'] == 'gyroscope') {
              gyroCalibrationStatus =
                  jsonData['status'] ?? gyroCalibrationStatus;
            }
          }
          notifyListeners();
          debugPrint('Received data: $data');
        },

        onDone: () {
          debugPrint('WebSocket connection closed');
          _cleanupConnection();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _cleanupConnection();
        },
      );
      _isConnected = true;
      init();
      notifyListeners();
    } catch (e) {
      await _cleanupConnection();
      rethrow;
    }
  }

  void disconnect() async {
    if (webSocket != null) {
      await webSocket!.close();
      webSocket = null;
    }
    _isConnected = false;
    notifyListeners();
  }

  Future<void> init() async {
    final now = DateTime.now();

    webSocket?.add(
      jsonEncode({
        "command": "updateTime",
        "year": now.year,
        "month": now.month,
        "day": now.day,
        "hour": now.hour,
        "minute": now.minute,
        "second": now.second,
        "timestamp": now.millisecondsSinceEpoch,
      }),
    );

    final position = await _getCurrentPosition();
    if (position != null) {
      webSocket?.add(
        jsonEncode({
          "command": "updateLocation",
          "latitude": position.latitude,
          "longitude": position.longitude,
          "timestamp": now.millisecondsSinceEpoch,
        }),
      );
    } else {
      debugPrint('Unable to retrieve device location for updateLocation');
    }
  }

  Future<void> _cleanupConnection() async {
    if (webSocket != null) {
      try {
        await webSocket!.close();
      } catch (_) {
        // ignore cleanup errors
      }
    }
    webSocket = null;
    _isConnected = false;
    notifyListeners();
  }

  Future<void> _sendCommand(String command, Map<String, dynamic> params) async {
    if (webSocket == null) {
      throw Exception('Not connected to stepper motor controller');
    }
    print("Send command $command with params $params");

    try {
      var message = {
        'command': command,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        ...params,
      };

      webSocket?.add(jsonEncode(message));
    } catch (e) {
      rethrow;
    }
  }

  Future<Position?> _getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }
}
