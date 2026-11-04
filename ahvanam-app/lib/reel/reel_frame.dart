import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../templates/card_template.dart';
import '../video/effects.dart';
import '../widgets/invitation_card.dart';
import '../wording/card_text.dart';
import '../models/ceremony.dart';
import '../video/native_media.dart';
import 'card_story.dart';
import 'photo_shapes.dart';
import 'reel_project.dart';

const double kReelW = 360;
const double kReelH = 640;

double _clamp(double x, [double a = 0, double b = 1]) => x < a ? a : (x > b ? b : x);
double _ease(double x) => 1 - math.pow(1 - x, 3).toDouble();

/// Photos of a reel decoded once (at most 1280 px), shared by the preview,
/// the timeline thumbnails and the export.
class ReelImages extends ChangeNotifier {
  final _images = <String, ui.Image>{};
  final _loading = <String>{};
  final _failed = <String>{};

  ui.Image? operator [](String? path) => path == null ? null : _images[path];

  bool failed(String? path) => path != null && _failed.contains(path);

  final _faces = <String, FaceSpot?>{};

  /// Where the face is in photo [path] (null if none or not looked at yet).
  FaceSpot? face(String? path) => path == null ? null : _faces[path];

  /// Looks for the face in [path] once; listeners hear when done.
  Future<void> ensureFace(String? path) async {
    if (path == null || _faces.containsKey(path)) return;
    _faces[path] = null;
    final f = await NativeMedia.findFace(path);
    if (f == null) return;
    _faces[path] = f;
    notifyListeners();
  }

  /// Starts decoding [path] if needed; listeners hear when it is ready.
  Future<void> ensure(String? path) async {
    if (path == null || _images.containsKey(path) || _failed.contains(path) || !_loading.add(path)) return;
    try {
      final bytes = await File(path).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final desc = await ui.ImageDescriptor.encoded(buffer);
      // One side only, so the photo keeps its shape (also when EXIF rotates it).
      final codec = desc.width >= desc.height
          ? await desc.instantiateCodec(targetWidth: math.min(desc.width, 1280))
          : await desc.instantiateCodec(targetHeight: math.min(desc.height, 1280));
      final frame = await codec.getNextFrame();
      _images[path] = frame.image;
      codec.dispose();
      desc.dispose();
      buffer.dispose();
    } catch (e) {
      debugPrint('ReelImages: $e');
      _failed.add(path);
    } finally {
      _loading.remove(path);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final i in _images.values) {
      i.dispose();
    }
    _images.clear();
    super.dispose();
  }
}

/// Fonts used for names and text on the reel.
TextStyle reelFont(ReelTextStyle s, {double? size, Color color = Colors.white, List<Shadow>? shadows}) {
  final base = TextStyle(color: color, shadows: shadows, height: 1.15);
  return switch (s) {
    ReelTextStyle.script => GoogleFonts.getFont('Great Vibes', textStyle: base, fontSize: size ?? 36),
    ReelTextStyle.classic =>
      GoogleFonts.getFont('Cinzel', textStyle: base, fontSize: size ?? 24, fontWeight: FontWeight.w600),
    ReelTextStyle.bold =>
      GoogleFonts.getFont('Plus Jakarta Sans', textStyle: base, fontSize: size ?? 26, fontWeight: FontWeight.w800),
    ReelTextStyle.telugu => GoogleFonts.getFont('Ramabhadra', textStyle: base, fontSize: size ?? 30),
    ReelTextStyle.neon =>
      GoogleFonts.getFont('Plus Jakarta Sans', textStyle: base, fontSize: size ?? 24, fontWeight: FontWeight.w800),
  };
}

/// Default colour of a name caption in each style.
Color captionColor(ReelTextStyle s) => switch (s) {
      ReelTextStyle.classic || ReelTextStyle.telugu => const Color(0xFFFFE6A8),
      ReelTextStyle.neon => const Color(0xFFFF8FB1),
      _ => Colors.white,
    };

/// One frame of the reel at time [t], on the 360 × 640 canvas.
///
/// The same widget is shown in the editor and captured for the MP4, so what
/// the user sees is what they get. Everything is a pure function of [t].
class ReelFrame extends StatelessWidget {
  const ReelFrame({
    super.key,
    required this.project,
    required this.t,
    required this.faces,
    required this.template,
    required this.layout,
    required this.images,
    required this.video,
    this.deity = Deity.none,
    this.deityArtPath,
    this.storyInfo = const StoryInfo(),
    this.defaultPhotos = const {},
  });

  /// Photos chosen on the details page (a clip's own photos replace them).
  final Map<String, String> defaultPhotos;

  /// Names, surname and tradition for story cards.
  final StoryInfo storyInfo;

  /// The god chosen on the details page, shown at the start of story cards.
  final Deity deity;

  /// Ahvanam's downloaded picture of that god (null = drawn symbol).
  final String? deityArtPath;

  final ReelProject project;
  final double t;
  final List<CardText> faces;
  final CardTemplate template;
  final CardLayout layout;
  final ReelImages images;

  /// Draws a video clip at [local] seconds into it (texture while editing,
  /// exact decoded frames while exporting).
  final Widget Function(ReelClip clip, double local) video;

  @override
  Widget build(BuildContext context) {
    final p = project;
    final lay = p.timeline;
    Widget base = const ColoredBox(color: Colors.black);
    PlacedClip? current;
    if (lay.isNotEmpty) {
      final i = p.indexAt(t);
      final a = lay[i];
      current = a;
      final la = t - a.start;
      final len = a.clip.length;
      final next = i + 1 < lay.length ? lay[i + 1] : null;
      if (next != null && a.clip.trans != ReelTransition.cut && la > len - kTransitionSeconds) {
        final q = _clamp((la - (len - kTransitionSeconds)) / kTransitionSeconds);
        base = _transition(a.clip, la, next.clip, q, a.clip.trans);
      } else {
        base = _clip(a.clip, la);
      }
    }

    return SizedBox(
      width: kReelW,
      height: kReelH,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Clips and effect get the colour filter; names, text and logo stay clean.
            ColorFiltered(
              colorFilter: ColorFilter.matrix(p.filter.matrix),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const ColoredBox(color: Colors.black),
                  base,
                  if (p.effect != VideoEffect.none)
                    CustomPaint(
                      painter: EffectPainter(p.effect, t, colors: [template.accent, template.frame, const Color(0xFFF7B32B)]),
                    ),
                ],
              ),
            ),
            if (current != null && current.clip.type != ClipType.card) _caption(current.clip, t - current.start),
            ..._texts(lay),
            const _Logo(),
          ],
        ),
      ),
    );
  }

  // ---- clips -----------------------------------------------------------------

  Widget _clip(ReelClip c, double local) => switch (c.type) {
        ClipType.card => _card(c, local),
        ClipType.photo => _photo(c, local),
        ClipType.video => ClipRect(child: video(c, local)),
      };

  Widget _card(ReelClip c, double local) {
    if (faces.isEmpty) return const SizedBox.expand();
    final face = faces[c.face.clamp(0, faces.length - 1)];
    if (c.story) {
      return CardStory.frame(
        face: face,
        template: template,
        layout: layout,
        local: local,
        dur: c.dur,
        art: StoryArt(
          info: storyInfo,
          deity: deity,
          intro: c.deityIntro,
          deityImage: images[c.deityPath ?? deityArtPath],
          photos: {
            for (final e in {...defaultPhotos, ...c.photos}.entries)
              if (images[e.value] case final img?) e.key: img,
          },
          faces: {
            for (final e in {...defaultPhotos, ...c.photos}.entries)
              if (images.face(e.value) case final f?) e.key: f,
          },
          shape: PhotoShape.byName(c.photoShape),
          look: c.look,
        ),
      );
    }
    // The card's lines appear one by one; speed makes that slower / faster.
    final reveal = _clamp(local * c.speed / (c.dur * 0.6));
    final zoom = 1 + 0.04 * _clamp(local / c.dur);
    return Transform.scale(
      scale: zoom,
      child: InvitationCard(text: face, template: template, layout: layout, reveal: reveal),
    );
  }

  Widget _photo(ReelClip c, double local) {
    final img = images[c.path];
    if (img == null) {
      return ColoredBox(
        color: const Color(0xFF1A1A22),
        child: Center(
          child: Icon(images.failed(c.path) ? Icons.broken_image_outlined : Icons.image_outlined,
              color: Colors.white24, size: 48),
        ),
      );
    }
    // Movement follows the clip speed: 0.3× = dreamy slow zoom.
    final p = _clamp(local * c.speed / 4);
    final (scale, dx) = switch (c.motion) {
      PhotoMotion.zoomIn => (1 + 0.18 * p, 0.0),
      PhotoMotion.zoomOut => (1.18 - 0.18 * p, 0.0),
      PhotoMotion.panLeft => (1.15, (0.5 - p) * 40),
      PhotoMotion.panRight => (1.15, (p - 0.5) * 40),
      PhotoMotion.still => (1.0, 0.0),
    };
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.translationValues(dx, 0, 0).multiplied(Matrix4.diagonal3Values(scale, scale, 1)),
      child: RawImage(image: img, fit: BoxFit.cover, width: kReelW, height: kReelH, filterQuality: FilterQuality.medium),
    );
  }

  Widget _transition(ReelClip a, double la, ReelClip b, double q, ReelTransition kind) {
    Widget aw() => _clip(a, la);
    Widget bw() => _clip(b, 0);
    final half = q < 0.5;
    switch (kind) {
      case ReelTransition.fade:
        return Stack(fit: StackFit.expand, children: [aw(), Opacity(opacity: q, child: bw())]);
      case ReelTransition.slide:
        return Stack(fit: StackFit.expand, children: [
          Transform.translate(offset: Offset(-q * kReelW, 0), child: aw()),
          Transform.translate(offset: Offset((1 - q) * kReelW, 0), child: bw()),
        ]);
      case ReelTransition.zoom:
        return half
            ? Transform.scale(scale: 1 + q * 1.2, child: aw())
            : Transform.scale(scale: 0.7 + (q - 0.5) * 0.6, child: bw());
      case ReelTransition.flash:
        return Stack(fit: StackFit.expand, children: [
          half ? aw() : bw(),
          ColoredBox(color: Colors.white.withAlpha(((1 - (q - 0.5).abs() * 2) * 255).round().clamp(0, 255))),
        ]);
      case ReelTransition.spin:
        return Transform.rotate(angle: (half ? q : q - 1) * math.pi, child: half ? aw() : bw());
      case ReelTransition.blur:
        final sigma = (1 - (q - 0.5).abs() * 2) * 6 + 0.001;
        return ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma, tileMode: TileMode.clamp),
          child: half ? aw() : bw(),
        );
      case ReelTransition.cut:
        return aw();
    }
  }

  // ---- names, text, logo ---------------------------------------------------------

  Widget _caption(ReelClip c, double local) {
    if (c.caption.trim().isEmpty) return const SizedBox.shrink();
    final len = c.length;
    final p = _ease(_clamp((local - 0.35) / 0.7));
    final out = _clamp((len - local) / 0.35);
    if (p <= 0) return const SizedBox.shrink();
    final col = captionColor(c.capStyle);
    final neon = c.capStyle == ReelTextStyle.neon;
    var blur = neon ? 16.0 : 8.0;
    if (c.capAnim == CaptionAnim.glow) blur = 8 + 10 * (1 + math.sin(local * 4));
    var text = c.caption;
    if (c.capAnim == CaptionAnim.type) {
      final chars = text.characters;
      text = chars.take((chars.length * _clamp((local - 0.35) / 1.2)).ceil()).toString();
    }
    var dx = 0.0, dy = 0.0, zoom = 1.0;
    switch (c.capAnim) {
      case CaptionAnim.rise:
        dy = (1 - p) * 22;
      case CaptionAnim.slide:
        dx = -(1 - p) * kReelW * 0.6;
      case CaptionAnim.pop:
        zoom = p < 1 ? 0.6 + 0.5 * p - 0.1 * math.sin(p * math.pi) : 1.0;
      case CaptionAnim.type:
      case CaptionAnim.glow:
        break;
    }
    final subAlpha = math.min(_ease(_clamp((local - 0.8) / 0.6)), out);
    final alpha = math.min(p, out);
    return Stack(
      fit: StackFit.expand,
      children: [
        // Soft shade so names read on any photo.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: kReelH * 0.38,
          child: Opacity(
            opacity: alpha,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xAA000000)],
                ),
              ),
            ),
          ),
        ),
        _at(
          kReelH - 92 + dy,
          Opacity(
            opacity: alpha,
            child: Transform.translate(
              offset: Offset(dx, 0),
              child: Transform.scale(
                scale: zoom,
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: reelFont(c.capStyle,
                      color: col, shadows: [Shadow(color: neon ? col : const Color(0xCC000000), blurRadius: blur)]),
                ),
              ),
            ),
          ),
        ),
        if (c.sub.trim().isNotEmpty && subAlpha > 0)
          _at(
            kReelH - 92 + 30 + dy,
            Opacity(
              opacity: subAlpha,
              child: Transform.translate(
                offset: Offset(dx, 0),
                child: Text(
                  c.sub.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: GoogleFonts.getFont('Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: const Color(0xD9FFFFFF),
                      shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 4)]),
                ),
              ),
            ),
            h: 30,
          ),
      ],
    );
  }

  List<Widget> _texts(List<PlacedClip> lay) {
    final total = project.total;
    return [
      for (final tx in project.texts)
        if (tx.text.trim().isNotEmpty)
          if (_text(tx, lay, total) case final w?) w,
    ];
  }

  Widget? _text(ReelText tx, List<PlacedClip> lay, double total) {
    final r = tx.range(lay, total);
    if (r == null) return null;
    final (s, e) = r;
    if (t < s || t > e) return null;
    final local = t - s;
    final p = _ease(_clamp(local / 0.5));
    final out = _clamp((e - t) / 0.3);
    final color = Color(tx.color);
    final glow = tx.anim == CaptionAnim.glow || tx.style == ReelTextStyle.neon;
    var text = tx.text;
    if (tx.anim == CaptionAnim.type) {
      final chars = text.characters;
      text = chars.take((chars.length * _clamp(local / 1.0)).ceil()).toString();
    }
    var dx = 0.0, dy = 0.0, zoom = 1.0;
    switch (tx.anim) {
      case CaptionAnim.rise:
        dy = (1 - p) * 16;
      case CaptionAnim.slide:
        dx = -(1 - p) * kReelW * 0.6;
      case CaptionAnim.pop:
        zoom = p < 1 ? 0.6 + 0.5 * p - 0.1 * math.sin(p * math.pi) : 1.0;
      case CaptionAnim.type:
      case CaptionAnim.glow:
        break;
    }
    // Filled box: the colour becomes the box, the letters black or white.
    final light = color.computeLuminance() > 0.5;
    final ink = tx.box == 1 ? (light ? Colors.black : Colors.white) : color;
    final blur = glow ? 10 + 6 * (1 + math.sin(local * 4)) : 6.0;
    final style = GoogleFonts.getFont(
      tx.family,
      fontSize: tx.size,
      fontWeight: tx.bold ? FontWeight.w800 : FontWeight.w500,
      color: ink,
      height: 1.15,
      shadows: tx.box == 1
          ? null
          : [Shadow(color: glow ? color : const Color(0xAA000000), blurRadius: blur)],
    );
    Widget w = Text(text, textAlign: TextAlign.center, style: style);
    if (tx.box != 0) {
      w = Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: tx.box == 1 ? color : const Color(0x73000000),
          borderRadius: BorderRadius.circular(10),
        ),
        child: w,
      );
    }
    return _at(
      tx.y * kReelH + dy,
      Opacity(
        opacity: _clamp(math.min(p, out)),
        child: Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: zoom, child: w),
        ),
      ),
      h: 160,
    );
  }

  /// [child] centred on the line y (canvas coordinates).
  static Widget _at(double y, Widget child, {double h = 80}) => Positioned(
        left: 14,
        right: 14,
        top: y - h / 2,
        height: h,
        child: Center(child: child),
      );
}

/// Small Ahvanam logo in the bottom-right corner.
class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) => Positioned(
        right: 8,
        bottom: 8,
        child: Opacity(
          opacity: 0.8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/brand/logo.png', width: 10, height: 10),
              const SizedBox(width: 3),
              Text(
                'Ahvanam',
                style: GoogleFonts.getFont('Plus Jakarta Sans',
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    shadows: const [Shadow(color: Color(0x88000000), blurRadius: 2)]),
              ),
            ],
          ),
        ),
      );
}
