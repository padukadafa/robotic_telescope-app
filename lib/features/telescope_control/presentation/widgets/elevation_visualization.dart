import 'package:flutter/material.dart';

/// Elevation Visualization Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Displays elevation position with gauge visualization
/// - No business logic or state management
/// - Receives elevation data from parent widgets
/// - Focuses only on visual representation of elevation angle
class ElevationVisualization extends StatelessWidget {
  /// Current elevation position in degrees
  final double elevation;

  /// Optional title override
  final String? title;

  const ElevationVisualization({
    super.key,
    required this.elevation,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Icon(
              Icons.height,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title ?? 'Elevation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Elevation Gauge
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.2),
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),

              // Degree markings
              ..._buildDegreeMarkings(context),

              // Elevation indicator
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: (elevation / 90) * 140,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Current elevation line
              Positioned(
                bottom: (elevation / 90) * 140 - 2,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),

              // Elevation value display
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${elevation.toStringAsFixed(1)}°',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: _getElevationColor(
              elevation,
              context,
            ).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _getElevationColor(
                elevation,
                context,
              ).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getElevationIcon(elevation),
                color: _getElevationColor(elevation, context),
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getElevationStatus(elevation),
                  style: TextStyle(
                    color: _getElevationColor(elevation, context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds degree markings for the elevation gauge
  List<Widget> _buildDegreeMarkings(BuildContext context) {
    final markings = <Widget>[];
    for (int degree = 0; degree <= 90; degree += 15) {
      final position = (degree / 90) * 140;

      markings.add(
        Positioned(
          bottom: position - 6,
          left: 6,
          child: Text(
            '${degree}°',
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      // Degree line
      markings.add(
        Positioned(
          bottom: position,
          left: 24,
          right: 6,
          child: Container(
            height: 1,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
      );
    }
    return markings;
  }

  /// Gets color based on elevation range
  Color _getElevationColor(double elevation, BuildContext context) {
    if (elevation < 15) {
      return Colors.blue; // Low elevation
    } else if (elevation < 45) {
      return Colors.green; // Optimal elevation
    } else if (elevation < 75) {
      return Colors.orange; // High elevation
    } else {
      return Colors.red; // Very high elevation
    }
  }

  /// Gets icon based on elevation range
  IconData _getElevationIcon(double elevation) {
    if (elevation < 15) {
      return Icons.arrow_downward;
    } else if (elevation < 45) {
      return Icons.check_circle;
    } else if (elevation < 75) {
      return Icons.arrow_upward;
    } else {
      return Icons.warning;
    }
  }

  /// Gets status message based on elevation range
  String _getElevationStatus(double elevation) {
    if (elevation < 15) {
      return 'Low elevation - Limited visibility';
    } else if (elevation < 45) {
      return 'Optimal elevation range';
    } else if (elevation < 75) {
      return 'High elevation - Good visibility';
    } else {
      return 'Very high elevation - Maximum visibility';
    }
  }
}
