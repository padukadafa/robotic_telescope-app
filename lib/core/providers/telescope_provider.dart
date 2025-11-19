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

  void connect(String ip) async {
    try {
      final wsUrl = 'ws://$ip:81';
      print('Connecting to $wsUrl');
      if (isConnected || webSocket != null) {
        return;
      }
      webSocket = await WebSocket.connect(wsUrl);
      webSocket!.listen(
        (data) {
          final jsonData = jsonDecode(data);
          azimuth = jsonData['azimuth'] ?? azimuth;
          elevation = jsonData['elevation'] ?? elevation;
          isMoving = jsonData['isMoving'] ?? isMoving;
          notifyListeners();
          print('Received data: $data');
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          notifyListeners();
        },
        onError: (error) {
          print('WebSocket error: $error');
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
