import 'package:flutter/material.dart';

class UIUtils {
  static void showMessageDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
  }) {
    // We'll keep the dialog as a fallback but move to showPremiumNotification for better UX
    showPremiumNotification(
      context,
      title: title,
      message: message,
      isError: isError,
    );
  }

  static void showPremiumNotification(
    BuildContext context, {
    required String title,
    required String message,
    bool isError = false,
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _PremiumNotificationWidget(
        title: title,
        message: message,
        isError: isError,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _PremiumNotificationWidget extends StatefulWidget {
  final String title;
  final String message;
  final bool isError;
  final VoidCallback onDismiss;

  const _PremiumNotificationWidget({
    required this.title,
    required this.message,
    required this.isError,
    required this.onDismiss,
  });

  @override
  State<_PremiumNotificationWidget> createState() =>
      _PremiumNotificationWidgetState();
}

class _PremiumNotificationWidgetState extends State<_PremiumNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yOffset;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _yOffset = Tween<double>(
      begin: -100,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((value) => widget.onDismiss());
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = widget.isError
        ? Colors.redAccent
        : const Color(0xFFF48FB1);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: 20 + _yOffset.value,
          left: 16,
          right: 16,
          child: SafeArea(
            child: Opacity(
              opacity: _opacity.value,
              child: Material(
                color: Colors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.2),
                      BlendMode.darken,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isError
                              ? [
                                  const Color(
                                    0xFF421010,
                                  ).withValues(alpha: 0.8),
                                  const Color(
                                    0xFF1a0505,
                                  ).withValues(alpha: 0.8),
                                ]
                              : [
                                  const Color(
                                    0xFF16213e,
                                  ).withValues(alpha: 0.8),
                                  const Color(
                                    0xFF0f172a,
                                  ).withValues(alpha: 0.8),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: themeColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.15),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Pulsing Icon
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.8, end: 1.0),
                            duration: const Duration(seconds: 1),
                            curve: Curves.easeInOutSine,
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: themeColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: themeColor.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 10 * scale,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    widget.isError
                                        ? Icons.error_rounded
                                        : Icons.auto_awesome_rounded,
                                    color: themeColor,
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              _controller.reverse().then(
                                (value) => widget.onDismiss(),
                              );
                            },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white24,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
