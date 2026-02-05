import 'package:flutter/material.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/mjpeg_viewer.dart';

class FullscreenCameraView extends StatelessWidget {
  final String streamUrl;
  final String streamKey;
  final VoidCallback onConnected;
  final VoidCallback onError;
  final VoidCallback onExit;

  const FullscreenCameraView({
    super.key,
    required this.streamUrl,
    required this.streamKey,
    required this.onConnected,
    required this.onError,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MjpegViewer(
            key: ValueKey(streamKey),
            streamUrl: streamUrl,
            fit: BoxFit.contain,
            onConnected: onConnected,
            onError: onError,
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit),
              color: Colors.white,
              iconSize: 32,
              onPressed: onExit,
            ),
          ),
        ],
      ),
    );
  }
}
