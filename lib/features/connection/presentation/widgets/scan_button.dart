import 'package:flutter/material.dart';

/// Scan Button Widget - Pure UI Component (Presentation Layer Only)
///
/// This widget follows Clean Architecture principles:
/// - Presentation Layer: Handles UI rendering and user interactions
/// - No business logic or state management
/// - Receives state and callbacks from parent widgets
/// - Focuses only on visual representation
class ScanButton extends StatefulWidget {
  /// Current scanning state
  final bool isScanning;

  /// Callback when scan button is pressed
  final VoidCallback? onScanPressed;

  /// Optional custom button text
  final String? buttonText;

  /// Optional custom scanning text
  final String? scanningText;

  const ScanButton({
    super.key,
    required this.isScanning,
    this.onScanPressed,
    this.buttonText,
    this.scanningText,
  });

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton> with TickerProviderStateMixin {
  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scanAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: AnimatedBuilder(
          animation: _scanAnimation,
          builder: (context, child) {
            return Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: [
                    0.0,
                    widget.isScanning ? _scanAnimation.value : 0.0,
                    1.0,
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated scanning rings when scanning
                  if (widget.isScanning) ...[
                    _buildScanningRing(0.6, 0.3),
                    _buildScanningRing(0.8, 0.2),
                    _buildScanningRing(1.0, 0.1),
                  ],

                  // Main button
                  ElevatedButton(
                    onPressed: widget.isScanning ? null : widget.onScanPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isScanning
                          ? Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: widget.isScanning
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onPrimary,
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(35),
                      elevation: widget.isScanning ? 2 : 8,
                      shadowColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    child: _buildButtonContent(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Builds the button content (icon, text, progress indicator)
  Widget _buildButtonContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon with loading indicator
        Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isScanning)
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            Icon(
              Icons.wifi_find,
              size: 44,
              color: widget.isScanning
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onPrimary,
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Main text
        Text(
          widget.isScanning
              ? (widget.scanningText ?? 'Scanning...')
              : (widget.buttonText ?? 'Scan Networks'),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: widget.isScanning
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onPrimary,
          ),
        ),

        // Progress indicator text
        if (widget.isScanning) ...[
          const SizedBox(height: 3),
          Flexible(
            child: Text(
              'Searching...',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  /// Builds animated scanning rings
  Widget _buildScanningRing(double scale, double opacity) {
    return AnimatedBuilder(
      animation: _scanAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: scale * _scanAnimation.value,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: opacity),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
