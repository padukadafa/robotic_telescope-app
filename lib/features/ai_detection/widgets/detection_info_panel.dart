import 'package:flutter/material.dart';
import 'package:robotic_telescope/core/models/detection_result.dart';
import 'dart:math' as math;

/// Info panel displaying detection status and metrics
class DetectionInfoPanel extends StatelessWidget {
  final DetectionResult? bestDetection;
  final PointingError? pointingError;
  final double fps;
  final int frameCount;
  final int detectionCount;
  final bool isDetecting;

  const DetectionInfoPanel({
    super.key,
    required this.bestDetection,
    required this.pointingError,
    required this.fps,
    required this.frameCount,
    required this.detectionCount,
    required this.isDetecting,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDetecting ? Colors.green : Colors.grey,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isDetecting ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isDetecting ? 'Detecting' : 'Idle',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                '${fps.toStringAsFixed(1)} FPS',
                style: TextStyle(
                  color: _getFpsColor(fps),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Detection info
          if (bestDetection != null) ...[
            _buildInfoRow(
              'Object',
              bestDetection!.objectName,
              Icons.explore,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Confidence',
              '${(bestDetection!.confidence * 100).toStringAsFixed(1)}%',
              Icons.check_circle,
              Colors.green,
            ),
          ] else ...[
            _buildInfoRow(
              'Status',
              'No object detected',
              Icons.search,
              Colors.orange,
            ),
          ],

          if (pointingError != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              'Error X',
              '${pointingError!.dx.toStringAsFixed(1)}px',
              Icons.height,
              Colors.yellow,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Error Y',
              '${pointingError!.dy.toStringAsFixed(1)}px',
              Icons.height,
              Colors.yellow,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Magnitude',
              '${math.sqrt(pointingError!.magnitude).toStringAsFixed(1)}px',
              Icons.straighten,
              Colors.red,
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 12),

          // Statistics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatistic('Frames', frameCount.toString()),
              _buildStatistic('Detections', detectionCount.toString()),
              _buildStatistic(
                'Hit Rate',
                frameCount > 0
                    ? '${((detectionCount / frameCount) * 100).toStringAsFixed(1)}%'
                    : '0%',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Color _getFpsColor(double fps) {
    if (fps >= 15) return Colors.green;
    if (fps >= 10) return Colors.yellow;
    if (fps >= 5) return Colors.orange;
    return Colors.red;
  }
}
