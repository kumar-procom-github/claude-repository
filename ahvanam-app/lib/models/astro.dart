/// Lagnam (rasi) and nakshatram names in English and Telugu.
/// Picked from a list instead of typed, so the Telugu card never has a
/// misspelt astrological term.
/// Lagnam value meaning "the user writes the whole muhurtham line".
const kOwnMuhurtham = 'own';

class AstroName {
  final String en;
  final String te;
  const AstroName(this.en, this.te);
}

const lagnams = <AstroName>[
  AstroName('Mesha', 'మేష'),
  AstroName('Vrishabha', 'వృషభ'),
  AstroName('Mithuna', 'మిథున'),
  AstroName('Karkataka', 'కర్కాటక'),
  AstroName('Simha', 'సింహ'),
  AstroName('Kanya', 'కన్యా'),
  AstroName('Tula', 'తులా'),
  AstroName('Vrischika', 'వృశ్చిక'),
  AstroName('Dhanus', 'ధనుర్'),
  AstroName('Makara', 'మకర'),
  AstroName('Kumbha', 'కుంభ'),
  AstroName('Meena', 'మీన'),
];

const nakshatrams = <AstroName>[
  AstroName('Ashwini', 'అశ్విని'),
  AstroName('Bharani', 'భరణి'),
  AstroName('Krittika', 'కృత్తిక'),
  AstroName('Rohini', 'రోహిణి'),
  AstroName('Mrigasira', 'మృగశిర'),
  AstroName('Arudra', 'ఆరుద్ర'),
  AstroName('Punarvasu', 'పునర్వసు'),
  AstroName('Pushyami', 'పుష్యమి'),
  AstroName('Ashlesha', 'ఆశ్లేష'),
  AstroName('Makha', 'మఖ'),
  AstroName('Pubba', 'పుబ్బ'),
  AstroName('Uttara', 'ఉత్తర'),
  AstroName('Hasta', 'హస్త'),
  AstroName('Chitta', 'చిత్త'),
  AstroName('Swati', 'స్వాతి'),
  AstroName('Visakha', 'విశాఖ'),
  AstroName('Anuradha', 'అనూరాధ'),
  AstroName('Jyeshta', 'జ్యేష్ఠ'),
  AstroName('Moola', 'మూల'),
  AstroName('Purvashadha', 'పూర్వాషాఢ'),
  AstroName('Uttarashadha', 'ఉత్తరాషాఢ'),
  AstroName('Sravanam', 'శ్రవణం'),
  AstroName('Dhanishta', 'ధనిష్ఠ'),
  AstroName('Satabhisham', 'శతభిషం'),
  AstroName('Purvabhadra', 'పూర్వాభాద్ర'),
  AstroName('Uttarabhadra', 'ఉత్తరాభాద్ర'),
  AstroName('Revati', 'రేవతి'),
];

AstroName? findAstro(List<AstroName> list, String? en) {
  if (en == null || en.isEmpty) return null;
  for (final a in list) {
    if (a.en == en) return a;
  }
  return null;
}
