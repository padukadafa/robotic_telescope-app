import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConnectionHelper {
  /// Shows a dialog to guide user for manual WiFi connection
  static Future<bool> showWiFiConnectionGuide(
    BuildContext context,
    String ssid,
    String password,
  ) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.blue),
              SizedBox(width: 8),
              Text('Connect to WiFi'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please follow these steps to connect to the telescope:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Step 1
              const Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Text(
                      '1',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Open your device WiFi settings'),
                ],
              ),
              const SizedBox(height: 8),

              // Step 2
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Text(
                      '2',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Connect to: '),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          ssid,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: ssid));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Network name copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Step 3
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Text(
                      '3',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Use password: '),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          password,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 16),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: password));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'After connecting, return to this app and tap "I\'m Connected"',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("I'm Connected"),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  /// Shows a dialog with telescope connection instructions
  static Future<void> showTelescopeSetupGuide(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.satellite_alt, color: Colors.purple),
              SizedBox(width: 8),
              Text('Telescope Setup'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Follow these steps to set up your telescope:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                _GuideStep(
                  number: '1',
                  title: 'Power on your ESP32 telescope controller',
                  description:
                      'Make sure your ESP32 is powered and running the telescope firmware.',
                ),

                _GuideStep(
                  number: '2',
                  title: 'Look for WiFi network',
                  description:
                      'The telescope should create a WiFi hotspot named "RoboticTelescope".',
                ),

                _GuideStep(
                  number: '3',
                  title: 'Scan for networks',
                  description:
                      'Tap "Scan for Telescopes" to find available telescope networks.',
                ),

                _GuideStep(
                  number: '4',
                  title: 'Connect and control',
                  description:
                      'Select your telescope network and start controlling!',
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it!'),
            ),
          ],
        );
      },
    );
  }
}

class _GuideStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _GuideStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.purple,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
