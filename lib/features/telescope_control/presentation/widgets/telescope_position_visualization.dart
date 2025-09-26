import 'package:flutter/material.dart';
import 'dart:math';

/// Telescope Position Visualization Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Displays azimuth position visualization with compass
/// - No business logic or state management
/// - Receives position data from parent widgets
/// - Focuses only on visual representation of telescope position
class TelescopePositionVisualization extends StatelessWidget {
  /// Current azimuth position in degrees
  final double azimuth;

  /// Current elevation position in degrees
  final double elevation;

  /// Optional title override
  final String? title;

  const TelescopePositionVisualization({
    super.key,
    required this.azimuth,
    required this.elevation,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Compass markings
          ..._buildCompassMarkings(context),

          // Telescope pointer
          Transform.rotate(
            angle: (azimuth * pi / 180),
            child: Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),

          // Center point
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Elevation indicator
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
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

          if (title != null)
            Positioned(
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  title!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Builds compass markings with cardinal directions
  List<Widget> _buildCompassMarkings(BuildContext context) {
    final markings = <Widget>[];
    for (int i = 0; i < 360; i += 45) {
      final angle = i * pi / 180;
      final isMainDirection = i % 90 == 0;
      final length = isMainDirection ? 20.0 : 10.0;

      markings.add(
        Transform.rotate(
          angle: angle,
          child: Container(
            width: 2,
            height: length,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
            margin: EdgeInsets.only(top: 140 - length / 2),
          ),
        ),
      );

      if (isMainDirection) {
        final direction = _getDirectionLabel(i);
        markings.add(
          Transform.rotate(
            angle: angle,
            child: Container(
              margin: const EdgeInsets.only(top: 120),
              child: Text(
                direction,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    return markings;
  }

  /// Gets cardinal direction label for degree
  String _getDirectionLabel(int degrees) {
    switch (degrees) {
      case 0:
        return 'N';
      case 90:
        return 'E';
      case 180:
        return 'S';
      case 270:
        return 'W';
      default:
        return '';
    }
  }
}
