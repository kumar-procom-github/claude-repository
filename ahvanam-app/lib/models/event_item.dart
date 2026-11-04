import 'package:flutter/material.dart';

import 'ceremony.dart';

/// Wedding functions per community. 'custom' lets the user name their own.
class EventPreset {
  final String id;
  final String en;
  final String te;

  /// Empty = shown for every tradition.
  final Set<Tradition> traditions;
  const EventPreset(this.id, this.en, this.te, [this.traditions = const {}]);

  bool fits(Tradition t) => traditions.isEmpty || traditions.contains(t);
}

const _h = {Tradition.hindu};
const _m = {Tradition.muslim};
const _c = {Tradition.christian};

const eventPresets = <EventPreset>[
  // Hindu
  EventPreset('pellikuthuru', 'Pellikuthuru Function', 'పెళ్లికూతురు వేడుక', _h),
  EventPreset('pellikoduku', 'Pellikoduku Function', 'పెళ్లికొడుకు వేడుక', _h),
  EventPreset('haldi', 'Haldi', 'హల్దీ', {Tradition.hindu, Tradition.christian}),
  EventPreset('snathakam', 'Snathakam', 'స్నాతకం', _h),
  EventPreset('muhurtham', 'Wedding Muhurtham', 'వివాహ ముహూర్తం', _h),
  EventPreset('vratham', 'Satyanarayana Vratham', 'సత్యనారాయణ వ్రతం', _h),
  // Muslim
  EventPreset('manjha', 'Manjha', 'మాంఝా', _m),
  EventPreset('sanchaq', 'Sanchaq', 'సాంచక్', _m),
  EventPreset('nikah', 'Nikah', 'నిఖా', _m),
  EventPreset('walima', 'Walima', 'వలీమా', _m),
  EventPreset('jumagi', 'Jumagi', 'జుమాగీ', _m),
  // Christian
  EventPreset('prayer', 'Pre-wedding Prayer', 'వివాహ పూర్వ ప్రార్థన', _c),
  EventPreset('church', 'Church Wedding', 'చర్చిలో వివాహం', _c),
  // Shared
  EventPreset('mehendi', 'Mehendi', 'మెహందీ'),
  EventPreset('sangeet', 'Sangeet', 'సంగీత్', {Tradition.hindu, Tradition.muslim}),
  EventPreset('reception', 'Reception', 'రిసెప్షన్'),
  EventPreset('custom', 'Other (type a name)', 'ఇతర కార్యక్రమం'),
];

List<EventPreset> presetsFor(Tradition t) => [for (final p in eventPresets) if (p.fits(t)) p];

EventPreset presetById(String id) =>
    eventPresets.firstWhere((p) => p.id == id, orElse: () => eventPresets.last);

/// One function in a multi-event invitation (e.g. Haldi on Friday evening).
class EventItem {
  EventItem({
    this.presetId = 'haldi',
    this.customEn = '',
    this.customTe = '',
    this.date,
    this.time,
    this.venue = '',
    this.venueTe = '',
    this.mapLink = '',
  });

  String presetId;
  String customEn;
  String customTe;
  DateTime? date;
  TimeOfDay? time;
  String venue;
  String venueTe;
  String mapLink;

  bool get isCustom => presetId == 'custom';

  String get nameEn => isCustom ? customEn.trim() : presetById(presetId).en;
  String get nameTe {
    if (!isCustom) return presetById(presetId).te;
    return customTe.trim().isNotEmpty ? customTe.trim() : customEn.trim();
  }

  EventItem copy() => EventItem(
        presetId: presetId,
        customEn: customEn,
        customTe: customTe,
        date: date,
        time: time,
        venue: venue,
        venueTe: venueTe,
        mapLink: mapLink,
      );

  Map<String, Object?> toJson() => {
        'p': presetId,
        'ce': customEn,
        'ct': customTe,
        'd': date?.toIso8601String(),
        't': time == null ? null : time!.hour * 60 + time!.minute,
        'v': venue,
        'vt': venueTe,
        'm': mapLink,
      };

  static EventItem fromJson(Map<String, dynamic> j) => EventItem(
        presetId: (j['p'] as String?) ?? 'custom',
        customEn: (j['ce'] as String?) ?? '',
        customTe: (j['ct'] as String?) ?? '',
        date: DateTime.tryParse((j['d'] as String?) ?? ''),
        time: j['t'] is int ? TimeOfDay(hour: (j['t'] as int) ~/ 60, minute: (j['t'] as int) % 60) : null,
        venue: (j['v'] as String?) ?? '',
        venueTe: (j['vt'] as String?) ?? '',
        mapLink: (j['m'] as String?) ?? '',
      );

  /// For sorting the schedule chronologically.
  DateTime get sortKey {
    final d = date ?? DateTime(9999);
    final t = time ?? const TimeOfDay(hour: 0, minute: 0);
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }
}
