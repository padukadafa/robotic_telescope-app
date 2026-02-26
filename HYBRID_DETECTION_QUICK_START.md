# Quick Start: Hybrid Astronomical Detection

## 🚀 Get Started in 5 Minutes

### Step 1: Verify Installation

All required dependencies are already in your `pubspec.yaml`. No new packages needed!

### Step 2: Add to Your UI

Import the example screen in your navigation:

```dart
import 'package:robotic_telescope/features/ai_detection/astronomical_detection_example_screen.dart';

// In your navigation/menu:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const AstronomicalDetectionScreen(),
  ),
);
```

### Step 3: Run the App

```bash
flutter run
```

### Step 4: Grant Permissions

When prompted, allow:

- ✅ Camera access
- ✅ Location access

### Step 5: Start Detection

1. Wait for initialization (camera + GPS)
2. Tap the **Play** button
3. Point telescope at a target
4. Watch real-time detection!

## 📱 Using the Detection System

### Basic Workflow

```dart
// 1. Get the provider
final provider = Provider.of<AstronomicalDetectionProvider>(context);

// 2. Initialize
await provider.initialize();
await provider.initializeLocation();
await provider.initializeCamera();

// 3. Update telescope position
provider.updateTelescopePosition(
  altitude: currentElevation,
  azimuth: currentAzimuth,
);

// 4. Start detection
await provider.startDetection();

// 5. Read results
final detection = provider.currentDetection;
if (detection != null) {
  print('Detected: ${detection.objectName}');
  print('Type: ${detection.type}'); // "sun", "moon", or "point"
  print('Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%');

  // Get pointing error
  final error = provider.getPointingError();
  print('Error: dx=${error?['dx']}, dy=${error?['dy']}');
}
```

## 🎯 Integration with Telescope Control

### Sync with TelescopeProvider

```dart
// Listen to telescope position changes
final telescopeProvider = Provider.of<TelescopeProvider>(context);
telescopeProvider.addListener(() {
  detectionProvider.updateTelescopePosition(
    altitude: telescopeProvider.elevation.toDouble(),
    azimuth: telescopeProvider.azimuth.toDouble(),
  );
});
```

### Send Corrections via WebSocket

```dart
if (provider.needsCorrection()) {
  final correctionData = provider.getCorrectionData();

  // Send to ESP32 telescope controller
  telescopeProvider.webSocket?.add(
    jsonEncode(correctionData),
  );
}
```

## ⚙️ Configuration

### Adjust Detection Sensitivity

Edit `lib/core/services/hybrid_classifier.dart`:

```dart
// Make Sun detection more strict (reduce false positives)
static const double sunAngularThreshold = 1.5;  // Default: 2.0
static const double sunMinBrightness = 230.0;   // Default: 220.0

// Make star detection more sensitive
static const double pointMaxArea = 200.0;  // Default: 150.0
```

### Adjust Brightness Threshold

Edit `lib/core/services/brightness_detector.dart`:

```dart
// Detect fainter objects
static const double minBrightness = 150.0;  // Default: 180.0

// For dark skies, use:
static const double minBrightness = 120.0;
```

## 🌞 Sun Safety

### Automatic Protection

The system includes built-in safety:

```dart
// Sun detected → Automatic warning
if (detection.isSun) {
  // 1. Warning banner appears
  // 2. Detection can auto-stop
  // 3. Requires solar filter confirmation
}

// Confirm solar filter before tracking
provider.confirmSolarFilter();
```

### Disable Sun Detection (Optional)

```dart
// If you only want stars/moon
provider.toggleSunDetection();
```

## 📊 Performance Optimization

### For Mid-Range Devices

```dart
// Lower camera resolution
await provider.initializeCamera();
// Then manually adjust:
_cameraController = CameraController(
  camera,
  ResolutionPreset.low,  // Instead of .medium
  enableAudio: false,
  imageFormatGroup: ImageFormatGroup.yuv420,
);
```

### For High FPS

```dart
// In brightness_detector.dart
static const int blurRadius = 1;  // Reduce from 2
static const double maxArea = 20000.0;  // Reduce processing
```

## 🧪 Testing

### Test Single Frame

```dart
// Capture one frame and test detection
final service = Services.astronomicalDetection;
service.updateTelescopePosition(altitude: 45, azimuth: 180);

final result = await service.detectSingleFrame(
  imageBytes: yourImageBytes,
  telescopeAltitude: 45.0,
  telescopeAzimuth: 180.0,
  latitude: 37.7749,
  longitude: -122.4194,
);

print('Result: ${result?.toJson()}');
```

### Debug Output

Enable verbose logging in `astronomical_detection_service.dart`:

```dart
// Uncomment debug prints
print('☀️ Sun position: ${sunAltAz['altitude']}° alt, ${sunAltAz['azimuth']}° az');
print('🌙 Moon position: ${moonAltAz['altitude']}° alt, ${moonAltAz['azimuth']}° az');
print('📐 Angular distances: Sun=${deltaSun}°, Moon=${deltaMoon}°');
print('🔆 Detected ${blobs.length} bright blobs');
```

## 🎨 UI Customization

### Custom Detection Overlay

```dart
// In your camera preview
if (detection != null) {
  // Draw custom indicator
  Positioned(
    left: detection.centerX,
    top: detection.centerY,
    child: Icon(
      detection.isSun ? Icons.wb_sunny :
      detection.isMoon ? Icons.brightness_3 :
      Icons.star,
      color: Colors.green,
    ),
  )
}
```

### Show Angular Distance

```dart
Text('Distance to Sun: ${detection.deltaSun.toStringAsFixed(2)}°')
Text('Distance to Moon: ${detection.deltaMoon.toStringAsFixed(2)}°')
```

## 🐛 Troubleshooting

### "Camera not initialized"

```dart
// Ensure camera initialization completes
await provider.initializeCamera();
await Future.delayed(Duration(milliseconds: 500));
await provider.startDetection();
```

### "Location not initialized"

```dart
// Check permissions
final permission = await Geolocator.checkPermission();
print('Location permission: $permission');

// Request if needed
if (permission == LocationPermission.denied) {
  await Geolocator.requestPermission();
}
```

### Low FPS

```dart
// Check if isolate is working
print('FPS: ${provider.fps}');
print('Frames: ${provider.frameCount}');

// If FPS < 5, reduce resolution or image processing
```

### No Detections

```dart
// Check telescope position
print('Telescope: ${provider.telescopeAltitude}° alt, ${provider.telescopeAzimuth}° az');

// Check location
print('Location: ${provider.latitude}, ${provider.longitude}');

// Check camera exposure
// (May need to adjust manually for night sky)
```

## 📝 Example: Complete Integration

```dart
class MyTelescopeScreen extends StatefulWidget {
  @override
  State<MyTelescopeScreen> createState() => _MyTelescopeScreenState();
}

class _MyTelescopeScreenState extends State<MyTelescopeScreen> {
  late AstronomicalDetectionProvider _detectionProvider;
  late TelescopeProvider _telescopeProvider;

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  Future<void> _initSystem() async {
    _detectionProvider = context.read<AstronomicalDetectionProvider>();
    _telescopeProvider = context.read<TelescopeProvider>();

    // Initialize detection
    await _detectionProvider.initialize();
    await _detectionProvider.initializeLocation();
    await _detectionProvider.initializeCamera();

    // Sync telescope position
    _telescopeProvider.addListener(_updateTelescopePosition);

    // Start detection
    await _detectionProvider.startDetection();
  }

  void _updateTelescopePosition() {
    _detectionProvider.updateTelescopePosition(
      altitude: _telescopeProvider.elevation.toDouble(),
      azimuth: _telescopeProvider.azimuth.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AstronomicalDetectionProvider>(
        builder: (context, provider, _) {
          final detection = provider.currentDetection;

          return Column(
            children: [
              // Camera preview
              Expanded(
                child: CameraPreview(provider.cameraController!),
              ),

              // Detection info
              if (detection != null)
                Card(
                  child: ListTile(
                    leading: Icon(
                      detection.isSun ? Icons.wb_sunny :
                      detection.isMoon ? Icons.brightness_3 :
                      Icons.star,
                    ),
                    title: Text('Detected: ${detection.objectName}'),
                    subtitle: Text(
                      'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.adjust),
                      onPressed: () => _sendCorrection(provider),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _sendCorrection(AstronomicalDetectionProvider provider) {
    final data = provider.getCorrectionData();
    if (data != null) {
      _telescopeProvider.webSocket?.add(jsonEncode(data));
    }
  }

  @override
  void dispose() {
    _telescopeProvider.removeListener(_updateTelescopePosition);
    super.dispose();
  }
}
```

## 🎓 Next Steps

1. **Test with real sky**: Point at Moon or bright star
2. **Calibrate thresholds**: Adjust for your telescope/camera
3. **Integrate with tracking**: Use corrections for auto-tracking
4. **Add logging**: Record detection history
5. **Implement auto-focus**: Use detection confidence

## 📚 Further Reading

- [HYBRID_DETECTION_SYSTEM.md](HYBRID_DETECTION_SYSTEM.md) - Complete documentation
- [astronomical_calculator.dart](lib/core/services/astronomical_calculator.dart) - Ephemeris algorithms
- [hybrid_classifier.dart](lib/core/services/hybrid_classifier.dart) - Classification logic

## 🆘 Support

If you encounter issues:

1. Check logs for errors
2. Verify permissions granted
3. Test telescope position updates
4. Try single-frame detection first

---

**Happy Stargazing!** 🔭✨
