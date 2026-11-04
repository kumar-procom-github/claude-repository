import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahvanam/models/ceremony.dart';
import 'package:ahvanam/models/event_item.dart';
import 'package:ahvanam/templates/card_template.dart';
import 'package:ahvanam/models/invitation_draft.dart';
import 'package:ahvanam/wording/card_text.dart';
import 'package:ahvanam/wording/dates.dart';
import 'package:ahvanam/wording/transliterator.dart';
import 'package:ahvanam/wording/wording_engine.dart';

void main() {
  test('birthday: parents, birth order, boy / girl colours', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.birthday), tradition: Tradition.hindu)
      ..date = DateTime(2026, 12, 12);
    d
      ..setEn('child', 'Hanish')
      ..setEn('childGender', 'son', autoTelugu: false)
      ..setEn('father', 'Ramesh')
      ..setEn('mother', 'Lakshmi')
      ..setEn('childOrder', 'first', autoTelugu: false);
    final te = WordingEngine.telugu(d).lines.map((l) => l.text).join(' | ');
    expect(te, contains('దంపతుల ప్రథమ కుమారుడు'));
    final en = WordingEngine.english(d).lines.map((l) => l.text).join(' | ');
    expect(en, contains('Eldest son of'));
    expect(CardTemplate.defaultFor(tradition: Tradition.hindu, remembrance: false,
        ceremony: CeremonyId.birthday, childGender: 'son').id, 'sky');
    expect(CardTemplate.defaultFor(tradition: Tradition.hindu, remembrance: false,
        ceremony: CeremonyId.birthday, childGender: 'daughter').id, 'candy');
    // Weddings keep the tradition's colours.
    expect(CardTemplate.defaultFor(tradition: Tradition.hindu, remembrance: false,
        ceremony: CeremonyId.wedding).id, 'kumkum');
  });

  group('Transliterator', () {
    test('names ending in -am take ం (Sunkaram → సుంకరం)', () {
      expect(Transliterator.toTelugu('Sunkaram Satya'), 'సుంకరం సత్య');
      expect(Transliterator.toTelugu('Navaratnam'), 'నవరత్నం');
      // Names people write with మ్ stay that way, and మ్ is offered as a spelling.
      expect(Transliterator.toTelugu('Gautam'), 'గౌతమ్');
      expect(Transliterator.toTelugu('Sriram'), 'శ్రీరామ్');
      expect(Transliterator.alternatives('Sunkaram'), contains('సుంకరమ్'));
    });

    test('venues: English words translated, village endings kept', () {
      expect(Transliterator.toTeluguPlace('At The Church, gantavarigudem'), 'చర్చి వద్ద, గంటవారిగూడెం');
      expect(Transliterator.toTeluguPlace('Near Bus Stand, Kothapeta'), 'బస్ స్టాండ్ దగ్గర, కొత్తపేట');
      expect(Transliterator.toTeluguPlace("St. Mary's Church"), 'సెయింట్. మేరీస్ చర్చి');
      expect(Transliterator.toTeluguPlace('Our residence'), 'స్వగృహం');
      expect(Transliterator.placeAlternatives('At The Church, gantavarigudem'), isNot(contains('చర్చి వద్ద, గంటవారిగూడెం')));
    });

    test('dictionary names', () {
      expect(Transliterator.toTelugu('Lakshmi'), 'లక్ష్మి');
      expect(Transliterator.toTelugu('Venkateswara Rao'), 'వేంకటేశ్వర రావు');
    });
    test('phonetic rules', () {
      expect(Transliterator.toTelugu('Priya'), 'ప్రియ');
      expect(Transliterator.toTelugu('Arjun'), 'అర్జున్');
      expect(Transliterator.toTelugu('Shiva'), 'శివ');
      expect(Transliterator.toTelugu('Pallavi'), 'పల్లవి');
      expect(Transliterator.toTelugu('Hansika'), 'హంసిక');
    });
    test('Telugu surnames: retroflex d and short o/e', () {
      expect(Transliterator.toTelugu('Chidibomma Kumaara swaami'), 'చిడిబొమ్మ కుమార స్వామి');
      expect(Transliterator.toTelugu('Gudivada'), 'గుడివడ');
      expect(Transliterator.toTelugu('Kollipara'), 'కొల్లిపర');
      expect(Transliterator.toTelugu('Chitti'), 'చిట్టి');
    });
    test('Sanskrit names keep long vowels and dental d', () {
      expect(Transliterator.toTelugu('Sridevi'), 'శ్రీదేవి');
      expect(Transliterator.toTelugu('Nagendra'), 'నాగేంద్ర'); // నాగ + ఇంద్ర
      expect(Transliterator.toTelugu('Hemanth'), 'హేమంత్');
    });
    test('alternatives offer the other spellings', () {
      expect(Transliterator.alternatives('Kondapalli'), contains('కొండపల్లి'));
      expect(Transliterator.alternatives('Chidibomma Kumaara'), contains('చిదిబొమ్మ కుమార'));
      expect(Transliterator.alternatives('Sadanand'), contains('సదనంద్'));
    });
    test('venue / function hall names', () {
      expect(Transliterator.toTelugu('Sri Lakshmi Function Hall, Kukatpally'), 'శ్రీ లక్ష్మి ఫంక్షన్ హాల్, కూకట్‌పల్లి');
      expect(Transliterator.toTelugu('N Convention, Madhapur'), 'ఎన్ కన్వెన్షన్, మాదాపూర్');
    });
    test('retroflex n after r (Arani → అరణి)', () {
      expect(Transliterator.toTelugu('Arani'), 'అరణి');
      expect(Transliterator.toTelugu('Varun'), 'వరుణ్');
      expect(Transliterator.toTelugu('Pranav'), 'ప్రణవ్');
      expect(Transliterator.toTelugu('Rajini'), 'రజిని'); // j blocks the rule
      expect(Transliterator.toTelugu('Narendra'), 'నరేంద్ర');
      expect(Transliterator.alternatives('Arani'), contains('అరని'));
    });
    test('Invited-by phrases are translated, not sound-converted', () {
      expect(Transliterator.toTelugu('Sri Aarya And His family'), 'శ్రీ ఆర్య మరియు వారి కుటుంబ సభ్యులు');
      expect(Transliterator.toTelugu('Ramesh & Family'), 'రమేష్ మరియు కుటుంబ సభ్యులు');
      expect(Transliterator.toTelugu('Late Sri Krishna'), 'కీ.శే. శ్రీ కృష్ణ');
      expect(Transliterator.toTelugu('Friends and Relatives'), 'బంధుమిత్రులు');
    });
    test('initials and punctuation pass through', () {
      expect(Transliterator.toTelugu('K. Ramesh'), 'కె. రమేష్');
    });
  });

  group('Dates', () {
    test('Telugu time names the part of day', () {
      expect(InviteDates.teTime(const TimeOfDay(hour: 10, minute: 30)), 'ఉదయం 10:30 గం॥లకు');
      expect(InviteDates.teTime(const TimeOfDay(hour: 19, minute: 5)), 'రాత్రి 7:05 గం॥లకు');
    });
    test('English date', () {
      expect(InviteDates.enDate(DateTime(2026, 12, 12)), 'Saturday, 12th December 2026');
    });
  });

  test('Telugu wedding card has traditional structure', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.wedding))
      ..setEn('groom', 'Arjun')
      ..setEn('groomFather', 'Ramesh')
      ..setEn('groomMother', 'Lakshmi')
      ..setEn('bride', 'Priya')
      ..setEn('brideFather', 'Suresh')
      ..setEn('brideMother', 'Padma')
      ..setEn('lagnam', 'Vrishabha', autoTelugu: false)
      ..setEn('nakshatram', 'Rohini', autoTelugu: false);
    d
      ..date = DateTime(2026, 12, 12)
      ..time = const TimeOfDay(hour: 10, minute: 30)
      ..venue = 'Sri Convention, Hyderabad';

    final lines = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
    expect(lines.first, 'శుభలేఖ');
    expect(lines, contains('చి॥ అర్జున్'));
    expect(lines, contains('చి॥ల॥సౌ॥ ప్రియ'));
    expect(lines, contains('ది. 12-12-2026 శనివారం ఉదయం 10:30 గం॥లకు'));
    expect(lines.any((l) => l.contains('రోహిణి నక్షత్రయుక్త వృషభ లగ్నమందు')), isTrue);

    final en = WordingEngine.english(d).lines;
    expect(en.where((l) => l.role == LineRole.name).map((l) => l.text),
        ['Chi. Arjun', 'Chi. La. Sow. Priya']);
  });

  test('wedding with functions adds a schedule page per language', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.wedding))
      ..setEn('groom', 'Arjun')
      ..setEn('bride', 'Priya')
      ..date = DateTime(2026, 12, 12)
      ..venue = 'Sri Convention';
    d.addEvent(EventItem(presetId: 'reception', date: DateTime(2026, 12, 13)));
    d.addEvent(EventItem(presetId: 'haldi', date: DateTime(2026, 12, 10), time: const TimeOfDay(hour: 9, minute: 0)));

    final faces = WordingEngine.faces(d); // both languages by default
    expect(faces.length, 4);
    final teSchedule = faces[1].lines.where((l) => l.role == LineRole.event).map((l) => l.text).toList();
    expect(teSchedule, ['హల్దీ', 'రిసెప్షన్']); // sorted by date
    // Empty event venue falls back to the main venue.
    expect(faces[3].lines.any((l) => l.text == 'Sri Convention'), isTrue);
  });

  group('Traditions', () {
    test('each tradition has its own ceremonies; Birthday is shared', () {
      final muslim = ceremoniesFor(Tradition.muslim).map((c) => c.id);
      expect(muslim, containsAll([CeremonyId.nikah, CeremonyId.walima, CeremonyId.birthday]));
      expect(muslim, isNot(contains(CeremonyId.wedding)));
      final christian = ceremoniesFor(Tradition.christian).map((c) => c.id);
      expect(christian, containsAll([CeremonyId.holyMatrimony, CeremonyId.baptism, CeremonyId.birthday]));
    });

    test('Nikah: Bismillah header, Janab parentage, duas closing', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.nikah), tradition: Tradition.muslim)
        ..setEn('groom', 'Imran')
        ..setEn('groomFather', 'Salim')
        ..setEn('bride', 'Ayesha')
        ..setEn('brideFather', 'Rafiq')
        ..date = DateTime(2026, 12, 20);
      expect(d.deity, Deity.bismillah);
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
      expect(te.first, 'నిఖా ఆహ్వానం');
      expect(te, contains('బిస్మిల్లాహిర్రహ్మానిర్రహీం'));
      expect(te.any((l) => l.startsWith('జనాబ్ ')), isTrue);
      expect(te.any((l) => l.contains('దువాలు')), isTrue);
      final en = WordingEngine.english(d).lines.map((l) => l.text).toList();
      expect(en, contains('S/o Janab Salim')); // mother optional
    });

    test('Birthday chosen under Christian gets Christian header options only', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.birthday), tradition: Tradition.christian);
      expect(Deity.forTradition(d.tradition), containsAll([Deity.cross, Deity.psalm23, Deity.none]));
      expect(Deity.forTradition(d.tradition), isNot(contains(Deity.ganesha)));
      expect(d.deity, Deity.none);
    });

    test('Hindu-only designs are not offered on Muslim cards', () {
      expect(CardLayout.forTradition(Tradition.muslim), isNot(contains(CardLayout.gopuram)));
      expect(CardLayout.forTradition(Tradition.muslim), contains(CardLayout.mehrab));
      expect(CardLayout.forTradition(Tradition.christian), contains(CardLayout.chapel));
    });
  });

  group('Remembrance', () {
    test('each tradition has its own remembrance ceremonies', () {
      expect(ceremoniesFor(Tradition.hindu, CeremonyCategory.remembrance).map((c) => c.id),
          [CeremonyId.peddaKarma, CeremonyId.vardhanthi, CeremonyId.jayanthi]);
      expect(ceremoniesFor(Tradition.muslim, CeremonyCategory.remembrance).map((c) => c.id),
          [CeremonyId.chehlum, CeremonyId.barsi]);
      expect(ceremoniesFor(Tradition.christian, CeremonyCategory.remembrance).map((c) => c.id),
          [CeremonyId.memorialService, CeremonyId.remembranceAnniversary, CeremonyId.birthRemembrance]);
      expect(ceremoniesFor(Tradition.hindu, CeremonyCategory.celebration).map((c) => c.id),
          isNot(contains(CeremonyId.peddaKarma)));
    });

    test('Pedda Karma wording is respectful', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.peddaKarma))
        ..setEn('deceased', 'Ramaiah')
        ..setEn('relation', 'father', autoTelugu: false)
        ..date = DateTime(2026, 11, 10);
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
      expect(te.first, 'పెద్దకర్మ');
      expect(te, contains('ఓం శాంతి శాంతి శాంతిః'));
      expect(te.any((l) => l.startsWith('కీ.శే. ')), isTrue);
      expect(te.any((l) => l.contains('శుభ')), isFalse); // nothing festive
      d.inviters = 'Ramesh & Family';
      final en = WordingEngine.english(d).lines.map((l) => l.text).toList();
      expect(en, contains('Late Ramaiah'));
      expect(en, contains('With grieving hearts'));
    });

    test('house / home are translated, -rao names spelt the Telugu way', () {
      expect(Transliterator.toTelugu('house'), 'స్వగృహం');
      expect(Transliterator.toTelugu('Home'), 'స్వగృహం');
      expect(Transliterator.toTelugu('our house, Kukatpally'), 'స్వగృహం, కూకట్‌పల్లి');
      expect(Transliterator.alternatives('house'), contains('ఇల్లు'));
      expect(Transliterator.toTelugu('ramarao'), 'రామారావు');
      expect(Transliterator.toTelugu('Subbarao'), 'సుబ్బారావు');
      expect(Transliterator.toTelugu('Srinivasarao'), 'శ్రీనివాసరావు');
      expect(Transliterator.toTelugu('Mohanrao'), 'మోహన్\u200Cరావు');
      expect(Transliterator.toTelugu('Nagarjuna'), 'నాగార్జున');
      expect(Transliterator.toTelugu('Saikumar'), 'సాయికుమార్');
      expect(Transliterator.toTelugu('Nagalakshmi'), 'నాగలక్ష్మి');
      expect(Transliterator.toTelugu('Jayanthi'), 'జయంతి');
    });

    test('Birth order after the parents (ప్రథమ కుమారుడు / Eldest son of)', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.wedding))
        ..setEn('groom', 'Arjun')
        ..setEn('groomFather', 'Ramesh')
        ..setEn('groomMother', 'Lakshmi')
        ..setEn('groomOrder', 'first', autoTelugu: false)
        ..setEn('bride', 'Priya')
        ..setEn('brideFather', 'Suresh')
        ..setEn('brideMother', 'Padma')
        ..setEn('brideOrder', 'second', autoTelugu: false);
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
      expect(te, contains('శ్రీ రమేష్ - శ్రీమతి లక్ష్మి దంపతుల ప్రథమ కుమారుడు'));
      expect(te, contains('శ్రీ సురేష్ - శ్రీమతి పద్మ దంపతుల ద్వితీయ కుమార్తె'));
      final en = WordingEngine.english(d).lines.map((l) => l.text).toList();
      expect(en, contains('Eldest son of Sri Ramesh & Smt. Lakshmi'));
      expect(en, contains('Second daughter of Sri Suresh & Smt. Padma'));
      // Not chosen → card unchanged.
      d.setEn('groomOrder', '', autoTelugu: false);
      expect(WordingEngine.english(d).lines.map((l) => l.text), contains('S/o Sri Ramesh & Smt. Lakshmi'));
    });

    test('Education line and lunch / dinner', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.wedding))
        ..setEn('groom', 'Arjun')
        ..setEn('groomEdu', 'B.Tech, Software Engineer', autoTelugu: false)
        ..meal = 'dinner'
        ..mealTime = const TimeOfDay(hour: 19, minute: 30);
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
      expect(te, contains('(B.Tech, Software Engineer)'));
      expect(te, contains('రాత్రి విందు: రాత్రి 7:30 గం॥ల నుండి'));
      final en = WordingEngine.english(d).lines.map((l) => l.text).toList();
      expect(en, contains('Dinner will be served from 7:30 PM.'));
      d.setMealVenue('Sri Lakshmi Function Hall');
      expect(WordingEngine.english(d).lines.map((l) => l.text),
          contains('Dinner will be served from 7:30 PM at Sri Lakshmi Function Hall.'));
      expect(WordingEngine.telugu(d).lines.map((l) => l.text), contains('స్థలం: శ్రీ లక్ష్మి ఫంక్షన్ హాల్'));
    });

    test('Greeting cards: Sankranti wish, no date or venue needed', () {
      expect(ceremoniesFor(Tradition.hindu, CeremonyCategory.greeting).map((c) => c.id),
          containsAll([CeremonyId.gSankranti, CeremonyId.gDeepavali, CeremonyId.gBirthday]));
      expect(ceremoniesFor(Tradition.muslim, CeremonyCategory.greeting).map((c) => c.id),
          containsAll([CeremonyId.gEidUlFitr, CeremonyId.gBakrid]));
      expect(ceremoniesFor(Tradition.muslim, CeremonyCategory.greeting).map((c) => c.id),
          isNot(contains(CeremonyId.gDeepavali)));
      final d = InvitationDraft(ceremonyById(CeremonyId.gSankranti), tradition: Tradition.hindu)
        ..setEn('from', 'Ramesh & Family');
      expect(d.isReady, isTrue);
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
      expect(te.first, 'సంక్రాంతి శుభాకాంక్షలు');
      expect(te, contains('శుభాకాంక్షలతో'));
      final en = WordingEngine.english(d).lines.map((l) => l.text).toList();
      expect(en.first, 'Happy Sankranti');
      expect(en.last, 'Ramesh & Family');
      d.setEn('wishEn', 'Have a colourful festival!', autoTelugu: false);
      expect(WordingEngine.english(d).lines.map((l) => l.text), contains('Have a colourful festival!'));
      expect(CardLayout.forTradition(Tradition.hindu, greeting: true).first, CardLayout.kites);
      expect(CardLayout.forTradition(Tradition.hindu), isNot(contains(CardLayout.kites)));
    });

    test('Baptism with several children', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.baptism))
        ..setEn('father', 'John')
        ..setEn('mother', 'Mary')
        ..setEn('child', 'David');
      d.addChild();
      d.setEn('child2', 'Sarah');
      d.setEn('childGender2', 'daughter', autoTelugu: false);
      expect(d.fields.where((f) => f.childIndex == 2).length, 2);
      final en = WordingEngine.english(d).lines.map((l) => l.text).toList();
      expect(en, contains('With joy and thanksgiving, we invite you to the Baptism of our beloved children'));
      expect(en, contains('David & Sarah'));
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).join('\n');
      expect(te, contains('పిల్లలకు'));
      expect(te, contains('చిన్నారులను'));
      d.removeChild(1);
      expect(d.childCount, 1);
      expect(d.enValue('child'), 'Sarah');
    });

    test('Christian and Muslim cards use their own names for bride & groom', () {
      final c = ceremonyById(CeremonyId.holyMatrimony).fields.first;
      expect(c.te, 'పెండ్లి కుమారుని పేరు');
      expect(ceremonyById(CeremonyId.betrothal).te, 'ప్రధానం');
      final m = ceremonyById(CeremonyId.nikah).fields.first;
      expect(m.te, 'దుల్హా పేరు');
    });

    test('Jayanthi (birth anniversary of the departed)', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.jayanthi))
        ..setEn('deceased', 'Ramaiah')
        ..setEn('relation', 'grandfather', autoTelugu: false)
        ..setEn('years', '75', autoTelugu: false);
      expect(WordingEngine.telugu(d).lines.first.text, '75వ జయంతి');
      expect(WordingEngine.english(d).lines.first.text, '75th Jayanthi');
    });

    test('Chehlum uses Marhooma for a woman and ordinal anniversaries work', () {
      final d = InvitationDraft(ceremonyById(CeremonyId.barsi), tradition: Tradition.muslim)
        ..setEn('deceased', 'Fatima')
        ..setEn('relation', 'mother', autoTelugu: false)
        ..setEn('years', '2', autoTelugu: false);
      final te = WordingEngine.telugu(d).lines.map((l) => l.text).toList();
      expect(te.first, 'ద్వితీయ బర్సీ');
      expect(te.any((l) => l.startsWith('మర్హూమా ')), isTrue);
      expect(WordingEngine.english(d).lines.first.text, '2nd Barsi');
    });

    test('festive headers, designs and colours are kept off remembrance cards', () {
      expect(Deity.forTradition(Tradition.hindu), isNot(contains(Deity.omShanti)));
      expect(Deity.forTradition(Tradition.hindu, remembrance: true), contains(Deity.omShanti));
      expect(CardLayout.forTradition(Tradition.hindu, remembrance: true), [CardLayout.deepaSmriti, CardLayout.serene]);
      expect(CardTemplate.forCategory(remembrance: true).every((t) => t.sober), isTrue);
      expect(CardTemplate.forCategory(remembrance: false).map((t) => t.id), isNot(contains('shanti')));
    });
  });

  test('every ceremony renders both languages without throwing', () {
    for (final c in ceremonies) {
      final d = InvitationDraft(c)..date = DateTime(2026, 11, 20);
      if (c.fields.any((f) => f.key == 'age')) d.setEn('age', '5', autoTelugu: false);
      for (final f in c.fields) {
        if (f.kind == FieldKind.name) d.setEn(f.key, 'Ravi');
      }
      d.language = CardLanguage.both;
      expect(WordingEngine.faces(d).length, 2);
    }
  });
}
