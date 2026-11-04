import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated overlays for video invitations, drawn in code (0 KB of assets).
enum VideoEffect {
  none('None', 'ఏదీ వద్దు', Icons.block),
  petals('Flower petals', 'పూల రేకులు', Icons.local_florist_outlined),
  sparkles('Sparkles', 'మెరుపులు', Icons.auto_awesome_outlined),
  confetti('Confetti', 'కాన్ఫెట్టి', Icons.celebration_outlined),
  hearts('Hearts', 'హృదయాలు', Icons.favorite_border),
  snow('Snow', 'మంచు', Icons.ac_unit),
  lights('Floating lights', 'దీపకాంతులు', Icons.blur_on),
  grain('Film grain', 'ఫిల్మ్ గ్రెయిన్', Icons.grain),
  leak('Light leak', 'లైట్ లీక్', Icons.wb_sunny_outlined),
  vignette('Vignette', 'విగ్నెట్', Icons.vignette_outlined);

  const VideoEffect(this.en, this.te, this.icon);
  final String en;
  final String te;
  final IconData icon;
}

/// Colour grading applied to the whole video.
enum VideoFilter {
  original('Original', 'అసలు'),
  warm('Warm', 'వెచ్చని'),
  golden('Golden', 'బంగారు'),
  cool('Cool', 'చల్లని'),
  vivid('Vivid', 'ప్రకాశం'),
  punch('Punch', 'పంచ్'),
  vintage('Vintage', 'పాతకాలం'),
  fade('Fade', 'ఫేడ్'),
  soft('Soft', 'మృదువు'),
  mono('B & W', 'నలుపు తెలుపు');

  const VideoFilter(this.en, this.te);
  final String en;
  final String te;

  /// 5 × 4 colour matrix for [ColorFilter.matrix].
  List<double> get matrix => switch (this) {
        VideoFilter.original => _identity,
        VideoFilter.warm => const [1.08, 0, 0, 0, 12, 0, 1.0, 0, 0, 4, 0, 0, 0.88, 0, -8, 0, 0, 0, 1, 0],
        VideoFilter.golden => _mix(_sepia, 0.35, add: const [18, 10, -6]),
        VideoFilter.cool => const [0.92, 0, 0, 0, -6, 0, 1.0, 0, 0, 2, 0, 0, 1.1, 0, 14, 0, 0, 0, 1, 0],
        VideoFilter.vivid => _saturation(1.4),
        VideoFilter.punch => _contrast(1.2, _saturation(1.25)),
        VideoFilter.fade => _contrast(0.8, const [1, 0, 0, 0, 14, 0, 1, 0, 0, 14, 0, 0, 1, 0, 18, 0, 0, 0, 1, 0]),
        VideoFilter.vintage => _mix(_sepia, 0.7, add: const [10, 4, -4]),
        VideoFilter.soft => const [0.86, 0, 0, 0, 28, 0, 0.86, 0, 0, 26, 0, 0, 0.86, 0, 30, 0, 0, 0, 1, 0],
        VideoFilter.mono => _saturation(0),
      };

  static const _identity = <double>[1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0];
  static const _sepia = <double>[
    0.393, 0.769, 0.189, 0, 0, //
    0.349, 0.686, 0.168, 0, 0, //
    0.272, 0.534, 0.131, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  static List<double> _mix(List<double> m, double amount, {List<double> add = const [0, 0, 0]}) {
    final out = [for (var i = 0; i < 20; i++) _identity[i] * (1 - amount) + m[i] * amount];
    out[4] += add[0];
    out[9] += add[1];
    out[14] += add[2];
    return out;
  }

  /// Scales contrast around mid-grey on top of [m].
  static List<double> _contrast(double c, List<double> m) {
    final t = 128 * (1 - c);
    return [
      for (var i = 0; i < 20; i++)
        (i == 0 || i == 6 || i == 12) ? m[i] * c : ((i == 4 || i == 9 || i == 14) ? m[i] + t : m[i]),
    ];
  }

  static List<double> _saturation(double s) {
    const r = 0.2126, g = 0.7152, b = 0.0722;
    return [
      (1 - s) * r + s, (1 - s) * g, (1 - s) * b, 0, 0, //
      (1 - s) * r, (1 - s) * g + s, (1 - s) * b, 0, 0, //
      (1 - s) * r, (1 - s) * g, (1 - s) * b + s, 0, 0, //
      0, 0, 0, 1, 0,
    ];
  }
}

/// Draws [effect] at time [t] seconds on the 360 × 640 video canvas.
/// Every particle's path is a pure function of t, so the preview and the
/// exported frames are identical.
class EffectPainter extends CustomPainter {
  EffectPainter(this.effect, this.t, {required this.colors});

  final VideoEffect effect;
  final double t;

  /// Design colours to tint petals / confetti so they match the card.
  final List<Color> colors;

  static final _cache = <VideoEffect, List<_P>>{};

  static List<_P> _particles(VideoEffect e) => _cache.putIfAbsent(e, () {
        final rnd = math.Random(41 + e.index * 7);
        final n = switch (e) {
          VideoEffect.none => 0,
          VideoEffect.sparkles => 26,
          VideoEffect.snow => 70,
          VideoEffect.lights => 22,
          _ => 36,
        };
        return [
          for (var i = 0; i < n; i++)
            _P(
              x: rnd.nextDouble(),
              y: rnd.nextDouble(),
              size: 0.6 + rnd.nextDouble() * 0.8,
              speed: 0.05 + rnd.nextDouble() * 0.07,
              phase: rnd.nextDouble() * math.pi * 2,
              spin: (rnd.nextDouble() - 0.5) * 4,
              colour: i,
            ),
        ];
      });

  @override
  void paint(Canvas canvas, Size size) {
    if (effect == VideoEffect.none) return;
    final w = size.width, h = size.height;
    // Whole-frame looks (no particles).
    if (effect == VideoEffect.vignette) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const RadialGradient(
            radius: 0.75,
            colors: [Color(0x00000000), Color(0x00000000), Color(0xBB000000)],
            stops: [0, 0.45, 1],
          ).createShader(Offset.zero & size),
      );
      return;
    }
    if (effect == VideoEffect.leak) {
      final x = w * (0.5 + 0.5 * math.sin(t * 0.6));
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = RadialGradient(
            center: Alignment(x / w * 2 - 1, -0.75),
            radius: 0.9,
            colors: const [Color(0x88FFB366), Color(0x33FF5E62), Color(0x00000000)],
            stops: const [0, 0.5, 1],
          ).createShader(Offset.zero & size),
      );
      return;
    }
    if (effect == VideoEffect.grain) {
      final rnd = math.Random((t * 24).floor() + 9);
      final paint = Paint();
      for (var i = 0; i < 900; i++) {
        paint.color = Colors.white.withAlpha((rnd.nextDouble() * 30).round());
        canvas.drawRect(Rect.fromLTWH(rnd.nextDouble() * w, rnd.nextDouble() * h, 1.2, 1.2), paint);
      }
      return;
    }
    final palette = colors.isEmpty ? const [Color(0xFFFFB703)] : colors;
    for (final p in _particles(effect)) {
      final colour = palette[p.colour % palette.length];
      switch (effect) {
        case VideoEffect.none || VideoEffect.grain || VideoEffect.leak || VideoEffect.vignette:
          break;
        case VideoEffect.petals || VideoEffect.confetti || VideoEffect.hearts || VideoEffect.snow:
          // Falls from the top, wrapping around, with a gentle sideways sway.
          final fall = effect == VideoEffect.snow ? p.speed * 0.8 : p.speed;
          final y = ((p.y + t * fall) % 1.12 - 0.06) * h;
          final x = (p.x * w) + math.sin(t * 1.4 + p.phase) * 14 * p.size;
          final c = Offset(x, y);
          if (effect == VideoEffect.petals) {
            _petal(canvas, c, 7 * p.size, t * p.spin + p.phase, colour);
          } else if (effect == VideoEffect.confetti) {
            canvas.save();
            canvas.translate(c.dx, c.dy);
            canvas.rotate(t * p.spin * 1.5 + p.phase);
            canvas.drawRect(
                Rect.fromCenter(center: Offset.zero, width: 7 * p.size, height: 3.4 * p.size), Paint()..color = colour);
            canvas.restore();
          } else if (effect == VideoEffect.hearts) {
            _heart(canvas, c, 7 * p.size, Color.lerp(const Color(0xFFE63E6D), colour, 0.3)!.withAlpha(215));
          } else {
            canvas.drawCircle(c, 2.2 * p.size, Paint()..color = Colors.white.withAlpha(210));
          }
        case VideoEffect.sparkles:
          // Twinkle in place.
          final a = math.pow((math.sin(t * 2.2 * (0.6 + p.size) + p.phase) + 1) / 2, 3).toDouble();
          _sparkle(canvas, Offset(p.x * w, p.y * h), 8 * p.size * (0.5 + a), const Color(0xFFFFE08A).withAlpha((a * 255).round()));
        case VideoEffect.lights:
          // Soft glowing dots drifting upwards (diya / lantern glow).
          final glow = Offset(
            p.x * w + math.sin(t * 0.8 + p.phase) * 10,
            (1.08 - ((p.y + t * p.speed * 0.7) % 1.16)) * h,
          );
          final radius = 10 * p.size;
          canvas.drawCircle(
            glow,
            radius,
            Paint()
              ..shader = RadialGradient(colors: [
                const Color(0xFFFFD58A).withAlpha(170),
                const Color(0xFFFFD58A).withAlpha(0),
              ]).createShader(Rect.fromCircle(center: glow, radius: radius)),
          );
      }
    }
  }

  void _petal(Canvas canvas, Offset c, double r, double angle, Color colour) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(angle);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 1.1, height: r * 2), Paint()..color = colour.withAlpha(230));
    canvas.drawOval(Rect.fromCenter(center: Offset(0, -r * 0.3), width: r * 0.4, height: r * 0.9),
        Paint()..color = Colors.white.withAlpha(60));
    canvas.restore();
  }

  void _heart(Canvas canvas, Offset c, double r, Color colour) {
    final p = Path()
      ..moveTo(c.dx, c.dy + r * 0.9)
      ..cubicTo(c.dx - r * 1.6, c.dy - r * 0.2, c.dx - r * 0.6, c.dy - r * 1.3, c.dx, c.dy - r * 0.4)
      ..cubicTo(c.dx + r * 0.6, c.dy - r * 1.3, c.dx + r * 1.6, c.dy - r * 0.2, c.dx, c.dy + r * 0.9)
      ..close();
    canvas.drawPath(p, Paint()..color = colour);
  }

  void _sparkle(Canvas canvas, Offset c, double r, Color colour) {
    final p = Path();
    for (var k = 0; k < 8; k++) {
      final rad = k.isOdd ? r * 0.28 : r;
      final a = k * math.pi / 4;
      final pt = c + Offset(math.cos(a), math.sin(a)) * rad;
      if (k == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(p..close(), Paint()..color = colour);
  }

  @override
  bool shouldRepaint(covariant EffectPainter old) => old.t != t || old.effect != effect || old.colors != colors;
}

class _P {
  const _P({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.spin,
    required this.colour,
  });
  final double x, y, size, speed, phase, spin;
  final int colour;
}
