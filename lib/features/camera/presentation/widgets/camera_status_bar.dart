import 'package:flutter/material.dart';

class CameraStatusBar extends StatelessWidget {
  final bool isServerMode;
  final bool isConnected;
  final bool hasError;
  final String displayText;
  final VoidCallback onTap;

  const CameraStatusBar({
    super.key,
    required this.isServerMode,
    required this.isConnected,
    required this.hasError,
    required this.displayText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.videocam,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isServerMode ? 'Camera Server' : 'ESP32-CAM',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isServerMode
                  ? Colors.green
                  : (hasError
                        ? Colors.red
                        : (isConnected ? Colors.green : Colors.orange)),
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Row(
              children: [
                Text(
                  displayText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
