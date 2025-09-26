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
      print('Location permission denied');
      return false;
    }

    return true;
  }

  Future<List<String>> scanForTelescopes() async {
    List<String> telescopeNetworks = [];

    try {
      // Check if permissions are granted
      if (!await _requestPermissions()) {
        print('Required permissions not granted');
        return telescopeNetworks;
      }

      // Check if WiFi scan is supported
      final canStartScan = await WiFiScan.instance.canStartScan();
      if (canStartScan != CanStartScan.yes) {
        print('Cannot start WiFi scan: $canStartScan');
        return telescopeNetworks;
      }

      // Start scan
      final scanResult = await WiFiScan.instance.startScan();
      if (scanResult) {
        print('WiFi scan started successfully');

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

        print('Found ${telescopeNetworks.length} telescope networks');
      } else {
        print('Failed to start WiFi scan');
      }
    } catch (e) {
      print('Error scanning networks: $e');
    }

    return telescopeNetworks;
  }

  Future<bool> connectToNetwork(String ssid, String password) async {
    try {
      // Note: wifi_scan plugin doesn't support connection
      // For connection, we need to guide user to connect manually
      // or use platform-specific methods

      print(
        'Please connect to network "$ssid" manually through device settings',
      );
      print('Password: $password');

      // For now, we'll simulate connection success
      // In a real app, you'd check connectivity status
      await Future.delayed(const Duration(seconds: 2));

      _isConnected = true;
      _connectedNetwork = ssid;

      return true;
    } catch (e) {
      print('Error connecting to network: $e');
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      // Note: wifi_scan doesn't support disconnection
      // User needs to disconnect manually or use platform-specific methods

      _isConnected = false;
      _connectedNetwork = '';

      print('Please disconnect from WiFi manually through device settings');
    } catch (e) {
      print('Error disconnecting: $e');
    }
  }
}
