import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/status_display.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_control_header.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/go_to_object_button.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/connection_status_banner.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_position_visualization.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/elevation_visualization.dart';

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
                Theme.of(context).colorScheme.background,
                Theme.of(context).colorScheme.surface.withOpacity(0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const TelescopeControlHeader(),

                    const SizedBox(height: 32),

                    if (objectProvider.selectedObject != null)
                      GoToObjectButton(
                        selectedObject: objectProvider.selectedObject!,
                      ),

                    const ConnectionStatusBanner(),

                    const SizedBox(height: 32),

                    // Side-by-side layout for visualizations
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.3),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left side - Elevation Visualization
                          Expanded(child: const ElevationVisualization()),

                          const SizedBox(width: 16),

                          Expanded(
                            child: const TelescopePositionVisualization(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Prominent Control Buttons in the center
                    const ControlButtons(),

                    const SizedBox(height: 24),

                    // Status Display at the bottom
                    const StatusDisplay(),
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
