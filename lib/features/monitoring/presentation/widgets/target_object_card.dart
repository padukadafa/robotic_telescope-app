import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';

class TargetObjectCard extends StatelessWidget {
  const TargetObjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ObjectProvider>(
      builder: (context, objectProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
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
                        color:
                            (objectProvider.selectedObject != null
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey)
                                .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.star,
                        color: objectProvider.selectedObject != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target Object',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            objectProvider.selectedObject?.name ??
                                'No object selected',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (objectProvider.selectedObject != null) ...[
                  _buildDetailRow(
                    context,
                    'Type',
                    objectProvider.selectedObject!.type,
                    _getObjectIcon(objectProvider.selectedObject!.type),
                  ),
                  _buildDetailRow(
                    context,
                    'Right Ascension',
                    '${objectProvider.selectedObject!.ra.toStringAsFixed(2)}°',
                    Icons.explore,
                  ),
                  _buildDetailRow(
                    context,
                    'Declination',
                    '${objectProvider.selectedObject!.dec.toStringAsFixed(2)}°',
                    Icons.north,
                  ),
                ] else ...[
                  _buildDetailRow(
                    context,
                    'Status',
                    'No target selected',
                    Icons.info_outline,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

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
                  .withOpacity(0.1),
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
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
}
