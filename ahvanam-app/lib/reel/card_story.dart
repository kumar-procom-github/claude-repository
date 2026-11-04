import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/ceremony.dart';
import '../models/invitation_draft.dart';
import '../templates/card_template.dart';
import '../templates/toran_painter.dart';
import '../widgets/invitation_card.dart';
import 'photo_shapes.dart';
import 'story_art.dart';
import '../wording/card_text.dart';

/// One frame of a card story, and whose photo (if any) it shows.
class StoryPage {
  const StoryPage(this.lines, [this.photoKey, this.couple = false, this.icon]);

  /// Small moving illustration above the heading (when there's no photo).
  final StoryIcon? icon;
  final List<CardLine> lines;

  /// "Groom weds Bride" frame, drawn inside a gold frame.
  final bool couple;

  /// 'groom', 'bride' or 'main' — the photo slot shown above these words.
  final String? photoKey;
}

/// Pictures used by a story: the god's picture for the opening and the
/// people's photos for their frames.
/// What the story needs to know about the function.
class StoryInfo {
  const StoryInfo({
    this.tradition = Tradition.hindu,
    this.solemn = false,
    this.familyTe = '',
    this.familyEn = '',
    this.groomTe = '',
    this.groomEn = '',
    this.brideTe = '',
    this.brideEn = '',
    this.engagement = false,
  });

  /// Engagement / Mangni / Betrothal: "&" instead of "weds", and the venue
  /// isn't called కళ్యాణ వేదిక.
  final bool engagement;
  final Tradition tradition;

  /// Remembrance: no "warm welcome" heading.
  final bool solemn;

  /// Family surname for the first frame: "తుంపాటి వారి వివాహ ఆహ్వానము".
  final String familyTe;
  final String familyEn;

  /// Plain names for the "Groom weds Bride" frame.
  final String groomTe;
  final String groomEn;
  final String brideTe;
  final String brideEn;
}

/// [StoryInfo] from the details the user filled in.
StoryInfo storyInfoFor(InvitationDraft d) {
  String en(String k) => (d.en[k] ?? '').trim();
  String te(String k) => (d.te[k] ?? '').trim();
  return StoryInfo(
    tradition: d.tradition,
    solemn: d.ceremony.isRemembrance,
    familyEn: en('familyName'),
    familyTe: te('familyName').isNotEmpty ? te('familyName') : en('familyName'),
    groomEn: en('groom'),
    groomTe: te('groom').isNotEmpty ? te('groom') : en('groom'),
    brideEn: en('bride'),
    brideTe: te('bride').isNotEmpty ? te('bride') : en('bride'),
    engagement: const {CeremonyId.engagement, CeremonyId.mangni, CeremonyId.betrothal}.contains(d.ceremony.id),
  );
}

class StoryArt {
  const StoryArt({
    this.deity = Deity.none,
    this.deityImage,
    this.photos = const {},
    this.faces = const {},
    this.shape = PhotoShape.splash,
    this.intro = true,
    this.info = const StoryInfo(),
    this.look = 'card',
  });
  final Deity deity;

  /// 'card' (the card's own design) or 'watercolor' (watercolour flowers).
  final String look;
  bool get watercolor => look == 'watercolor';
  final StoryInfo info;

  /// Photo of the god (Ahvanam's or the user's own). null = drawn symbol.
  final ui.Image? deityImage;
  final Map<String, ui.Image> photos;

  /// Where the face is in each photo (same keys as [photos]).
  final Map<String, FaceSpot> faces;

  /// Shape the photos are cut in.
  final PhotoShape shape;

  /// Show the god at the start.
  final bool intro;

  bool get hasIntro => intro && deity != Deity.none;
}

/// "Story" playback of a card in the video editor:
///   0. the empty card; the god's picture eases in and out (if a god is chosen)
///   1. the card's top and bottom art slide in
///   2. the words play frame by frame — heading → people (groom, bride …) →
///      date & muhurtham → meal & venue → wishes & who invites.
/// Used only by the video editor; the card screens are unchanged.
class CardStory {
  CardStory._();

  static const _introStart = 0.7;
  static const _introSeconds = 2.8;
  static const _artSeconds = 1.2;
  static const _fadeOut = 0.45;

  static double _artStart(bool intro) => intro ? _introStart + _introSeconds : 1.1;

  /// Seconds before the first words appear.
  static double openSeconds({bool intro = false}) => _artStart(intro) + _artSeconds + 0.1;

  /// The face's lines split into frames, each (after the first) with a
  /// heading: వరుడు / వధువు / సుముహూర్తం / వేదిక / సాదర ఆహ్వానం …
  static List<StoryPage> pages(CardText face, [StoryInfo info = const StoryInfo()]) {
    final te = face.telugu;
    final lines = face.lines;
    var i = 0;
    final header = <CardLine>[];
    while (i < lines.length &&
        const {LineRole.title, LineRole.blessing, LineRole.deity, LineRole.spacer}.contains(lines[i].role)) {
      header.add(lines[i++]);
    }
    final rest = lines.sublist(i);

    // First frame: blessing and god's line small, then "<surname> వారి" and
    // the function's title big.
    final family = (te ? info.familyTe : info.familyEn).trim();
    var title = header.where((l) => l.role == LineRole.title).toList();
    // "తుంపాటి వారి వివాహ ఆహ్వానము": the surname big, వారి small, then the invitation.
    if (family.isNotEmpty && te) {
      title = [
        for (final l in title)
          l.text.trim() == 'శుభలేఖ' ? const CardLine('వివాహ ఆహ్వానము', LineRole.title) : l,
      ];
    }
    final opening = [
      ...header.where((l) => l.role == LineRole.blessing || l.role == LineRole.deity),
      if (family.isNotEmpty) ...[
        const CardLine('', LineRole.spacer),
        const CardLine('', LineRole.spacer),
        CardLine(te ? '$family\u0001 వారి' : '$family\u0001  Family', LineRole.title),
      ],
      ...title,
    ];

    // Meal / venue / who-invites start at the first icon or label.
    var footerStart = rest.indexWhere((l) => l.role == LineRole.icon || l.role == LineRole.label);
    if (footerStart < 0) footerStart = rest.length;
    final bodyAll = rest.sublist(0, footerStart);
    final footer = rest.sublist(footerStart);

    final closing = [for (final l in bodyAll) if (l.role == LineRole.closing) l];
    final body = [for (final l in bodyAll) if (l.role != LineRole.closing) l];

    // Who invites = the last label block of the footer (when there are two or more).
    final labels = [for (var k = 0; k < footer.length; k++) if (footer[k].role == LineRole.label) k];
    var place = footer;
    var inviters = <CardLine>[];
    if (labels.length >= 2) {
      place = footer.sublist(0, labels.last);
      inviters = footer.sublist(labels.last);
    }

    List<CardLine> head(String text) => [CardLine(text, LineRole.title), const CardLine('divider', LineRole.icon)];
    String pick(String teText, String enText) => te ? teText : enText;
    // Date frames: సుముహూర్తం when the card speaks of a muhurtham / lagnam.
    List<CardLine> withWhenHeading(List<CardLine> l) {
      if (!l.any((x) => x.role == LineRole.highlight)) return l;
      final all = l.map((x) => x.text).join(' ');
      final muhurtham = all.contains('ముహూర్త') || all.contains('లగ్న') || all.contains('Muhurtham') || all.contains('Lagnam');
      return [...head(muhurtham ? pick('సుముహూర్తం', 'Muhurtham') : pick('తేదీ & సమయం', 'Date & Time')), ..._trim(l)];
    }

    StoryPage whenPage(List<CardLine> l, [String? key]) {
      final lines = withWhenHeading(l);
      final heading = lines.isEmpty ? '' : lines.first.text;
      final icon = heading == 'సుముహూర్తం' || heading == 'Muhurtham'
          ? StoryIcon.kalasam
          : (lines.any((x) => x.role == LineRole.highlight) ? StoryIcon.calendar : null);
      return StoryPage(lines, key, false, icon);
    }

    final out = <StoryPage>[StoryPage(opening)];
    var wedding = false;
    int names(List<CardLine> l) => l.where((x) => x.role == LineRole.name).length;

    if (body.any((l) => l.role == LineRole.event)) {
      // Schedule cards: one frame per function.
      var cur = <CardLine>[];
      for (final l in body) {
        if (l.role == LineRole.event && _count(cur) > 0) {
          out.add(StoryPage(cur));
          cur = [];
        }
        cur.add(l);
      }
      out.add(StoryPage(cur));
    } else {
      final hl = body.indexWhere((l) => l.role == LineRole.highlight);
      final people = hl > 0 ? body.sublist(0, hl) : <CardLine>[];
      final when = hl > 0 ? body.sublist(hl) : body;
      final connector = people.indexWhere((l) => l.role == LineRole.connector);
      if (names(people) >= 2 && connector > 0) {
        // Weddings / engagements: the groom, then the bride, then the date.
        final (groomTe, groomEn, brideTe, brideEn) = switch (info.tradition) {
          Tradition.christian => ('పెండ్లి కుమారుడు', 'The Bridegroom', 'పెండ్లి కుమార్తె', 'The Bride'),
          Tradition.muslim => ('దుల్హా', 'The Dulha', 'దుల్హన్', 'The Dulhan'),
          _ => ('వరుడు', 'The Groom', 'వధువు', 'The Bride'),
        };
        final bride = people.sublist(connector + 1); // "మరియు" isn't needed on its own frame
        wedding = true;
        final g = (te ? info.groomTe : info.groomEn).trim(), b = (te ? info.brideTe : info.brideEn).trim();
        out
          ..add(StoryPage([...head(pick(groomTe, groomEn)), ..._trim(people.sublist(0, connector))], 'groom'))
          ..add(StoryPage([...head(pick(brideTe, brideEn)), ..._trim(bride)], 'bride'));
        if (g.isNotEmpty && b.isNotEmpty) {
          // The couple together: "Groom weds Bride".
          out.add(StoryPage([
            CardLine(g, LineRole.title),
            CardLine(info.engagement ? '&' : (te ? 'వెడ్స్' : 'weds'), LineRole.connector),
            CardLine(b, LineRole.title),
          ], 'couple', true));
        }
        out.add(whenPage(when));
      } else if (names(people) >= 1) {
        // One person (birthday, naming…): their frame, then the date.
        out
          ..add(StoryPage(people, 'main'))
          ..add(whenPage(when));
      } else if (_count(body) > 7 && hl > 0) {
        out
          ..add(StoryPage(people))
          ..add(whenPage(when));
      } else {
        out.add(whenPage(body, 'main'));
      }
    }

    // Venue frame: its label (వేదిక / నూతన గృహం / Venue) becomes the heading,
    // the address comes first and the meal under it.
    final placeLabel = place.indexWhere((l) => l.role == LineRole.label);
    if (placeLabel >= 0) {
      final meal = _trim(place.sublist(0, placeLabel));
      final value = _trim(place.sublist(placeLabel + 1));
      var label = place[placeLabel].text;
      if (wedding && !info.engagement && (label == 'వేదిక' || label == 'Venue')) label = pick('కళ్యాణ వేదిక', 'Wedding Venue');
      out
        ..add(StoryPage([...head(label), ...value], null, false, StoryIcon.mandapam))
        ..add(StoryPage(_mealFrame(meal, te), null, false, StoryIcon.meal));
    } else {
      out.add(StoryPage(place));
    }

    final last = [
      ...closing,
      if (closing.isNotEmpty && inviters.isNotEmpty) const CardLine('', LineRole.spacer),
      ...inviters,
    ];
    out.add(StoryPage([
      if (_count(last) > 0 && !info.solemn) ...head(pick('సాదర ఆహ్వానం', 'A Warm Welcome')),
      ...last,
    ], null, false, info.solemn ? null : StoryIcon.welcome));

    // Very long frames are halved; spacers at the edges are dropped.
    final result = <StoryPage>[];
    for (final p in out) {
      final t = _trim(p.lines);
      if (_count(t) == 0 || t.every((l) => l.role == LineRole.title || l.role == LineRole.icon)) continue;
      if (_count(t) > 11) {
        final mid = t.length ~/ 2;
        result
          ..add(StoryPage(_trim(t.sublist(0, mid)), p.photoKey, false, p.icon))
          ..add(StoryPage(_trim(t.sublist(mid))));
      } else {
        result.add(StoryPage(t, p.photoKey, p.couple, p.icon));
      }
    }
    return result.isEmpty ? [StoryPage(lines)] : result;
  }

  /// Lunch / dinner as its own frame: "విందు" heading, then when and where.
  static List<CardLine> _mealFrame(List<CardLine> meal, bool te) {
    final lines = [for (final l in meal) if (l.role != LineRole.icon) l];
    final hi = lines.indexWhere((l) => l.role == LineRole.highlight);
    if (hi < 0) return lines;
    final text = lines[hi].text;
    String heading;
    var rest = text;
    final colon = text.indexOf(':');
    if (colon > 0) {
      heading = text.substring(0, colon).trim();
      rest = text.substring(colon + 1).trim();
    } else if (te) {
      heading = text.split(' ఏర్పాటు').first.trim();
      rest = '';
    } else {
      heading = text.split(' ').first;
    }
    return [
      CardLine(heading, LineRole.title),
      const CardLine('divider', LineRole.icon),
      if (rest.isNotEmpty) CardLine(rest, LineRole.highlight),
      for (var k = 0; k < lines.length; k++)
        if (k != hi) lines[k],
    ];
  }

  /// Photo slots this face offers ('groom', 'bride' or 'main').
  static List<String> photoKeys(CardText face, [StoryInfo info = const StoryInfo()]) => [
        for (final p in pages(face, info))
          if (p.photoKey != null) p.photoKey!,
      ];

  static int _count(List<CardLine> l) => l.where((x) => x.role != LineRole.spacer).length;

  static List<CardLine> _trim(List<CardLine> l) {
    var a = 0, b = l.length;
    while (a < b && l[a].role == LineRole.spacer) {
      a++;
    }
    while (b > a && l[b - 1].role == LineRole.spacer) {
      b--;
    }
    return l.sublist(a, b);
  }

  static double _pageSeconds(StoryPage p, StoryArt art) =>
      (1.4 + 0.42 * _count(p.lines) + (p.photoKey != null ? 0.6 : 0)).clamp(3.0, 6.5).toDouble();

  /// Natural length of the story at 1× speed, in seconds.
  static double naturalSeconds(CardText face, [StoryArt art = const StoryArt()]) =>
      openSeconds(intro: art.hasIntro) + pages(face, art.info).fold(0.0, (a, p) => a + _pageSeconds(p, art)) + 0.4;

  /// The card at [local] seconds into a clip lasting [dur] seconds (the
  /// story is stretched / squeezed to fill it).
  static Widget frame({
    required CardText face,
    required CardTemplate template,
    required CardLayout layout,
    required double local,
    required double dur,
    StoryArt art = const StoryArt(),
  }) {
    if (art.watercolor) {
      template = watercolorTemplate;
      layout = CardLayout.modern; // only its text area is used
    }
    final natural = naturalSeconds(face, art);
    final t = dur <= 0 ? local : local * natural / dur;
    final ps = pages(face, art.info);
    final intro = art.hasIntro;

    double clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);
    double ease(double x) => 1 - math.pow(1 - clamp01(x), 3).toDouble();

    // Art: frame fades in, top art slides down, bottom art slides up.
    final slide = ease((t - _artStart(intro)) / _artSeconds);
    final middle = intro ? clamp01((t - _artStart(intro) + 0.4) / 0.8) : clamp01(t / 0.9);
    const size = InvitationCard.designSize;
    final pad = layout.contentPadding;
    Widget ornaments(Rect band, double dy, double alpha) => Opacity(
          opacity: alpha,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: ClipRect(
              clipper: _Band(band),
              // The art stays alive: flames flicker, leaves sway, mandalas turn…
              child: CustomPaint(
                  size: size, painter: CardPainter(template, layout, part: CardPaintPart.ornaments, time: t)),
            ),
          ),
        );

    // Which frame of words, and how far into it.
    var start = openSeconds(intro: intro);
    Widget words = const SizedBox.shrink();
    var pulse = 0.0; // art lifts and settles as each new frame comes in
    for (var i = 0; i < ps.length; i++) {
      final page = ps[i];
      final len = _pageSeconds(page, art);
      final end = start + len;
      final last = i == ps.length - 1;
      if (t >= start && (t < end || last)) {
        final reveal = clamp01((t - start) / math.min(1.6, len * 0.4));
        final alpha = last ? 1.0 : clamp01((end - t) / _fadeOut);
        final photo = page.photoKey == null ? null : art.photos[page.photoKey];
        if (i > 0) pulse = math.sin(clamp01((t - start) / 0.9) * math.pi);
        final card = InvitationCard(
            text: CardText(page.lines, telugu: face.telugu),
            template: template,
            layout: layout,
            reveal: reveal,
            bare: true,
            leading: photo == null
                ? (page.icon == null
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SizedBox(
                          width: 130,
                          height: 86,
                          child: CustomPaint(
                            painter: StoryIconPainter(page.icon!, template,
                                progress: clamp01((t - start) / 0.9), time: t),
                          ),
                        ),
                      ))
                : Padding(
                    padding: EdgeInsets.only(bottom: page.couple ? 14 : 10),
                    child: () {
                      final shaped = ShapedPhoto(
                        image: photo,
                        shape: art.shape,
                        color: template.accent,
                        face: art.faces[page.photoKey],
                        progress: clamp01((t - start) / 1.1),
                        time: t - start,
                        height: page.couple ? 160 : 210,
                      );
                      if (!page.couple) return shaped;
                      // The couple photo sits inside the gold hexagons; the names go below.
                      return SizedBox(
                        width: 262,
                        height: 262,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CoupleFramePainter(template.accent, ease((t - start) / 1.2), t, radius: 116),
                              ),
                            ),
                            shaped,
                          ],
                        ),
                      );
                    }(),
                  ),
          );
        words = Opacity(
          opacity: alpha,
          child: !page.couple || photo != null
              ? card
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _CoupleFramePainter(template.accent, ease((t - start) / 1.2), t)),
                    card,
                  ],
                ),
        );
        break;
      }
      start = end;
    }

    final zoom = 1 + 0.03 * clamp01(t / natural);
    return Transform.scale(
      scale: zoom,
      child: SizedBox.fromSize(
        size: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (art.watercolor) ...[
              CustomPaint(painter: WatercolorPainter(time: t, bloom: 0, flowers: false)),
              if (intro) _deity(art, face, template, t),
              CustomPaint(painter: WatercolorPainter(time: t, bloom: slide, pulse: pulse, background: false)),
            ] else ...[
              CustomPaint(painter: CardPainter(template, layout, part: CardPaintPart.background)),
              if (intro) _deity(art, face, template, t),
              ornaments(Rect.fromLTRB(0, pad.top, size.width, size.height - pad.bottom), 0, middle),
              ornaments(Rect.fromLTWH(0, 0, size.width, pad.top), -(1 - slide) * (pad.top + 12) - pulse * 7, slide),
              ornaments(Rect.fromLTRB(0, size.height - pad.bottom, size.width, size.height),
                  (1 - slide) * (pad.bottom + 12) + pulse * 7, slide),
            ],
            words,
          ],
        ),
      ),
    );
  }

  /// The god's picture in the middle of the empty card: eases in, glows, eases out.
  static Widget _deity(StoryArt art, CardText face, CardTemplate t, double time) {
    final local = time - _introStart;
    if (local <= 0 || local >= _introSeconds) return const SizedBox.shrink();
    double c(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);
    final inP = Curves.easeInOutCubic.transform(c(local / 1.0));
    final outP = c((_introSeconds - local) / 0.6);
    final glow = 0.5 + 0.5 * math.sin(local * 2.4);
    final line = face.lines.where((l) => l.role == LineRole.deity && l.text.trim().isNotEmpty).firstOrNull?.text ?? '';
    final img = art.deityImage;
    final Widget picture = img != null
        ? Container(
            width: 200,
            height: 250,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(100), bottom: Radius.circular(14)),
              border: Border.all(color: t.accent, width: 3),
              boxShadow: [BoxShadow(color: t.accent.withAlpha((90 + 70 * glow).round()), blurRadius: 26, spreadRadius: 3)],
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(97), bottom: Radius.circular(11)),
              child: RawImage(image: img, fit: BoxFit.cover, width: 194, height: 244),
            ),
          )
        : SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(painter: DeitySymbolPainter(art.deity, t.accent, glow)),
          );
    return Opacity(
      opacity: math.min(inP, outP),
      child: Center(
        child: Transform.scale(
          scale: 0.86 + 0.14 * inP,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              picture,
              if (line.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(line,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.getFont(face.telugu ? 'Ramabhadra' : 'Cinzel',
                        fontSize: 17, color: t.accent, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Drawn stand-in when no picture of the god is available: Om, the
/// Venkateswara namam, the cross or the crescent, in the card's colour.
class DeitySymbolPainter extends CustomPainter {
  DeitySymbolPainter(this.deity, this.color, this.glow);
  final Deity deity;
  final Color color;
  final double glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(
        c,
        r * 0.95,
        Paint()
          ..shader = RadialGradient(colors: [color.withAlpha((70 + 60 * glow).round()), color.withAlpha(0)])
              .createShader(Rect.fromCircle(center: c, radius: r)));
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.07
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = color;
    switch (deity) {
      case Deity.venkateswara:
        // Namam: white U with a red line in the middle.
        final w = r * 0.5, h = r * 1.0;
        final u = Path()
          ..moveTo(c.dx - w, c.dy - h * 0.55)
          ..lineTo(c.dx - w * 0.55, c.dy + h * 0.35)
          ..quadraticBezierTo(c.dx, c.dy + h * 0.65, c.dx + w * 0.55, c.dy + h * 0.35)
          ..lineTo(c.dx + w, c.dy - h * 0.55);
        canvas.drawPath(u, Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * 0.16
          ..strokeCap = StrokeCap.round);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(center: Offset(c.dx, c.dy - h * 0.05), width: r * 0.12, height: h * 0.8),
                Radius.circular(r * 0.06)),
            Paint()..color = const Color(0xFFE53935));
      case Deity.cross:
      case Deity.mark109:
      case Deity.psalm23:
      case Deity.john1125:
        canvas.drawLine(Offset(c.dx, c.dy - r * 0.62), Offset(c.dx, c.dy + r * 0.62), stroke..strokeWidth = r * 0.12);
        canvas.drawLine(Offset(c.dx - r * 0.38, c.dy - r * 0.22), Offset(c.dx + r * 0.38, c.dy - r * 0.22), stroke);
      case Deity.bismillah:
      case Deity.n786:
      case Deity.innaLillahi:
        final moon = Path()
          ..addOval(Rect.fromCircle(center: c, radius: r * 0.55))
          ..fillType = PathFillType.evenOdd;
        final cut = Path()..addOval(Rect.fromCircle(center: c.translate(r * 0.22, -r * 0.08), radius: r * 0.47));
        canvas.drawPath(Path.combine(PathOperation.difference, moon, cut), fill);
        _star(canvas, c.translate(r * 0.42, -r * 0.18), r * 0.13, fill);
      default:
        // Om
        final tp = TextPainter(
          text: TextSpan(text: 'ॐ', style: TextStyle(fontSize: r * 1.15, color: color, height: 1)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (var k = 0; k < 10; k++) {
      final rad = k.isEven ? r : r * 0.45;
      final a = -math.pi / 2 + k * math.pi / 5;
      final pt = c + Offset(math.cos(a) * rad, math.sin(a) * rad);
      k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    canvas.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(covariant DeitySymbolPainter old) =>
      old.deity != deity || old.color != color || old.glow != glow;
}

/// Two crossed gold hexagons drawing themselves around "Groom weds Bride".
class _CoupleFramePainter extends CustomPainter {
  _CoupleFramePainter(this.color, this.progress, this.time, {this.radius = 118});
  final Color color;

  /// Outer hexagon's radius (its height is a little taller).
  final double radius;
  final double progress;
  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color.withAlpha(200)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final (r, turn) in [(radius, 0.0), (radius * 0.95, 0.32)]) {
      final path = Path();
      for (var k = 0; k <= 6; k++) {
        final a = -math.pi / 2 + turn + k * math.pi / 3 + time * 0.05;
        final pt = c + Offset(math.cos(a) * r, math.sin(a) * r * (radius < 118 ? 1.0 : 1.12));
        k == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      // Draw only the first [progress] of the outline.
      for (final m in path.computeMetrics()) {
        canvas.drawPath(m.extractPath(0, m.length * progress), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CoupleFramePainter old) =>
      old.progress != progress || old.time != time || old.color != color;
}

class _Band extends CustomClipper<Rect> {
  const _Band(this.rect);
  final Rect rect;

  @override
  Rect getClip(Size size) => rect;

  @override
  bool shouldReclip(_Band old) => old.rect != rect;
}
