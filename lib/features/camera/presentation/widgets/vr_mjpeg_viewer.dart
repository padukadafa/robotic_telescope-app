import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// VR MJPEG Viewer widget that displays side-by-side stereoscopic view
/// using a single camera stream connection to avoid ESP32-CAM multi-client limitation
class VRMjpegViewer extends StatefulWidget {
  final String streamUrl;
  final VoidCallback? onError;
  final VoidCallback? onConnected;

  const VRMjpegViewer({
    super.key,
    required this.streamUrl,
    this.onError,
    this.onConnected,
  });

  @override
  State<VRMjpegViewer> createState() => _VRMjpegViewerState();
}

class _VRMjpegViewerState extends State<VRMjpegViewer> {
  http.Client? _httpClient;
  Stream<Uint8List>? _stream;
  bool _isConnected = false;
  Uint8List? _currentFrame;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  @override
  void didUpdateWidget(VRMjpegViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.streamUrl != widget.streamUrl) {
      _cancelStream();
      _initializeStream();
    }
  }

  void _initializeStream() {
    setState(() {
      _isConnected = false;
    });

    _stream = _getMjpegStream(widget.streamUrl);
    _stream?.listen(
      (frame) {
        if (mounted) {
          setState(() {
            _currentFrame = frame;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          widget.onError?.call();
        }
      },
    );
  }

  Stream<Uint8List> _getMjpegStream(String url) async* {
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient!
          .send(request)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('Failed to connect to stream: ${response.statusCode}');
      }

      if (!_isConnected) {
        setState(() {
          _isConnected = true;
        });
        widget.onConnected?.call();
      }

      final List<int> buffer = [];
      const jpegStart = [0xFF, 0xD8]; // JPEG start marker
      const jpegEnd = [0xFF, 0xD9]; // JPEG end marker

      await for (var chunk in response.stream) {
        buffer.addAll(chunk);

        // Look for JPEG frames in buffer
        while (true) {
          // Find JPEG start
          int startIndex = -1;
          for (int i = 0; i < buffer.length - 1; i++) {
            if (buffer[i] == jpegStart[0] && buffer[i + 1] == jpegStart[1]) {
              startIndex = i;
              break;
            }
          }

          if (startIndex == -1) {
            if (buffer.length > 1) {
              buffer.removeRange(0, buffer.length - 1);
            }
            break;
          }

          // Find JPEG end after start
          int endIndex = -1;
          for (int i = startIndex + 2; i < buffer.length - 1; i++) {
            if (buffer[i] == jpegEnd[0] && buffer[i + 1] == jpegEnd[1]) {
              endIndex = i + 1;
              break;
            }
          }

          if (endIndex == -1) {
            if (startIndex > 0) {
              buffer.removeRange(0, startIndex);
            }
            break;
          }

          // Extract complete JPEG frame
          final frame = Uint8List.fromList(
            buffer.sublist(startIndex, endIndex + 1),
          );
          yield frame;

          // Remove processed frame from buffer
          buffer.removeRange(0, endIndex + 1);
        }
      }
    } catch (e) {
      if (mounted) {
        widget.onError?.call();
      }
      rethrow;
    }
  }

  void _cancelStream() {
    _httpClient?.close();
    _httpClient = null;
  }

  @override
  void dispose() {
    _cancelStream();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentFrame == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Connecting to camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    // Side-by-side stereoscopic view with barrel distortion
    return Row(
      children: [
        // Left eye view with barrel distortion
        Expanded(child: _buildVRLensView(_currentFrame!)),
        // Center divider
        Container(width: 2, color: Colors.white.withValues(alpha: 0.3)),
        // Right eye view with barrel distortion
        Expanded(child: _buildVRLensView(_currentFrame!)),
      ],
    );
  }

  /// Builds a single VR lens view with pincushion distortion correction
  Widget _buildVRLensView(Uint8List frameData) {
    return Container(
      color: Colors.black,
      child: FutureBuilder<ui.Image>(
        future: _decodeImage(frameData),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(color: Colors.black);
          }
          return CustomPaint(
            painter: _VRDistortionPainter(snapshot.data!),
            size: Size.infinite,
          );
        },
      ),
    );
  }

  Future<ui.Image> _decodeImage(Uint8List data) async {
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}

/// Pincushion distortion painter for VR lens correction
class _VRDistortionPainter extends CustomPainter {
  final ui.Image image;

  // Distortion coefficients for Cardboard-style lenses
  static const double k1 = 0.22;
  static const double k2 = 0.24;

  _VRDistortionPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final maxRadius = size.width / 2;

    final paint = Paint()..filterQuality = FilterQuality.medium;

    // Apply pincushion pre-distortion
    for (double y = 0; y < size.height; y += 1.5) {
      for (double x = 0; x < size.width; x += 1.5) {
        final dx = (x - centerX) / maxRadius;
        final dy = (y - centerY) / maxRadius;
        final r2 = dx * dx + dy * dy;
        final distortion = 1.0 + k1 * r2 + k2 * r2 * r2;

        final srcX = centerX + dx * maxRadius * distortion;
        final srcY = centerY + dy * maxRadius * distortion;

        if (srcX >= 0 && srcX < size.width && srcY >= 0 && srcY < size.height) {
          final srcRect = Rect.fromLTWH(
            srcX * image.width / size.width,
            srcY * image.height / size.height,
            1.5 * image.width / size.width,
            1.5 * image.height / size.height,
          );
          final dstRect = Rect.fromLTWH(x, y, 1.5, 1.5);
          canvas.drawImageRect(image, srcRect, dstRect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_VRDistortionPainter oldDelegate) => true;
}
