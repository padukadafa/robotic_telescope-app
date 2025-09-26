import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

/// Go To Object Button Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Handles go-to object UI and animations
/// - No business logic or state management
/// - Receives object data and callbacks from parent widgets
/// - Focuses only on visual representation and animations
class GoToObjectButton extends StatefulWidget {
  /// The selected astronomical object to go to
  final AstronomicalObject selectedObject;

  /// Whether telescope is currently moving
  final bool isMoving;

  /// Whether telescope is connected
  final bool isConnected;

  /// Callback when go-to button is pressed
  final VoidCallback? onGoTo;

  const GoToObjectButton({
    super.key,
    required this.selectedObject,
    required this.isMoving,
    required this.isConnected,
    this.onGoTo,
  });

  @override
  State<GoToObjectButton> createState() => _GoToObjectButtonState();
}

class _GoToObjectButtonState extends State<GoToObjectButton>
    with TickerProviderStateMixin {
  late AnimationController _moveAnimationController;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _moveAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _moveAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _moveAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void didUpdateWidget(GoToObjectButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start animation when moving starts
    if (!oldWidget.isMoving && widget.isMoving) {
      _moveAnimationController.forward();
    }
    // Stop animation when moving stops
    if (oldWidget.isMoving && !widget.isMoving) {
      _moveAnimationController.reverse();
    }
  }

  @override
  void dispose() {
    _moveAnimationController.dispose();
    super.dispose();
  }

  void _handleGoTo() {
    if (widget.onGoTo != null) {
      // Start animation before calling callback
      _moveAnimationController.forward().then(
        (_) => _moveAnimationController.reverse(),
      );
      widget.onGoTo!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled =
        !widget.isMoving && widget.isConnected && widget.onGoTo != null;

    return AnimatedBuilder(
      animation: _moveAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isMoving ? _moveAnimation.value : 1.0,
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey.withValues(alpha: 0.4),
                        Colors.grey.withValues(alpha: 0.6),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: isEnabled ? _handleGoTo : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.isMoving ? Icons.sync : Icons.gps_fixed,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.onPrimary
                        : Colors.white.withValues(alpha: 0.5),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    widget.isMoving
                        ? 'Moving to ${widget.selectedObject.name}...'
                        : 'Go To ${widget.selectedObject.name}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isEnabled
                          ? Theme.of(context).colorScheme.onPrimary
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
