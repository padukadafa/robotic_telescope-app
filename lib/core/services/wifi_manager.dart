import 'package:wifi_iot/wifi_iot.dart';

class WiFiManager {
  bool _isConnected = false;
  String _connectedNetwork = '';

  bool get isConnected => _isConnected;
  String get connectedNetwork => _connectedNetwork;

  Future<List<String>> scanForTelescopes() async {
    List<String> telescopeNetworks = [];
    try {
      List<WifiNetwork> networks = await WiFiForIoTPlugin.loadWifiList();

      // Filter for telescope networks (starting with "Tele_")
      for (var network in networks) {
        if (network.ssid != null && network.ssid!.startsWith('Tele_')) {
          telescopeNetworks.add(network.ssid!);
        }
      }
    } catch (e) {
      print('Error scanning networks: $e');
    }
    return telescopeNetworks;
  }

  Future<bool> connectToNetwork(String ssid, String password) async {
    try {
      bool result = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
      );

      if (result) {
        _isConnected = true;
        _connectedNetwork = ssid;
      }
      return result;
    } catch (e) {
      print('Error connecting to network: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await WiFiForIoTPlugin.disconnect();
      _isConnected = false;
      _connectedNetwork = '';
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }
}
