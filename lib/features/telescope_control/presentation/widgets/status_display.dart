import 'package:flutter/material.dart';

/// Status Display Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Displays telescope status information
/// - No business logic or state management
/// - Receives status data from parent widgets
/// - Focuses only on visual representation of telescope state
class StatusDisplay extends StatelessWidget {
  /// Current azimuth angle in degrees
  final double azimuth;

  /// Current elevation angle in degrees
  final double elevation;

  /// Whether telescope is currently moving
  final bool isMoving;

  /// Optional title override
  final String? title;

  const StatusDisplay({
    super.key,
    required this.azimuth,
    required this.elevation,
    required this.isMoving,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusItem(
                context,
                'Azimuth',
                '${azimuth.toStringAsFixed(1)}°',
                Icons.explore,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
              _buildStatusItem(
                context,
                'Elevation',
                '${elevation.toStringAsFixed(1)}°',
                Icons.north,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
              _buildStatusItem(
                context,
                'Status',
                isMoving ? 'Moving' : 'Stopped',
                isMoving ? Icons.directions_run : Icons.stop,
                color: isMoving ? Colors.green : Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds individual status item with proper styling
  Widget _buildStatusItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color:
              color ??
              Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color ?? Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
