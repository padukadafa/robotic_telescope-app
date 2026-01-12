import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

enum _CalibrationStatus { idle, running, success, failed }

enum _CalibrationType { gyro, compass }

class CallibrationScreen extends StatefulWidget {
  const CallibrationScreen({super.key});

  @override
  State<CallibrationScreen> createState() => _CallibrationScreenState();
}

class _CallibrationScreenState extends State<CallibrationScreen> {
  DateTime? _gyroUpdatedAt;
  DateTime? _compassUpdatedAt;

  _CalibrationStatus _mapProviderStatus(String status) {
    switch (status) {
      case 'in_progress':
        return _CalibrationStatus.running;
      case 'inprogress':
      case 'running':
      case 'progress':
      case 'calibrating':
        return _CalibrationStatus.running;
      case 'done':
        return _CalibrationStatus.success;
      case 'not_started':
      default:
        return _CalibrationStatus.idle;
    }
  }

  Future<void> _startCalibration(
    TelescopeProvider telescope,
    _CalibrationType type,
  ) async {
    if (!telescope.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sambungkan teleskop terlebih dahulu.')),
      );
      return;
    }

    final sensorName = type == _CalibrationType.gyro ? 'gyro' : 'kompas';

    try {
      if (type == _CalibrationType.gyro) {
        await telescope.calibrateGyro();
      } else {
        await telescope.calibrateCompass();
      }

      setState(() {
        if (type == _CalibrationType.gyro) {
          _gyroUpdatedAt = DateTime.now();
        } else {
          _compassUpdatedAt = DateTime.now();
        }
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perintah kalibrasi $sensorName dikirim. Pantau status.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memulai kalibrasi $sensorName: $e')),
      );
    }
  }

  String _statusLabel(_CalibrationStatus status) {
    switch (status) {
      case _CalibrationStatus.running:
        return 'Sedang berjalan';
      case _CalibrationStatus.success:
        return 'Selesai';
      case _CalibrationStatus.failed:
        return 'Gagal';
      case _CalibrationStatus.idle:
      default:
        return 'Belum dimulai';
    }
  }

  Color _statusColor(_CalibrationStatus status, ColorScheme colors) {
    switch (status) {
      case _CalibrationStatus.running:
        return colors.tertiary;
      case _CalibrationStatus.success:
        return colors.primary;
      case _CalibrationStatus.failed:
        return colors.error;
      case _CalibrationStatus.idle:
      default:
        return colors.outline;
    }
  }

  void _showStepsSheet({required String title, required List<String> steps}) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...steps.map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• '),
                        Expanded(child: Text(step)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Kalibrasi Sensor')),
      body: SafeArea(
        child: Consumer<TelescopeProvider>(
          builder: (context, telescope, _) {
            final gyroStatus = _mapProviderStatus(
              telescope.gyroCalibrationStatus,
            );
            final compassStatus = _mapProviderStatus(
              telescope.compassCalibrationStatus,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lakukan kalibrasi sebelum mengoperasikan teleskop untuk memastikan orientasi tepat.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!telescope.isConnected)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.link_off, color: colors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Hubungkan ke teleskop untuk memulai kalibrasi.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!telescope.isConnected) const SizedBox(height: 12),
                  _CalibrationCard(
                    title: 'Kalibrasi Gyro',
                    description:
                        'Menyesuaikan orientasi awal teleskop terhadap gravitasi.',
                    statusLabel: _statusLabel(gyroStatus),
                    statusColor: _statusColor(gyroStatus, colors),
                    isRunning: gyroStatus == _CalibrationStatus.running,
                    lastUpdated: _gyroUpdatedAt,
                    icon: Icons.threed_rotation,
                    steps: const [
                      'Letakkan teleskop di permukaan datar dan stabil.',
                      'Tekan tombol mulai dan tunggu hingga indikator selesai.',
                      'Hindari getaran selama proses berjalan.',
                    ],
                    onStart: () =>
                        _startCalibration(telescope, _CalibrationType.gyro),
                    onShowSteps: () => _showStepsSheet(
                      title: 'Langkah kalibrasi gyro',
                      steps: const [
                        'Pastikan daya mencukupi dan sambungan stabil.',
                        'Letakkan perangkat pada posisi parkir standar.',
                        'Jauhkan dari magnet atau sumber getaran.',
                        'Mulai kalibrasi dan tunggu hingga status berubah menjadi selesai.',
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CalibrationCard(
                    title: 'Kalibrasi Kompas',
                    description:
                        'Mengoreksi pembacaan arah utara untuk pointing akurat.',
                    statusLabel: _statusLabel(compassStatus),
                    statusColor: _statusColor(compassStatus, colors),
                    isRunning: compassStatus == _CalibrationStatus.running,
                    lastUpdated: _compassUpdatedAt,
                    icon: Icons.explore,
                    steps: const [
                      'Jauhkan teleskop dari benda feromagnetik.',
                      'Gerakkan teleskop perlahan melingkar.',
                      'Tunggu indikator selesai sebelum digunakan.',
                    ],
                    onStart: () =>
                        _startCalibration(telescope, _CalibrationType.compass),
                    onShowSteps: () => _showStepsSheet(
                      title: 'Langkah kalibrasi kompas',
                      steps: const [
                        'Pastikan tidak ada magnet kuat dalam radius 2 meter.',
                        'Gerakkan mount melingkar selama 10-15 detik.',
                        'Biarkan perangkat diam hingga status selesai.',
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({
    required this.title,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
    required this.isRunning,
    required this.lastUpdated,
    required this.icon,
    required this.steps,
    required this.onStart,
    required this.onShowSteps,
  });

  final String title;
  final String description;
  final String statusLabel;
  final Color statusColor;
  final bool isRunning;
  final DateTime? lastUpdated;
  final IconData icon;
  final List<String> steps;
  final VoidCallback onStart;
  final VoidCallback onShowSteps;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(description, style: textTheme.bodyMedium),
                    ],
                  ),
                ),
                _StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            if (isRunning) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(minHeight: 6),
            ],
            const SizedBox(height: 12),
            ...steps
                .map(
                  (step) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(step, style: textTheme.bodyMedium),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            const SizedBox(height: 8),
            if (lastUpdated != null)
              Text(
                'Terakhir kalibrasi: ${lastUpdated!.hour.toString().padLeft(2, '0')}:${lastUpdated!.minute.toString().padLeft(2, '0')} '
                '${lastUpdated!.day}/${lastUpdated!.month}/${lastUpdated!.year}',
                style: textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: isRunning ? null : onShowSteps,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('Lihat panduan'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isRunning ? null : onStart,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      isRunning ? 'Sedang kalibrasi...' : 'Mulai Kalibrasi',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
