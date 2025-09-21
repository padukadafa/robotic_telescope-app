import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class PositionAccuracyIndicator extends StatelessWidget {
  const PositionAccuracyIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        // Only show if we have a target position
        if (telescopeProvider.targetAzimuth == null ||
            telescopeProvider.targetElevation == null) {
          return const SizedBox.shrink();
        }

        final accuracy = telescopeProvider.getPositionAccuracy();
        final isAccurate = telescopeProvider.isPositionAccurate();

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getAccuracyColor(isAccurate, context).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getAccuracyColor(isAccurate, context).withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getAccuracyIcon(isAccurate),
                    color: _getAccuracyColor(isAccurate, context),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Position Accuracy',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getAccuracyColor(isAccurate, context),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getAccuracyColor(isAccurate, context),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isAccurate ? 'GOOD' : 'ADJUST',
                      style: TextStyle(
                        color:
                            _getAccuracyColor(isAccurate, context) ==
                                Colors.green
                            ? Colors.white
                            : Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Accuracy details
              Row(
                children: [
                  Expanded(
                    child: _buildAccuracyDetail(
                      context,
                      'Current',
                      '${telescopeProvider.azimuth.toStringAsFixed(1)}°, ${telescopeProvider.elevation.toStringAsFixed(1)}°',
                      Icons.my_location,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildAccuracyDetail(
                      context,
                      'Target',
                      '${telescopeProvider.targetAzimuth!.toStringAsFixed(1)}°, ${telescopeProvider.targetElevation!.toStringAsFixed(1)}°',
                      Icons.flag,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Accuracy bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accuracy Score',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '${_getAccuracyPercentage(accuracy).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getAccuracyColor(isAccurate, context),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withOpacity(0.2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _getAccuracyPercentage(accuracy) / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          gradient: LinearGradient(
                            colors: [
                              _getAccuracyColor(
                                isAccurate,
                                context,
                              ).withOpacity(0.8),
                              _getAccuracyColor(isAccurate, context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (!isAccurate) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fine-tuning recommended for better accuracy',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccuracyDetail(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAccuracyColor(bool isAccurate, BuildContext context) {
    return isAccurate ? Colors.green : Colors.orange;
  }

  IconData _getAccuracyIcon(bool isAccurate) {
    return isAccurate ? Icons.check_circle : Icons.adjust;
  }

  double _getAccuracyPercentage(double accuracy) {
    // Convert accuracy score to percentage (lower accuracy score = higher percentage)
    // Max accuracy considered is 10.0 degrees difference
    final maxAccuracy = 10.0;
    final percentage = ((maxAccuracy - accuracy) / maxAccuracy * 100).clamp(
      0.0,
      100.0,
    );
    return percentage;
  }
}
