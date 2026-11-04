import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/invitation_draft.dart';

/// Remembers what the user typed, separately for every ceremony of every
/// tradition (Birthday keeps Birthday's details, Wedding keeps Wedding's…).
/// Saved automatically a moment after each change, so going back by mistake
/// or closing the app loses nothing.
class DraftStore {
  DraftStore._();

  static String _key(InvitationDraft d) => 'draft_${d.tradition.name}_${d.ceremony.id.name}';

  /// Fills [d] with the last saved details, if any. Returns true if restored.
  static Future<bool> restore(InvitationDraft d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(d));
      if (raw == null) return false;
      d.loadJson(jsonDecode(raw) as Map<String, dynamic>);
      return true;
    } catch (e) {
      debugPrint('DraftStore.restore: $e');
      return false;
    }
  }

  static final _timers = Expando<Timer>();
  static final _stopped = Expando<bool>();

  /// Saves [d] (debounced) every time it changes.
  static void watch(InvitationDraft d) {
    d.addListener(() {
      if (_stopped[d] == true) return;
      _timers[d]?.cancel();
      _timers[d] = Timer(const Duration(milliseconds: 600), () => save(d));
    });
  }

  /// Stops saving [d] (used when the user starts fresh).
  static void stop(InvitationDraft d) {
    _stopped[d] = true;
    _timers[d]?.cancel();
  }

  static Future<void> save(InvitationDraft d) async {
    if (_stopped[d] == true) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!d.hasContent) {
        await prefs.remove(_key(d));
        return;
      }
      await prefs.setString(_key(d), jsonEncode(d.toJson()));
    } catch (e) {
      debugPrint('DraftStore.save: $e');
    }
  }

  static Future<void> clear(InvitationDraft d) async {
    stop(d);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(d));
    } catch (_) {}
  }
}
