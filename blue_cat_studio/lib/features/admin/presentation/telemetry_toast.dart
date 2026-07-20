import 'package:flutter/material.dart';

// Helper class for managing and queueing styled, rich telemetry cards safely from async streams
class TelemetryToast {
  // Keep track of the currently active overlay entry so we can animate it out when a new one arrives
  static OverlayEntry? _currentOverlayEntry;
  static VoidCallback? _currentDismissAnimator;

  static void show(
      BuildContext context, {
        required String severity,
        required String code,
        required String message,
      }) {
    if (!context.mounted) return;

    final overlayState = Navigator.of(context).overlay;
    if (overlayState == null) return;

    // Function to actually insert the new toast
    void insertNew() {
      if (!context.mounted) return;

      late OverlayEntry newEntry;

      newEntry = OverlayEntry(
        builder: (context) => _TelemetryCardWidget(
          severity: severity,
          code: code,
          message: message,
          onDismiss: () {
            if (_currentOverlayEntry == newEntry) {
              _currentOverlayEntry = null;
              _currentDismissAnimator = null;
            }
            try {
              newEntry.remove();
            } catch (e) {
              debugPrint('Overlay already removed: $e');
            }
          },
          onRegisterDismissAnimator: (animator) {
            _currentDismissAnimator = animator;
          },
        ),
      );

      _currentOverlayEntry = newEntry;
      overlayState.insert(newEntry);
    }

    // If there is an existing toast, play its close animation first, then insert the new one
    if (_currentOverlayEntry != null && _currentDismissAnimator != null) {
      final oldAnimator = _currentDismissAnimator!;
      _currentDismissAnimator = null; // Clear to prevent double triggers

      // Animate out the old one, then show the new one
      oldAnimator();

      // Wait for the slide-down animation (300ms) to finish before inserting the new toast
      Future.delayed(const Duration(milliseconds: 300), () {
        insertNew();
      });
    } else {
      // If no toast is currently showing, show immediately
      insertNew();
    }
  }
}

class _TelemetryCardWidget extends StatefulWidget {
  final String severity;
  final String code;
  final String message;
  final VoidCallback onDismiss;
  final ValueChanged<VoidCallback> onRegisterDismissAnimator;

  const _TelemetryCardWidget({
    required this.severity,
    required this.code,
    required this.message,
    required this.onDismiss,
    required this.onRegisterDismissAnimator,
  });

  @override
  State<_TelemetryCardWidget> createState() => _TelemetryCardWidgetState();
}

class _TelemetryCardWidgetState extends State<_TelemetryCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Slide up from bottom
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    // Register this state's reverse animation so an incoming toast can trigger it
    widget.onRegisterDismissAnimator(() {
      _dismissWithAnimation();
    });

    // Auto-dismiss after 4 seconds if no new telemetry comes in
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && !_isDismissed) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() {
    if (_isDismissed) return;
    _isDismissed = true;

    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final severityLower = widget.severity.toLowerCase();
    final isError = severityLower == 'error' || severityLower == 'critical';
    final isWarning = severityLower == 'warning';

    final accentColor = isError
        ? Colors.red.shade600
        : isWarning
        ? Colors.orange.shade700
        : const Color(0xFF0284C7); // Default UI Blue

    final pillBgColor = isError
        ? Colors.red.shade100
        : isWarning
        ? Colors.orange.shade100
        : Colors.lightBlue.shade100;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Card(
              elevation: 6,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: accentColor.withOpacity(0.3), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: pillBgColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isError
                            ? Icons.error_outline
                            : isWarning
                            ? Icons.warning_amber_rounded
                            : Icons.bolt,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: pillBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.code,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: pillBgColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.severity.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: _dismissWithAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}