import 'package:flutter/material.dart';

class IPSettingsDialog extends StatelessWidget {
  final TextEditingController ipController;
  final TextEditingController portController;
  final VoidCallback onScanQR;
  final Function(String ip, String port) onSave;

  const IPSettingsDialog({
    super.key,
    required this.ipController,
    required this.portController,
    required this.onScanQR,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Camera IP Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: ipController,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              hintText: '192.168.4.50',
              prefixIcon: Icon(Icons.computer),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '81',
              prefixIcon: Icon(Icons.settings_ethernet),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onScanQR();
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan QR'),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final ip = ipController.text.trim();
            final port = portController.text.trim();
            if (ip.isNotEmpty && port.isNotEmpty) {
              onSave(ip, port);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
