import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/providers/connection_provider.dart';
import 'package:robotic_telescope/core/providers/object_provider.dart';

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
                      Text(
                        'System Monitoring',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),

                      const SizedBox(height: 32),

                      // Status Cards
                      Expanded(
                        child: ListView(
                          children: [
                            // Connection Status Card
                            _buildConnectionCard(context, connectionProvider),

                            const SizedBox(height: 16),

                            // Telescope Position Card
                            _buildTelescopeCard(context, telescopeProvider),

                            const SizedBox(height: 16),

                            // System Status Card
                            _buildSystemCard(context),
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

  Widget _buildConnectionCard(
    BuildContext context,
    ConnectionProvider provider,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Connection Status',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'WiFi: ${provider.isConnected ? 'Connected' : 'Disconnected'}',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  provider.telescopeConnected ? Icons.link : Icons.link_off,
                  color: provider.telescopeConnected
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Telescope: ${provider.telescopeConnected ? 'Connected' : 'Disconnected'}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelescopeCard(BuildContext context, TelescopeProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Telescope Position',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.explore),
                const SizedBox(width: 8),
                Text('Azimuth: ${provider.azimuth.toStringAsFixed(1)}°'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.height),
                const SizedBox(width: 8),
                Text('Elevation: ${provider.elevation.toStringAsFixed(1)}°'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'System Health',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text('System: Healthy'),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.speed, color: Colors.blue),
                const SizedBox(width: 8),
                const Text('Performance: Normal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
