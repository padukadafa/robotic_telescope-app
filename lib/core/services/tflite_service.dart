import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img_lib;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:robotic_telescope/core/models/detection_result.dart';

/// Service for TFLite model inference
class TFLiteService {
  Interpreter? _interpreter;
  List<String>? _labels;
  bool _isInitialized = false;

  // Model configuration
  static const int inputSize = 320; // Model input size (320x320)
  static const double confidenceThreshold =
      0.5; // Minimum confidence for detection
  static const int maxDetections = 10; // Maximum number of detections per frame

  bool get isInitialized => _isInitialized;

  /// Initialize the TFLite model
  Future<void> initialize({
    required String modelPath,
    required String labelsPath,
  }) async {
    try {
      // Load the model
      _interpreter = await Interpreter.fromAsset(modelPath);

      // Load labels
      final labelsData = await rootBundle.loadString(labelsPath);
      _labels = labelsData
          .split('\n')
          .where((label) => label.isNotEmpty)
          .toList();

      _isInitialized = true;
      print('✅ TFLite model initialized successfully');
      print('   Input shape: ${_interpreter?.getInputTensor(0).shape}');
      print('   Output shape: ${_interpreter?.getOutputTensor(0).shape}');
      print('   Labels loaded: ${_labels?.length}');
    } catch (e) {
      print('❌ Error initializing TFLite model: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Run object detection on raw RGB bytes (more efficient)
  Future<List<DetectionResult>> detectObjectsFromRGB(
    int width,
    int height,
    Uint8List rgbBytes,
  ) async {
    if (!_isInitialized || _interpreter == null || _labels == null) {
      throw Exception('TFLite service not initialized');
    }

    try {
      // Preprocess RGB bytes directly
      final inputImage = _preprocessRGBBytes(width, height, rgbBytes);

      // Run inference
      final outputs = _runInference(inputImage);

      // Parse results
      final detections = _parseDetections(outputs);

      return detections;
    } catch (e) {
      print('❌ Error during object detection: $e');
      return [];
    }
  }

  /// Run object detection on encoded image bytes (legacy - for JPEG/PNG)
  Future<List<DetectionResult>> detectObjects(Uint8List imageBytes) async {
    if (!_isInitialized || _interpreter == null || _labels == null) {
      throw Exception('TFLite service not initialized');
    }

    try {
      // Decode and preprocess image
      final inputImage = _preprocessImage(imageBytes);

      // Run inference
      final outputs = _runInference(inputImage);

      // Parse results
      final detections = _parseDetections(outputs);

      return detections;
    } catch (e) {
      print('❌ Error during object detection: $e');
      return [];
    }
  }

  /// Preprocess raw RGB bytes for model input (more efficient)
  List<List<List<List<double>>>> _preprocessRGBBytes(
    int width,
    int height,
    Uint8List rgbBytes,
  ) {
    // Create image from RGB bytes
    final image = img_lib.Image.fromBytes(
      width: width,
      height: height,
      bytes: rgbBytes.buffer,
      numChannels: 3,
    );

    // Resize to model input size
    final resizedImage = img_lib.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Convert to normalized float array [1, 320, 320, 3]
    var input = List.generate(
      1,
      (index) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r / 255.0, // Normalize to [0, 1]
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        }),
      ),
    );

    return input;
  }

  /// Preprocess encoded image bytes for model input (legacy)
  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    // Decode image
    img_lib.Image? image = img_lib.decodeImage(imageBytes);
    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize to model input size
    img_lib.Image resizedImage = img_lib.copyResize(
      image,
      width: inputSize,
      height: inputSize,
    );

    // Convert to normalized float array [1, 320, 320, 3]
    var input = List.generate(
      1,
      (index) => List.generate(
        inputSize,
        (y) => List.generate(inputSize, (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [
            pixel.r / 255.0, // Normalize to [0, 1]
            pixel.g / 255.0,
            pixel.b / 255.0,
          ];
        }),
      ),
    );

    return input;
  }

  /// Run model inference
  Map<String, dynamic> _runInference(List<List<List<List<double>>>> input) {
    // Output tensors for YOLO-style detection
    // Output shape: [1, num_detections, 5 + num_classes]
    // Format: [x, y, w, h, confidence, class_scores...]

    // Allocate output buffer dynamically based on model output shape
    var outputTensors = List.generate(
      _interpreter!.getOutputTensors().length,
      (index) => List.generate(
        maxDetections,
        (i) => List.filled(_interpreter!.getOutputTensor(index).shape[2], 0.0),
      ),
    );

    // Run inference
    _interpreter!.run(input, outputTensors[0]);

    return {'detections': outputTensors[0]};
  }

  /// Parse detection results
  List<DetectionResult> _parseDetections(Map<String, dynamic> outputs) {
    List<DetectionResult> results = [];
    var detections = outputs['detections'] as List;

    for (var detection in detections) {
      // Parse detection format: [x, y, w, h, confidence, class_scores...]
      double x = (detection[0] as num).toDouble();
      double y = (detection[1] as num).toDouble();
      double w = (detection[2] as num).toDouble();
      double h = (detection[3] as num).toDouble();
      double confidence = (detection[4] as num).toDouble();

      // Skip low confidence detections
      if (confidence < confidenceThreshold) continue;

      // Find class with highest score
      int classIndex = 0;
      double maxScore = 0.0;
      for (int i = 5; i < detection.length; i++) {
        double score = (detection[i] as num).toDouble();
        if (score > maxScore) {
          maxScore = score;
          classIndex = i - 5;
        }
      }

      // Get class label
      String label = classIndex < _labels!.length
          ? _labels![classIndex]
          : 'unknown';

      // Create bounding box
      final boundingBox = BoundingBox(
        left: (x - w / 2) * inputSize,
        top: (y - h / 2) * inputSize,
        right: (x + w / 2) * inputSize,
        bottom: (y + h / 2) * inputSize,
      );

      // Create detection result
      results.add(
        DetectionResult(
          objectName: label,
          confidence: confidence * maxScore,
          boundingBox: boundingBox,
          center: boundingBox.getCenter(),
        ),
      );
    }

    return results;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isInitialized = false;
    print('🧹 TFLite service disposed');
  }
}
