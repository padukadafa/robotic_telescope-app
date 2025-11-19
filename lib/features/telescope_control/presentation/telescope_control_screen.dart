import 'package:flutter/material.dart';
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
  double azimuth = 0.0;
  double elevation = 45.0;
  bool isMoving = false;
  bool isConnected = false;
  String status = 'Ready';

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
                ConnectionStatusBanner(
                  isConnected: isConnected,
                ),
                const SizedBox(height: 32),
                // Position visualizations
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.3),
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
                          elevation: elevation,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 2,
                        child: TelescopePositionVisualization(
                          azimuth: azimuth,
                          elevation: elevation,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                StatusDisplay(
                  azimuth: azimuth,
                  elevation: elevation,
                  isMoving: isMoving,
                ),
                const SizedBox(height: 32),
                ControlButtons(
                  isConnected: isConnected,
                  onSlewUp: () {
                    setState(() {
                      elevation = (elevation + 5).clamp(0, 90);
                    });
                  },
                  onSlewDown: () {
                    setState(() {
                      elevation = (elevation - 5).clamp(0, 90);
                    });
                  },
                  onSlewLeft: () {
                    setState(() {
                      azimuth = (azimuth - 5) % 360;
                    });
                  },
                  onSlewRight: () {
                    setState(() {
                      azimuth = (azimuth + 5) % 360;
                    });
                  },
                  onStop: () {
                    setState(() {
                      isMoving = false;
                      status = 'Stopped';
                    });
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
