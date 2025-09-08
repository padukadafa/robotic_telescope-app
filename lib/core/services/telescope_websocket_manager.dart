import 'dart:io';

class TelescopeWebSocketManager {
  WebSocket? _webSocket;
  String _wsUrl = 'ws://192.168.4.1:81';
  bool _isConnected = false;

  bool get isConnected => _isConnected;
  String get wsUrl => _wsUrl;

  Future<void> connect(String ip) async {
    try {
      _wsUrl = 'ws://$ip:81';
      _webSocket = await WebSocket.connect(_wsUrl);
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      print('WebSocket connection error: $e');
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_webSocket != null) {
      await _webSocket!.close();
      _webSocket = null;
    }
    _isConnected = false;
  }

  void sendMessage(String message) {
    if (_isConnected && _webSocket != null) {
      _webSocket!.add(message);
    }
  }

  void listen(
    void Function(dynamic) onMessage,
    void Function() onDone,
    void Function(dynamic) onError,
  ) {
    if (_webSocket != null) {
      _webSocket!.listen(onMessage, onDone: onDone, onError: onError);
    }
  }
}
