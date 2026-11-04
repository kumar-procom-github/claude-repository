import '../models/greetings.dart';
import '../models/invitation_draft.dart';
import '../wording/dates.dart';

/// WhatsApp-based RSVP with zero backend: the share caption carries a
/// wa.me link that opens a pre-filled reply to the host's number.
class Rsvp {
  Rsvp._();

  /// Normalises an Indian mobile number to wa.me format (country code, digits only).
  static String? waNumber(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length == 10) digits = '91$digits';
    return digits.length >= 11 && digits.length <= 15 ? digits : null;
  }

  static String mapLink(InvitationDraft d) {
    final custom = d.mapLink.trim();
    if (custom.isNotEmpty) return custom;
    // Free, keyless Google Maps search link.
    return 'https://maps.google.com/?q=${Uri.encodeComponent(d.venue.trim())}';
  }

  static String? rsvpLink(InvitationDraft d) {
    final n = waNumber(d.rsvpPhone);
    if (n == null) return null;
    final date = d.date == null ? '' : ' on ${InviteDates.enDate(d.date!)}';
    final msg = 'Hello! I will attend the ${d.ceremony.en}$date. Number of guests: ';
    return 'https://wa.me/$n?text=${Uri.encodeComponent(msg)}';
  }

  /// Caption sent along with the card image(s).
  static String shareCaption(InvitationDraft d) {
    final g = greetingFor(d.ceremony.id);
    if (g != null) {
      // Greeting cards: just the wish, no date / venue / RSVP.
      return [if (d.needsTelugu) g.titleTe, if (d.needsEnglish) '${g.titleEn}!'].join('\n');
    }
    final b = StringBuffer();
    if (d.ceremony.isRemembrance) {
      // Quiet, respectful wording — no celebration emojis or exclamation marks.
      if (d.needsTelugu) b.writeln('ఆహ్వానం');
      b.writeln('Invitation: ${d.ceremony.en}');
    } else {
      if (d.needsTelugu) b.writeln('మీకు ఆహ్వానం 🙏');
      b.writeln("You're invited to our ${d.ceremony.en}!");
    }
    if (d.date != null) {
      b.write('🗓 ${InviteDates.enDate(d.date!)}');
      if (d.time != null) b.write(', ${InviteDates.enTime(d.time!)}');
      b.writeln();
    }
    if (d.meal.isNotEmpty) {
      final label = switch (d.meal) { 'breakfast' => 'Breakfast (tiffin)', 'dinner' => 'Dinner', _ => 'Lunch' };
      final place = d.mealVenue.trim().isNotEmpty ? d.mealVenue.trim() : d.venue.trim();
      final at = place.isEmpty ? '' : ' at $place';
      b.writeln(d.mealTime == null ? '🍽 $label will be served$at' : '🍽 $label from ${InviteDates.enTime(d.mealTime!)}$at');
    }
    if (d.venue.trim().isNotEmpty) b.writeln('📍 Location: ${mapLink(d)}');
    if (d.hasSchedule) {
      b.writeln();
      b.writeln('Functions:');
      for (final e in d.sortedEvents) {
        b.write('• ${e.nameEn}');
        if (e.date != null) b.write(' — ${InviteDates.enDate(e.date!)}');
        if (e.time != null) b.write(', ${InviteDates.enTime(e.time!)}');
        final link = e.mapLink.trim().isNotEmpty
            ? e.mapLink.trim()
            : (e.venue.trim().isNotEmpty ? 'https://maps.google.com/?q=${Uri.encodeComponent(e.venue.trim())}' : '');
        if (link.isNotEmpty) b.write('\n   📍 $link');
        b.writeln();
      }
      b.writeln();
    }
    final rsvp = rsvpLink(d);
    if (rsvp != null) b.writeln('✅ RSVP on WhatsApp: $rsvp');
    return b.toString().trim();
  }
}
