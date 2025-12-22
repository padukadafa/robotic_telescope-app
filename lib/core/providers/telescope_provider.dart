import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

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

  Future<void> stop() async {
    await _sendCommand('stop', {});
  }

  void connect(String ip) async {
    try {
      _lastIp = ip;
      final wsUrl = 'ws://$ip:81';
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
}
