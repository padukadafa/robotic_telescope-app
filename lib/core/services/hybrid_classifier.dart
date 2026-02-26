import 'package:robotic_telescope/core/services/brightness_detector.dart';
import 'package:robotic_telescope/core/models/astronomical_detection_result.dart';

/// Input data for hybrid classification
class ClassificationInput {
  final BrightBlob blob;
  final double telescopeAltitude;
  final double telescopeAzimuth;
  final double sunAltitude;
  final double sunAzimuth;
  final double moonAltitude;
  final double moonAzimuth;
  final double deltaSun;
  final double deltaMoon;

  ClassificationInput({
    required this.blob,
    required this.telescopeAltitude,
    required this.telescopeAzimuth,
    required this.sunAltitude,
    required this.sunAzimuth,
    required this.moonAltitude,
    required this.moonAzimuth,
    required this.deltaSun,
    required this.deltaMoon,
  });
}

/// Hybrid classifier combining computer vision and astronomical calculations
class HybridClassifier {
  // Classification thresholds
  static const double sunAngularThreshold = 2.0; // degrees
  static const double moonAngularThreshold = 2.0; // degrees

  // Brightness thresholds
  static const double sunMinBrightness = 220.0; // Very bright (0-255)
  static const double moonMinBrightness = 150.0; // Moderate brightness
  static const double pointMaxBrightness =
      240.0; // Stars are bright but not as intense

  // Area thresholds (in pixels)
  static const double sunMinArea = 500.0; // Large bright region
  static const double moonMinArea = 200.0; // Medium to large circular region
  static const double pointMaxArea = 150.0; // Small bright blob

  // Circularity thresholds
  static const double moonMinCircularity =
      0.7; // Moon should be fairly circular
  static const double sunMinCircularity = 0.6; // Sun should be circular

  /// Classify a detected bright blob
  static AstronomicalDetectionResult classify(ClassificationInput input) {
    final blob = input.blob;
    final deltaSun = input.deltaSun;
    final deltaMoon = input.deltaMoon;

    // Decision tree based on hybrid approach:
    // 1. Check angular distance to known celestial objects
    // 2. Verify visual characteristics match expectations
    // 3. Classify accordingly

    // ===== SUN DETECTION =====
    if (_isSunCandidate(blob, deltaSun, input.sunAltitude)) {
      return AstronomicalDetectionResult(
        type: 'sun',
        centerX: blob.centerX,
        centerY: blob.centerY,
        confidence: _calculateSunConfidence(blob, deltaSun),
        deltaSun: deltaSun,
        deltaMoon: deltaMoon,
        brightness: blob.brightness,
        area: blob.area,
        circularity: blob.circularityRatio,
        timestamp: DateTime.now(),
      );
    }

    // ===== MOON DETECTION =====
    if (_isMoonCandidate(blob, deltaMoon, input.moonAltitude)) {
      return AstronomicalDetectionResult(
        type: 'moon',
        centerX: blob.centerX,
        centerY: blob.centerY,
        confidence: _calculateMoonConfidence(blob, deltaMoon),
        deltaSun: deltaSun,
        deltaMoon: deltaMoon,
        brightness: blob.brightness,
        area: blob.area,
        circularity: blob.circularityRatio,
        timestamp: DateTime.now(),
      );
    }

    // ===== POINT SOURCE (STAR) DETECTION =====
    // If neither Sun nor Moon is near, classify as point source
    return AstronomicalDetectionResult(
      type: 'point',
      centerX: blob.centerX,
      centerY: blob.centerY,
      confidence: _calculatePointConfidence(blob),
      deltaSun: deltaSun,
      deltaMoon: deltaMoon,
      brightness: blob.brightness,
      area: blob.area,
      circularity: blob.circularityRatio,
      timestamp: DateTime.now(),
    );
  }

  /// Check if blob is a Sun candidate
  static bool _isSunCandidate(
    BrightBlob blob,
    double deltaSun,
    double sunAltitude,
  ) {
    // Sun must be above horizon
    if (sunAltitude < 0) return false;

    // Must be within angular threshold
    if (deltaSun > sunAngularThreshold) return false;

    // Must meet brightness requirement
    if (blob.brightness < sunMinBrightness) return false;

    // Must be large enough
    if (blob.area < sunMinArea) return false;

    // Should be reasonably circular
    if (blob.circularityRatio < sunMinCircularity) return false;

    return true;
  }

  /// Check if blob is a Moon candidate
  static bool _isMoonCandidate(
    BrightBlob blob,
    double deltaMoon,
    double moonAltitude,
  ) {
    // Moon must be above horizon
    if (moonAltitude < 0) return false;

    // Must be within angular threshold
    if (deltaMoon > moonAngularThreshold) return false;

    // Must meet brightness requirement
    if (blob.brightness < moonMinBrightness) return false;

    // Must be large enough
    if (blob.area < moonMinArea) return false;

    // Should be circular
    if (blob.circularityRatio < moonMinCircularity) return false;

    return true;
  }

  /// Calculate Sun detection confidence
  static double _calculateSunConfidence(BrightBlob blob, double deltaSun) {
    // Confidence based on:
    // 1. Angular distance (closer = higher confidence)
    // 2. Brightness (brighter = higher confidence)
    // 3. Circularity (more circular = higher confidence)

    final angularScore = 1.0 - (deltaSun / sunAngularThreshold).clamp(0.0, 1.0);
    final brightnessScore =
        ((blob.brightness - sunMinBrightness) / (255.0 - sunMinBrightness))
            .clamp(0.0, 1.0);
    final circularityScore = blob.circularityRatio;

    // Weighted average (angular distance is most important)
    final confidence =
        (angularScore * 0.5) +
        (brightnessScore * 0.3) +
        (circularityScore * 0.2);

    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate Moon detection confidence
  static double _calculateMoonConfidence(BrightBlob blob, double deltaMoon) {
    final angularScore =
        1.0 - (deltaMoon / moonAngularThreshold).clamp(0.0, 1.0);
    final brightnessScore =
        ((blob.brightness - moonMinBrightness) / (255.0 - moonMinBrightness))
            .clamp(0.0, 1.0);
    final circularityScore = blob.circularityRatio;

    // Weighted average
    final confidence =
        (angularScore * 0.5) +
        (circularityScore * 0.3) +
        (brightnessScore * 0.2);

    return confidence.clamp(0.0, 1.0);
  }

  /// Calculate point source (star) detection confidence
  static double _calculatePointConfidence(BrightBlob blob) {
    // Stars should be small, bright, and fairly circular
    final sizeScore = blob.area <= pointMaxArea
        ? 1.0
        : (pointMaxArea / blob.area).clamp(0.0, 1.0);
    final brightnessScore = (blob.brightness / 255.0).clamp(0.0, 1.0);
    final circularityScore = blob.circularityRatio;

    // Weighted average
    final confidence =
        (sizeScore * 0.4) + (brightnessScore * 0.3) + (circularityScore * 0.3);

    return confidence.clamp(
      0.5,
      0.95,
    ); // Point sources have moderate confidence
  }
}
