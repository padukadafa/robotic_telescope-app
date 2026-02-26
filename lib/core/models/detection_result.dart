/// Represents a detected astronomical object in the camera frame
class DetectionResult {
  final String objectName;
  final double confidence;
  final BoundingBox boundingBox;
  final ObjectCenter center;

  DetectionResult({
    required this.objectName,
    required this.confidence,
    required this.boundingBox,
    required this.center,
  });

  /// Calculate pointing error relative to frame center
  PointingError calculatePointingError(
    double frameCenterX,
    double frameCenterY,
  ) {
    return PointingError(
      dx: center.x - frameCenterX,
      dy: center.y - frameCenterY,
    );
  }

  @override
  String toString() =>
      'DetectionResult(object: $objectName, confidence: ${(confidence * 100).toStringAsFixed(1)}%, center: $center)';
}

/// Bounding box coordinates for detected object
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double width;
  final double height;

  BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  }) : width = right - left,
       height = bottom - top;

  /// Get center point of bounding box
  ObjectCenter getCenter() {
    return ObjectCenter(x: left + width / 2, y: top + height / 2);
  }
}

/// Center coordinates of detected object
class ObjectCenter {
  final double x;
  final double y;

  ObjectCenter({required this.x, required this.y});

  @override
  String toString() => '($x, $y)';
}

/// Pointing error for telescope correction
class PointingError {
  final double dx; // Horizontal error
  final double dy; // Vertical error

  PointingError({required this.dx, required this.dy});

  /// Get normalized error (for sending to telescope controller)
  Map<String, double> toNormalized(double frameWidth, double frameHeight) {
    return {
      'dx': dx / frameWidth,
      'dy': dy / frameHeight,
      'dx_pixels': dx,
      'dy_pixels': dy,
    };
  }

  /// Get magnitude of error
  double get magnitude => (dx * dx + dy * dy);

  /// Check if error is within acceptable threshold (in pixels)
  bool isWithinThreshold(double threshold) {
    return magnitude.abs() < (threshold * threshold);
  }

  @override
  String toString() =>
      'PointingError(dx: ${dx.toStringAsFixed(2)}px, dy: ${dy.toStringAsFixed(2)}px)';
}

/// Enum for supported astronomical objects
enum AstronomicalObject {
  moon('Moon'),
  jupiter('Jupiter'),
  saturn('Saturn'),
  venus('Venus'),
  mars('Mars'),
  unknown('Unknown');

  final String displayName;
  const AstronomicalObject(this.displayName);

  static AstronomicalObject fromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'moon':
        return AstronomicalObject.moon;
      case 'jupiter':
        return AstronomicalObject.jupiter;
      case 'saturn':
        return AstronomicalObject.saturn;
      case 'venus':
        return AstronomicalObject.venus;
      case 'mars':
        return AstronomicalObject.mars;
      default:
        return AstronomicalObject.unknown;
    }
  }
}
