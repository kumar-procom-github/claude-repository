import 'package:flutter/material.dart';

import 'card_template.dart';

/// An illustrated template from the online catalog: a full-bleed artwork
/// image plus where the text goes and how it is coloured.
///
/// catalog.json entry:
/// {
///   "id": "pelli-marigold-01", "version": 1,
///   "name": "Marigold Mandapam", "nameTe": "బంతిపూల మండపం",
///   "ceremonies": ["wedding", "engagement"],      // or ["all"]
///   "art": "art/pelli-marigold-01.webp",          // 1080 × 1920
///   "thumb": "thumbs/pelli-marigold-01.webp",     // 270 × 480
///   "textBox": [40, 150, 320, 560],               // l, t, r, b on 360 × 640
///   "scrim": 0.0,                                 // 0–1 white veil behind text
///   "colors": {"text": "#4A1A12", "accent": "#8E1116"},
///   "fonts": {"teTitle": "Ramabhadra", "teBody": "Mandali",
///             "enTitle": "Cinzel", "enNames": "Great Vibes", "enBody": "Lora"},
///   "added": "2026-10-29"
/// }
class RemoteTemplate {
  final String id;
  final int version;
  final String name;
  final String nameTe;
  final Set<String> ceremonies;
  final String art;
  final String thumb;
  final Rect textBox;
  final double scrim;
  final Color text;
  final Color accent;
  final Map<String, String> fonts;
  final DateTime? added;

  const RemoteTemplate({
    required this.id,
    required this.version,
    required this.name,
    required this.nameTe,
    required this.ceremonies,
    required this.art,
    required this.thumb,
    required this.textBox,
    required this.scrim,
    required this.text,
    required this.accent,
    required this.fonts,
    required this.added,
  });

  static RemoteTemplate? tryParse(Object? json) {
    if (json is! Map) return null;
    try {
      final box = (json['textBox'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [36, 100, 324, 580];
      final colors = (json['colors'] as Map?) ?? const {};
      return RemoteTemplate(
        id: json['id'] as String,
        version: (json['version'] as num?)?.toInt() ?? 1,
        name: json['name'] as String? ?? json['id'] as String,
        nameTe: json['nameTe'] as String? ?? '',
        ceremonies: {...((json['ceremonies'] as List?) ?? const ['all']).cast<String>()},
        art: json['art'] as String,
        thumb: json['thumb'] as String? ?? json['art'] as String,
        textBox: Rect.fromLTRB(box[0], box[1], box[2], box[3]),
        scrim: ((json['scrim'] as num?) ?? 0).toDouble().clamp(0.0, 1.0).toDouble(),
        text: _color(colors['text'], const Color(0xFF3B2F2F)),
        accent: _color(colors['accent'], const Color(0xFF8E1116)),
        fonts: {...((json['fonts'] as Map?) ?? const {}).cast<String, String>()},
        added: DateTime.tryParse(json['added'] as String? ?? ''),
      );
    } catch (_) {
      return null; // a bad entry must never break the whole catalog
    }
  }

  static Color _color(Object? hex, Color fallback) {
    if (hex is! String) return fallback;
    final h = hex.replaceFirst('#', '');
    final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return v == null ? fallback : Color(v);
  }

  bool fits(String ceremonyId) => ceremonies.contains('all') || ceremonies.contains(ceremonyId);

  /// Content padding on the 360 × 640 design canvas.
  EdgeInsets get padding => EdgeInsets.fromLTRB(textBox.left, textBox.top, 360 - textBox.right, 640 - textBox.bottom);

  /// Colours + default fonts in the shape the card renderer already uses.
  CardTemplate get style => CardTemplate(
        id: id,
        name: name,
        nameTe: nameTe,
        background: const [Colors.white, Colors.white],
        frame: accent,
        text: text,
        accent: accent,
        leaf: const Color(0xFF2E7D32),
        marigold: const Color(0xFFFB8500),
        marigoldCenter: const Color(0xFFD62828),
        teTitleFont: fonts['teTitle'] ?? 'Ramabhadra',
        teBodyFont: fonts['teBody'] ?? 'Mandali',
        enTitleFont: fonts['enTitle'] ?? 'Cinzel',
        enNameFont: fonts['enNames'] ?? 'Great Vibes',
        enBodyFont: fonts['enBody'] ?? 'Lora',
      );
}
