import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ahvanam/widgets/telugu_backspace.dart';

TextEditingValue _v(String t) =>
    TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));

/// [after] is what Flutter sends for one backspace (the whole last letter gone).
String _backspace(String before, String after) =>
    const TeluguBackspaceFormatter().formatEditUpdate(_v(before), _v(after)).text;

void main() {
  test('backspace removes one part of a Telugu letter at a time', () {
    expect(_backspace('రోజా', 'రో'), 'రోజ');
    expect(_backspace('రోజ', 'రో'), 'రో');
    expect(_backspace('రో', ''), 'ర');
    expect(_backspace('లక్ష్మి', 'లక్ష్'), 'లక్ష్మ');
  });

  test('English and single letters are untouched', () {
    expect(_backspace('Roja', 'Roj'), 'Roj');
    expect(_backspace('ర', ''), '');
  });
}
