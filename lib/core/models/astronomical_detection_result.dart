/// Result of hybrid astronomical detection
class AstronomicalDetectionResult {
  /// Type of detected object: "sun", "moon", or "point" (star-like)
  final String type;

  /// Center X coordinate in image frame
  final double centerX;

  /// Center Y coordinate in image frame
  final double centerY;

  /// Detection confidence (0.0 - 1.0)
  final double confidence;

  /// Angular distance to Sun in degrees
  final double deltaSun;

  /// Angular distance to Moon in degrees
  final double deltaMoon;

  /// Brightness value (0-255)
  final double brightness;

  /// Blob area in pixels
  final double area;

  /// Circularity ratio (0.0-1.0, 1.0 = perfect circle)
  final double circularity;

  /// Timestamp of detection
  final DateTime timestamp;

  AstronomicalDetectionResult({
    required this.type,
    required this.centerX,
    required this.centerY,
    required this.confidence,
    required this.deltaSun,
    required this.deltaMoon,
    required this.brightness,
    required this.area,
    required this.circularity,
    required this.timestamp,
  });

  /// Calculate pointing error relative to frame center
  Map<String, double> calculatePointingError(
    double frameCenterX,
    double frameCenterY,
  ) {
    return {'dx': centerX - frameCenterX, 'dy': centerY - frameCenterY};
  }

  /// Check if this is a Sun detection (safety critical)
  bool get isSun => type == 'sun';

  /// Check if this is a Moon detection
  bool get isMoon => type == 'moon';

  /// Check if this is a point source (star-like)
  bool get isPoint => type == 'point';

  /// Get human-readable object name
  String get objectName {
    switch (type) {
      case 'sun':
        return 'Sun';
      case 'moon':
        return 'Moon';
      case 'point':
        return 'Bright Point';
      default:
        return 'Unknown';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'center_x': centerX,
      'center_y': centerY,
      'confidence': confidence,
      'delta_sun': deltaSun,
      'delta_moon': deltaMoon,
      'brightness': brightness,
      'area': area,
      'circularity': circularity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AstronomicalDetection(type: $type, center: ($centerX, $centerY), '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'δSun: ${deltaSun.toStringAsFixed(2)}°, δMoon: ${deltaMoon.toStringAsFixed(2)}°)';
  }
}

/// No detection result
class NoDetectionResult extends AstronomicalDetectionResult {
  NoDetectionResult({required double deltaSun, required double deltaMoon})
    : super(
        type: 'none',
        centerX: 0,
        centerY: 0,
        confidence: 0,
        deltaSun: deltaSun,
        deltaMoon: deltaMoon,
        brightness: 0,
        area: 0,
        circularity: 0,
        timestamp: DateTime.now(),
      );

  @override
  String get objectName => 'Nothing Detected';
}
