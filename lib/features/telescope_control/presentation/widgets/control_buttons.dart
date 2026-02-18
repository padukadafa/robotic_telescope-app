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

  /// Whether hold position is active
  final bool isHoldingPosition;

  /// Callbacks for control actions
  final VoidCallback? onSlewUp;
  final VoidCallback? onSlewDown;
  final VoidCallback? onSlewLeft;
  final VoidCallback? onSlewRight;
  final VoidCallback? onStop;
  final VoidCallback? onHoldPosition;

  /// Optional title override
  final String? title;

  /// Step size for slewing operations
  final int stepSize;

  const ControlButtons({
    super.key,
    required this.isConnected,
    this.isHoldingPosition = false,
    this.onSlewUp,
    this.onSlewDown,
    this.onSlewLeft,
    this.onSlewRight,
    this.onStop,
    this.onHoldPosition,
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
                stopsOnRelease: true,
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
                stopsOnRelease: true,
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
                stopsOnRelease: true,
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
                stopsOnRelease: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Hold Position button
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [_buildHoldPositionButton(context)],
          // ),
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
    bool stopsOnRelease = false,
  }) {
    final isEnabled = isConnected && onPressed != null;

    return GestureDetector(
      onTapDown: isEnabled ? (_) => onPressed?.call() : null,
      onTapUp: isEnabled && stopsOnRelease ? (_) => onStop?.call() : null,
      onTapCancel: isEnabled && stopsOnRelease ? () => onStop?.call() : null,
      child: Container(
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
        child: Icon(
          icon,
          color: isEnabled ? Colors.white : Colors.white.withValues(alpha: 0.5),
          size: size * 0.4,
        ),
      ),
    );
  }

  /// Builds Hold Position button
  Widget _buildHoldPositionButton(BuildContext context) {
    final isEnabled = isConnected && onHoldPosition != null;
    final color = isHoldingPosition ? Colors.green : Colors.blue;
    final icon = isHoldingPosition ? Icons.lock : Icons.lock_open;
    final label = isHoldingPosition ? 'Holding Position' : 'Hold Position';

    return ElevatedButton.icon(
      onPressed: isEnabled ? onHoldPosition : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? color : Colors.grey,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: isEnabled ? 4 : 0,
      ),
    );
  }
}
