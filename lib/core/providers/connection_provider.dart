import 'package:flutter/foundation.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ConnectionProvider extends ChangeNotifier {
  bool _isConnected = false;
  String _connectedNetwork = '';
  bool _isScanning = false;
  List<String> _availableNetworks = [];

  bool get isConnected => _isConnected;
  String get connectedNetwork => _connectedNetwork;
  bool get isScanning => _isScanning;
  List<String> get availableNetworks => _availableNetworks;

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
      }
    } catch (e) {
      print('Error connecting to network: $e');
    }
  }

  Future<void> disconnect() async {
    try {
      await WiFiForIoTPlugin.disconnect();
      _isConnected = false;
      _connectedNetwork = '';
      notifyListeners();
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }
}
