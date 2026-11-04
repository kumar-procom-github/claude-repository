import 'dart:io';

import 'package:flutter/material.dart';

import '../ads/ads.dart';
import '../ads/banner_slot.dart';

import '../models/astro.dart';
import '../models/ceremony.dart';
import '../models/event_item.dart';
import '../models/invitation_draft.dart';
import '../i18n/app_lang.dart';
import '../services/draft_store.dart';
import '../services/rsvp.dart';
import '../wording/dates.dart';
import '../wording/transliterator.dart';
import '../widgets/event_editor.dart';
import '../reel/reel_editor_screen.dart';
import 'preview_screen.dart';
import '../video/native_media.dart';
import '../widgets/telugu_backspace.dart';

/// The form: language, tone, deity, ceremony-specific names, muhurtham,
/// venue, inviters and RSVP number. Telugu name fields auto-fill from the
/// English ones (offline transliteration) and stay editable.
/// Opens the form for [c]: a fresh draft in the app's language, filled
/// with this ceremony's last saved details (if any) and saved as you type.
Future<void> openDetails(BuildContext context, Ceremony c, Tradition t, {bool fresh = false, bool replace = false}) async {
  final te = LangScope.isTe(context);
  final draft = InvitationDraft(c, tradition: t)
    ..language = te ? CardLanguage.telugu : CardLanguage.english
    ..teluguFirst = te;
  final restored = !fresh && await DraftStore.restore(draft);
  DraftStore.watch(draft);
  if (!context.mounted) return;
  final route = MaterialPageRoute<void>(builder: (_) => DetailsScreen(draft: draft, restored: restored));
  if (replace) {
    await Navigator.of(context).pushReplacement(route);
  } else {
    await Navigator.of(context).push(route);
  }
}

class DetailsScreen extends StatefulWidget {
  const DetailsScreen({super.key, required this.draft, this.restored = false, this.editOnly = false});
  final InvitationDraft draft;

  /// Opened from the video editor to change details: one "Done" button.
  final bool editOnly;

  /// The form was filled from this ceremony's saved details.
  final bool restored;

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  InvitationDraft get d => widget.draft;

  final _en = <String, TextEditingController>{};
  final _te = <String, TextEditingController>{};
  late final _venue = TextEditingController(text: d.venue);
  late final _venueTe = TextEditingController(text: d.venueTe);
  late final _mapLink = TextEditingController(text: d.mapLink);
  late final _inviters = TextEditingController(text: d.inviters);
  late final _invitersTe = TextEditingController(text: d.invitersTe);
  late final _rsvp = TextEditingController(text: d.rsvpPhone);
  late final _mealVenue = TextEditingController(text: d.mealVenue);
  late final _mealVenueTe = TextEditingController(text: d.mealVenueTe);

  /// Turned on the first time the user taps "Preview card" with gaps, so
  /// fields don't shout "required" before the user has had a chance to type.
  bool _showErrors = false;
  final _keys = <String, GlobalKey>{};
  GlobalKey _k(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  static const _requiredMsg = 'Required · తప్పనిసరి';

  // Text controllers are made on first use, so fields added later
  // (2nd, 3rd child…) get theirs too.
  TextEditingController _enC(String key) =>
      _en.putIfAbsent(key, () => TextEditingController(text: d.en[key] ?? ''));
  TextEditingController _teC(String key) =>
      _te.putIfAbsent(key, () => TextEditingController(text: d.te[key] ?? ''));

  /// After a child is removed the later children move up: refresh their boxes.
  void _syncChildControllers() {
    for (var i = 1; i <= d.ceremony.maxChildren; i++) {
      final key = InvitationDraft.childKey('child', i);
      if (_en.containsKey(key)) _en[key]!.text = d.en[key] ?? '';
      if (_te.containsKey(key)) _te[key]!.text = d.te[key] ?? '';
    }
  }

  /// Ceremony fields, with a small header per child and "+ Add another child".
  List<Widget> _detailFields() {
    final fields = d.fields;
    final out = <Widget>[];
    for (var n = 0; n < fields.length; n++) {
      final f = fields[n];
      // Lagnam / nakshatram belong to the muhurtham, shown under the date.
      if (_isMuhurthamField(f)) continue;
      final header = _personHeader(f.key);
      if (header != null) out.add(header);
      final first = f.childIndex > 0 && (n == 0 || fields[n - 1].childIndex != f.childIndex);
      if (first && d.childCount > 1) out.add(_childHeader(f.childIndex));
      out.add(_field(f));
      // Photo boxes right under the groom's / bride's name (for the video).
      if (_videoPhotos && _hasCouple && f.key == 'groom') out.addAll(_photoFields(const ['groom']));
      if (_videoPhotos && _hasCouple && f.key == 'bride') out.addAll(_photoFields(const ['bride']));
      final lastOfGroup = f.childIndex > 0 && (n == fields.length - 1 || fields[n + 1].childIndex == 0);
      if (lastOfGroup) out.add(_addChildButton());
    }
    return out;
  }

  /// Optional photos for the video (not printed on cards).
  /// Wedding-type functions: photo boxes sit right under the groom's and
  /// bride's names. Others: one "Photo" box after the details.
  bool get _hasCouple =>
      d.ceremony.fields.any((f) => f.key == 'groom') && d.ceremony.fields.any((f) => f.key == 'bride');

  bool get _videoPhotos => !_greeting && !d.ceremony.isRemembrance;

  List<Widget> _photoFields([List<String>? only]) {
    final keys = only ?? (_hasCouple ? const <String>[] : const ['main']);
    if (keys.isEmpty) return const [];
    final inline = only != null;
    final muslim = d.tradition == Tradition.muslim;
    String label(String k) => switch (k) {
          'groom' => muslim ? 'Dulha photo · దుల్హా ఫోటో' : 'Groom photo · వరుడి ఫోటో',
          'bride' => muslim ? 'Dulhan photo · దుల్హన్ ఫోటో' : 'Bride photo · వధువు ఫోటో',
          'couple' => 'Couple photo (together) · దంపతుల ఫోటో',
          _ => 'Photo · ఫోటో',
        };
    final scheme = Theme.of(context).colorScheme;
    return [
      if (!inline) _subHeader('Photos for the video (optional)', 'వీడియో కోసం ఫోటోలు'),
      for (final k in keys)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: d.photos[k] != null && File(d.photos[k]!).existsSync()
                      ? Image.file(File(d.photos[k]!), fit: BoxFit.cover, cacheWidth: 160)
                      : ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Icon(Icons.person_outline, color: scheme.outline),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label(k))),
              TextButton(
                onPressed: () => _pickPhoto(k),
                child: Text(d.photos[k] == null ? '+ Add · జోడించు' : 'Change · మార్చు'),
              ),
              if (d.photos[k] != null)
                IconButton(
                  tooltip: 'Remove · తీసివేయి',
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => d.setPhoto(k, null),
                ),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
            inline
                ? 'Optional · for the video only (cards stay as they are)'
                : 'Shown in the video, cut in a shape around the face. Cards stay as they are.',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
      ),
    ];
  }

  Future<void> _pickPhoto(String key) async {
    try {
      for (final m in await NativeMedia.pickMedia()) {
        if (!m.isVideo) {
          d.setPhoto(key, m.path);
          return;
        }
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open your photos.')));
    }
  }

  /// Family surname: opens the video ("తుంపాటి వారి వివాహ ఆహ్వానము").
  List<Widget> _familyNameFields() => [
        _text(_enC('familyName'), 'Family surname (optional, opens the video) · ఇంటి పేరు', onChanged: (v) {
          d.setEn('familyName', v);
          if (!d.isTeEdited('familyName')) _teC('familyName').text = d.te['familyName'] ?? '';
        }),
        if (d.needsTelugu)
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: _text(_teC('familyName'), 'ఇంటి పేరు తెలుగులో (auto, edit if needed)',
                onChanged: (v) => d.setTe('familyName', v)),
          ),
      ];

  bool get _ownMuhurtham => d.en['lagnam'] == kOwnMuhurtham;

  /// The user's own muhurtham line, printed on the card as written.
  List<Widget> _ownMuhurthamFields() => [
        _text(_enC('muhurthamOwn'), 'Your muhurtham line (e.g. Rohini Nakshatram, Vrishabha Lagnam)', maxLines: 2,
            onChanged: (v) {
          d.setEn('muhurthamOwn', v);
          if (!d.isTeEdited('muhurthamOwn')) _teC('muhurthamOwn').text = d.te['muhurthamOwn'] ?? '';
        }),
        if (d.needsTelugu)
          _text(_teC('muhurthamOwn'), 'తెలుగులో (ఉదా: రోహిణి నక్షత్రయుక్త వృషభ లగ్నమందు)', maxLines: 2,
              onChanged: (v) => d.setTe('muhurthamOwn', v)),
      ];

  static bool _isMuhurthamField(FieldSpec f) => f.kind == FieldKind.lagnam || f.kind == FieldKind.nakshatram;

  /// A clear heading where each person's block starts (groom, bride, parents).
  Widget? _personHeader(String key) {
    final (en, te) = switch ((key, d.tradition)) {
      ('groom', Tradition.christian) => ('Bridegroom', 'పెండ్లి కుమారుడు'),
      ('groom', Tradition.muslim) => ('Dulha (groom)', 'దుల్హా'),
      ('groom', _) => ('Groom', 'వరుడు'),
      ('bride', Tradition.christian) => ('Bride', 'పెండ్లి కుమార్తె'),
      ('bride', Tradition.muslim) => ('Dulhan (bride)', 'దుల్హన్'),
      ('bride', _) => ('Bride', 'వధువు'),
      ('father', _) => ('Parents', 'తల్లిదండ్రులు'),
      _ => ('', ''),
    };
    if (en.isEmpty) return null;
    return _subHeader(en, te);
  }

  /// Small coloured heading inside a section.
  Widget _subHeader(String en, String te) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Row(
        children: [
          Container(width: 4, height: 18, decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text('$en · $te',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary)),
          const SizedBox(width: 10),
          Expanded(child: Divider(color: scheme.outlineVariant, height: 1)),
        ],
      ),
    );
  }

  Widget _childHeader(int i) => Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Row(
          children: [
            Icon(Icons.child_care, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Child $i · $iవ చిన్నారి',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Remove child $i',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                d.removeChild(i);
                _syncChildControllers();
              },
            ),
          ],
        ),
      );

  Widget _addChildButton() {
    if (d.ceremony.maxChildren <= 1) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: Text(d.canAddChild
              ? 'Add another child · మరో చిన్నారి'
              : 'Up to ${d.ceremony.maxChildren} children'),
          onPressed: d.canAddChild ? d.addChild : null,
        ),
      ),
    );
  }

  /// Set while the "last details are filled in" note is showing.
  ScaffoldMessengerState? _restoredNote;

  @override
  void initState() {
    super.initState();
    if (widget.restored) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        _restoredNote = messenger;
        messenger
            .showSnackBar(SnackBar(
              content: const Text('Your last details are filled in · మీ పాత వివరాలు నింపబడ్డాయి'),
              duration: const Duration(seconds: 3),
              showCloseIcon: true,
              action: SnackBarAction(label: 'Start fresh', onPressed: _startFresh),
            ))
            .closed
            .then((_) => _restoredNote = null);
        // Close it after 3 s even where snackbars with a button stay open.
        Future.delayed(const Duration(seconds: 3), () => _restoredNote?.hideCurrentSnackBar());
      });
    }
  }

  /// Clears this ceremony's saved details and opens an empty form.
  Future<void> _startFresh() async {
    await DraftStore.clear(d);
    if (!mounted) return;
    await openDetails(context, d.ceremony, d.tradition, fresh: true, replace: true);
  }

  Future<void> _confirmStartFresh() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start fresh? · కొత్తగా మొదలుపెట్టాలా?'),
        content: const Text('All details for this ceremony will be cleared.\nఈ వేడుక వివరాలన్నీ తొలగించబడతాయి.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (ok == true) await _startFresh();
  }

  @override
  void dispose() {
    // Don't leave the "details filled in" note on the next screen.
    _restoredNote?.hideCurrentSnackBar();
    _restoredNote = null;
    // Save right away too (the auto-save waits a moment after typing).
    DraftStore.save(d);
    for (final c in [..._en.values, ..._te.values, _venue, _venueTe, _mapLink, _inviters, _invitersTe, _rsvp, _mealVenue, _mealVenueTe]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${d.ceremony.te} · ${d.ceremony.en}'),
        actions: [
          IconButton(
            tooltip: 'Start fresh · కొత్తగా',
            icon: const Icon(Icons.restart_alt),
            onPressed: _confirmStartFresh,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: d,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _section('Card language', 'కార్డు భాష'),
            SegmentedButton<CardLanguage>(
              segments: [
                for (final l in d.teluguFirst
                    ? const [CardLanguage.telugu, CardLanguage.both, CardLanguage.english]
                    : const [CardLanguage.english, CardLanguage.both, CardLanguage.telugu])
                  ButtonSegment(
                    value: l,
                    label: Text(switch (l) {
                      CardLanguage.telugu => 'తెలుగు',
                      CardLanguage.english => 'English',
                      CardLanguage.both => 'Both · రెండూ',
                    }),
                  ),
              ],
              selected: {d.language},
              onSelectionChanged: (s) => d.update(() => d.language = s.first),
            ),
            if (d.needsEnglish) ...[
              const SizedBox(height: 12),
              SegmentedButton<EnglishTone>(
                segments: const [
                  ButtonSegment(value: EnglishTone.traditional, label: Text('Traditional')),
                  ButtonSegment(value: EnglishTone.modern, label: Text('Modern')),
                ],
                selected: {d.tone},
                onSelectionChanged: (s) => d.update(() => d.tone = s.first),
              ),
            ],
            if (!_greeting) _section(d.tradition == Tradition.hindu ? 'Blessing / deity' : 'Header line', 'శీర్షిక'),
            if (!_greeting) _dropdown<Deity>(
              value: d.deity,
              items: [
                for (final x in Deity.forTradition(d.tradition, remembrance: d.ceremony.isRemembrance))
                  (x, '${x.te} · ${x.en}'),
              ],
              onChanged: (x) => d.update(() => d.deity = x ?? Deity.none),
            ),
            _section(_greeting ? 'Your greeting' : 'Details', _greeting ? 'మీ శుభాకాంక్షలు' : 'వివరాలు'),
            if (!_greeting && !d.ceremony.isRemembrance) ..._familyNameFields(),
            ..._detailFields(),
            if (!_greeting && !d.ceremony.isRemembrance) ..._photoFields(),
            // Greeting cards stop here: no date, venue, meal, invitees or RSVP.
            if (!_greeting) ...[
            // The couple's photo together, just before the date (for the video).
            if (_videoPhotos && _hasCouple) ...[
              _subHeader('Couple photo for the video (optional)', 'దంపతుల ఫోటో'),
              ..._photoFields(const ['couple']),
            ],
            _usesMuhurtham ? _section('Date & muhurtham', 'తేదీ & ముహూర్తం') : _section('Date & time', 'తేదీ & సమయం'),
            _dateTile(context),
            _timeTile(context),
            if (d.fields.any(_isMuhurthamField)) ...[
              _subHeader('Lagnam & star (optional)', 'లగ్నం & నక్షత్రం'),
              for (final f in d.fields)
                if (_isMuhurthamField(f) && !(_ownMuhurtham && f.kind == FieldKind.nakshatram)) _field(f),
              if (_ownMuhurtham) ..._ownMuhurthamFields(),
            ],
            ..._mealSection(context),
            if (d.ceremony.supportsEvents) ..._eventsSection(context),
            _atHome ? _section('Address', 'చిరునామా') : _section('Venue', 'వేదిక'),
            _text(_venue, _atHome ? 'House address *' : 'Function hall / venue & address *', maxLines: 3, key: _k('venue'),
                errorText: _showErrors && d.venue.trim().isEmpty ? _requiredMsg : null, onChanged: (v) {
              d.setVenue(v);
              if (!d.venueTeEdited) _venueTe.text = d.venueTe;
            }),
            if (d.needsTelugu) ...[
              _text(_venueTe, _atHome ? 'చిరునామా తెలుగులో (auto-filled, edit if needed)' : 'వేదిక తెలుగులో (auto-filled, edit if needed)',
                  maxLines: 3, onChanged: d.setVenueTe),
              _spellingChips(d.venue, _venueTe.text, (alt) {
                _venueTe.text = alt;
                d.setVenueTe(alt);
              }, place: true),
            ],
            _text(_mapLink, 'Google Maps link (optional)',
                keyboard: TextInputType.url, onChanged: (v) => d.update(() => d.mapLink = v)),
            _section(d.ceremony.isRemembrance ? 'Family (shown at the bottom)' : 'Invited by',
                d.ceremony.isRemembrance ? 'దుఃఖతప్త హృదయాలతో' : 'ఆహ్వానించువారు'),
            _inviterSuggestions(),
            _text(_inviters, 'e.g. Sri Ramesh & Family', onChanged: (v) {
              d.setInviters(v);
              if (!d.invitersTeEdited) _invitersTe.text = d.invitersTe;
            }),
            if (d.needsTelugu) ...[
              _text(_invitersTe, 'తెలుగులో (auto-filled, edit if needed)', onChanged: d.setInvitersTe),
              _spellingChips(d.inviters, _invitersTe.text, (alt) {
                _invitersTe.text = alt;
                d.setInvitersTe(alt);
              }),
            ],
            _section('RSVP on WhatsApp', 'వాట్సాప్ ద్వారా సమాధానం'),
            _text(_rsvp, 'Your WhatsApp number (guests reply here)',
                keyboard: TextInputType.phone,
                key: _k('rsvp'),
                errorText: _rsvpError(),
                onChanged: (v) => d.update(() => d.rsvpPhone = v)),
            ],
            const BannerSlot(padding: EdgeInsets.only(top: 20)),
            // Action buttons at the end of the form (not floating over the fields).
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: widget.editOnly
                  // Opened from the video editor: just go back to it.
                  ? FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.check),
                      label: const Text('Done · పూర్తయింది'),
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                            onPressed: _openPreview,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Card · కార్డు'),
                          ),
                        ),
                        // Video invitations for everything except remembrance.
                        if (!d.ceremony.isRemembrance) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: const Color(0xFFFF6B4A),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _openVideo,
                              icon: const Icon(Icons.movie_creation_outlined),
                              label: const Text('Video · వీడియో'),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _greeting => d.ceremony.isGreeting;

  /// Events held at the host's own home: the venue box asks for the
  /// address, and the meal needs no separate place.
  bool get _atHome => const {CeremonyId.housewarming, CeremonyId.houseBlessing, CeremonyId.iftar}
      .contains(d.ceremony.id);

  /// 'Muhurtham' only fits Hindu celebrations; others just say date & time.
  bool get _usesMuhurtham => d.tradition == Tradition.hindu && !d.ceremony.isRemembrance;

  // ---- validation -----------------------------------------------------------

  String? _fieldError(FieldSpec f) {
    if (!_showErrors) return null;
    final v = d.enValue(f.key);
    if (f.required && v.isEmpty) return _requiredMsg;
    if (f.kind == FieldKind.number && v.isNotEmpty) {
      final n = int.tryParse(v);
      if (n == null || n <= 0 || n > 120) return 'Enter a valid number';
    }
    return null;
  }

  /// Optional, but if typed it must be a real mobile number.
  String? _rsvpError() {
    final v = d.rsvpPhone.trim();
    if (v.isEmpty || Rsvp.waNumber(v) != null) return null;
    return _showErrors ? 'Enter a 10-digit mobile number · సరైన నంబర్ ఇవ్వండి' : null;
  }

  /// Ids of invalid inputs, in screen order, with a readable name for each.
  List<(String, String)> _problems() => [
        for (final f in d.fields)
          if ((f.required && d.enValue(f.key).isEmpty) ||
              (f.kind == FieldKind.number &&
                  d.enValue(f.key).isNotEmpty &&
                  !((int.tryParse(d.enValue(f.key)) ?? 0) > 0 && (int.tryParse(d.enValue(f.key)) ?? 0) <= 120)))
            ('f:${f.key}', f.en),
        if (!_greeting && d.date == null) ('date', 'Date'),
        if (!_greeting && d.venue.trim().isEmpty) ('venue', 'Venue'),
        if (d.rsvpPhone.trim().isNotEmpty && Rsvp.waNumber(d.rsvpPhone) == null) ('rsvp', 'WhatsApp number'),
      ];

  Future<void> _openPreview() async {
    if (!_checkFilled()) return;
    // Every second preview shows a full-screen ad first.
    await Ads.beforePreview();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreviewScreen(draft: d)));
  }

  /// The reel editor, starting from this card's details.
  Future<void> _openVideo() async {
    if (!_checkFilled()) return;
    await Ads.beforePreview();
    if (!mounted) return;
    await openReelEditor(context, d);
  }

  /// True when everything required is filled; otherwise shows what's missing.
  bool _checkFilled() {
    final problems = _problems();
    if (problems.isEmpty) return true;
    setState(() => _showErrors = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Please fill: ${problems.map((p) => p.$2).join(', ')}')));
    // Bring the first problem into view after the error texts are drawn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[problems.first.$1]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), alignment: 0.2);
      }
    });
    return false;
  }

  // ---- building blocks ----------------------------------------------------

  Widget _section(String en, String te) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text('$en · $te', style: Theme.of(context).textTheme.titleSmall),
      );

  Widget _text(
    TextEditingController c,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
    Key? key,
    String? errorText,
    required ValueChanged<String> onChanged,
  }) =>
      Padding(
        key: key,
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          inputFormatters: const [TeluguBackspaceFormatter()],
          controller: c,
          maxLines: maxLines,
          minLines: 1,
          keyboardType: keyboard,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: label, errorText: errorText),
          onChanged: onChanged,
        ),
      );

  /// Haldi / Mehendi / Sangeet / Reception … shown on an extra card page.
  List<Widget> _eventsSection(BuildContext context) {
    return [
      _section('Other functions', 'ఇతర కార్యక్రమాలు'),
      Text(
        'Add the other functions (${presetsFor(d.tradition).take(4).map((p) => p.en).join(', ')} …). They appear on a separate "Schedule" card.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 6),
      for (final e in d.sortedEvents)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(d.needsTelugu ? '${e.nameTe} · ${e.nameEn}' : e.nameEn),
            subtitle: Text([
              if (e.date != null) InviteDates.enDate(e.date!),
              if (e.time != null) InviteDates.enTime(e.time!),
              if (e.venue.trim().isNotEmpty) e.venue.trim(),
            ].join(' · ')),
            onTap: () async {
              final updated = await showEventEditor(context, initial: e, telugu: d.needsTelugu, tradition: d.tradition);
              if (updated != null) d.replaceEvent(e, updated);
            },
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Remove',
              onPressed: () => d.removeEvent(e),
            ),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add function · కార్యక్రమం జోడించండి'),
          onPressed: d.events.length >= 8
              ? null
              : () async {
                  final created = await showEventEditor(context, defaultDate: d.date, telugu: d.needsTelugu, tradition: d.tradition);
                  if (created != null) d.addEvent(created);
                },
        ),
      ),
    ];
  }

  /// Tappable alternative Telugu spellings (d/డ, o/ొ, a/ా …) for a name.
  Widget _spellingChips(String english, String current, ValueChanged<String> onPick, {bool place = false}) {
    if (english.trim().isEmpty) return const SizedBox.shrink();
    final options = [
      if (place) Transliterator.toTeluguPlace(english) else Transliterator.toTelugu(english),
      ...(place ? Transliterator.placeAlternatives(english) : Transliterator.alternatives(english)),
    ].where((s) => s.trim().isNotEmpty && s != current).toList();
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Other spellings:', style: Theme.of(context).textTheme.bodySmall),
          for (final o in options)
            ActionChip(
              label: Text(o),
              visualDensity: VisualDensity.compact,
              onPressed: () => onPick(o),
            ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required List<(T?, String)> items,
    required ValueChanged<T?> onChanged,
    String? label,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              isExpanded: true,
              itemHeight: null, // long items (greeting messages) wrap
              value: value,
              items: [for (final (v, text) in items) DropdownMenuItem<T>(value: v, child: Text(text))],
              onChanged: onChanged,
            ),
          ),
        ),
      );

  Widget _field(FieldSpec f) {
    final label = '${f.en} · ${f.te}${f.required ? ' *' : ''}';
    switch (f.kind) {
      case FieldKind.name:
      case FieldKind.text:
        return Column(
          children: [
            _text(_enC(f.key), label,
                key: _k('f:${f.key}'),
                maxLines: f.key.startsWith('wish') ? 3 : 1,
                errorText: _fieldError(f), onChanged: (v) {
              d.setEn(f.key, v);
              if (f.hasTeluguVariant && !d.isTeEdited(f.key)) _teC(f.key).text = d.te[f.key] ?? '';
            }),
            if (f.hasTeluguVariant && d.needsTelugu)
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _text(_teC(f.key), '${f.te} (తెలుగులో — auto, edit if needed)',
                        onChanged: (v) => d.setTe(f.key, v)),
                    _spellingChips(d.enValue(f.key), _teC(f.key).text, (alt) {
                      _teC(f.key).text = alt;
                      d.setTe(f.key, alt);
                    }),
                  ],
                ),
              ),
          ],
        );
      case FieldKind.number:
        return _text(_enC(f.key), label,
            key: _k('f:${f.key}'),
            errorText: _fieldError(f),
            keyboard: TextInputType.number, onChanged: (v) => d.setEn(f.key, v, autoTelugu: false));
      case FieldKind.choice when f.options.any((o) => o.te.length + o.en.length > 30):
        // Long choices (greeting messages): full text, one tappable box each.
        final selected = d.en[f.key] ?? f.options.first.value;
        final scheme = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(label)),
              for (final o in f.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: o.value == selected ? scheme.primaryContainer : scheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: o.value == selected ? scheme.primary : scheme.outlineVariant),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => d.setEn(f.key, o.value, autoTelugu: false),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(o.value == selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                size: 20, color: o.value == selected ? scheme.primary : scheme.outline),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (o.te.isNotEmpty) Text(o.te),
                                  if (o.en.isNotEmpty)
                                    Text(o.en, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      case FieldKind.choice when f.options.length > 3:
        return _dropdown<String>(
          label: label,
          value: d.en[f.key] ?? f.options.first.value,
          items: [for (final o in f.options) (o.value, '${o.te} · ${o.en}')],
          onChanged: (v) => d.setEn(f.key, v ?? f.options.first.value, autoTelugu: false),
        );
      case FieldKind.choice:
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(child: Text(label)),
              SegmentedButton<String>(
                segments: [
                  for (final o in f.options) ButtonSegment(value: o.value, label: Text('${o.te} · ${o.en}')),
                ],
                selected: {d.en[f.key] ?? f.options.first.value},
                onSelectionChanged: (s) => d.setEn(f.key, s.first, autoTelugu: false),
              ),
            ],
          ),
        );
      case FieldKind.lagnam:
      case FieldKind.nakshatram:
        final list = f.kind == FieldKind.lagnam ? lagnams : nakshatrams;
        final current = d.en[f.key];
        return _dropdown<String>(
          label: label,
          value: (current == null || current.isEmpty) ? null : current,
          items: [
            (null, '— Not needed —'),
            if (f.kind == FieldKind.lagnam) (kOwnMuhurtham, '✏️ Write my own · నేనే రాస్తాను'),
            for (final a in list) (a.en, '${a.te} · ${a.en}'),
          ],
          onChanged: (v) => d.setEn(f.key, v ?? '', autoTelugu: false),
        );
    }
  }

  Widget _dateTile(BuildContext context) {
    final missing = _showErrors && d.date == null;
    final error = Theme.of(context).colorScheme.error;
    return ListTile(
        key: _k('date'),
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.event, color: missing ? error : null),
        title: Text(d.date == null ? 'Pick date *' : InviteDates.enDate(d.date!),
            style: missing ? TextStyle(color: error) : null),
        subtitle: d.date == null
            ? Text(missing ? 'Required · తేదీ ఎంచుకోండి' : 'తేదీ ఎంచుకోండి', style: missing ? TextStyle(color: error) : null)
            : Text(InviteDates.teDate(d.date!)),
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: d.date ?? now.add(const Duration(days: 30)),
            firstDate: DateTime(now.year, now.month, now.day),
            lastDate: now.add(const Duration(days: 365 * 3)),
          );
          if (picked != null) d.update(() => d.date = picked);
        },
      );
  }

  // ---- lunch / dinner ---------------------------------------------------------

  static const _meals = [
    ('', 'None', 'వద్దు'),
    ('breakfast', 'Breakfast / Tiffin', 'టిఫిన్'),
    ('lunch', 'Lunch', 'భోజనం'),
    ('dinner', 'Dinner', 'విందు'),
  ];

  List<Widget> _mealSection(BuildContext context) => [
        _section('Lunch / dinner for guests', 'భోజనం / విందు'),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (value, en, te) in _meals)
              ChoiceChip(
                label: Text('$te · $en'),
                selected: d.meal == value,
                onSelected: (_) => d.update(() {
                  d.meal = value;
                  if (value.isEmpty) d.mealTime = null;
                }),
              ),
          ],
        ),
        if (d.meal.isNotEmpty)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.restaurant_outlined),
            title: Text(d.mealTime == null ? 'From what time? (optional)' : 'From ${InviteDates.enTime(d.mealTime!)}'),
            subtitle: Text(d.mealTime == null
                ? 'ఏ సమయం నుండి (optional)'
                : InviteDates.teTime(d.mealTime!).replaceAll('గం॥లకు', 'గం॥ల నుండి')),
            trailing: d.mealTime == null
                ? null
                : IconButton(icon: const Icon(Icons.clear), onPressed: () => d.update(() => d.mealTime = null)),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: d.mealTime ??
                    (d.meal == 'dinner'
                        ? const TimeOfDay(hour: 19, minute: 30)
                        : d.meal == 'breakfast'
                            ? const TimeOfDay(hour: 8, minute: 0)
                            : const TimeOfDay(hour: 12, minute: 30)),
              );
              if (picked != null) d.update(() => d.mealTime = picked);
            },
          ),
        // At-home events: the meal is at the same house, so no extra place box.
        if (d.meal.isNotEmpty && !_atHome) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16),
                  label: const Text('మా స్వగృహం నందు · At our residence'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    d.setMealVenuePreset('our residence', 'మా స్వగృహం నందు');
                    _mealVenue.text = d.mealVenue;
                    _mealVenueTe.text = d.mealVenueTe;
                  },
                ),
              ],
            ),
          ),
          _text(_mealVenue, 'Place (optional, if different from venue) · స్థలం', maxLines: 2, onChanged: (v) {
            d.setMealVenue(v);
            if (!d.mealVenueTeEdited) _mealVenueTe.text = d.mealVenueTe;
          }),
          if (d.needsTelugu && d.mealVenue.trim().isNotEmpty) ...[
            _text(_mealVenueTe, 'స్థలం తెలుగులో (auto-filled, edit if needed)',
                maxLines: 2, onChanged: d.setMealVenueTe),
            _spellingChips(d.mealVenue, _mealVenueTe.text, (alt) {
              _mealVenueTe.text = alt;
              d.setMealVenueTe(alt);
            }, place: true),
          ],
        ],
      ];

  // ---- "Invited by" suggestions ---------------------------------------------

  /// One tap fills both the English and the Telugu box.
  List<(String, String)> _inviterPresets() {
    // "Sri Ramesh & Family" from a name already typed above.
    String? key;
    for (final k in const ['groomFather', 'father', 'hosts', 'husband']) {
      if (d.enValue(k).isNotEmpty) {
        key = k;
        break;
      }
    }
    final (titleEn, titleTe) = switch (d.tradition) {
      Tradition.muslim => ('Janab', 'జనాబ్'),
      Tradition.christian => ('Mr.', 'శ్రీ'),
      Tradition.hindu => ('Sri', 'శ్రీ'),
    };
    final named = key == null || key == 'hosts'
        ? null
        : ('$titleEn ${d.enValue(key)} & Family', '$titleTe ${d.teOrEn(key)} మరియు కుటుంబ సభ్యులు');
    if (d.ceremony.isRemembrance) {
      return [
        ('Family Members', 'కుటుంబ సభ్యులు'),
        ('Family & Relatives', 'కుటుంబ సభ్యులు మరియు బంధువులు'),
        ('Sons, Daughters & Grandchildren', 'కుమారులు, కుమార్తెలు, మనుమలు మరియు మనుమరాళ్ళు'),
      ];
    }
    return [
      ('Family & Friends', 'కుటుంబ సభ్యులు మరియు బంధుమిత్రులు'),
      if (named != null) named,
      ('Relatives & Friends', 'బంధుమిత్రులు'),
      ('Parents, Grandparents & Family', 'తల్లిదండ్రులు, తాతయ్య నానమ్మలు మరియు కుటుంబ సభ్యులు'),
    ];
  }

  Widget _inviterSuggestions() => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final (en, te) in _inviterPresets())
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(d.needsTelugu ? te : en),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  d.setInvitersPreset(en, te);
                  _inviters.text = en;
                  _invitersTe.text = te;
                },
              ),
          ],
        ),
      );

  Widget _timeTile(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.schedule),
        title: Text(d.time == null ? (_usesMuhurtham ? 'Muhurtham / start time' : 'Start time') : InviteDates.enTime(d.time!)),
        subtitle: d.time == null
            ? Text(_usesMuhurtham ? 'ముహూర్త సమయం (optional)' : 'సమయం (optional)')
            : Text(InviteDates.teTime(d.time!)),
        trailing: d.time == null
            ? null
            : IconButton(icon: const Icon(Icons.clear), onPressed: () => d.update(() => d.time = null)),
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: d.time ?? const TimeOfDay(hour: 10, minute: 30),
          );
          if (picked != null) d.update(() => d.time = picked);
        },
      );
}
