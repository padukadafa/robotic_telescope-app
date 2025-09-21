import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class FineTuningControls extends StatelessWidget {
  const FineTuningControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        if (!telescopeProvider.isInFineTuningMode) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header with status
              Row(
                children: [
                  Icon(
                    Icons.tune,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fine-Tuning Mode',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        Text(
                          'Adjust telescope position for precise targeting',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: telescopeProvider.exitFineTuningMode,
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Step size selector
              Row(
                children: [
                  Text(
                    'Step Size:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        _buildStepSizeButton(
                          context,
                          telescopeProvider,
                          5,
                          'Fine',
                        ),
                        const SizedBox(width: 8),
                        _buildStepSizeButton(
                          context,
                          telescopeProvider,
                          10,
                          'Medium',
                        ),
                        const SizedBox(width: 8),
                        _buildStepSizeButton(
                          context,
                          telescopeProvider,
                          20,
                          'Coarse',
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Fine-tuning control pad
              Column(
                children: [
                  // Up button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFineTuningButton(
                        context,
                        Icons.keyboard_arrow_up,
                        telescopeProvider.isConnected
                            ? () => telescopeProvider.fineTuneUp()
                            : () {},
                        'Up',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Left, Center, Right buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFineTuningButton(
                        context,
                        Icons.keyboard_arrow_left,
                        telescopeProvider.isConnected
                            ? () => telescopeProvider.fineTuneLeft()
                            : () {},
                        'Left',
                      ),

                      // Center position button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                          ),
                        ),
                        child: IconButton(
                          onPressed: telescopeProvider.isConnected
                              ? telescopeProvider.confirmFineTuning
                              : null,
                          icon: Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          tooltip: 'Confirm Position',
                        ),
                      ),

                      _buildFineTuningButton(
                        context,
                        Icons.keyboard_arrow_right,
                        telescopeProvider.isConnected
                            ? () => telescopeProvider.fineTuneRight()
                            : () {},
                        'Right',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Down button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildFineTuningButton(
                        context,
                        Icons.keyboard_arrow_down,
                        telescopeProvider.isConnected
                            ? () => telescopeProvider.fineTuneDown()
                            : () {},
                        'Down',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: telescopeProvider.exitFineTuningMode,
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: telescopeProvider.isConnected
                          ? telescopeProvider.confirmFineTuning
                          : null,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepSizeButton(
    BuildContext context,
    TelescopeProvider provider,
    int stepSize,
    String label,
  ) {
    final isSelected = provider.fineTuningStepSize == stepSize;

    return Expanded(
      child: GestureDetector(
        onTap: () => provider.setFineTuningStepSize(stepSize),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                '${stepSize}°',
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.8)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFineTuningButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    String tooltip,
  ) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        final isEnabled = telescopeProvider.isConnected;

        return Tooltip(
          message: tooltip,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled
                  ? Theme.of(context).colorScheme.secondaryContainer
                  : Theme.of(context).colorScheme.surface.withOpacity(0.5),
              border: Border.all(
                color: isEnabled
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.secondary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              onPressed: isEnabled ? onPressed : null,
              icon: Icon(
                icon,
                color: isEnabled
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                size: 24,
              ),
            ),
          ),
        );
      },
    );
  }
}
