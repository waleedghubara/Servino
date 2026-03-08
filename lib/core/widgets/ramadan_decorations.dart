// ignore_for_file: deprecated_member_use

import 'dart:math' as math;
import 'package:flutter/material.dart';

class RamadanDecorations extends StatefulWidget {
  const RamadanDecorations({super.key});

  @override
  State<RamadanDecorations> createState() => _RamadanDecorationsState();
}

class _RamadanDecorationsState extends State<RamadanDecorations>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RamadanPainter(animationValue: _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _RamadanPainter extends CustomPainter {
  final double animationValue;

  _RamadanPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()
      ..color =
          const Color(0xFFD4AF37) // Gold color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw hanging wire (Catenary curve approximation with quadratic bezier)
    final path = Path();
    path.moveTo(0, size.height * 0.1);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.25, // Dip point
      size.width,
      size.height * 0.1,
    );
    canvas.drawPath(path, paint);

    // Points along the wire to hang things
    // We can approximate positions or calculate them.
    // For simplicity, let's use fixed percentages of width and calculate Y using the bezier formula or just visually fitting.

    final points = [0.15, 0.3, 0.5, 0.7, 0.85];
    final colors = [
      Colors.redAccent,
      Colors.greenAccent,
      Colors.amberAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
    ];

    for (int i = 0; i < points.length; i++) {
      final t = points[i];
      // Quadratic Bezier Point: (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
      final x = size.width * t;
      // Approximate Y on the curve
      // P0=(0, 0.1h), P1=(0.5w, 0.25h), P2=(1w, 0.1h) -> Control point P1 needs to be adjusted for quadratic bezier to pass through dip.
      // Actually standard quadratic bezier control point is roughly where the curve "aims".
      // Let's iterate simply:

      // Simple parabola approximation for Y roughly
      // y = a(x - h)^2 + k
      // vertex (h,k) = (0.5w, 0.25h)
      // pass through (0, 0.1h)
      // 0.1h = a(0 - 0.5w)^2 + 0.25h
      // -0.15h = a * 0.25w^2
      // a = -0.15h / 0.25w^2 = -0.6 * h / w^2  <-- Wait, curve hangs DOWN, so a should be positive if y goes down?
      // Flutter Coord: Y increases downwards.
      // Vertex is lowest point (highest Y value).
      // So vertex is maximum Y.
      // P0y = 0.1h, Vy = 0.25h.
      // y = a(x - 0.5w)^2 + 0.25h (Vertex form open UP? No, open DOWN visually, but Y axis is inverted? No Y is down.)
      // It's a "U" shape in normal view, so it opens "UP" in math terms but Y increases down.. wait.
      // (0,0) is top left.
      // Wire hangs down from top. So it looks like a U.
      // Y increases as we go down.
      // So Vertex is at MAX Y (0.25h).
      // P0 is at 0.1h.
      // Since Vertex > P0, parabola opens UP (if Y was standard), but here Y is down.
      // Actually, standard parabola y = x^2 opens up (y increases).
      // Here we want Y to be LARGEST at center.
      // P0(y=0.1), Vertex(y=0.25).
      // So we have a peak at 0.25.
      // So coefficient must be negative?
      // Let's re-eval:
      // t=0, y=0.1. t=0.5, y=0.25. t=1, y=0.1.
      // y = -a(x-center)^2 + peak ??
      // If we use simple lerp for simplicity:
      // Bezier: B(t) = (1-t)^2 P0 + 2(1-t)t P1 + t^2 P2
      // If P0y=0.1, P2y=0.1. We need P1y such that curve passes through ~0.25 at t=0.5.
      // B(0.5) = 0.25*P0 + 0.5*P1 + 0.25*P2
      // By(0.5) = 0.25*0.1 + 0.5*P1y + 0.25*0.1 = 0.05 + 0.5*P1y.
      // We want By(0.5) = 0.25 (screen height).
      // 0.25 = 0.05 + 0.5*P1y => 0.20 = 0.5*P1y => P1y = 0.4.
      // So Control Point Y is 0.4 * height.

      final double tVal = t;
      final double y =
          math.pow(1 - tVal, 2) * (size.height * 0.1) +
          2 * (1 - tVal) * tVal * (size.height * 0.4) +
          math.pow(tVal, 2) * (size.height * 0.1);

      // Draw Light Bulb or Lantern?
      // Let's alternate or make the center one a big Lantern.

      final isLantern = i == 2; // Center is lantern

      if (isLantern) {
        _drawLantern(
          canvas,
          Offset(x, y),
          animationValue,
          const Color(0xFFFFD700),
        );
      } else {
        final color = colors[i];
        // Alternate lantern/light if needed, or just lights.
        // Let's make index 1 and 3 small lanterns too?
        // Let's make all lanterns for "Fawanis" request?
        // The user said "Fawanis" (Plural).
        // Let's make 1, 2, 3 lanterns. 0 and 4 lights?
        if (i == 1 || i == 3) {
          _drawLantern(canvas, Offset(x, y), animationValue, color, scale: 0.7);
        } else {
          _drawlight(canvas, Offset(x, y), color, animationValue);
        }
      }
    }
  }

  void _drawlight(Canvas canvas, Offset anchor, Color color, double anim) {
    final paint = Paint()
      ..color = color.withOpacity(0.6 + 0.4 * math.sin(anim * 2 * math.pi))
      ..style = PaintingStyle.fill;

    // Draw wire segment down
    canvas.drawLine(
      anchor,
      anchor + const Offset(0, 10),
      Paint()
        ..color = Colors.black54
        ..strokeWidth = 1,
    );

    // Bulb
    canvas.drawCircle(anchor + const Offset(0, 15), 5, paint);

    // Glow
    final glowPaint = Paint()
      ..color = color.withOpacity(
        0.3 * (0.5 + 0.5 * math.sin(anim * 2 * math.pi)),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(anchor + const Offset(0, 15), 12, glowPaint);
  }

  void _drawLantern(
    Canvas canvas,
    Offset anchor,
    double anim,
    Color color, {
    double scale = 1.0,
  }) {
    // Pendulum swing
    // theta = A * cos(omega * t)
    // Use anim value (0..1) but mapped to time.
    final double theta =
        0.1 * math.sin(anim * 2 * math.pi + (anchor.dx / 100)); // phase shift

    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.rotate(theta);
    canvas.scale(scale);

    // Draw Wire String
    final wirePaint = Paint()
      ..color = const Color(0xFFC0C0C0)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset.zero, const Offset(0, 40), wirePaint);

    // Draw Lantern Body
    // Simple Fanous shape:
    // Top triangle (cap)
    // Middle rectangle/trapezoid (glass)
    // Bottom inverted triangle (base)

    final framePaint = Paint()
      ..color =
          const Color(0xFFB8860B) // Dark Gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();

    // Center of lantern starts at (0, 40)
    const double startY = 40;

    // Top Cap
    path.moveTo(0, startY);
    path.lineTo(-10, startY + 15);
    path.lineTo(10, startY + 15);
    path.close();

    // Body (Glass)
    path.moveTo(-10, startY + 15);
    path.lineTo(-15, startY + 45); // widen
    path.lineTo(15, startY + 45);
    path.lineTo(10, startY + 15);
    path.close();

    // Base
    path.moveTo(-15, startY + 45);
    path.lineTo(-8, startY + 60); // narrow
    path.lineTo(8, startY + 60);
    path.lineTo(15, startY + 45);
    path.close();

    // Ring at bottom
    canvas.drawCircle(
      const Offset(0, startY + 63),
      3,
      framePaint..style = PaintingStyle.stroke,
    );

    // Fix: Paint does not have copyWith. We just need to set the color on a new paint or modify existing.
    final fillPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, framePaint..style = PaintingStyle.stroke);

    // Glow in center
    final glowPaint = Paint()
      ..color = Colors.yellow.withOpacity(
        0.4 + 0.2 * math.sin(anim * 4 * math.pi),
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(const Offset(0, startY + 30), 10, glowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RamadanPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
