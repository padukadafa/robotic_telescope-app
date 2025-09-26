import 'package:flutter/material.dart';

/// Connection Status Banner Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Displays connection status UI banner
/// - No business logic or state management
/// - Receives connection state from parent widgets
/// - Focuses only on visual representation of connection status
class ConnectionStatusBanner extends StatelessWidget {
  /// Whether telescope is connected
  final bool isConnected;

  /// Optional custom message
  final String? message;

  /// Optional callback when banner is tapped
  final VoidCallback? onTap;

  const ConnectionStatusBanner({
    super.key,
    required this.isConnected,
    this.message,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? Colors.green : Colors.red;
    final defaultMessage = isConnected
        ? 'Connected to Telescope'
        : 'Not Connected to Telescope';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              message ?? defaultMessage,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.info_outline,
                color: color.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
