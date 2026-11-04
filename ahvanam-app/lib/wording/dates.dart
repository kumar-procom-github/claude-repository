import 'package:flutter/material.dart';

/// Date/time phrasing for invitations, without the intl package.
class InviteDates {
  InviteDates._();

  static const _teWeekdays = [
    'సోమవారం', 'మంగళవారం', 'బుధవారం', 'గురువారం', 'శుక్రవారం', 'శనివారం', 'ఆదివారం',
  ];
  static const _enWeekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const _enMonths = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// ది. 12-12-2026 శనివారం
  static String teDate(DateTime d) =>
      'ది. ${_two(d.day)}-${_two(d.month)}-${d.year} ${_teWeekdays[d.weekday - 1]}';

  /// ఉదయం 10:30 గం॥లకు  — Telugu cards name the part of day, not AM/PM.
  static String teTime(TimeOfDay t) {
    final h = t.hour;
    final String part;
    if (h < 4) {
      part = 'రాత్రి';
    } else if (h < 6) {
      part = 'తెల్లవారుజామున';
    } else if (h < 12) {
      part = 'ఉదయం';
    } else if (h < 16) {
      part = 'మధ్యాహ్నం';
    } else if (h < 19) {
      part = 'సాయంత్రం';
    } else {
      part = 'రాత్రి';
    }
    return '$part ${_h12(t)}:${_two(t.minute)} గం॥లకు';
  }

  /// "ది. 12-12-2026 శనివారం ఉదయం 10:30 గం॥లకు" or "... శనివారం నాడు"
  static String teWhen(DateTime? d, TimeOfDay? t) {
    if (d == null) return '';
    return t == null ? '${teDate(d)} నాడు' : '${teDate(d)} ${teTime(t)}';
  }

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}th';
    return switch (n % 10) { 1 => '${n}st', 2 => '${n}nd', 3 => '${n}rd', _ => '${n}th' };
  }

  static String ordinal(int n) => _ordinal(n);

  /// Saturday, 12th December 2026
  static String enDate(DateTime d) =>
      '${_enWeekdays[d.weekday - 1]}, ${_ordinal(d.day)} ${_enMonths[d.month - 1]} ${d.year}';

  static int _h12(TimeOfDay t) => t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;

  /// 10:30 AM
  static String enTime(TimeOfDay t) =>
      '${_h12(t)}:${_two(t.minute)} ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}
