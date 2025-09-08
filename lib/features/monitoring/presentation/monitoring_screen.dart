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
      builder: (context, telescopeProvider, connectionProvider, objectProvider, child) {
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
                            Icons.monitor,
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
                                'System Monitoring',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Real-time telescope status',
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

                  // Status Cards
                  Expanded(
                    child: ListView(
                      children: [
                        // Connection Status
                        _buildStatusCard(
                          context,
                          'Connection Status',
                          Icons.wifi,
                          connectionProvider.isConnected
                            ? 'Connected to ${connectionProvider.connectedNetwork}'
                            : 'Not Connected',
                          connectionProvider.isConnected ? Colors.green : Colors.red,
                          [
                            _buildDetailRow(
                              context,
                              'WiFi Network',
                              connectionProvider.isConnected ? connectionProvider.connectedNetwork : 'None',
                              Icons.router,
                            ),
                            _buildDetailRow(
                              context,
                              'Telescope WebSocket',
                              connectionProvider.telescopeConnected ? 'Connected (${connectionProvider.telescopeIp})' : 'Disconnected',
                              connectionProvider.telescopeConnected ? Icons.wifi : Icons.wifi_off,
                              color: connectionProvider.telescopeConnected ? Colors.green : Colors.red,
                            ),
                            _buildDetailRow(
                              context,
                              'Signal Strength',
                              connectionProvider.isConnected ? 'Strong' : 'N/A',
                              Icons.signal_wifi_4_bar,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Stepper Motor Status
                        _buildStatusCard(
                          context,
                          'Stepper Motors',
                          Icons.settings,
                          'NEMA 17 Control System',
                          Colors.blue,
                          [
                            _buildDetailRow(
                              context,
                              'Motor Type',
                              'NEMA 17',
                              Icons.electrical_services,
                            ),
                            _buildDetailRow(
                              context,
                              'Steps/Revolution',
                              '200 steps',
                              Icons.rotate_right,
                            ),
                            _buildDetailRow(
                              context,
                              'Microstepping',
                              '16x',
                              Icons.precision_manufacturing,
                            ),
                            _buildDetailRow(
                              context,
                              'Control Method',
                              'WebSocket Commands',
                              Icons.cloud_sync,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Telescope Position
                        _buildStatusCard(
                          context,
                          'Telescope Position',
                          Icons.explore,
                          'Current coordinates',
                          Theme.of(context).colorScheme.primary,
                          [
                            _buildDetailRow(
                              context,
                              'Azimuth',
                              '${telescopeProvider.azimuth.toStringAsFixed(2)}°',
                              Icons.rotate_right,
                            ),
                            _buildDetailRow(
                              context,
                              'Elevation',
                              '${telescopeProvider.elevation.toStringAsFixed(2)}°',
                              Icons.arrow_upward,
                            ),
                            _buildProgressIndicator(
                              context,
                              'Azimuth Progress',
                              telescopeProvider.azimuth / 360,
                              Colors.blue,
                            ),
                            _buildProgressIndicator(
                              context,
                              'Elevation Progress',
                              telescopeProvider.elevation / 90,
                              Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Selected Object
                        _buildStatusCard(
                          context,
                          'Target Object',
                          Icons.star,
                          objectProvider.selectedObject?.name ?? 'No object selected',
                          objectProvider.selectedObject != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                          objectProvider.selectedObject != null
                            ? [
                                _buildDetailRow(
                                  context,
                                  'Type',
                                  objectProvider.selectedObject!.type,
                                  _getObjectIcon(objectProvider.selectedObject!.type),
                                ),
                                _buildDetailRow(
                                  context,
                                  'Right Ascension',
                                  '${objectProvider.selectedObject!.ra.toStringAsFixed(2)}°',
                                  Icons.explore,
                                ),
                                _buildDetailRow(
                                  context,
                                  'Declination',
                                  '${objectProvider.selectedObject!.dec.toStringAsFixed(2)}°',
                                  Icons.north,
                                ),
                              ]
                            : [
                                _buildDetailRow(
                                  context,
                                  'Status',
                                  'No target selected',
                                  Icons.info_outline,
                                ),
                              ],
                        ),

                        const SizedBox(height: 16),

                        // Movement Status
                        _buildStatusCard(
                          context,
                          'Movement Status',
                          telescopeProvider.isMoving ? Icons.directions_run : Icons.stop,
                          telescopeProvider.isMoving ? 'Telescope is moving' : 'Telescope is stationary',
                          telescopeProvider.isMoving ? Colors.orange : Colors.blue,
                          [
                            _buildDetailRow(
                              context,
                              'Current Action',
                              telescopeProvider.status,
                              telescopeProvider.isMoving ? Icons.directions_run : Icons.stop,
                            ),
                            _buildDetailRow(
                              context,
                              'Control Method',
                              'Stepper Motor Commands',
                              Icons.precision_manufacturing,
                            ),
                            if (telescopeProvider.isMoving)
                              _buildDetailRow(
                                context,
                                'Command Type',
                                'WebSocket Transmission',
                                Icons.cloud_upload,
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // System Health
                        _buildStatusCard(
                          context,
                          'System Health',
                          Icons.health_and_safety,
                          'All systems operational',
                          Colors.green,
                          [
                            _buildDetailRow(
                              context,
                              'Telescope Controller',
                              telescopeProvider.isConnected ? 'Online' : 'Offline',
                              telescopeProvider.isConnected ? Icons.check_circle : Icons.error,
                              color: telescopeProvider.isConnected ? Colors.green : Colors.red,
                            ),
                            _buildDetailRow(
                              context,
                              'WebSocket Connection',
                              connectionProvider.telescopeConnected ? 'Connected' : 'Disconnected',
                              connectionProvider.telescopeConnected ? Icons.wifi : Icons.wifi_off,
                              color: connectionProvider.telescopeConnected ? Colors.green : Colors.red,
                            ),
                            _buildDetailRow(
                              context,
                              'Stepper Motors',
                              'Ready',
                              Icons.electrical_services,
                              color: Colors.green,
                            ),
                            _buildDetailRow(
                              context,
                              'Power Status',
                              'Normal',
                              Icons.battery_full,
                              color: Colors.green,
                            ),
                          ],
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

  Widget _buildStatusCard(
    BuildContext context,
    String title,
    IconData icon,
    String subtitle,
    Color accentColor,
    List<Widget> details,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context,
    String label,
    double value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              Text(
                '${(value * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: Theme.of(context).colorScheme.surface,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  IconData _getObjectIcon(String type) {
    switch (type.toLowerCase()) {
      case 'star':
        return Icons.star;
      case 'galaxy':
        return Icons.blur_circular;
      case 'nebula':
        return Icons.cloud;
      case 'planet':
        return Icons.public;
      default:
        return Icons.help_outline;
    }
  }
}