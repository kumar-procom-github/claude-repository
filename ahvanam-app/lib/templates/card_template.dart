import 'package:flutter/material.dart';

import '../models/ceremony.dart';

/// The card's design (ornaments and where the text sits). Each tradition gets
/// its own motifs plus three shared floral/modern designs; any design can be
/// combined with any colour theme ([CardTemplate]). All drawn in code.
enum CardLayout {
  toran('Toran', 'తోరణం', EdgeInsets.fromLTRB(36, 92, 36, 56), _hindu),
  garland('Garland', 'పూలమాల', EdgeInsets.fromLTRB(36, 98, 36, 58), _all),
  temple('Temple Arch', 'గుడి ద్వారం', EdgeInsets.fromLTRB(46, 140, 46, 58), _hindu),
  gopuram('Gopuram', 'గోపురం', EdgeInsets.fromLTRB(40, 136, 40, 50), _hindu),
  kalasam('Kalasam', 'కలశం', EdgeInsets.fromLTRB(34, 104, 34, 44), _hindu),
  deepam('Deepam', 'దీపం', EdgeInsets.fromLTRB(34, 112, 34, 96), _hindu),
  mehrab('Mehrab Arch', 'మెహ్రాబ్', EdgeInsets.fromLTRB(54, 178, 54, 72), _muslim),
  lanterns('Lanterns', 'లాంతర్లు', EdgeInsets.fromLTRB(36, 120, 36, 120), _muslim),
  chapel('Chapel Window', 'చర్చి కిటికీ', EdgeInsets.fromLTRB(52, 150, 52, 104), _christian),
  bells('Wedding Bells', 'గంటలు', EdgeInsets.fromLTRB(38, 130, 38, 84), _christian),
  modern('Modern', 'మోడర్న్', EdgeInsets.fromLTRB(40, 84, 40, 76), _all),
  wreath('Wreath', 'పూల వలయం', EdgeInsets.fromLTRB(42, 118, 42, 64), _all),
  // Greeting-card motifs (shown first for greetings, not on invitations).
  kites('Kites', 'గాలిపటాలు', EdgeInsets.fromLTRB(40, 150, 40, 86), _hindu, false, true),
  balloons('Balloons', 'బెలూన్లు', EdgeInsets.fromLTRB(40, 138, 40, 132), _all, false, true),
  fireworks('Fireworks', 'బాణసంచా', EdgeInsets.fromLTRB(40, 150, 40, 104), _all, false, true),
  // Remembrance — sober, no festive motifs.
  deepaSmriti('Deepam', 'దీపం', EdgeInsets.fromLTRB(42, 132, 42, 92), _hindu, true),
  hilal('Crescent', 'నెలవంక', EdgeInsets.fromLTRB(42, 118, 42, 76), _muslim, true),
  candle('Candle & Lilies', 'కొవ్వొత్తి', EdgeInsets.fromLTRB(42, 96, 42, 150), _christian, true),
  serene('Serene', 'ప్రశాంతం', EdgeInsets.fromLTRB(42, 96, 42, 86), _all, true);

  const CardLayout(this.en, this.te, this.contentPadding, this.traditions,
      [this.remembrance = false, this.greetingOnly = false]);

  /// Festive motifs only offered on greeting cards.
  final bool greetingOnly;

  /// Sober designs used only for remembrance cards (and vice versa).
  final bool remembrance;
  final String en;
  final String te;

  /// Space left for ornaments around the text, on the 360 × 640 canvas.
  final EdgeInsets contentPadding;

  /// Communities this design suits (Hindu motifs aren't offered on a Nikah card).
  final Set<Tradition> traditions;

  /// Designs for a tradition: remembrance → sober ones only; greeting cards →
  /// the greeting motifs first, then all celebration designs.
  static List<CardLayout> forTradition(Tradition t, {bool remembrance = false, bool greeting = false}) => [
        if (greeting)
          for (final l in values)
            if (l.greetingOnly && l.traditions.contains(t)) l,
        for (final l in values)
          if (!l.greetingOnly && l.traditions.contains(t) && l.remembrance == remembrance) l,
      ];
}

const _hindu = {Tradition.hindu};
const _muslim = {Tradition.muslim};
const _christian = {Tradition.christian};
const _all = {Tradition.hindu, Tradition.muslim, Tradition.christian};

/// A colour theme for the card. Everything is drawn in code (gradients +
/// CustomPainter), so templates cost ~0 KB of app size — no image assets.
class CardTemplate {
  final String id;
  final String name;
  final String nameTe;
  final List<Color> background; // top → bottom gradient
  final Color frame; // border + ornaments
  final Color text; // body text
  final Color accent; // names, title, highlights
  final Color leaf; // mango leaves on the toran
  final Color marigold; // marigold flowers on the toran
  final Color marigoldCenter;

  // English fonts (Google Fonts family names, fetched once and cached).
  final String enTitleFont;
  final String enNameFont;
  final String enBodyFont;

  // Telugu fonts.
  final String teTitleFont;
  final String teBodyFont;

  /// Quiet colours for remembrance cards.
  final bool sober;

  const CardTemplate({
    required this.id,
    required this.name,
    required this.nameTe,
    required this.background,
    required this.frame,
    required this.text,
    required this.accent,
    required this.leaf,
    required this.marigold,
    required this.marigoldCenter,
    this.enTitleFont = 'Cinzel',
    this.enNameFont = 'Great Vibes',
    this.enBodyFont = 'Lora',
    this.teTitleFont = 'Ramabhadra',
    this.teBodyFont = 'Mandali',
    this.sober = false,
    this.traditions = _all,
    this.kids = false,
  });

  /// Blue (boy) / pink (girl) themes for children's functions.
  final bool kids;

  /// The colours a new card starts with: the tradition's own, or blue /
  /// pink for a boy's / girl's birthday, naming or first-rice ceremony.
  static CardTemplate defaultFor({
    required Tradition tradition,
    required bool remembrance,
    CeremonyId? ceremony,
    String? childGender,
  }) {
    const kidsFunctions = {CeremonyId.birthday, CeremonyId.barasala, CeremonyId.annaprasana};
    if (!remembrance && kidsFunctions.contains(ceremony) && (childGender == 'son' || childGender == 'daughter')) {
      final id = childGender == 'son' ? 'sky' : 'candy';
      return cardTemplates.firstWhere((t) => t.id == id);
    }
    return forCategory(remembrance: remembrance, tradition: tradition).first;
  }

  /// Traditions this colour theme suits best; they see it first.
  final Set<Tradition> traditions;

  /// Colour themes, the tradition's own first (Christian: whites; Muslim:
  /// emerald / mint / teal; Hindu: kumkum, pasupu, silk) and then the rest.
  static List<CardTemplate> forCategory({required bool remembrance, Tradition? tradition}) {
    final list = [for (final t in cardTemplates) if (t.sober == remembrance) t];
    if (tradition == null) return list;
    bool own(CardTemplate t) => t.traditions.length < 3 && t.traditions.contains(tradition);
    bool shared(CardTemplate t) => t.traditions.length == 3 && !t.kids;
    return [
      ...list.where(own),
      ...list.where(shared),
      ...list.where((t) => !own(t) && !shared(t) && !t.kids),
      ...list.where((t) => t.kids),
    ];
  }
}

const cardTemplates = <CardTemplate>[
  CardTemplate(
    id: 'kumkum',
    name: 'Kumkum',
    nameTe: 'కుంకుమ',
    background: [Color(0xFF8E1116), Color(0xFF4A0508)],
    frame: Color(0xFFE8B84A),
    text: Color(0xFFFBEBC8),
    accent: Color(0xFFFFD27A),
    leaf: Color(0xFF3E8E41),
    marigold: Color(0xFFFF9F1C),
    marigoldCenter: Color(0xFFE85D04),
    traditions: _hindu,
  ),
  CardTemplate(
    id: 'pasupu',
    name: 'Pasupu',
    nameTe: 'పసుపు',
    background: [Color(0xFFFFF6DC), Color(0xFFF9DD8C)],
    frame: Color(0xFF9C1C27),
    text: Color(0xFF4A1A12),
    accent: Color(0xFF8E1116),
    leaf: Color(0xFF2E7D32),
    marigold: Color(0xFFFB8500),
    marigoldCenter: Color(0xFFD62828),
    teTitleFont: 'Suranna',
    teBodyFont: 'Mandali',
    enTitleFont: 'Playfair Display',
    traditions: _hindu,
  ),
  CardTemplate(
    id: 'kanchi',
    name: 'Kanchi Silk',
    nameTe: 'కంచి పట్టు',
    background: [Color(0xFF5C0F3A), Color(0xFF2E0620)],
    frame: Color(0xFFD4AF37),
    text: Color(0xFFF6E7C1),
    accent: Color(0xFFF2C14E),
    leaf: Color(0xFF4CAF50),
    marigold: Color(0xFFFFB703),
    marigoldCenter: Color(0xFFFB8500),
    teTitleFont: 'NTR',
    teBodyFont: 'Mandali',
    traditions: _hindu,
  ),
  // ---- Children: boy (blue) and girl (pink) ----
  CardTemplate(
    id: 'sky',
    name: 'Sky Blue (boy)',
    nameTe: 'నీలం (అబ్బాయి)',
    background: [Color(0xFFEAF6FF), Color(0xFFC9E4FA)],
    frame: Color(0xFF2F80C9),
    text: Color(0xFF16324F),
    accent: Color(0xFF1565C0),
    leaf: Color(0xFF43A047),
    marigold: Color(0xFFFFC107),
    marigoldCenter: Color(0xFFFF7043),
    teTitleFont: 'Baloo Tammudu 2',
    enTitleFont: 'Fredoka',
    enNameFont: 'Pacifico',
    enBodyFont: 'Nunito',
    kids: true,
  ),
  CardTemplate(
    id: 'candy',
    name: 'Candy Pink (girl)',
    nameTe: 'గులాబీ (అమ్మాయి)',
    background: [Color(0xFFFFF0F6), Color(0xFFF9D0E3)],
    frame: Color(0xFFD6338A),
    text: Color(0xFF4A1530),
    accent: Color(0xFFC2185B),
    leaf: Color(0xFF66BB6A),
    marigold: Color(0xFFFFB300),
    marigoldCenter: Color(0xFFAB47BC),
    teTitleFont: 'Baloo Tammudu 2',
    enTitleFont: 'Fredoka',
    enNameFont: 'Pacifico',
    enBodyFont: 'Nunito',
    kids: true,
  ),
  // ---- Christian: white and light ----
  CardTemplate(
    id: 'pearl',
    name: 'Pearl White',
    nameTe: 'ముత్యపు తెలుపు',
    background: [Color(0xFFFFFFFF), Color(0xFFF2F4F8)],
    frame: Color(0xFFC9A54B),
    text: Color(0xFF2F3A4F),
    accent: Color(0xFF1F3A68),
    leaf: Color(0xFF6B8F71),
    marigold: Color(0xFFF4D3DA),
    marigoldCenter: Color(0xFFD98FA0),
    enTitleFont: 'Cormorant SC',
    enNameFont: 'Pinyon Script',
    enBodyFont: 'Cormorant Garamond',
    teTitleFont: 'Suranna',
    traditions: _christian,
  ),
  CardTemplate(
    id: 'lily',
    name: 'Lily Silver',
    nameTe: 'లిల్లీ వెండి',
    background: [Color(0xFFFDFDFB), Color(0xFFE9EDF2)],
    frame: Color(0xFF98A4B3),
    text: Color(0xFF34404F),
    accent: Color(0xFF3F6AA6),
    leaf: Color(0xFF7FA38A),
    marigold: Color(0xFFFFFFFF),
    marigoldCenter: Color(0xFFE8C66A),
    enTitleFont: 'Playfair Display',
    enNameFont: 'Great Vibes',
    teTitleFont: 'Suranna',
    traditions: _christian,
  ),
  CardTemplate(
    id: 'blush',
    name: 'Blush Rose',
    nameTe: 'గులాబీ',
    background: [Color(0xFFFFFBFB), Color(0xFFFAE6EA)],
    frame: Color(0xFFC79A57),
    text: Color(0xFF4A3036),
    accent: Color(0xFF9C3D54),
    leaf: Color(0xFF7E9F7B),
    marigold: Color(0xFFF3A6B6),
    marigoldCenter: Color(0xFFD06C86),
    enTitleFont: 'Cormorant SC',
    enNameFont: 'Parisienne',
    teTitleFont: 'Suranna',
    traditions: _christian,
  ),
  // ---- Muslim: emerald, mint and teal with gold ----
  CardTemplate(
    id: 'emerald',
    name: 'Emerald',
    nameTe: 'పచ్చ',
    background: [Color(0xFF0E4D3A), Color(0xFF052A1F)],
    frame: Color(0xFFD4AF37),
    text: Color(0xFFF0E8CF),
    accent: Color(0xFFF2CF63),
    leaf: Color(0xFF6FBF73),
    marigold: Color(0xFFF2CF63),
    marigoldCenter: Color(0xFFC9963A),
    enTitleFont: 'Cinzel',
    traditions: _muslim,
  ),
  CardTemplate(
    id: 'mint',
    name: 'Mint Ivory',
    nameTe: 'పుదీనా',
    background: [Color(0xFFFBFDF8), Color(0xFFE2F0E6)],
    frame: Color(0xFF1E7A5A),
    text: Color(0xFF1F3B30),
    accent: Color(0xFF0F6B4C),
    leaf: Color(0xFF2E8B57),
    marigold: Color(0xFFD4AF37),
    marigoldCenter: Color(0xFFB8860B),
    enTitleFont: 'Playfair Display',
    teTitleFont: 'Suranna',
    traditions: _muslim,
  ),
  CardTemplate(
    id: 'midnight',
    name: 'Midnight Teal',
    nameTe: 'నీలి రాత్రి',
    background: [Color(0xFF0B3C49), Color(0xFF05212A)],
    frame: Color(0xFFE0B85C),
    text: Color(0xFFEAF2F0),
    accent: Color(0xFFF5D48A),
    leaf: Color(0xFF5FB3A1),
    marigold: Color(0xFFF5D48A),
    marigoldCenter: Color(0xFFE0A84A),
    enTitleFont: 'Cinzel',
    traditions: _muslim,
  ),
  CardTemplate(
    id: 'malle',
    name: 'Malle (Ivory)',
    nameTe: 'మల్లె',
    background: [Color(0xFFFFFDF7), Color(0xFFF4ECDD)],
    frame: Color(0xFFB8893B),
    text: Color(0xFF3B2F2F),
    accent: Color(0xFF7A4A12),
    leaf: Color(0xFF558B2F),
    marigold: Color(0xFFFFB703),
    marigoldCenter: Color(0xFFF77F00),
    teTitleFont: 'Suranna',
    teBodyFont: 'Mandali',
    enTitleFont: 'Playfair Display',
  ),
  // ---- Remembrance (sober) ----
  CardTemplate(
    id: 'shanti',
    name: 'Shanti (White)',
    nameTe: 'శాంతి',
    background: [Color(0xFFFFFFFF), Color(0xFFF0F0EC)],
    frame: Color(0xFF8C8C86),
    text: Color(0xFF2F3133),
    accent: Color(0xFF3F434A),
    leaf: Color(0xFF7C8C6A),
    marigold: Color(0xFFF4F1E8),
    marigoldCenter: Color(0xFFE0A030),
    teTitleFont: 'Suranna',
    enTitleFont: 'Cormorant Garamond',
    enNameFont: 'Cormorant Garamond',
    enBodyFont: 'Cormorant Garamond',
    sober: true,
  ),
  CardTemplate(
    id: 'dhooli',
    name: 'Grey Blue',
    nameTe: 'బూడిద నీలం',
    background: [Color(0xFFF0F3F6), Color(0xFFDCE2E9)],
    frame: Color(0xFF6B7785),
    text: Color(0xFF2B3440),
    accent: Color(0xFF34404F),
    leaf: Color(0xFF6E8072),
    marigold: Color(0xFFF2F2EE),
    marigoldCenter: Color(0xFFE0A030),
    teTitleFont: 'Suranna',
    enTitleFont: 'Cormorant Garamond',
    enNameFont: 'Cormorant Garamond',
    enBodyFont: 'Cormorant Garamond',
    sober: true,
  ),
  CardTemplate(
    id: 'chandanam',
    name: 'Sandal',
    nameTe: 'చందనం',
    background: [Color(0xFFFBF7F0), Color(0xFFEEE4D3)],
    frame: Color(0xFF9C8461),
    text: Color(0xFF3E3326),
    accent: Color(0xFF5E4A30),
    leaf: Color(0xFF7D8A5C),
    marigold: Color(0xFFF7F2E6),
    marigoldCenter: Color(0xFFE0A030),
    teTitleFont: 'Suranna',
    enTitleFont: 'Cormorant Garamond',
    enNameFont: 'Cormorant Garamond',
    enBodyFont: 'Cormorant Garamond',
    sober: true,
  ),
];
