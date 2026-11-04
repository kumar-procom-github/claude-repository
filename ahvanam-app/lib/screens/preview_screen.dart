import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../ads/ads.dart';
import '../ads/banner_slot.dart';
import '../models/invitation_draft.dart';
import '../services/export_service.dart';
import '../services/rsvp.dart';
import '../services/template_catalog.dart';
import '../templates/card_fonts.dart';
import '../templates/card_template.dart';
import '../templates/remote_template.dart';
import '../widgets/invitation_card.dart';
import '../wording/card_text.dart';
import '../wording/wording_engine.dart';

enum _Action { share, gallery, pdf }

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.draft});
  final InvitationDraft draft;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  InvitationDraft get d => widget.draft;
  late CardTemplate _template = CardTemplate.defaultFor(
    tradition: widget.draft.tradition,
    remembrance: widget.draft.ceremony.isRemembrance,
    ceremony: widget.draft.ceremony.id,
    childGender: widget.draft.en['childGender'],
  );
  late CardLayout _layout = _firstLayout();

  /// The occasion's own design first (kites for Sankranti, diyas for Deepavali…).
  CardLayout _firstLayout() {
    final list = _layouts;
    final preferred = widget.draft.ceremony.design;
    return list.firstWhere((l) => l.name == preferred, orElse: () => list.first);
  }

  List<CardLayout> get _layouts => CardLayout.forTradition(widget.draft.tradition,
      remembrance: widget.draft.ceremony.isRemembrance, greeting: widget.draft.ceremony.isGreeting);
  TeluguFont? _teFont; // null = the design's own font
  EnglishFont? _enFont;
  final _keys = <GlobalKey>[];
  _Action? _busy;

  // Illustrated designs from the online catalog.
  final _catalog = TemplateCatalog.instance;
  bool _illustrated = true;
  RemoteTemplate? _remote;
  File? _remoteArt;
  String? _loadingId;
  bool _autoPicked = false;
  final _thumbs = <String, Future<File>>{};

  List<RemoteTemplate> get _remoteList => _catalog.forCeremony(d.ceremony.id.name);

  @override
  void initState() {
    super.initState();
    _catalog.addListener(_onCatalog);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onCatalog());
  }

  @override
  void dispose() {
    _catalog.removeListener(_onCatalog);
    _catalog.markSeen(_remoteList);
    super.dispose();
  }

  void _onCatalog() {
    if (!mounted) return;
    final list = _remoteList;
    setState(() {
      if (list.isEmpty && _remote == null && !_catalog.refreshing) _illustrated = false;
    });
    // Open on the newest illustrated design the first time one is available.
    if (!_autoPicked && _remote == null && list.isNotEmpty) {
      _autoPicked = true;
      _pickRemote(list.first);
    }
  }

  Future<void> _pickRemote(RemoteTemplate t) async {
    setState(() => _loadingId = t.id);
    try {
      final file = await _catalog.art(t);
      if (!mounted) return;
      await precacheImage(FileImage(file), context); // ready before export
      setState(() {
        _remote = t;
        _remoteArt = file;
        _illustrated = true;
      });
    } catch (_) {
      _toast('Could not download this design. Check internet.');
    } finally {
      if (mounted) setState(() => _loadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final faces = WordingEngine.faces(d);
    while (_keys.length < faces.length) {
      _keys.add(GlobalKey());
    }
    final rsvp = Rsvp.rsvpLink(d);

    return Scaffold(
      appBar: AppBar(title: const Text('Preview · ముందుచూపు')),
      // SingleChildScrollView (not a lazy list) so every face is painted
      // and can be captured for export.
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _designHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: true,
                    icon: const Icon(Icons.auto_awesome_outlined),
                    label: Text('Illustrated (${_remoteList.length})'),
                  ),
                  const ButtonSegment(value: false, icon: Icon(Icons.offline_bolt_outlined), label: Text('Classic')),
                ],
                selected: {_illustrated},
                onSelectionChanged: (v) => setState(() => _illustrated = v.first),
              ),
            ),
            const SizedBox(height: 10),
            if (_illustrated) _remoteGrid(faces.first) else ...[
              _designGrid(faces.first),
              _heading('Colour · రంగు'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final t in CardTemplate.forCategory(remembrance: d.ceremony.isRemembrance, tradition: d.tradition))
                      ChoiceChip(
                        avatar: CircleAvatar(backgroundColor: t.background.first),
                        label: Text('${t.nameTe} · ${t.name}'),
                        selected: t == _template,
                        onSelected: (_) => setState(() => _template = t),
                      ),
                  ],
                ),
              ),
            ],
            if (faces.any((f) => f.telugu)) ...[
              _heading('Telugu font · తెలుగు అక్షరాలు'),
              _fontChips<TeluguFont?>(
                fonts: [null, ...teluguFonts],
                selected: _teFont,
                label: (f) => f == null
                    ? const Text('Design default')
                    : Text(f.name, style: GoogleFonts.getFont(f.title, fontSize: 18)),
                onSelect: (f) => setState(() => _teFont = f),
              ),
            ],
            if (faces.any((f) => !f.telugu)) ...[
              _heading('English font'),
              _fontChips<EnglishFont?>(
                fonts: [null, ...englishFonts],
                selected: _enFont,
                label: (f) => f == null
                    ? const Text('Design default')
                    : Text(f.name,
                        style: GoogleFonts.getFont(f.names, fontSize: InvitationCard.isScriptFont(f.names) ? 22 : 17)),
                onSelect: (f) => setState(() => _enFont = f),
              ),
            ],
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                children: [
                  for (var i = 0; i < faces.length; i++) ...[
                    if (faces.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('${i + 1}/${faces.length} · ${_faceLabel(faces[i], i, faces)}',
                            style: Theme.of(context).textTheme.labelLarge),
                      ),
                    AspectRatio(
                      aspectRatio: 9 / 16,
                      child: FittedBox(
                        child: RepaintBoundary(
                          key: _keys[i],
                          child: _mainCard(faces[i]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: BannerSlot(padding: EdgeInsets.only(top: 20)),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              if (rsvp != null)
                IconButton(
                  tooltip: 'Test RSVP link',
                  icon: const Icon(Icons.how_to_reg_outlined),
                  onPressed: () => launchUrl(Uri.parse(rsvp), mode: LaunchMode.externalApplication),
                ),
              _iconAction(_Action.gallery, Icons.download_outlined, 'Save to gallery', faces.length),
              _iconAction(_Action.pdf, Icons.picture_as_pdf_outlined, 'PDF for printing', faces.length),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: _busy != null ? null : () => _run(_Action.share, faces.length),
                  icon: _busy == _Action.share ? _spinner() : const Icon(Icons.share),
                  label: const Text('Share · పంపండి'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );

  bool get _usingRemote => _illustrated && _remote != null && _remoteArt != null;

  /// The full-size card that gets exported.
  /// The full-size card (preview, save, share, PDF) carries the small Ahvanam logo.
  Widget _mainCard(CardText face) => _usingRemote
      ? _remoteCard(face, _remote!, _remoteArt!, watermark: true)
      : _card(face, _layout, watermark: true);

  InvitationCard _remoteCard(CardText face, RemoteTemplate t, File art, {bool watermark = false}) => InvitationCard(
        watermark: watermark,
        text: face,
        template: t.style,
        art: art,
        artPadding: t.padding,
        scrim: t.scrim,
        teluguFont: _teFont,
        englishFont: _enFont,
      );

  Widget _designHeader() {
    final updated = _catalog.lastUpdated;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Choose a design · డిజైన్ ఎంచుకోండి', style: Theme.of(context).textTheme.titleSmall),
                if (updated != null)
                  Text('New designs added ${updated.day}-${updated.month}-${updated.year}',
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          _catalog.refreshing
              ? const Padding(padding: EdgeInsets.all(14), child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  tooltip: 'Check for new designs',
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    final before = _catalog.templates.length;
                    _thumbs.clear(); // retry thumbnails that failed offline
                    await _catalog.refresh();
                    final added = _catalog.templates.length - before;
                    final err = _catalog.error;
                    _toast(err ?? (added > 0 ? '$added new designs added!' : 'You have the latest designs'));
                  },
                ),
        ],
      ),
    );
  }

  /// Illustrated designs with the user's own text on each, NEW badges.
  Widget _remoteGrid(CardText face) {
    final list = _remoteList;
    final scheme = Theme.of(context).colorScheme;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          _catalog.refreshing
              ? 'Loading designs…'
              : (_catalog.error ?? 'No illustrated designs for this ceremony yet — tap refresh, or use Classic.'),
        ),
      );
    }
    return LayoutBuilder(builder: (context, c) {
      const perRow = 3, gap = 8.0, side = 12.0;
      final w = (c.maxWidth - side * 2 - gap * (perRow - 1)) / perRow;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: side),
        child: Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (final t in list)
              GestureDetector(
                onTap: _loadingId != null ? null : () => _pickRemote(t),
                child: SizedBox(
                  width: w,
                  child: Column(
                    children: [
                      Container(
                        width: w,
                        height: w * 16 / 9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: t.id == _remote?.id ? scheme.primary : scheme.outlineVariant,
                            width: t.id == _remote?.id ? 3 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            FutureBuilder<File>(
                              future: _thumbs[t.id] ??= _catalog.thumb(t),
                              builder: (context, snap) => snap.hasData
                                  ? IgnorePointer(child: FittedBox(child: _remoteCard(face, t, snap.data!)))
                                  : ColoredBox(
                                      color: scheme.surfaceContainerHighest,
                                      child: Center(
                                        child: snap.hasError ? const Icon(Icons.cloud_off) : _spinner(),
                                      ),
                                    ),
                            ),
                            if (_catalog.isNew(t))
                              Positioned(
                                top: 4,
                                left: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            if (_loadingId == t.id) ColoredBox(color: Colors.black26, child: Center(child: _spinner())),
                          ],
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(t.nameTe.isNotEmpty ? t.nameTe : t.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  InvitationCard _card(CardText face, CardLayout layout, {bool watermark = false}) => InvitationCard(
        watermark: watermark,
        text: face,
        template: _template,
        layout: layout,
        teluguFont: _teFont,
        englishFont: _enFont,
      );

  Widget _fontChips<F>({
    required List<F> fonts,
    required F selected,
    required Widget Function(F) label,
    required ValueChanged<F> onSelect,
  }) =>
      // A dropdown: each font shown in its own letters.
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: InputDecorator(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: fonts.indexOf(selected).clamp(0, fonts.length - 1),
              isExpanded: true,
              itemHeight: null,
              menuMaxHeight: 420,
              items: [
                for (var i = 0; i < fonts.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: label(fonts[i])),
                  ),
              ],
              onChanged: (i) {
                if (i != null) onSelect(fonts[i]);
              },
            ),
          ),
        ),
      );

  /// All 8 designs (4 families × 2 variations) as live mini-renders of the
  /// user's own card, 4 per row so every option is visible without scrolling.
  Widget _designGrid(CardText face) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, c) {
      const perRow = 4, gap = 8.0, side = 12.0;
      final w = (c.maxWidth - side * 2 - gap * (perRow - 1)) / perRow;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: side),
        child: Wrap(
          spacing: gap,
          runSpacing: 10,
          children: [
            for (final l in _layouts)
              GestureDetector(
                onTap: () => setState(() => _layout = l),
                child: SizedBox(
                  width: w,
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: w,
                        height: w * 16 / 9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: l == _layout ? scheme.primary : scheme.outlineVariant,
                            width: l == _layout ? 3 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: IgnorePointer(child: FittedBox(child: _card(face, l))),
                      ),
                      const SizedBox(height: 3),
                      Text(l.te, style: TextStyle(fontSize: 11, fontWeight: l == _layout ? FontWeight.w700 : FontWeight.w400)),
                      Text(l.en, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  String _faceLabel(CardText face, int index, List<CardText> faces) {
    final lang = face.telugu ? 'తెలుగు' : 'English';
    final isSchedule = index > 0 && faces[index - 1].telugu == face.telugu;
    return isSchedule ? '$lang · Schedule' : lang;
  }

  Widget _spinner() =>
      const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2));

  Widget _iconAction(_Action action, IconData icon, String tooltip, int faceCount) => IconButton.outlined(
        tooltip: tooltip,
        icon: _busy == action ? _spinner() : Icon(icon),
        onPressed: _busy != null ? null : () => _run(action, faceCount),
      );

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _run(_Action action, int faceCount) async {
    if (!d.isReady) {
      final missing = [
        ...d.missingRequired.map((f) => f.en),
        if (!d.ceremony.isGreeting && d.date == null) 'Date',
        if (!d.ceremony.isGreeting && d.venue.trim().isEmpty) 'Venue',
      ];
      _toast('Please fill: ${missing.join(', ')}');
      return;
    }
    setState(() => _busy = action);
    try {
      // Make sure Google Fonts have finished downloading before capturing,
      // otherwise the image could use a fallback font.
      // A font download that fails (weak or blocked network) must not stop
      // the save — the card is captured with whatever font is already loaded.
      try {
        await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Font download failed, saving with fallback font: $e');
      }
      await WidgetsBinding.instance.endOfFrame;

      final keys = _keys.take(faceCount).toList();
      final baseName = 'ahvanam_${d.ceremony.id.name}_${DateTime.now().millisecondsSinceEpoch}';
      final caption = Rsvp.shareCaption(d);

      switch (action) {
        case _Action.share:
          await ExportService.sharePngs(await ExportService.capturePngs(keys, baseName), caption);
        case _Action.gallery:
          // Every second save shows a full-screen ad first.
          await Ads.beforeSave();
          final ok = await ExportService.saveToGallery(await ExportService.capturePngs(keys, baseName));
          _toast(ok ? 'Saved to gallery (album "Ahvanam")' : 'Photo access was denied');
        case _Action.pdf:
          await ExportService.sharePdf(await ExportService.buildPdf(keys, baseName), caption);
      }
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }
}
