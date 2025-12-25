import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

class TelescopeProvider extends ChangeNotifier {
  bool _isConnected = false;
  WebSocket? webSocket;
  TelescopeProvider();
  num azimuth = 0.0;
  num elevation = 0.0;
  bool isMoving = false;
  String? _lastIp;

  bool get isConnected => _isConnected;

  void updateConnectionStatus(bool status) {
    _isConnected = status;
    notifyListeners();
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

  Future<void> goto({required double ra, required double dec}) async {
    await _sendCommand('goto', {'ra': ra, 'dec': dec});
  }

  Future<void> goToObject(AstronomicalObject object) async {
    await goto(ra: object.ra, dec: object.dec);
  }

  Future<void> stop() async {
    await _sendCommand('stop', {});
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
          azimuth = jsonData['azimuth'] ?? azimuth;
          elevation = jsonData['elevation'] ?? elevation;
          isMoving = jsonData['moving'] ?? isMoving;
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

      notifyListeners();
      init();
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
}
