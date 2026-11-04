// Font choices the user can pick on the preview screen. All are free
// Google Fonts, downloaded once on first use and cached (0 KB in the APK).

class TeluguFont {
  final String name; // shown in its own font on the picker
  final String title; // headings + names
  final String body;
  const TeluguFont(this.name, this.title, this.body);
}

class EnglishFont {
  final String name;
  final String title;
  final String names; // bride/groom names (often a script font)
  final String body;
  const EnglishFont(this.name, this.title, this.names, this.body);
}

const teluguFonts = <TeluguFont>[
  TeluguFont('రామభద్ర', 'Ramabhadra', 'Mandali'),
  TeluguFont('సురన్న', 'Suranna', 'Suranna'),
  TeluguFont('ఎన్టీఆర్', 'NTR', 'Mandali'),
  TeluguFont('తెనాలి', 'Tenali Ramakrishna', 'Mandali'),
  TeluguFont('గిడుగు', 'Gidugu', 'Gidugu'),
  TeluguFont('మల్లన్న', 'Mallanna', 'Mallanna'),
  TeluguFont('తిమ్మన', 'Timmana', 'Mandali'),
  TeluguFont('తమ్ముడు', 'Baloo Tammudu 2', 'Baloo Tammudu 2'),
  TeluguFont('శ్రీ కృష్ణదేవరాయ', 'Sree Krushnadevaraya', 'Mandali'),
  TeluguFont('రామరాజ', 'Ramaraja', 'Ramaraja'),
  TeluguFont('నోటో సెరిఫ్', 'Noto Serif Telugu', 'Noto Serif Telugu'),
];

const englishFonts = <EnglishFont>[
  EnglishFont('Invite', 'Cormorant SC', 'Pinyon Script', 'Cormorant Garamond'),
  EnglishFont('Royal', 'Cinzel', 'Great Vibes', 'Lora'),
  EnglishFont('Elegant', 'Playfair Display', 'Playfair Display', 'Lora'),
  EnglishFont('Script', 'Great Vibes', 'Great Vibes', 'EB Garamond'),
  EnglishFont('Classic', 'Cormorant Garamond', 'Cormorant Garamond', 'Cormorant Garamond'),
  EnglishFont('Clean', 'Marcellus', 'Marcellus', 'Poppins'),
  EnglishFont('Luxe', 'Bodoni Moda', 'Parisienne', 'Libre Baskerville'),
  EnglishFont('Romantic', 'Italiana', 'Alex Brush', 'Lora'),
  EnglishFont('Festive', 'Cinzel Decorative', 'Allura', 'Cormorant Garamond'),
  EnglishFont('Modern', 'Montserrat', 'Sacramento', 'Montserrat'),
];
