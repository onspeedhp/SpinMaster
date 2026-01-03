import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wheeler/services/sound_manager.dart';
import 'package:wheeler/model/spinner_segment_model.dart';
import 'package:wheeler/widget/spin_pointer.dart';
import 'dart:math' as math;
import 'wheel_painter.dart';

class WheelCard extends StatefulWidget {
  final List<SpinnerSegment> segments;
  final String wheelName;
  final Function(String result, Color color)? onSpinComplete;
  final bool? isFullScreen;
  final Future<int?> Function()? onSpinRequest;

  const WheelCard({
    super.key,
    required this.segments,
    required this.wheelName,
    this.onSpinComplete,
    this.isFullScreen,
    this.onSpinRequest,
  });

  @override
  _WheelCardState createState() => _WheelCardState();
}

class _WheelCardState extends State<WheelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool isSpinning = false;
  String result = '';
  double _currentRotation = 0.0;

  // ✅ React-like segment tracking
  int? _lastTickSegmentIndex;
  double _lastTickTime = 0.0;
  double _segmentStartTime = 0.0; // ✅ Segment boundary cross start time

  // ✅ Spin tracking
  bool _isMainSpin = false;

  @override
  void initState() {
    super.initState();
    SoundManager.initializePlayerPool();
    _controller = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  /// Helper function to get ordinal suffix
  String _getOrdinalSuffix(int number) {
    if (number % 100 >= 11 && number % 100 <= 13) {
      return 'th';
    }
    switch (number % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// ✅ React jaisa segment boundary detection
  void _maybeTickOnRotation(double currentRotation) {
    if (widget.segments.isEmpty || !_isMainSpin) return;

    final numSegments = widget.segments.length;
    final segmentAngle = 2 * math.pi / numSegments;

    // Normalize rotation to 0-2π range
    final normalizedRotation = currentRotation % (2 * math.pi);

    // ✅ Pointer at top (90° offset like React code)
    // React: const adjustedAngle = (360 - normalizedRotation + 90) % 360;
    final adjustedAngle = normalizedRotation;

    // Calculate current segment index
    final segmentIndex = (adjustedAngle / segmentAngle).floor() % numSegments;

    // ✅ Initialize on first call
    if (_lastTickSegmentIndex == null) {
      _lastTickSegmentIndex = segmentIndex;
      _segmentStartTime = DateTime.now().millisecondsSinceEpoch.toDouble();
      return;
    }

    // ✅ Detect segment boundary crossing
    if (segmentIndex != _lastTickSegmentIndex) {
      final now = DateTime.now().millisecondsSinceEpoch.toDouble();

      // ✅ Calculate segment crossing duration
      final segmentDuration = now - _segmentStartTime;

      // Get ordinal numbers
      final fromOrdinal =
          '${_lastTickSegmentIndex! + 1}${_getOrdinalSuffix(_lastTickSegmentIndex! + 1)}';
      final toOrdinal =
          '${segmentIndex + 1}${_getOrdinalSuffix(segmentIndex + 1)}';

      // ✅ Throttle: minimum 40ms between ticks (React logic)
      if (now - _lastTickTime > 40) {
        SoundManager.playSpinSound();
        _lastTickTime = now;

        // ✅ Print segment duration with ordinal numbers
        print(
          '🔊 $fromOrdinal → $toOrdinal | Duration: ${segmentDuration.toStringAsFixed(0)}ms',
        );
      } else {
        // ✅ Skipped sound but still show duration
        print(
          '⏭️  $fromOrdinal → $toOrdinal | Duration: ${segmentDuration.toStringAsFixed(0)}ms (sound skipped)',
        );
      }

      _lastTickSegmentIndex = segmentIndex;
      _segmentStartTime = now; // ✅ Reset for next segment
    }
  }

  void _onAnimationUpdate() {
    _currentRotation = _animation.value * 2 * math.pi;
    _maybeTickOnRotation(_currentRotation);

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    SoundManager.stopSpinSound();
    super.dispose();
  }

  Future<void> _startMainSpin(int? targetIndex) async {
    final random = math.Random();

    debugPrint('🎡 Starting spin... Target Index: $targetIndex');
    if (widget.segments.isNotEmpty) {
      debugPrint('🎡 Segments Config:');
      for (int i = 0; i < widget.segments.length; i++) {
        debugPrint('  [$i] ${widget.segments[i].text}');
      }
    }

    // ✅ React-like: 6 full rotations + random position
    double fullSpins = 6;
    double randomSegmentIndex =
        targetIndex?.toDouble() ??
        random.nextInt(widget.segments.length).toDouble();
    double segmentAngleCalc = 2 * math.pi / widget.segments.length;

    // ✅ Final angle calculation (Target Position from 0)
    // Remove all manual offsets.
    // Force land on CENTER of segment for debugging
    double offsetWithinSegment = segmentAngleCalc / 2;
    double offsetAdjustment = 0;

    // This is the Absolute Angle we want the wheel to be at (relative to 0) to show the target segment at Top.
    double targetAbsoluteAngle =
        (2 * math.pi -
            (randomSegmentIndex * segmentAngleCalc + offsetWithinSegment)) +
        offsetAdjustment;

    // Normalize current rotation to 0..2PI
    double currentAngleNormalized = _currentRotation % (2 * math.pi);

    // Calculate required rotation (Delta) to get from Current to Target
    // We want to rotate CW (positive).
    // Delta = Target - Current.
    // If Target > Current. Delta is positive.
    // If Target < Current. Delta is negative. We want positive rotation, so add 2PI.
    double rotationDelta = targetAbsoluteAngle - currentAngleNormalized;
    if (rotationDelta < 0) {
      rotationDelta += 2 * math.pi;
    }

    // Check what segment we expect (Simulated)
    int expectedIndex = (randomSegmentIndex.toInt()) % widget.segments.length;
    String expectedText = widget.segments[expectedIndex].text;

    // Debug
    debugPrint('🎡 Spin Calculation (DELTA LOGIC):');
    debugPrint('   Target Index: $targetIndex');
    debugPrint('   Expected Segment: $expectedIndex ($expectedText)');
    debugPrint(
      '   Current Angle: ${(currentAngleNormalized * 180 / math.pi).toStringAsFixed(1)}°',
    );
    debugPrint(
      '   Target Abs Angle: ${(targetAbsoluteAngle * 180 / math.pi).toStringAsFixed(1)}°',
    );
    debugPrint(
      '   Delta to Rotate: ${(rotationDelta * 180 / math.pi).toStringAsFixed(1)}°',
    );

    double totalRotation = fullSpins * 2 * math.pi + rotationDelta;

    // ✅ Cumulative rotation
    double startValue = _currentRotation / (2 * math.pi);
    double endValue = startValue + (totalRotation / (2 * math.pi));

    _animation = Tween<double>(begin: startValue, end: endValue).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic, // React: [0.3, 0, 0.1, 1]
      ),
    );

    _controller.value = 0.0;

    // ✅ Ensure listener is added since we skipped initial rotation
    _controller.removeListener(_onAnimationUpdate);
    _controller.addListener(_onAnimationUpdate);

    // ✅ Enable tick sounds for main spin
    _isMainSpin = true;
    _lastTickSegmentIndex = null;
    _lastTickTime = DateTime.now().millisecondsSinceEpoch.toDouble();
    _segmentStartTime = DateTime.now().millisecondsSinceEpoch
        .toDouble(); // ✅ Initialize segment timer

    await _controller.forward();

    // Calculate the final rotation in radians (normalized to 0-2π)
    double finalRotation = _currentRotation % (2 * math.pi);

    // The pointer is at the top (12 o'clock position)
    // We need to find which segment is at the top (π/2 radians or 90 degrees)

    // The wheel spins counter-clockwise, and the pointer is at the top (0 radians)
    // We need to find which segment contains the pointer at the top
    // The angle is measured from the positive x-axis (3 o'clock position) in the mathematical coordinate system

    // Calculate the angle of the pointer (top position) in the wheel's coordinate system
    // Since the wheel spins counter-clockwise, we need to invert the rotation
    double pointerAngle = (2 * math.pi) - (finalRotation % (2 * math.pi));

    // Calculate the angle of each segment
    double segmentAngle = 2 * math.pi / widget.segments.length;

    // Calculate which segment contains the pointer
    // The modulo operation ensures the result is within the valid range of indices
    int selectedIndex =
        (pointerAngle / segmentAngle).floor() % widget.segments.length;

    // Ensure the index is within bounds
    selectedIndex = selectedIndex.clamp(0, widget.segments.length - 1);

    final selectedSegment = widget.segments[selectedIndex];

    setState(() {
      isSpinning = false;
      result = selectedSegment.text;
      _isMainSpin = false;
    });

    SoundManager.stopSpinSound();
    widget.onSpinComplete?.call(result, selectedSegment.color);
    _showResultDialog(selectedSegment);
  }

  Future<void> spinWheel() async {
    if (isSpinning) return;

    setState(() {
      isSpinning = true; // Block immediate interactions
    });

    // Check validation callback first
    int? targetIndex;
    if (widget.onSpinRequest != null) {
      targetIndex = await widget.onSpinRequest!();
      if (targetIndex != null && targetIndex < 0) {
        // Abort if validation fails (e.g. no spins)
        setState(() {
          isSpinning = false;
        });
        return;
      }
      // Note: for official wheel targetIndex will be 0-5, for custom it might be -1 to abort
    }

    await SoundManager.stopSpinSound();

    setState(() {
      isSpinning = true;
      result = '';
      _lastTickSegmentIndex = null;
      _isMainSpin = false;
    });

    print('🎡 Spin started!');

    // ✅ Initial nudge back
    // await _startInitialRotation(); // Removed for debugging stability

    // ✅ Main spin with duration
    _controller.duration = Duration(seconds: 7); // React: 7 seconds
    await _startMainSpin(targetIndex);

    print('🏁 Spin completed!');
  }

  Future<void> _showResultDialog(SpinnerSegment segment) async {
    final String resultText = segment.text;
    bool isWin =
        resultText.toLowerCase().contains('win') ||
        resultText.startsWith('+') ||
        resultText.contains('JACKPOT');

    await SoundManager.playVictorySound();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await SoundManager.stopVictorySound();
          },
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF16213e),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: (isWin ? const Color(0xFFF48FB1) : Colors.grey)
                      .withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isWin ? const Color(0xFFF48FB1) : Colors.black)
                        .withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isWin ? 'CONGRATULATIONS!' : 'SPIN RESULT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isWin ? const Color(0xFFF48FB1) : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (segment.iconUrl != null ||
                      segment.centerImagePath != null) ...[
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF48FB1).withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF48FB1,
                            ).withValues(alpha: 0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child:
                          (segment.iconUrl != null &&
                              segment.iconUrl!.startsWith('http'))
                          ? Image.network(segment.iconUrl!)
                          : Image.file(
                              File(segment.iconUrl ?? segment.centerImagePath!),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Text(
                    resultText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        SoundManager.stopVictorySound();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF48FB1),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'AWESOME!',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void resetWheel() {
    _controller.reset();
    _controller.stop();
    _animation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    setState(() {
      result = '';
      isSpinning = false;
      _lastTickSegmentIndex = null;
      _isMainSpin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity,
              height: 380, // Larger size
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _currentRotation,
                        child: CustomPaint(
                          size: Size(380, 380),
                          painter: WheelPainter(
                            widget.segments,
                            onImageLoaded: () {
                              if (mounted) setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  GestureDetector(
                    onTap: isSpinning ? null : spinWheel,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF48FB1),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFF48FB1,
                            ).withValues(alpha: 0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: isSpinning
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFFF48FB1),
                                  ),
                                ),
                              )
                            : const Text(
                                'SPIN',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(top: 0, child: VerticalArrow()),
                ],
              ),
            ),
            const SizedBox(height: 24),
            widget.isFullScreen ?? false
                ? const SizedBox(height: 10)
                : OutlinedButton(
                    onPressed: isSpinning ? null : spinWheel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: isSpinning
                            ? Colors.white24
                            : const Color(0xFFF48FB1),
                        width: 2,
                      ),
                      foregroundColor: isSpinning
                          ? Colors.white24
                          : const Color(0xFFF48FB1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'START SPIN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
