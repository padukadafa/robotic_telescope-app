import 'package:flutter/foundation.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'dart:io';
import 'dart:convert';

class ConnectionProvider extends ChangeNotifier {
  bool _isConnected = false;
  String _connectedNetwork = '';
  bool _isScanning = false;
  List<String> _availableNetworks = [];
  bool _telescopeConnected = false;
  String _telescopeIp = '';
  WebSocket? _telescopeWebSocket;

  bool get isConnected => _isConnected;
  String get connectedNetwork => _connectedNetwork;
  bool get isScanning => _isScanning;
  List<String> get availableNetworks => _availableNetworks;
  bool get telescopeConnected => _telescopeConnected;
  String get telescopeIp => _telescopeIp;

  Future<void> scanForTelescopes() async {
    _isScanning = true;
    notifyListeners();

    try {
      _availableNetworks.clear();
      List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();

      // Filter for telescope networks (starting with "Tele_")
      for (var network in networks) {
        if (network.ssid != null && network.ssid!.startsWith('Tele_')) {
          _availableNetworks.add(network.ssid!);
        }
      }
    } catch (e) {
      print('Error scanning networks: $e');
    }

    _isScanning = false;
    notifyListeners();
  }

  Future<void> connectToTelescope(String ssid, String password) async {
    try {
      bool result = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
      );

      if (result) {
        _isConnected = true;
        _connectedNetwork = ssid;
        notifyListeners();

        // After WiFi connection, try to connect to telescope WebSocket
        await _connectToTelescopeWebSocket();
      }
    } catch (e) {
      print('Error connecting to network: $e');
    }
  }

  Future<void> _connectToTelescopeWebSocket() async {
    try {
      // Try common telescope IP addresses
      List<String> possibleIps = ['192.168.4.1', '192.168.1.1', '10.0.0.1'];

      for (String ip in possibleIps) {
        try {
          _telescopeWebSocket = await WebSocket.connect('ws://$ip:81')
              .timeout(const Duration(seconds: 5));

          _telescopeConnected = true;
          _telescopeIp = ip;

          // Send handshake message
          _telescopeWebSocket!.add(jsonEncode({
            'type': 'handshake',
            'client': 'mobile_app',
            'timestamp': DateTime.now().millisecondsSinceEpoch
          }));

          // Listen for messages from telescope
          _telescopeWebSocket!.listen(
            (data) {
              try {
                var message = jsonDecode(data);
                print('Received from telescope: $message');
                // Handle different message types if needed
              } catch (e) {
                print('Error parsing telescope message: $e');
              }
            },
            onDone: () {
              _telescopeConnected = false;
              notifyListeners();
            },
            onError: (error) {
              _telescopeConnected = false;
              print('WebSocket error: $error');
              notifyListeners();
            },
          );

          notifyListeners();
          break; // Successfully connected, exit loop

        } catch (e) {
          print('Failed to connect to $ip: $e');
          continue;
        }
      }
    } catch (e) {
      print('Error connecting to telescope WebSocket: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      // Close WebSocket connection first
      if (_telescopeWebSocket != null) {
        await _telescopeWebSocket!.close();
        _telescopeWebSocket = null;
        _telescopeConnected = false;
      }

      // Then disconnect from WiFi
      await WiFiForIoTPlugin.disconnect();
      _isConnected = false;
      _connectedNetwork = '';
      notifyListeners();
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }

  // Send command to telescope via WebSocket
  Future<void> sendTelescopeCommand(String command, Map<String, dynamic> params) async {
    if (!_telescopeConnected || _telescopeWebSocket == null) {
      throw Exception('Not connected to telescope');
    }

    var message = {
      'command': command,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      ...params
    };

    _telescopeWebSocket!.add(jsonEncode(message));
  }

  // Get telescope status
  Future<Map<String, dynamic>?> getTelescopeStatus() async {
    if (!_telescopeConnected) return null;

    try {
      await sendTelescopeCommand('get_status', {});
      // Status will be received via WebSocket listener
      return null; // Async response will come through WebSocket
    } catch (e) {
      print('Error getting telescope status: $e');
      return null;
    }
  }

  @override
  void dispose() {
    if (_telescopeWebSocket != null) {
      _telescopeWebSocket!.close();
    }
    super.dispose();
  }
}
