import 'package:flutter/material.dart';

import '../wording/transliterator.dart';
import 'ceremony.dart';
import 'event_item.dart';

enum CardLanguage { english, telugu, both }

enum EnglishTone { traditional, modern }

/// Everything the user has entered for one invitation.
/// A ChangeNotifier so the live preview rebuilds as they type.
class InvitationDraft extends ChangeNotifier {
  InvitationDraft(this.ceremony, {Tradition? tradition})
      : tradition = tradition ?? ceremony.mainTradition,
        deity = _defaultDeity(ceremony, tradition ?? ceremony.mainTradition) {
    for (final f in ceremony.fields) {
      if (f.kind == FieldKind.choice && f.options.isNotEmpty) {
        en[f.key] = f.options.first.value;
      }
    }
  }

  // ---- several children (Baptism, Communion, Aqiqah) ----------------------

  static const childKeys = {'child', 'childGender', 'childOrder'};

  /// How many children are on this card (1 … ceremony.maxChildren).
  int childCount = 1;

  bool get canAddChild => childCount < ceremony.maxChildren;

  /// Key of a per-child field for child [i] (1-based): child, child2, child3…
  static String childKey(String base, int i) => i == 1 ? base : '$base$i';

  /// The form's fields, with the child group repeated once per child.
  List<FieldSpec> get fields {
    if (ceremony.maxChildren <= 1) return ceremony.fields;
    final group = [for (final f in ceremony.fields) if (childKeys.contains(f.key)) f];
    final out = <FieldSpec>[];
    var inserted = false;
    for (final f in ceremony.fields) {
      if (!childKeys.contains(f.key)) {
        out.add(f);
        continue;
      }
      if (inserted) continue;
      inserted = true;
      for (var i = 1; i <= childCount; i++) {
        for (final g in group) {
          final isName = g.key == 'child';
          out.add(g.copyWith(
            key: childKey(g.key, i),
            childIndex: i,
            en: childCount == 1
                ? null
                : switch (g.key) {
                    'child' => 'Child $i – name',
                    'childOrder' => 'Child $i – birth order',
                    _ => 'Child $i is a',
                  },
            te: childCount == 1
                ? null
                : switch (g.key) {
                    'child' => '$iవ చిన్నారి పేరు',
                    'childOrder' => '$iవ చిన్నారి – ఎన్నవ సంతానం',
                    _ => '$iవ చిన్నారి',
                  },
            // With two or more children each one needs a name on the card.
            required: isName && childCount > 1 ? true : null,
          ));
        }
      }
    }
    return out;
  }

  void addChild() {
    if (!canAddChild) return;
    childCount++;
    en[childKey('childGender', childCount)] = 'son';
    notifyListeners();
  }

  /// Removes child [i]; the children after it move up one place.
  void removeChild(int i) {
    if (childCount <= 1 || i < 1 || i > childCount) return;
    for (final base in childKeys) {
      for (var j = i; j < childCount; j++) {
        final to = childKey(base, j), from = childKey(base, j + 1);
        _move(en, from, to);
        _move(te, from, to);
        _teEdited.remove(to);
        if (_teEdited.remove(from)) _teEdited.add(to);
      }
      final last = childKey(base, childCount);
      en.remove(last);
      te.remove(last);
      _teEdited.remove(last);
    }
    childCount--;
    notifyListeners();
  }

  static void _move(Map<String, String> m, String from, String to) {
    final v = m[from];
    if (v == null) {
      m.remove(to);
    } else {
      m[to] = v;
    }
  }

  /// The children on the card, in order.
  List<({String en, String te, bool son, String order})> get children => [
        for (var i = 1; i <= childCount; i++)
          (
            en: enValue(childKey('child', i)),
            te: teOrEn(childKey('child', i)),
            son: en[childKey('childGender', i)] != 'daughter',
            order: en[childKey('childOrder', i)] ?? '',
          ),
      ];

  final Ceremony ceremony;

  /// Community chosen on the first screen (matters for shared ceremonies
  /// like Birthday: header lines, functions and designs follow it).
  final Tradition tradition;

  static Deity _defaultDeity(Ceremony c, Tradition t) {
    final d = c.defaultDeity;
    return (d.tradition == null || d.tradition == t) ? d : Deity.none;
  }

  CardLanguage language = CardLanguage.both;

  /// With "Both", which language's card comes first (follows the app language).
  bool teluguFirst = true;
  EnglishTone tone = EnglishTone.traditional;
  Deity deity;

  DateTime? date;
  TimeOfDay? time;

  /// English / Latin-script values, keyed by FieldSpec.key.
  final Map<String, String> en = {};

  /// Telugu values for name fields. Auto-filled from [en] by transliteration
  /// until the user edits them by hand (tracked in [_teEdited]).
  final Map<String, String> te = {};
  final Set<String> _teEdited = {};

  String venue = '';
  String venueTe = '';
  String mapLink = '';
  String inviters = '';
  String invitersTe = '';
  bool _invitersTeEdited = false;

  /// Meal for guests: '' (none), 'breakfast', 'lunch' or 'dinner', with an
  /// optional start time. Printed above the venue on the card.
  String meal = '';
  TimeOfDay? mealTime;

  /// Where the meal is served, if not at the main venue (optional).
  /// Telugu auto-fills from the English until edited by hand.
  String mealVenue = '';
  String mealVenueTe = '';
  bool _mealVenueTeEdited = false;
  bool get mealVenueTeEdited => _mealVenueTeEdited;

  void setMealVenue(String value) {
    mealVenue = value;
    if (!_mealVenueTeEdited) mealVenueTe = Transliterator.toTeluguPlace(value);
    notifyListeners();
  }

  /// A tapped suggestion such as "మా స్వగృహం నందు · our residence".
  void setMealVenuePreset(String en, String te) {
    mealVenue = en;
    mealVenueTe = te;
    _mealVenueTeEdited = false;
    notifyListeners();
  }

  void setMealVenueTe(String value) {
    mealVenueTe = value;
    _mealVenueTeEdited = true;
    notifyListeners();
  }

  /// WhatsApp number guests reply to (10-digit Indian mobile, or with country code).
  String rsvpPhone = '';

  /// Extra functions for multi-event invitations (wedding).
  final List<EventItem> events = [];

  List<EventItem> get sortedEvents => [...events]..sort((a, b) => a.sortKey.compareTo(b.sortKey));

  bool get hasSchedule => ceremony.supportsEvents && events.isNotEmpty;

  void addEvent(EventItem e) {
    events.add(e);
    notifyListeners();
  }

  void replaceEvent(EventItem old, EventItem updated) {
    final i = events.indexOf(old);
    if (i >= 0) events[i] = updated;
    notifyListeners();
  }

  void removeEvent(EventItem e) {
    events.remove(e);
    notifyListeners();
  }

  bool get needsTelugu => language != CardLanguage.english;
  bool get needsEnglish => language != CardLanguage.telugu;

  void setEn(String key, String value, {bool autoTelugu = true}) {
    en[key] = value;
    if (autoTelugu && !_teEdited.contains(key)) {
      te[key] = Transliterator.toTelugu(value);
    }
    notifyListeners();
  }

  bool _venueTeEdited = false;
  bool get venueTeEdited => _venueTeEdited;

  /// Venue / hall name, with Telugu auto-filled until edited by hand.
  void setVenue(String value) {
    venue = value;
    if (!_venueTeEdited) venueTe = Transliterator.toTeluguPlace(value);
    notifyListeners();
  }

  void setVenueTe(String value) {
    venueTe = value;
    _venueTeEdited = true;
    notifyListeners();
  }

  bool isTeEdited(String key) => _teEdited.contains(key);
  bool get invitersTeEdited => _invitersTeEdited;

  void setTe(String key, String value) {
    te[key] = value;
    _teEdited.add(key);
    notifyListeners();
  }

  void setInviters(String value) {
    inviters = value;
    if (!_invitersTeEdited) invitersTe = Transliterator.toTelugu(value);
    notifyListeners();
  }

  /// A tapped suggestion: fills both languages; the Telugu keeps following
  /// the English if the user edits it afterwards.
  void setInvitersPreset(String en, String te) {
    inviters = en;
    invitersTe = te;
    _invitersTeEdited = false;
    notifyListeners();
  }

  void setInvitersTe(String value) {
    invitersTe = value;
    _invitersTeEdited = true;
    notifyListeners();
  }

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Telugu value with English fallback, so a card never shows an empty slot.
  // ---- saving / restoring (see DraftStore) -----------------------------------

  static int? _mins(TimeOfDay? t) => t == null ? null : t.hour * 60 + t.minute;
  static TimeOfDay? _time(Object? v) => v is int ? TimeOfDay(hour: v ~/ 60, minute: v % 60) : null;

  Map<String, Object?> toJson() => {
        'v': 1,
        'language': language.name,
        'teluguFirst': teluguFirst,
        'tone': tone.name,
        'deity': deity.name,
        'date': date?.toIso8601String(),
        'time': _mins(time),
        'en': en,
        'te': te,
        'teEdited': _teEdited.toList(),
        'venue': venue,
        'venueTe': venueTe,
        'venueTeEdited': _venueTeEdited,
        'mapLink': mapLink,
        'inviters': inviters,
        'invitersTe': invitersTe,
        'invitersTeEdited': _invitersTeEdited,
        'rsvpPhone': rsvpPhone,
        'events': [for (final e in events) e.toJson()],
        'childCount': childCount,
        'meal': meal,
        'mealTime': _mins(mealTime),
        'mealVenue': mealVenue,
        'mealVenueTe': mealVenueTe,
        'mealVenueTeEdited': _mealVenueTeEdited,
        'photos': photos,
      };

  /// Optional photos for the video: 'groom', 'bride', 'couple' or 'main'
  /// (files in the app's folder). Cards don't use them.
  final Map<String, String> photos = {};

  void setPhoto(String key, String? path) {
    if (path == null) {
      photos.remove(key);
    } else {
      photos[key] = path;
    }
    notifyListeners();
  }

  /// Puts back what the user last typed for this ceremony. Unknown or
  /// broken values are skipped, never fatal.
  void loadJson(Map<String, dynamic> j) {
    T? pick<T extends Enum>(List<T> values, Object? name) {
      for (final v in values) {
        if (v.name == name) return v;
      }
      return null;
    }

    language = pick(CardLanguage.values, j['language']) ?? language;
    photos
      ..clear()
      ..addAll({
        for (final e in ((j['photos'] as Map?) ?? const {}).entries)
          if (e.key is String && e.value is String) e.key as String: e.value as String,
      });
    teluguFirst = j['teluguFirst'] is bool ? j['teluguFirst'] as bool : teluguFirst;
    tone = pick(EnglishTone.values, j['tone']) ?? tone;
    deity = pick(Deity.values, j['deity']) ?? deity;
    date = DateTime.tryParse((j['date'] as String?) ?? '');
    time = _time(j['time']);
    en
      ..clear()
      ..addAll({...((j['en'] as Map?) ?? const {}).cast<String, String>()});
    te
      ..clear()
      ..addAll({...((j['te'] as Map?) ?? const {}).cast<String, String>()});
    _teEdited
      ..clear()
      ..addAll(((j['teEdited'] as List?) ?? const []).cast<String>());
    venue = (j['venue'] as String?) ?? '';
    venueTe = (j['venueTe'] as String?) ?? '';
    _venueTeEdited = j['venueTeEdited'] == true;
    mapLink = (j['mapLink'] as String?) ?? '';
    inviters = (j['inviters'] as String?) ?? '';
    invitersTe = (j['invitersTe'] as String?) ?? '';
    _invitersTeEdited = j['invitersTeEdited'] == true;
    rsvpPhone = (j['rsvpPhone'] as String?) ?? '';
    events
      ..clear()
      ..addAll([
        for (final e in (j['events'] as List?) ?? const [])
          if (e is Map) EventItem.fromJson(e.cast<String, dynamic>()),
      ]);
    childCount = ((j['childCount'] as int?) ?? 1).clamp(1, ceremony.maxChildren < 1 ? 1 : ceremony.maxChildren);
    meal = (j['meal'] as String?) ?? '';
    mealTime = _time(j['mealTime']);
    mealVenue = (j['mealVenue'] as String?) ?? '';
    mealVenueTe = (j['mealVenueTe'] as String?) ?? '';
    _mealVenueTeEdited = j['mealVenueTeEdited'] == true;
    // Choice fields must still have a value.
    for (final f in fields) {
      if (f.kind == FieldKind.choice && f.options.isNotEmpty && !f.options.any((o) => o.value == en[f.key])) {
        en[f.key] = f.options.first.value;
      }
    }
  }

  /// Anything typed at all? (Empty forms aren't worth saving.)
  bool get hasContent =>
      en.entries.any((e) => e.value.trim().isNotEmpty && !_isDefaultChoice(e.key, e.value)) ||
      venue.trim().isNotEmpty ||
      date != null ||
      inviters.trim().isNotEmpty ||
      events.isNotEmpty;

  bool _isDefaultChoice(String key, String value) {
    for (final f in fields) {
      if (f.key == key && f.kind == FieldKind.choice) return f.options.isNotEmpty && f.options.first.value == value;
    }
    return false;
  }

  String teOrEn(String key) {
    final t = te[key]?.trim() ?? '';
    return t.isNotEmpty ? t : (en[key]?.trim() ?? '');
  }

  String enValue(String key) => en[key]?.trim() ?? '';

  /// Required fields that are still empty (used to block sharing).
  List<FieldSpec> get missingRequired => [
        for (final f in fields)
          if (f.required && enValue(f.key).isEmpty) f,
      ];

  /// Greetings need no date or venue.
  bool get isReady =>
      missingRequired.isEmpty && (ceremony.isGreeting || (date != null && venue.trim().isNotEmpty));
}
