import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../model/spinner_segment_model.dart';

class WheelPainter extends CustomPainter {
  final List<SpinnerSegment> segments;
  static final Map<String, ui.Image> _imageCache = {};
  static bool _isLoadingImages = false;
  static Completer<void>? _precacheCompleter;
  static int _debugPaintCount = 0;

  final VoidCallback? onImageLoaded;

  WheelPainter(this.segments, {this.onImageLoaded}) {
    _precacheInstanceImages();
  }

  Future<void> _precacheInstanceImages() async {
    if (_isLoadingImages) {
      await _precacheCompleter?.future;
      return;
    }
    await loadImagesForSegments(segments, onProgress: onImageLoaded);
  }

  static Future<void> loadImagesForSegments(
    List<SpinnerSegment> segments, {
    VoidCallback? onProgress,
  }) async {
    if (_isLoadingImages) {
      await _precacheCompleter?.future;
      // Continue to check if OUR segments are loaded, as the previous batch might be different
    }

    _isLoadingImages = true;
    _precacheCompleter = Completer<void>();

    try {
      final imagesToLoad = <String>[];

      for (final segment in segments) {
        if (segment.imagePath != null &&
            segment.imagePath!.isNotEmpty &&
            !_imageCache.containsKey(segment.imagePath)) {
          imagesToLoad.add(segment.imagePath!);
        }
        if (segment.centerImagePath != null &&
            segment.centerImagePath!.isNotEmpty &&
            !_imageCache.containsKey(segment.centerImagePath)) {
          imagesToLoad.add(segment.centerImagePath!);
        }
        if (segment.iconUrl != null &&
            segment.iconUrl!.isNotEmpty &&
            !_imageCache.containsKey(segment.iconUrl)) {
          imagesToLoad.add(segment.iconUrl!);
        }
      }

      await Future.wait(
        imagesToLoad.map((path) => _loadImage(path, onProgress)),
      );
    } finally {
      _isLoadingImages = false;
      if (!(_precacheCompleter?.isCompleted ?? true)) {
        _precacheCompleter?.complete();
      }
    }
  }

  static Future<void> _loadImage(
    String imagePath,
    VoidCallback? onLoaded,
  ) async {
    if (_imageCache.containsKey(imagePath)) return;
    try {
      Uint8List data;
      if (imagePath.startsWith('http')) {
        final uri = Uri.parse(imagePath);
        final request = await HttpClient().getUrl(uri);
        final response = await request.close();
        data = await consolidateHttpClientResponseBytes(response);
      } else {
        final file = File(imagePath);
        if (await file.exists()) {
          data = await file.readAsBytes();
        } else {
          return;
        }
      }

      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      _imageCache[imagePath] = frame.image;
      onLoaded?.call();
    } catch (e) {
      debugPrint('Error loading image ($imagePath): $e');
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Draw Outer Rim Shadow/Glow
    // Simplified: No outer rim, maximized radius
    final radius = size.width / 2;
    final segmentAngle = 2 * math.pi / segments.length;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final startAngle = i * segmentAngle - math.pi / 2;
      final sweepAngle = segmentAngle;

      // 1. Draw Segment with Gradient for 3D effect
      final path = _createSegmentPath(center, radius, startAngle, sweepAngle);

      // Gradient shader for depth
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          segment.color.withValues(alpha: 0.8), // Lighter at center
          segment.color, // Original color
          segment.color.withValues(alpha: 0.6), // Darker at edge
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

      final paint = Paint()
        ..shader = gradient
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, paint);

      // Separator Line (Premium Gold/White look)
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0; // Thicker separator

      canvas.drawPath(path, borderPaint);

      // 1. Draw Background Image
      if (segment.imagePath != null &&
          _imageCache.containsKey(segment.imagePath!)) {
        final image = _imageCache[segment.imagePath!]!;
        final imageRect = Rect.fromCircle(center: center, radius: radius);
        canvas.save();
        canvas.clipPath(
          _createSegmentPath(center, radius, startAngle, sweepAngle),
        );
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          imageRect,
          Paint()..isAntiAlias = true,
        );
        canvas.restore();
      }

      // 2. Draw Text (Emoji-safe) - Reduced Size
      final int f = segment.fontSize ?? 14;
      final int maxChars = 12;

      // Use .characters to safely trim including emojis
      String displayText = segment.text;

      // Debug first segment
      if (i == 0 && _debugPaintCount < 5) {
        // Limit logs
        debugPrint(
          '🎨 Painting Segment 0: $displayText (Color: ${segment.color})',
        );
        _debugPaintCount++;
      }

      if (displayText.characters.length > maxChars) {
        displayText = '${displayText.characters.take(maxChars).toString()}...';
      }

      final textAngle = startAngle + sweepAngle / 2;

      // Fixed: Uniform radius for ALL segments
      // User feedback: "chữ nên gần tâm 1 chút nữa" -> 0.5
      // "icon không cách cạnh wheel" -> Pull icon in to 0.7
      final double textBaseRadius = 0.52;
      final double textRadius = radius * textBaseRadius;

      final textOffset = Offset(
        center.dx + textRadius * math.cos(textAngle),
        center.dy + textRadius * math.sin(textAngle),
      );

      // Variables for text visibility replaced by consistent heavy-outline style.

      final textSpanStroke = TextSpan(
        text: displayText,
        style: TextStyle(
          fontSize: f.toDouble(),
          fontWeight: FontWeight.w900, // Extra bold
          fontFamily:
              'Avenir', // Or any premium font if available, else default
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.0
            ..color = Colors.black.withValues(
              alpha: 0.5,
            ), // Stronger outline for contrast
        ),
      );

      final textSpanFill = TextSpan(
        text: displayText,
        style: TextStyle(
          fontSize: f.toDouble(),
          fontWeight: FontWeight.w900,
          color: Colors
              .white, // Always white text looks better on vibrant/dark colors
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
      );

      final strokePainter = TextPainter(
        text: textSpanStroke,
        textDirection: TextDirection.ltr,
      )..layout();
      final fillPainter = TextPainter(
        text: textSpanFill,
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(textOffset.dx, textOffset.dy);
      canvas.rotate(textAngle);
      strokePainter.paint(
        canvas,
        Offset(-strokePainter.width / 2, -strokePainter.height / 2),
      );
      fillPainter.paint(
        canvas,
        Offset(-fillPainter.width / 2, -fillPainter.height / 2),
      );
      canvas.restore();

      // 3. Draw Icon (if available)
      final String? iconToDraw = segment.iconUrl ?? segment.centerImagePath;
      if (iconToDraw != null && _imageCache.containsKey(iconToDraw)) {
        final image = _imageCache[iconToDraw]!;
        final imageSize = Size(28, 28);

        // Fixed: Dynamic positioning!
        // Calculate radius based on where the text ACTUALLY ends
        // textRadius = center of text
        // textPainter.width / 2 = half width
        // gap = 10 pixels
        // imageSize.width / 2 = center of icon
        final double gap = 10.0;
        final double contentRadius =
            textRadius + (fillPainter.width / 2) + gap + (imageSize.width / 2);

        final contentOffset = Offset(
          center.dx + contentRadius * math.cos(textAngle),
          center.dy + contentRadius * math.sin(textAngle),
        );

        canvas.save();
        // Fixed: Rotate icon with the text!
        // 1. Move to the calculated position
        canvas.translate(contentOffset.dx, contentOffset.dy);
        // 2. Rotate by the same angle as the text
        canvas.rotate(textAngle);

        // 3. Draw centered at (0,0) local coordinates
        final localImageRect = Rect.fromCenter(
          center: Offset.zero,
          width: imageSize.width,
          height: imageSize.height,
        );

        // Circular clip
        final Path circlePath = Path()..addOval(localImageRect);
        canvas.clipPath(circlePath);

        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          localImageRect,
          Paint()..isAntiAlias = true,
        );
        canvas.restore();
      }
    }
  }

  Path _createSegmentPath(
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.lineTo(
      center.dx + radius * math.cos(startAngle),
      center.dy + radius * math.sin(startAngle),
    );
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
