import 'package:flutter_test/flutter_test.dart';
import 'package:ahvanam/models/ceremony.dart';
import 'package:ahvanam/models/invitation_draft.dart';
import 'package:ahvanam/music/music_library.dart';
import 'package:ahvanam/reel/reel_editor_screen.dart';
import 'package:ahvanam/reel/reel_project.dart';
import 'package:ahvanam/video/effects.dart';

void main() {
  test('every colour filter is a valid 5 × 4 matrix', () {
    for (final f in VideoFilter.values) {
      expect(f.matrix.length, 20, reason: f.name);
    }
    expect(VideoFilter.original.matrix, [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0]);
  });

  test('music catalog entries parse; bad ones are skipped', () {
    final t = MusicTrack.tryParse({'id': 'noor', 'title': 'Noor', 'file': 'tracks/noor.m4a', 'seconds': 60});
    expect(t?.file, 'tracks/noor.m4a');
    expect(MusicTrack.tryParse({'title': 'no id'}), isNull);
    expect(MusicLibrary.bundledTracks.length, 2);
  });

  test('remembrance has no video; greetings are their own category', () {
    expect(ceremonyById(CeremonyId.vardhanthi).isRemembrance, isTrue);
    expect(ceremonyById(CeremonyId.gChristmas).isGreeting, isTrue);
    expect(ceremoniesFor(Tradition.christian, CeremonyCategory.greeting).map((c) => c.id),
        containsAll([CeremonyId.gChristmas, CeremonyId.gEaster, CeremonyId.gNewYear]));
  });

  test('reel timeline: slow motion stretches videos, photos keep their length', () {
    final p = ReelProject(tradition: Tradition.hindu, ceremonyId: CeremonyId.wedding, clips: [
      ReelClip(type: ClipType.card, dur: 6),
      ReelClip(type: ClipType.photo, path: 'a.jpg', dur: 3.5, speed: 0.5),
      ReelClip(type: ClipType.video, path: 'b.mp4', trimIn: 1, trimOut: 4, full: 10, speed: 0.5),
    ]);
    expect(p.clips[1].length, 3.5);
    expect(p.clips[2].length, 6); // 3 s of video at 0.5×
    expect(p.total, 15.5);
    expect(p.indexAt(0), 0);
    expect(p.indexAt(7), 1);
    expect(p.indexAt(99), 2);
    expect(p.clips[2].sourceTime(2), 2); // 1 s in + 2 s × 0.5
  });

  test('reel drafts survive a JSON round trip', () {
    final d = InvitationDraft(ceremonyById(CeremonyId.wedding), tradition: Tradition.hindu);
    d.en['groom'] = 'Arjun';
    final p = newReel(d)
      ..clips.add(ReelClip(type: ClipType.photo, path: 'x.jpg', caption: 'Arjun', sub: 'Groom · వరుడు', capAnim: CaptionAnim.pop))
      ..texts.add(ReelText(text: 'Save the date', style: ReelTextStyle.neon))
      ..filter = VideoFilter.golden
      ..music = 'own'
      ..ownMusicPath = '/x/song.mp3';
    final back = ReelProject.fromJson(p.toJson().map((k, v) => MapEntry(k, v)))!;
    expect(back.clips.length, 2);
    expect(back.clips.first.type, ClipType.card);
    expect(back.clips.last.capAnim, CaptionAnim.pop);
    expect(back.clips.last.sub, 'Groom · వరుడు');
    expect(back.texts.single.style, ReelTextStyle.neon);
    expect(back.filter, VideoFilter.golden);
    expect(back.ownMusicPath, '/x/song.mp3');
    expect(back.draft().en['groom'], 'Arjun');
    final copy = back.clips.last.copy();
    expect(copy.id, isNot(back.clips.last.id));
    expect(copy.caption, 'Arjun');
  });

  test('text shows only on its clips (1 – 3 of 4)', () {
    final clips = [for (var i = 0; i < 4; i++) ReelClip(type: ClipType.photo, path: '$i.jpg', dur: 3)];
    final p = ReelProject(tradition: Tradition.hindu, ceremonyId: CeremonyId.wedding, clips: clips);
    final t = ReelText(text: 'Save the date', clipId: clips[0].id, toClipId: clips[2].id);
    expect(t.range(p.timeline, p.total), (0.0, 9.0));
    // Picked backwards still works; whole video when no clip is set.
    final back = ReelText(clipId: clips[2].id, toClipId: clips[1].id);
    expect(back.range(p.timeline, p.total), (3.0, 9.0));
    expect(ReelText().range(p.timeline, p.total), (0.0, 12.0));
    final again = ReelText.fromJson(t.toJson());
    expect(again.toClipId, clips[2].id);
    expect(again.bold, isTrue);
  });
}
