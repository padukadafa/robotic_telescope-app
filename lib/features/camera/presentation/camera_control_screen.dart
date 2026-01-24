import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/mjpeg_viewer.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';

class CameraControlScreen extends StatefulWidget {
  const CameraControlScreen({super.key});

  @override
  State<CameraControlScreen> createState() => _CameraControlScreenState();
}

class _CameraControlScreenState extends State<CameraControlScreen> {
  final String cameraUrl = 'http://192.168.1.50:81';
  bool _isFullscreen = false;
  bool _isVRMode = false;
  bool _isConnected = false;
  bool _hasError = false;
  String _streamKey = UniqueKey().toString();

  @override
  void initState() {
    super.initState();
  }

  void _refreshStream() {
    setState(() {
      _streamKey = UniqueKey().toString();
      _isConnected = false;
      _hasError = false;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _toggleVRMode() {
    setState(() {
      _isVRMode = !_isVRMode;
    });

    if (_isVRMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  @override
  void dispose() {
    // Reset orientation when leaving the screen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isVRMode) {
      return _buildVRView();
    }
    
    if (_isFullscreen) {
      return _buildFullscreenView();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Control'),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: 0.9),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar),
            onPressed: _toggleVRMode,
            tooltip: 'VR Mode',
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleFullscreen,
            tooltip: 'Fullscreen',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStream,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Camera stream view (Top)
              Expanded(
                flex: 3,
                child: Container(
                  color: Colors.black,
                  child: MjpegViewer(
                    key: ValueKey(_streamKey),
                    streamUrl: cameraUrl,
                    fit: BoxFit.contain,
                    onConnected: () {
                      if (mounted) {
                        setState(() {
                          _isConnected = true;
                          _hasError = false;
                        });
                      }
                    },
                    onError: () {
                      if (mounted) {
                        setState(() {
                          _hasError = true;
                          _isConnected = false;
                        });
                      }
                    },
                  ),
                ),
              ),
              // Controller section (Bottom)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Status bar
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ESP32-CAM',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _hasError
                                  ? Colors.red
                                  : (_isConnected
                                        ? Colors.green
                                        : Colors.orange),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '192.168.1.50:81',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Telescope Control
                    Consumer<TelescopeProvider>(
                      builder: (context, telescope, child) {
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ControlButtons(
                                isConnected: telescope.isConnected,
                                onSlewUp: () => telescope.slewUp(),
                                onSlewDown: () => telescope.slewDown(),
                                onSlewLeft: () => telescope.slewLeft(),
                                onSlewRight: () => telescope.slewRight(),
                                onStop: () => telescope.stop(),
                                title: 'Telescope Control',
                              ),
                            ),
                            // Camera controls
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildCameraButton(
                                    context,
                                    icon: Icons.camera_alt,
                                    label: 'Capture',
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Capture feature coming soon',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  _buildCameraButton(
                                    context,
                                    icon: Icons.light_mode,
                                    label: 'Flash',
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Flash control coming soon',
                                          ),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullscreenView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MjpegViewer(
            key: ValueKey(_streamKey),
            streamUrl: cameraUrl,
            fit: BoxFit.contain,
            onConnected: () {
              if (mounted) {
                setState(() {
                  _isConnected = true;
                  _hasError = false;
                });
              }
            },
            onError: () {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isConnected = false;
                });
              }
            },
          ),
          Positioned(
            top: 40,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit),
              color: Colors.white,
              iconSize: 32,
              onPressed: _toggleFullscreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
