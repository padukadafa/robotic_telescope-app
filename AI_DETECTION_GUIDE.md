# AI Object Detection for Robotic Telescope

## Overview

This feature implements real-time AI-based object detection for astronomical objects using TensorFlow Lite. The system detects celestial bodies and calculates pointing errors to automatically correct telescope alignment.

## Architecture

The implementation follows clean architecture with clear separation of concerns:

```
lib/
├── core/
│   ├── models/
│   │   └── detection_result.dart          # Data models for detection
│   ├── services/
│   │   ├── tflite_service.dart            # TFLite model inference
│   │   ├── object_detector.dart           # Detection orchestration
│   │   └── telescope_ai_correction.dart   # WebSocket integration
│   └── providers/
│       └── detection_provider.dart        # State management
└── features/
    └── ai_detection/
        ├── ai_detection_screen.dart       # Main UI
        └── widgets/
            ├── detection_overlay.dart     # Visual overlay
            └── detection_info_panel.dart  # Info display
```

## Features

### 1. Real-time Object Detection

- Detects Moon, Jupiter, Saturn, Venus, Mars
- Runs at 5-15 FPS on mid-range devices
- Uses YUV420 to RGB conversion for camera frames
- Confidence threshold filtering (default: 50%)

### 2. Pointing Error Calculation

- Computes object center coordinates
- Calculates deviation from frame center (dx, dy)
- Displays error magnitude and direction
- Visual error vector overlay

### 3. Automatic Telescope Correction

- Sends corrections via WebSocket
- Smoothing filter to reduce jitter (5-frame moving average)
- Configurable correction threshold
- Manual or automatic correction mode

### 4. Visual Feedback

- Bounding boxes around detected objects
- Center crosshair
- Error vector arrows
- Real-time FPS and statistics
- Object confidence display

## Installation

### 1. Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.3.1
  camera: ^0.11.3
  image: ^4.0.0
```

### 2. Model Setup

Place your TensorFlow Lite model and labels in:

```
assets/
└── models/
    ├── detect.tflite    # Your trained model
    └── labels.txt       # Class labels
```

**Labels format** (`labels.txt`):

```
Moon
Jupiter
Saturn
Venus
Mars
```

### 3. Register Provider

The `DetectionProvider` is already registered in `main.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => DetectionProvider()),
    // ... other providers
  ],
)
```

## Usage

### Basic Usage

```dart
import 'package:robotic_telescope/features/ai_detection/ai_detection_screen.dart';

// Navigate to AI detection screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AIDetectionScreen()),
);
```

### Programmatic Control

```dart
// Get provider
final detectionProvider = Provider.of<DetectionProvider>(context, listen: false);

// Initialize
await detectionProvider.initialize(
  modelPath: 'assets/models/detect.tflite',
  labelsPath: 'assets/models/labels.txt',
);

// Initialize camera
await detectionProvider.initializeCamera();

// Start detection
await detectionProvider.startDetection();

// Stop detection
await detectionProvider.stopDetection();
```

### WebSocket Integration

```dart
import 'package:robotic_telescope/core/services/telescope_ai_correction.dart';

// Create correction service
final correctionService = TelescopeAICorrection(
  websocketManager: websocketManager,
  detectionProvider: detectionProvider,
);

// Start auto-correction
correctionService.startAutoCorrection();

// Send single correction
await correctionService.sendCorrection();

// Stop
correctionService.stopAutoCorrection();
```

## Configuration

### Detection Settings

```dart
// Set correction threshold (pixels)
detectionProvider.setCorrectionThreshold(50.0);

// Toggle auto-correction
detectionProvider.toggleAutoCorrection();

// Check if correction needed
if (detectionProvider.needsCorrection()) {
  // Correction required
}
```

### Correction Service Settings

```dart
// Set correction interval
correctionService.setCorrectionInterval(Duration(milliseconds: 500));
```

## Message Format

### Correction Message

Sent to telescope via WebSocket:

```json
{
  "command": "ai_pointing_correction",
  "object": "Moon",
  "confidence": 0.95,
  "error": {
    "dx": -0.15, // Normalized (-1 to 1)
    "dy": 0.08, // Normalized (-1 to 1)
    "dx_pixels": -48.2, // Pixels
    "dy_pixels": 25.6 // Pixels
  },
  "timestamp": "2026-02-18T10:30:45.123Z"
}
```

## Performance Optimization

### Frame Rate Optimization

- Uses frame throttling to prevent overload
- Skips frames if processing is still ongoing
- Moving average smoothing reduces corrections

### Memory Management

- Proper disposal of camera controller
- TFLite interpreter cleanup
- Timer cancellation on dispose

### Best Practices

- Use `ResolutionPreset.medium` for camera
- Set appropriate confidence threshold
- Limit detection to 10 objects per frame
- Use isolates for heavy processing (future enhancement)

## Training Custom Models

### Model Requirements

- Input size: 320x320 or 416x416
- Format: TFLite
- Architecture: YOLO or SSD
- Output: [1, num_detections, 5 + num_classes]

### Recommended Tools

- TensorFlow Model Maker
- YOLOv5/YOLOv8 -> TFLite conversion
- AutoML Vision Edge

### Training Dataset

- Collect images of Moon, planets from telescope
- Label with bounding boxes
- Augment: rotation, brightness, contrast
- Train with transfer learning

## Troubleshooting

### Camera Issues

```dart
// Check camera availability
final cameras = await availableCameras();
print('Available cameras: ${cameras.length}');

// Check permissions
// Android: Add to AndroidManifest.xml
// <uses-permission android:name="android.permission.CAMERA"/>
```

### Model Loading Errors

```dart
// Verify model path
print('Model path: assets/models/detect.tflite');

// Check pubspec.yaml
// flutter:
//   assets:
//     - assets/models/
```

### Low FPS

- Reduce camera resolution
- Increase frame throttling
- Use smaller model (e.g., 320x320)
- Check device thermal throttling

### False Detections

- Increase confidence threshold
- Retrain model with more data
- Add negative samples to training

## Future Enhancements

1. **Isolate-based Processing**
   - Move inference to separate isolate
   - Improve UI responsiveness

2. **Multi-object Tracking**
   - Track multiple objects simultaneously
   - Priority-based tracking

3. **Advanced Correction**
   - Kalman filtering for smoother corrections
   - Predictive tracking for moving objects

4. **Model Updates**
   - Over-the-air model updates
   - A/B testing for models

5. **Analytics**
   - Detection accuracy metrics
   - Performance profiling
   - Error analysis

## API Reference

### DetectionProvider

```dart
class DetectionProvider extends ChangeNotifier {
  // Initialization
  Future<void> initialize({required String modelPath, required String labelsPath});
  Future<void> initializeCamera({CameraDescription? camera});

  // Detection control
  Future<void> startDetection();
  Future<void> stopDetection();

  // Settings
  void toggleAutoCorrection();
  void setCorrectionThreshold(double threshold);

  // Data access
  List<DetectionResult> get currentDetections;
  DetectionResult? get bestDetection;
  PointingError? get pointingError;
  Map<String, dynamic>? getCorrectionData();
  bool needsCorrection();

  // State
  bool get isInitialized;
  bool get isDetecting;
  double get fps;
}
```

### DetectionResult

```dart
class DetectionResult {
  final String objectName;
  final double confidence;
  final BoundingBox boundingBox;
  final ObjectCenter center;

  PointingError calculatePointingError(double frameCenterX, double frameCenterY);
}
```

### TelescopeAICorrection

```dart
class TelescopeAICorrection {
  TelescopeAICorrection({
    required TelescopeWebSocketManager websocketManager,
    required DetectionProvider detectionProvider,
  });

  void startAutoCorrection();
  void stopAutoCorrection();
  Future<void> sendCorrection();
  void setCorrectionInterval(Duration interval);
  void dispose();
}
```

## License

Part of the Robotic Telescope project.

## Support

For issues or questions, please refer to the main project documentation.
