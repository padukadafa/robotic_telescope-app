# AI Object Detection - Quick Start

## 🚀 What Was Implemented

A complete AI-based object detection system for your robotic telescope app using:

- **TensorFlow Lite** for on-device inference
- **Clean architecture** with proper separation of concerns
- **Real-time detection** at 5-15 FPS
- **Automatic pointing correction** via WebSocket
- **Visual feedback** with bounding boxes and error vectors

## 📁 Files Created

### Core Models

- `lib/core/models/detection_result.dart` - Data models for detections

### Services

- `lib/core/services/tflite_service.dart` - TFLite model inference
- `lib/core/services/object_detector.dart` - Detection orchestration
- `lib/core/services/telescope_ai_correction.dart` - WebSocket integration

### Provider

- `lib/core/providers/detection_provider.dart` - State management

### UI Components

- `lib/features/ai_detection/ai_detection_screen.dart` - Main screen
- `lib/features/ai_detection/widgets/detection_overlay.dart` - Visual overlay
- `lib/features/ai_detection/widgets/detection_info_panel.dart` - Info display
- `lib/features/ai_detection/navigation_examples.dart` - Integration examples

### Assets

- `assets/models/labels.txt` - Object labels (Moon, Jupiter, Saturn, Venus, Mars)
- `assets/models/README.md` - Model setup guide

### Documentation

- `AI_DETECTION_GUIDE.md` - Complete documentation

## ⚡ Quick Start

### Step 1: Get a Model

You need a TensorFlow Lite model. Choose one:

**Option A: Download pre-trained model**

```bash
# From TensorFlow Model Zoo (general objects)
cd assets/models
wget https://storage.googleapis.com/download.tensorflow.org/models/tflite/coco_ssd_mobilenet_v1_1.0_quant_2018_06_29.zip
unzip *.zip
mv detect.tflite .
```

**Option B: Train custom model**

1. Collect telescope images of Moon/planets
2. Label with bounding boxes
3. Train using TensorFlow Lite Model Maker
4. Export to `assets/models/detect.tflite`

**Note:** For best results, train a custom model on your telescope images.

### Step 2: Run the App

```bash
# Make sure dependencies are installed
flutter pub get

# Run on device (camera required)
flutter run
```

### Step 3: Navigate to AI Detection

Add navigation to your app. Example:

```dart
// In any screen, add a button:
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIDetectionScreen(),
      ),
    );
  },
  child: const Text('AI Detection'),
)
```

See `lib/features/ai_detection/navigation_examples.dart` for more examples.

### Step 4: Use the Feature

1. **Connect to telescope** via WebSocket first
2. **Tap "AI Detection"** in your app
3. **Point camera** at Moon or planet
4. **Tap "Start"** to begin detection
5. **Enable "Auto"** for automatic correction

## 🎯 How It Works

```
Camera Frame → YUV to RGB → TFLite Model → Detection Results
                                                    ↓
                                           Pointing Error
                                                    ↓
                                          WebSocket Message
                                                    ↓
                                         ESP32 Telescope
```

### Detection Flow

1. Camera captures frame (YUV420 format)
2. Converts to RGB and resizes to 320x320
3. TFLite model runs inference
4. Detects objects with >50% confidence
5. Calculates center point of detected object
6. Computes error from frame center
7. Sends correction via WebSocket

### Message Format

```json
{
  "command": "ai_pointing_correction",
  "object": "Moon",
  "confidence": 0.95,
  "error": {
    "dx": -0.15,
    "dy": 0.08,
    "dx_pixels": -48.2,
    "dy_pixels": 25.6
  }
}
```

## 🔧 Configuration

### Adjust Detection Sensitivity

In the AI Detection screen, tap ⚙️ Settings:

- **Correction Threshold**: 10-200 pixels (default: 50)
  - Lower = more sensitive (corrects small errors)
  - Higher = less sensitive (ignores small errors)

### Programmatic Configuration

```dart
final provider = Provider.of<DetectionProvider>(context);

// Set threshold
provider.setCorrectionThreshold(75.0);

// Toggle auto-correction
provider.toggleAutoCorrection();

// Check if correction needed
if (provider.needsCorrection()) {
  // Manual correction logic
}
```

## 📱 UI Features

### Info Panel (Top)

- **Status**: Detecting / Idle
- **FPS**: Real-time frame rate
- **Object**: Detected object name
- **Confidence**: Detection confidence %
- **Error X/Y**: Pointing error in pixels
- **Statistics**: Frames, detections, hit rate

### Visual Overlay

- **Green crosshair**: Frame center (target)
- **Red box**: Best detection
- **Blue boxes**: Other detections
- **Yellow arrow**: Pointing error vector

### Control Buttons

- **Start/Stop**: Begin/end detection
- **Auto**: Enable automatic correction

## 🔌 WebSocket Integration

### Manual Usage

```dart
import 'package:robotic_telescope/core/services/telescope_ai_correction.dart';

// Create service
final correctionService = TelescopeAICorrection(
  websocketManager: websocketManager,
  detectionProvider: detectionProvider,
);

// Start auto-correction (sends corrections every 500ms)
correctionService.startAutoCorrection();

// Or send single correction
await correctionService.sendCorrection();

// Stop
correctionService.stopAutoCorrection();
```

## 🎨 Customization

### Add to Navigation Drawer

```dart
ListTile(
  leading: const Icon(Icons.camera_alt),
  title: const Text('AI Detection'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIDetectionScreen()),
    );
  },
)
```

### Add to Bottom Navigation

```dart
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Control'),
    BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'AI Detect'),
  ],
)
```

### Modify Detected Objects

Edit `assets/models/labels.txt`:

```
Moon
Jupiter
Saturn
Venus
Mars
Sun        # Add new objects
Mercury
```

Then retrain your model with those classes.

## ⚠️ Important Notes

1. **Camera Permission Required**
   - Android: Already in AndroidManifest.xml
   - iOS: Add to Info.plist if needed

2. **Model Not Included**
   - You must provide your own TFLite model
   - Place at `assets/models/detect.tflite`
   - See `assets/models/README.md` for setup

3. **WebSocket Connection**
   - Connect to telescope before using AI detection
   - Auto-correction requires active WebSocket

4. **Performance**
   - Runs on-device (no internet required)
   - Target: 5-15 FPS on mid-range phones
   - Lower camera resolution if FPS too low

## 🐛 Troubleshooting

### Problem: "Model not found"

**Solution**: Place `detect.tflite` in `assets/models/`

### Problem: Low FPS (< 5)

**Solutions**:

- Use smaller model (320x320 instead of 416x416)
- Reduce camera resolution
- Check device thermal throttling

### Problem: No detections

**Solutions**:

- Lower confidence threshold in code
- Ensure proper lighting
- Train model on your specific telescope images
- Test with test images first

### Problem: Jittery corrections

**Solutions**:

- Increase correction threshold
- Increase smoothing filter size (in `telescope_ai_correction.dart`)
- Reduce correction frequency

### Problem: Camera not working

**Solutions**:

- Check permissions
- Restart app
- Try different ResolutionPreset

## 📚 Next Steps

1. **Train Custom Model**
   - Best accuracy for your telescope
   - See `assets/models/README.md`

2. **Optimize Performance**
   - Profile FPS on target device
   - Adjust resolution/model size

3. **Test Thoroughly**
   - Test with real sky objects
   - Validate corrections accuracy

4. **Integrate with App**
   - Add to main navigation
   - Connect with existing features

## 📖 Full Documentation

See `AI_DETECTION_GUIDE.md` for:

- Complete API reference
- Advanced configuration
- Training guide
- WebSocket protocol details
- Performance optimization tips

## 🎓 Architecture Summary

**Presentation Layer** (UI)

- `AIDetectionScreen` - Main screen
- `DetectionOverlay` - Visual feedback
- `DetectionInfoPanel` - Stats display

**Data Layer** (Logic)

- `TFLiteService` - Model inference
- `ObjectDetector` - Frame processing
- `TelescopeAICorrection` - WebSocket comm

**State Management**

- `DetectionProvider` - Centralized state

**Clean separation ensures:**

- Testability
- Maintainability
- Reusability
- Performance

## ✅ Ready to Use!

Your AI detection system is ready. Just add a TFLite model and start detecting!

For questions, see `AI_DETECTION_GUIDE.md` or the code comments.

---

Built with ❤️ for robotic telescope automation.
