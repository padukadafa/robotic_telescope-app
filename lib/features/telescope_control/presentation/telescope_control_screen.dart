import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_control_header.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/go_to_object_button.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/connection_status_banner.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/telescope_position_visualization.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/status_display.dart';

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

                  const TelescopePositionVisualization(),

                  const SizedBox(height: 24),

                  const ControlButtons(),

                  const SizedBox(height: 16),

                  const StatusDisplay(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
