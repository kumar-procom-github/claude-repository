/// The generated text of one card face, as an ordered list of styled lines.
/// Templates decide fonts/colours per [LineRole]; the wording engine only
/// decides *what* is said.
enum LineRole {
  /// Big heading: శుభలేఖ / Wedding Invitation
  title,

  /// శ్రీరస్తు శుభమస్తు అవిఘ్నమస్తు
  blessing,

  /// Deity invocation line
  deity,

  /// Normal sentence text
  body,

  /// A person's name, shown large and decorative
  name,

  /// Small parentage line under a name (S/o ..., దంపతుల కుమారుడు)
  small,

  /// "with" / "మరియు" between names
  connector,

  /// Date and time — the most important facts
  highlight,

  /// Section label: Venue, ఆహ్వానించువారు
  label,

  /// Function name on the schedule page: Haldi, సంగీత్
  event,

  /// Value under a label
  value,

  /// The closing request to attend/bless
  closing,

  /// Vertical breathing room
  spacer,

  /// Small decorative icon that opens a section (🍽 before lunch / dinner).
  /// The line's text names the icon: 'meal'.
  icon,
}

/// How text lines appear in a video invitation.
enum TextReveal {
  fadeUp('Fade up', 'పైకి'),
  zoom('Zoom', 'జూమ్'),
  slide('Slide', 'స్లైడ్');

  const TextReveal(this.en, this.te);
  final String en;
  final String te;
}

class CardLine {
  final String text;
  final LineRole role;
  const CardLine(this.text, this.role);
}

class CardText {
  final List<CardLine> lines;
  final bool telugu;
  const CardText(this.lines, {required this.telugu});
}
