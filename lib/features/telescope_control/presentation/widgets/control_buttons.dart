import 'package:flutter/material.dart';

/// Control Buttons Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Handles UI rendering and user interactions
/// - No business logic or state management
/// - Receives state and callbacks from parent widgets
/// - Focuses only on visual representation
class ControlButtons extends StatelessWidget {
  /// Whether telescope is connected
  final bool isConnected;

  /// Callbacks for control actions
  final VoidCallback? onSlewUp;
  final VoidCallback? onSlewDown;
  final VoidCallback? onSlewLeft;
  final VoidCallback? onSlewRight;
  final VoidCallback? onStop;

  /// Optional title override
  final String? title;

  /// Step size for slewing operations
  final int stepSize;

  const ControlButtons({
    super.key,
    required this.isConnected,
    this.onSlewUp,
    this.onSlewDown,
    this.onSlewLeft,
    this.onSlewRight,
    this.onStop,
    this.title,
    this.stepSize = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            title ?? 'Manual Control',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          // Up button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                context,
                Icons.arrow_upward,
                onSlewUp,
                Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Left, Stop, Right buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                context,
                Icons.arrow_back,
                onSlewLeft,
                Colors.orange,
              ),
              const SizedBox(width: 32),
              _buildControlButton(
                context,
                Icons.stop,
                onStop,
                Colors.red,
                size: 60,
              ),
              const SizedBox(width: 32),
              _buildControlButton(
                context,
                Icons.arrow_forward,
                onSlewRight,
                Colors.orange,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Down button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                context,
                Icons.arrow_downward,
                onSlewDown,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds individual control button with proper styling
  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    VoidCallback? onPressed,
    Color color, {
    double size = 50,
  }) {
    final isEnabled = isConnected && onPressed != null;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isEnabled
              ? [color.withValues(alpha: 0.8), color]
              : [
                  Colors.grey.withValues(alpha: 0.4),
                  Colors.grey.withValues(alpha: 0.6),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
          size: size * 0.4,
        ),
        onPressed: isEnabled ? onPressed : null,
      ),
    );
  }
}
