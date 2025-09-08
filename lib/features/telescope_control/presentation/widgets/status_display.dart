import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class StatusDisplay extends StatelessWidget {
  const StatusDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatusItem(
                context,
                'Azimuth',
                '${telescopeProvider.azimuth.toStringAsFixed(1)}°',
                Icons.explore,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              _buildStatusItem(
                context,
                'Elevation',
                '${telescopeProvider.elevation.toStringAsFixed(1)}°',
                Icons.north,
              ),
              Container(
                width: 1,
                height: 40,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              _buildStatusItem(
                context,
                'Status',
                telescopeProvider.isMoving ? 'Moving' : 'Stopped',
                telescopeProvider.isMoving ? Icons.directions_run : Icons.stop,
                color: telescopeProvider.isMoving ? Colors.green : Colors.red,
              ),
            ],
          ),
        );
      },
    );
  }

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
              color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
