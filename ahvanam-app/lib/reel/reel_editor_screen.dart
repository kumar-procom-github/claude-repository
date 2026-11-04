import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../ads/ads.dart';
import '../ads/banner_slot.dart';
import '../i18n/app_lang.dart';
import '../models/ceremony.dart';
import '../models/invitation_draft.dart';
import '../music/music_library.dart';
import '../screens/details_screen.dart';
import '../services/rsvp.dart';
import '../templates/card_template.dart';
import '../video/effects.dart';
import '../video/native_media.dart';
import '../wording/card_text.dart';
import '../wording/wording_engine.dart';
import 'card_story.dart';
import 'deity_art.dart';
import 'photo_shapes.dart';
import 'reel_drafts_screen.dart';
import 'reel_frame.dart';
import 'reel_project.dart';
import '../widgets/telugu_backspace.dart';

const _coral = Color(0xFFFF6B4A);
const _fps = 24;

/// Opens the video editor for the details in [d] (a new reel).
Future<void> openReelEditor(BuildContext context, InvitationDraft d) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReelEditorScreen(project: newReel(d), draft: d)));

/// Opens a saved reel (from "My videos").
Future<void> openReelProject(BuildContext context, ReelProject p, {bool replace = false}) {
  final route = MaterialPageRoute<void>(builder: (_) => ReelEditorScreen(project: p, draft: p.draft()));
  return replace ? Navigator.of(context).pushReplacement(route) : Navigator.of(context).push(route);
}

/// A plain video editor (no invitation): the user's own photos and videos.
Future<void> openCustomReel(BuildContext context) {
  final d = InvitationDraft(ceremonyById(CeremonyId.wedding), tradition: Tradition.hindu);
  final p = ReelProject(
    tradition: Tradition.hindu,
    ceremonyId: CeremonyId.wedding,
    custom: true,
    effect: VideoEffect.none,
    music: 'none',
  );
  return Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReelEditorScreen(project: p, draft: d)));
}

/// A new reel: the invitation card first, ready for the user's photos.
ReelProject newReel(InvitationDraft d) {
  final c = d.ceremony;
  final layouts = CardLayout.forTradition(d.tradition, remembrance: c.isRemembrance, greeting: c.isGreeting);
  final layout = layouts.firstWhere((l) => l.name == c.design, orElse: () => layouts.first);
  return ReelProject(
    tradition: d.tradition,
    ceremonyId: c.id,
    clips: [
      ReelClip(
        type: ClipType.card,
        story: true,
        dur: CardStory.naturalSeconds(WordingEngine.faces(d).first,
            StoryArt(deity: d.deity, info: storyInfoFor(d))),
        trans: ReelTransition.zoom,
      ),
    ],
    effect: defaultEffect(d),
    music: c.isGreeting ? 'utsavam' : 'mangalam',
    templateId: CardTemplate.defaultFor(
      tradition: d.tradition,
      remembrance: c.isRemembrance,
      ceremony: c.id,
      childGender: d.en['childGender'],
    ).id,
    layout: layout.name,
    details: d.toJson(),
  );
}

/// The effect a new reel starts with, by occasion.
VideoEffect defaultEffect(InvitationDraft d) {
  if (d.ceremony.isGreeting) return VideoEffect.confetti;
  return switch (d.tradition) {
    Tradition.muslim => VideoEffect.lights,
    Tradition.christian => VideoEffect.sparkles,
    _ => VideoEffect.petals,
  };
}

enum _Tool {
  // Whole reel
  add(Icons.add_photo_alternate_outlined, 'Add', 'జోడించు'),
  music(Icons.music_note_outlined, 'Music', 'సంగీతం'),
  text(Icons.text_fields, 'Text', 'టెక్స్ట్'),
  effects(Icons.auto_awesome_outlined, 'Effects', 'ఎఫెక్ట్స్'),
  filters(Icons.filter_vintage_outlined, 'Filters', 'ఫిల్టర్లు'),
  card(Icons.style_outlined, 'Card', 'కార్డు'),
  // Selected clip
  name(Icons.badge_outlined, 'Name', 'పేరు'),
  style(Icons.auto_stories_outlined, 'Style', 'శైలి'),
  shape(Icons.interests_outlined, 'Shape', 'ఆకారం'),
  page(Icons.description_outlined, 'Page', 'పేజీ'),
  speed(Icons.speed, 'Speed', 'వేగం'),
  length(Icons.straighten, 'Length', 'నిడివి'),
  motion(Icons.open_with, 'Motion', 'కదలిక'),
  transition(Icons.animation, 'Transition', 'మార్పు'),
  arrange(Icons.swap_horiz, 'Arrange', 'క్రమం');

  const _Tool(this.icon, this.en, this.te);
  final IconData icon;
  final String en;
  final String te;
}

class ReelEditorScreen extends StatefulWidget {
  const ReelEditorScreen({super.key, required this.project, required this.draft});

  final ReelProject project;
  final InvitationDraft draft;

  @override
  State<ReelEditorScreen> createState() => _ReelEditorScreenState();
}

class _ReelEditorScreenState extends State<ReelEditorScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ReelProject get p => widget.project;
  InvitationDraft get d => widget.draft;

  late final Ticker _ticker = createTicker(_onTick);
  final _images = ReelImages();
  final _frameKey = GlobalKey();
  final _library = MusicLibrary.instance;

  List<CardText> _faces = const [];
  double _t = 0;
  bool _playing = false;
  double _playFrom = 0;

  final _players = <String, ClipPlayer>{};
  final _creating = <String>{};
  final _thumbs = <String, ui.Image>{};
  bool _seekQueued = false;

  String? _sel;
  _Tool _tool = _Tool.add;

  final _capCtl = TextEditingController();
  final _subCtl = TextEditingController();
  final _textCtl = <ReelText, TextEditingController>{};

  Timer? _saveTimer;
  bool _dirty = false;

  // Export
  bool _exporting = false;
  bool _cancel = false;
  double _progress = 0;
  double _renderT = 0;
  final _exportFrames = <String, ui.Image>{};
  final _exportMs = <String, int>{};

  ReelClip? get _clip {
    final id = _sel;
    if (id == null) return null;
    for (final c in p.clips) {
      if (c.id == id) return c;
    }
    return null;
  }

  CardTemplate get _template {
    final list = CardTemplate.forCategory(remembrance: p.ceremony.isRemembrance, tradition: p.tradition);
    return list.firstWhere((t) => t.id == p.templateId, orElse: () => list.first);
  }

  List<CardLayout> get _layouts =>
      CardLayout.forTradition(p.tradition, remembrance: p.ceremony.isRemembrance, greeting: p.ceremony.isGreeting);

  CardLayout get _layout {
    final list = _layouts;
    return list.firstWhere((l) => l.name == p.layout, orElse: () => list.first);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faces = WordingEngine.faces(d);
    p.addListener(_onProjectChanged);
    _images.addListener(_redraw);
    for (final c in p.clips) {
      _prepare(c);
    }
    _loadDeityArt();
    unawaited(_library.load());
    // A new custom video starts by picking the user's photos and videos.
    if (p.custom && p.clips.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _addMedia();
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) precacheImage(const AssetImage('assets/brand/logo.png'), context);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _saveTimer?.cancel();
    if (_dirty) unawaited(ReelStore.save(p));
    p.removeListener(_onProjectChanged);
    _images.removeListener(_redraw);
    unawaited(NativeMedia.stop().catchError((_) {}));
    for (final pl in _players.values) {
      unawaited(pl.dispose().catchError((_) {}));
    }
    unawaited(NativeMedia.closeFrames().catchError((_) {}));
    _images.dispose();
    for (final i in _thumbs.values) {
      i.dispose();
    }
    for (final c in [_capCtl, _subCtl, ..._textCtl.values]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _playing) _pause();
  }

  void _redraw() {
    if (mounted) setState(() {});
  }

  /// Every edit: redraw, then save the draft a moment later.
  void _onProjectChanged() {
    _dirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      _dirty = false;
      unawaited(ReelStore.save(p));
    });
    if (_t > p.total) _t = p.total;
    _redraw();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// [_toast] in the app's language; safe after an await.
  void _toastTr(String en, String te) {
    if (!mounted) return;
    _toast(context.tr(en, te));
  }

  /// "Save draft" button (drafts also save on their own after every change).
  Future<void> _saveDraft() async {
    if (_playing) _pause();
    _saveTimer?.cancel();
    _dirty = false;
    await ReelStore.save(p);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 3),
        showCloseIcon: true,
        content: Text(context.tr('Draft saved. Find it in My videos.', 'డ్రాఫ్ట్ సేవ్ అయింది. "నా వీడియోలు"లో ఉంటుంది.')),
      ));
  }

  // ---- media ---------------------------------------------------------------------

  /// Ahvanam's picture of the god chosen on the details page (null = symbol).
  String? _deityArt;

  void _loadDeityArt() {
    final deity = d.deity;
    _deityArt = null;
    unawaited(DeityArt.fileFor(deity).then((f) {
      if (f == null || !mounted || d.deity != deity) return;
      setState(() => _deityArt = f.path);
      unawaited(_images.ensure(f.path));
    }));
  }

  /// Every picture a clip shows (photo, god's picture, story photos).
  List<String> _picturesOf(ReelClip c) => [
        if (c.type == ClipType.photo && c.path != null) c.path!,
        if (c.type == ClipType.card) ...[
          if (c.deityPath != null) c.deityPath! else if (_deityArt != null) _deityArt!,
          ..._photosOf(c).values,
        ],
      ];

  /// A story card's photos: the details page's, replaced by the clip's own.
  Map<String, String> _photosOf(ReelClip c) => {...d.photos, ...c.photos};

  void _prepare(ReelClip c) {
    for (final path in _picturesOf(c)) {
      unawaited(_images.ensure(path));
    }
    if (c.type == ClipType.card) {
      for (final path in _photosOf(c).values) {
        unawaited(_images.ensureFace(path));
      }
    }
    if (c.type == ClipType.video) unawaited(_thumbFor(c));
  }

  Future<ui.Image> _decode(VideoFrameData f) {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(f.rgba, f.width, f.height, ui.PixelFormat.rgba8888, done.complete);
    return done.future;
  }

  Future<void> _thumbFor(ReelClip c) async {
    final path = c.path;
    if (path == null || _thumbs.containsKey(c.id)) return;
    try {
      final img = await _decode(await NativeMedia.frameAt(path, (c.trimIn * 1000).round(), maxSide: 360));
      if (!mounted) {
        img.dispose();
        return;
      }
      setState(() => _thumbs[c.id] = img);
    } catch (e) {
      debugPrint('thumb: $e');
    }
  }

  Future<ClipPlayer?> _player(ReelClip c) async {
    final have = _players[c.id];
    if (have != null) return have;
    final path = c.path;
    if (path == null || !_creating.add(c.id)) return null;
    try {
      final pl = await ClipPlayer.create(path);
      if (!mounted) {
        unawaited(pl.dispose());
        return null;
      }
      await pl.seek((c.trimIn * 1000).round());
      _players[c.id] = pl;
      _redraw();
      return pl;
    } catch (e) {
      debugPrint('player: $e');
      return null;
    } finally {
      _creating.remove(c.id);
    }
  }

  Widget _videoPreview(ReelClip c, double local) {
    final pl = _players[c.id];
    if (pl == null) {
      unawaited(_player(c));
      final th = _thumbs[c.id];
      return th == null
          ? const ColoredBox(color: Colors.black)
          : RawImage(image: th, fit: BoxFit.cover, width: kReelW, height: kReelH);
    }
    final turns = (pl.rotation ~/ 90) % 4;
    final w = pl.width.clamp(1, 4096).toDouble(), h = pl.height.clamp(1, 4096).toDouble();
    // When the texture already turns the video upright, use the upright size
    // read when it was picked.
    final shown = turns == 0 && c.width > 0 && c.height > 0;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: RotatedBox(
        quarterTurns: turns,
        child: SizedBox(
          width: shown ? c.width.toDouble() : w,
          height: shown ? c.height.toDouble() : h,
          child: Texture(textureId: pl.textureId),
        ),
      ),
    );
  }

  Widget _videoExport(ReelClip c, double local) {
    final img = _exportFrames[c.id];
    return img == null
        ? const ColoredBox(color: Colors.black)
        : RawImage(image: img, fit: BoxFit.cover, width: kReelW, height: kReelH);
  }

  // ---- playback --------------------------------------------------------------------

  Future<String?> _songPath() async {
    switch (p.music) {
      case 'none':
        return null;
      case 'own':
        final path = p.ownMusicPath;
        return path != null && File(path).existsSync() ? path : null;
    }
    for (final track in _library.all) {
      if (track.id == p.music) return (await _library.fileFor(track)).path;
    }
    return null;
  }

  Future<void> _play() async {
    if (p.clips.isEmpty || _exporting) return;
    if (_t >= p.total - 0.05) _t = 0;
    _playFrom = _t;
    setState(() => _playing = true);
    _ticker
      ..stop()
      ..start();
    _syncVideos();
    await _startSong();
  }

  Future<void> _startSong() async {
    try {
      final path = await _songPath();
      if (path == null || !_playing) return;
      await NativeMedia.play(path, startMs: ((p.musicStart + _t) * 1000).round(), volume: p.volume);
    } catch (e) {
      _toastTr('Music needs internet the first time.', 'మొదటిసారి సంగీతానికి ఇంటర్నెట్ కావాలి.');
    }
  }

  void _pause() {
    if (!_playing) return;
    _ticker.stop();
    setState(() => _playing = false);
    unawaited(NativeMedia.stop().catchError((_) {}));
    for (final pl in _players.values) {
      unawaited(pl.pause().catchError((_) {}));
    }
    _showStill();
  }

  void _onTick(Duration elapsed) {
    final total = p.total;
    final t = _playFrom + elapsed.inMicroseconds / 1e6;
    if (t >= total) {
      _t = total;
      _pause();
      return;
    }
    setState(() => _t = t);
    _syncVideos();
  }

  /// While playing: the current video clip plays at its speed; others wait
  /// at their first frame so transitions into them look right.
  void _syncVideos() {
    final lay = p.timeline;
    if (lay.isEmpty) return;
    final i = p.indexAt(_t);
    final cur = lay[i];
    if (i + 1 < lay.length && lay[i + 1].clip.type == ClipType.video) unawaited(_player(lay[i + 1].clip));
    for (final c in p.clips) {
      final pl = _players[c.id];
      if (pl == null) continue;
      if (c.id == cur.clip.id) {
        if (!pl.playing) {
          final ms = (c.sourceTime(_t - cur.start) * 1000).round();
          unawaited(pl.seek(ms).then((_) => pl.play(speed: c.speed)).catchError((_) {}));
          pl.playing = true;
        }
      } else if (pl.playing) {
        unawaited(pl.pause().then((_) => pl.seek((c.trimIn * 1000).round())).catchError((_) {}));
      }
    }
  }

  /// Paused / scrubbing: show the exact frame of the video under the playhead.
  void _showStill() {
    if (_seekQueued) return;
    _seekQueued = true;
    Future.delayed(const Duration(milliseconds: 60), () async {
      _seekQueued = false;
      if (!mounted || p.clips.isEmpty) return;
      final lay = p.timeline;
      final i = p.indexAt(_t);
      final cur = lay[i];
      final c = cur.clip;
      if (c.type != ClipType.video) return;
      final pl = await _player(c);
      try {
        await pl?.seek((c.sourceTime(_t - cur.start) * 1000).round());
      } catch (_) {}
    });
  }

  void _seek(double t) {
    if (_playing) _pause();
    setState(() => _t = t.clamp(0.0, p.total).toDouble());
    _showStill();
  }

  // ---- selection & edits ------------------------------------------------------------------

  void _select(ReelClip? c) {
    setState(() {
      _sel = c?.id;
      if (c == null) {
        if (!_mainTools.contains(_tool)) _tool = _Tool.add;
      } else {
        _capCtl.text = c.caption;
        _subCtl.text = c.sub;
        final tools = _clipTools(c);
        if (!tools.contains(_tool)) _tool = tools.first;
      }
    });
    if (c != null) _seek(p.startOf(c) + 0.01);
  }

  /// Whole-reel tools. A custom video has no card, effects or filters.
  List<_Tool> get _mainTools => p.custom
      ? const [_Tool.add, _Tool.music, _Tool.text]
      : const [_Tool.add, _Tool.music, _Tool.text, _Tool.effects, _Tool.filters, _Tool.card];

  List<_Tool> _clipTools(ReelClip c) => [
        if (c.type != ClipType.card) _Tool.name,
        if (c.type == ClipType.card) _Tool.style,
        if (c.type == ClipType.card && c.story) _Tool.shape,
        if (c.type == ClipType.card && _faces.length > 1) _Tool.page,
        _Tool.speed,
        _Tool.length,
        if (c.type == ClipType.photo) _Tool.motion,
        _Tool.transition,
        _Tool.arrange,
      ];

  void _edit(VoidCallback change) {
    change();
    p.changed();
  }

  Future<void> _addMedia() async {
    if (_playing) _pause();
    List<PickedMedia> picked;
    try {
      picked = await NativeMedia.pickMedia();
    } catch (e) {
      _toastTr('Could not open your photos.', 'ఫోటోలు తెరవలేకపోయాం.');
      return;
    }
    if (picked.isEmpty || !mounted) return;
    final sel = _clip;
    var at = sel == null ? p.clips.length : p.clips.indexOf(sel) + 1;
    final added = <ReelClip>[];
    var zoomIn = true;
    for (final m in picked) {
      final ReelClip c;
      if (m.isVideo) {
        final full = m.durationMs / 1000;
        c = ReelClip(
          type: ClipType.video,
          path: m.path,
          full: full,
          trimIn: 0,
          trimOut: full > 0 ? full : 3.0,
          width: m.width,
          height: m.height,
          trans: ReelTransition.fade,
        );
      } else {
        c = ReelClip(
          type: ClipType.photo,
          path: m.path,
          dur: 3,
          motion: zoomIn ? PhotoMotion.zoomIn : PhotoMotion.zoomOut,
          trans: ReelTransition.fade,
        );
        zoomIn = !zoomIn;
      }
      added.add(c);
      p.clips.insert(at++, c);
      _prepare(c);
    }
    p.changed();
    _select(added.first);
    _toastTr('Added ${added.length}. Tap a clip to add a name, speed or effects.',
        '${added.length} జోడించాం. పేరు, వేగం మార్చడానికి క్లిప్‌ను నొక్కండి.');
  }

  void _addCardPage(int face) {
    final sel = _clip;
    final at = sel == null ? p.clips.length : p.clips.indexOf(sel) + 1;
    final c = ReelClip(
        type: ClipType.card, face: face, story: true, trans: ReelTransition.zoom);
    c.dur = _storySeconds(c);
    _edit(() => p.clips.insert(at, c));
    _select(c);
  }

  void _duplicate(ReelClip c) {
    final copy = c.copy();
    _edit(() => p.clips.insert(p.clips.indexOf(c) + 1, copy));
    _prepare(copy);
    _select(copy);
  }

  void _delete(ReelClip c) {
    if (p.clips.length <= 1) {
      _toastTr('A video needs at least one clip.', 'వీడియోలో కనీసం ఒక క్లిప్ ఉండాలి.');
      return;
    }
    if (_playing) _pause();
    _edit(() {
      p.clips.remove(c);
      p.texts.removeWhere((t) => t.clipId == c.id);
    });
    final pl = _players.remove(c.id);
    if (pl != null) unawaited(pl.dispose().catchError((_) {}));
    _thumbs.remove(c.id)?.dispose();
    _select(null);
    _seek(_t);
  }

  void _move(ReelClip c, int by) {
    final i = p.clips.indexOf(c), j = i + by;
    if (j < 0 || j >= p.clips.length) return;
    _edit(() {
      p.clips.removeAt(i);
      p.clips.insert(j, c);
    });
    _seek(p.startOf(c) + 0.01);
  }

  Future<void> _editDetails() async {
    if (_playing) _pause();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DetailsScreen(draft: d, editOnly: true)));
    if (!mounted) return;
    _faces = WordingEngine.faces(d);
    _loadDeityArt(); // the god may have changed
    _edit(() {
      p.details = d.toJson();
      for (final c in p.clips) {
        if (c.face >= _faces.length) c.face = 0;
        // New wording → the story's frames change length.
        if (c.type == ClipType.card && c.story) c.dur = _storySeconds(c) / c.speed;
      }
    });
  }

  /// Natural length of a card page played as a story, at 1×.
  double _storySeconds(ReelClip c) => _faces.isEmpty
      ? 6
      : CardStory.naturalSeconds(
          _faces[c.face.clamp(0, _faces.length - 1)], StoryArt(deity: d.deity, intro: c.deityIntro, info: _storyInfo));

  StoryInfo get _storyInfo => storyInfoFor(d);

  /// Photo slots of a story card ('groom', 'bride' or 'main').
  List<String> _photoSlots(ReelClip c) =>
      _faces.isEmpty ? const [] : CardStory.photoKeys(_faces[c.face.clamp(0, _faces.length - 1)], _storyInfo);

  String _slotLabel(String key) {
    final muslim = p.tradition == Tradition.muslim;
    return switch (key) {
      'groom' => muslim ? context.tr('Dulha photo', 'దుల్హా ఫోటో') : context.tr('Groom photo', 'వరుడి ఫోటో'),
      'couple' => context.tr('Couple photo (together)', 'దంపతుల ఫోటో'),
      'bride' => muslim ? context.tr('Dulhan photo', 'దుల్హన్ ఫోటో') : context.tr('Bride photo', 'వధువు ఫోటో'),
      _ => context.tr('Photo', 'ఫోటో'),
    };
  }

  /// One photo from the phone (null if cancelled).
  Future<String?> _pickOnePhoto() async {
    if (_playing) _pause();
    try {
      final picked = await NativeMedia.pickMedia();
      for (final m in picked) {
        if (!m.isVideo) return m.path;
      }
    } catch (_) {
      _toastTr('Could not open your photos.', 'ఫోటోలు తెరవలేకపోయాం.');
    }
    return null;
  }

  /// Photos belong to the details (so every video of this function has them).
  Future<void> _setStoryPhoto(ReelClip c, String key) async {
    final path = await _pickOnePhoto();
    if (path == null || !mounted) return;
    _setPhoto(c, key, path);
    unawaited(_images.ensure(path));
    unawaited(_images.ensureFace(path));
  }

  void _setPhoto(ReelClip c, String key, String? path) {
    d.setPhoto(key, path);
    _edit(() {
      c.photos.remove(key);
      p.details = d.toJson();
    });
  }

  Future<void> _setDeityPicture(ReelClip c) async {
    final path = await _pickOnePhoto();
    if (path == null || !mounted) return;
    _edit(() => c.deityPath = path);
    unawaited(_images.ensure(path));
    _seek(p.startOf(c) + 0.01);
    _play();
  }

  Widget _thumbBox(String? path, {double w = 44, double h = 44}) {
    final img = _images[path];
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: w,
        height: h,
        child: img == null
            ? const ColoredBox(color: Colors.white10, child: Icon(Icons.image_outlined, size: 18, color: Colors.white38))
            : RawImage(image: img, fit: BoxFit.cover),
      ),
    );
  }

  List<Widget> _storyExtras(ReelClip c) {
    final deity = d.deity;
    return [
      if (deity != Deity.none) ...[
        _label(context.tr('God at the start', 'మొదట దేవుని చిత్రం')),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text('${deity.te} · ${deity.en}'),
          subtitle: Text(c.deityPath != null
              ? context.tr('Your picture', 'మీ చిత్రం')
              : _deityArt != null
                  ? context.tr("Ahvanam's picture", 'ఆహ్వానం చిత్రం')
                  : context.tr('Drawn symbol (add your own picture for a photo)', 'గీసిన గుర్తు (ఫోటో కోసం మీ చిత్రం జోడించండి)')),
          value: c.deityIntro,
          onChanged: (on) {
            _edit(() {
              c.deityIntro = on;
              c.dur = _storySeconds(c) / c.speed;
            });
            _seek(p.startOf(c) + 0.01);
          },
        ),
        if (c.deityIntro)
          Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (c.deityPath != null) _thumbBox(c.deityPath),
              OutlinedButton.icon(
                onPressed: () => _setDeityPicture(c),
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: Text(c.deityPath == null
                    ? context.tr('Use my own picture', 'నా చిత్రం వాడండి')
                    : context.tr('Change', 'మార్చు')),
              ),
              if (c.deityPath != null)
                TextButton(
                  onPressed: () => _edit(() => c.deityPath = null),
                  child: Text(context.tr('Use default', 'డిఫాల్ట్')),
                ),
            ],
          ),
      ],
      if (_photoSlots(c).isNotEmpty) ...[
        _label(context.tr('Photos on the frames (optional)', 'ఫ్రేమ్‌లపై ఫోటోలు (ఐచ్ఛికం)')),
        for (final key in _photoSlots(c))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                _thumbBox(_photosOf(c)[key]),
                const SizedBox(width: 10),
                Expanded(child: Text(_slotLabel(key))),
                TextButton(
                  onPressed: () => _setStoryPhoto(c, key),
                  child: Text(_photosOf(c)[key] == null
                      ? context.tr('+ Add', '+ జోడించు')
                      : context.tr('Change', 'మార్చు')),
                ),
                if (_photosOf(c)[key] != null)
                  IconButton(
                    tooltip: context.tr('Remove', 'తీసివేయి'),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _setPhoto(c, key, null),
                  ),
              ],
            ),
          ),
      ],
    ];
  }

  /// Photo shapes, each shown with the user's own photo (like Filters).
  Widget _shapeTray(ReelClip c) {
    final photos = _photosOf(c);
    final key = ['groom', 'bride', 'couple', 'main'].firstWhere((k) => photos[k] != null, orElse: () => '');
    final path = photos[key];
    final img = _images[path];
    final accent = _template.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final shape in PhotoShape.values)
                GestureDetector(
                  onTap: () {
                    _edit(() => c.photoShape = shape.name);
                    // Jump to the first photo frame to see it.
                    _seek(p.startOf(c) + 0.01);
                    _play();
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 78,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: c.photoShape == shape.name ? Colors.white : Colors.transparent, width: 2),
                          ),
                          child: img == null
                              ? CustomPaint(painter: _ShapeIconPainter(shape, accent))
                              : FittedBox(
                                  child: ShapedPhoto(
                                      image: img, shape: shape, color: accent, face: _images.face(path), height: 120),
                                ),
                        ),
                        const SizedBox(height: 3),
                        Text(context.tr(shape.en, shape.te),
                            style: TextStyle(
                                fontSize: 10.5,
                                color: c.photoShape == shape.name ? Colors.white : Colors.white60)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _note(img == null
            ? context.tr('Add photos of the groom, bride or couple (Style tool or the details page) to see them here.',
                'వరుడు, వధువు లేదా దంపతుల ఫోటోలు జోడించండి (శైలి లేదా వివరాల పేజీ).')
            : context.tr('The face is found and zoomed in automatically.', 'ముఖం ఆటోమేటిక్‌గా జూమ్ అవుతుంది.')),
      ],
    );
  }

  Widget _styleTray(ReelClip c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context.tr('How the card plays', 'కార్డు ఎలా ప్లే అవ్వాలి')),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.auto_stories_outlined, size: 16),
                label: Text(context.tr('Story · frame by frame', 'కథలా · ఒక్కొక్కటిగా')),
                selected: c.story,
                onSelected: (_) {
                  _edit(() {
                    c.story = true;
                    c.dur = _storySeconds(c) / c.speed;
                  });
                  _seek(p.startOf(c) + 0.01);
                  _play();
                },
              ),
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.crop_portrait, size: 16),
                label: Text(context.tr('Full card', 'పూర్తి కార్డు')),
                selected: !c.story,
                onSelected: (_) {
                  _edit(() {
                    c.story = false;
                    c.dur = 6;
                  });
                  _seek(p.startOf(c) + 0.01);
                  _play();
                },
              ),
            ],
          ),
          _note(c.story
              ? context.tr(
                  'The empty card first, then its art slides in and the words play frame by frame: heading → date & muhurtham → venue → wishes.',
                  'ముందు ఖాళీ కార్డు, తర్వాత డిజైన్ లోపలికి వస్తుంది, మాటలు ఒక్కో భాగంగా: శీర్షిక → తేదీ & ముహూర్తం → వేదిక → ఆహ్వానం.')
              : context.tr('The whole card with its lines appearing one by one.', 'మొత్తం కార్డు, వాక్యాలు ఒక్కొక్కటిగా.')),
          if (c.story) ...[
            _label(context.tr('Look', 'రూపం')),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (look, en, te, icon) in const [
                  ('card', 'Card design', 'కార్డు డిజైన్', Icons.style_outlined),
                  ('watercolor', 'Watercolour flowers', 'వాటర్‌కలర్ పూలు', Icons.local_florist_outlined),
                ])
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(icon, size: 16),
                    label: Text(context.tr(en, te)),
                    selected: c.look == look,
                    onSelected: (_) {
                      _edit(() => c.look = look);
                      _seek(p.startOf(c) + 0.01);
                      _play();
                    },
                  ),
              ],
            ),
            ..._storyExtras(c),
          ],
        ],
      );

  /// Quick names from the details page: (chip label, caption, small line, style).
  List<(String, String, String, ReelTextStyle)> _quickNames() {
    String en(String k) => (d.en[k] ?? '').trim();
    String te(String k) => (d.te[k] ?? '').trim();
    final date = d.date;
    final dateLine = date == null
        ? ''
        : '${date.day.toString().padLeft(2, '0')} · ${date.month.toString().padLeft(2, '0')} · ${date.year}';
    final out = <(String, String, String, ReelTextStyle)>[];
    void person(String key, String roleEn, String roleTe) {
      if (en(key).isNotEmpty) out.add(('$roleEn: ${en(key)}', en(key), '$roleEn · $roleTe', ReelTextStyle.script));
      if (te(key).isNotEmpty) out.add(('$roleTe: ${te(key)}', te(key), roleTe, ReelTextStyle.telugu));
    }

    final muslim = p.tradition == Tradition.muslim;
    person('groom', muslim ? 'Dulha' : 'Groom', muslim ? 'దుల్హా' : 'వరుడు');
    person('bride', muslim ? 'Dulhan' : 'Bride', muslim ? 'దుల్హన్' : 'వధువు');
    if (en('groom').isNotEmpty && en('bride').isNotEmpty) {
      out.add(('${en('groom')} ♥ ${en('bride')}', '${en('groom')} ♥ ${en('bride')}', dateLine, ReelTextStyle.classic));
    }
    if (te('groom').isNotEmpty && te('bride').isNotEmpty) {
      out.add(('${te('groom')} ♥ ${te('bride')}', '${te('groom')} ♥ ${te('bride')}', dateLine, ReelTextStyle.telugu));
    }
    for (final (k, ren, rte) in const [
      ('child', 'Little star', 'చిన్నారి'),
      ('boy', 'Our boy', 'మా అబ్బాయి'),
      ('husband', 'Husband', 'భర్త'),
      ('wife', 'Wife', 'భార్య'),
      ('hosts', 'Hosts', 'ఆతిథ్యం'),
    ]) {
      person(k, ren, rte);
    }
    return out;
  }

  // ---- export -----------------------------------------------------------------------

  Future<void> _export() async {
    if (!NativeMedia.videoSupported) {
      _toastTr('Video export works on Android phones.', 'వీడియో ఎగుమతి ఆండ్రాయిడ్ ఫోన్‌లలో పనిచేస్తుంది.');
      return;
    }
    if (p.clips.isEmpty) return;
    _pause();
    setState(() {
      _sel = null;
      _exporting = true;
      _cancel = false;
      _progress = 0;
      _renderT = 0;
    });
    String? out;
    var started = false;
    try {
      try {
        await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 8));
      } catch (_) {}
      // Every photo decoded before the first frame.
      for (final path in [for (final c in p.clips) ..._picturesOf(c)]) {
        unawaited(_images.ensure(path));
        for (var i = 0; i < 100 && _images[path] == null && !_images.failed(path); i++) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      String? song;
      try {
        song = await _songPath();
      } catch (_) {
        _toastTr('Music could not download — making the video without it.',
            'సంగీతం డౌన్‌లోడ్ కాలేదు — సంగీతం లేకుండా వీడియో తయారు చేస్తున్నాం.');
      }
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/ahvanam_${p.ceremonyId.name}_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final frames = (p.total * _fps).ceil();
      await NativeMedia.startVideo(path: path, width: 720, height: 1280, fps: _fps);
      started = true;
      for (var f = 0; f < frames; f++) {
        if (_cancel || !mounted) {
          await NativeMedia.cancelVideo();
          started = false;
          return;
        }
        final t = f / _fps;
        final old = await _videoFramesFor(t);
        setState(() => _renderT = t);
        await WidgetsBinding.instance.endOfFrame;
        final boundary = _frameKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        for (final o in old) {
          o.dispose();
        }
        await NativeMedia.addFrame(bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        if (f % 3 == 0 && mounted) setState(() => _progress = (f + 1) / frames);
      }
      if (mounted) setState(() => _progress = 1);
      out = await NativeMedia.finishVideo(
        audioPath: song,
        audioStartMs: (p.musicStart * 1000).round(),
        volume: p.volume,
        fadeOutMs: 1500,
      );
      started = false;
    } catch (e) {
      debugPrint('export: $e');
      if (started) unawaited(NativeMedia.cancelVideo().catchError((_) {}));
      _toastTr('Could not make the video. Please try again.', 'వీడియో తయారు కాలేదు. మళ్ళీ ప్రయత్నించండి.');
    } finally {
      for (final i in _exportFrames.values) {
        i.dispose();
      }
      _exportFrames.clear();
      _exportMs.clear();
      unawaited(NativeMedia.closeFrames().catchError((_) {}));
      if (mounted) setState(() => _exporting = false);
    }
    if (out != null && mounted) await _done(out);
  }

  /// Decodes the exact frames of the video clips visible at [t]. Returns
  /// the images they replace (disposed after the frame is captured).
  Future<List<ui.Image>> _videoFramesFor(double t) async {
    final lay = p.timeline;
    final i = p.indexAt(t);
    final a = lay[i];
    final la = t - a.start;
    final need = <(ReelClip, double)>[(a.clip, la)];
    if (i + 1 < lay.length && a.clip.trans != ReelTransition.cut && la > a.clip.length - kTransitionSeconds) {
      need.add((lay[i + 1].clip, 0));
    }
    final old = <ui.Image>[];
    for (final (c, local) in need) {
      if (c.type != ClipType.video || c.path == null) continue;
      final ms = (c.sourceTime(local) * 1000).round();
      if (_exportMs[c.id] == ms && _exportFrames.containsKey(c.id)) continue;
      try {
        final img = await _decode(await NativeMedia.frameAt(c.path!, ms, maxSide: 1280));
        final prev = _exportFrames[c.id];
        if (prev != null) old.add(prev);
        _exportFrames[c.id] = img;
        _exportMs[c.id] = ms;
      } catch (e) {
        debugPrint('frameAt: $e');
      }
    }
    return old;
  }

  Future<void> _done(String path) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 44),
              const SizedBox(height: 8),
              Text('Your video is ready · మీ వీడియో సిద్ధం',
                  textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('${p.total.toStringAsFixed(0)} s · 720 × 1280 · MP4',
                  textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.bodySmall),
              const SizedBox(height: 18),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: const Color(0xFF25A35A)),
                onPressed: () async {
                  try {
                    await SharePlus.instance.share(ShareParams(
                      files: [XFile(path, mimeType: 'video/mp4')],
                      text: Rsvp.shareCaption(d),
                    ));
                  } catch (e) {
                    _toast('Could not share: $e');
                  }
                },
                icon: const Icon(Icons.share),
                label: const Text('Share on WhatsApp… · షేర్'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () async {
                  await Ads.beforeSave();
                  try {
                    if (!await Gal.hasAccess(toAlbum: true) && !await Gal.requestAccess(toAlbum: true)) {
                      _toast('Allow photo access to save · అనుమతి ఇవ్వండి');
                      return;
                    }
                    await Gal.putVideo(path, album: 'Ahvanam');
                    _toast('Saved to your gallery · గ్యాలరీలో సేవ్ అయింది');
                  } catch (e) {
                    _toast('Could not save: $e');
                  }
                },
                icon: const Icon(Icons.download_outlined),
                label: const Text('Save to gallery · గ్యాలరీలో సేవ్'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- UI ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final dark = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(seedColor: base.colorScheme.primary, brightness: Brightness.dark),
      textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
    );
    return Theme(
      data: dark,
      child: Builder(builder: (context) {
        return PopScope(
          canPop: !_exporting,
          child: Scaffold(
            backgroundColor: const Color(0xFF0E0E14),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0E0E14),
              title: Text(context.tr('Video', 'వీడియో')),
              actions: [
                IconButton(
                  tooltip: context.tr('Save draft', 'డ్రాఫ్ట్ సేవ్'),
                  icon: const Icon(Icons.save_outlined),
                  onPressed: _exporting ? null : _saveDraft,
                ),
                IconButton(
                  tooltip: context.tr('My videos', 'నా వీడియోలు'),
                  icon: const Icon(Icons.video_library_outlined),
                  onPressed: _exporting
                      ? null
                      : () async {
                          _pause();
                          await ReelStore.save(p);
                          if (!mounted) return;
                          final other = await Navigator.of(this.context).push<ReelProject>(
                              MaterialPageRoute(builder: (_) => ReelDraftsScreen(currentId: p.id)));
                          if (other != null && mounted) await openReelProject(this.context, other, replace: true);
                        },
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: _coral, foregroundColor: Colors.white),
                    onPressed: _exporting ? null : _export,
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: Text(context.tr('Export', 'ఎగుమతి')),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _stage()),
                  _transport(),
                  if (p.texts.isNotEmpty && !_exporting) _textTrack(),
                  _timeline(),
                  if (!_exporting) ...[
                    if (_clip != null) _clipBar(_clip!),
                    _toolTabs(),
                    SizedBox(height: 150, child: _tray()),
                  ],
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _stage() {
    final frame = RepaintBoundary(
      key: _frameKey,
      child: ReelFrame(
        project: p,
        t: _exporting ? _renderT : _t,
        faces: _faces,
        template: _template,
        layout: _layout,
        images: _images,
        deity: d.deity,
        deityArtPath: _deityArt,
        storyInfo: _storyInfo,
        defaultPhotos: d.photos,
        video: _exporting ? _videoExport : _videoPreview,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: GestureDetector(
            onTap: _exporting ? null : (_playing ? _pause : _play),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FittedBox(child: frame),
                  if (!_playing && !_exporting)
                    const Center(
                      child: CircleAvatar(
                        radius: 26,
                        backgroundColor: Color(0x66000000),
                        child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                      ),
                    ),
                  if (_exporting) _exportOverlay(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _exportOverlay() => ColoredBox(
        color: const Color(0x99000000),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Making your video… ${(_progress * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                const Text('వీడియో తయారవుతోంది', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: _progress, color: _coral, backgroundColor: Colors.white24),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => setState(() => _cancel = true),
                  child: const Text('Cancel · ఆపు', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );

  String _clock(double s) {
    final whole = s.floor();
    return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
  }

  Widget _transport() {
    final total = p.total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          IconButton(
            onPressed: _exporting ? null : (_playing ? _pause : _play),
            icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
          Text('${_clock(_exporting ? _renderT : _t)} / ${_clock(total)}',
              style: const TextStyle(fontFeatures: [ui.FontFeature.tabularFigures()], fontSize: 12)),
          Expanded(
            child: Slider(
              value: (_exporting ? _renderT : _t).clamp(0.0, total <= 0 ? 0.01 : total).toDouble(),
              max: total <= 0 ? 0.01 : total,
              onChanged: _exporting ? null : _seek,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeline() {
    final scheme = Theme.of(context).colorScheme;
    final current = p.clips.isEmpty ? null : p.clips[p.indexAt(_exporting ? _renderT : _t)];
    return SizedBox(
      height: 68,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: p.clips.length,
        buildDefaultDragHandles: !_exporting,
        onReorderItem: (from, to) {
          final c = p.clips[from];
          _edit(() {
            p.clips.removeAt(from);
            p.clips.insert(to, c);
          });
        },
        footer: _exporting
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _addMedia,
                  child: Container(
                    width: 52,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
        itemBuilder: (context, i) {
          final c = p.clips[i];
          final selected = c.id == _sel;
          final playing = identical(c, current);
          return Padding(
            key: ValueKey(c.id),
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: _exporting ? null : () => selected ? _select(null) : _select(c),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: (c.length * 16).clamp(48.0, 150.0).toDouble(),
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? Colors.white : (playing ? scheme.primary : Colors.transparent),
                    width: selected ? 2.5 : 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _thumb(c),
                      Positioned(
                        left: 4,
                        bottom: 3,
                        child: Text(
                          '${c.length.toStringAsFixed(1)}s${c.speed != 1 ? ' · ${_speedLabel(c.speed)}' : ''}',
                          style: const TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              shadows: [Shadow(blurRadius: 3)]),
                        ),
                      ),
                      if (c.caption.isNotEmpty)
                        const Positioned(
                            right: 3, top: 3, child: Icon(Icons.badge, size: 12, color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _thumb(ReelClip c) {
    switch (c.type) {
      case ClipType.card:
        final t = _template;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: t.background.length >= 2 ? t.background : [t.background.first, t.background.first],
            ),
          ),
          child: Center(child: Icon(Icons.mail_outline, color: t.accent, size: 22)),
        );
      case ClipType.photo:
        final img = _images[c.path];
        return img == null
            ? const ColoredBox(color: Colors.white10, child: Icon(Icons.image_outlined, color: Colors.white38))
            : RawImage(image: img, fit: BoxFit.cover);
      case ClipType.video:
        final img = _thumbs[c.id];
        return Stack(
          fit: StackFit.expand,
          children: [
            if (img != null) RawImage(image: img, fit: BoxFit.cover) else const ColoredBox(color: Colors.white10),
            const Positioned(right: 3, bottom: 3, child: Icon(Icons.videocam, size: 12, color: Colors.white)),
          ],
        );
    }
  }

  String _speedLabel(double s) => '${s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toString()}×';

  String _clipName(ReelClip c) => switch (c.type) {
        ClipType.card => context.tr('Invitation card', 'ఆహ్వాన పత్రిక'),
        ClipType.photo => context.tr('Photo', 'ఫోటో'),
        ClipType.video => context.tr('Video', 'వీడియో'),
      };

  Widget _clipBar(ReelClip c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 8, 0),
        child: Row(
          children: [
            Expanded(
              child: Text('${_clipName(c)} · ${c.length.toStringAsFixed(1)} s',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: context.tr('Duplicate', 'నకలు'),
              icon: const Icon(Icons.copy_all_outlined, size: 20),
              onPressed: () => _duplicate(c),
            ),
            IconButton(
              tooltip: context.tr('Delete', 'తొలగించు'),
              icon: const Icon(Icons.delete_outline, size: 20),
              onPressed: () => _delete(c),
            ),
            TextButton(onPressed: () => _select(null), child: Text(context.tr('Done', 'సరే'))),
          ],
        ),
      );

  Widget _toolTabs() {
    final c = _clip;
    final tools = c == null ? _mainTools : _clipTools(c);
    return SizedBox(
      height: 58,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final t in tools)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _tool = t),
              child: Container(
                width: 66,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: t == _tool ? Colors.white12 : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.icon, size: 22, color: t == _tool ? Colors.white : Colors.white70),
                    const SizedBox(height: 2),
                    Text(
                      t == _Tool.length && c?.type == ClipType.video ? context.tr('Trim', 'కత్తిరించు') : context.tr(t.en, t.te),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: t == _tool ? Colors.white : Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- trays ------------------------------------------------------------------------

  Widget _label(String s) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white60, fontWeight: FontWeight.w600)),
      );

  Widget _note(String s) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(s, style: const TextStyle(fontSize: 11.5, color: Colors.white54)),
      );

  Widget _chips<T>(List<T> values, T? selected, String Function(T) label, void Function(T) onTap,
          {IconData? Function(T)? icon}) =>
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final v in values)
            ChoiceChip(
              visualDensity: VisualDensity.compact,
              avatar: icon?.call(v) == null ? null : Icon(icon!(v), size: 16),
              label: Text(label(v)),
              selected: v == selected,
              onSelected: (_) => onTap(v),
            ),
        ],
      );

  Widget _tray() {
    final c = _clip;
    final Widget body = switch (_tool) {
      _Tool.add => _addTray(),
      _Tool.music => _musicTray(),
      _Tool.text => _textTray(),
      _Tool.effects => _effectsTray(),
      _Tool.filters => _filtersTray(),
      _Tool.card => _cardTray(),
      _Tool.name => c == null ? const SizedBox() : _nameTray(c),
      _Tool.style => c == null ? const SizedBox() : _styleTray(c),
      _Tool.shape => c == null ? const SizedBox() : _shapeTray(c),
      _Tool.page => c == null ? const SizedBox() : _pageTray(c),
      _Tool.speed => c == null ? const SizedBox() : _speedTray(c),
      _Tool.length => c == null ? const SizedBox() : _lengthTray(c),
      _Tool.motion => c == null ? const SizedBox() : _motionTray(c),
      _Tool.transition => c == null ? const SizedBox() : _transitionTray(c),
      _Tool.arrange => c == null ? const SizedBox() : _arrangeTray(c),
    };
    // The ad sits after the tools: seen only when scrolled to the end.
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      children: [body, const BannerSlot(padding: EdgeInsets.only(top: 20))],
    );
  }

  Widget _addTray() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.icon(
            onPressed: _addMedia,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(context.tr('Photos & videos from your phone', 'ఫోన్ నుండి ఫోటోలు & వీడియోలు')),
          ),
          _note(context.tr(
              'Pick one or many. They are added after the selected clip (or at the end). Long-press a clip to drag it.',
              'ఒకటి లేదా ఎక్కువ ఎంచుకోండి. ఎంచుకున్న క్లిప్ తర్వాత చేరుతాయి. క్రమం మార్చడానికి క్లిప్‌ను నొక్కి పట్టి లాగండి.')),
          _label(context.tr('Invitation card pages', 'ఆహ్వాన పత్రిక పేజీలు')),
          Wrap(
            spacing: 6,
            children: [
              for (var i = 0; i < _faces.length; i++)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.add, size: 16),
                  label: Text(_faceLabel(i)),
                  onPressed: () => _addCardPage(i),
                ),
            ],
          ),
        ],
      );

  String _faceLabel(int i) {
    final f = _faces[i];
    final schedule = i > 0 && _faces[i - 1].telugu == f.telugu;
    final lang = f.telugu ? 'తెలుగు' : 'English';
    return schedule ? '$lang · ${context.tr('schedule', 'కార్యక్రమాలు')}' : '$lang ${context.tr('card', 'కార్డు')}';
  }

  Widget _nameTray(ReelClip c) {
    final quick = _quickNames();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (quick.isNotEmpty) ...[
          _label(context.tr('Quick names (from your details)', 'త్వరిత పేర్లు (మీ వివరాల నుండి)')),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (label, caption, sub, style) in quick)
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  label: Text(label),
                  onPressed: () {
                    _capCtl.text = caption;
                    _subCtl.text = sub;
                    _edit(() {
                      c.caption = caption;
                      c.sub = sub;
                      c.capStyle = style;
                    });
                    _seek(p.startOf(c) + 0.01);
                  },
                ),
              ActionChip(
                visualDensity: VisualDensity.compact,
                label: Text(context.tr('No name', 'పేరు వద్దు')),
                onPressed: () {
                  _capCtl.clear();
                  _subCtl.clear();
                  _edit(() {
                    c.caption = '';
                    c.sub = '';
                  });
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          inputFormatters: const [TeluguBackspaceFormatter()],
          controller: _capCtl,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            labelText: context.tr('Name / caption', 'పేరు / శీర్షిక'),
          ),
          onChanged: (v) => _edit(() => c.caption = v),
        ),
        const SizedBox(height: 8),
        TextField(
          inputFormatters: const [TeluguBackspaceFormatter()],
          controller: _subCtl,
          decoration: InputDecoration(
            isDense: true,
            border: const OutlineInputBorder(),
            labelText: context.tr('Small line under it (optional)', 'కింద చిన్న వాక్యం (ఐచ్ఛికం)'),
          ),
          onChanged: (v) => _edit(() => c.sub = v),
        ),
        _label(context.tr('Style', 'శైలి')),
        _chips(ReelTextStyle.values, c.capStyle, (s) => s.en, (s) => _edit(() => c.capStyle = s)),
        _label(context.tr('Animation', 'యానిమేషన్')),
        _chips(CaptionAnim.values, c.capAnim, (a) => context.tr(a.en, a.te), (a) {
          _edit(() => c.capAnim = a);
          _seek(p.startOf(c) + 0.01);
          _play();
        }),
      ],
    );
  }

  Widget _pageTray(ReelClip c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context.tr('Which card page this clip shows', 'ఈ క్లిప్‌లో చూపే పేజీ')),
          _chips(List.generate(_faces.length, (i) => i), c.face.clamp(0, _faces.length - 1), _faceLabel,
              (i) => _edit(() {
                    c.face = i;
                    if (c.story) c.dur = _storySeconds(c) / c.speed;
                  })),
        ],
      );

  Widget _speedTray(ReelClip c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context.tr('Speed', 'వేగం')),
          _chips(reelSpeeds, c.speed, _speedLabel, (s) => _edit(() {
                c.speed = s;
                // A story card's length follows its speed.
                if (c.type == ClipType.card && c.story) c.dur = _storySeconds(c) / s;
              })),
          _note(switch (c.type) {
            ClipType.video => context.tr('Slow motion (0.3×, 0.5×) stretches the clip; 2× and 3× shorten it.',
                'స్లో మోషన్ (0.3×, 0.5×) క్లిప్‌ను పొడిగిస్తుంది; 2×, 3× తగ్గిస్తాయి.'),
            ClipType.photo => context.tr('For photos, speed sets how fast the zoom / pan moves — 0.3× is a dreamy slow motion.',
                'ఫోటోలకు జూమ్ / కదలిక వేగం — 0.3× మెల్లని స్లో మోషన్.'),
            ClipType.card => context.tr('For the card, speed sets how fast the lines appear.',
                'కార్డుకు, వాక్యాలు ఎంత వేగంగా కనిపించాలో.'),
          }),
        ],
      );

  Widget _lengthTray(ReelClip c) {
    if (c.type == ClipType.video) {
      final full = c.full > 0 ? c.full : c.trimOut;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('${context.tr('Trim', 'కత్తిరించు')} · ${c.trimIn.toStringAsFixed(1)}s – ${c.trimOut.toStringAsFixed(1)}s'),
          RangeSlider(
            values: RangeValues(c.trimIn.clamp(0.0, full).toDouble(), c.trimOut.clamp(0.0, full).toDouble()),
            max: full <= 0 ? 1.0 : full,
            onChanged: (r) {
              if (r.end - r.start < 0.3) return;
              final startMoved = r.start != c.trimIn;
              _edit(() {
                c.trimIn = r.start;
                c.trimOut = r.end;
              });
              if (_playing) _pause();
              // Show the frame being trimmed.
              _t = p.startOf(c) + (startMoved ? 0.01 : c.length - 0.05);
              _showStill();
            },
            onChangeEnd: (_) {
              _thumbs.remove(c.id)?.dispose();
              unawaited(_thumbFor(c));
            },
          ),
          _note(context.tr('In the reel: ${c.length.toStringAsFixed(1)} s at ${_speedLabel(c.speed)}. The video\'s own sound is muted; your music plays over the whole reel.',
              'రీల్‌లో: ${c.length.toStringAsFixed(1)} సె (${_speedLabel(c.speed)}). వీడియో అసలు శబ్దం ఉండదు; మీ సంగీతం మొత్తం రీల్‌పై వినిపిస్తుంది.')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('${context.tr('Length', 'నిడివి')} · ${c.dur.toStringAsFixed(1)} s'),
        Slider(
          value: c.dur.clamp(1.0, _maxLen(c)).toDouble(),
          min: 1,
          max: _maxLen(c),
          divisions: ((_maxLen(c) - 1) * 2).round(),
          label: '${c.dur.toStringAsFixed(1)} s',
          onChanged: (v) => _edit(() => c.dur = v),
        ),
      ],
    );
  }

  /// Story cards can run longer than photos.
  double _maxLen(ReelClip c) => c.type == ClipType.card && c.story ? 60.0 : 12.0;

  Widget _motionTray(ReelClip c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label(context.tr('Photo movement', 'ఫోటో కదలిక')),
          _chips(PhotoMotion.values, c.motion, (m) => context.tr(m.en, m.te), (m) {
            _edit(() => c.motion = m);
            _seek(p.startOf(c) + 0.01);
            _play();
          }),
        ],
      );

  Widget _transitionTray(ReelClip c) {
    final last = p.clips.isNotEmpty && identical(p.clips.last, c);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(context.tr('Into the next clip', 'తర్వాతి క్లిప్‌లోకి')),
        _chips(ReelTransition.values, c.trans, (t) => context.tr(t.en, t.te), (t) {
          _edit(() => c.trans = t);
          if (!last) {
            _seek((p.startOf(c) + c.length - kTransitionSeconds - 0.6).clamp(0.0, p.total).toDouble());
            _play();
          }
        }),
        Row(
          children: [
            Expanded(
              child: _note(last
                  ? context.tr('This is the last clip — add one after it to see the transition.',
                      'ఇది చివరి క్లిప్ — మార్పు చూడడానికి తర్వాత ఇంకోటి జోడించండి.')
                  : context.tr('Plays over the last half-second of this clip.', 'ఈ క్లిప్ చివరి అర సెకనులో.')),
            ),
            TextButton(
              onPressed: () => _edit(() {
                for (final o in p.clips) {
                  o.trans = c.trans;
                }
              }),
              child: Text(context.tr('Apply to all', 'అన్నింటికీ')),
            ),
          ],
        ),
      ],
    );
  }

  Widget _arrangeTray(ReelClip c) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _move(c, -1),
                icon: const Icon(Icons.chevron_left),
                label: Text(context.tr('Move left', 'ఎడమకు')),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _move(c, 1),
                icon: const Icon(Icons.chevron_right),
                label: Text(context.tr('Move right', 'కుడికి')),
              ),
            ],
          ),
          _note(context.tr('Or long-press a clip on the timeline and drag it.',
              'లేదా టైమ్‌లైన్‌లో క్లిప్‌ను నొక్కి పట్టి లాగండి.')),
        ],
      );

  Widget _musicTray() => ListenableBuilder(
        listenable: _library,
        builder: (context, _) {
          final tracks = _library.all;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text(context.tr('No music', 'సంగీతం వద్దు')),
                    selected: p.music == 'none',
                    onSelected: (_) => _setMusic('none'),
                  ),
                  for (final t in tracks)
                    ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      avatar: _library.downloading.containsKey(t.id)
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, value: _library.downloading[t.id]),
                            )
                          : Icon(t.bundled ? Icons.music_note : Icons.cloud_download_outlined, size: 16),
                      label: Text('${t.titleTe} · ${t.title}'),
                      selected: p.music == t.id,
                      onSelected: (_) => _setMusic(t.id),
                    ),
                  ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.library_music_outlined, size: 16),
                    label: Text(p.ownMusicPath != null && p.ownMusicName.isNotEmpty
                        ? p.ownMusicName
                        : context.tr('+ My song', '+ నా పాట')),
                    selected: p.music == 'own',
                    onSelected: (_) => _pickSong(),
                  ),
                ],
              ),
              if (_library.loading) _note(context.tr('Loading the music library…', 'సంగీత లైబ్రరీ వస్తోంది…')),
              if (_library.error != null) _note(_library.error!),
              Row(
                children: [
                  SizedBox(width: 64, child: Text(context.tr('Start', 'మొదలు'), style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: Slider(
                      value: p.musicStart.clamp(0.0, 60.0).toDouble(),
                      max: 60,
                      divisions: 120,
                      label: '${p.musicStart.toStringAsFixed(1)} s',
                      onChanged: p.music == 'none' ? null : (v) => _edit(() => p.musicStart = v),
                      onChangeEnd: (_) {
                        if (_playing) {
                          _pause();
                          _play();
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 40, child: Text('${p.musicStart.toStringAsFixed(0)}s', style: const TextStyle(fontSize: 12))),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 64, child: Text(context.tr('Volume', 'శబ్దం'), style: const TextStyle(fontSize: 12))),
                  Expanded(
                    child: Slider(
                      value: p.volume.clamp(0.0, 1.0).toDouble(),
                      onChanged: p.music == 'none'
                          ? null
                          : (v) {
                              _edit(() => p.volume = v);
                              unawaited(NativeMedia.setVolume(v).catchError((_) {}));
                            },
                    ),
                  ),
                  SizedBox(width: 40, child: Text('${(p.volume * 100).round()}%', style: const TextStyle(fontSize: 12))),
                ],
              ),
              _note(context.tr('Online tracks download once when you pick them. Tap ▶ to hear the reel with music.',
                  'ఆన్‌లైన్ పాటలు ఎంచుకున్నప్పుడు ఒక్కసారి డౌన్‌లోడ్ అవుతాయి. ▶ నొక్కి వినండి.')),
            ],
          );
        },
      );

  Future<void> _setMusic(String id) async {
    if (_playing) _pause();
    _edit(() => p.music = id);
    if (id == 'none') return;
    try {
      await _songPath(); // download now, so playing and export are instant
      await _play();
    } catch (e) {
      _toastTr('This track needs internet to download.', 'ఈ పాట డౌన్‌లోడ్‌కు ఇంటర్నెట్ కావాలి.');
    }
  }

  Future<void> _pickSong() async {
    if (_playing) _pause();
    try {
      final song = await NativeMedia.pickAudio();
      if (song == null) {
        if (p.ownMusicPath != null) _edit(() => p.music = 'own');
        return;
      }
      _edit(() {
        p.ownMusicPath = song.path;
        p.ownMusicName = song.name;
        p.music = 'own';
        p.musicStart = 0;
      });
      await _play();
    } catch (e) {
      _toastTr('Could not open your songs.', 'పాటలు తెరవలేకపోయాం.');
    }
  }

  static const _textColors = [
    0xFFFFFFFF, 0xFF000000, 0xFFFFD27A, 0xFFFFB300, 0xFFFF6B4A, 0xFFE53935, 0xFFFF8FB1, 0xFFC2185B,
    0xFF8C78FF, 0xFF3F51B5, 0xFF29B6F6, 0xFF7EE8C5, 0xFF43A047,
  ];

  /// (name, Google Fonts family) for text on the video.
  static const _textFonts = [
    ('Bold', 'Plus Jakarta Sans'),
    ('Poster', 'Bebas Neue'),
    ('Modern', 'Montserrat'),
    ('Clean', 'Poppins'),
    ('Script', 'Great Vibes'),
    ('Hand', 'Dancing Script'),
    ('Fun', 'Pacifico'),
    ('Retro', 'Lobster'),
    ('Classic', 'Cinzel'),
    ('Elegant', 'Playfair Display'),
    ('తెలుగు', 'Ramabhadra'),
    ('తెలుగు రౌండ్', 'Baloo Tammudu 2'),
  ];

  int _textSel = 0;

  TextEditingController _ctlFor(ReelText t) => _textCtl.putIfAbsent(t, () => TextEditingController(text: t.text));

  /// Text layer under the play bar: one bar per text, from its first to its
  /// last clip (like the text track in reel editors). Tap to edit it.
  Widget _textTrack() {
    final lay = p.timeline;
    final total = p.total <= 0 ? 1.0 : p.total;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: SizedBox(
        height: 24,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
                ),
              ),
              for (final (i, tx) in p.texts.indexed)
                if (tx.range(lay, total) case (final a, final b))
                  Positioned(
                    left: a / total * w,
                    width: ((b - a) / total * w).clamp(22.0, w).toDouble(),
                    top: 2,
                    bottom: 2,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _sel = null;
                        _tool = _Tool.text;
                        _textSel = i;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: i == _textSel && _tool == _Tool.text ? const Color(0xFFB04BE0) : const Color(0xFF7E3FB0),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'T  ${tx.text}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
              // Playhead.
              Positioned(
                left: (_t / total * w).clamp(0.0, w).toDouble(),
                top: -2,
                bottom: -2,
                child: Container(width: 2, color: Colors.white),
              ),
            ],
          );
        }),
      ),
    );
  }

  void _addText() {
    final c = _clip;
    final t = ReelText(
      text: context.tr('Save the date', 'తేదీ గుర్తుంచుకోండి'),
      font: 'Plus Jakarta Sans',
      bold: true,
      size: 30,
      clipId: c?.id,
      toClipId: c?.id,
    );
    _edit(() => p.texts.add(t));
    setState(() {
      _textSel = p.texts.length - 1;
      _sel = null;
      _tool = _Tool.text;
    });
  }

  Widget _textTray() {
    if (p.texts.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton.tonalIcon(
            onPressed: _addText,
            icon: const Icon(Icons.add),
            label: Text(context.tr('Add text', 'టెక్స్ట్ జోడించు')),
          ),
          _note(context.tr('Choose which clips it shows on, its font, colour, box and animation.',
              'ఏ క్లిప్‌లపై కనిపించాలో, ఫాంట్, రంగు, బాక్స్, యానిమేషన్ ఎంచుకోండి.')),
        ],
      );
    }
    final i = _textSel.clamp(0, p.texts.length - 1);
    final t = p.texts[i];
    final n = p.clips.length;
    final ids = [for (final c in p.clips) c.id];
    var a = t.clipId == null ? 0 : ids.indexOf(t.clipId!);
    var b = t.clipId == null ? n - 1 : ids.indexOf(t.toClipId ?? t.clipId!);
    if (a < 0 || b < 0) {
      a = 0;
      b = n - 1;
    }
    if (a > b) (a, b) = (b, a);
    final whole = t.clipId == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Which text.
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (k, tx) in p.texts.indexed)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('${k + 1} · ${tx.text.length > 14 ? '${tx.text.substring(0, 14)}…' : tx.text}'),
                    selected: k == i,
                    onSelected: (_) => setState(() => _textSel = k),
                  ),
                ),
              ActionChip(
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.add, size: 16),
                label: Text(context.tr('Add', 'జోడించు')),
                onPressed: _addText,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                inputFormatters: const [TeluguBackspaceFormatter()],
                controller: _ctlFor(t),
                decoration: InputDecoration(
                  isDense: true,
                  border: const OutlineInputBorder(),
                  labelText: '${context.tr('Text', 'టెక్స్ట్')} ${i + 1}',
                ),
                onChanged: (v) => _edit(() => t.text = v),
              ),
            ),
            IconButton(
              tooltip: context.tr('Delete', 'తొలగించు'),
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                _textCtl.remove(t)?.dispose();
                _edit(() => p.texts.remove(t));
                setState(() => _textSel = 0);
              },
            ),
          ],
        ),
        // Which clips.
        _label(whole
            ? context.tr('Shows on: the whole video', 'కనిపించేది: మొత్తం వీడియో')
            : (a == b
                ? context.tr('Shows on: clip ${a + 1}', 'కనిపించేది: క్లిప్ ${a + 1}')
                : context.tr('Shows on: clips ${a + 1} – ${b + 1}', 'కనిపించేది: క్లిప్‌లు ${a + 1} – ${b + 1}'))),
        Row(
          children: [
            FilterChip(
              visualDensity: VisualDensity.compact,
              label: Text(context.tr('Whole video', 'మొత్తం')),
              selected: whole,
              onSelected: (on) => _edit(() {
                t.clipId = on || n == 0 ? null : ids[0];
                t.toClipId = on || n == 0 ? null : ids[0];
              }),
            ),
            if (n > 1)
              Expanded(
                child: RangeSlider(
                  values: RangeValues(a.toDouble(), b.toDouble()),
                  max: (n - 1).toDouble(),
                  divisions: n - 1,
                  labels: RangeLabels('${a + 1}', '${b + 1}'),
                  onChanged: (v) {
                    final from = v.start.round(), to = v.end.round();
                    _edit(() {
                      t.clipId = ids[from];
                      t.toClipId = ids[to];
                    });
                    _seek(p.startOf(p.clips[from]) + 0.01);
                  },
                ),
              ),
          ],
        ),
        // Font.
        _label(context.tr('Font', 'ఫాంట్')),
        SizedBox(
          height: 62,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (name, family) in _textFonts)
                GestureDetector(
                  onTap: () => _edit(() => t.font = family),
                  child: Container(
                    width: 74,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: t.family == family ? Colors.white : Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name.startsWith('తె') ? 'అఆ' : 'Aa',
                            style: GoogleFonts.getFont(family, fontSize: 20, color: Colors.white, fontWeight: FontWeight.w700)),
                        Text(name, style: const TextStyle(fontSize: 10, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            FilterChip(
              visualDensity: VisualDensity.compact,
              avatar: const Icon(Icons.format_bold, size: 16),
              label: Text(context.tr('Bold', 'బోల్డ్')),
              selected: t.bold,
              onSelected: (on) => _edit(() => t.bold = on),
            ),
            const SizedBox(width: 8),
            Text(context.tr('Size', 'సైజు'), style: const TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                value: t.size.clamp(16.0, 60.0).toDouble(),
                min: 16,
                max: 60,
                onChanged: (v) => _edit(() => t.size = v),
              ),
            ),
          ],
        ),
        // Colour.
        _label(context.tr('Colour', 'రంగు')),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final col in _textColors)
              GestureDetector(
                onTap: () => _edit(() => t.color = col),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Color(col),
                    shape: BoxShape.circle,
                    border: Border.all(color: t.color == col ? Colors.white : Colors.white24, width: t.color == col ? 3 : 1),
                  ),
                ),
              ),
          ],
        ),
        // Background.
        _label(context.tr('Background', 'నేపథ్యం')),
        _chips(const [0, 1, 2], t.box, (b) => switch (b) {
              1 => context.tr('Colour box', 'రంగు బాక్స్'),
              2 => context.tr('Soft dark box', 'ముదురు బాక్స్'),
              _ => context.tr('None', 'ఏదీ వద్దు'),
            }, (b) => _edit(() => t.box = b)),
        // Animation.
        _label(context.tr('Animation', 'యానిమేషన్')),
        _chips(CaptionAnim.values, t.anim, (an) => context.tr(an.en, an.te), (an) {
          _edit(() => t.anim = an);
          final r = t.range(p.timeline, p.total);
          if (r != null) _seek(r.$1 + 0.01);
          _play();
        }),
        Row(
          children: [
            Text(context.tr('Position', 'స్థానం'), style: const TextStyle(fontSize: 12)),
            Expanded(
              child: Slider(
                  value: t.y.clamp(0.08, 0.92).toDouble(), min: 0.08, max: 0.92, onChanged: (v) => _edit(() => t.y = v)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _effectsTray() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chips(VideoEffect.values, p.effect, (e) => context.tr(e.en, e.te), (e) => _edit(() => p.effect = e),
              icon: (e) => e.icon),
          _note(context.tr('Plays over the whole reel.', 'మొత్తం రీల్‌పై వస్తుంది.')),
        ],
      );

  Widget _filtersTray() {
    ui.Image? sample;
    for (final c in p.clips) {
      if (c.type == ClipType.photo && _images[c.path] != null) {
        sample = _images[c.path];
        break;
      }
    }
    final t = _template;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in VideoFilter.values)
                GestureDetector(
                  onTap: () => _edit(() => p.filter = f),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 54,
                          height: 78,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: f == p.filter ? Colors.white : Colors.transparent, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ColorFiltered(
                              colorFilter: ColorFilter.matrix(f.matrix),
                              child: sample != null
                                  ? RawImage(image: sample, fit: BoxFit.cover)
                                  : DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [t.background.first, t.accent, t.frame],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(context.tr(f.en, f.te),
                            style: TextStyle(fontSize: 10.5, color: f == p.filter ? Colors.white : Colors.white60)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _note(context.tr('Colour for every clip. Names, text and the logo stay clean.',
            'అన్ని క్లిప్‌లకు రంగు. పేర్లు, టెక్స్ట్, లోగో మారవు.')),
      ],
    );
  }

  Widget _cardTray() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: _editDetails,
            icon: const Icon(Icons.edit_note),
            label: Text(context.tr('Edit details (names, date, venue…)', 'వివరాలు మార్చండి (పేర్లు, తేదీ, వేదిక…)')),
          ),
          _label(context.tr('Colours', 'రంగులు')),
          _chips(CardTemplate.forCategory(remembrance: p.ceremony.isRemembrance, tradition: p.tradition), _template,
              (t) => context.tr(t.name, t.nameTe), (t) => _edit(() => p.templateId = t.id)),
          _label(context.tr('Design', 'డిజైన్')),
          _chips(_layouts, _layout, (l) => context.tr(l.en, l.te), (l) => _edit(() => p.layout = l.name)),
        ],
      );
}

/// Outline of a shape (for the Shape strip when there is no photo yet).
class _ShapeIconPainter extends CustomPainter {
  _ShapeIconPainter(this.shape, this.color);
  final PhotoShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * 0.62;
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: h * shape.aspect, height: h);
    canvas.drawPath(shape.path(r), Paint()..color = color.withAlpha(70));
    canvas.drawPath(
        shape.path(r),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color);
  }

  @override
  bool shouldRepaint(covariant _ShapeIconPainter old) => old.shape != shape || old.color != color;
}
