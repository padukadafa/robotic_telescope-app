import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

class ObjectListItem extends StatelessWidget {
  final AstronomicalObject object;
  final bool isSelected;
  final VoidCallback onTap;
  final double? observerLatitude;
  final double? observerLongitude;
  final bool isAboveHorizon;
  final double? altitudeDeg;

  const ObjectListItem({
    super.key,
    required this.object,
    required this.isSelected,
    required this.onTap,
    this.observerLatitude,
    this.observerLongitude,
    this.isAboveHorizon = true,
    this.altitudeDeg,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: isAboveHorizon ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getObjectColor(object.type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getObjectIcon(object.type),
                  color: _getObjectColor(object.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Object name
                    Text(
                      object.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isAboveHorizon
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description (spectral type, magnitude, constellation)
                    if (object.description.isNotEmpty)
                      Text(
                        object.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface
                              .withValues(alpha: isAboveHorizon ? 0.7 : 0.3),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // Coordinates and additional info
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          context,
                          'RA: ${object.ra.toStringAsFixed(2)}°',
                          Icons.explore,
                        ),
                        _buildInfoChip(
                          context,
                          'Dec: ${object.dec.toStringAsFixed(2)}°',
                          Icons.north,
                        ),
                        if (altitudeDeg != null)
                          _buildInfoChip(
                            context,
                            'Alt: ${altitudeDeg!.toStringAsFixed(1)}°',
                            Icons.alt_route,
                          ),
                        if (object.mag != null)
                          _buildInfoChip(
                            context,
                            'Mag: ${object.mag!.toStringAsFixed(2)}',
                            Icons.brightness_5,
                          ),
                        if (object.dist != null)
                          _buildInfoChip(
                            context,
                            '${object.dist!.toStringAsFixed(1)} pc',
                            Icons.straighten,
                          ),
                        if (!isAboveHorizon)
                          _buildInfoChip(
                            context,
                            'Di bawah horizon',
                            Icons.visibility_off,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getObjectColor(ObjectType type) {
    switch (type) {
      case ObjectType.deepSky:
        return Colors.yellow.shade700;
      case ObjectType.solarSystem:
        return Colors.orange;
    }
  }

  IconData _getObjectIcon(ObjectType type) {
    switch (type) {
      case ObjectType.deepSky:
        return Icons.star;
      case ObjectType.solarSystem:
        return Icons.public;
    }
  }

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
