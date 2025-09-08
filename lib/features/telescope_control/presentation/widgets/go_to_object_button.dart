import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/core/models/astronomical_object.dart';

class GoToObjectButton extends StatefulWidget {
  final AstronomicalObject selectedObject;

  const GoToObjectButton({super.key, required this.selectedObject});

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
  void dispose() {
    _moveAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TelescopeProvider, ObjectProvider>(
      builder: (context, telescopeProvider, objectProvider, child) {
        return AnimatedBuilder(
          animation: _moveAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: telescopeProvider.isMoving ? _moveAnimation.value : 1.0,
              child: Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      telescopeProvider.isMoving ||
                          !telescopeProvider.isConnected
                      ? null
                      : () {
                          _moveAnimationController.forward().then(
                            (_) => _moveAnimationController.reverse(),
                          );
                          telescopeProvider.moveTo(
                            widget.selectedObject.ra * 15,
                            widget.selectedObject.dec,
                          );
                        },
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
                        Icons.gps_fixed,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Go To ${widget.selectedObject.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
