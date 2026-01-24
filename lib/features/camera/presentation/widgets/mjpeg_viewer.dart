import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MjpegViewer extends StatefulWidget {
  final String streamUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Duration timeout;
  final VoidCallback? onError;
  final VoidCallback? onConnected;

  const MjpegViewer({
    super.key,
    required this.streamUrl,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.timeout = const Duration(seconds: 5),
    this.onError,
    this.onConnected,
  });

  @override
  State<MjpegViewer> createState() => _MjpegViewerState();
}

class _MjpegViewerState extends State<MjpegViewer> {
  http.Client? _httpClient;
  Stream<Uint8List>? _stream;
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeStream();
  }

  @override
  void didUpdateWidget(MjpegViewer oldWidget) {
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
  }

  Stream<Uint8List> _getMjpegStream(String url) async* {
    try {
      _httpClient = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await _httpClient!.send(request).timeout(widget.timeout);

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
            // No start marker found, clear old data and keep last byte
            if (buffer.length > 1) {
              buffer.removeRange(0, buffer.length - 1);
            }
            break;
          }

          // Find JPEG end after start
          int endIndex = -1;
          for (int i = startIndex + 2; i < buffer.length - 1; i++) {
            if (buffer[i] == jpegEnd[0] && buffer[i + 1] == jpegEnd[1]) {
              endIndex = i + 1; // Include the end marker
              break;
            }
          }

          if (endIndex == -1) {
            // No end marker found yet, remove data before start
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
    if (_stream == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<Uint8List>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red[300], size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Failed to connect to camera stream',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData) {
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

        return Image.memory(
          snapshot.data!,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          gaplessPlayback: true,
        );
      },
    );
  }
}
