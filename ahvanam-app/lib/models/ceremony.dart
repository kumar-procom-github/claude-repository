import 'package:flutter/material.dart';

import 'greetings.dart';

/// What kind of input a field needs on the details form.
enum FieldKind { name, text, number, choice, lagnam, nakshatram }

class ChoiceOption {
  final String value;
  final String en;
  final String te;
  const ChoiceOption(this.value, this.en, this.te);
}

/// One input on the details form. Labels are shown in both languages.
class FieldSpec {
  final String key;
  final String en;
  final String te;
  final FieldKind kind;
  final bool required;
  final String? hint;
  final List<ChoiceOption> options;

  /// For ceremonies with several children (Baptism…): which child this
  /// field belongs to (1, 2, 3…). 0 = not a per-child field.
  final int childIndex;

  const FieldSpec(
    this.key,
    this.en,
    this.te, {
    this.kind = FieldKind.name,
    this.required = true,
    this.hint,
    this.options = const [],
    this.childIndex = 0,
  });

  FieldSpec copyWith({String? key, String? en, String? te, bool? required, int? childIndex}) => FieldSpec(
        key ?? this.key,
        en ?? this.en,
        te ?? this.te,
        kind: kind,
        required: required ?? this.required,
        hint: hint,
        options: options,
        childIndex: childIndex ?? this.childIndex,
      );

  /// Name-like fields get an auto-filled, editable Telugu version.
  bool get hasTeluguVariant => kind == FieldKind.name;
}

/// The three communities the app serves. Chosen on the first screen; it
/// decides which ceremonies, header lines, functions and designs are offered.
enum Tradition {
  hindu('Hindu', 'హిందూ', 'Pelli, Gruhapravesam, Barasala… · Pedda Karma, Vardhanthi, Jayanthi',
      'పెళ్లి, గృహప్రవేశం, బారసాల… · పెద్దకర్మ, వర్ధంతి, జయంతి', Icons.temple_hindu_outlined),
  muslim('Muslim', 'ముస్లిం', 'Nikah, Walima, Aqiqah, Iftar… · Chehlum, Barsi',
      'నిఖా, వలీమా, అఖీఖా, ఇఫ్తార్… · చెహల్లుమ్, బర్సీ', Icons.mosque_outlined),
  christian('Christian', 'క్రైస్తవ', 'Holy Matrimony, Baptism… · Memorial Service',
      'పరిశుద్ధ వివాహం, బాప్తిస్మం… · సంస్మరణ ఆరాధన', Icons.church_outlined);

  const Tradition(this.en, this.te, this.examples, this.examplesTe, this.icon);
  final String en;
  final String te;
  final String examples;
  final String examplesTe;
  final IconData icon;
}

/// Second level of the flow: happy occasions vs remembrance (death rites).
enum CeremonyCategory {
  celebration('Celebrations', 'వేడుకలు', Icons.celebration_outlined),
  remembrance('Remembrance', 'సంస్మరణ', Icons.local_florist_outlined),
  greeting('Greetings', 'శుభాకాంక్షలు', Icons.card_giftcard_outlined);

  const CeremonyCategory(this.en, this.te, this.icon);
  final String en;
  final String te;
  final IconData icon;

  /// Examples shown under the category for a tradition.
  String examplesFor(Tradition t, {bool te = false}) => te ? _examplesTe(t) : _examplesEn(t);

  String _examplesTe(Tradition t) => switch ((this, t)) {
        (CeremonyCategory.celebration, Tradition.hindu) => 'పెళ్లి, గృహప్రవేశం, బారసాల, వ్రతం…',
        (CeremonyCategory.celebration, Tradition.muslim) => 'నిఖా, వలీమా, అఖీఖా, ఇఫ్తార్…',
        (CeremonyCategory.celebration, Tradition.christian) => 'పరిశుద్ధ వివాహం, ప్రధానం, బాప్తిస్మం…',
        (CeremonyCategory.remembrance, Tradition.hindu) => 'పెద్దకర్మ, వర్ధంతి, జయంతి',
        (CeremonyCategory.remembrance, Tradition.muslim) => 'చెహల్లుమ్, బర్సీ',
        (CeremonyCategory.remembrance, Tradition.christian) => 'సంస్మరణ ఆరాధన, వర్ధంతి & జయంతి',
        (CeremonyCategory.greeting, Tradition.hindu) => 'సంక్రాంతి, ఉగాది, దీపావళి, పుట్టినరోజు…',
        (CeremonyCategory.greeting, Tradition.muslim) => 'రంజాన్, బక్రీద్, పుట్టినరోజు, నూతన సంవత్సరం…',
        (CeremonyCategory.greeting, Tradition.christian) => 'క్రిస్మస్, ఈస్టర్, పుట్టినరోజు, నూతన సంవత్సరం…',
      };

  String _examplesEn(Tradition t) => switch ((this, t)) {
        (CeremonyCategory.celebration, Tradition.hindu) => 'Pelli, Gruhapravesam, Barasala, Vratham…',
        (CeremonyCategory.celebration, Tradition.muslim) => 'Nikah, Walima, Aqiqah, Iftar…',
        (CeremonyCategory.celebration, Tradition.christian) => 'Holy Matrimony, Pradhanam, Baptism…',
        (CeremonyCategory.remembrance, Tradition.hindu) => 'Pedda Karma, Vardhanthi, Jayanthi',
        (CeremonyCategory.remembrance, Tradition.muslim) => 'Chehlum, Barsi',
        (CeremonyCategory.remembrance, Tradition.christian) => 'Memorial Service, death & birth anniversaries',
        (CeremonyCategory.greeting, Tradition.hindu) => 'Sankranti, Ugadi, Deepavali, Birthday, New Year…',
        (CeremonyCategory.greeting, Tradition.muslim) => 'Ramzan, Bakrid, Ramadan, Birthday, New Year…',
        (CeremonyCategory.greeting, Tradition.christian) => 'Christmas, Easter, Birthday, New Year…',
      };
}

/// The invocation line at the top of the card ("header"), per tradition.
enum Deity {
  none(null),
  // Hindu
  ganesha(Tradition.hindu),
  venkateswara(Tradition.hindu),
  shivaParvati(Tradition.hindu),
  sitaRama(Tradition.hindu),
  satyanarayana(Tradition.hindu),
  // Muslim
  bismillah(Tradition.muslim),
  n786(Tradition.muslim),
  // Christian
  cross(Tradition.christian),
  mark109(Tradition.christian),
  psalm23(Tradition.christian),
  // Solemn headers for remembrance cards.
  omShanti(Tradition.hindu, solemn: true),
  innaLillahi(Tradition.muslim, solemn: true),
  john1125(Tradition.christian, solemn: true);

  const Deity(this.tradition, {this.solemn = false});

  /// null = available for every tradition ("None").
  final Tradition? tradition;

  /// Only offered on remembrance cards.
  final bool solemn;

  static List<Deity> forTradition(Tradition t, {bool remembrance = false}) => [
        for (final d in values)
          if ((d.tradition == null || d.tradition == t) && (remembrance || !d.solemn)) d,
      ];
}

extension DeityLabel on Deity {
  String get en => switch (this) {
        Deity.none => 'None',
        Deity.ganesha => 'Lord Ganesha',
        Deity.venkateswara => 'Lord Venkateswara',
        Deity.shivaParvati => 'Shiva & Parvati',
        Deity.sitaRama => 'Sita Rama',
        Deity.satyanarayana => 'Satyanarayana Swamy',
        Deity.bismillah => 'Bismillah',
        Deity.n786 => '786',
        Deity.cross => 'Cross · In the name of Jesus',
        Deity.mark109 => 'Mark 10:9 (wedding verse)',
        Deity.psalm23 => 'Psalm 23:1',
        Deity.omShanti => 'Om Shanti',
        Deity.innaLillahi => 'Inna Lillahi…',
        Deity.john1125 => 'John 11:25',
      };
  String get te => switch (this) {
        Deity.none => 'వద్దు',
        Deity.ganesha => 'శ్రీ గణేశుడు',
        Deity.venkateswara => 'శ్రీ వేంకటేశ్వరుడు',
        Deity.shivaParvati => 'శివ పార్వతులు',
        Deity.sitaRama => 'సీతారాములు',
        Deity.satyanarayana => 'సత్యనారాయణ స్వామి',
        Deity.bismillah => 'బిస్మిల్లాహ్',
        Deity.n786 => '786',
        Deity.cross => 'శిలువ',
        Deity.mark109 => 'మార్కు 10:9',
        Deity.psalm23 => 'కీర్తన 23:1',
        Deity.omShanti => 'ఓం శాంతి',
        Deity.innaLillahi => 'ఇన్నా లిల్లాహి',
        Deity.john1125 => 'యోహాను 11:25',
      };
}

enum CeremonyId {
  wedding,
  engagement,
  housewarming,
  barasala,
  annaprasana,
  seemantham,
  upanayanam,
  shashtipoorthi,
  satyanarayana,
  birthday,
  // Muslim
  nikah,
  walima,
  mangni,
  aqiqah,
  iftar,
  // Christian
  holyMatrimony,
  betrothal,
  baptism,
  communion,
  houseBlessing,
  // Remembrance
  peddaKarma,
  vardhanthi,
  chehlum,
  barsi,
  memorialService,
  remembranceAnniversary,
  jayanthi,
  birthRemembrance,
  // Greetings (see greetings.dart)
  gSankranti,
  gUgadi,
  gSriRamaNavami,
  gVinayakaChavithi,
  gDasara,
  gDeepavali,
  gBathukamma,
  gHoli,
  gRakhi,
  gKrishnashtami,
  gShivaratri,
  gRamadan,
  gEidUlFitr,
  gBakrid,
  gMilad,
  gChristmas,
  gEaster,
  gNewYear,
  gBirthday,
  gAnniversary,
  gIndependence,
  gRepublic,
  gMothersDay,
  gFathersDay,
  gTeachersDay,
  gFriendship,
  gCongrats,
  gThankYou,
  gGetWell,
}

class Ceremony {
  final CeremonyId id;
  final String en;
  final String te;
  final IconData icon;
  final Deity defaultDeity;
  final bool showBlessingLine;

  /// Whether the user can add a schedule of functions (Haldi, Sangeet …),
  /// rendered as an extra card page.
  final bool supportsEvents;
  final List<FieldSpec> fields;

  /// Which communities see this ceremony (Birthday is shared by all).
  final Set<Tradition> traditions;

  /// Celebration (default) or remembrance.
  final CeremonyCategory category;

  /// More than 1 → the form has "+ Add another child" (siblings baptised
  /// together, twins…). The per-child fields are 'child' and 'childGender'.
  final int maxChildren;

  bool get isRemembrance => category == CeremonyCategory.remembrance;
  bool get isGreeting => category == CeremonyCategory.greeting;

  /// Design shown first in the preview (a CardLayout name), if any.
  final String? design;

  const Ceremony({
    required this.id,
    required this.en,
    required this.te,
    required this.icon,
    required this.fields,
    this.defaultDeity = Deity.ganesha,
    this.showBlessingLine = true,
    this.supportsEvents = false,
    this.traditions = const {Tradition.hindu},
    this.category = CeremonyCategory.celebration,
    this.maxChildren = 1,
    this.design,
  });

  /// The tradition this ceremony belongs to (first one for shared ceremonies).
  Tradition get mainTradition => traditions.first;
}

// ---- Reusable field specs -------------------------------------------------

const _groom = FieldSpec('groom', "Groom's name", 'వరుడి పేరు');
const _groomFather = FieldSpec('groomFather', "Groom's father", 'వరుడి తండ్రి');
const _groomMother = FieldSpec('groomMother', "Groom's mother", 'వరుడి తల్లి');
const _bride = FieldSpec('bride', "Bride's name", 'వధువు పేరు');
const _brideFather = FieldSpec('brideFather', "Bride's father", 'వధువు తండ్రి');
const _brideMother = FieldSpec('brideMother', "Bride's mother", 'వధువు తల్లి');
const _father = FieldSpec('father', "Father's name", 'తండ్రి పేరు');
const _mother = FieldSpec('mother', "Mother's name", 'తల్లి పేరు');
const _hosts = FieldSpec('hosts', 'Hosts (e.g. Ramesh & Lakshmi)', 'ఆతిథేయులు',
    hint: 'Ramesh & Lakshmi');
const _lagnam = FieldSpec('lagnam', 'Lagnam (optional)', 'లగ్నం',
    kind: FieldKind.lagnam, required: false);
const _nakshatram = FieldSpec('nakshatram', 'Nakshatram (optional)', 'నక్షత్రం',
    kind: FieldKind.nakshatram, required: false);
// Christian cards (Telugu Bible usage): పెండ్లి కుమారుడు / పెండ్లి కుమార్తె.
const _cGroom = FieldSpec('groom', "Bridegroom's name", 'పెండ్లి కుమారుని పేరు');
const _cGroomFather = FieldSpec('groomFather', "Bridegroom's father", 'పెండ్లి కుమారుని తండ్రి');
const _cGroomMother = FieldSpec('groomMother', "Bridegroom's mother", 'పెండ్లి కుమారుని తల్లి');
const _cBride = FieldSpec('bride', "Bride's name", 'పెండ్లి కుమార్తె పేరు');
const _cBrideFather = FieldSpec('brideFather', "Bride's father", 'పెండ్లి కుమార్తె తండ్రి');
const _cBrideMother = FieldSpec('brideMother', "Bride's mother", 'పెండ్లి కుమార్తె తల్లి');

// Muslim cards: Dulha / Dulhan, as Telugu-speaking Muslim families say it.
const _mGroom = FieldSpec('groom', 'Dulha (groom)', 'దుల్హా పేరు');
const _mGroomFather = FieldSpec('groomFather', "Dulha's father", 'దుల్హా తండ్రి');
const _mGroomMotherOpt = FieldSpec('groomMother', "Dulha's mother (optional)", 'దుల్హా తల్లి', required: false);
const _mBride = FieldSpec('bride', 'Dulhan (bride)', 'దుల్హన్ పేరు');
const _mBrideFather = FieldSpec('brideFather', "Dulhan's father", 'దుల్హన్ తండ్రి');
const _mBrideMotherOpt = FieldSpec('brideMother', "Dulhan's mother (optional)", 'దుల్హన్ తల్లి', required: false);

const _childOpt = FieldSpec('child', "Child's name (optional)", 'చిన్నారి పేరు', required: false);
const _deceased = FieldSpec('deceased', 'Name of the departed', 'దివంగతుల పేరు');
const _years = FieldSpec('years', 'Which anniversary (1, 2, 3…)', 'ఎన్నవ వర్ధంతి', kind: FieldKind.number);
const _birthYears = FieldSpec('years', 'Which birth anniversary (e.g. 75)', 'ఎన్నవ జయంతి', kind: FieldKind.number);

/// How the departed is related to the family sending the card.
const relations = <ChoiceOption>[
  ChoiceOption('father', 'Father', 'తండ్రిగారు'),
  ChoiceOption('mother', 'Mother', 'తల్లిగారు'),
  ChoiceOption('husband', 'Husband', 'భర్త'),
  ChoiceOption('wife', 'Wife', 'భార్య'),
  ChoiceOption('grandfather', 'Grandfather', 'తాతగారు'),
  ChoiceOption('grandmother', 'Grandmother', 'నానమ్మగారు'),
  ChoiceOption('brother', 'Brother', 'సోదరుడు'),
  ChoiceOption('sister', 'Sister', 'సోదరి'),
  ChoiceOption('son', 'Son', 'కుమారుడు'),
  ChoiceOption('daughter', 'Daughter', 'కుమార్తె'),
];
const femaleRelations = {'mother', 'wife', 'grandmother', 'sister', 'daughter'};
const _relation = FieldSpec('relation', 'The departed is our', 'మా', kind: FieldKind.choice, options: relations);

/// Birth order, written right after the parents' names on Telugu cards:
/// "… దంపతుల ప్రథమ కుమారుడు", "… ద్వితీయ కుమార్తె".
const birthOrders = <ChoiceOption>[
  ChoiceOption('', "Don't mention", 'చెప్పనవసరం లేదు'),
  ChoiceOption('only', 'Only', 'ఏకైక'),
  ChoiceOption('first', 'Eldest', 'ప్రథమ'),
  ChoiceOption('second', 'Second', 'ద్వితీయ'),
  ChoiceOption('third', 'Third', 'తృతీయ'),
  ChoiceOption('fourth', 'Fourth', 'చతుర్థ'),
  ChoiceOption('fifth', 'Fifth', 'పంచమ'),
  ChoiceOption('youngest', 'Youngest', 'కనిష్ఠ'),
];
// Education / job, printed in brackets under the name: "(B.Tech, Software Engineer)".
const _groomEdu = FieldSpec('groomEdu', "Groom's education / job (optional)", 'వరుడి చదువు / ఉద్యోగం',
    kind: FieldKind.text, required: false);
const _brideEdu = FieldSpec('brideEdu', "Bride's education / job (optional)", 'వధువు చదువు / ఉద్యోగం',
    kind: FieldKind.text, required: false);
const _cGroomEdu = FieldSpec('groomEdu', "Bridegroom's education / job (optional)", 'పెండ్లి కుమారుని చదువు / ఉద్యోగం',
    kind: FieldKind.text, required: false);
const _cBrideEdu = FieldSpec('brideEdu', "Bride's education / job (optional)", 'పెండ్లి కుమార్తె చదువు / ఉద్యోగం',
    kind: FieldKind.text, required: false);
const _mGroomEdu = FieldSpec('groomEdu', "Dulha's education / job (optional)", 'దుల్హా చదువు / ఉద్యోగం',
    kind: FieldKind.text, required: false);
const _mBrideEdu = FieldSpec('brideEdu', "Dulhan's education / job (optional)", 'దుల్హన్ చదువు / ఉద్యోగం',
    kind: FieldKind.text, required: false);

const _groomOrder = FieldSpec('groomOrder', 'Which son? (birth order)', 'ఎన్నవ కుమారుడు',
    kind: FieldKind.choice, required: false, options: birthOrders);
const _brideOrder = FieldSpec('brideOrder', 'Which daughter? (birth order)', 'ఎన్నవ కుమార్తె',
    kind: FieldKind.choice, required: false, options: birthOrders);
const _boyOrder = FieldSpec('boyOrder', 'Which son? (birth order)', 'ఎన్నవ కుమారుడు',
    kind: FieldKind.choice, required: false, options: birthOrders);
const _childOrder = FieldSpec('childOrder', 'Which child? (birth order)', 'ఎన్నవ సంతానం',
    kind: FieldKind.choice, required: false, options: birthOrders);

const _childGender = FieldSpec('childGender', 'Baby is a', 'శిశువు',
    kind: FieldKind.choice,
    options: [
      ChoiceOption('son', 'Boy', 'కుమారుడు'),
      ChoiceOption('daughter', 'Girl', 'కుమార్తె'),
    ]);

/// Birthday: boy or girl (also picks the card colours: blue / pink).
const _birthdayGender = FieldSpec('childGender', 'Boy or girl', 'అబ్బాయి / అమ్మాయి',
    kind: FieldKind.choice,
    options: [
      ChoiceOption('son', 'Boy', 'అబ్బాయి'),
      ChoiceOption('daughter', 'Girl', 'అమ్మాయి'),
    ]);
const _fatherOpt = FieldSpec('father', "Father's name (optional)", 'తండ్రి పేరు', required: false);
const _motherOpt = FieldSpec('mother', "Mother's name (optional)", 'తల్లి పేరు', required: false);

const ceremonies = <Ceremony>[
  Ceremony(
    id: CeremonyId.wedding,
    en: 'Wedding',
    te: 'పెళ్లి శుభలేఖ',
    icon: Icons.favorite,
    defaultDeity: Deity.venkateswara,
    supportsEvents: true,
    fields: [_groom, _groomEdu, _groomFather, _groomMother, _groomOrder, _bride, _brideEdu, _brideFather, _brideMother, _brideOrder, _lagnam, _nakshatram],
  ),
  Ceremony(
    id: CeremonyId.engagement,
    en: 'Engagement',
    te: 'నిశ్చితార్థం',
    icon: Icons.diamond_outlined,
    fields: [_groom, _groomEdu, _groomFather, _groomMother, _groomOrder, _bride, _brideEdu, _brideFather, _brideMother, _brideOrder],
  ),
  Ceremony(
    id: CeremonyId.housewarming,
    en: 'Housewarming',
    te: 'గృహప్రవేశం',
    icon: Icons.home_outlined,
    fields: [_hosts, _lagnam],
  ),
  Ceremony(
    id: CeremonyId.barasala,
    en: 'Naming Ceremony',
    te: 'బారసాల',
    icon: Icons.child_care,
    showBlessingLine: false,
    fields: [
      _father,
      _mother,
      _childGender,
      FieldSpec('child', "Baby's name (optional)", 'శిశువు పేరు', required: false),
      _childOrder,
    ],
  ),
  Ceremony(
    id: CeremonyId.annaprasana,
    en: 'Annaprasana',
    te: 'అన్నప్రాశన',
    icon: Icons.rice_bowl_outlined,
    showBlessingLine: false,
    fields: [FieldSpec('child', "Child's name", 'చిన్నారి పేరు'), _father, _mother, _childOrder],
  ),
  Ceremony(
    id: CeremonyId.seemantham,
    en: 'Seemantham',
    te: 'సీమంతం',
    icon: Icons.pregnant_woman,
    fields: [
      FieldSpec('wife', 'Mother-to-be', 'కాబోయే తల్లి'),
      FieldSpec('husband', 'Husband', 'భర్త'),
    ],
  ),
  Ceremony(
    id: CeremonyId.upanayanam,
    en: 'Upanayanam',
    te: 'ఉపనయనం',
    icon: Icons.self_improvement,
    fields: [FieldSpec('boy', "Boy's name", 'వటువు పేరు'), _father, _mother, _boyOrder, _lagnam],
  ),
  Ceremony(
    id: CeremonyId.shashtipoorthi,
    en: 'Shashtipoorthi (60th)',
    te: 'షష్టిపూర్తి',
    icon: Icons.celebration_outlined,
    fields: [FieldSpec('husband', 'Husband', 'భర్త'), FieldSpec('wife', 'Wife', 'భార్య')],
  ),
  Ceremony(
    id: CeremonyId.satyanarayana,
    en: 'Satyanarayana Vratham',
    te: 'సత్యనారాయణ వ్రతం',
    icon: Icons.temple_hindu_outlined,
    defaultDeity: Deity.satyanarayana,
    showBlessingLine: false,
    fields: [_hosts],
  ),
  Ceremony(
    id: CeremonyId.birthday,
    en: 'Birthday',
    te: 'పుట్టినరోజు',
    icon: Icons.cake_outlined,
    defaultDeity: Deity.none,
    showBlessingLine: false,
    traditions: {Tradition.hindu, Tradition.muslim, Tradition.christian},
    fields: [
      FieldSpec('child', 'Birthday person', 'పుట్టినరోజు జరుపుకునేవారు'),
      _birthdayGender,
      FieldSpec('age', 'Turning (age)', 'వయస్సు', kind: FieldKind.number),
      _fatherOpt,
      _motherOpt,
      _childOrder,
    ],
  ),

  // ---- Muslim -------------------------------------------------------------
  Ceremony(
    id: CeremonyId.nikah,
    en: 'Nikah (Wedding)',
    te: 'నిఖా',
    icon: Icons.favorite,
    defaultDeity: Deity.bismillah,
    showBlessingLine: false,
    supportsEvents: true,
    traditions: {Tradition.muslim},
    fields: [_mGroom, _mGroomEdu, _mGroomFather, _mGroomMotherOpt, _groomOrder, _mBride, _mBrideEdu, _mBrideFather, _mBrideMotherOpt, _brideOrder],
  ),
  Ceremony(
    id: CeremonyId.walima,
    en: 'Walima (Reception)',
    te: 'వలీమా',
    icon: Icons.restaurant_outlined,
    defaultDeity: Deity.bismillah,
    showBlessingLine: false,
    traditions: {Tradition.muslim},
    fields: [_mGroom, _mGroomEdu, _mBride, _mBrideEdu, _mGroomFather, _mGroomMotherOpt],
  ),
  Ceremony(
    id: CeremonyId.mangni,
    en: 'Mangni (Engagement)',
    te: 'మంగ్నీ',
    icon: Icons.diamond_outlined,
    defaultDeity: Deity.bismillah,
    showBlessingLine: false,
    traditions: {Tradition.muslim},
    fields: [_mGroom, _mGroomEdu, _mGroomFather, _mGroomMotherOpt, _groomOrder, _mBride, _mBrideEdu, _mBrideFather, _mBrideMotherOpt, _brideOrder],
  ),
  Ceremony(
    id: CeremonyId.aqiqah,
    en: 'Aqiqah',
    te: 'అఖీఖా',
    icon: Icons.child_care,
    defaultDeity: Deity.bismillah,
    showBlessingLine: false,
    traditions: {Tradition.muslim},
    maxChildren: 5, // twins
    fields: [_father, _mother, _childGender, _childOpt, _childOrder],
  ),
  Ceremony(
    id: CeremonyId.iftar,
    en: 'Iftar Dawat',
    te: 'ఇఫ్తార్ విందు',
    icon: Icons.nightlight_outlined,
    defaultDeity: Deity.bismillah,
    showBlessingLine: false,
    traditions: {Tradition.muslim},
    fields: [_hosts],
  ),

  // ---- Christian ----------------------------------------------------------
  Ceremony(
    id: CeremonyId.holyMatrimony,
    en: 'Holy Matrimony',
    te: 'పరిశుద్ధ వివాహం',
    icon: Icons.favorite,
    defaultDeity: Deity.mark109,
    showBlessingLine: false,
    supportsEvents: true,
    traditions: {Tradition.christian},
    fields: [_cGroom, _cGroomEdu, _cGroomFather, _cGroomMother, _groomOrder, _cBride, _cBrideEdu, _cBrideFather, _cBrideMother, _brideOrder],
  ),
  Ceremony(
    id: CeremonyId.betrothal,
    en: 'Engagement (Pradhanam)',
    te: 'ప్రధానం',
    icon: Icons.diamond_outlined,
    defaultDeity: Deity.cross,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    fields: [_cGroom, _cGroomEdu, _cGroomFather, _cGroomMother, _groomOrder, _cBride, _cBrideEdu, _cBrideFather, _cBrideMother, _brideOrder],
  ),
  Ceremony(
    id: CeremonyId.baptism,
    en: 'Baptism',
    te: 'బాప్తిస్మం',
    icon: Icons.water_drop_outlined,
    defaultDeity: Deity.cross,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    maxChildren: 5,
    fields: [_father, _mother, _childGender, _childOpt, _childOrder],
  ),
  Ceremony(
    id: CeremonyId.communion,
    en: 'First Holy Communion',
    te: 'ప్రథమ దివ్య సత్ప్రసాదం',
    icon: Icons.wine_bar_outlined,
    defaultDeity: Deity.cross,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    maxChildren: 5,
    fields: [_father, _mother, _childGender, FieldSpec('child', "Child's name", 'చిన్నారి పేరు'), _childOrder],
  ),
  Ceremony(
    id: CeremonyId.houseBlessing,
    en: 'House Blessing',
    te: 'గృహ ప్రతిష్ఠ ఆరాధన',
    icon: Icons.home_outlined,
    defaultDeity: Deity.psalm23,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    fields: [_hosts],
  ),

  // ---- Remembrance ---------------------------------------------------------
  Ceremony(
    id: CeremonyId.peddaKarma,
    en: 'Pedda Karma',
    te: 'పెద్దకర్మ',
    icon: Icons.local_florist_outlined,
    defaultDeity: Deity.omShanti,
    showBlessingLine: false,
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation],
  ),
  Ceremony(
    id: CeremonyId.vardhanthi,
    en: 'Vardhanthi (Death Anniversary)',
    te: 'వర్ధంతి',
    icon: Icons.event_repeat_outlined,
    defaultDeity: Deity.omShanti,
    showBlessingLine: false,
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation, _years],
  ),
  Ceremony(
    id: CeremonyId.jayanthi,
    en: 'Jayanthi (Birth Anniversary)',
    te: 'జయంతి',
    icon: Icons.cake_outlined,
    defaultDeity: Deity.omShanti,
    showBlessingLine: false,
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation, _birthYears],
  ),
  Ceremony(
    id: CeremonyId.chehlum,
    en: 'Chehlum (40th day)',
    te: 'చెహల్లుమ్',
    icon: Icons.local_florist_outlined,
    defaultDeity: Deity.innaLillahi,
    showBlessingLine: false,
    traditions: {Tradition.muslim},
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation],
  ),
  Ceremony(
    id: CeremonyId.barsi,
    en: 'Barsi (Death Anniversary)',
    te: 'బర్సీ',
    icon: Icons.event_repeat_outlined,
    defaultDeity: Deity.innaLillahi,
    showBlessingLine: false,
    traditions: {Tradition.muslim},
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation, _years],
  ),
  Ceremony(
    id: CeremonyId.memorialService,
    en: 'Memorial Service',
    te: 'సంస్మరణ ఆరాధన',
    icon: Icons.local_florist_outlined,
    defaultDeity: Deity.john1125,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation],
  ),
  Ceremony(
    id: CeremonyId.remembranceAnniversary,
    en: 'Remembrance Anniversary',
    te: 'జ్ఞాపకార్థ వర్ధంతి ఆరాధన',
    icon: Icons.event_repeat_outlined,
    defaultDeity: Deity.john1125,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation, _years],
  ),
  Ceremony(
    id: CeremonyId.birthRemembrance,
    en: 'Birth Anniversary Remembrance',
    te: 'జన్మదిన జ్ఞాపకార్థ ఆరాధన',
    icon: Icons.cake_outlined,
    defaultDeity: Deity.john1125,
    showBlessingLine: false,
    traditions: {Tradition.christian},
    category: CeremonyCategory.remembrance,
    fields: [_deceased, _relation, _birthYears],
  ),
];

/// Invitations + greeting cards.
final List<Ceremony> allCeremonies = [...ceremonies, ...greetingCeremonies];

List<Ceremony> ceremoniesFor(Tradition t, [CeremonyCategory? category]) => [
      for (final c in allCeremonies)
        if (c.traditions.contains(t) && (category == null || c.category == category)) c,
    ];

Ceremony ceremonyById(CeremonyId id) => allCeremonies.firstWhere((c) => c.id == id);
