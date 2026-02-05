import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServerInfoDialog extends StatelessWidget {
  final String serverIpAddress;
  final int serverPort;

  const ServerInfoDialog({
    super.key,
    required this.serverIpAddress,
    required this.serverPort,
  });

  @override
  Widget build(BuildContext context) {
    final serverUrl = 'http://$serverIpAddress:$serverPort';

    return AlertDialog(
      title: const Text('Camera Server Info'),
      content: SizedBox(
        width: 280,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan this QR code from another device:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                width: 232,
                height: 232,
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: QrImageView(
                  data: serverUrl,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                serverUrl,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'IP: $serverIpAddress',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                'Port: $serverPort',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
