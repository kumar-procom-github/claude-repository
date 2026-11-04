import 'package:flutter_test/flutter_test.dart';
import 'package:ahvanam/models/ceremony.dart';
import 'package:ahvanam/models/invitation_draft.dart';
import 'package:ahvanam/reel/card_story.dart';
import 'package:ahvanam/reel/photo_shapes.dart';
import 'package:ahvanam/templates/card_template.dart';
import 'package:flutter/painting.dart';
import 'package:ahvanam/wording/card_text.dart';
import 'package:ahvanam/wording/wording_engine.dart';

String _text(StoryPage p) => p.lines.map((l) => l.text).join(' | ');

void main() {
  test('a housewarming plays as title → muhurtham → home → lunch → welcome', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.housewarming), tradition: Tradition.hindu)
      ..date = DateTime(2026, 12, 16)
      ..meal = 'lunch';
    d.setEn('hosts', 'Ramesh & Lakshmi');
    d.setEn('familyName', 'Tumpati');
    d.setVenue('Plot 12, Kukatpally');
    d.setInviters('Family and friends');
    final face = WordingEngine.faces(d).firstWhere((f) => f.telugu);
    final pages = CardStory.pages(face, storyInfoFor(d));
    final why = pages.map(_text).join('\n');

    expect(pages.length, 5, reason: why);
    // "<surname> వారి" then the title.
    expect(pages[0].lines.any((l) => l.role == LineRole.title && l.text.contains('వారి')), isTrue, reason: why);
    expect(pages[0].lines.last.role, LineRole.title);
    expect(pages[1].lines.first.text, 'సుముహూర్తం');
    expect(pages[2].lines.first.text, 'నూతన గృహం');
    expect(pages[3].lines.first.text, 'మధ్యాహ్న భోజనం');
    expect(pages[4].lines.any((l) => l.role == LineRole.closing), isTrue);
  });

  test('a wedding: groom, bride, "weds", muhurtham, wedding venue', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.wedding), tradition: Tradition.hindu)
      ..date = DateTime(2026, 12, 12);
    for (final (k, v) in [
      ('groom', 'Arjun'),
      ('groomFather', 'Ramesh'),
      ('groomMother', 'Lakshmi'),
      ('bride', 'Priya'),
      ('brideFather', 'Suresh'),
      ('brideMother', 'Padma'),
    ]) {
      d.setEn(k, v);
    }
    d.setVenue('Sri Lakshmi Function Hall');
    final info = storyInfoFor(d);
    for (final face in WordingEngine.faces(d)) {
      final pages = CardStory.pages(face, info);
      final why = pages.map(_text).join('\n');
      expect(CardStory.photoKeys(face, info), ['groom', 'bride', 'couple'], reason: why);
      final groom = pages.firstWhere((p) => p.photoKey == 'groom');
      final bride = pages.firstWhere((p) => p.photoKey == 'bride');
      expect(groom.lines.where((l) => l.role == LineRole.name).length, 1);
      expect(bride.lines.where((l) => l.role == LineRole.name).length, 1);
      expect(pages.where((p) => p.couple).length, 1, reason: why);
      expect(pages.any((p) => p.lines.first.text == (face.telugu ? 'కళ్యాణ వేదిక' : 'Wedding Venue')), isTrue,
          reason: why);
      final plain = CardStory.naturalSeconds(face, StoryArt(info: info));
      final withGod = CardStory.naturalSeconds(face, StoryArt(deity: Deity.ganesha, info: info));
      expect(withGod, greaterThan(plain));
    }
  });

  test('every photo shape is a closed outline inside its box', () {
    const box = Rect.fromLTWH(0, 0, 200, 240);
    for (final shape in PhotoShape.values) {
      final b = shape.path(box).getBounds();
      expect(b.width, greaterThan(100), reason: shape.name);
      expect(box.inflate(20).contains(b.topLeft) && box.inflate(20).contains(b.bottomRight), isTrue, reason: shape.name);
    }
    expect(PhotoShape.byName('nope'), PhotoShape.splash);
  });

  test('photos chosen on the details page are saved with the details', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.wedding), tradition: Tradition.hindu)..setPhoto('groom', '/x/g.jpg');
    final back = InvitationDraft(ceremonyById(CeremonyId.wedding), tradition: Tradition.hindu)..loadJson(d.toJson());
    expect(back.photos, {'groom': '/x/g.jpg'});
  });

  test('each tradition sees its own colours first', () {
    expect(CardTemplate.forCategory(remembrance: false, tradition: Tradition.hindu).first.id, 'kumkum');
    expect(CardTemplate.forCategory(remembrance: false, tradition: Tradition.christian).first.id, 'pearl');
    expect(CardTemplate.forCategory(remembrance: false, tradition: Tradition.muslim).first.id, 'emerald');
    // Nothing is hidden, only ordered.
    expect(CardTemplate.forCategory(remembrance: false, tradition: Tradition.muslim).length,
        CardTemplate.forCategory(remembrance: false).length);
  });
}
