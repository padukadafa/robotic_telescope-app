import 'package:flutter/material.dart';

/// Connection Status Card Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Displays connection status information
/// - No business logic or state management
/// - Receives connection data from parent widgets
/// - Focuses only on visual representation of connection state
class ConnectionStatusCard extends StatelessWidget {
  /// Whether WiFi is connected
  final bool isConnected;

  /// Connected WiFi network name
  final String connectedNetwork;

  /// Whether telescope WebSocket is connected
  final bool telescopeConnected;

  /// Telescope IP address
  final String telescopeIp;

  /// Signal strength description
  final String signalStrength;

  const ConnectionStatusCard({
    super.key,
    required this.isConnected,
    required this.connectedNetwork,
    required this.telescopeConnected,
    required this.telescopeIp,
    required this.signalStrength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isConnected ? Colors.green : Colors.red).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.wifi,
                    color: isConnected ? Colors.green : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connection Status',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isConnected
                            ? 'Connected to $connectedNetwork'
                            : 'Not Connected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              'WiFi Network',
              isConnected ? connectedNetwork : 'None',
              Icons.router,
            ),
            _buildDetailRow(
              context,
              'Telescope WebSocket',
              telescopeConnected ? 'Connected ($telescopeIp)' : 'Disconnected',
              telescopeConnected ? Icons.wifi : Icons.wifi_off,
              color: telescopeConnected ? Colors.green : Colors.red,
            ),
            _buildDetailRow(
              context,
              'Signal Strength',
              isConnected ? signalStrength : 'N/A',
              Icons.signal_wifi_4_bar,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds detail row with icon, label, and value
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Theme.of(context).colorScheme.primary)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
