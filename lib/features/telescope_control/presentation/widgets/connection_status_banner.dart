import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: telescopeProvider.isConnected
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: telescopeProvider.isConnected
                  ? Colors.green.withOpacity(0.3)
                  : Colors.red.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                telescopeProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                color: telescopeProvider.isConnected
                    ? Colors.green
                    : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                telescopeProvider.isConnected
                    ? 'Connected to Telescope'
                    : 'Not Connected to Telescope',
                style: TextStyle(
                  color: telescopeProvider.isConnected
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
