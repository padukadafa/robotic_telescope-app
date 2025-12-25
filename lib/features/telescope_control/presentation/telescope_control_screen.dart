import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/features/object_selection/provider/object_selection_provider.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/go_to_object_button.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/status_display.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/connection_status_banner.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_position_visualization.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/elevation_visualization.dart';

class TelescopeControlScreen extends StatefulWidget {
  const TelescopeControlScreen({super.key});

  @override
  State<TelescopeControlScreen> createState() => _TelescopeControlScreenState();
}

class _TelescopeControlScreenState extends State<TelescopeControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
