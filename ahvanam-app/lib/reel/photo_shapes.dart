import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Shapes for people's photos in video invitations.
enum PhotoShape {
  splash('Paint splash', 'పెయింట్'),
  wave('Wave', 'అల'),
  arch('Arch', 'ఆర్చ్'),
  circle('Circle', 'వృత్తం'),
  heart('Heart', 'హృదయం'),
  hexagon('Hexagon', 'షట్కోణం');

  const PhotoShape(this.en, this.te);
  final String en;
  final String te;

  static PhotoShape byName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => PhotoShape.splash);

  /// The shape inside [r].
  Path path(Rect r) {
    final c = r.center, w = r.width, h = r.height;
    switch (this) {
      case PhotoShape.splash:
        // An uneven blob, like a splash of paint.
        final p = Path();
        const n = 72;
        for (var k = 0; k <= n; k++) {
          final a = 2 * math.pi * k / n;
          final f = 0.9 + 0.06 * math.sin(5 * a + 0.6) + 0.04 * math.sin(9 * a + 2.1) + 0.03 * math.cos(13 * a);
          final pt = c + Offset(math.cos(a) * w / 2 * f, math.sin(a) * h / 2 * f);
          k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        return p..close();
      case PhotoShape.wave:
        // Rectangle with wavy top and bottom edges.
        final p = Path()..moveTo(r.left, r.top + h * 0.06);
        const n = 40;
        for (var k = 0; k <= n; k++) {
          final x = r.left + w * k / n;
          p.lineTo(x, r.top + h * 0.06 + math.sin(k / n * 2 * math.pi * 1.5) * h * 0.05);
        }
        p.lineTo(r.right, r.bottom - h * 0.06);
        for (var k = n; k >= 0; k--) {
          final x = r.left + w * k / n;
          p.lineTo(x, r.bottom - h * 0.06 + math.sin(k / n * 2 * math.pi * 1.5 + math.pi) * h * 0.05);
        }
        return p..close();
      case PhotoShape.arch:
        return Path()
          ..moveTo(r.left, r.bottom)
          ..lineTo(r.left, r.top + w / 2)
          ..arcToPoint(Offset(r.right, r.top + w / 2), radius: Radius.circular(w / 2))
          ..lineTo(r.right, r.bottom)
          ..close();
      case PhotoShape.circle:
        final d = math.min(w, h);
        return Path()..addOval(Rect.fromCenter(center: c, width: d, height: d));
      case PhotoShape.heart:
        return Path()
          ..moveTo(c.dx, r.top + h * 0.28)
          ..cubicTo(c.dx - w * 0.05, r.top - h * 0.02, r.left - w * 0.02, r.top + h * 0.06, r.left + w * 0.02, r.top + h * 0.36)
          ..cubicTo(r.left + w * 0.06, r.top + h * 0.62, c.dx - w * 0.2, r.top + h * 0.8, c.dx, r.bottom)
          ..cubicTo(c.dx + w * 0.2, r.top + h * 0.8, r.right - w * 0.06, r.top + h * 0.62, r.right - w * 0.02, r.top + h * 0.36)
          ..cubicTo(r.right + w * 0.02, r.top + h * 0.06, c.dx + w * 0.05, r.top - h * 0.02, c.dx, r.top + h * 0.28)
          ..close();
      case PhotoShape.hexagon:
        final p = Path();
        for (var k = 0; k < 6; k++) {
          final a = -math.pi / 2 + k * math.pi / 3;
          final pt = c + Offset(math.cos(a) * w / 2, math.sin(a) * h / 2);
          k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        return p..close();
    }
  }

  /// Width ÷ height of the box this shape looks best in.
  double get aspect => switch (this) {
        PhotoShape.circle || PhotoShape.splash || PhotoShape.hexagon => 1.0,
        PhotoShape.heart => 1.05,
        PhotoShape.arch || PhotoShape.wave => 0.82,
      };
}

/// A face in a photo: centre and face width, as fractions of the photo.
typedef FaceSpot = ({double x, double y, double size});

/// A person's photo in a [PhotoShape]: zoomed onto the face, with a gold
/// edge, an entrance that suits the shape and a slow zoom while on screen.
class ShapedPhoto extends StatelessWidget {
  const ShapedPhoto({
    super.key,
    required this.image,
    required this.shape,
    required this.color,
    this.face,
    this.progress = 1,
    this.time = 0,
    this.height = 210,
  });

  final ui.Image image;
  final PhotoShape shape;
  final Color color;
  final FaceSpot? face;

  /// 0 → 1 entrance.
  final double progress;

  /// Seconds the photo has been on screen (slow zoom).
  final double time;
  final double height;

  @override
  Widget build(BuildContext context) {
    final w = height * shape.aspect;
    return SizedBox(
      width: w + 24,
      height: height + 24,
      child: CustomPaint(painter: _ShapedPhotoPainter(this)),
    );
  }
}

class _ShapedPhotoPainter extends CustomPainter {
  _ShapedPhotoPainter(this.p);
  final ShapedPhoto p;

  @override
  void paint(Canvas canvas, Size size) {
    final t = p.progress.clamp(0.0, 1.0);
    if (t <= 0) return;
    final box = Rect.fromCenter(center: size.center(Offset.zero), width: size.width - 24, height: size.height - 24);
    final ease = Curves.easeOutBack.transform(t);

    canvas.save();
    // Entrance: splash spreads open, wave slides in, others grow in.
    switch (p.shape) {
      case PhotoShape.wave:
        canvas.translate((1 - Curves.easeOutCubic.transform(t)) * -60, 0);
      default:
        final s = p.shape == PhotoShape.splash ? 0.2 + 0.8 * ease : 0.85 + 0.15 * ease;
        canvas.translate(box.center.dx, box.center.dy);
        canvas.scale(s);
        canvas.translate(-box.center.dx, -box.center.dy);
    }
    final alpha = (t * 2).clamp(0.0, 1.0);
    final path = p.shape.path(box);

    // Soft glow behind.
    canvas.drawPath(
        path.shift(const Offset(0, 4)),
        Paint()
          ..color = p.color.withAlpha((90 * alpha).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));

    // The photo, zoomed so the face sits in the middle of the shape.
    final img = p.image;
    final iw = img.width.toDouble(), ih = img.height.toDouble();
    final f = p.face;
    final boxAspect = box.width / box.height;
    // Show about 2.6 face-widths across, or the whole photo's short side.
    var srcW = f == null ? math.min(iw, ih * boxAspect) : math.min(iw, f.size * iw * 2.6);
    var srcH = srcW / boxAspect;
    if (srcH > ih) {
      srcH = ih;
      srcW = srcH * boxAspect;
    }
    // Slow zoom while on screen.
    final zoom = 1 + 0.06 * (p.time / 5).clamp(0.0, 1.0);
    srcW /= zoom;
    srcH /= zoom;
    final cx = f == null ? iw / 2 : f.x * iw;
    final cy = f == null ? ih * 0.42 : f.y * ih;
    final src = Rect.fromLTWH(
      (cx - srcW / 2).clamp(0.0, iw - srcW),
      (cy - srcH / 2).clamp(0.0, ih - srcH),
      srcW,
      srcH,
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawImageRect(img, src, box, Paint()
      ..filterQuality = FilterQuality.medium
      ..color = Color.fromARGB((255 * alpha).round(), 255, 255, 255));
    canvas.restore();

    // Gold edge.
    canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = p.color.withAlpha((255 * alpha).round()));

    // Paint drops around the splash.
    if (p.shape == PhotoShape.splash) {
      final dots = Paint()..color = p.color.withAlpha((220 * alpha).round());
      final rnd = math.Random(7);
      for (var k = 0; k < 9; k++) {
        final a = rnd.nextDouble() * 2 * math.pi;
        final d = 0.56 + rnd.nextDouble() * 0.12;
        final pt = box.center + Offset(math.cos(a) * box.width * d, math.sin(a) * box.height * d);
        canvas.drawCircle(pt, (2 + rnd.nextDouble() * 4) * t, dots);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ShapedPhotoPainter old) =>
      old.p.progress != p.progress ||
      old.p.time != p.time ||
      old.p.image != p.image ||
      old.p.shape != p.shape ||
      old.p.face != p.face ||
      old.p.color != p.color;
}
