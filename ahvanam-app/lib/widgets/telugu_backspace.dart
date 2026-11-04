import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Backspace in Telugu removes one part of a letter at a time, like a Telugu
/// keyboard does: రోజా → రోజ → రో … (instead of removing all of "జా").
class TeluguBackspaceFormatter extends TextInputFormatter {
  const TeluguBackspaceFormatter();

  static bool _telugu(int r) => (r >= 0x0C00 && r <= 0x0C7F) || r == 0x200C || r == 0x200D;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final o = oldValue.selection, n = newValue.selection;
    if (!o.isValid || !n.isValid || !o.isCollapsed || !n.isCollapsed) return newValue;
    final removed = o.baseOffset - n.baseOffset;
    final old = oldValue.text, now = newValue.text;
    // Only a plain backspace of 2+ code units just before the cursor.
    if (removed < 2 || old.length - now.length != removed) return newValue;
    if (now != old.substring(0, n.baseOffset) + old.substring(o.baseOffset)) return newValue;
    final gone = old.substring(n.baseOffset, o.baseOffset);
    // Exactly one Telugu letter cluster (జా, క్ష, ...) made of several parts.
    if (gone.characters.length != 1) return newValue;
    final runes = gone.runes.toList();
    if (runes.length < 2 || !runes.every(_telugu)) return newValue;
    final cut = o.baseOffset - String.fromCharCode(runes.last).length;
    return TextEditingValue(
      text: old.substring(0, cut) + old.substring(o.baseOffset),
      selection: TextSelection.collapsed(offset: cut),
    );
  }
}
