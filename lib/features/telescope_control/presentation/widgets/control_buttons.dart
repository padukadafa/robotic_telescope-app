import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class ControlButtons extends StatelessWidget {
  const ControlButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Text(
                'Manual Control',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    context,
                    Icons.arrow_upward,
                    telescopeProvider.isConnected
                        ? () => telescopeProvider.slewUp(steps: 50)
                        : () {},
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    context,
                    Icons.arrow_back,
                    telescopeProvider.isConnected
                        ? () => telescopeProvider.slewLeft(steps: 50)
                        : () {},
                    Colors.orange,
                  ),
                  const SizedBox(width: 32),
                  _buildControlButton(
                    context,
                    Icons.stop,
                    telescopeProvider.isConnected
                        ? telescopeProvider.stop
                        : () {},
                    Colors.red,
                    size: 60,
                  ),
                  const SizedBox(width: 32),
                  _buildControlButton(
                    context,
                    Icons.arrow_forward,
                    telescopeProvider.isConnected
                        ? () => telescopeProvider.slewRight(steps: 50)
                        : () {},
                    Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildControlButton(
                    context,
                    Icons.arrow_downward,
                    telescopeProvider.isConnected
                        ? () => telescopeProvider.slewDown(steps: 50)
                        : () {},
                    Colors.green,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    VoidCallback onPressed,
    Color color, {
    double size = 50,
  }) {
    return Consumer<TelescopeProvider>(
      builder: (context, telescopeProvider, child) {
        final isEnabled = telescopeProvider.isConnected && onPressed != (() {});
        return GestureDetector(
          onTapDown: (_) {},
          onTapUp: (_) {},
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isEnabled
                    ? [color.withOpacity(0.8), color]
                    : [
                        Colors.grey.withOpacity(0.4),
                        Colors.grey.withOpacity(0.6),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: IconButton(
              icon: Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.white.withOpacity(0.5),
                size: size * 0.4,
              ),
              onPressed: isEnabled ? onPressed : null,
            ),
          ),
        );
      },
    );
  }
}
