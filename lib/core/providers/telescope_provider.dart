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

  bool get isConnected => _isConnected;

  void updateConnectionStatus(bool status) {
    _isConnected = status;
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

  Future<void> slewDown({int steps = 10}) async {
    await _sendCommand('slew', {'direction': 'down', 'steps': steps});
  }

  void connect(String ip) async {
    try {
      final wsUrl = 'ws://$ip:81';
      debugPrint('Connecting to $wsUrl');
      if (isConnected || webSocket != null) {
        return;
      }
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
          _isConnected = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
      );
      _isConnected = true;
      notifyListeners();
    } catch (e) {
      _isConnected = false;
      notifyListeners();
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
