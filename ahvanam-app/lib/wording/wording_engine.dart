import '../models/astro.dart';
import '../models/ceremony.dart';
import '../models/greetings.dart';
import '../models/invitation_draft.dart';
import 'card_text.dart';
import 'dates.dart';

/// Writes the invitation text, fully offline.
///
/// Telugu follows the traditional శుభలేఖ structure (blessing line, deity,
/// parents → honorific + name, muhurtham sentence, request to bless,
/// venue, ఆహ్వానించువారు). English follows Indian-English conventions in a
/// traditional (Chi./S/o/Sri/Smt.) or modern tone.
///
/// NOTE: have a native Telugu speaker review these strings before release.
class WordingEngine {
  WordingEngine._();

  static CardText telugu(InvitationDraft d) => CardText(_Te(d).build(), telugu: true);
  static CardText english(InvitationDraft d) => CardText(_En(d).build(), telugu: false);

  /// The "schedule of functions" page (Haldi, Sangeet, Muhurtham, Reception …).
  static CardText scheduleTelugu(InvitationDraft d) => CardText(_schedule(d, true), telugu: true);
  static CardText scheduleEnglish(InvitationDraft d) => CardText(_schedule(d, false), telugu: false);

  /// Faces to render for the chosen language mode, in order.
  static List<CardText> faces(InvitationDraft d) {
    final te = [telugu(d), if (d.hasSchedule) scheduleTelugu(d)];
    final en = [english(d), if (d.hasSchedule) scheduleEnglish(d)];
    return switch (d.language) {
      CardLanguage.english => en,
      CardLanguage.telugu => te,
      CardLanguage.both => d.teluguFirst ? [...te, ...en] : [...en, ...te],
    };
  }

  static List<CardLine> _schedule(InvitationDraft d, bool te) {
    final l = <CardLine>[];
    void add(String text, LineRole role) {
      if (text.trim().isNotEmpty) l.add(CardLine(text, role));
    }

    final trad = d.tone == EnglishTone.traditional;
    if (te) {
      add('శుభ కార్యక్రమాలు', LineRole.title);
      final hindu = d.tradition == Tradition.hindu;
      add(
          hindu
              ? 'చి॥ ${d.teOrEn('groom')}  ♥  చి॥ల॥సౌ॥ ${d.teOrEn('bride')}'
              : '${d.teOrEn('groom')}  ♥  ${d.teOrEn('bride')}',
          LineRole.small);
    } else {
      add(trad ? 'Wedding Functions' : 'Wedding Celebrations', LineRole.title);
      add('${d.enValue('groom')}  ♥  ${d.enValue('bride')}', LineRole.small);
    }
    l.add(const CardLine('', LineRole.spacer));

    for (final e in d.sortedEvents) {
      add(te ? e.nameTe : e.nameEn, LineRole.event);
      if (e.date != null) {
        if (te) {
          add(InviteDates.teWhen(e.date, e.time), LineRole.highlight);
        } else {
          final t = e.time == null ? '' : ' · ${InviteDates.enTime(e.time!)}';
          add('${InviteDates.enDate(e.date!)}$t', LineRole.highlight);
        }
      }
      // Empty venue means "same as the main venue".
      String pick(List<String> options) =>
          options.firstWhere((s) => s.trim().isNotEmpty, orElse: () => '');
      add(te ? pick([e.venueTe, e.venue, d.venueTe, d.venue]) : pick([e.venue, d.venue]), LineRole.value);
      l.add(const CardLine('', LineRole.spacer));
    }

    add(
      te
          ? 'అన్ని కార్యక్రమాలకు తాము సకుటుంబంగా విచ్చేయవలసినదిగా ప్రార్థన.'
          : (trad
              ? 'We request your gracious presence at all the functions.'
              : 'We can’t wait to celebrate with you!'),
      LineRole.closing,
    );
    return l;
  }
}

// ---------------------------------------------------------------------------
// Telugu
// ---------------------------------------------------------------------------

class _Te {
  _Te(this.d);
  final InvitationDraft d;
  final _l = <CardLine>[];

  String v(String key) => d.teOrEn(key);
  void add(String text, LineRole role) {
    if (text.trim().isNotEmpty) _l.add(CardLine(text, role));
  }

  void space() => _l.add(const CardLine('', LineRole.spacer));

  String get when => InviteDates.teWhen(d.date, d.time);

  /// రోహిణి నక్షత్రయుక్త వృషభ లగ్నమందు / వృషభ లగ్న శుభముహూర్తమున / శుభముహూర్తమున
  String get muhurtham {
    if (d.en['lagnam'] == kOwnMuhurtham) {
      final own = (d.te['muhurthamOwn'] ?? '').trim();
      return own.isEmpty ? 'శుభముహూర్తమున' : own;
    }
    final lag = findAstro(lagnams, d.en['lagnam']);
    final nak = findAstro(nakshatrams, d.en['nakshatram']);
    if (lag != null && nak != null) return '${nak.te} నక్షత్రయుక్త ${lag.te} లగ్నమందు';
    if (lag != null) return '${lag.te} లగ్న శుభముహూర్తమున';
    return 'శుభముహూర్తమున';
  }

  String parents(String fatherKey, String motherKey) =>
      'శ్రీ ${v(fatherKey)} - శ్రీమతి ${v(motherKey)} దంపతుల';

  // ---- remembrance helpers ----
  ChoiceOption get _rel =>
      relations.firstWhere((o) => o.value == d.en['relation'], orElse: () => relations.first);
  bool get _female => femaleRelations.contains(d.en['relation']);
  String get relTe => _rel.te;
  static const _grief = 'దుఃఖతప్త హృదయాలతో';

  /// ప్రథమ, ద్వితీయ, తృతీయ … for anniversaries.
  String get yearsTe {
    final n = int.tryParse(d.enValue('years')) ?? 1;
    return switch (n) { 1 => 'ప్రథమ', 2 => 'ద్వితీయ', 3 => 'తృతీయ', 4 => 'చతుర్థ', 5 => 'పంచమ', _ => '$nవ' };
  }

  /// Muslim parents: జనాబ్ … - బేగం … దంపతుల (mother optional on Muslim cards).
  String mParents(String fatherKey, String motherKey) => v(motherKey).isEmpty
      ? 'జనాబ్ ${v(fatherKey)} గారి'
      : 'జనాబ్ ${v(fatherKey)} - బేగం ${v(motherKey)} దంపతుల';

  static const _bless = 'కావున తాము సకుటుంబ సపరివార సమేతంగా విచ్చేసి';

  /// Birth order before కుమారుడు / కుమార్తె: "ప్రథమ ", "ఏకైక " … or "".
  String ord(String key) => _ordTe(d.en[key] ?? '');
  static String _ordTe(String value) {
    if (value.isEmpty) return '';
    final o = birthOrders.where((x) => x.value == value);
    return o.isEmpty ? '' : '${o.first.te} ';
  }

  // ---- children (one or several) ----
  bool get _many => d.childCount > 1;

  /// Son / daughter / sons / daughters / children in the given case:
  /// [forms] = (son, daughter, sons, daughters, mixed).
  /// One child: the birth order goes in front (ప్రథమ కుమారునికి).
  String kidWord((String, String, String, String, String) forms) {
    final kids = d.children;
    if (kids.length == 1) return '${_ordTe(kids.first.order)}${kids.first.son ? forms.$1 : forms.$2}';
    if (kids.every((k) => k.son)) return forms.$3;
    if (kids.every((k) => !k.son)) return forms.$4;
    return forms.$5;
  }

  /// "A", "A మరియు B", "A, B మరియు C". With several children each name
  /// carries its birth order: "A (ప్రథమ కుమారుడు)".
  String get kidNames {
    final n = [
      for (final k in d.children)
        if (k.te.isNotEmpty)
          _many && k.order.isNotEmpty ? '${k.te} (${_ordTe(k.order)}${k.son ? 'కుమారుడు' : 'కుమార్తె'})' : k.te
    ];
    if (n.length <= 1) return n.join();
    return '${n.sublist(0, n.length - 1).join(', ')} మరియు ${n.last}';
  }

  void header(String title) {
    add(title, LineRole.title);
    if (d.ceremony.showBlessingLine) add('శ్రీరస్తు  శుభమస్తు  అవిఘ్నమస్తు', LineRole.blessing);
    add(_deityTe(d.deity), LineRole.deity);
    space();
  }

  /// "(B.Tech, Software Engineer)" under a name, if given.
  void edu(String key) {
    final e = d.enValue(key);
    if (e.isNotEmpty) add('($e)', LineRole.small);
  }

  /// మధ్యాహ్న భోజనం / రాత్రి విందు line, if the host chose one.
  void meal() {
    // Remembrance cards say భోజనం (meal), never విందు (feast).
    final quiet = d.ceremony.isRemembrance;
    final label = switch (d.meal) {
      'breakfast' => 'అల్పాహారం (టిఫిన్)',
      'lunch' => 'మధ్యాహ్న భోజనం',
      'dinner' => quiet ? 'రాత్రి భోజనం' : 'రాత్రి విందు',
      _ => '',
    };
    if (label.isEmpty) return;
    space();
    _l.add(const CardLine('meal', LineRole.icon));
    final t = d.mealTime;
    add(t == null ? '$label ఏర్పాటు చేయబడినది.' : '$label: ${InviteDates.teTime(t).replaceAll('గం॥లకు', 'గం॥ల నుండి')}',
        LineRole.highlight);
    // No separate place → the meal is at the main venue: print that.
    final place = [d.mealVenueTe, d.mealVenue, d.venueTe, d.venue]
        .map((s) => s.trim())
        .firstWhere((s) => s.isNotEmpty, orElse: () => '');
    // "మా స్వగృహం నందు" already says where, so it needs no "స్థలం:" label.
    if (place.isNotEmpty) add(place.endsWith('నందు') ? place : 'స్థలం: $place', LineRole.small);
  }

  void footer({String venueLabel = 'వేదిక', String? fallbackInviters, String inviterLabel = 'ఆహ్వానించువారు'}) {
    meal();
    space();
    add(venueLabel, LineRole.label);
    add(d.venueTe.trim().isNotEmpty ? d.venueTe : d.venue, LineRole.value);
    final inv = d.invitersTe.trim().isNotEmpty
        ? d.invitersTe
        : (d.inviters.trim().isNotEmpty ? d.inviters : (fallbackInviters ?? ''));
    if (inv.trim().isNotEmpty) {
      space();
      add(inviterLabel, LineRole.label);
      add(inv, LineRole.value);
    }
  }

  List<CardLine> build() {
    switch (d.ceremony.id) {
      case CeremonyId.wedding:
        header('శుభలేఖ');
        add('${parents('groomFather', 'groomMother')} ${ord('groomOrder')}కుమారుడు', LineRole.small);
        add('చి॥ ${v('groom')}', LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add('${parents('brideFather', 'brideMother')} ${ord('brideOrder')}కుమార్తె', LineRole.small);
        add('చి॥ల॥సౌ॥ ${v('bride')}', LineRole.name);
        edu('brideEdu');
        space();
        add('వీరి వివాహము', LineRole.body);
        add(when, LineRole.highlight);
        add('$muhurtham జరుపుటకు దైవజ్ఞులచే నిశ్చయించబడినది.', LineRole.body);
        add('$_bless, వధూవరులను ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.engagement:
        header('నిశ్చితార్థ ఆహ్వానం');
        add('${parents('groomFather', 'groomMother')} ${ord('groomOrder')}కుమారుడు', LineRole.small);
        add('చి॥ ${v('groom')}', LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add('${parents('brideFather', 'brideMother')} ${ord('brideOrder')}కుమార్తె', LineRole.small);
        add('చి॥ల॥సౌ॥ ${v('bride')}', LineRole.name);
        edu('brideEdu');
        space();
        add('వీరి నిశ్చితార్థ మహోత్సవము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('$_bless, కాబోయే వధూవరులను ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.housewarming:
        header('గృహప్రవేశ ఆహ్వానం');
        add('మా నూతన గృహప్రవేశ మహోత్సవము', LineRole.body);
        add(when, LineRole.highlight);
        add('$muhurtham జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('$_bless, మమ్ములను ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer(venueLabel: 'నూతన గృహం', fallbackInviters: v('hosts'));

      case CeremonyId.barasala:
        final sonBarasala = d.en['childGender'] != 'daughter';
        header('బారసాల ఆహ్వానం');
        add('${parents('father', 'mother')} ${ord('childOrder')}${sonBarasala ? 'కుమారునికి' : 'కుమార్తెకు'}', LineRole.small);
        add('నామకరణ మహోత్సవము (బారసాల)', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        if (v('child').isNotEmpty) add('చి॥ ${v('child')}', LineRole.name);
        add('$_bless, చిన్నారిని ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.annaprasana:
        header('అన్నప్రాశన ఆహ్వానం');
        add('${parents('father', 'mother')} ${ord('childOrder').isEmpty ? 'ముద్దుల చిన్నారి' : '${ord('childOrder')}సంతానం'}', LineRole.small);
        add('చి॥ ${v('child')}', LineRole.name);
        add('యొక్క అన్నప్రాశన మహోత్సవము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('$_bless, చిన్నారిని ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.seemantham:
        header('సీమంత ఆహ్వానం');
        add('శ్రీ ${v('husband')} గారి ధర్మపత్ని', LineRole.small);
        add('సౌ॥ ${v('wife')}', LineRole.name);
        add('యొక్క సీమంత మహోత్సవము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('$_bless, తల్లీబిడ్డలను ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.upanayanam:
        header('ఉపనయన ఆహ్వానం');
        add('${parents('father', 'mother')} ${ord('boyOrder')}కుమారుడు', LineRole.small);
        add('చి॥ ${v('boy')}', LineRole.name);
        add('యొక్క ఉపనయన మహోత్సవము', LineRole.body);
        add(when, LineRole.highlight);
        add('$muhurtham జరుపుటకు దైవజ్ఞులచే నిశ్చయించబడినది.', LineRole.body);
        add('$_bless, వటువును ఆశీర్వదించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.shashtipoorthi:
        header('షష్టిపూర్తి ఆహ్వానం');
        add('మా తల్లిదండ్రులు', LineRole.small);
        add('శ్రీ ${v('husband')} - శ్రీమతి ${v('wife')}', LineRole.name);
        add('గార్ల షష్టిపూర్తి మహోత్సవము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('$_bless, కార్యక్రమాన్ని జయప్రదం చేయవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer();

      case CeremonyId.satyanarayana:
        header('శ్రీ సత్యనారాయణ స్వామి వ్రతం');
        add('మా గృహమునందు శ్రీ సత్యనారాయణ స్వామి వ్రతము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('$_bless, స్వామివారి తీర్థప్రసాదములు స్వీకరించవలసినదిగా ప్రార్థన.', LineRole.closing);
        footer(fallbackInviters: v('hosts'));

      case CeremonyId.birthday:
        header('పుట్టినరోజు ఆహ్వానం');
        final sonB = d.en['childGender'] != 'daughter';
        final fB = v('father'), mB = v('mother');
        // With parents: "శ్రీ రమేష్ - శ్రీమతి లక్ష్మి దంపతుల ప్రథమ కుమారుడు".
        final whoseB = fB.isNotEmpty && mB.isNotEmpty
            ? parents('father', 'mother')
            : (fB.isNotEmpty ? 'శ్రీ $fB గారి' : (mB.isNotEmpty ? 'శ్రీమతి $mB గారి' : ''));
        add(whoseB.isEmpty ? 'మా ప్రియమైన' : '$whoseB ${ord('childOrder')}${sonB ? 'కుమారుడు' : 'కుమార్తె'}',
            LineRole.small);
        add(v('child'), LineRole.name);
        final age = d.enValue('age');
        add(age.isEmpty ? 'పుట్టినరోజు వేడుకలు' : '$ageవ పుట్టినరోజు వేడుకలు', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుకొనుచున్నాము.', LineRole.body);
        add('తాము తప్పక విచ్చేసి, ఆశీర్వదించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer();

      // ---------------- Muslim ----------------
      case CeremonyId.nikah:
        header('నిఖా ఆహ్వానం');
        add('${mParents('groomFather', 'groomMother')} ${ord('groomOrder')}కుమారుడు', LineRole.small);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add('${mParents('brideFather', 'brideMother')} ${ord('brideOrder')}కుమార్తె', LineRole.small);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        space();
        add('వీరి నిఖా', LineRole.body);
        add(when, LineRole.highlight);
        add('ఇన్‌షా అల్లాహ్ జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('కావున తాము సకుటుంబ సమేతంగా విచ్చేసి, వధూవరులకు మీ దువాలు అందించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer();

      case CeremonyId.walima:
        header('దావత్-ఎ-వలీమా');
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        add('వీరి నిఖా సందర్భంగా ఏర్పాటు చేసిన వలీమా విందు', LineRole.body);
        add(when, LineRole.highlight);
        add('ఇన్‌షా అల్లాహ్ జరుగును.', LineRole.body);
        add('కావున తాము సకుటుంబ సమేతంగా విచ్చేసి, నూతన దంపతులకు మీ దువాలు అందించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(fallbackInviters: '${mParents('groomFather', 'groomMother').replaceAll(' దంపతుల', '').replaceAll(' గారి', '')} & కుటుంబ సభ్యులు');

      case CeremonyId.mangni:
        header('మంగ్నీ (నిశ్చితార్థ) ఆహ్వానం');
        add('${mParents('groomFather', 'groomMother')} ${ord('groomOrder')}కుమారుడు', LineRole.small);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add('${mParents('brideFather', 'brideMother')} ${ord('brideOrder')}కుమార్తె', LineRole.small);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        space();
        add('వీరి మంగ్నీ వేడుక', LineRole.body);
        add(when, LineRole.highlight);
        add('ఇన్‌షా అల్లాహ్ జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('కావున తాము సకుటుంబ సమేతంగా విచ్చేసి, కాబోయే వధూవరులకు మీ దువాలు అందించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer();

      case CeremonyId.aqiqah:
        header('అఖీఖా ఆహ్వానం');
        add('${mParents('father', 'mother')} ${kidWord(('కుమారుని', 'కుమార్తె', 'కుమారుల', 'కుమార్తెల', 'పిల్లల'))}', LineRole.small);
        add(kidNames, LineRole.name);
        add('అఖీఖా వేడుక', LineRole.body);
        add(when, LineRole.highlight);
        add('ఇన్‌షా అల్లాహ్ జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('తాము సకుటుంబ సమేతంగా విచ్చేసి, ${_many ? 'చిన్నారులకు' : 'చిన్నారికి'} మీ దువాలు అందించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer();

      case CeremonyId.iftar:
        header('ఇఫ్తార్ విందు ఆహ్వానం');
        add('పవిత్ర రంజాన్ మాసం సందర్భంగా మా ఇంట ఏర్పాటు చేసిన ఇఫ్తార్ విందు', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము సకుటుంబ సమేతంగా విచ్చేయవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(fallbackInviters: v('hosts'));

      // ---------------- Christian ----------------
      case CeremonyId.holyMatrimony:
        header('పరిశుద్ధ వివాహ ఆహ్వానం');
        add('${parents('groomFather', 'groomMother')} ${ord('groomOrder')}కుమారుడు', LineRole.small);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add('${parents('brideFather', 'brideMother')} ${ord('brideOrder')}కుమార్తె', LineRole.small);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        space();
        add('వీరి వివాహము ప్రభువు చిత్తమైతే', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('కావున తాము సకుటుంబ సమేతంగా విచ్చేసి, నూతన దంపతులను ప్రభువునందు ఆశీర్వదించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక');

      case CeremonyId.betrothal:
        header('ప్రధాన ఆహ్వానం');
        add('${parents('groomFather', 'groomMother')} ${ord('groomOrder')}కుమారుడు', LineRole.small);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add('మరియు', LineRole.connector);
        add('${parents('brideFather', 'brideMother')} ${ord('brideOrder')}కుమార్తె', LineRole.small);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        space();
        add('వీరి ప్రధాన ఆరాధన ప్రభువు చిత్తమైతే', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('కావున తాము సకుటుంబ సమేతంగా విచ్చేసి, కాబోయే దంపతులను ప్రభువునందు ఆశీర్వదించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక');

      case CeremonyId.baptism:
        header('బాప్తిస్మ ఆహ్వానం');
        add('${parents('father', 'mother')} ${kidWord(('కుమారునికి', 'కుమార్తెకు', 'కుమారులకు', 'కుమార్తెలకు', 'పిల్లలకు'))}', LineRole.small);
        add(kidNames, LineRole.name);
        add('బాప్తిస్మ ఆరాధన', LineRole.body);
        add(when, LineRole.highlight);
        add('ప్రభువు చిత్తమైతే జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, ${_many ? 'చిన్నారులను' : 'చిన్నారిని'} ప్రభువునందు ఆశీర్వదించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక');

      case CeremonyId.communion:
        header('ప్రథమ దివ్య సత్ప్రసాద ఆహ్వానం');
        add('${parents('father', 'mother')} ${kidWord(('కుమారుడు', 'కుమార్తె', 'కుమారులు', 'కుమార్తెలు', 'పిల్లలు'))}', LineRole.small);
        add(kidNames, LineRole.name);
        add('యొక్క ప్రథమ దివ్య సత్ప్రసాద స్వీకరణ', LineRole.body);
        add(when, LineRole.highlight);
        add('ప్రభువు చిత్తమైతే జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, ${_many ? 'చిన్నారులను' : 'చిన్నారిని'} ప్రభువునందు ఆశీర్వదించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక');

      case CeremonyId.houseBlessing:
        header('నూతన గృహ ప్రతిష్ఠ ఆరాధన');
        add('ప్రభువు కృపవలన మా నూతన గృహ ప్రతిష్ఠ ఆరాధన', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('కావున తాము సకుటుంబ సమేతంగా విచ్చేసి, ప్రార్థనలో పాల్గొనవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'నూతన గృహం', fallbackInviters: v('hosts'));

      // ---------------- Remembrance ----------------
      case CeremonyId.peddaKarma:
        header('పెద్దకర్మ');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('కీ.శే. ${v('deceased')}', LineRole.name);
        add('గారు ఇటీవల పరమపదించినారు. వారి పెద్దకర్మ', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుపుటకు నిశ్చయించితిమి.', LineRole.body);
        add('కావున తాము విచ్చేసి, వారి ఆత్మకు శాంతి కలగాలని ప్రార్థించవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.vardhanthi:
        header('$yearsTe వర్ధంతి');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('కీ.శే. ${v('deceased')}', LineRole.name);
        add('గారి $yearsTe వర్ధంతి కార్యక్రమము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, వారిని స్మరించుకొనవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.chehlum:
        header('చెహల్లుమ్');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('${_female ? 'మర్హూమా' : 'మర్హూమ్'} ${v('deceased')}', LineRole.name);
        add('గారి చెహల్లుమ్ (40వ రోజు) ఫాతిహా', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, మర్హూమ్ మగ్ఫిరత్ కొరకు దువా చేయవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.barsi:
        header('$yearsTe బర్సీ');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('${_female ? 'మర్హూమా' : 'మర్హూమ్'} ${v('deceased')}', LineRole.name);
        add('గారి $yearsTe బర్సీ సందర్భంగా ఫాతిహా', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, ఫాతిహా మరియు దువాలో పాల్గొనవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.memorialService:
        header('సంస్మరణ ఆరాధన');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('దివంగత ${v('deceased')}', LineRole.name);
        add('గారు ప్రభువునందు నిద్రించిన సందర్భంగా సంస్మరణ ఆరాధన', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, ప్రార్థనలో పాల్గొని మా కుటుంబాన్ని ఓదార్చవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక', inviterLabel: _grief);

      case CeremonyId.remembranceAnniversary:
        header('$yearsTe వర్ధంతి ఆరాధన');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('దివంగత ${v('deceased')}', LineRole.name);
        add('గారి $yearsTe వర్ధంతి సందర్భంగా జ్ఞాపకార్థ ఆరాధన', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, ప్రార్థనలో పాల్గొనవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక', inviterLabel: _grief);

      case CeremonyId.jayanthi:
        final nJ = int.tryParse(d.enValue('years')) ?? 1;
        header('$nJవ జయంతి');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('కీ.శే. ${v('deceased')}', LineRole.name);
        add('గారి $nJవ జయంతి సందర్భంగా స్మరణ కార్యక్రమము', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, వారిని స్మరించుకొనవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer();

      case CeremonyId.birthRemembrance:
        final nB = int.tryParse(d.enValue('years')) ?? 1;
        header('జన్మదిన జ్ఞాపకార్థ ఆరాధన');
        add('మా ప్రియమైన $relTe', LineRole.small);
        add('దివంగత ${v('deceased')}', LineRole.name);
        add('గారి $nBవ జన్మదిన సందర్భంగా జ్ఞాపకార్థ ఆరాధన', LineRole.body);
        add(when, LineRole.highlight);
        add('జరుగును.', LineRole.body);
        add('తాము విచ్చేసి, ప్రార్థనలో పాల్గొనవలసినదిగా కోరుచున్నాము.', LineRole.closing);
        footer(venueLabel: 'చర్చి / వేదిక');
      // Greeting cards (festivals, birthday wishes …).
      default:
        greeting();
    }
    return _l;
  }

  void greeting() {
    final g = greetingFor(d.ceremony.id);
    if (g == null) return;
    final i = (int.tryParse(d.en['wish'] ?? '0') ?? 0).clamp(0, g.wishes.length - 1);
    final ownTe = d.enValue('wishTe'), ownEn = d.enValue('wishEn');
    add(g.titleTe, LineRole.title);
    add(_deityTe(d.deity), LineRole.deity);
    space();
    if (v('to').isNotEmpty) {
      add('ప్రియమైన', LineRole.small);
      add(v('to'), LineRole.name);
      space();
    }
    add(ownTe.isNotEmpty ? ownTe : (ownEn.isNotEmpty ? ownEn : g.wishes[i].$1), LineRole.body);
    space();
    add(_lovingIds.contains(g.id) ? 'ప్రేమతో' : 'శుభాకాంక్షలతో', LineRole.label);
    add(v('from'), LineRole.value);
  }

  static const _lovingIds = {CeremonyId.gThankYou, CeremonyId.gGetWell, CeremonyId.gMothersDay, CeremonyId.gFathersDay};

  static String _deityTe(Deity deity) => switch (deity) {
        Deity.none => '',
        Deity.ganesha => '॥ శ్రీ గణేశాయ నమః ॥',
        Deity.venkateswara => 'శ్రీ వేంకటేశ్వర స్వామి వారి కృపతో',
        Deity.shivaParvati => 'శ్రీ ఉమామహేశ్వరుల కృపతో',
        Deity.sitaRama => 'శ్రీ సీతారామచంద్ర స్వామి వారి కృపతో',
        Deity.satyanarayana => 'శ్రీ సత్యనారాయణ స్వామి వారి కృపతో',
        Deity.bismillah => 'బిస్మిల్లాహిర్రహ్మానిర్రహీం',
        Deity.n786 => '786',
        Deity.cross => '✝ ప్రభువైన యేసుక్రీస్తు నామమున శుభములు ✝',
        Deity.mark109 => 'దేవుడు జతపరచినవారిని మనుష్యుడు వేరుపరచకూడదు. — మార్కు 10:9',
        Deity.psalm23 => 'యెహోవా నా కాపరి, నాకు లేమి కలుగదు. — కీర్తన 23:1',
        Deity.omShanti => 'ఓం శాంతి శాంతి శాంతిః',
        Deity.innaLillahi => 'ఇన్నా లిల్లాహి వ ఇన్నా ఇలైహి రాజిఊన్',
        Deity.john1125 => '"పునరుత్థానమును జీవమును నేనే" — యోహాను 11:25',
      };
}

// ---------------------------------------------------------------------------
// English
// ---------------------------------------------------------------------------

class _En {
  _En(this.d);
  final InvitationDraft d;
  final _l = <CardLine>[];

  bool get trad => d.tone == EnglishTone.traditional;
  String v(String key) => d.enValue(key);

  // ---- children (one or several) ----
  bool get _many => d.childCount > 1;

  /// son / daughter / sons / daughters / children
  String get kidWord {
    final kids = d.children;
    if (kids.length == 1) {
      final o = _ordEn(kids.first.order);
      return '${o.isEmpty ? '' : '$o '}${kids.first.son ? 'son' : 'daughter'}';
    }
    if (kids.every((k) => k.son)) return 'sons';
    if (kids.every((k) => !k.son)) return 'daughters';
    return 'children';
  }

  /// "A", "A & B", "A, B & C".
  String get kidNames {
    final n = [
      for (final k in d.children)
        if (k.en.isNotEmpty)
          _many && k.order.isNotEmpty ? '${k.en} (${_ordEn(k.order)} ${k.son ? 'son' : 'daughter'})' : k.en
    ];
    if (n.length <= 1) return n.join();
    return '${n.sublist(0, n.length - 1).join(', ')} & ${n.last}';
  }
  void add(String text, LineRole role) {
    if (text.trim().isNotEmpty) _l.add(CardLine(text, role));
  }

  void space() => _l.add(const CardLine('', LineRole.spacer));

  /// Birth order in English: "eldest", "second", "only" … or "".
  String ordEn(String key) => _ordEn(d.en[key] ?? '');
  static String _ordEn(String value) => switch (value) {
        'only' => 'only',
        'first' => 'eldest',
        'second' => 'second',
        'third' => 'third',
        'fourth' => 'fourth',
        'fifth' => 'fifth',
        'youngest' => 'youngest',
        _ => '',
      };
  static String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  /// "S/o Sri A & Smt. B" or "son of A & B"; with a birth order
  /// "Eldest son of Sri A & Smt. B".
  String parentage(String rel, String fatherKey, String motherKey, [String? orderKey]) {
    final f = v(fatherKey), m = v(motherKey);
    final o = orderKey == null ? '' : ordEn(orderKey);
    if (o.isNotEmpty) return trad ? '${_cap(o)} $rel of Sri $f & Smt. $m' : '$o $rel of $f & $m';
    if (trad) {
      final short = switch (rel) { 'son' => 'S/o', 'daughter' => 'D/o', _ => 'C/o' };
      return '$short Sri $f & Smt. $m';
    }
    return '$rel of $f & $m';
  }

  String groom(String key) => trad ? 'Chi. ${v(key)}' : v(key);
  String bride(String key) => trad ? 'Chi. La. Sow. ${v(key)}' : v(key);
  /// "S/o Janab A & Begum B" (mother optional) or "son of A & B".
  String mParentage(String rel, String fatherKey, String motherKey, [String? orderKey]) {
    final f = v(fatherKey), m = v(motherKey);
    final o = orderKey == null ? '' : ordEn(orderKey);
    if (o.isNotEmpty) {
      final parents = trad ? (m.isEmpty ? 'Janab $f' : 'Janab $f & Begum $m') : (m.isEmpty ? f : '$f & $m');
      return trad ? '${_cap(o)} $rel of $parents' : '$o $rel of $parents';
    }
    if (trad) {
      final short = rel == 'son' ? 'S/o' : 'D/o';
      return m.isEmpty ? '$short Janab $f' : '$short Janab $f & Begum $m';
    }
    return m.isEmpty ? '$rel of $f' : '$rel of $f & $m';
  }

  // ---- remembrance helpers ----
  String get relEn =>
      relations.firstWhere((o) => o.value == d.en['relation'], orElse: () => relations.first).en.toLowerCase();
  bool get _female => femaleRelations.contains(d.en['relation']);
  String get yearsEn => InviteDates.ordinal(int.tryParse(v('years')) ?? 1);
  static const _grief = 'With grieving hearts';

  /// "Son of Mr. A & Mrs. B" or "son of A & B".
  String cParentage(String rel, String fatherKey, String motherKey, [String? orderKey]) {
    final o = orderKey == null ? '' : ordEn(orderKey);
    final r = o.isEmpty ? rel : '${_cap(o)} ${rel.toLowerCase()}';
    return trad
        ? '$r of Mr. ${v(fatherKey)} & Mrs. ${v(motherKey)}'
        : '${r.toLowerCase()} of ${v(fatherKey)} & ${v(motherKey)}';
  }

  String couple(String h, String w) => trad ? 'Sri ${v(h)} & Smt. ${v(w)}' : '${v(h)} & ${v(w)}';

  void header(String title) {
    add(title, LineRole.title);
    if (trad && d.ceremony.showBlessingLine) {
      add('Srirastu  ·  Subhamastu  ·  Avighnamastu', LineRole.blessing);
    }
    add(_deityEn(d.deity), LineRole.deity);
    space();
  }

  void when({bool muhurthamWord = false}) {
    final date = d.date;
    if (date == null) return;
    add(InviteDates.enDate(date), LineRole.highlight);
    final t = d.time;
    if (t != null) {
      add(trad && muhurthamWord ? 'Muhurtham: ${InviteDates.enTime(t)}' : 'at ${InviteDates.enTime(t)}',
          LineRole.highlight);
    }
    final lag = findAstro(lagnams, d.en['lagnam']);
    final nak = findAstro(nakshatrams, d.en['nakshatram']);
    final own = d.en['lagnam'] == kOwnMuhurtham ? (d.en['muhurthamOwn'] ?? '').trim() : '';
    final astro = own.isNotEmpty
        ? own
        : [
            if (nak != null) '${nak.en} Nakshatram',
            if (lag != null) '${lag.en} Lagnam',
          ].join('  ·  ');
    add(astro, LineRole.small);
  }

  /// "(B.Tech, Software Engineer)" under a name, if given.
  void edu(String key) {
    final e = v(key);
    if (e.isNotEmpty) add('($e)', LineRole.small);
  }

  /// "Lunch will be served from 12:30 PM." if the host chose one.
  void meal() {
    final label = switch (d.meal) {
      'breakfast' => 'Breakfast (tiffin)',
      'lunch' => 'Lunch',
      'dinner' => 'Dinner',
      _ => '',
    };
    if (label.isEmpty) return;
    space();
    _l.add(const CardLine('meal', LineRole.icon));
    final t = d.mealTime;
    // No separate place → the meal is at the main venue.
    final place = d.mealVenue.trim().isNotEmpty ? d.mealVenue.trim() : d.venue.trim();
    final at = place.isEmpty ? '' : (place.toLowerCase().startsWith('at ') ? ' $place' : ' at $place');
    add(t == null ? '$label will be served$at.' : '$label will be served from ${InviteDates.enTime(t)}$at.',
        LineRole.highlight);
  }

  void footer({String venueLabel = 'Venue', String? fallbackInviters, String? inviterLabel}) {
    meal();
    space();
    add(venueLabel, LineRole.label);
    add(d.venue, LineRole.value);
    final inv = d.inviters.trim().isNotEmpty ? d.inviters : (fallbackInviters ?? '');
    if (inv.trim().isNotEmpty) {
      space();
      add(inviterLabel ?? (trad ? 'With best compliments from' : 'With love'), LineRole.label);
      add(inv, LineRole.value);
    }
  }

  List<CardLine> build() {
    switch (d.ceremony.id) {
      case CeremonyId.wedding:
        header(trad ? 'Wedding Invitation' : "We're getting married");
        add(
            trad
                ? 'We solicit your gracious presence with family and friends at the auspicious wedding of'
                : 'Together with their families, we joyfully invite you to the wedding of',
            LineRole.body);
        add(groom('groom'), LineRole.name);
        edu('groomEdu');
        add(parentage('son', 'groomFather', 'groomMother', 'groomOrder'), LineRole.small);
        add(trad ? 'with' : '&', LineRole.connector);
        add(bride('bride'), LineRole.name);
        edu('brideEdu');
        add(parentage('daughter', 'brideFather', 'brideMother', 'brideOrder'), LineRole.small);
        space();
        when(muhurthamWord: true);
        add(trad ? 'Kindly grace the occasion and bless the couple.' : 'Your presence will make our day complete.',
            LineRole.closing);
        footer();

      case CeremonyId.engagement:
        header(trad ? 'Engagement Invitation' : "We're engaged!");
        add(
            trad
                ? 'We cordially invite you with family to the engagement ceremony (Nischitartham) of'
                : 'Join us to celebrate the engagement of',
            LineRole.body);
        add(groom('groom'), LineRole.name);
        edu('groomEdu');
        add(parentage('son', 'groomFather', 'groomMother', 'groomOrder'), LineRole.small);
        add(trad ? 'with' : '&', LineRole.connector);
        add(bride('bride'), LineRole.name);
        edu('brideEdu');
        add(parentage('daughter', 'brideFather', 'brideMother', 'brideOrder'), LineRole.small);
        space();
        when();
        add(trad ? 'Kindly grace the occasion and bless the couple-to-be.' : 'We would love to see you there.',
            LineRole.closing);
        footer();

      case CeremonyId.housewarming:
        header(trad ? 'Gruhapravesam' : 'Housewarming');
        add(
            trad
                ? 'With the blessings of the Almighty, we cordially invite you with family to the Gruhapravesam (housewarming ceremony) of our new home'
                : "We've found our new home! Join us for the housewarming (Gruhapravesam)",
            LineRole.body);
        space();
        when(muhurthamWord: true);
        add(trad ? 'Kindly grace the occasion and bless us.' : 'Come share our joy.', LineRole.closing);
        footer(venueLabel: 'Address', fallbackInviters: v('hosts'));

      case CeremonyId.barasala:
        final sonBarasala = d.en['childGender'] != 'daughter';
        header(trad ? 'Barasala Invitation' : 'Naming Ceremony');
        add(
            'We cordially invite you to the Barasala (naming ceremony) of our beloved ${ordEn('childOrder').isEmpty ? '' : '${ordEn('childOrder')} '}${sonBarasala ? 'son' : 'daughter'}',
            LineRole.body);
        add(v('child'), LineRole.name);
        add(trad ? 'Sri ${v('father')} & Smt. ${v('mother')}' : '${v('father')} & ${v('mother')}', LineRole.small);
        space();
        when();
        add('Kindly join us and bless the little one.', LineRole.closing);
        footer();

      case CeremonyId.annaprasana:
        header(trad ? 'Annaprasana Invitation' : 'First Rice Ceremony');
        add('We cordially invite you to the Annaprasana (first rice ceremony) of our little one', LineRole.body);
        add(trad ? 'Chi. ${v('child')}' : v('child'), LineRole.name);
        add(ordEn('childOrder').isNotEmpty
                ? '${_cap(ordEn('childOrder'))} child of ${trad ? 'Sri ' : ''}${v('father')} & ${trad ? 'Smt. ' : ''}${v('mother')}'
                : (trad ? 'C/o Sri ${v('father')} & Smt. ${v('mother')}' : 'child of ${v('father')} & ${v('mother')}'),
            LineRole.small);
        space();
        when();
        add('Kindly join us and bless the little one.', LineRole.closing);
        footer();

      case CeremonyId.seemantham:
        header(trad ? 'Seemantham Invitation' : 'Baby Shower');
        add('We cordially invite you to the Seemantham (traditional baby shower) of', LineRole.body);
        add(trad ? 'Sow. ${v('wife')}' : v('wife'), LineRole.name);
        add(trad ? 'W/o Sri ${v('husband')}' : 'wife of ${v('husband')}', LineRole.small);
        space();
        when();
        add('Kindly join us and bless the mother and the baby.', LineRole.closing);
        footer();

      case CeremonyId.upanayanam:
        header('Upanayanam Invitation');
        add('We cordially invite you with family to the Upanayanam (sacred thread ceremony) of', LineRole.body);
        add(groom('boy'), LineRole.name);
        add(parentage('son', 'father', 'mother', 'boyOrder'), LineRole.small);
        space();
        when(muhurthamWord: true);
        add('Kindly grace the occasion and bless the vatu.', LineRole.closing);
        footer();

      case CeremonyId.shashtipoorthi:
        header(trad ? 'Shashtipoorthi Invitation' : '60th Birthday Celebration');
        add('We cordially invite you to the Shashtipoorthi (60th birthday celebration) of our beloved parents',
            LineRole.body);
        add(couple('husband', 'wife'), LineRole.name);
        space();
        when();
        add('Kindly grace the occasion with your presence.', LineRole.closing);
        footer();

      case CeremonyId.satyanarayana:
        header('Sri Satyanarayana Swamy Vratham');
        add('We cordially invite you with family to the Sri Satyanarayana Swamy Vratham at our home', LineRole.body);
        space();
        when();
        add("Kindly attend and receive the Swamy's theertha prasadam.", LineRole.closing);
        footer(fallbackInviters: v('hosts'));

      case CeremonyId.birthday:
        header('Birthday Invitation');
        final age = int.tryParse(v('age'));
        add(age == null ? 'Join us to celebrate the birthday of' : 'Join us to celebrate the ${InviteDates.ordinal(age)} birthday of',
            LineRole.body);
        add(v('child'), LineRole.name);
        final fE = v('father'), mE = v('mother');
        if (fE.isNotEmpty || mE.isNotEmpty) {
          final rel = d.en['childGender'] == 'daughter' ? 'daughter' : 'son';
          final o = ordEn('childOrder');
          final who = fE.isNotEmpty && mE.isNotEmpty
              ? (trad ? 'Sri $fE & Smt. $mE' : '$fE & $mE')
              : (fE.isNotEmpty ? (trad ? 'Sri $fE' : fE) : (trad ? 'Smt. $mE' : mE));
          add('${o.isEmpty ? _cap(rel) : '${_cap(o)} $rel'} of $who', LineRole.small);
        }
        space();
        when();
        add('Your presence and blessings mean the world to us.', LineRole.closing);
        footer();

      // ---------------- Muslim ----------------
      case CeremonyId.nikah:
        header(trad ? 'Nikah Invitation' : 'Shaadi Mubarak');
        add(
            trad
                ? 'With the blessings of Allah, we request the honour of your presence at the Nikah of'
                : 'Together with their families, we invite you to the Nikah of',
            LineRole.body);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add(mParentage('son', 'groomFather', 'groomMother', 'groomOrder'), LineRole.small);
        add(trad ? 'with' : '&', LineRole.connector);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        add(mParentage('daughter', 'brideFather', 'brideMother', 'brideOrder'), LineRole.small);
        space();
        when();
        add('Your presence and duas will be our greatest blessing.', LineRole.closing);
        footer();

      case CeremonyId.walima:
        header('Dawat-e-Walima');
        add('We cordially invite you to the Walima reception celebrating the Nikah of', LineRole.body);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add('&', LineRole.connector);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        space();
        when();
        add('Kindly join us and bless the newly-weds with your duas.', LineRole.closing);
        footer(
            fallbackInviters:
                trad ? 'Janab ${v('groomFather')} & Family' : '${v('groomFather')} & Family');

      case CeremonyId.mangni:
        header(trad ? 'Mangni Ceremony' : "We're engaged!");
        add('We cordially invite you with family to the Mangni (engagement) of', LineRole.body);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add(mParentage('son', 'groomFather', 'groomMother', 'groomOrder'), LineRole.small);
        add(trad ? 'with' : '&', LineRole.connector);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        add(mParentage('daughter', 'brideFather', 'brideMother', 'brideOrder'), LineRole.small);
        space();
        when();
        add('Kindly join us and bless the couple-to-be with your duas.', LineRole.closing);
        footer();

      case CeremonyId.aqiqah:
        header('Aqiqah Invitation');
        add('With gratitude to Allah, we invite you to the Aqiqah of our beloved $kidWord', LineRole.body);
        add(kidNames, LineRole.name);
        add(trad ? 'Janab ${v('father')} & Begum ${v('mother')}' : '${v('father')} & ${v('mother')}', LineRole.small);
        space();
        when();
        add('Kindly join us and bless ${_many ? 'the little ones' : 'the little one'} with your duas.', LineRole.closing);
        footer();

      case CeremonyId.iftar:
        header('Iftar Invitation');
        add('In this blessed month of Ramadan, we cordially invite you to Iftar at our home', LineRole.body);
        space();
        when();
        add('Your presence will be a blessing to us.', LineRole.closing);
        footer(fallbackInviters: v('hosts'));

      // ---------------- Christian ----------------
      case CeremonyId.holyMatrimony:
        header(trad ? 'Holy Matrimony' : "We're getting married");
        add(
            trad
                ? 'By the grace of God, we request the honour of your presence at the Holy Matrimony of'
                : 'Together with their families, we invite you to the wedding of',
            LineRole.body);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add(cParentage('Son', 'groomFather', 'groomMother', 'groomOrder'), LineRole.small);
        add(trad ? 'with' : '&', LineRole.connector);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        add(cParentage('Daughter', 'brideFather', 'brideMother', 'brideOrder'), LineRole.small);
        space();
        when();
        add('Kindly join us and bless the couple in prayer.', LineRole.closing);
        footer(venueLabel: 'Church / Venue');

      case CeremonyId.betrothal:
        header(trad ? 'Engagement (Pradhanam)' : "We're engaged!");
        add('By the grace of God, we invite you to the engagement of', LineRole.body);
        add(v('groom'), LineRole.name);
        edu('groomEdu');
        add(cParentage('Son', 'groomFather', 'groomMother', 'groomOrder'), LineRole.small);
        add(trad ? 'with' : '&', LineRole.connector);
        add(v('bride'), LineRole.name);
        edu('brideEdu');
        add(cParentage('Daughter', 'brideFather', 'brideMother', 'brideOrder'), LineRole.small);
        space();
        when();
        add('Kindly join us and bless the couple-to-be in prayer.', LineRole.closing);
        footer(venueLabel: 'Church / Venue');

      case CeremonyId.baptism:
        header('Baptism');
        add('With joy and thanksgiving, we invite you to the Baptism of our beloved $kidWord', LineRole.body);
        add(kidNames, LineRole.name);
        add(trad ? 'Mr. ${v('father')} & Mrs. ${v('mother')}' : '${v('father')} & ${v('mother')}', LineRole.small);
        space();
        when();
        add('Kindly join us and bless ${_many ? 'the little ones' : 'the little one'} in prayer.', LineRole.closing);
        footer(venueLabel: 'Church');

      case CeremonyId.communion:
        header('First Holy Communion');
        add('We joyfully invite you to celebrate the First Holy Communion of our $kidWord', LineRole.body);
        add(kidNames, LineRole.name);
        add(trad ? 'Mr. ${v('father')} & Mrs. ${v('mother')}' : '${v('father')} & ${v('mother')}', LineRole.small);
        space();
        when();
        add('Kindly join us and bless ${_many ? 'the children' : 'the child'} in prayer.', LineRole.closing);
        footer(venueLabel: 'Church');

      case CeremonyId.houseBlessing:
        header('House Blessing');
        add("By God's grace, we invite you to the blessing and dedication service of our new home", LineRole.body);
        space();
        when();
        add('Kindly join us in prayer and thanksgiving.', LineRole.closing);
        footer(venueLabel: 'Address', fallbackInviters: v('hosts'));

      // ---------------- Remembrance ----------------
      case CeremonyId.peddaKarma:
        header('Pedda Karma');
        add('With deep sorrow, we invite you to the Pedda Karma ceremony of our beloved $relEn',
            LineRole.body);
        add('Late ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us and pray for the departed soul.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.vardhanthi:
        header('$yearsEn Death Anniversary');
        add('We invite you to join us in remembering our beloved $relEn', LineRole.body);
        add('Late ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us in prayer and remembrance.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.chehlum:
        header('Chehlum');
        add('We request your presence at the Chehlum (40th day Fateha) of our beloved $relEn', LineRole.body);
        add('${_female ? 'Marhooma' : 'Marhoom'} ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us and pray for the maghfirat of the departed.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.barsi:
        header('$yearsEn Barsi');
        add('We request your presence for Fateha on the $yearsEn death anniversary of our beloved $relEn',
            LineRole.body);
        add('${_female ? 'Marhooma' : 'Marhoom'} ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us for Fateha and dua.', LineRole.closing);
        footer(inviterLabel: _grief);

      case CeremonyId.memorialService:
        header('Memorial Service');
        add('We invite you to a service of thanksgiving and remembrance for our beloved $relEn', LineRole.body);
        add('Late ${v('deceased')}', LineRole.name);
        add('who rests in the Lord', LineRole.small);
        space();
        when();
        add('Kindly join us in prayer and fellowship.', LineRole.closing);
        footer(venueLabel: 'Church / Venue', inviterLabel: _grief);

      case CeremonyId.remembranceAnniversary:
        header('$yearsEn Remembrance Service');
        add('We invite you to a remembrance service on the $yearsEn anniversary of our beloved $relEn',
            LineRole.body);
        add('Late ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us in prayer.', LineRole.closing);
        footer(venueLabel: 'Church / Venue', inviterLabel: _grief);

      case CeremonyId.jayanthi:
        header('$yearsEn Jayanthi');
        add('We invite you to join us in remembering our beloved $relEn on ${_female ? 'her' : 'his'} $yearsEn birth anniversary',
            LineRole.body);
        add('Late ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us in remembrance.', LineRole.closing);
        footer(inviterLabel: 'With love and remembrance');

      case CeremonyId.birthRemembrance:
        header('Birth Anniversary Remembrance');
        add('We invite you to a remembrance service on the $yearsEn birth anniversary of our beloved $relEn',
            LineRole.body);
        add('Late ${v('deceased')}', LineRole.name);
        space();
        when();
        add('Kindly join us in prayer and thanksgiving.', LineRole.closing);
        footer(venueLabel: 'Church / Venue', inviterLabel: 'With love and remembrance');
      // Greeting cards (festivals, birthday wishes …).
      default:
        greeting();
    }
    return _l;
  }

  void greeting() {
    final g = greetingFor(d.ceremony.id);
    if (g == null) return;
    final i = (int.tryParse(d.en['wish'] ?? '0') ?? 0).clamp(0, g.wishes.length - 1);
    final own = v('wishEn');
    add(g.titleEn, LineRole.title);
    add(_deityEn(d.deity), LineRole.deity);
    space();
    if (v('to').isNotEmpty) {
      add('Dear', LineRole.small);
      add(v('to'), LineRole.name);
      space();
    }
    add(own.isNotEmpty ? own : g.wishes[i].$2, LineRole.body);
    space();
    add(_lovingIds.contains(g.id) ? 'With love' : 'With warm wishes', LineRole.label);
    add(v('from'), LineRole.value);
  }

  static const _lovingIds = {CeremonyId.gThankYou, CeremonyId.gGetWell, CeremonyId.gMothersDay, CeremonyId.gFathersDay};

  static String _deityEn(Deity deity) => switch (deity) {
        Deity.none => '',
        Deity.ganesha => '|| Sri Ganeshaya Namaha ||',
        Deity.venkateswara => 'With the divine blessings of Lord Sri Venkateswara',
        Deity.shivaParvati => 'With the blessings of Lord Shiva & Goddess Parvati',
        Deity.sitaRama => 'With the blessings of Sri Sita Rama',
        Deity.satyanarayana => 'With the blessings of Sri Satyanarayana Swamy',
        Deity.bismillah => 'Bismillah-hir-Rahman-nir-Raheem',
        Deity.n786 => '786',
        Deity.cross => '✝ In the name of our Lord Jesus Christ ✝',
        Deity.mark109 => '"What God has joined together, let no one separate." — Mark 10:9',
        Deity.psalm23 => '"The Lord is my shepherd; I shall not want." — Psalm 23:1',
        Deity.omShanti => 'Om Shanti Shanti Shantih',
        Deity.innaLillahi => "Inna Lillahi wa Inna Ilayhi Raji'un",
        Deity.john1125 => '"I am the resurrection and the life." — John 11:25',
      };
}
