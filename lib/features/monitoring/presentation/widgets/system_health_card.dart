import 'package:flutter/material.dart';

/// System Health Card Widget
/// 
/// A presentation widget that displays system health information including:
/// - Battery status and level
/// - CPU and memory usage
/// - Temperature monitoring
/// - Disk usage statistics
/// 
/// This is a pure UI widget that follows clean architecture principles.
/// It receives system health data through parameters instead of directly
/// accessing providers, making it more testable and reusable.
class SystemHealthCard extends StatelessWidget {
  /// Battery level as a percentage (0-100)
  final int batteryLevel;
  
  /// CPU usage as a percentage (0-100)
  final int cpuUsage;
  
  /// Memory usage as a percentage (0-100)
  final int memoryUsage;
  
  /// System temperature in Celsius
  final double temperature;
  
  /// Disk usage as a percentage (0-100)
  final int diskUsage;
  
  /// Whether the system is in a healthy state
  final bool isHealthy;

  const SystemHealthCard({
    super.key,
    required this.batteryLevel,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.temperature,
    required this.diskUsage,
    required this.isHealthy,
  });

  @override
  Widget build(BuildContext context) {
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
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.health_and_safety,
                        color: Colors.green,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Health',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'All systems operational',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow(
                  context,
                  'Battery Level',
                  '$batteryLevel%',
                  Icons.battery_full,
                  color: _getBatteryColor(),
                ),
                _buildDetailRow(
                  context,
                  'CPU Usage',
                  '$cpuUsage%',
                  Icons.memory,
                  color: _getUsageColor(cpuUsage),
                ),
                _buildDetailRow(
                  context,
                  'Memory Usage',
                  '$memoryUsage%',
                  Icons.storage,
                  color: _getUsageColor(memoryUsage),
                ),
                _buildDetailRow(
                  context,
                  'Temperature',
                  '${temperature.toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  color: _getTemperatureColor(),
                ),
                _buildDetailRow(
                  context,
                  'Disk Usage',
                  '$diskUsage%',
                  Icons.storage,
                  color: _getUsageColor(diskUsage),
                ),
                _buildDetailRow(
                  context,
                  'Overall Status',
                  isHealthy ? 'Healthy' : 'Warning',
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ),
        );
  }

  /// Get color for battery level indicator
  Color _getBatteryColor() {
    if (batteryLevel > 50) return Colors.green;
    if (batteryLevel > 20) return Colors.orange;
    return Colors.red;
  }

  /// Get color for usage percentage indicators
  Color _getUsageColor(int usage) {
    if (usage < 70) return Colors.green;
    if (usage < 90) return Colors.orange;
    return Colors.red;
  }

  /// Get color for temperature indicator
  Color _getTemperatureColor() {
    if (temperature < 50) return Colors.green;
    if (temperature < 70) return Colors.orange;
    return Colors.red;
  }
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
              color: (color ?? Theme.of(context).colorScheme.primary)
                  .withOpacity(0.1),
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
}
