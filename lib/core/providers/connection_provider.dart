import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:robotic_telescope/core/services/wifi_manager.dart';
import 'package:robotic_telescope/core/services/telescope_websocket_manager.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectionProvider extends ChangeNotifier {
  final WiFiManager _wifiManager = WiFiManager();
  final TelescopeWebSocketManager _wsManager = TelescopeWebSocketManager();

  bool _isScanning = false;
  List<String> _availableNetworks = [];
  bool _telescopeConnected = false;
  String _telescopeIp = '';

  bool get isConnected => _wifiManager.isConnected;
  String get connectedNetwork => _wifiManager.connectedNetwork;
  bool get isScanning => _isScanning;
  List<String> get availableNetworks => _availableNetworks;
  bool get telescopeConnected => _telescopeConnected;
  String get telescopeIp => _telescopeIp;

  Future<void> scanForTelescopes() async {
    _isScanning = true;
    notifyListeners();

    try {
      _availableNetworks = await _wifiManager.scanForTelescopes();

      // Simulate longer scanning time for better UX
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _availableNetworks = [];
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToTelescope(String ssid, String password) async {
    try {
      // For wifi_scan plugin, we need to guide user to connect manually

      bool wifiResult = await _wifiManager.connectToNetwork(ssid, password);

      if (wifiResult) {
        // Wait a bit for connection to stabilize
        await Future.delayed(const Duration(seconds: 2));

        // Check actual connectivity status (updated for newer connectivity_plus)
        final List<ConnectivityResult> connectivityResult = await Connectivity()
            .checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.wifi)) {
          notifyListeners();
          // After WiFi connection, try to connect to telescope WebSocket
          await _connectToTelescopeWebSocket();
        } else {}
      }
    } catch (e) {}
  }

  Future<void> _connectToTelescopeWebSocket() async {
    try {
      // Try common telescope IP addresses
      List<String> possibleIps = ['192.168.4.1', '192.168.1.1', '10.0.0.1'];

      for (String ip in possibleIps) {
        try {
          await _wsManager.connect(ip);

          _telescopeConnected = true;
          _telescopeIp = ip;

          // Send handshake message
          _wsManager.sendMessage(
            jsonEncode({
              'type': 'handshake',
              'client': 'mobile_app',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          );

          // Listen for messages from telescope
          _wsManager.listen(
            (data) {
              try {
                jsonDecode(data);
                // Handle different message types if needed
              } catch (e) {}
            },
            () {
              _telescopeConnected = false;
              notifyListeners();
            },
            (error) {
              _telescopeConnected = false;
              notifyListeners();
            },
          );

          notifyListeners();
          break; // Successfully connected, exit loop
        } catch (e) {
          continue;
        }
      }
    } catch (e) {}
  }

  Future<void> disconnect() async {
    try {
      // Close WebSocket connection first
      await _wsManager.disconnect();
      _telescopeConnected = false;

      // Then disconnect from WiFi
      await _wifiManager.disconnect();
      notifyListeners();
    } catch (e) {}
  }

  // Send command to telescope via WebSocket
  Future<void> sendTelescopeCommand(
    String command,
    Map<String, dynamic> params,
  ) async {
    if (!_telescopeConnected) {
      throw Exception('Not connected to telescope');
    }

    var message = {
      'command': command,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...params,
    };

    _wsManager.sendMessage(jsonEncode(message));
  }

  // Get telescope status
  Future<Map<String, dynamic>?> getTelescopeStatus() async {
    if (!_telescopeConnected) return null;

    try {
      await sendTelescopeCommand('get_status', {});
      // Status will be received via WebSocket listener
      return null; // Async response will come through WebSocket
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
