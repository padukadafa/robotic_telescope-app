import 'dart:async';
import 'dart:typed_data';
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

    // Side-by-side stereoscopic view
    return Row(
      children: [
        // Left eye view
        Expanded(
          child: Image.memory(
            _currentFrame!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
        // Center divider
        Container(width: 2, color: Colors.white.withValues(alpha: 0.3)),
        // Right eye view (duplicate)
        Expanded(
          child: Image.memory(
            _currentFrame!,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          ),
        ),
      ],
    );
  }
}
