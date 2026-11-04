import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'card_template.dart';

/// Paints the card background and ornaments for each [CardLayout]
/// (Hindu, Muslim and Christian motifs plus shared floral ones):
///  * toran   – mango-leaf & marigold toran, double frame, lotus
///  * temple  – temple-arch doorway with kalasam finial, bells, step border
///  * kalasam – purna kalasam on top, mandala watermark, corner mandalas
///  * modern  – clean gold rules, small marigold sprays in two corners
/// Everything is vector-drawn on a 360 × 640 design canvas (scaled to size).
/// What [CardPainter] draws. Cards always use [all]; the video editor's
/// story mode draws the background and the ornaments separately.
enum CardPaintPart { all, background, ornaments }

class CardPainter extends CustomPainter {
  CardPainter(this.t, this.layout, {this.part = CardPaintPart.all, this.time});
  final CardTemplate t;
  final CardLayout layout;
  final CardPaintPart part;

  /// Seconds into a video: the art comes alive (flames flicker, leaves and
  /// toran sway, mandalas and flower wreaths turn, bells and lanterns swing,
  /// stars twinkle). null = a still card (card screens, saved images, PDF).
  final double? time;

  bool get _live => time != null;
  double get _tt => time ?? 0;

  /// Gentle back-and-forth (radians or pixels), different per [phase].
  double _sway(double phase, double amp) => _live ? amp * math.sin(_tt * 1.7 + phase) : 0;

  /// Flame height factor around 1.
  double _flick(double phase) =>
      _live ? 1 + 0.12 * math.sin(_tt * 11 + phase) + 0.07 * math.sin(_tt * 23.7 + phase * 2.3) : 1;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 360; // scale from the design canvas
    final rect = Offset.zero & size;
    canvas.clipRect(rect); // corner ornaments must not bleed outside the card

    if (part != CardPaintPart.ornaments) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: t.background,
          ).createShader(rect),
      );
    }
    if (part == CardPaintPart.background) return;

    switch (layout) {
      case CardLayout.toran:
        _doubleFrame(canvas, size, s);
        _toran(canvas, size, s);
        _lotus(canvas, Offset(size.width / 2, size.height - 30 * s), s);
      case CardLayout.temple:
        _templeArch(canvas, size, s);
      case CardLayout.kalasam:
        _kalasamLayout(canvas, size, s);
      case CardLayout.modern:
        _modern(canvas, size, s);
      case CardLayout.garland:
        _garlandLayout(canvas, size, s);
      case CardLayout.gopuram:
        _gopuram(canvas, size, s);
      case CardLayout.deepam:
        _deepamLayout(canvas, size, s);
      case CardLayout.wreath:
        _wreath(canvas, size, s);
      case CardLayout.mehrab:
        _mehrab(canvas, size, s);
      case CardLayout.lanterns:
        _lanternsLayout(canvas, size, s);
      case CardLayout.chapel:
        _chapel(canvas, size, s);
      case CardLayout.bells:
        _bellsLayout(canvas, size, s);
      case CardLayout.deepaSmriti:
        _deepaSmriti(canvas, size, s);
      case CardLayout.hilal:
        _hilal(canvas, size, s);
      case CardLayout.candle:
        _candleLayout(canvas, size, s);
      case CardLayout.serene:
        _serene(canvas, size, s);
      case CardLayout.kites:
        _kitesLayout(canvas, size, s);
      case CardLayout.balloons:
        _balloonsLayout(canvas, size, s);
      case CardLayout.fireworks:
        _fireworksLayout(canvas, size, s);
    }
  }

  // ------------------------------------------------------------- remembrance --

  void _thinFrames(Canvas canvas, Size size, double s) {
    canvas.drawRect(Rect.fromLTRB(16 * s, 16 * s, size.width - 16 * s, size.height - 16 * s), _stroke(1.2 * s));
    canvas.drawRect(Rect.fromLTRB(22 * s, 22 * s, size.width - 22 * s, size.height - 22 * s), _stroke(0.6 * s));
  }

  void _glow(Canvas canvas, Offset c, double r) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x73FFC85A), Color(0x00FFC85A)])
            .createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  Path _flame(Offset base, double h, double w) => _flamePath(base, h * _flick(base.dx * 0.1 + w), w);

  Path _flamePath(Offset base, double h, double w) => Path()
    ..moveTo(base.dx, base.dy - h)
    ..quadraticBezierTo(base.dx + w, base.dy - h * 0.27, base.dx, base.dy)
    ..quadraticBezierTo(base.dx - w, base.dy - h * 0.27, base.dx, base.dy - h)
    ..close();

  void _deepaSmriti(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    _thinFrames(canvas, size, s);
    final c = Offset(cx, 96 * s);
    _glow(canvas, c - Offset(0, 14 * s), 40 * s);
    canvas.drawPath(
        Path()
          ..moveTo(cx - 22 * s, c.dy)
          ..quadraticBezierTo(cx, c.dy + 20 * s, cx + 22 * s, c.dy)
          ..quadraticBezierTo(cx + 26 * s, c.dy - 3 * s, cx + 30 * s, c.dy - 6 * s)
          ..lineTo(cx + 20 * s, c.dy - 2 * s)
          ..close(),
        _fill(t.frame));
    canvas.drawOval(Rect.fromCenter(center: c, width: 44 * s, height: 7 * s), _fill(t.accent));
    canvas.drawPath(_flame(c - Offset(0, 5 * s), 22 * s, 9 * s), _fill(const Color(0xFFF2B544)));
    canvas.drawPath(_flame(c - Offset(0, 5 * s), 14 * s, 4.5 * s), _fill(const Color(0xFFFFF3C4)));
    // Lotus outline at the bottom.
    final lb = Offset(cx, h - 46 * s);
    for (var i = 0; i < 7; i++) {
      canvas.save();
      canvas.translate(lb.dx, lb.dy);
      canvas.rotate((i - 3) * 0.33);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -11 * s), width: 9 * s, height: 23 * s), _stroke(1.1 * s));
      canvas.restore();
    }
    canvas.drawLine(Offset(70 * s, h - 44 * s), Offset(cx - 34 * s, h - 44 * s), _stroke(0.8 * s));
    canvas.drawLine(Offset(cx + 34 * s, h - 44 * s), Offset(w - 70 * s, h - 44 * s), _stroke(0.8 * s));
  }

  void _hilal(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    _thinFrames(canvas, size, s);
    for (final c in [Offset(22 * s, 22 * s), Offset(w - 22 * s, 22 * s), Offset(22 * s, h - 22 * s), Offset(w - 22 * s, h - 22 * s)]) {
      _star8(canvas, c, 6 * s);
    }
    canvas.drawCircle(Offset(cx, 62 * s), 16 * s, _fill(t.frame));
    canvas.drawCircle(Offset(cx + 6 * s, 58 * s), 13.5 * s, _fill(t.background.first));
    final star = Path();
    for (var k = 0; k < 10; k++) {
      final r = (k.isOdd ? 2.0 : 5.0) * s;
      final a = -math.pi / 2 + k * math.pi / 5;
      final p = Offset(cx + 16 * s + math.cos(a) * r, 50 * s + math.sin(a) * r);
      if (k == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(star..close(), _fill(t.frame));
    final y = h - 50 * s;
    canvas.drawLine(Offset(70 * s, y), Offset(cx - 12 * s, y), _stroke(0.8 * s));
    canvas.drawLine(Offset(cx + 12 * s, y), Offset(w - 70 * s, y), _stroke(0.8 * s));
    _star8(canvas, Offset(cx, y), 6 * s);
  }

  void _lily(Canvas canvas, Offset base, double s, double dir) {
    _leaf(canvas, base + Offset(0, 20 * s), 34 * s, 6 * s, angle: -math.pi / 2 + dir * 0.25);
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(dir * 0.35);
    for (final a in [-0.6, 0.0, 0.6]) {
      canvas.save();
      canvas.rotate(a);
      final petal = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(7 * s, -10 * s, 0, -22 * s)
        ..quadraticBezierTo(-7 * s, -10 * s, 0, 0)
        ..close();
      canvas.drawPath(petal, _fill(Colors.white));
      canvas.drawPath(petal, _stroke(0.8, t.frame));
      canvas.restore();
    }
    canvas.drawCircle(Offset(0, -4 * s), 1.6 * s, _fill(t.marigoldCenter));
    canvas.restore();
  }

  void _candleLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    _thinFrames(canvas, size, s);
    canvas.drawRect(Rect.fromLTWH(cx - 2 * s, 34 * s, 4 * s, 30 * s), _fill(t.frame));
    canvas.drawRect(Rect.fromLTWH(cx - 10 * s, 42 * s, 20 * s, 4 * s), _fill(t.frame));
    final top = h - 128 * s; // top of the candle body
    _glow(canvas, Offset(cx, top - 12 * s), 60 * s);
    final body = Rect.fromLTWH(cx - 10 * s, top, 20 * s, 82 * s);
    canvas.drawRect(body, _fill(Colors.white));
    canvas.drawRect(body, _stroke(1 * s));
    canvas.drawRect(Rect.fromLTWH(cx - 16 * s, body.bottom, 32 * s, 5 * s), _fill(t.frame));
    canvas.drawPath(_flame(Offset(cx, top - 2 * s), 24 * s, 8 * s), _fill(const Color(0xFFF2B544)));
    canvas.drawPath(_flame(Offset(cx, top - 2 * s), 15 * s, 3.5 * s), _fill(const Color(0xFFFFF3C4)));
    _lily(canvas, Offset(cx - 46 * s, h - 80 * s), s, -1);
    _lily(canvas, Offset(cx - 70 * s, h - 64 * s), 0.85 * s, -1);
    _lily(canvas, Offset(cx + 46 * s, h - 80 * s), s, 1);
    _lily(canvas, Offset(cx + 70 * s, h - 64 * s), 0.85 * s, 1);
  }

  /// Leaves with three small jasmine flowers; [dir] 1 = pointing up, -1 = down.
  void _sprig(Canvas canvas, Offset c, double s, double dir) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(s, s * dir);
    _leaf(canvas, Offset.zero, 30, 7, angle: -math.pi / 2 - 0.9);
    _leaf(canvas, Offset.zero, 30, 7, angle: -math.pi / 2 + 0.9);
    for (final (dx, dy) in const [(-12.0, -16.0), (0.0, -23.0), (12.0, -16.0)]) {
      for (var k = 0; k < 5; k++) {
        final a = k * 2 * math.pi / 5;
        canvas.drawCircle(Offset(dx + math.cos(a) * 3, dy + math.sin(a) * 3), 2.4, _fill(Colors.white));
      }
      canvas.drawCircle(Offset(dx, dy), 5.4, _stroke(0.6, const Color(0x1F000000)));
      canvas.drawCircle(Offset(dx, dy), 1.4, _fill(t.marigoldCenter));
    }
    canvas.restore();
  }

  void _serene(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(18 * s, 18 * s, w - 18 * s, h - 18 * s), Radius.circular(12 * s)),
        _stroke(1 * s));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(24 * s, 24 * s, w - 24 * s, h - 24 * s), Radius.circular(9 * s)),
        _stroke(0.5 * s));
    _sprig(canvas, Offset(cx, 78 * s), 1.3 * s, 1);
    _sprig(canvas, Offset(cx, h - 78 * s), 1.3 * s, -1);
  }

  // ------------------------------------------------------- Muslim / Christian --

  /// Pointed arch (Islamic mehrab / gothic chapel window) on the design canvas.
  Path _pointedArch(double l, double r, double b, double sh, double ap, double s,
      {double k1 = 0.55, double k2 = 0.08, double k3 = 0.25}) {
    final cx = 180 * s, w = r - l;
    return Path()
      ..moveTo(l, b)
      ..lineTo(l, sh)
      ..cubicTo(l, sh - (sh - ap) * k1, cx - w * k2, ap + (sh - ap) * k3, cx, ap)
      ..cubicTo(cx + w * k2, ap + (sh - ap) * k3, r, sh - (sh - ap) * k1, r, sh)
      ..lineTo(r, b)
      ..close();
  }

  void _crescent(Canvas canvas, Offset c, double r, Color cutout) {
    canvas.drawCircle(c, r, _fill(t.frame));
    canvas.drawCircle(c + Offset(r * 0.38, -r * 0.22), r * 0.84, _fill(cutout));
  }

  double _twinkle(Offset c) => _live ? 0.8 + 0.2 * math.sin(_tt * 3.2 + c.dx * 0.13 + c.dy * 0.07) : 1.0;

  void _star8(Canvas canvas, Offset c, double r) {
    r *= _twinkle(c);
    for (final rot in [0.0, math.pi / 4]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(rot);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: r * 1.4, height: r * 1.4), _fill(t.frame));
      canvas.restore();
    }
  }

  void _sparkle(Canvas canvas, Offset c, double r) {
    r *= _twinkle(c);
    final p = Path();
    for (var k = 0; k < 8; k++) {
      final rad = k.isOdd ? r * 0.31 : r;
      final a = k * math.pi / 4;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rad;
      if (k == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p..close(), _fill(t.frame));
  }

  /// Hanging fanous lantern with a soft glow; [top] is where the string starts.
  void _lantern(Canvas canvas, double x, double top, double len, double s) {
    canvas.save();
    canvas.translate(x, top);
    canvas.rotate(_sway(x * 0.03, 0.07));
    canvas.translate(-x, -top);
    _lanternShape(canvas, x, top, len, s);
    canvas.restore();
  }

  void _lanternShape(Canvas canvas, double x, double top, double len, double s) {
    canvas.drawLine(Offset(x, top), Offset(x, top + len), _stroke(1 * s));
    canvas.save();
    canvas.translate(x, top + len);
    canvas.scale(s);
    canvas.drawCircle(
      const Offset(0, 20),
      30,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x8CFFD27A), Color(0x00FFD27A)])
            .createShader(Rect.fromCircle(center: const Offset(0, 20), radius: 30)),
    );
    final f = _fill(t.frame);
    canvas.drawPath(Path()..moveTo(-5, 4)..lineTo(0, -3)..lineTo(5, 4)..close(), f);
    canvas.drawRect(const Rect.fromLTWH(-8, 4, 16, 3), f);
    canvas.drawPath(
        Path()..moveTo(-7, 7)..lineTo(-11, 18)..lineTo(-7, 30)..lineTo(7, 30)..lineTo(11, 18)..lineTo(7, 7)..close(), f);
    canvas.drawPath(
        Path()..moveTo(-4, 10)..lineTo(-7, 18)..lineTo(-4, 27)..lineTo(4, 27)..lineTo(7, 18)..lineTo(4, 10)..close(),
        _fill(const Color(0xFFFFE7A3)));
    canvas.drawRect(const Rect.fromLTWH(-0.8, 9, 1.6, 19), f);
    canvas.drawRect(const Rect.fromLTWH(-8, 30, 16, 3), f);
    canvas.drawPath(Path()..moveTo(-4, 33)..lineTo(0, 40)..lineTo(4, 33)..close(), f);
    canvas.restore();
  }

  void _rose(Canvas canvas, Offset c, double r, Color petal, Color edge) {
    canvas.drawCircle(c, r, _fill(petal));
    for (var k = 0; k < 3; k++) {
      canvas.drawArc(
        Rect.fromCircle(center: c + Offset((k - 1) * r * 0.12, (k - 1) * r * 0.1), radius: r * (0.75 - k * 0.22)),
        math.pi * (0.2 + k * 0.5),
        math.pi * 1.2,
        false,
        _stroke(1, edge),
      );
    }
  }

  void _dove(Canvas canvas, Offset c, double dir, double s) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.scale(dir * s, s);
    final white = _fill(Colors.white);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 26, height: 14), white);
    canvas.drawCircle(const Offset(11, -6), 4.5, white);
    canvas.drawPath(Path()..moveTo(15, -6)..lineTo(20, -5)..lineTo(15, -4)..close(), _fill(const Color(0xFFE0A030)));
    canvas.drawPath(
        Path()
          ..moveTo(-2, -4)
          ..quadraticBezierTo(-8, -22, 8, -26)
          ..quadraticBezierTo(2, -12, 6, -4)
          ..close(),
        white);
    canvas.drawPath(Path()..moveTo(-12, 0)..lineTo(-22, -4)..lineTo(-21, 4)..close(), white);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 26, height: 14), _stroke(0.8, const Color(0x2E000000)));
    canvas.drawCircle(const Offset(12, -7), 1, _fill(const Color(0xFF333333)));
    canvas.restore();
  }

  void _weddingBell(Canvas canvas, Offset c, double s, double rot) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(rot + _sway(c.dx * 0.05, 0.12));
    canvas.scale(s);
    canvas.drawPath(
        Path()
          ..moveTo(-14, 26)
          ..quadraticBezierTo(-14, 0, 0, 0)
          ..quadraticBezierTo(14, 0, 14, 26)
          ..lineTo(18, 31)
          ..lineTo(-18, 31)
          ..close(),
        _fill(t.frame));
    canvas.drawPath(Path()..moveTo(-8, 8)..quadraticBezierTo(-8, 4, 0, 4), _stroke(2, const Color(0x80FFFFFF)));
    canvas.drawCircle(const Offset(0, 35), 4, _fill(t.frame));
    canvas.restore();
  }

  void _mehrab(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRect(Rect.fromLTRB(14 * s, 14 * s, w - 14 * s, h - 14 * s), _stroke(1.4 * s));
    canvas.drawRect(Rect.fromLTRB(20 * s, 20 * s, w - 20 * s, h - 20 * s), _stroke(0.7 * s));
    for (var y = 60 * s; y < h - 40 * s; y += 18 * s) {
      _diamond(canvas, Offset(27 * s, y), 2.8 * s, _fill(t.frame));
      _diamond(canvas, Offset(w - 27 * s, y), 2.8 * s, _fill(t.frame));
    }
    final outer = _pointedArch(36 * s, w - 36 * s, h - 28 * s, 250 * s, 78 * s, s);
    canvas.drawPath(outer, _fill(Colors.white.withAlpha(16)));
    canvas.drawPath(outer, _stroke(2.4 * s));
    canvas.drawPath(_pointedArch(44 * s, w - 44 * s, h - 36 * s, 254 * s, 92 * s, s), _stroke(1 * s));
    _crescent(canvas, Offset(cx, 50 * s), 13 * s, t.background.first);
    _lantern(canvas, cx - 74 * s, 112 * s, 14 * s, 0.85 * s);
    _lantern(canvas, cx + 74 * s, 112 * s, 14 * s, 0.85 * s);
    canvas.drawLine(Offset(50 * s, h - 74 * s), Offset(w - 50 * s, h - 74 * s), _stroke(0.8 * s));
    for (var x = 62 * s; x <= w - 60 * s; x += 26 * s) {
      _star8(canvas, Offset(x, h - 56 * s), 6 * s);
    }
  }

  void _lanternsLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(14 * s, 14 * s, w - 14 * s, h - 14 * s), Radius.circular(10 * s)),
        _stroke(1.2 * s));
    const hangs = [(52.0, 40.0, 1.1), (116.0, 82.0, 0.95), (180.0, 58.0, 1.1), (244.0, 92.0, 0.95), (308.0, 46.0, 1.1)];
    for (final (x, len, sc) in hangs) {
      _lantern(canvas, x * s, 0, len * s, sc * s);
    }
    for (final (x, y) in const [(86.0, 120.0), (150.0, 26.0), (214.0, 132.0), (280.0, 24.0), (330.0, 120.0), (30.0, 110.0)]) {
      _sparkle(canvas, Offset(x * s, y * s), 4.5 * s);
    }
    // Mosque silhouette at the bottom.
    final m = _fill(t.frame.withAlpha(218));
    final base = h - 40 * s;
    canvas.drawRect(Rect.fromLTRB(110 * s, base - 50 * s, 250 * s, base), m);
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, base - 50 * s), width: 84 * s, height: 80 * s), math.pi, math.pi, true, m);
    canvas.drawRect(Rect.fromLTWH(cx - 2 * s, base - 100 * s, 4 * s, 12 * s), m);
    _crescent(canvas, Offset(cx, base - 104 * s), 5 * s, t.background.last);
    for (final x in [128.0, 232.0]) {
      canvas.drawArc(Rect.fromCenter(center: Offset(x * s, base - 40 * s), width: 36 * s, height: 32 * s), math.pi, math.pi,
          true, m);
    }
    for (final x in [84.0, 276.0]) {
      canvas.drawRect(Rect.fromLTRB((x - 6) * s, base - 114 * s, (x + 6) * s, base), m);
      canvas.drawArc(Rect.fromCenter(center: Offset(x * s, base - 114 * s), width: 16 * s, height: 20 * s), math.pi,
          math.pi, true, m);
      canvas.drawRect(Rect.fromLTRB((x - 9) * s, base - 80 * s, (x + 9) * s, base - 77 * s), m);
    }
    for (var x = 150.0; x <= 210; x += 20) {
      canvas.drawPath(
          Path()
            ..moveTo((x - 6) * s, base)
            ..lineTo((x - 6) * s, base - 16 * s)
            ..arcToPoint(Offset((x + 6) * s, base - 16 * s), radius: Radius.circular(6 * s))
            ..lineTo((x + 6) * s, base)
            ..close(),
          _fill(t.background.last));
    }
    canvas.drawRect(Rect.fromLTRB(30 * s, base, w - 30 * s, base + 3 * s), _fill(t.frame));
  }

  void _chapel(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRect(Rect.fromLTRB(16 * s, 16 * s, w - 16 * s, h - 16 * s), _stroke(1.2 * s));
    final outer = _pointedArch(40 * s, w - 40 * s, h - 28 * s, 240 * s, 74 * s, s, k1: 0.6, k2: 0.02, k3: 0.05);
    canvas.drawPath(outer, _fill(Colors.white.withAlpha(18)));
    canvas.drawPath(outer, _stroke(2.4 * s));
    canvas.drawPath(_pointedArch(48 * s, w - 48 * s, h - 36 * s, 244 * s, 88 * s, s, k1: 0.6, k2: 0.02, k3: 0.05),
        _stroke(1 * s));
    // Cross above the window.
    canvas.drawRect(Rect.fromLTWH(cx - 2.5 * s, 22 * s, 5 * s, 34 * s), _fill(t.frame));
    canvas.drawRect(Rect.fromLTWH(cx - 11 * s, 31 * s, 22 * s, 5 * s), _fill(t.frame));
    // Rose (stained-glass) window.
    const glass = [Color(0x8C5B8DB8), Color(0x8CE8B04A), Color(0x73C2185B), Color(0x734CAF50)];
    final rc = Offset(cx, 116 * s);
    for (var k = 0; k < 8; k++) {
      canvas.drawArc(Rect.fromCircle(center: rc, radius: 20 * s), k * math.pi / 4, math.pi / 4, true, _fill(glass[k % 4]));
    }
    canvas.drawCircle(rc, 20 * s, _stroke(1 * s));
    canvas.drawCircle(rc, 6 * s, _fill(t.frame));
    // Roses in the bottom corners, doves in the middle.
    for (final (x, dir) in [(56.0, 1.0), (304.0, -1.0)]) {
      _leaf(canvas, Offset((x + dir * 6) * s, h - 42 * s), 28 * s, 8 * s, angle: -math.pi / 2 - dir * 0.6);
      _leaf(canvas, Offset((x + dir * 22) * s, h - 36 * s), 24 * s, 7 * s, angle: -math.pi / 2 - dir * 1.1);
      _rose(canvas, Offset(x * s, h - 52 * s), 13 * s, Colors.white, t.frame);
      _rose(canvas, Offset((x + dir * 22) * s, h - 62 * s), 10 * s, const Color(0xFFF6C9CF), const Color(0xFFC77B8A));
      _rose(canvas, Offset((x + dir * 6) * s, h - 76 * s), 8 * s, Colors.white, t.frame);
    }
    _dove(canvas, Offset(cx - 26 * s, h - 72 * s), 1, 1.1 * s);
    _dove(canvas, Offset(cx + 26 * s, h - 72 * s), -1, 1.1 * s);
  }

  void _bellsLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(14 * s, 14 * s, w - 14 * s, h - 14 * s), Radius.circular(14 * s)),
        _stroke(1.2 * s));
    // Garland of jasmine and blush roses from the corners to the bells.
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i <= 12; i++) {
        final u = i / 12;
        final p = Offset(cx + side * (28 + 122 * u) * s, (40 + math.sin(u * math.pi) * 26 + u * 10) * s);
        if (i.isOdd) {
          _rose(canvas, p, 4.6 * s, const Color(0xFFF6C9CF), const Color(0xFFC77B8A));
        } else {
          canvas.drawCircle(p, 3.2 * s, _fill(Colors.white));
        }
      }
    }
    _weddingBell(canvas, Offset(cx - 12 * s, 34 * s), s, 0.28);
    _weddingBell(canvas, Offset(cx + 12 * s, 34 * s), s, -0.28);
    final ribbon = _fill(t.accent);
    for (final sd in [-1.0, 1.0]) {
      canvas.drawPath(
          Path()
            ..moveTo(cx, 30 * s)
            ..quadraticBezierTo(cx + sd * 18 * s, 14 * s, cx + sd * 20 * s, 30 * s)
            ..quadraticBezierTo(cx + sd * 10 * s, 34 * s, cx, 30 * s)
            ..close(),
          ribbon);
      canvas.drawPath(
          Path()
            ..moveTo(cx, 30 * s)
            ..lineTo(cx + sd * 10 * s, 58 * s)
            ..lineTo(cx + sd * 5 * s, 58 * s)
            ..close(),
          ribbon);
    }
    canvas.drawCircle(Offset(cx, 30 * s), 4 * s, ribbon);
    // Rose border along the bottom and a small cross above it.
    var i = 0;
    for (var x = 34.0; x <= 326; x += 24, i++) {
      _leaf(canvas, Offset((x - 8) * s, h - 28 * s), 16 * s, 5 * s, angle: -math.pi / 2 - 0.7);
      _leaf(canvas, Offset((x + 8) * s, h - 28 * s), 16 * s, 5 * s, angle: -math.pi / 2 + 0.7);
      if (i.isOdd) {
        _rose(canvas, Offset(x * s, h - 36 * s), 7 * s, const Color(0xFFF6C9CF), const Color(0xFFC77B8A));
      } else {
        _rose(canvas, Offset(x * s, h - 36 * s), 9 * s, Colors.white, t.frame);
      }
    }
    canvas.drawRect(Rect.fromLTWH(cx - 1.5 * s, h - 92 * s, 3 * s, 22 * s), _fill(t.frame));
    canvas.drawRect(Rect.fromLTWH(cx - 7 * s, h - 86 * s, 14 * s, 3 * s), _fill(t.frame));
  }

  // --------------------------------------------------------------- garland --

  void _garlandLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(14 * s, 14 * s, w - 14 * s, h - 14 * s), Radius.circular(14 * s)),
        _stroke(1.6 * s));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(20 * s, 20 * s, w - 20 * s, h - 20 * s), Radius.circular(10 * s)),
        _stroke(0.8 * s));

    // Three marigold swags across the top, with leaf tassels at the joins.
    final pts = [24 * s, w / 3, 2 * w / 3, w - 24 * s];
    final y = 26 * s;
    for (var i = 0; i < 3; i++) {
      const n = 9;
      for (var k = 0; k <= n; k++) {
        final u = k / n;
        _marigold(canvas, Offset(pts[i] + (pts[i + 1] - pts[i]) * u, y + math.sin(u * math.pi) * 34 * s), 6 * s);
      }
    }
    for (final p in pts) {
      _leaf(canvas, Offset(p, y), 30 * s, 8 * s);
      _leaf(canvas, Offset(p - 6 * s, y), 24 * s, 6 * s, angle: math.pi / 2 + 0.5);
      _leaf(canvas, Offset(p + 6 * s, y), 24 * s, 6 * s, angle: math.pi / 2 - 0.5);
      _marigold(canvas, Offset(p, y - 2 * s), 8 * s);
    }
    // Row of upright mango leaves along the bottom.
    for (var x = 34 * s; x < w - 30 * s; x += 18 * s) {
      _leaf(canvas, Offset(x, h - 24 * s), 22 * s, 6 * s, angle: -math.pi / 2);
    }
  }

  // --------------------------------------------------------------- gopuram --

  void _gopuram(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRect(Rect.fromLTRB(12 * s, 12 * s, w - 12 * s, h - 12 * s), _stroke(2.2 * s));
    canvas.drawRect(Rect.fromLTRB(18 * s, 18 * s, w - 18 * s, h - 18 * s), _stroke(0.9 * s));

    // Stacked temple tower tiers with little windows.
    const tiers = [(150.0, 94.0), (118.0, 74.0), (88.0, 56.0), (60.0, 40.0)];
    var y = 118 * s;
    for (final (wb, wt) in tiers) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - wb / 2 * s, y)
          ..lineTo(cx + wb / 2 * s, y)
          ..lineTo(cx + wt / 2 * s, y - 16 * s)
          ..lineTo(cx - wt / 2 * s, y - 16 * s)
          ..close(),
        _fill(t.frame),
      );
      for (var k = -1; k <= 1; k++) {
        canvas.drawRect(Rect.fromLTWH(cx + k * wt / 3 * s - 2 * s, y - 11 * s, 4 * s, 7 * s), _fill(t.background.first));
      }
      y -= 18 * s;
    }
    // Dome + finial.
    // (after the loop, the top tier's upper edge is at y + 2)
    canvas.drawArc(Rect.fromCenter(center: Offset(cx, y + 2 * s), width: 44 * s, height: 16 * s), math.pi, math.pi,
        true, _fill(t.frame));
    _kalasam(canvas, Offset(cx, y - 30 * s), s * 0.4);
    canvas.drawLine(Offset(30 * s, 120 * s), Offset(w - 30 * s, 120 * s), _stroke(1 * s));

    // Marigold strings down both sides.
    for (final x in [30 * s, w - 30 * s]) {
      for (var yy = 140 * s; yy < h - 40 * s; yy += 24 * s) {
        _marigold(canvas, Offset(x, yy), 4.5 * s);
      }
    }
  }

  // ---------------------------------------------------------------- deepam --

  void _diya(Canvas canvas, Offset c, double s) {
    final bowl = Path()
      ..moveTo(c.dx - 22 * s, c.dy)
      ..quadraticBezierTo(c.dx, c.dy + 22 * s, c.dx + 22 * s, c.dy)
      ..quadraticBezierTo(c.dx + 26 * s, c.dy - 3 * s, c.dx + 30 * s, c.dy - 6 * s)
      ..lineTo(c.dx + 20 * s, c.dy - 2 * s)
      ..close();
    canvas.drawPath(bowl, _fill(t.frame));
    canvas.drawOval(Rect.fromCenter(center: c, width: 44 * s, height: 8 * s), _fill(t.marigoldCenter));
    Path flame(double height, double width) {
      final fy = c.dy - 6 * s;
      return Path()
        ..moveTo(c.dx, fy - height)
        ..quadraticBezierTo(c.dx + width, fy - height * 0.27, c.dx, fy)
        ..quadraticBezierTo(c.dx - width, fy - height * 0.27, c.dx, fy - height)
        ..close();
    }

    final f = _flick(c.dx * 0.1);
    if (_live) _glow(canvas, c - Offset(0, 16 * s), (24 + 40 * (f - 1)) * s);
    canvas.drawPath(flame(22 * s * f, 9 * s), _fill(const Color(0xFFFFB703)));
    canvas.drawPath(flame(14 * s * _flick(c.dx * 0.1 + 1.3), 4.5 * s), _fill(const Color(0xFFFFF3B0)));
  }

  void _deepamLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height;
    _mandala(canvas, Offset(w / 2, 0), 120 * s, t.frame.withAlpha(176)); // half mandala at the top
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(14 * s, 14 * s, w - 14 * s, h - 14 * s), Radius.circular(10 * s)),
        _stroke(1.2 * s));
    for (final dx in [-70.0, 0.0, 70.0]) {
      _diya(canvas, Offset(w / 2 + dx * s, h - 58 * s), s * (dx == 0 ? 1 : 0.8));
    }
    for (var x = 40 * s; x < w - 30 * s; x += 14 * s) {
      canvas.drawCircle(Offset(x, h - 26 * s), 1.6 * s, _fill(t.frame));
    }
  }

  // ---------------------------------------------------------------- wreath --

  void _wreath(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height, cx = w / 2;
    canvas.drawRect(Rect.fromLTRB(22 * s, 22 * s, w - 22 * s, h - 22 * s), _stroke(1 * s));
    // Gold L-brackets in the corners.
    final bracket = _stroke(3 * s);
    for (final (x, y, dx, dy) in [(22.0, 22.0, 1.0, 1.0), (338.0, 22.0, -1.0, 1.0), (22.0, 618.0, 1.0, -1.0), (338.0, 618.0, -1.0, -1.0)]) {
      final c = Offset(x * s, y * s);
      canvas.drawLine(c, c + Offset(26 * dx * s, 0), bracket);
      canvas.drawLine(c, c + Offset(0, 26 * dy * s), bracket);
    }
    // Marigold wreath with a lotus inside.
    final wc = Offset(cx, 70 * s);
    final spin = _live ? _tt * 0.25 : 0.0;
    for (var i = 0; i < 16; i++) {
      final a = 2 * math.pi * i / 16 + spin;
      _leaf(canvas, wc + Offset(math.cos(a), math.sin(a)) * (34 * s), 14 * s, 4 * s, angle: a + math.pi / 2 + 0.6);
    }
    for (var i = 0; i < 12; i++) {
      final a = 2 * math.pi * i / 12 + spin;
      _marigold(canvas, wc + Offset(math.cos(a), math.sin(a)) * (34 * s), 6 * s);
    }
    _lotus(canvas, wc + Offset(0, 12 * s), s * 0.9, withLines: false);
    // Bottom rule.
    canvas.drawLine(Offset(cx - 70 * s, h - 48 * s), Offset(cx + 70 * s, h - 48 * s), _stroke(1 * s));
    _diamond(canvas, Offset(cx, h - 48 * s), 5 * s, _fill(t.frame));
  }

  // ---------------------------------------------------------------- shared --

  Paint _stroke(double w, [Color? c]) => Paint()
    ..color = c ?? t.frame
    ..style = PaintingStyle.stroke
    ..strokeWidth = w;

  Paint _fill(Color c) => Paint()..color = c;

  void _leaf(Canvas canvas, Offset base, double length, double width, {double angle = math.pi / 2}) {
    // Leaf from [base] towards [angle] (π/2 = straight down).
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(angle - math.pi / 2 + _sway(base.dx * 0.07 + base.dy * 0.05, 0.09));
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width, length * 0.45, 0, length)
      ..quadraticBezierTo(-width, length * 0.45, 0, 0)
      ..close();
    canvas.drawPath(path, _fill(t.leaf));
    canvas.drawLine(Offset.zero, Offset(0, length), _stroke(0.8, Colors.white.withAlpha(90)));
    canvas.restore();
  }

  void _marigold(Canvas canvas, Offset c, double r) {
    const petals = 10;
    for (var i = 0; i < petals; i++) {
      final a = 2 * math.pi * i / petals + (_live ? _tt * 0.9 + c.dx * 0.02 : 0);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r * 0.62), r * 0.48, _fill(t.marigold));
    }
    canvas.drawCircle(c, r * 0.5, _fill(t.marigoldCenter));
  }

  void _diamond(Canvas canvas, Offset c, double r, Paint p) {
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - r)
        ..lineTo(c.dx + r, c.dy)
        ..lineTo(c.dx, c.dy + r)
        ..lineTo(c.dx - r, c.dy)
        ..close(),
      p,
    );
  }

  void _lotus(Canvas canvas, Offset base, double s, {bool withLines = true}) {
    final p = _fill(t.frame.withAlpha(220));
    const petals = 7;
    for (var i = 0; i < petals; i++) {
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate((i - (petals - 1) / 2) * 0.32);
      canvas.drawOval(Rect.fromCenter(center: Offset(0, -9 * s), width: 6.5 * s, height: 18 * s), p);
      canvas.restore();
    }
    if (withLines) {
      canvas.drawLine(base + Offset(-60 * s, 3 * s), base + Offset(-16 * s, 3 * s), _stroke(1 * s));
      canvas.drawLine(base + Offset(16 * s, 3 * s), base + Offset(60 * s, 3 * s), _stroke(1 * s));
    }
  }

  /// Purna kalasam: pot, mango leaves and coconut. [top] = top of coconut.
  void _kalasam(Canvas canvas, Offset top, double s) {
    final cx = top.dx;
    final coconutC = Offset(cx, top.dy + 9 * s);
    final rimY = top.dy + 20 * s;
    // Mango leaves fanning out behind the coconut.
    for (var i = -2; i <= 2; i++) {
      _leaf(canvas, Offset(cx, rimY), 22 * s, 6 * s, angle: -math.pi / 2 + i * 0.42);
    }
    canvas.drawCircle(coconutC, 9 * s, _fill(const Color(0xFF8D5524)));
    canvas.drawCircle(coconutC + Offset(-2.5 * s, -3 * s), 2.5 * s, _fill(const Color(0x55FFFFFF)));
    // Rim, neck, body.
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, rimY), width: 30 * s, height: 7 * s), _fill(t.frame));
    canvas.drawRect(Rect.fromLTWH(cx - 8 * s, rimY, 16 * s, 7 * s), _fill(t.frame));
    final bodyC = Offset(cx, rimY + 24 * s);
    canvas.drawCircle(bodyC, 19 * s, _fill(t.frame));
    // Decorative band + kumkum dot.
    canvas.drawLine(bodyC + Offset(-18 * s, -4 * s), bodyC + Offset(18 * s, -4 * s), _stroke(2 * s, t.marigold));
    canvas.drawCircle(bodyC + Offset(0, 5 * s), 3 * s, _fill(t.marigoldCenter));
    // Base.
    canvas.drawOval(Rect.fromCenter(center: bodyC + Offset(0, 19 * s), width: 26 * s, height: 5 * s), _fill(t.frame));
  }

  void _mandala(Canvas canvas, Offset c, double r, Color color) {
    canvas.save();
    if (_live) {
      // Turns slowly in place.
      canvas.translate(c.dx, c.dy);
      canvas.rotate(_tt * 0.12);
      canvas.translate(-c.dx, -c.dy);
    }
    _mandalaShape(canvas, c, r, color);
    canvas.restore();
  }

  void _mandalaShape(Canvas canvas, Offset c, double r, Color color) {
    final line = _stroke(1.1 * r / 100, color);
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * 0.82, line);
    canvas.drawCircle(c, r * 0.5, line);
    canvas.drawCircle(c, r * 0.18, _fill(color));
    for (var ring = 0; ring < 2; ring++) {
      final count = ring == 0 ? 16 : 8;
      final dist = ring == 0 ? r * 0.66 : r * 0.34;
      final len = ring == 0 ? r * 0.3 : r * 0.28;
      for (var i = 0; i < count; i++) {
        final a = 2 * math.pi * i / count + (ring == 1 ? math.pi / 8 : 0);
        canvas.save();
        canvas.translate(c.dx + math.cos(a) * dist, c.dy + math.sin(a) * dist);
        canvas.rotate(a + math.pi / 2);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: len * 0.42, height: len), line);
        canvas.restore();
      }
    }
    for (var i = 0; i < 32; i++) {
      final a = 2 * math.pi * i / 32;
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * (r * 0.91), r * 0.025, _fill(color));
    }
  }

  // ----------------------------------------------------------------- toran --

  void _doubleFrame(Canvas canvas, Size size, double s) {
    final outer = Rect.fromLTRB(12 * s, 12 * s, size.width - 12 * s, size.height - 12 * s);
    canvas.drawRect(outer, _stroke(2.2 * s));
    canvas.drawRect(outer.deflate(6 * s), _stroke(0.9 * s));
    for (final c in [outer.topLeft, outer.topRight, outer.bottomLeft, outer.bottomRight]) {
      _diamond(canvas, c, 9 * s, _fill(t.frame));
      canvas.drawCircle(c, 3 * s, _fill(t.background.first));
    }
  }

  void _toran(Canvas canvas, Size size, double s) {
    final left = 20 * s, right = size.width - 20 * s, top = 22 * s;
    const items = 13;
    double ropeY(double x) => top + math.sin((x - left) / (right - left) * math.pi) * 6 * s;

    final ropePath = Path()..moveTo(left, ropeY(left));
    for (var x = left; x <= right; x += 4 * s) {
      ropePath.lineTo(x, ropeY(x));
    }
    canvas.drawPath(ropePath, _stroke(2 * s));

    for (var i = 0; i < items; i++) {
      final x = left + (right - left) * (i + 0.5) / items;
      final y = ropeY(x);
      if (i.isEven) {
        final mid = 1 - ((i - (items - 1) / 2).abs() / items);
        _leaf(canvas, Offset(x, y), (34 + 16 * mid) * s, 11 * s);
      } else {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(_sway(x * 0.05, 0.1));
        canvas.translate(-x, -y);
        final stringEnd = Offset(x, y + 10 * s);
        canvas.drawLine(Offset(x, y), stringEnd, _stroke(1 * s));
        _marigold(canvas, stringEnd + Offset(0, 7 * s), 7.5 * s);
        _marigold(canvas, stringEnd + Offset(0, 22 * s), 5.5 * s);
        canvas.restore();
      }
    }
  }

  // ---------------------------------------------------------------- temple --

  Path _archPath(double l, double r, double bottom, double shoulder, double apex) {
    final cx = (l + r) / 2;
    final w = r - l;
    return Path()
      ..moveTo(l, bottom)
      ..lineTo(l, shoulder)
      ..cubicTo(l, shoulder - (shoulder - apex) * 0.75, cx - w * 0.12, apex + (shoulder - apex) * 0.2, cx, apex)
      ..cubicTo(cx + w * 0.12, apex + (shoulder - apex) * 0.2, r, shoulder - (shoulder - apex) * 0.75, r, shoulder)
      ..lineTo(r, bottom)
      ..close();
  }

  void _templeArch(Canvas canvas, Size size, double s) {
    final l = 20 * s, r = size.width - 20 * s, bottom = size.height - 20 * s;
    final shoulder = 165 * s, apex = 62 * s;
    final outer = _archPath(l, r, bottom, shoulder, apex);
    final inner = _archPath(l + 8 * s, r - 8 * s, bottom - 8 * s, shoulder + 4 * s, apex + 10 * s);
    canvas.drawPath(inner, _fill(Colors.white.withAlpha(14)));
    canvas.drawPath(outer, _stroke(2.6 * s));
    canvas.drawPath(inner, _stroke(1 * s));

    // Pillar capitals with hanging bells.
    for (final x in [l, r]) {
      canvas.drawRect(Rect.fromCenter(center: Offset(x, shoulder), width: 18 * s, height: 7 * s), _fill(t.frame));
      final bx = x == l ? x + 20 * s : x - 20 * s;
      canvas.drawLine(Offset(bx, shoulder - 6 * s), Offset(bx, shoulder + 16 * s), _stroke(1 * s));
      final bell = Path()
        ..moveTo(bx - 6 * s, shoulder + 30 * s)
        ..quadraticBezierTo(bx - 6 * s, shoulder + 16 * s, bx, shoulder + 16 * s)
        ..quadraticBezierTo(bx + 6 * s, shoulder + 16 * s, bx + 6 * s, shoulder + 30 * s)
        ..close();
      canvas.drawPath(bell, _fill(t.frame));
      canvas.drawCircle(Offset(bx, shoulder + 32 * s), 2 * s, _fill(t.frame));
    }

    // Kalasam finial on the apex.
    _kalasam(canvas, Offset(size.width / 2, apex - 56 * s), s * 0.8);

    // Marigold strings down both pillars.
    for (final x in [l + 4 * s, r - 4 * s]) {
      for (var y = shoulder + 50 * s; y < bottom - 40 * s; y += 26 * s) {
        _marigold(canvas, Offset(x, y), 4.5 * s);
      }
    }

    // Temple-step (zigzag) band at the bottom.
    final zig = Path()..moveTo(l + 10 * s, bottom - 18 * s);
    var up = true;
    for (var x = l + 10 * s; x < r - 10 * s; x += 10 * s) {
      zig.lineTo(x + 5 * s, bottom - (up ? 26 : 18) * s);
      up = !up;
    }
    canvas.drawPath(zig, _stroke(1.2 * s));
  }

  // --------------------------------------------------------------- kalasam --

  void _kalasamLayout(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    // Mandala watermark behind the text.
    _mandala(canvas, Offset(cx, size.height * 0.55), 150 * s, t.frame.withAlpha(40));
    // Corner quarter-mandalas.
    for (final c in [Offset.zero, Offset(size.width, 0), Offset(0, size.height), Offset(size.width, size.height)]) {
      _mandala(canvas, c, 58 * s, t.frame.withAlpha(150));
    }
    // Thin single frame.
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(14 * s, 14 * s, size.width - 14 * s, size.height - 14 * s), Radius.circular(10 * s)),
      _stroke(1.2 * s),
    );
    _kalasam(canvas, Offset(cx, 20 * s), s);
    // Small marigold pairs either side of the kalasam.
    for (final dx in [-46.0, -32.0, 32.0, 46.0]) {
      _marigold(canvas, Offset(cx + dx * s, 70 * s), (dx.abs() > 40 ? 5 : 6.5) * s);
    }
  }

  // ---------------------------------------------------------------- modern --

  void _modern(Canvas canvas, Size size, double s) {
    final cx = size.width / 2;
    for (final y in [52 * s, size.height - 52 * s]) {
      canvas.drawLine(Offset(80 * s, y), Offset(cx - 14 * s, y), _stroke(1 * s));
      canvas.drawLine(Offset(cx + 14 * s, y), Offset(size.width - 80 * s, y), _stroke(1 * s));
      _diamond(canvas, Offset(cx, y), 6 * s, _fill(t.frame));
      _diamond(canvas, Offset(cx, y), 2.5 * s, _fill(t.background.first));
    }
    _spray(canvas, Offset(18 * s, 18 * s), s, 1);
    _spray(canvas, Offset(size.width - 18 * s, size.height - 18 * s), s, -1);
  }

  /// A small diagonal spray of marigolds and leaves from a corner.
  void _spray(Canvas canvas, Offset corner, double s, double dir) {
    final angle = dir > 0 ? math.pi / 4 : math.pi + math.pi / 4;
    final along = Offset(math.cos(angle), math.sin(angle));
    _leaf(canvas, corner + along * (30 * s), 26 * s, 7 * s, angle: angle - 0.9);
    _leaf(canvas, corner + along * (30 * s), 26 * s, 7 * s, angle: angle + 0.9);
    _leaf(canvas, corner + along * (52 * s), 20 * s, 6 * s, angle: angle - 0.8);
    _marigold(canvas, corner + along * (16 * s), 10 * s);
    _marigold(canvas, corner + along * (38 * s), 8 * s);
    _marigold(canvas, corner + along * (56 * s), 6 * s);
  }

  // ---------------------------------------------------------------- greetings --

  /// Sankranti: three kites with strings and bow tails, muggu dots below.
  void _kitesLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height;
    _thinFrames(canvas, size, s);
    void kite(Offset c, double r, double tilt, Color body, Color stripe) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(tilt);
      final kitePath = Path()
        ..moveTo(0, -r)
        ..lineTo(r * 0.8, 0)
        ..lineTo(0, r * 1.1)
        ..lineTo(-r * 0.8, 0)
        ..close();
      canvas.drawPath(kitePath, _fill(body));
      canvas.drawPath(
          Path()
            ..moveTo(0, -r)
            ..lineTo(r * 0.8, 0)
            ..lineTo(0, 0)
            ..close(),
          _fill(stripe));
      canvas.drawLine(Offset(0, -r), Offset(0, r * 1.1), _stroke(0.8 * s, t.frame));
      canvas.drawLine(Offset(-r * 0.8, 0), Offset(r * 0.8, 0), _stroke(0.8 * s, t.frame));
      // Tail with little bows.
      final tail = Path()..moveTo(0, r * 1.1);
      for (var i = 1; i <= 4; i++) {
        tail.quadraticBezierTo(i.isOdd ? 6 * s : -6 * s, r * 1.1 + (i - 0.5) * 9 * s, 0, r * 1.1 + i * 9 * s);
      }
      canvas.drawPath(tail, _stroke(0.9 * s, t.frame));
      for (var i = 1; i <= 3; i++) {
        final y = r * 1.1 + i * 9 * s;
        canvas.drawPath(
            Path()
              ..moveTo(0, y)
              ..lineTo(-4 * s, y - 3 * s)
              ..lineTo(-4 * s, y + 3 * s)
              ..close()
              ..moveTo(0, y)
              ..lineTo(4 * s, y - 3 * s)
              ..lineTo(4 * s, y + 3 * s)
              ..close(),
            _fill(i.isOdd ? stripe : body));
      }
      canvas.restore();
    }

    // Strings from the bottom-left, like they are being flown.
    final anchor = Offset(30 * s, h - 30 * s);
    for (final p in [Offset(78 * s, 74 * s), Offset(w / 2 + 6 * s, 52 * s), Offset(w - 74 * s, 88 * s)]) {
      canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy + 20 * s)
            ..quadraticBezierTo(p.dx - 40 * s, (p.dy + anchor.dy) / 2, anchor.dx, anchor.dy),
          _stroke(0.5 * s, t.frame.withAlpha(110)));
    }
    kite(Offset(78 * s, 74 * s), 22 * s, -0.35, t.marigold, t.accent);
    kite(Offset(w / 2 + 6 * s, 52 * s), 26 * s, 0.1, t.accent, t.marigoldCenter);
    kite(Offset(w - 74 * s, 88 * s), 20 * s, 0.4, t.leaf, t.marigold);
    // Muggu (rangoli) dot grid at the bottom with a lotus.
    final cy = h - 40 * s;
    for (var row = -2; row <= 2; row++) {
      final n = 5 - row.abs();
      for (var i = 0; i < n; i++) {
        final x = w / 2 + (i - (n - 1) / 2) * 12 * s;
        canvas.drawCircle(Offset(x, cy + row * 7 * s), 1.6 * s, _fill(t.frame));
      }
    }
    _sparkle(canvas, Offset(w * 0.32, 40 * s), 5 * s);
    _sparkle(canvas, Offset(w * 0.72, 34 * s), 4 * s);
  }

  /// Birthdays & friendship: bunting across the top, balloons in the corners,
  /// confetti.
  void _balloonsLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height;
    _thinFrames(canvas, size, s);
    final colors = [t.accent, t.marigold, t.leaf, t.marigoldCenter, t.frame];
    // Bunting.
    final sag = Path()
      ..moveTo(18 * s, 34 * s)
      ..quadraticBezierTo(w / 2, 78 * s, w - 18 * s, 34 * s);
    canvas.drawPath(sag, _stroke(0.9 * s, t.frame));
    const flags = 11;
    for (var i = 0; i < flags; i++) {
      final f = (i + 0.5) / flags;
      final x = 18 * s + f * (w - 36 * s);
      final y = 34 * s + 4 * f * (1 - f) * 22 * s;
      canvas.drawPath(
          Path()
            ..moveTo(x - 9 * s, y)
            ..lineTo(x + 9 * s, y)
            ..lineTo(x, y + 18 * s)
            ..close(),
          _fill(colors[i % colors.length]));
    }
    // Balloons.
    void balloon(Offset c, double r, Color col, Offset tie) {
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy + r * 1.15)
            ..quadraticBezierTo(c.dx + 8 * s, (c.dy + tie.dy) / 2, tie.dx, tie.dy),
          _stroke(0.6 * s, t.frame.withAlpha(150)));
      canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 2.3), _fill(col));
      canvas.drawOval(
          Rect.fromCenter(center: c + Offset(-r * 0.35, -r * 0.45), width: r * 0.45, height: r * 0.7),
          _fill(const Color(0x55FFFFFF)));
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy + r * 1.12)
            ..lineTo(c.dx - 3 * s, c.dy + r * 1.3)
            ..lineTo(c.dx + 3 * s, c.dy + r * 1.3)
            ..close(),
          _fill(col));
    }

    final tieL = Offset(44 * s, h - 22 * s), tieR = Offset(w - 44 * s, h - 22 * s);
    balloon(Offset(30 * s, h - 118 * s), 15 * s, t.accent, tieL);
    balloon(Offset(58 * s, h - 104 * s), 13 * s, t.marigold, tieL);
    balloon(Offset(40 * s, h - 82 * s), 11 * s, t.leaf, tieL);
    balloon(Offset(w - 30 * s, h - 118 * s), 15 * s, t.marigold, tieR);
    balloon(Offset(w - 58 * s, h - 104 * s), 13 * s, t.accent, tieR);
    balloon(Offset(w - 40 * s, h - 82 * s), 11 * s, t.marigoldCenter, tieR);
    // Confetti (fixed pattern, so every render looks the same).
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final p = Offset((30 + rnd.nextDouble() * 300) * s, (92 + rnd.nextDouble() * 40) * s);
      canvas.save();
      canvas.translate(p.dx, p.dy);
      canvas.rotate(rnd.nextDouble() * math.pi);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: 5 * s, height: 2.4 * s),
          _fill(colors[i % colors.length].withAlpha(200)));
      canvas.restore();
    }
  }

  /// New Year, national days, congratulations: firework bursts and sparkles.
  void _fireworksLayout(Canvas canvas, Size size, double s) {
    final w = size.width, h = size.height;
    _thinFrames(canvas, size, s);
    void burst(Offset c, double r, Color col, int rays) {
      for (var i = 0; i < rays; i++) {
        final a = 2 * math.pi * i / rays;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + dir * (r * 0.28), c + dir * (r * 0.86), _stroke(1.4 * s, col));
        canvas.drawCircle(c + dir * r, 2 * s, _fill(col));
      }
      canvas.drawCircle(c, 3 * s, _fill(col));
    }

    burst(Offset(86 * s, 74 * s), 40 * s, t.accent, 16);
    burst(Offset(w - 82 * s, 62 * s), 34 * s, t.marigold, 14);
    burst(Offset(w / 2 + 4 * s, 108 * s), 26 * s, t.marigoldCenter, 12);
    burst(Offset(52 * s, h - 66 * s), 18 * s, t.marigold, 10);
    burst(Offset(w - 54 * s, h - 76 * s), 22 * s, t.accent, 12);
    for (final p in [
      Offset(w * 0.5, 40 * s),
      Offset(w * 0.18, 140 * s),
      Offset(w * 0.84, 132 * s),
      Offset(w * 0.5, h - 40 * s),
    ]) {
      _sparkle(canvas, p, 5 * s);
    }
  }

  @override
  bool shouldRepaint(covariant CardPainter old) =>
      old.t != t || old.layout != layout || old.part != part || old.time != time;
}
