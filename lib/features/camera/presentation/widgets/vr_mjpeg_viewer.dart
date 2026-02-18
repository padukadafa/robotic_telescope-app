import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  ui.Image? _currentImage;
  ui.FragmentShader? _shader;
  bool _isShaderLoaded = false;
  Timer? _frameTimer;
  Uint8List? _pendingFrame;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _initializeStream();
  }

  Future<void> _loadShader() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/vr_distortion.frag',
      );
      if (mounted) {
        setState(() {
          _shader = program.fragmentShader();
          _isShaderLoaded = true;
        });
      }
    } catch (e) {
      print('Failed to load shader: $e');
    }
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

    // Frame rate limiter to 30 FPS for better performance
    _frameTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (_pendingFrame != null && mounted) {
        _updateFrame(_pendingFrame!);
        _pendingFrame = null;
      }
    });

    _stream = _getMjpegStream(widget.streamUrl);
    _stream?.listen(
      (frame) {
        _pendingFrame = frame;
      },
      onError: (error) {
        if (mounted) {
          widget.onError?.call();
        }
      },
    );
  }

  Future<void> _updateFrame(Uint8List frame) async {
    try {
      final codec = await ui.instantiateImageCodec(frame);
      final frameImage = await codec.getNextFrame();

      if (mounted) {
        setState(() {
          _currentImage?.dispose();
          _currentImage = frameImage.image;
        });
      }
      codec.dispose();
    } catch (e) {
      print('Error decoding frame: $e');
    }
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
    _frameTimer?.cancel();
    _frameTimer = null;
    _httpClient?.close();
    _httpClient = null;
    _currentImage?.dispose();
    _currentImage = null;
  }

  @override
  void dispose() {
    _cancelStream();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentImage == null || !_isShaderLoaded) {
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

    // Side-by-side stereoscopic view with GPU-accelerated barrel distortion
    return Row(
      children: [
        // Left eye view - shift right via shader
        Expanded(child: _buildVRLensView(offsetX: 0.11)),
        // Right eye view - shift left via shader
        Expanded(child: _buildVRLensView(offsetX: -0.11)),
      ],
    );
  }

  /// Builds a single VR lens view with GPU-accelerated distortion
  Widget _buildVRLensView({required double offsetX}) {
    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: _VRDistortionPainter(
          image: _currentImage!,
          shader: _shader!,
          offsetX: offsetX,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// GPU-accelerated pincushion distortion painter for VR lens correction
class _VRDistortionPainter extends CustomPainter {
  final ui.Image image;
  final ui.FragmentShader shader;
  final double offsetX;

  // Distortion coefficients for Cardboard-style lenses
  static const double k1 = 1.2;
  static const double k2 = 0.24;

  _VRDistortionPainter({
    required this.image,
    required this.shader,
    required this.offsetX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set shader uniforms
    shader.setFloat(0, size.width); // uSize.x
    shader.setFloat(1, size.height); // uSize.y
    shader.setImageSampler(0, image); // uTexture
    shader.setFloat(2, k1); // uK1
    shader.setFloat(3, k2); // uK2
    shader.setFloat(4, offsetX); // uOffsetX

    // Draw using GPU shader
    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_VRDistortionPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
