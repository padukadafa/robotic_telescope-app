import 'package:flutter/material.dart';

/// Movement Status Card Widget
///
/// A presentation widget that displays telescope movement status including:
/// - Current movement state (moving, stationary, or calibrating)
/// - Movement progress for ongoing operations
/// - Target position information
/// - Movement speed and acceleration settings
///
/// This is a pure UI widget that follows clean architecture principles.
/// It receives movement data through parameters instead of directly
/// accessing providers, making it more testable and reusable.
class MovementStatusCard extends StatelessWidget {
  /// Whether the telescope is currently moving
  final bool isMoving;

  /// Current movement status description
  final String movementStatus;

  /// Progress of current movement (0.0 to 1.0)
  final double progress;

  /// Current movement speed as a percentage
  final int movementSpeed;

  /// Target azimuth position (optional)
  final double? targetAzimuth;

  /// Target elevation position (optional)
  final double? targetElevation;

  /// Estimated time remaining for movement (in seconds)
  final int? estimatedTimeRemaining;

  const MovementStatusCard({
    super.key,
    required this.isMoving,
    required this.movementStatus,
    required this.progress,
    required this.movementSpeed,
    this.targetAzimuth,
    this.targetElevation,
    this.estimatedTimeRemaining,
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
                    color: (isMoving ? Colors.orange : Colors.blue).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isMoving ? Icons.directions_run : Icons.pause_circle_filled,
                    color: isMoving ? Colors.orange : Colors.blue,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Movement Status',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        movementStatus,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (isMoving ? Colors.orange : Colors.green).withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMoving ? Colors.orange : Colors.green,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    isMoving ? 'Moving' : 'Stationary',
                    style: TextStyle(
                      color: isMoving ? Colors.orange : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Movement Details
            Column(
              children: [
                _buildDetailRow(
                  context,
                  'Status',
                  movementStatus,
                  isMoving ? Icons.play_arrow : Icons.check,
                  color: isMoving ? Colors.orange : Colors.green,
                ),
                if (targetAzimuth != null || targetElevation != null)
                  _buildDetailRow(
                    context,
                    'Target Position',
                    '${targetAzimuth?.toStringAsFixed(1) ?? 'N/A'}°, ${targetElevation?.toStringAsFixed(1) ?? 'N/A'}°',
                    Icons.my_location,
                  ),
                _buildDetailRow(
                  context,
                  'Movement Speed',
                  '$movementSpeed%',
                  Icons.speed,
                ),
                if (estimatedTimeRemaining != null)
                  _buildDetailRow(
                    context,
                    'Time Remaining',
                    '${estimatedTimeRemaining}s',
                    Icons.schedule,
                  ),
              ],
            ),

            // Progress Indicator (only show when moving)
            if (isMoving && progress > 0) ...[
              const SizedBox(height: 16),
              _buildProgressIndicator(context),
            ],
          ],
        ),
      ),
    );
  }

  /// Builds a detail row with label, value, and icon
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
                  .withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
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
                ).colorScheme.onSurface.withValues(alpha: 0.7),
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

  /// Builds the progress indicator for movement tracking
  Widget _buildProgressIndicator(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }
}
