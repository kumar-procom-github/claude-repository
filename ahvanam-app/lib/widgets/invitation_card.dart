import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../templates/card_fonts.dart';
import '../templates/card_template.dart';
import '../templates/toran_painter.dart';
import '../wording/card_text.dart';

/// Renders one card face at a fixed 9:16 design size (360 × 640 logical px).
/// Exported at pixelRatio 3 → 1080 × 1920, the WhatsApp/Status-friendly size.
class InvitationCard extends StatelessWidget {
  const InvitationCard({
    super.key,
    required this.text,
    required this.template,
    this.layout = CardLayout.toran,
    this.teluguFont,
    this.englishFont,
    this.art,
    this.artPadding,
    this.scrim = 0,
    this.watermark = false,
    this.reveal,
    this.revealStyle = TextReveal.fadeUp,
    this.bare = false,
    this.leading,
  });

  /// Video invitations: 0 → no text yet, 1 → all lines shown. Lines appear
  /// one after another. null = a still card (everything visible).
  final double? reveal;
  final TextReveal revealStyle;

  /// Words only, no background or ornaments (video story mode draws those).
  final bool bare;

  /// Shown above the words (a photo in the video story); cards don't use it.
  final Widget? leading;

  /// Small "Ahvanam" logo in the bottom-right corner (saved / shared cards).
  final bool watermark;

  static const designSize = Size(360, 640);

  final CardText text;
  final CardTemplate template;
  final CardLayout layout;

  /// User-chosen fonts; null = the colour theme's defaults.
  final TeluguFont? teluguFont;
  final EnglishFont? englishFont;

  /// Illustrated background from the online catalog. When set, it replaces
  /// the code-drawn [layout] ornaments and [artPadding] marks the text area.
  final File? art;
  final EdgeInsets? artPadding;

  /// 0–1 white veil behind the text area, for busy artwork.
  final double scrim;

  static const _scriptFonts = {
    'Great Vibes',
    'Pinyon Script',
    'Parisienne',
    'Tangerine',
    'Alex Brush',
    'Allura',
    'Sacramento',
  };
  static bool _isScript(String family) => _scriptFonts.contains(family);

  /// Handwriting fonts look small at normal sizes and get a bigger size.
  static bool isScriptFont(String family) => _scriptFonts.contains(family);

  @override
  Widget build(BuildContext context) {
    final pad = art != null ? (artPadding ?? layout.contentPadding) : layout.contentPadding;
    final content = Padding(
      padding: pad,
      child: Center(
        child: FittedBox(
          // Long Telugu text shrinks to fit instead of overflowing.
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: designSize.width - pad.horizontal,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) leading!,
                for (var i = 0; i < text.lines.length; i++) _animated(i, text.lines.length, _line(text.lines[i])),
              ],
            ),
          ),
        ),
      ),
    );

    final card = SizedBox.fromSize(
      size: designSize,
      child: bare
          ? content
          : art == null
          ? CustomPaint(painter: CardPainter(template, layout), child: content)
          : Stack(
              fit: StackFit.expand,
              children: [
                Image.file(art!, fit: BoxFit.cover, gaplessPlayback: true),
                if (scrim > 0)
                  Positioned.fromRect(
                    rect: pad.deflateRect(Offset.zero & designSize).inflate(8),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha((scrim * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                content,
              ],
            ),
    );
    if (!watermark) return card;
    return Stack(
      children: [
        card,
        Positioned(
          right: 8,
          bottom: 6,
          child: Opacity(
            opacity: 0.75,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2.5),
                  child: Image.asset('assets/brand/logo.png', width: 10, height: 10),
                ),
                const SizedBox(width: 3),
                Text(
                  'Ahvanam',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: template.text,
                    shadows: const [Shadow(blurRadius: 2, color: Color(0x55000000))],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Line [i] of [n] at the current [reveal] progress. Layout never changes
  /// (hidden lines keep their space), so text doesn't jump while animating.
  Widget _animated(int i, int n, Widget child) {
    final r = reveal;
    if (r == null) return child;
    const each = 0.28; // share of the reveal one line takes to appear
    final start = n <= 1 ? 0.0 : (1 - each) * i / (n - 1);
    final p = Curves.easeOutCubic.transform(((r - start) / each).clamp(0.0, 1.0));
    if (p >= 1) return child;
    if (p <= 0) return Opacity(opacity: 0, child: child);
    final moved = switch (revealStyle) {
      TextReveal.fadeUp => Transform.translate(offset: Offset(0, (1 - p) * 16), child: child),
      TextReveal.zoom => Transform.scale(scale: 0.82 + 0.18 * p, child: child),
      TextReveal.slide => Transform.translate(offset: Offset((i.isEven ? -1 : 1) * (1 - p) * 40, 0), child: child),
    };
    return Opacity(opacity: p, child: moved);
  }

  Widget _line(CardLine line) {
    if (line.role == LineRole.spacer) return const SizedBox(height: 10);
    if (line.role == LineRole.icon && line.text == 'divider') {
      // ── ◆ ── under a heading (video story frames only).
      final c = template.accent;
      Widget rule() => Container(width: 46, height: 1, color: c.withAlpha(150));
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            rule(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Transform.rotate(angle: 0.785398, child: Container(width: 6, height: 6, color: c)),
            ),
            rule(),
          ],
        ),
      );
    }
    if (line.role == LineRole.icon) {
      // ── 🍴 ── in the design's accent colour, to set the meal section apart.
      final c = template.accent;
      Widget rule() => Container(width: 36, height: 1, color: c.withAlpha(140));
      return Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            rule(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.restaurant, size: 16, color: c),
            ),
            rule(),
          ],
        ),
      );
    }
    if (line.text.contains('\u0001')) {
      // "BIG\u0001 small" on one line: "తుంపాటి వారి" (video story only).
      final parts = line.text.split('\u0001');
      final big = _style(line.role);
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: parts[0], style: big.copyWith(fontSize: (big.fontSize ?? 30) * 1.25)),
            TextSpan(text: parts.skip(1).join(), style: big.copyWith(fontSize: (big.fontSize ?? 30) * 0.55)),
          ]),
          textAlign: TextAlign.center,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: line.role == LineRole.name ? 2 : 1.5),
      child: Text(
        line.text,
        textAlign: TextAlign.center,
        style: _style(line.role),
      ),
    );
  }

  TextStyle _style(LineRole role) {
    final te = text.telugu;
    final t = template;
    // Telugu needs taller lines for vowel signs and vattulu (conjuncts).
    final height = te ? 1.55 : 1.3;

    TextStyle font(String family, double size, Color color,
        {FontWeight weight = FontWeight.w400, FontStyle style = FontStyle.normal, double spacing = 0}) {
      return GoogleFonts.getFont(
        family,
        fontSize: size,
        color: color,
        fontWeight: weight,
        fontStyle: style,
        height: height,
        letterSpacing: spacing,
      );
    }

    final tf = teluguFont, ef = englishFont;
    final titleFont = te ? (tf?.title ?? t.teTitleFont) : (ef?.title ?? t.enTitleFont);
    final bodyFont = te ? (tf?.body ?? t.teBodyFont) : (ef?.body ?? t.enBodyFont);
    final nameFont = te ? titleFont : (ef?.names ?? t.enNameFont);
    final titleSize = te ? 30.0 : (_isScript(titleFont) ? 34.0 : 24.0);
    final nameSize = te ? 22.0 : (_isScript(nameFont) ? 32.0 : 23.0);

    return switch (role) {
      LineRole.title => font(titleFont, titleSize, t.accent,
          weight: te || _isScript(titleFont) ? FontWeight.w400 : FontWeight.w700),
      LineRole.blessing => font(bodyFont, 11.5, t.accent, spacing: te ? 0 : 1),
      LineRole.deity => font(bodyFont, 12.5, t.text, weight: FontWeight.w700),
      LineRole.body => font(bodyFont, 13, t.text),
      LineRole.name => font(nameFont, nameSize, t.accent),
      LineRole.small => font(bodyFont, 11, t.text.withAlpha(220)),
      LineRole.connector => font(bodyFont, 12.5, t.text, style: te ? FontStyle.normal : FontStyle.italic),
      LineRole.highlight => font(bodyFont, 14.5, t.accent, weight: FontWeight.w700),
      LineRole.event => te
          ? font(titleFont, 18, t.accent)
          : font(titleFont, _isScript(titleFont) ? 24 : 17, t.accent,
              weight: _isScript(titleFont) ? FontWeight.w400 : FontWeight.w700),
      LineRole.label => font(bodyFont, 10.5, t.accent, weight: FontWeight.w700, spacing: te ? 0 : 1.5),
      LineRole.value => font(bodyFont, 12.5, t.text),
      LineRole.closing => font(bodyFont, 12.5, t.text, style: te ? FontStyle.normal : FontStyle.italic),
      LineRole.spacer || LineRole.icon => const TextStyle(),
    };
  }
}
