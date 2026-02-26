import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img_lib;

/// Detected bright blob information
class BrightBlob {
  final double centerX;
  final double centerY;
  final double area;
  final double brightness;
  final double circularityRatio;

  BrightBlob({
    required this.centerX,
    required this.centerY,
    required this.area,
    required this.brightness,
    required this.circularityRatio,
  });

  @override
  String toString() =>
      'BrightBlob(center: ($centerX, $centerY), area: $area, brightness: $brightness, circularity: $circularityRatio)';
}

/// Detects bright astronomical objects using computer vision
class BrightnessDetector {
  // Detection thresholds
  static const double minBrightness = 180.0; // 0-255 scale
  static const double minArea = 5.0; // minimum pixels
  static const double maxArea = 50000.0; // maximum pixels for processing
  static const int blurRadius = 2; // radius for noise reduction

  /// Detect bright blobs from raw RGB bytes (more efficient)
  static Future<List<BrightBlob>> detectBrightObjectsFromRGB(
    int width,
    int height,
    Uint8List rgbBytes,
  ) async {
    // Step 1: Convert RGB bytes to grayscale directly
    final grayscale = _convertRGBBytesToGrayscale(width, height, rgbBytes);

    // Step 2: Apply Gaussian blur to reduce noise
    final blurred = _applyGaussianBlur(grayscale, blurRadius);

    // Step 3: Apply adaptive thresholding
    final threshold = _calculateAdaptiveThreshold(blurred);
    final binary = _applyThreshold(blurred, threshold);

    // Step 4: Detect connected components (blobs)
    final blobs = _detectBlobs(binary, grayscale);

    return blobs;
  }

  /// Convert RGB bytes to grayscale (optimized)
  static List<List<int>> _convertRGBBytesToGrayscale(
    int width,
    int height,
    Uint8List rgbBytes,
  ) {
    final grayscale = List.generate(height, (_) => List<int>.filled(width, 0));

    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = rgbBytes[pixelIndex++];
        final g = rgbBytes[pixelIndex++];
        final b = rgbBytes[pixelIndex++];

        // Weighted luminance formula
        final gray = (0.299 * r + 0.587 * g + 0.114 * b).round();
        grayscale[y][x] = gray;
      }
    }

    return grayscale;
  }

  /// Detect bright blobs from image bytes (legacy method for JPEG/PNG)
  static Future<List<BrightBlob>> detectBrightObjects(
    Uint8List imageBytes,
  ) async {
    // Decode image
    img_lib.Image? image = img_lib.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Convert to RGB bytes and use the optimized method
    final width = image.width;
    final height = image.height;
    final rgbBytes = Uint8List(width * height * 3);

    int pixelIndex = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        rgbBytes[pixelIndex++] = pixel.r.toInt();
        rgbBytes[pixelIndex++] = pixel.g.toInt();
        rgbBytes[pixelIndex++] = pixel.b.toInt();
      }
    }

    return detectBrightObjectsFromRGB(width, height, rgbBytes);
  }

  /// Apply Gaussian blur
  static List<List<int>> _applyGaussianBlur(
    List<List<int>> grayscale,
    int radius,
  ) {
    final height = grayscale.length;
    final width = grayscale[0].length;
    final blurred = List.generate(height, (_) => List<int>.filled(width, 0));

    // Simple box blur approximation (faster than true Gaussian)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int sum = 0;
        int count = 0;

        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final ny = y + dy;
            final nx = x + dx;

            if (ny >= 0 && ny < height && nx >= 0 && nx < width) {
              sum += grayscale[ny][nx];
              count++;
            }
          }
        }

        blurred[y][x] = (sum / count).round();
      }
    }

    return blurred;
  }

  /// Calculate adaptive threshold using Otsu's method
  static int _calculateAdaptiveThreshold(List<List<int>> grayscale) {
    final height = grayscale.length;
    final width = grayscale[0].length;

    // Build histogram
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        histogram[grayscale[y][x]]++;
      }
    }

    // Calculate total pixels
    final total = width * height;

    // Otsu's method
    double sum = 0;
    for (int i = 0; i < 256; i++) {
      sum += i * histogram[i];
    }

    double sumB = 0;
    int wB = 0;
    int wF = 0;
    double varMax = 0;
    int threshold = 0;

    for (int i = 0; i < 256; i++) {
      wB += histogram[i];
      if (wB == 0) continue;

      wF = total - wB;
      if (wF == 0) break;

      sumB += i * histogram[i];

      final mB = sumB / wB;
      final mF = (sum - sumB) / wF;

      final varBetween = wB * wF * (mB - mF) * (mB - mF);

      if (varBetween > varMax) {
        varMax = varBetween;
        threshold = i;
      }
    }

    // For astronomical detection, we want bright objects
    // Use higher threshold (above calculated)
    return max(threshold, minBrightness.toInt());
  }

  /// Apply threshold to create binary image
  static List<List<bool>> _applyThreshold(
    List<List<int>> grayscale,
    int threshold,
  ) {
    final height = grayscale.length;
    final width = grayscale[0].length;
    final binary = List.generate(
      height,
      (_) => List<bool>.filled(width, false),
    );

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        binary[y][x] = grayscale[y][x] >= threshold;
      }
    }

    return binary;
  }

  /// Detect connected components (blobs) using flood fill
  static List<BrightBlob> _detectBlobs(
    List<List<bool>> binary,
    List<List<int>> grayscale,
  ) {
    final height = binary.length;
    final width = binary[0].length;
    final visited = List.generate(
      height,
      (_) => List<bool>.filled(width, false),
    );

    final blobs = <BrightBlob>[];

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (binary[y][x] && !visited[y][x]) {
          final blob = _floodFill(binary, visited, grayscale, x, y);

          // Filter by area
          if (blob != null && blob.area >= minArea && blob.area <= maxArea) {
            blobs.add(blob);
          }
        }
      }
    }

    // Sort by brightness (descending)
    blobs.sort((a, b) => b.brightness.compareTo(a.brightness));

    return blobs;
  }

  /// Flood fill to detect a single blob
  static BrightBlob? _floodFill(
    List<List<bool>> binary,
    List<List<bool>> visited,
    List<List<int>> grayscale,
    int startX,
    int startY,
  ) {
    final height = binary.length;
    final width = binary[0].length;

    final stack = <Point<int>>[];
    stack.add(Point(startX, startY));
    visited[startY][startX] = true;

    double sumX = 0;
    double sumY = 0;
    double sumBrightness = 0;
    int pixelCount = 0;
    int perimeter = 0;

    while (stack.isNotEmpty) {
      final point = stack.removeLast();
      final x = point.x;
      final y = point.y;

      sumX += x;
      sumY += y;
      sumBrightness += grayscale[y][x];
      pixelCount++;

      // Check 4-connected neighbors
      final neighbors = [
        Point(x + 1, y),
        Point(x - 1, y),
        Point(x, y + 1),
        Point(x, y - 1),
      ];

      for (final neighbor in neighbors) {
        final nx = neighbor.x;
        final ny = neighbor.y;

        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
          if (binary[ny][nx] && !visited[ny][nx]) {
            visited[ny][nx] = true;
            stack.add(neighbor);
          } else if (!binary[ny][nx]) {
            perimeter++;
          }
        } else {
          perimeter++;
        }
      }
    }

    if (pixelCount == 0) return null;

    final centerX = sumX / pixelCount;
    final centerY = sumY / pixelCount;
    final avgBrightness = sumBrightness / pixelCount;

    // Calculate circularity: 4π * area / perimeter²
    // Perfect circle = 1.0, lower values = less circular
    final circularity = perimeter > 0
        ? (4 * pi * pixelCount) / (perimeter * perimeter)
        : 0.0;

    return BrightBlob(
      centerX: centerX,
      centerY: centerY,
      area: pixelCount.toDouble(),
      brightness: avgBrightness,
      circularityRatio: circularity.clamp(0.0, 1.0),
    );
  }
}
