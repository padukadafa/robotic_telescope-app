import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:robotic_telescope/core/models/detection_result.dart';
import 'dart:math' as math;

/// Overlay widget that draws detection bounding boxes and crosshair
class DetectionOverlay extends StatelessWidget {
  final List<DetectionResult> detections;
  final DetectionResult? bestDetection;
  final PointingError? pointingError;
  final CameraController cameraController;

  const DetectionOverlay({
    super.key,
    required this.detections,
    required this.bestDetection,
    required this.pointingError,
    required this.cameraController,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: DetectionPainter(
        detections: detections,
        bestDetection: bestDetection,
        pointingError: pointingError,
        previewSize: cameraController.value.previewSize,
      ),
    );
  }
}

/// Custom painter for drawing detection results
class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final DetectionResult? bestDetection;
  final PointingError? pointingError;
  final Size? previewSize;

  DetectionPainter({
    required this.detections,
    required this.bestDetection,
    required this.pointingError,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (previewSize == null) return;

    // Calculate scale factors
    final double scaleX = size.width / previewSize!.width;
    final double scaleY = size.height / previewSize!.height;

    // Draw center crosshair
    _drawCenterCrosshair(canvas, size);

    // Draw all detections
    for (var detection in detections) {
      final isBest = detection == bestDetection;
      _drawDetection(canvas, detection, scaleX, scaleY, isBest);
    }

    // Draw pointing error vector
    if (pointingError != null && bestDetection != null) {
      _drawPointingError(canvas, size, bestDetection!, scaleX, scaleY);
    }
  }

  void _drawCenterCrosshair(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final crosshairSize = 30.0;

    // Draw crosshair lines
    canvas.drawLine(
      Offset(centerX - crosshairSize, centerY),
      Offset(centerX + crosshairSize, centerY),
      paint,
    );
    canvas.drawLine(
      Offset(centerX, centerY - crosshairSize),
      Offset(centerX, centerY + crosshairSize),
      paint,
    );

    // Draw center circle
    canvas.drawCircle(Offset(centerX, centerY), 5.0, paint);
  }

  void _drawDetection(
    Canvas canvas,
    DetectionResult detection,
    double scaleX,
    double scaleY,
    bool isBest,
  ) {
    // Scale bounding box
    final box = detection.boundingBox;
    final rect = Rect.fromLTRB(
      box.left * scaleX,
      box.top * scaleY,
      box.right * scaleX,
      box.bottom * scaleY,
    );

    // Draw bounding box
    final boxPaint = Paint()
      ..color = (isBest ? Colors.red : Colors.blue).withOpacity(0.8)
      ..strokeWidth = isBest ? 4.0 : 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(rect, boxPaint);

    // Draw corner indicators for best detection
    if (isBest) {
      _drawCornerIndicators(canvas, rect);
    }

    // Draw label background
    final labelText =
        '${detection.objectName} ${(detection.confidence * 100).toStringAsFixed(0)}%';
    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: Colors.white,
        fontSize: isBest ? 16.0 : 12.0,
        fontWeight: isBest ? FontWeight.bold : FontWeight.normal,
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final labelRect = Rect.fromLTWH(
      rect.left,
      rect.top - textPainter.height - 8,
      textPainter.width + 12,
      textPainter.height + 8,
    );

    final labelBgPaint = Paint()
      ..color = (isBest ? Colors.red : Colors.blue).withOpacity(0.8);

    canvas.drawRect(labelRect, labelBgPaint);

    // Draw label text
    textPainter.paint(
      canvas,
      Offset(rect.left + 6, rect.top - textPainter.height - 4),
    );

    // Draw center point
    final centerPaint = Paint()
      ..color = isBest ? Colors.red : Colors.blue
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(detection.center.x * scaleX, detection.center.y * scaleY),
      isBest ? 8.0 : 5.0,
      centerPaint,
    );
  }

  void _drawCornerIndicators(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left + cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      rect.topLeft,
      Offset(rect.left, rect.top + cornerLength),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right - cornerLength, rect.top),
      paint,
    );
    canvas.drawLine(
      rect.topRight,
      Offset(rect.right, rect.top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left + cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      rect.bottomLeft,
      Offset(rect.left, rect.bottom - cornerLength),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right - cornerLength, rect.bottom),
      paint,
    );
    canvas.drawLine(
      rect.bottomRight,
      Offset(rect.right, rect.bottom - cornerLength),
      paint,
    );
  }

  void _drawPointingError(
    Canvas canvas,
    Size size,
    DetectionResult detection,
    double scaleX,
    double scaleY,
  ) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final objectX = detection.center.x * scaleX;
    final objectY = detection.center.y * scaleY;

    // Draw error vector
    final vectorPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(centerX, centerY),
      Offset(objectX, objectY),
      vectorPaint,
    );

    // Draw arrow head
    _drawArrowHead(
      canvas,
      Offset(centerX, centerY),
      Offset(objectX, objectY),
      vectorPaint,
    );

    // Draw error magnitude text
    final errorMag = pointingError!.magnitude.toStringAsFixed(1);
    final textSpan = TextSpan(
      text: '${errorMag}px',
      style: const TextStyle(
        color: Colors.yellow,
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(offset: Offset(1, 1), blurRadius: 3.0, color: Colors.black),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position text at midpoint of error vector
    final midX = (centerX + objectX) / 2;
    final midY = (centerY + objectY) / 2;
    textPainter.paint(canvas, Offset(midX + 10, midY - 20));
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 15.0;
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final angle = math.atan2(dy, dx);

    final path = Path();
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * math.cos(angle - 0.5),
      to.dy - arrowSize * math.sin(angle - 0.5),
    );
    path.moveTo(to.dx, to.dy);
    path.lineTo(
      to.dx - arrowSize * math.cos(angle + 0.5),
      to.dy - arrowSize * math.sin(angle + 0.5),
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DetectionPainter oldDelegate) {
    return detections != oldDelegate.detections ||
        bestDetection != oldDelegate.bestDetection ||
        pointingError != oldDelegate.pointingError;
  }
}
