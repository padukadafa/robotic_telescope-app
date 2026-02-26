import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:robotic_telescope/core/providers/astronomical_detection_provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/core/models/astronomical_detection_result.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/mjpeg_viewer.dart';

/// Example screen demonstrating hybrid astronomical detection
class AstronomicalDetectionScreen extends StatefulWidget {
  const AstronomicalDetectionScreen({super.key});

  @override
  State<AstronomicalDetectionScreen> createState() =>
      _AstronomicalDetectionScreenState();
}

class _AstronomicalDetectionScreenState
    extends State<AstronomicalDetectionScreen> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeSystem();
  }

  Future<void> _initializeSystem() async {
    setState(() => _isInitializing = true);

    try {
      final provider = context.read<AstronomicalDetectionProvider>();

      // Initialize detection system
      await provider.initialize();

      // Initialize location
      await provider.initializeLocation();

      // Initialize camera
      await provider.initializeCamera();

      print('✅ System initialized successfully');
    } catch (e) {
      print('❌ Failed to initialize: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Initialization failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Astronomical Detection'),
        backgroundColor: Colors.black,
        actions: [
          // Settings icon for IP camera configuration
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showIPSettingsDialog,
          ),
          // Play/Stop button
          Consumer<AstronomicalDetectionProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: Icon(
                  provider.isDetecting ? Icons.stop : Icons.play_arrow,
                ),
                onPressed: () => _toggleDetection(provider),
              );
            },
          ),
        ],
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Initializing system...',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            )
          : Consumer<AstronomicalDetectionProvider>(
              builder: (context, provider, _) {
                return Column(
                  children: [
                    // Camera preview
                    Expanded(flex: 3, child: _buildCameraPreview(provider)),

                    // Detection info
                    Expanded(flex: 1, child: _buildDetectionInfo(provider)),

                    // Control panel
                    _buildControlPanel(provider),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildCameraPreview(AstronomicalDetectionProvider provider) {
    // Show loading if not initialized
    if (!provider.isInitialized || !provider.locationInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error if any
    if (provider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Use LayoutBuilder to get display size for scaling detection overlays
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Camera view - using IP camera stream by default
            if (provider.useIPCamera)
              MjpegViewer(
                streamUrl: provider.ipCameraUrl,
                fit: BoxFit.cover,
                onConnected: () {
                  print('✅ IP Camera connected');
                },
                onError: () {
                  print('❌ IP Camera connection error');
                },
              )
            else if (provider.cameraController != null &&
                provider.cameraController!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: provider.cameraController!.value.aspectRatio,
                  child: CameraPreview(provider.cameraController!),
                ),
              )
            else
              const Center(
                child: Text(
                  'Camera not available',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // Crosshair overlay
            _buildCrosshair(),

            // Detection overlays for ALL detected objects with proper scaling
            if (provider.currentDetections.isNotEmpty)
              ...provider.currentDetections
                  .map(
                    (detection) => _buildDetectionOverlay(
                      detection,
                      constraints.maxWidth,
                      constraints.maxHeight,
                    ),
                  )
                  .toList(),

            // FPS counter
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${provider.fps.toStringAsFixed(1)} FPS',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Sun warning
            if (provider.sunWarning != null)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          provider.sunWarning!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => provider.confirmSolarFilter(),
                        child: const Text(
                          'CONFIRM FILTER',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCrosshair() {
    return Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CustomPaint(painter: CrosshairPainter()),
      ),
    );
  }

  Widget _buildDetectionOverlay(
    AstronomicalDetectionResult detection,
    double displayWidth,
    double displayHeight,
  ) {
    Color indicatorColor;
    IconData icon;

    if (detection.isSun) {
      indicatorColor = Colors.red;
      icon = Icons.wb_sunny;
    } else if (detection.isMoon) {
      indicatorColor = Colors.orange;
      icon = Icons.brightness_3;
    } else {
      indicatorColor = Colors.cyan;
      icon = Icons.star;
    }

    // Assume detection coordinates are from 640x480 image (common IP camera resolution)
    // Scale to display size
    const double sourceWidth = 640.0;
    const double sourceHeight = 480.0;

    final double scaleX = displayWidth / sourceWidth;
    final double scaleY = displayHeight / sourceHeight;

    // Use uniform scale (smaller of the two) to maintain aspect ratio
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    final double scaledX = detection.centerX * scale;
    final double scaledY = detection.centerY * scale;

    return Positioned(
      left: scaledX - 20,
      top: scaledY - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: indicatorColor, width: 2),
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(icon, color: indicatorColor, size: 16)),
      ),
    );
  }

  Widget _buildDetectionInfo(AstronomicalDetectionProvider provider) {
    final detections = provider.currentDetections;
    final primaryDetection = detections.isNotEmpty ? detections.first : null;

    return Container(
      color: Colors.grey[900],
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detections.isNotEmpty
                  ? 'Detected ${detections.length} object(s)'
                  : 'No detection',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (primaryDetection != null) ...[
              const SizedBox(height: 8),
              Text(
                'Primary: ${primaryDetection.objectName}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Confidence',
                      '${(primaryDetection.confidence * 100).toStringAsFixed(1)}%',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      'δSun',
                      '${primaryDetection.deltaSun.toStringAsFixed(2)}°',
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      'δMoon',
                      '${primaryDetection.deltaMoon.toStringAsFixed(2)}°',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Brightness',
                      primaryDetection.brightness.toStringAsFixed(0),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      'Area',
                      primaryDetection.area.toStringAsFixed(0),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoChip(
                      'Circularity',
                      primaryDetection.circularity.toStringAsFixed(2),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(AstronomicalDetectionProvider provider) {
    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: provider.isDetecting
                ? null
                : () => _toggleDetection(provider),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: !provider.isDetecting
                ? null
                : () => _toggleDetection(provider),
            icon: const Icon(Icons.stop),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: provider.currentDetection == null
                ? null
                : () => _sendCorrection(provider),
            icon: const Icon(Icons.adjust),
            label: const Text('Correct'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleDetection(AstronomicalDetectionProvider provider) async {
    try {
      if (provider.isDetecting) {
        await provider.stopDetection();
      } else {
        // Update telescope position before starting
        final telescopeProvider = context.read<TelescopeProvider>();
        provider.updateTelescopePosition(
          altitude: telescopeProvider.elevation.toDouble(),
          azimuth: telescopeProvider.azimuth.toDouble(),
        );

        await provider.startDetection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _sendCorrection(AstronomicalDetectionProvider provider) {
    final correctionData = provider.getCorrectionData();
    if (correctionData != null) {
      // Send to telescope via WebSocket
      print('Sending correction: $correctionData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correction sent to telescope'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// Show IP camera settings dialog
  void _showIPSettingsDialog() {
    final provider = context.read<AstronomicalDetectionProvider>();
    final TextEditingController urlController = TextEditingController(
      text: provider.ipCameraUrl,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('IP Camera Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Camera URL',
                hintText: 'http://192.168.4.50:81/stream',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Contoh:\nhttp://192.168.4.50:81/stream\nhttp://192.168.1.100:8080/stream',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                provider.setIPCameraUrl(newUrl);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Camera URL updated: $newUrl'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Custom painter for crosshair
class CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw circle
    canvas.drawCircle(center, size.width / 2, paint);

    // Draw crosshair lines
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      paint,
    );
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
