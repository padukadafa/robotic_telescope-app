import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gamepads/gamepads.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/features/object_selection/provider/object_selection_provider.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/go_to_object_button.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/status_display.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/connection_status_banner.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_position_visualization.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/elevation_visualization.dart';
import 'package:robotic_telescope/features/camera/presentation/camera_control_screen.dart';

class TelescopeControlScreen extends StatefulWidget {
  const TelescopeControlScreen({super.key});

  @override
  State<TelescopeControlScreen> createState() => _TelescopeControlScreenState();
}

class _TelescopeControlScreenState extends State<TelescopeControlScreen> {
  Timer? _autoStopTimer;
  String? _lastCommand;
  DateTime? _lastMovementTime;
  static const _autoStopDuration = Duration(milliseconds: 2000);
  static const _minMovementDuration = Duration(milliseconds: 100);

  @override
  void initState() {
    super.initState();
    
    Gamepads.events.listen((event) {
      print('Device: ${event.gamepadId}');
      print('Button: ${event.key}');
      print('Value: ${event.value}');
      print("Type: ${event.type}");
      if (event.type == KeyType.analog) {
        final now = DateTime.now();

        if (event.key == "AXIS_HAT_X" && event.value == -1.0) {
          // Left
          _lastCommand = 'left';
          _lastMovementTime = now;
          context.read<TelescopeProvider>().slewLeft();
          _startAutoStopTimer();
        } else if (event.key == "AXIS_HAT_X" && event.value == 1.0) {
          // Right
          _lastCommand = 'right';
          _lastMovementTime = now;
          context.read<TelescopeProvider>().slewRight();
          _startAutoStopTimer();
        } else if (event.key == "AXIS_HAT_Y" && event.value == -1.0) {
          // Up
          _lastCommand = 'up';
          _lastMovementTime = now;
          context.read<TelescopeProvider>().slewUp();
          _startAutoStopTimer();
        } else if (event.key == "AXIS_HAT_Y" && event.value == 1.0) {
          // Down
          _lastCommand = 'down';
          _lastMovementTime = now;
          context.read<TelescopeProvider>().slewDown();
          _startAutoStopTimer();
        } else if (event.value == 0.0) {
          // Validasi: Abaikan value 0 jika datang terlalu cepat setelah perintah gerakan
          if (_lastMovementTime != null) {
            final timeSinceLastMovement = now.difference(_lastMovementTime!);
            if (timeSinceLastMovement < _minMovementDuration) {
              print(
                'Ignoring premature stop signal: ${timeSinceLastMovement.inMilliseconds}ms since last movement',
              );
              return; // Abaikan perintah stop yang terlalu cepat
            }
          }

          // Stop hanya jika sudah cukup waktu sejak perintah gerakan terakhir
          _autoStopTimer?.cancel();
          _lastCommand = null;
          _lastMovementTime = null;
          context.read<TelescopeProvider>().stop();
        }
      } else if (event.type == KeyType.button) {
        if (event.key == "KEYCODE_BUTTON_A") {
          context.read<TelescopeProvider>().stop();
        }
      }
    });
  }

  void _startAutoStopTimer() {
    _autoStopTimer?.cancel();
    _autoStopTimer = Timer(_autoStopDuration, () {
      if (mounted) {
        print('Auto-stop: Tidak ada perintah dalam $_autoStopDuration');
        context.read<TelescopeProvider>().stop();
        _lastCommand = null;
        _lastMovementTime = null;
      }
    });
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CameraControlScreen(),
            ),
          );
        },
        child: const Icon(Icons.camera_alt),
        tooltip: 'Open Camera',
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Consumer<TelescopeProvider>(
                    builder: (context, value, child) {
                      return ConnectionStatusBanner(
                        isConnected: value.isConnected,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Position visualizations
                  Consumer<TelescopeProvider>(
                    builder: (context, value, child) {
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevationVisualization(
                                elevation: value.elevation.toDouble(),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: TelescopePositionVisualization(
                                azimuth: value.azimuth.toDouble(),
                                elevation: value.elevation.toDouble(),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Consumer<TelescopeProvider>(
                    builder: (context, value, child) {
                      return StatusDisplay(
                        azimuth: value.azimuth.toDouble(),
                        elevation: value.elevation.toDouble(),
                        isMoving: value.isMoving,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer2<ObjectSelectionProvider, TelescopeProvider>(
                    builder: (context, objects, telescope, _) {
                      if (objects.selectedObject == null) {
                        return const SizedBox.shrink();
                      }
                      return GoToObjectButton(
                        selectedObject: objects.selectedObject!,
                        isMoving: telescope.isMoving,
                        isConnected: telescope.isConnected,
                        onGoTo: telescope.isConnected
                            ? () async {
                                await telescope.goToObject(
                                  objects.selectedObject!,
                                );
                              }
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Consumer<TelescopeProvider>(
                    builder: (context, value, child) {
                      return ControlButtons(
                        isConnected: value.isConnected,
                        onSlewUp: () {
                          value.slewUp();
                        },

                        onSlewDown: () {
                          value.slewDown();
                        },
                        onSlewLeft: () {
                          value.slewLeft();
                        },
                        onSlewRight: () {
                          value.slewRight();
                        },
                        onStop: () {
                          value.stop();
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
