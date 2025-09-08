import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/connection_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/monitoring_header.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/connection_status_card.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/stepper_motor_status_card.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/telescope_position_card.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/target_object_card.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/movement_status_card.dart';
import 'package:robotic_telescope/features/monitoring/presentation/widgets/system_health_card.dart';

class MonitoringScreen extends StatelessWidget {
  const MonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<TelescopeProvider, ConnectionProvider, ObjectProvider>(
      builder:
          (
            context,
            telescopeProvider,
            connectionProvider,
            objectProvider,
            child,
          ) {
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      const MonitoringHeader(),

                      const SizedBox(height: 32),

                      // Status Cards
                      Expanded(
                        child: ListView(
                          children: [
                            // Connection Status
                            const ConnectionStatusCard(),

                            const SizedBox(height: 16),

                            // Stepper Motor Status
                            const StepperMotorStatusCard(),

                            const SizedBox(height: 16),

                            // Telescope Position
                            const TelescopePositionCard(),

                            const SizedBox(height: 16),

                            // Selected Object
                            const TargetObjectCard(),

                            const SizedBox(height: 16),

                            // Movement Status
                            const MovementStatusCard(),

                            const SizedBox(height: 16),

                            // System Health
                            const SystemHealthCard(),
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
}
