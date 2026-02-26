import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:robotic_telescope/core/providers/detection_provider.dart';
import 'package:robotic_telescope/features/ai_detection/widgets/detection_overlay.dart';
import 'package:robotic_telescope/features/ai_detection/widgets/detection_info_panel.dart';

/// Screen for AI-based object detection and tracking
class AIDetectionScreen extends StatefulWidget {
  const AIDetectionScreen({super.key});

  @override
  State<AIDetectionScreen> createState() => _AIDetectionScreenState();
}

class _AIDetectionScreenState extends State<AIDetectionScreen> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initializeDetection();
  }

  Future<void> _initializeDetection() async {
    if (_isInitializing) return;

    setState(() => _isInitializing = true);

    try {
      final provider = context.read<DetectionProvider>();

      // Initialize detection system
      await provider.initialize(
        modelPath: 'assets/models/detect.tflite',
        labelsPath: 'assets/models/labels.txt',
      );

      // Initialize camera
      await provider.initializeCamera();

      setState(() => _isInitializing = false);
    } catch (e) {
      setState(() => _isInitializing = false);
      if (mounted) {
        _showError('Initialization failed: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Object Detection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: _isInitializing
          ? _buildLoadingView()
          : Consumer<DetectionProvider>(
              builder: (context, provider, child) {
                if (!provider.isInitialized) {
                  return _buildErrorView('Detection system not initialized');
                }

                if (provider.cameraController == null ||
                    !provider.cameraController!.value.isInitialized) {
                  return _buildErrorView('Camera not initialized');
                }

                return _buildDetectionView(provider);
              },
            ),
      floatingActionButton: _buildControlButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initializing AI Detection System...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeDetection,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectionView(DetectionProvider provider) {
    return Stack(
      children: [
        // Camera preview
        Positioned.fill(child: CameraPreview(provider.cameraController!)),

        // Detection overlay
        Positioned.fill(
          child: DetectionOverlay(
            detections: provider.currentDetections,
            bestDetection: provider.bestDetection,
            pointingError: provider.pointingError,
            cameraController: provider.cameraController!,
          ),
        ),

        // Info panel
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DetectionInfoPanel(
            bestDetection: provider.bestDetection,
            pointingError: provider.pointingError,
            fps: provider.fps,
            frameCount: provider.frameCount,
            detectionCount: provider.detectionCount,
            isDetecting: provider.isDetecting,
          ),
        ),

        // Error message
        if (provider.errorMessage != null)
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Card(
              color: Colors.red[700],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        provider.errorMessage!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: provider.clearError,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Consumer<DetectionProvider>(
      builder: (context, provider, child) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Start/Stop detection button
              FloatingActionButton.extended(
                heroTag: 'detection_toggle',
                onPressed: () async {
                  if (provider.isDetecting) {
                    await provider.stopDetection();
                  } else {
                    await provider.startDetection();
                  }
                },
                backgroundColor: provider.isDetecting
                    ? Colors.red
                    : Colors.green,
                icon: Icon(
                  provider.isDetecting ? Icons.stop : Icons.play_arrow,
                ),
                label: Text(provider.isDetecting ? 'Stop' : 'Start'),
              ),

              // Auto-correction toggle
              FloatingActionButton.extended(
                heroTag: 'auto_correction',
                onPressed: provider.toggleAutoCorrection,
                backgroundColor: provider.autoCorrection
                    ? Colors.blue
                    : Colors.grey[700],
                icon: Icon(
                  provider.autoCorrection
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                ),
                label: const Text('Auto'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSettings() {
    final provider = context.read<DetectionProvider>();

    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detection Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Correction threshold slider
            const Text('Correction Threshold (pixels)'),
            Slider(
              value: provider.correctionThreshold,
              min: 10,
              max: 200,
              divisions: 19,
              label: provider.correctionThreshold.toStringAsFixed(0),
              onChanged: (value) {
                provider.setCorrectionThreshold(value);
              },
            ),

            const SizedBox(height: 16),

            // Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'How it works:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• AI detects Moon, Jupiter, Saturn, Venus, Mars\n'
                      '• Calculates pointing error from frame center\n'
                      '• Sends corrections via WebSocket\n'
                      '• Auto mode enables continuous correction',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
