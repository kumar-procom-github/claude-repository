import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../templates/card_template.dart';

/// Small moving illustrations above a story frame's heading.
enum StoryIcon {
  /// Purna kalasam — సుముహూర్తం.
  kalasam,

  /// Calendar — date & time (no muhurtham).
  calendar,

  /// Pillared mandapam — venue.
  mandapam,

  /// Banana-leaf meal and a steaming pot — lunch / dinner.
  meal,

  /// Lotus and lamps — the welcome at the end.
  welcome,
}

/// Draws a [StoryIcon] in the card's colours. [progress] 0 → 1 is the
/// entrance; [time] keeps it alive (leaves sway, steam rises, flames flicker).
class StoryIconPainter extends CustomPainter {
  StoryIconPainter(this.icon, this.t, {required this.progress, required this.time});
  final StoryIcon icon;
  final CardTemplate t;
  final double progress;
  final double time;

  Paint _fill(Color c) => Paint()..color = c;
  Paint _stroke(Color c, double w) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;

  void _leaf(Canvas canvas, Offset base, double len, double w, double angle) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle + 0.06 * math.sin(time * 1.8 + base.dx * 0.1));
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(w, -len * 0.45, 0, -len)
        ..quadraticBezierTo(-w, -len * 0.45, 0, 0)
        ..close(),
      _fill(t.leaf),
    );
    canvas.restore();
  }

  void _flame(Canvas canvas, Offset base, double h) {
    final f = 1 + 0.12 * math.sin(time * 11 + base.dx) + 0.06 * math.sin(time * 23 + base.dx * 2);
    final hh = h * f;
    canvas.drawCircle(
        base.translate(0, -hh * 0.5),
        hh * 1.1,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x66FFC85A), Color(0x00FFC85A)])
              .createShader(Rect.fromCircle(center: base.translate(0, -hh * 0.5), radius: hh * 1.1)));
    canvas.drawPath(
      Path()
        ..moveTo(base.dx, base.dy - hh)
        ..quadraticBezierTo(base.dx + hh * 0.42, base.dy - hh * 0.3, base.dx, base.dy)
        ..quadraticBezierTo(base.dx - hh * 0.42, base.dy - hh * 0.3, base.dx, base.dy - hh)
        ..close(),
      _fill(const Color(0xFFFFB703)),
    );
  }

  void _diya(Canvas canvas, Offset c, double s) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx - 14 * s, c.dy)
        ..quadraticBezierTo(c.dx, c.dy + 13 * s, c.dx + 14 * s, c.dy)
        ..close(),
      _fill(t.frame),
    );
    _flame(canvas, c.translate(0, -2 * s), 13 * s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = Curves.easeOutBack.transform(progress.clamp(0.0, 1.0));
    if (p <= 0) return;
    final c = size.center(Offset.zero);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(0.6 + 0.4 * p);
    canvas.translate(-c.dx, -c.dy + 2 * math.sin(time * 1.5));
    final s = size.height / 80;
    final gold = t.frame;
    switch (icon) {
      case StoryIcon.kalasam:
        final rim = c.translate(0, -2 * s);
        for (var i = -2; i <= 2; i++) {
          _leaf(canvas, rim, 26 * s, 7 * s, i * 0.42);
        }
        canvas.drawCircle(rim.translate(0, -9 * s), 10 * s, _fill(const Color(0xFF8D5524)));
        canvas.drawOval(Rect.fromCenter(center: rim, width: 34 * s, height: 8 * s), _fill(gold));
        canvas.drawRect(Rect.fromCenter(center: rim.translate(0, 5 * s), width: 18 * s, height: 8 * s), _fill(gold));
        final body = rim.translate(0, 26 * s);
        canvas.drawCircle(body, 20 * s, _fill(gold));
        canvas.drawLine(body.translate(-19 * s, -5 * s), body.translate(19 * s, -5 * s), _stroke(t.marigold, 2.4 * s));
        canvas.drawCircle(body.translate(0, 5 * s), 3.4 * s, _fill(t.marigoldCenter));
        // Twinkles.
        for (var k = 0; k < 4; k++) {
          final a = time * 0.8 + k * math.pi / 2;
          final r = (2 + 1.5 * math.sin(time * 3 + k)) * s;
          canvas.drawCircle(c + Offset(math.cos(a) * 38 * s, math.sin(a) * 26 * s), r, _fill(t.accent.withAlpha(200)));
        }
      case StoryIcon.calendar:
        final r = Rect.fromCenter(center: c.translate(0, 4 * s), width: 56 * s, height: 52 * s);
        canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(8 * s)), _stroke(gold, 2.4 * s));
        canvas.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 12 * s), _fill(gold));
        for (final x in [r.left + 14 * s, r.right - 14 * s]) {
          canvas.drawLine(Offset(x, r.top - 6 * s), Offset(x, r.top + 4 * s), _stroke(t.accent, 3 * s));
        }
        for (var row = 0; row < 3; row++) {
          for (var col = 0; col < 4; col++) {
            final on = row == 1 && col == 2;
            final pt = Offset(r.left + (10 + col * 12) * s, r.top + (22 + row * 10) * s);
            canvas.drawCircle(pt, (on ? 3.6 + 0.8 * math.sin(time * 4) : 2) * s, _fill(on ? t.marigoldCenter : gold));
          }
        }
      case StoryIcon.mandapam:
        final base = c.translate(0, 30 * s);
        canvas.drawRect(Rect.fromCenter(center: base, width: 84 * s, height: 6 * s), _fill(gold));
        canvas.drawRect(Rect.fromCenter(center: base.translate(0, -5 * s), width: 72 * s, height: 4 * s), _fill(gold));
        for (final x in [-30.0, -12.0, 12.0, 30.0]) {
          canvas.drawRect(Rect.fromLTWH(c.dx + (x - 2.5) * s, c.dy - 12 * s, 5 * s, 35 * s), _fill(gold));
        }
        // Roof and dome.
        canvas.drawPath(
          Path()
            ..moveTo(c.dx - 42 * s, c.dy - 12 * s)
            ..lineTo(c.dx + 42 * s, c.dy - 12 * s)
            ..lineTo(c.dx + 28 * s, c.dy - 22 * s)
            ..lineTo(c.dx - 28 * s, c.dy - 22 * s)
            ..close(),
          _fill(gold),
        );
        canvas.drawArc(Rect.fromCenter(center: c.translate(0, -22 * s), width: 34 * s, height: 26 * s), math.pi, math.pi,
            true, _fill(gold));
        canvas.drawCircle(c.translate(0, -38 * s), 3 * s, _fill(t.marigoldCenter));
        // A swinging marigold toran between the pillars.
        for (var k = 0; k < 7; k++) {
          final u = k / 6;
          final pt = Offset(c.dx + (-28 + 56 * u) * s,
              c.dy + (-8 + 7 * math.sin(u * math.pi) + 1.5 * math.sin(time * 2 + k)) * s);
          canvas.drawCircle(pt, 3 * s, _fill(k.isEven ? t.marigold : t.marigoldCenter));
        }
      case StoryIcon.meal:
        // Banana leaf with rice and curries.
        canvas.save();
        canvas.translate(c.dx - 6 * s, c.dy + 18 * s);
        canvas.rotate(-0.12);
        canvas.drawPath(
          Path()
            ..moveTo(-44 * s, 0)
            ..quadraticBezierTo(-10 * s, -22 * s, 44 * s, -6 * s)
            ..quadraticBezierTo(14 * s, 16 * s, -44 * s, 0)
            ..close(),
          _fill(const Color(0xFF3F8F3A)),
        );
        canvas.drawLine(Offset(-42 * s, 0), Offset(42 * s, -5 * s), _stroke(const Color(0xFF8BC34A), 1.4 * s));
        canvas.drawOval(Rect.fromCenter(center: Offset(-2 * s, -5 * s), width: 22 * s, height: 11 * s),
            _fill(const Color(0xFFFFFBEF)));
        for (final (dx, col) in [
          (-24.0, const Color(0xFFE85D04)),
          (16.0, const Color(0xFFFFB703)),
          (28.0, const Color(0xFF6A994E)),
          (-14.0, const Color(0xFFB5179E)),
        ]) {
          canvas.drawCircle(Offset(dx * s, -6 * s + (dx > 0 ? 2 : -1) * s), 4.2 * s, _fill(col));
        }
        canvas.restore();
        // Steaming pot.
        final pot = c.translate(30 * s, -8 * s);
        canvas.drawArc(Rect.fromCenter(center: pot, width: 26 * s, height: 22 * s), 0, math.pi, true, _fill(gold));
        canvas.drawRect(Rect.fromCenter(center: pot.translate(0, -1 * s), width: 30 * s, height: 3 * s), _fill(gold));
        for (var k = 0; k < 3; k++) {
          final phase = (time * 0.6 + k / 3) % 1.0;
          final x = pot.dx + (k - 1) * 7 * s;
          final path = Path()..moveTo(x, pot.dy - 4 * s);
          for (var j = 1; j <= 8; j++) {
            path.lineTo(x + math.sin(j * 0.9 + time * 3 + k) * 2.5 * s, pot.dy - 4 * s - j * 2.6 * s * (0.5 + phase));
          }
          canvas.drawPath(path, _stroke(t.text.withAlpha((180 * (1 - phase)).round()), 1.4 * s));
        }
      case StoryIcon.welcome:
        // Lotus between two lamps.
        final lb = c.translate(0, 18 * s);
        for (var i = 0; i < 7; i++) {
          canvas.save();
          canvas.translate(lb.dx, lb.dy);
          canvas.rotate((i - 3) * 0.33 + 0.02 * math.sin(time * 1.6 + i));
          canvas.drawOval(Rect.fromCenter(center: Offset(0, -15 * s), width: 10 * s, height: 30 * s),
              _fill(Color.lerp(t.accent, const Color(0xFFFF8FB1), 0.45)!.withAlpha(235)));
          canvas.restore();
        }
        canvas.drawLine(lb.translate(-30 * s, 2 * s), lb.translate(30 * s, 2 * s), _stroke(t.leaf, 2.4 * s));
        _diya(canvas, c.translate(-40 * s, 20 * s), s * 0.9);
        _diya(canvas, c.translate(40 * s, 20 * s), s * 0.9);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StoryIconPainter old) =>
      old.progress != progress || old.time != time || old.icon != icon || old.t != t;
}

/// Colours and fonts of the "Watercolour flowers" video look.
const watercolorTemplate = CardTemplate(
  id: 'watercolor',
  name: 'Watercolour',
  nameTe: 'వాటర్‌కలర్',
  background: [Color(0xFFFDFBFD), Color(0xFFF7F4FA)],
  frame: Color(0xFFCFAE62),
  text: Color(0xFF2E4A9C),
  accent: Color(0xFF2546A8),
  leaf: Color(0xFF9C88D0),
  marigold: Color(0xFF7FA0E0),
  marigoldCenter: Color(0xFF3550B0),
  teTitleFont: 'Baloo Tammudu 2',
  teBodyFont: 'Mandali',
  enTitleFont: 'Cormorant SC',
  enNameFont: 'Great Vibes',
  enBodyFont: 'Cormorant Garamond',
);

/// "Watercolour flowers" look: soft pink and blue washes on white paper,
/// painted blue and violet flowers in the corners that grow in and sway,
/// thin gold frame lines and drifting light specks.
class WatercolorPainter extends CustomPainter {
  WatercolorPainter({required this.time, required this.bloom, this.pulse = 0, this.background = true, this.flowers = true});

  final double time;

  /// 0 → 1: the flowers grow in from the corners.
  final double bloom;

  /// Extra sway when a new frame comes in.
  final double pulse;
  final bool background;
  final bool flowers;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rect = Offset.zero & size;
    canvas.clipRect(rect);
    if (background) {
      canvas.drawRect(rect, Paint()..color = const Color(0xFFFDFBFD));
      // Washes of colour that drift slowly.
      for (final (x, y, r, col) in [
        (0.82, 0.18, 0.75, const Color(0x66F7C6D3)),
        (0.15, 0.62, 0.8, const Color(0x5CC3D6F3)),
        (0.7, 0.86, 0.6, const Color(0x55D9CCF2)),
        (0.3, 0.12, 0.5, const Color(0x40CFE3F7)),
      ]) {
        final c = Offset(w * (x + 0.03 * math.sin(time * 0.25 + y * 7)), h * (y + 0.02 * math.cos(time * 0.2 + x * 5)));
        canvas.drawCircle(
            c,
            w * r,
            Paint()
              ..shader = RadialGradient(colors: [col, col.withAlpha(0)]).createShader(Rect.fromCircle(center: c, radius: w * r)));
      }
      // Light specks.
      final rnd = math.Random(3);
      for (var k = 0; k < 18; k++) {
        final x = rnd.nextDouble() * w, y0 = rnd.nextDouble() * h, sp = 6 + rnd.nextDouble() * 10;
        final y = (y0 - time * sp) % h;
        final a = (0.4 + 0.6 * (0.5 + 0.5 * math.sin(time * 2 + k))) * 150;
        canvas.drawCircle(Offset(x, y), 1.2 + rnd.nextDouble() * 2.2, Paint()..color = Colors.white.withAlpha(a.round()));
      }
    }
    if (!flowers) return;
    final g = Curves.easeOutCubic.transform(bloom.clamp(0.0, 1.0));
    if (g <= 0) return;
    // Thin gold frame: two lines a little apart, crossing at the corners.
    final gold = Paint()
      ..color = const Color(0xFFCFAE62).withAlpha((200 * g).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawRect(Rect.fromLTRB(26, 38, w - 22, h - 34), gold);
    canvas.drawLine(const Offset(18, 46), Offset(w - 14, 42), gold);
    canvas.drawLine(Offset(16, h - 40), Offset(w - 12, h - 44), gold);
    canvas.drawLine(const Offset(34, 26), Offset(30, h - 22), gold);
    canvas.drawLine(Offset(w - 30, 24), Offset(w - 34, h - 24), gold);

    // Corner bouquets (big top-right and bottom-left, small in the other corners).
    _bouquet(canvas, Offset(w - 18, 22), 1.0, math.pi * 0.75, g, 0);
    _bouquet(canvas, Offset(18, h - 22), 1.0, -math.pi * 0.25, g, 1);
    _bouquet(canvas, const Offset(14, 18), 0.55, math.pi * 0.25, g, 2);
    _bouquet(canvas, Offset(w - 14, h - 18), 0.6, -math.pi * 0.75, g, 3);
  }

  void _bouquet(Canvas canvas, Offset corner, double scale, double towards, double grow, int seed) {
    final sway = 0.05 * math.sin(time * 1.3 + seed * 1.7) + 0.06 * pulse * math.sin(seed + 1.0);
    canvas.save();
    canvas.translate(corner.dx, corner.dy);
    canvas.rotate(towards - math.pi / 2 + sway);
    canvas.scale(scale * grow);
    final rnd = math.Random(11 + seed);
    // Leaves.
    for (var k = 0; k < 9; k++) {
      final a = -1.1 + rnd.nextDouble() * 2.2;
      final len = 34 + rnd.nextDouble() * 34;
      final col = k.isEven ? const Color(0xB39C88D0) : const Color(0xA68FB5A6);
      canvas.save();
      canvas.translate(rnd.nextDouble() * 20 - 10, 20 + rnd.nextDouble() * 30);
      canvas.rotate(a + 0.08 * math.sin(time * 1.7 + k));
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(len * 0.22, len * 0.5, 0, len)
          ..quadraticBezierTo(-len * 0.22, len * 0.5, 0, 0)
          ..close(),
        Paint()..color = col,
      );
      canvas.restore();
    }
    // Berries on thin stems.
    for (var k = 0; k < 5; k++) {
      final p = Offset(-30 + rnd.nextDouble() * 60, 60 + rnd.nextDouble() * 30);
      canvas.drawLine(Offset.zero.translate(0, 40), p, Paint()
        ..color = const Color(0x88E59BB0)
        ..strokeWidth = 1);
      canvas.drawCircle(p, 2.6, Paint()..color = const Color(0xCCE77F9A));
    }
    // Flowers: soft watercolour petals, deep blue in the middle.
    for (final (dx, dy, r) in [(0.0, 34.0, 30.0), (-30.0, 56.0, 22.0), (26.0, 62.0, 20.0)]) {
      final c = Offset(dx, dy);
      final breathe = 1 + 0.03 * math.sin(time * 1.2 + dx);
      final spin = time * 0.05 + dx;
      for (var k = 0; k < 6; k++) {
        final a = spin + k * math.pi / 3;
        final pc = c + Offset(math.cos(a), math.sin(a)) * r * 0.55 * breathe;
        canvas.drawCircle(
            pc,
            r * 0.55,
            Paint()
              ..shader = const RadialGradient(colors: [Color(0xCC6F8FD8), Color(0x99B9CCF2), Color(0x33DCE6FA)])
                  .createShader(Rect.fromCircle(center: pc, radius: r * 0.55)));
      }
      canvas.drawCircle(
          c,
          r * 0.42,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0xFF2C3F9E), Color(0xCC4D6CC8), Color(0x004D6CC8)])
                .createShader(Rect.fromCircle(center: c, radius: r * 0.42)));
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3 + 0.3;
        canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * r * 0.16, 1.4, Paint()..color = const Color(0xE6FFF3C4));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WatercolorPainter old) =>
      old.time != time || old.bloom != bloom || old.pulse != pulse;
}
