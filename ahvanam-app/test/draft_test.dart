import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahvanam/models/ceremony.dart';
import 'package:ahvanam/models/event_item.dart';
import 'package:ahvanam/models/invitation_draft.dart';

void main() {
  test('saved details come back exactly (per ceremony draft)', () {
    final a = InvitationDraft(ceremonyById(CeremonyId.wedding))
      ..setEn('groom', 'Arjun')
      ..setTe('groom', 'అర్జున్')
      ..setEn('groomOrder', 'first', autoTelugu: false)
      ..setVenue('Sri Lakshmi Function Hall')
      ..setInviters('Ramesh & Family')
      ..language = CardLanguage.telugu
      ..date = DateTime(2026, 12, 12)
      ..time = const TimeOfDay(hour: 10, minute: 30)
      ..meal = 'dinner'
      ..mealTime = const TimeOfDay(hour: 19, minute: 30)
      ..events.add(EventItem(presetId: 'haldi', date: DateTime(2026, 12, 11)));
    final json = jsonDecode(jsonEncode(a.toJson())) as Map<String, dynamic>;
    final b = InvitationDraft(ceremonyById(CeremonyId.wedding))..loadJson(json);
    expect(b.enValue('groom'), 'Arjun');
    expect(b.te['groom'], 'అర్జున్');
    expect(b.isTeEdited('groom'), isTrue);
    expect(b.en['groomOrder'], 'first');
    expect(b.venue, 'Sri Lakshmi Function Hall');
    expect(b.venueTe, a.venueTe);
    expect(b.inviters, 'Ramesh & Family');
    expect(b.language, CardLanguage.telugu);
    expect(b.date, DateTime(2026, 12, 12));
    expect(b.time, const TimeOfDay(hour: 10, minute: 30));
    expect(b.meal, 'dinner');
    expect(b.mealTime, const TimeOfDay(hour: 19, minute: 30));
    expect(b.events.single.presetId, 'haldi');
    expect(b.hasContent, isTrue);
    expect(InvitationDraft(ceremonyById(CeremonyId.wedding)).hasContent, isFalse);
  });
}
