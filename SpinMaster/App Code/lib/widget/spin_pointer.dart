import 'package:flutter/material.dart';

class VerticalArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Paint for the arrow (black fill)
    final arrowPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    // Paint for the arrow border (sharp tip)
    final borderPaint = Paint()
      ..color = const Color(0xFFF48FB1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.miter; // sharp corners

    // Adjust triangle height (make it shorter)
    final triangleHeight = size.height * 0.2; // smaller height
    final rectHeight = size.height * 0.7; // rectangle height

    // Path for arrow (rectangle + smaller triangle merged)
    final path = Path()
      ..moveTo(size.width * 0.3, 0) // top-left of rect
      ..lineTo(size.width * 0.7, 0) // top-right of rect
      ..lineTo(size.width * 0.7, rectHeight) // bottom-right of rect
      ..lineTo(
        size.width * 0.5,
        rectHeight + triangleHeight,
      ) // shorter triangle tip
      ..lineTo(size.width * 0.3, rectHeight) // bottom-left of rect
      ..close();

    // Draw border first
    canvas.drawPath(path, borderPaint);
    // Draw fill inside
    canvas.drawPath(path, arrowPaint);

    // Circle paints
    final circlePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    final circleBorderPaint = Paint()
      ..color = const Color(0xFFF48FB1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Circle position and size
    final circleRadius = size.width * 0.08;
    final circleCenter = Offset(size.width / 2, size.height * 0.15);

    // Draw circle + border
    canvas.drawCircle(circleCenter, circleRadius, circlePaint);
    canvas.drawCircle(circleCenter, circleRadius, circleBorderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class VerticalArrow extends StatelessWidget {
  const VerticalArrow({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -15), // Move up slightly
      child: CustomPaint(
        painter: VerticalArrowPainter(),
        size: const Size(30, 40), // Original size
      ),
    );
  }
}
