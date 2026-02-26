import 'dart:async';
import 'dart:convert';
import 'package:robotic_telescope/core/services/telescope_websocket_manager.dart';
import 'package:robotic_telescope/core/providers/detection_provider.dart';

/// Service for sending AI-based pointing corrections to telescope
class TelescopeAICorrection {
  final TelescopeWebSocketManager _websocketManager;
  final DetectionProvider _detectionProvider;

  Timer? _correctionTimer;
  bool _isAutoCorrectingEnabled = false;
  Duration _correctionInterval = const Duration(milliseconds: 500);

  // Correction history for filtering
  final List<Map<String, double>> _correctionHistory = [];
  static const int _historySize = 5;

  TelescopeAICorrection({
    required TelescopeWebSocketManager websocketManager,
    required DetectionProvider detectionProvider,
  }) : _websocketManager = websocketManager,
       _detectionProvider = detectionProvider;

  bool get isAutoCorrectingEnabled => _isAutoCorrectingEnabled;

  /// Start automatic pointing correction
  void startAutoCorrection() {
    if (_isAutoCorrectingEnabled) {
      print('⚠️ Auto-correction already running');
      return;
    }

    if (!_websocketManager.isConnected) {
      throw Exception('WebSocket not connected');
    }

    _isAutoCorrectingEnabled = true;
    _startCorrectionLoop();
    print('✅ Auto-correction started');
  }

  /// Stop automatic pointing correction
  void stopAutoCorrection() {
    if (!_isAutoCorrectingEnabled) return;

    _isAutoCorrectingEnabled = false;
    _correctionTimer?.cancel();
    _correctionTimer = null;
    _correctionHistory.clear();
    print('🛑 Auto-correction stopped');
  }

  /// Send single pointing correction
  Future<void> sendCorrection() async {
    if (!_websocketManager.isConnected) {
      throw Exception('WebSocket not connected');
    }

    final correctionData = _detectionProvider.getCorrectionData();
    if (correctionData == null) {
      print('⚠️ No correction data available');
      return;
    }

    // Apply smoothing filter
    final smoothedCorrection = _applySmoothingFilter(correctionData['error']);

    // Prepare correction command
    final command = {
      'command': 'ai_pointing_correction',
      'object': correctionData['object'],
      'confidence': correctionData['confidence'],
      'error': smoothedCorrection,
      'timestamp': correctionData['timestamp'],
    };

    // Send via WebSocket
    _websocketManager.sendMessage(jsonEncode(command));

    print(
      '📡 Sent correction: ${command['object']} | '
      'dx: ${smoothedCorrection['dx_pixels']?.toStringAsFixed(1)}px | '
      'dy: ${smoothedCorrection['dy_pixels']?.toStringAsFixed(1)}px',
    );
  }

  /// Start correction loop
  void _startCorrectionLoop() {
    _correctionTimer = Timer.periodic(_correctionInterval, (timer) async {
      if (!_isAutoCorrectingEnabled) {
        timer.cancel();
        return;
      }

      // Check if correction is needed
      if (_detectionProvider.needsCorrection()) {
        try {
          await sendCorrection();
        } catch (e) {
          print('❌ Error sending correction: $e');
        }
      }
    });
  }

  /// Apply smoothing filter to reduce jitter
  Map<String, double> _applySmoothingFilter(Map<String, double> currentError) {
    // Add to history
    _correctionHistory.add(currentError);
    if (_correctionHistory.length > _historySize) {
      _correctionHistory.removeAt(0);
    }

    // Calculate moving average
    double avgDx = 0.0;
    double avgDy = 0.0;
    double avgDxPixels = 0.0;
    double avgDyPixels = 0.0;

    for (var error in _correctionHistory) {
      avgDx += error['dx'] ?? 0.0;
      avgDy += error['dy'] ?? 0.0;
      avgDxPixels += error['dx_pixels'] ?? 0.0;
      avgDyPixels += error['dy_pixels'] ?? 0.0;
    }

    final count = _correctionHistory.length;
    return {
      'dx': avgDx / count,
      'dy': avgDy / count,
      'dx_pixels': avgDxPixels / count,
      'dy_pixels': avgDyPixels / count,
    };
  }

  /// Set correction interval
  void setCorrectionInterval(Duration interval) {
    _correctionInterval = interval;
    if (_isAutoCorrectingEnabled) {
      // Restart correction loop with new interval
      stopAutoCorrection();
      startAutoCorrection();
    }
  }

  /// Send custom command to telescope
  void sendCustomCommand(String command, Map<String, dynamic> params) {
    if (!_websocketManager.isConnected) {
      throw Exception('WebSocket not connected');
    }

    final message = {
      'command': command,
      ...params,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _websocketManager.sendMessage(jsonEncode(message));
    print('📡 Sent custom command: $command');
  }

  /// Dispose resources
  void dispose() {
    stopAutoCorrection();
    print('🧹 TelescopeAICorrection disposed');
  }
}
