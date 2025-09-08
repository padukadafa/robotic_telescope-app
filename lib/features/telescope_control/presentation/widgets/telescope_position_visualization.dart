import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'dart:math';

class TelescopePositionVisualization extends StatelessWidget {
  const TelescopePositionVisualization({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        return Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
                Theme.of(context).colorScheme.surface.withOpacity(0.4),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
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
                angle: (telescopeProvider.azimuth * pi / 180),
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
                        ).colorScheme.primary.withOpacity(0.5),
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
                      ).colorScheme.primary.withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Elevation indicator
              Positioned(
                bottom: 60,
                right: 60,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    '${telescopeProvider.elevation.toStringAsFixed(1)}°',
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
        );
      },
    );
  }

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
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
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
                  ).colorScheme.onSurface.withOpacity(0.7),
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
