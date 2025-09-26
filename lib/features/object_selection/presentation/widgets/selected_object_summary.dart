import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

/// Selected Object Summary Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Displays selected astronomical object summary and navigation
/// - No business logic or state management
/// - Receives object data and callbacks from parent widgets
/// - Focuses only on visual representation of selected object
class SelectedObjectSummary extends StatelessWidget {
  /// The selected astronomical object to display
  final AstronomicalObject selectedObject;

  /// Callback when "Go To" button is pressed
  final VoidCallback? onGoToPressed;

  /// Optional button text override
  final String? buttonText;

  const SelectedObjectSummary({
    super.key,
    required this.selectedObject,
    this.onGoToPressed,
    this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getObjectIcon(selectedObject.type),
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Object',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onBackground,
                            ),
                      ),
                      Text(
                        selectedObject.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _buildInfoChip(
                            context,
                            selectedObject.type,
                            _getObjectIcon(selectedObject.type),
                          ),
                          _buildInfoChip(
                            context,
                            'RA: ${selectedObject.ra.toStringAsFixed(2)}°',
                            Icons.explore,
                          ),
                          _buildInfoChip(
                            context,
                            'Dec: ${selectedObject.dec.toStringAsFixed(2)}°',
                            Icons.north,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Go To Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: onGoToPressed != null
                    ? LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary,
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.withValues(alpha: 0.4),
                          Colors.grey.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: onGoToPressed != null
                    ? [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: onGoToPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.gps_fixed,
                      color: onGoToPressed != null
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white.withValues(alpha: 0.5),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      buttonText ?? 'Go To ${selectedObject.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: onGoToPressed != null
                            ? Theme.of(context).colorScheme.onPrimary
                            : Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: onGoToPressed != null
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets icon based on object type
  IconData _getObjectIcon(String type) {
    switch (type.toLowerCase()) {
      case 'star':
        return Icons.star;
      case 'galaxy':
        return Icons.blur_circular;
      case 'nebula':
        return Icons.cloud;
      case 'planet':
        return Icons.public;
      default:
        return Icons.help_outline;
    }
  }

  /// Builds info chip with icon and label
  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
