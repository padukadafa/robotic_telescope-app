import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/status_display.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/go_to_object_button.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/connection_status_banner.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_position_visualization.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/elevation_visualization.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/fine_tuning_controls.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/position_accuracy_indicator.dart';

class TelescopeControlScreen extends StatelessWidget {
  const TelescopeControlScreen({super.key});

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

                    if (objectProvider.selectedObject != null)
                      GoToObjectButton(
                        selectedObject: objectProvider.selectedObject!,
                        isMoving: telescopeProvider.isMoving,
                        isConnected: telescopeProvider.isConnected,
                        onGoTo: () => telescopeProvider.moveTo(
                          objectProvider.selectedObject!.ra * 15,
                          objectProvider.selectedObject!.dec,
                        ),
                      ),

                    ConnectionStatusBanner(
                      isConnected: telescopeProvider.isConnected,
                    ),

                    // Position accuracy indicator
                    PositionAccuracyIndicator(
                      currentAzimuth: telescopeProvider.azimuth,
                      currentElevation: telescopeProvider.elevation,
                      targetAzimuth: telescopeProvider.targetAzimuth,
                      targetElevation: telescopeProvider.targetElevation,
                      accuracy:
                          telescopeProvider.targetAzimuth != null &&
                              telescopeProvider.targetElevation != null
                          ? telescopeProvider.getPositionAccuracy()
                          : null,
                      isAccurate: telescopeProvider.isPositionAccurate(),
                    ),

                    const SizedBox(height: 32),

                    // Side-by-side layout for visualizations
                    Container(
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
                          // Left side - Elevation Visualization
                          Expanded(
                            child: ElevationVisualization(
                              elevation: telescopeProvider.elevation,
                            ),
                          ),

                          const SizedBox(width: 16),

                          Expanded(
                            child: TelescopePositionVisualization(
                              azimuth: telescopeProvider.azimuth,
                              elevation: telescopeProvider.elevation,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Fine-tuning controls (appears after GoTo operation)
                    FineTuningControls(
                      isInFineTuningMode: telescopeProvider.isInFineTuningMode,
                      isConnected: telescopeProvider.isConnected,
                      fineTuningStepSize: telescopeProvider.fineTuningStepSize,
                      onExitFineTuning: telescopeProvider.exitFineTuningMode,
                      onConfirmFineTuning: telescopeProvider.confirmFineTuning,
                      onFineTuneUp: () => telescopeProvider.fineTuneUp(),
                      onFineTuneDown: () => telescopeProvider.fineTuneDown(),
                      onFineTuneLeft: () => telescopeProvider.fineTuneLeft(),
                      onFineTuneRight: () => telescopeProvider.fineTuneRight(),
                      onSetStepSize: telescopeProvider.setFineTuningStepSize,
                    ),

                    // Prominent Control Buttons in the center
                    ControlButtons(
                      isConnected: telescopeProvider.isConnected,
                      onSlewUp: telescopeProvider.isConnected
                          ? () => telescopeProvider.slewUp(steps: 50)
                          : null,
                      onSlewDown: telescopeProvider.isConnected
                          ? () => telescopeProvider.slewDown(steps: 50)
                          : null,
                      onSlewLeft: telescopeProvider.isConnected
                          ? () => telescopeProvider.slewLeft(steps: 50)
                          : null,
                      onSlewRight: telescopeProvider.isConnected
                          ? () => telescopeProvider.slewRight(steps: 50)
                          : null,
                      onStop: telescopeProvider.isConnected
                          ? telescopeProvider.stop
                          : null,
                      stepSize: 50,
                    ),

                    const SizedBox(height: 24),

                    // Status Display at the bottom
                    StatusDisplay(
                      azimuth: telescopeProvider.azimuth,
                      elevation: telescopeProvider.elevation,
                      isMoving: telescopeProvider.isMoving,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
