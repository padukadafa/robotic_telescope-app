import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';

class WiFiManager {
  bool _isConnected = false;
  String _connectedNetwork = '';

  bool get isConnected => _isConnected;
  String get connectedNetwork => _connectedNetwork;

  Future<bool> _requestPermissions() async {
    // Request location permission (required for WiFi scanning on Android)
    var locationStatus = await Permission.location.request();

    if (locationStatus != PermissionStatus.granted) {
      return false;
    }

    return true;
  }

  Future<List<String>> scanForTelescopes() async {
    List<String> telescopeNetworks = [];

    try {
      // Check if permissions are granted
      if (!await _requestPermissions()) {
        return telescopeNetworks;
      }

      // Check if WiFi scan is supported
      final canStartScan = await WiFiScan.instance.canStartScan();
      if (canStartScan != CanStartScan.yes) {
        return telescopeNetworks;
      }

      // Start scan
      final scanResult = await WiFiScan.instance.startScan();
      if (scanResult) {
        // Wait a bit for scan to complete
        await Future.delayed(const Duration(seconds: 3));

        // Get scan results
        final accessPoints = await WiFiScan.instance.getScannedResults();

        // Filter for telescope networks
        for (var ap in accessPoints) {
          final ssid = ap.ssid;
          if (ssid.isNotEmpty) {
            // Look for telescope networks (RoboticTelescope or starting with "Tele_")
            if (ssid == 'RoboticTelescope' ||
                ssid.startsWith('Tele_') ||
                ssid.toLowerCase().contains('telescope')) {
              telescopeNetworks.add(ssid);
            }
          }
        }
      } else {}
    } catch (e) {}

    return telescopeNetworks;
  }

  Future<bool> connectToNetwork(String ssid, String password) async {
    try {
      // Note: wifi_scan plugin doesn't support connection
      // For connection, we need to guide user to connect manually
      // or use platform-specific methods

      // For now, we'll simulate connection success
      // In a real app, you'd check connectivity status
      await Future.delayed(const Duration(seconds: 2));

      _isConnected = true;
      _connectedNetwork = ssid;

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      // Note: wifi_scan doesn't support disconnection
      // User needs to disconnect manually or use platform-specific methods

      _isConnected = false;
      _connectedNetwork = '';
    } catch (e) {}
  }
}
