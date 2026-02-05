import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camera/camera.dart';

import 'package:robotic_telescope/core/providers/telescope_provider.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/mjpeg_viewer.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/camera_status_bar.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/camera_action_button.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/ip_settings_dialog.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/server_info_dialog.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/qr_scanner_screen.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/fullscreen_camera_view.dart';
import 'package:robotic_telescope/features/camera/presentation/widgets/vr_camera_view.dart';
import 'package:robotic_telescope/features/camera/services/camera_server_service.dart';
import 'package:robotic_telescope/features/telescope_control/presentation/widgets/control_buttons.dart';

class CameraControlScreen extends StatefulWidget {
  const CameraControlScreen({super.key});

  @override
  State<CameraControlScreen> createState() => _CameraControlScreenState();
}

class _CameraControlScreenState extends State<CameraControlScreen> {
  String cameraUrl = 'http://192.168.4.50:81';
  bool _isFullscreen = false;
  bool _isVRMode = false;
  bool _isConnected = false;
  bool _hasError = false;
  String _streamKey = UniqueKey().toString();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();

  // Server mode
  bool _isServerMode = false;
  late CameraServerService _serverService;

  @override
  void initState() {
    super.initState();
    _serverService = CameraServerService();
    _loadSavedIP();
    _ipController.text = '192.168.4.50';
    _portController.text = '81';
    _loadServerMode();
  }

  Future<void> _loadServerMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isServer = prefs.getBool('is_server_mode') ?? false;
    if (isServer && mounted) {
      setState(() {
        _isServerMode = true;
      });
      _startServerMode();
    }
  }

  Future<void> _saveServerMode(bool isServer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_server_mode', isServer);
  }

  Future<void> _loadSavedIP() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('camera_url');
    if (savedUrl != null && mounted) {
      setState(() {
        cameraUrl = savedUrl;
        final uri = Uri.parse(savedUrl);
        _ipController.text = uri.host;
        _portController.text = uri.port.toString();
      });
    }
  }

  Future<void> _saveIP(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('camera_url', url);
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
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _ipController.dispose();
    _portController.dispose();
    _serverService.dispose();
    super.dispose();
  }

  void _showIPSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => IPSettingsDialog(
        ipController: _ipController,
        portController: _portController,
        onScanQR: _showQRScanner,
        onSave: (ip, port) {
          final newUrl = 'http://$ip:$port';
          setState(() {
            cameraUrl = newUrl;
          });
          _saveIP(newUrl);
          _refreshStream();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera URL updated: $newUrl')),
          );
        },
      ),
    );
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerScreen(
          onQRScanned: (String qrData) {
            String newUrl;
            if (qrData.startsWith('http://') || qrData.startsWith('https://')) {
              newUrl = qrData;
            } else if (qrData.contains(':')) {
              newUrl = 'http://$qrData';
            } else {
              newUrl = 'http://$qrData:81';
            }

            final uri = Uri.tryParse(newUrl);
            if (uri != null && uri.host.isNotEmpty) {
              setState(() {
                cameraUrl = newUrl;
                _ipController.text = uri.host;
                _portController.text = uri.port.toString();
              });
              _saveIP(newUrl);
              _refreshStream();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Camera URL from QR: $newUrl')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid QR code format')),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _toggleServerMode() async {
    if (_isServerMode) {
      await _serverService.stopServer();
      setState(() {
        _isServerMode = false;
      });
      _saveServerMode(false);
    } else {
      setState(() {
        _isServerMode = true;
      });
      _saveServerMode(true);
      await _startServerMode();
    }
  }

  Future<void> _startServerMode() async {
    try {
      await _serverService.startServer();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Camera server started at http://${_serverService.serverIpAddress}:${_serverService.serverPort}',
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to start server: $e')));
        setState(() {
          _isServerMode = false;
        });
      }
    }
  }

  void _showServerInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => ServerInfoDialog(
        serverIpAddress: _serverService.serverIpAddress ?? 'loading',
        serverPort: _serverService.serverPort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVRMode) {
      return VRCameraView(
        streamUrl: cameraUrl,
        streamKey: _streamKey,
        hasError: _hasError,
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
        onExit: _toggleVRMode,
      );
    }

    if (_isFullscreen) {
      return FullscreenCameraView(
        streamUrl: cameraUrl,
        streamKey: _streamKey,
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
        onExit: _toggleFullscreen,
      );
    }

    return Scaffold(appBar: _buildAppBar(), body: _buildBody());
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(_isServerMode ? 'Camera Server' : 'Camera Control'),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.9),
      elevation: 0,
      actions: [
        if (_isServerMode)
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: _showServerInfoDialog,
            tooltip: 'Show QR Code',
          ),
        if (!_isServerMode) ...[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showIPSettingsDialog,
            tooltip: 'IP Settings',
          ),
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
        IconButton(
          icon: Icon(_isServerMode ? Icons.videocam_off : Icons.videocam),
          onPressed: _toggleServerMode,
          tooltip: _isServerMode ? 'Stop Server' : 'Start Server',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
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
            Expanded(flex: 3, child: _buildCameraView()),
            _buildControlSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraView() {
    return Container(
      color: Colors.black,
      child: _isServerMode
          ? (_serverService.isCameraInitialized &&
                    _serverService.cameraController != null
                ? CameraPreview(_serverService.cameraController!)
                : const Center(child: CircularProgressIndicator()))
          : MjpegViewer(
              key: ValueKey(_streamKey),
              streamUrl: cameraUrl,
              fit: BoxFit.cover,
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
    );
  }

  Widget _buildControlSection() {
    return Container(
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
          CameraStatusBar(
            isServerMode: _isServerMode,
            isConnected: _isConnected,
            hasError: _hasError,
            displayText: _isServerMode
                ? '${_serverService.serverIpAddress ?? 'loading'}:${_serverService.serverPort}'
                : '${Uri.parse(cameraUrl).host}:${Uri.parse(cameraUrl).port}',
            onTap: _isServerMode
                ? _showServerInfoDialog
                : _showIPSettingsDialog,
          ),
          const Divider(height: 1),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CameraActionButton(
                          icon: Icons.camera_alt,
                          label: 'Capture',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Capture feature coming soon'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                        CameraActionButton(
                          icon: Icons.light_mode,
                          label: 'Flash',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Flash control coming soon'),
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
    );
  }
}
