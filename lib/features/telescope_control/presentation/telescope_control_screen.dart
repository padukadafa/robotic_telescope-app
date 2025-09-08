import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'dart:math';

class TelescopeControlScreen extends StatefulWidget {
  const TelescopeControlScreen({super.key});

  @override
  State<TelescopeControlScreen> createState() => _TelescopeControlScreenState();
}

class _TelescopeControlScreenState extends State<TelescopeControlScreen>
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
      CurvedAnimation(parent: _moveAnimationController, curve: Curves.easeInOut),
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
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.control_camera,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Telescope Control',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Control your telescope movement',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Go To Object Button
                  if (objectProvider.selectedObject != null)
                    AnimatedBuilder(
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
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: telescopeProvider.isMoving
                                ? null
                                : () {
                                    _moveAnimationController.forward().then((_) =>
                                      _moveAnimationController.reverse());
                                    telescopeProvider.moveTo(
                                      objectProvider.selectedObject!.ra * 15,
                                      objectProvider.selectedObject!.dec,
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
                                    'Go To ${objectProvider.selectedObject!.name}',
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
                    ),

                  const SizedBox(height: 32),

                  // Telescope Position Visualization
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Theme.of(context).colorScheme.surface.withOpacity(0.8),
                              Theme.of(context).colorScheme.surface.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Compass markings
                            ..._buildCompassMarkings(context),

                            // Telescope pointer
                            Transform.rotate(
                              angle: (telescopeProvider.azimuth * pi / 180),
                              child: Container(
                                width: 6,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Center point
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    blurRadius: 6,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                            // Elevation indicator
                            Positioned(
                              bottom: 60,
                              right: 60,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${telescopeProvider.elevation.toStringAsFixed(1)}°',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Control Buttons
                  Container(
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
                              telescopeProvider.slewUp,
                              Colors.green,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlButton(
                              context,
                              Icons.arrow_back,
                              telescopeProvider.slewLeft,
                              Colors.orange,
                            ),
                            const SizedBox(width: 32),
                            _buildControlButton(
                              context,
                              Icons.stop,
                              telescopeProvider.stop,
                              Colors.red,
                              size: 60,
                            ),
                            const SizedBox(width: 32),
                            _buildControlButton(
                              context,
                              Icons.arrow_forward,
                              telescopeProvider.slewRight,
                              Colors.orange,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildControlButton(
                              context,
                              Icons.arrow_downward,
                              telescopeProvider.slewDown,
                              Colors.green,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Status Display
                  Container(
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
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCompassMarkings(BuildContext context) {
    final markings = <Widget>[];
    for (int i = 0; i < 360; i += 45) {
      final angle = i * pi / 180;
      final isMainDirection = i % 90 == 0;
      final length = isMainDirection ? 20.0 : 10.0;

      markings.add(
        Transform.rotate(
          angle: angle,
          child: Container(
            width: 2,
            height: length,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
            margin: EdgeInsets.only(top: 140 - length / 2),
          ),
        ),
      );

      if (isMainDirection) {
        final direction = _getDirectionLabel(i);
        markings.add(
          Transform.rotate(
            angle: angle,
            child: Container(
              margin: const EdgeInsets.only(top: 120),
              child: Text(
                direction,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    return markings;
  }

  String _getDirectionLabel(int degrees) {
    switch (degrees) {
      case 0: return 'N';
      case 90: return 'E';
      case 180: return 'S';
      case 270: return 'W';
      default: return '';
    }
  }

  Widget _buildControlButton(BuildContext context, IconData icon, VoidCallback onPressed, Color color, {double size = 50}) {
    return GestureDetector(
      onTapDown: (_) {},
      onTapUp: (_) {},
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: size * 0.4),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildStatusItem(BuildContext context, String label, String value, IconData icon, {Color? color}) {
    return Column(
      children: [
        Icon(
          icon,
          color: color ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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