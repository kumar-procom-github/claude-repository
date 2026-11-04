import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/ceremony.dart';
import '../models/invitation_draft.dart';
import '../video/effects.dart';

/// Length of a transition, played over the end of the clip before it.
const kTransitionSeconds = 0.5;

enum ClipType { card, photo, video }

enum PhotoMotion {
  zoomIn('Zoom in', 'జూమ్ ఇన్'),
  zoomOut('Zoom out', 'జూమ్ అవుట్'),
  panLeft('Pan left', 'ఎడమకు'),
  panRight('Pan right', 'కుడికి'),
  still('Still', 'కదలకుండా');

  const PhotoMotion(this.en, this.te);
  final String en;
  final String te;
}

enum ReelTransition {
  cut('Cut', 'కట్'),
  fade('Fade', 'ఫేడ్'),
  slide('Slide', 'స్లైడ్'),
  zoom('Zoom', 'జూమ్'),
  flash('Flash', 'ఫ్లాష్'),
  spin('Spin', 'స్పిన్'),
  blur('Blur', 'బ్లర్');

  const ReelTransition(this.en, this.te);
  final String en;
  final String te;
}

/// Look of a name caption or a text overlay.
enum ReelTextStyle {
  script('Script', 'స్క్రిప్ట్'),
  classic('Classic', 'క్లాసిక్'),
  bold('Bold', 'బోల్డ్'),
  telugu('తెలుగు', 'తెలుగు'),
  neon('Neon', 'నియాన్');

  const ReelTextStyle(this.en, this.te);
  final String en;
  final String te;
}

/// How a name caption appears.
enum CaptionAnim {
  rise('Rise', 'పైకి'),
  type('Typewriter', 'టైప్'),
  pop('Pop', 'పాప్'),
  slide('Slide in', 'స్లైడ్'),
  glow('Glow', 'మెరుపు');

  const CaptionAnim(this.en, this.te);
  final String en;
  final String te;
}

const reelSpeeds = [0.3, 0.5, 1.0, 2.0, 3.0];

T _enum<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

double _d(Object? v, double fallback) => v is num ? v.toDouble() : fallback;

/// One clip on the reel's timeline: the invitation card, a photo or a video.
class ReelClip {
  ReelClip({
    String? id,
    required this.type,
    this.path,
    this.face = 0,
    this.story = false,
    this.deityIntro = true,
    this.deityPath,
    Map<String, String>? photos,
    this.photoShape = 'splash',
    this.look = 'card',
    this.dur = 3,
    this.speed = 1,
    this.motion = PhotoMotion.zoomIn,
    this.trans = ReelTransition.fade,
    this.caption = '',
    this.sub = '',
    this.capStyle = ReelTextStyle.script,
    this.capAnim = CaptionAnim.rise,
    this.trimIn = 0,
    this.trimOut = 0,
    this.full = 0,
    this.width = 0,
    this.height = 0,
  })  : id = id ?? _newId(),
        photos = photos ?? {};

  static int _seq = 0;
  static String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  final String id;
  final ClipType type;

  /// Photo / video file (in the app's folder).
  String? path;

  /// Which card face (Telugu, English, schedule…) a card clip shows.
  int face;

  /// Card clips: play the card frame by frame (story) instead of all at once.
  bool story;

  /// Story cards: show the god's picture at the start.
  bool deityIntro;

  /// The user's own picture of the god (null = Ahvanam's picture / symbol).
  String? deityPath;

  /// Story cards: photos shown above names — 'groom', 'bride' or 'main'.
  final Map<String, String> photos;

  /// Story cards: shape of the photos (PhotoShape name).
  String photoShape;

  /// Story cards: 'card' (the card's design) or 'watercolor' (watercolour flowers).
  String look;

  /// Seconds on screen for cards and photos.
  double dur;

  /// 0.3× … 3×. Videos play slower / faster; photos zoom / pan slower /
  /// faster; cards reveal their lines slower / faster.
  double speed;
  PhotoMotion motion;

  /// Transition into the next clip.
  ReelTransition trans;

  /// Name under a photo / video (bride, groom, family…), and a small line.
  String caption;
  String sub;
  ReelTextStyle capStyle;
  CaptionAnim capAnim;

  /// Part of a video that is used, in seconds of the original.
  double trimIn;
  double trimOut;

  /// Full length of the original video in seconds.
  double full;
  int width;
  int height;

  /// Seconds this clip takes in the reel.
  double get length => type == ClipType.video ? math.max(0.3, (trimOut - trimIn) / speed) : dur;

  /// Position inside the original video for [local] seconds into the clip.
  double sourceTime(double local) => (trimIn + local * speed).clamp(trimIn, math.max(trimIn, trimOut - 0.04)).toDouble();

  ReelClip copy() => ReelClip.fromJson({...toJson(), 'id': null});

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'path': path,
        'face': face,
        'story': story,
        'deityIntro': deityIntro,
        'deityPath': deityPath,
        'photos': photos,
        'photoShape': photoShape,
        'look': look,
        'dur': dur,
        'speed': speed,
        'motion': motion.name,
        'trans': trans.name,
        'caption': caption,
        'sub': sub,
        'capStyle': capStyle.name,
        'capAnim': capAnim.name,
        'trimIn': trimIn,
        'trimOut': trimOut,
        'full': full,
        'width': width,
        'height': height,
      };

  static ReelClip fromJson(Map<String, dynamic> j) => ReelClip(
        id: j['id'] as String?,
        type: _enum(ClipType.values, j['type'], ClipType.photo),
        path: j['path'] as String?,
        face: (j['face'] as num?)?.toInt() ?? 0,
        story: j['story'] == true,
        deityIntro: j['deityIntro'] != false,
        deityPath: j['deityPath'] as String?,
        photoShape: (j['photoShape'] as String?) ?? 'splash',
        look: (j['look'] as String?) ?? 'card',
        photos: {
          for (final e in ((j['photos'] as Map?) ?? const {}).entries)
            if (e.key is String && e.value is String) e.key as String: e.value as String,
        },
        dur: _d(j['dur'], 3),
        speed: _d(j['speed'], 1),
        motion: _enum(PhotoMotion.values, j['motion'], PhotoMotion.zoomIn),
        trans: _enum(ReelTransition.values, j['trans'], ReelTransition.fade),
        caption: (j['caption'] as String?) ?? '',
        sub: (j['sub'] as String?) ?? '',
        capStyle: _enum(ReelTextStyle.values, j['capStyle'], ReelTextStyle.script),
        capAnim: _enum(CaptionAnim.values, j['capAnim'], CaptionAnim.rise),
        trimIn: _d(j['trimIn'], 0),
        trimOut: _d(j['trimOut'], 0),
        full: _d(j['full'], 0),
        width: (j['width'] as num?)?.toInt() ?? 0,
        height: (j['height'] as num?)?.toInt() ?? 0,
      );
}

/// Text placed over the reel (whole reel, or only during one clip).
class ReelText {
  ReelText({
    this.text = 'Save the date',
    this.style = ReelTextStyle.script,
    this.color = 0xFFFFFFFF,
    this.y = 0.2,
    this.clipId,
    this.toClipId,
    this.font,
    this.bold = true,
    this.size = 30,
    this.anim = CaptionAnim.rise,
    this.box = 0,
  });

  String text;

  /// Older drafts' look; [font] replaces it once chosen.
  ReelTextStyle style;
  int color;

  /// Vertical position, 0 (top) … 1 (bottom).
  double y;

  /// Shown from this clip … to [toClipId] (null = the whole reel).
  String? clipId;
  String? toClipId;

  /// Google Fonts family (null = from [style]).
  String? font;
  bool bold;
  double size;
  CaptionAnim anim;

  /// 0 = plain with shadow, 1 = filled box, 2 = soft dark box.
  int box;

  /// The font family to draw with.
  String get family =>
      font ??
      switch (style) {
        ReelTextStyle.script => 'Great Vibes',
        ReelTextStyle.classic => 'Cinzel',
        ReelTextStyle.bold || ReelTextStyle.neon => 'Plus Jakarta Sans',
        ReelTextStyle.telugu => 'Ramabhadra',
      };

  /// Start and end (seconds) on [lay]; null if its clips were deleted.
  (double, double)? range(List<PlacedClip> lay, double total) {
    if (clipId == null) return (0, total);
    final from = lay.where((l) => l.clip.id == clipId);
    if (from.isEmpty) return null;
    final to = lay.where((l) => l.clip.id == (toClipId ?? clipId));
    final a = from.first, b = to.isEmpty ? from.first : to.first;
    return a.start <= b.start ? (a.start, b.end) : (b.start, a.end);
  }

  Map<String, Object?> toJson() => {
        'text': text,
        'style': style.name,
        'color': color,
        'y': y,
        'clip': clipId,
        'toClip': toClipId,
        'font': font,
        'bold': bold,
        'size': size,
        'anim': anim.name,
        'box': box,
      };

  static ReelText fromJson(Map<String, dynamic> j) => ReelText(
        text: (j['text'] as String?) ?? '',
        style: _enum(ReelTextStyle.values, j['style'], ReelTextStyle.script),
        color: (j['color'] as num?)?.toInt() ?? 0xFFFFFFFF,
        y: _d(j['y'], 0.2),
        clipId: j['clip'] as String?,
        toClipId: j['toClip'] as String?,
        font: j['font'] as String?,
        bold: j['bold'] != false,
        size: _d(j['size'], 30),
        anim: _enum(CaptionAnim.values, j['anim'], CaptionAnim.rise),
        box: (j['box'] as num?)?.toInt() ?? 0,
      );
}

/// A clip with its start / end on the timeline.
typedef PlacedClip = ({ReelClip clip, double start, double end});

/// A video invitation being edited: clips, music, text, effect and filter,
/// plus the invitation details it was made from (so drafts reopen fully).
class ReelProject extends ChangeNotifier {
  ReelProject({
    String? id,
    required this.tradition,
    required this.ceremonyId,
    List<ReelClip>? clips,
    List<ReelText>? texts,
    this.filter = VideoFilter.original,
    this.effect = VideoEffect.petals,
    this.music = 'mangalam',
    this.ownMusicPath,
    this.ownMusicName = '',
    this.musicStart = 0,
    this.volume = 0.9,
    this.templateId = '',
    this.layout = '',
    this.details,
    this.custom = false,
    DateTime? saved,
  })  : id = id ?? 'reel_${DateTime.now().millisecondsSinceEpoch}',
        clips = clips ?? [],
        texts = texts ?? [],
        saved = saved ?? DateTime.now();

  final String id;
  final Tradition tradition;
  final CeremonyId ceremonyId;
  final List<ReelClip> clips;
  final List<ReelText> texts;
  VideoFilter filter;
  VideoEffect effect;

  /// 'none', a music library track id, or 'own' (the user's song).
  String music;
  String? ownMusicPath;
  String ownMusicName;

  /// Where the song starts, in seconds.
  double musicStart;
  double volume;

  /// Card design (CardTemplate.id) and ornament layout (CardLayout.name).
  String templateId;
  String layout;

  /// InvitationDraft.toJson() of the details used for the card.
  Map<String, dynamic>? details;

  /// A plain video of the user's own photos and videos: no invitation card,
  /// no card effects or filters.
  final bool custom;
  DateTime saved;

  Ceremony get ceremony => ceremonyById(ceremonyId);

  /// Every file of the phone this reel uses (photos, videos, songs, pictures).
  List<String?> get _files => [
        for (final c in clips) ...[c.path, c.deityPath, ...c.photos.values],
        ownMusicPath,
      ];

  double get total => clips.fold(0.0, (a, c) => a + c.length);

  List<PlacedClip> get timeline {
    var t = 0.0;
    return [
      for (final c in clips) (clip: c, start: t, end: t += c.length),
    ];
  }

  /// Index of the clip playing at [t] (the last one at the very end).
  int indexAt(double t) {
    final lay = timeline;
    for (var i = 0; i < lay.length; i++) {
      if (t < lay[i].end) return i;
    }
    return lay.length - 1;
  }

  double startOf(ReelClip c) => timeline.firstWhere((p) => p.clip.id == c.id, orElse: () => (clip: c, start: 0.0, end: 0.0)).start;

  /// Call after any change: redraws the editor and saves the draft.
  void changed() => notifyListeners();

  /// Builds an [InvitationDraft] from the saved details.
  InvitationDraft draft() {
    final d = InvitationDraft(ceremony, tradition: tradition);
    final j = details;
    if (j != null) d.loadJson(j);
    return d;
  }

  Map<String, Object?> toJson() => {
        'v': 1,
        'id': id,
        'tradition': tradition.name,
        'ceremony': ceremonyId.name,
        'clips': [for (final c in clips) c.toJson()],
        'texts': [for (final t in texts) t.toJson()],
        'filter': filter.name,
        'effect': effect.name,
        'music': music,
        'ownMusicPath': ownMusicPath,
        'ownMusicName': ownMusicName,
        'musicStart': musicStart,
        'volume': volume,
        'templateId': templateId,
        'layout': layout,
        'details': details,
        'custom': custom,
        'saved': saved.toIso8601String(),
      };

  static ReelProject? fromJson(Map<String, dynamic> j) {
    final tradition = _enumOrNull(Tradition.values, j['tradition']);
    final ceremony = _enumOrNull(CeremonyId.values, j['ceremony']);
    if (tradition == null || ceremony == null) return null;
    return ReelProject(
      id: j['id'] as String?,
      tradition: tradition,
      ceremonyId: ceremony,
      clips: [
        for (final c in (j['clips'] as List? ?? const []))
          if (c is Map<String, dynamic>) ReelClip.fromJson(c),
      ],
      texts: [
        for (final t in (j['texts'] as List? ?? const []))
          if (t is Map<String, dynamic>) ReelText.fromJson(t),
      ],
      filter: _enum(VideoFilter.values, j['filter'], VideoFilter.original),
      effect: _enum(VideoEffect.values, j['effect'], VideoEffect.none),
      music: (j['music'] as String?) ?? 'none',
      ownMusicPath: j['ownMusicPath'] as String?,
      ownMusicName: (j['ownMusicName'] as String?) ?? '',
      musicStart: _d(j['musicStart'], 0),
      volume: _d(j['volume'], 0.9),
      templateId: (j['templateId'] as String?) ?? '',
      layout: (j['layout'] as String?) ?? '',
      details: j['details'] as Map<String, dynamic>?,
      custom: j['custom'] == true,
      saved: DateTime.tryParse((j['saved'] as String?) ?? ''),
    );
  }

  static T? _enumOrNull<T extends Enum>(List<T> values, Object? name) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return null;
  }
}

/// Saved reels ("Drafts"), one JSON file each in the app's support folder.
class ReelStore {
  ReelStore._();

  static Directory? _dir;

  static Future<Directory> _folder() async {
    if (_dir != null) return _dir!;
    final support = await getApplicationSupportDirectory();
    _dir = Directory('${support.path}/reels');
    await _dir!.create(recursive: true);
    return _dir!;
  }

  static Future<void> save(ReelProject p) async {
    try {
      p.saved = DateTime.now();
      final f = File('${(await _folder()).path}/${p.id}.json');
      await f.writeAsString(jsonEncode(p.toJson()), flush: true);
    } catch (e) {
      debugPrint('ReelStore.save: $e');
    }
  }

  /// Newest first.
  static Future<List<ReelProject>> list() async {
    final out = <ReelProject>[];
    try {
      await for (final f in (await _folder()).list()) {
        if (f is! File || !f.path.endsWith('.json')) continue;
        try {
          final p = ReelProject.fromJson(jsonDecode(await f.readAsString()) as Map<String, dynamic>);
          if (p != null) out.add(p);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('ReelStore.list: $e');
    }
    out.sort((a, b) => b.saved.compareTo(a.saved));
    return out;
  }

  /// Deletes the draft and the photos / videos only it used.
  static Future<void> delete(ReelProject p) async {
    try {
      final others = (await list()).where((o) => o.id != p.id);
      final used = {
        for (final o in others) ...o._files,
      };
      for (final path in p._files) {
        if (path != null && !used.contains(path)) {
          final f = File(path);
          if (await f.exists()) await f.delete();
        }
      }
      final f = File('${(await _folder()).path}/${p.id}.json');
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('ReelStore.delete: $e');
    }
  }
}
