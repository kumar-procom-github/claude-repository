import 'package:flutter_test/flutter_test.dart';
import 'package:ahvanam/templates/remote_template.dart';

void main() {
  test('parses a catalog entry from Template Studio', () {
    final t = RemoteTemplate.tryParse({
      'id': 'marigold-mandapam',
      'version': 2,
      'name': 'Marigold Mandapam',
      'nameTe': 'బంతిపూల మండపం',
      'ceremonies': ['wedding', 'engagement'],
      'art': 'art/marigold-mandapam.webp',
      'thumb': 'thumbs/marigold-mandapam.webp',
      'textBox': [58, 120, 302, 590],
      'scrim': 0.3,
      'colors': {'text': '#4A1A12', 'accent': '#8E1116'},
      'fonts': {'teTitle': 'Suranna'},
      'added': '2026-10-29',
    })!;
    expect(t.fits('wedding'), isTrue);
    expect(t.fits('birthday'), isFalse);
    expect(t.padding.left, 58);
    expect(t.padding.right, 360 - 302);
    expect(t.style.teTitleFont, 'Suranna');
    expect(t.style.teBodyFont, 'Mandali'); // default when not given
  });

  test('a broken entry is skipped, not a crash', () {
    expect(RemoteTemplate.tryParse({'name': 'no id or art'}), isNull);
    expect(RemoteTemplate.tryParse('nonsense'), isNull);
  });
}
