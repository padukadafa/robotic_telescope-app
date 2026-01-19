import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';

class WaterpassScreen extends StatelessWidget {
  const WaterpassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Waterpass'), centerTitle: true),
      body: Consumer<TelescopeProvider>(
        builder: (context, telescope, _) {
          if (!telescope.isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.link_off,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Teleskop tidak terhubung',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sambungkan teleskop untuk melihat level',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Status Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: telescope.isLevel
                                ? Colors.green
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            telescope.isLevel
                                ? 'Teleskop sudah datar'
                                : 'Sesuaikan posisi teleskop',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Bubble Level Visualizer
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Level Indicator',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 300,
                          child: CustomPaint(
                            painter: BubbleLevelPainter(
                              roll: telescope.roll,
                              pitch: telescope.pitch,
                              isLevel: telescope.isLevel,
                              primaryColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              successColor: Colors.green,
                              warningColor: Colors.orange,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Roll: ${telescope.roll.toStringAsFixed(2)}°',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: telescope.roll.abs() < 2.0
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Pitch: ${telescope.pitch.toStringAsFixed(2)}°',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: telescope.pitch.abs() < 2.0
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                  ),
                                  if (telescope.isLevel) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green,
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'LEVEL',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cara Penggunaan',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _InstructionItem(
                          number: '1',
                          text: 'Letakkan teleskop di permukaan yang stabil',
                        ),
                        _InstructionItem(
                          number: '2',
                          text:
                              'Sesuaikan tripod hingga bubble berada di zona hijau (tengah)',
                        ),
                        _InstructionItem(
                          number: '3',
                          text: 'Level yang baik: Roll & Pitch < 2°',
                        ),
                        _InstructionItem(
                          number: '4',
                          text:
                              'Indikator berwarna hijau menandakan teleskop sudah datar',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class BubbleLevelPainter extends CustomPainter {
  final double roll;
  final double pitch;
  final bool isLevel;
  final Color primaryColor;
  final Color successColor;
  final Color warningColor;

  BubbleLevelPainter({
    required this.roll,
    required this.pitch,
    required this.isLevel,
    required this.primaryColor,
    required this.successColor,
    required this.warningColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2 - 40;

    // Draw outer circle (level indicator boundary)
    final outerPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, maxRadius, outerPaint);

    // Draw crosshairs
    final crosshairPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crosshairPaint,
    );

    // Draw inner safe zone circles (±2 degrees)
    final safeZoneRadius = maxRadius * 0.3;

    // Outer safe zone border
    final safeZoneBorderPaint = Paint()
      ..color = successColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, safeZoneRadius, safeZoneBorderPaint);

    // Inner safe zone fill
    final safeZonePaint = Paint()
      ..color = successColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, safeZoneRadius, safeZonePaint);

    // Draw additional reference circles
    for (int i = 1; i <= 3; i++) {
      final refRadius = maxRadius * (i / 4);
      final refPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, refRadius, refPaint);
    }

    // Calculate bubble position based on roll and pitch
    // Scale factor: 10 degrees = maxRadius
    final rollOffset = (roll / 10) * maxRadius;
    final pitchOffset = (pitch / 10) * maxRadius;

    var bubbleX = center.dx + rollOffset;
    var bubbleY = center.dy + pitchOffset;

    // Constrain bubble within outer circle
    final distance = sqrt(
      pow(bubbleX - center.dx, 2) + pow(bubbleY - center.dy, 2),
    );
    if (distance > maxRadius * 0.9) {
      final angle = atan2(bubbleY - center.dy, bubbleX - center.dx);
      bubbleX = center.dx + (maxRadius * 0.9) * cos(angle);
      bubbleY = center.dy + (maxRadius * 0.9) * sin(angle);
    }

    // Draw bubble shadow
    final bubbleColor = isLevel ? successColor : warningColor;
    final bubbleShadow = Paint()
      ..color = bubbleColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(bubbleX, bubbleY), 20, bubbleShadow);

    // Draw bubble
    final bubblePaint = Paint()
      ..color = bubbleColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bubbleX, bubbleY), 18, bubblePaint);

    // Draw bubble border
    final bubbleBorderPaint = Paint()
      ..color = bubbleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(Offset(bubbleX, bubbleY), 18, bubbleBorderPaint);

    // Draw bubble highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(bubbleX - 5, bubbleY - 5), 6, highlightPaint);
  }

  @override
  bool shouldRepaint(BubbleLevelPainter oldDelegate) {
    return oldDelegate.roll != roll ||
        oldDelegate.pitch != pitch ||
        oldDelegate.isLevel != isLevel;
  }
}
