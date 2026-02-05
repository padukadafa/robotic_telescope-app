import 'package:flutter/material.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/vr_mjpeg_viewer.dart';

class VRCameraView extends StatelessWidget {
  final String streamUrl;
  final String streamKey;
  final VoidCallback onConnected;
  final VoidCallback onError;
  final VoidCallback onExit;
  final bool hasError;

  const VRCameraView({
    super.key,
    required this.streamUrl,
    required this.streamKey,
    required this.onConnected,
    required this.onError,
    required this.onExit,
    required this.hasError,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          VRMjpegViewer(
            key: ValueKey(streamKey),
            streamUrl: streamUrl,
            onConnected: onConnected,
            onError: onError,
          ),
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.view_in_ar, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'VR MODE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 20,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.close),
              color: Colors.white,
              iconSize: 32,
              onPressed: onExit,
              tooltip: 'Exit VR Mode',
            ),
          ),
          if (hasError)
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Connection Error',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
