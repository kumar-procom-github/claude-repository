/// Offline English → Telugu name transliteration.
///
/// Romanised Telugu is ambiguous (d → ద or డ, o → ో or ొ, a → అ or ఆ …),
/// so this produces a best guess **plus alternative spellings** the user can
/// tap. No API, no model — a dictionary of common names and phonetic rules
/// tuned for Telugu names and surnames.
class Transliterator {
  Transliterator._();

  // (latin, dental/default letter, retroflex alternative)
  // Longest keys first so 'ksh' wins over 'k', 'th' over 't', etc.
  static const _consonants = <(String, String, String)>[
    ('ksh', 'క్ష', 'క్ష'), ('chh', 'ఛ', 'ఛ'),
    ('kh', 'ఖ', 'ఖ'), ('gh', 'ఘ', 'ఘ'), ('ch', 'చ', 'చ'), ('jh', 'ఝ', 'ఝ'),
    ('th', 'త', 'త'), ('dh', 'ధ', 'ఢ'), ('ph', 'ఫ', 'ఫ'), ('bh', 'భ', 'భ'),
    ('sh', 'ష', 'ష'),
    ('k', 'క', 'క'), ('g', 'గ', 'గ'), ('c', 'క', 'క'), ('j', 'జ', 'జ'),
    ('t', 'త', 'ట'), ('d', 'ద', 'డ'), ('n', 'న', 'ణ'), ('p', 'ప', 'ప'),
    ('f', 'ఫ', 'ఫ'), ('b', 'బ', 'బ'), ('m', 'మ', 'మ'), ('y', 'య', 'య'),
    ('r', 'ర', 'ర'), ('l', 'ల', 'ళ'), ('v', 'వ', 'వ'), ('w', 'వ', 'వ'),
    ('s', 'స', 'స'), ('h', 'హ', 'హ'), ('z', 'జ', 'జ'), ('x', 'క్స', 'క్స'),
    ('q', 'క', 'క'),
  ];

  // (latin, independent letter, vowel sign)
  static const _vowels = <(String, String, String)>[
    ('aa', 'ఆ', 'ా'), ('ai', 'ఐ', 'ై'), ('au', 'ఔ', 'ౌ'), ('ou', 'ఔ', 'ౌ'),
    ('ee', 'ఈ', 'ీ'), ('ii', 'ఈ', 'ీ'), ('oo', 'ఊ', 'ూ'), ('uu', 'ఊ', 'ూ'),
    ('a', 'అ', ''), ('i', 'ఇ', 'ి'), ('u', 'ఉ', 'ు'), ('e', 'ఏ', 'ే'),
    ('o', 'ఓ', 'ో'),
  ];

  /// Short forms of e / o: (independent, sign).
  static const _shortVowel = {'e': ('ఎ', 'ె'), 'o': ('ఒ', 'ొ')};

  static const _virama = '్';
  static const _anusvara = 'ం';
  static const _latinVowels = 'aeiou';

  // 'n' / 'm' before these become ం (Anand → ఆనంద్, Sampath → సంపత్).
  static const _nasalAfterN = {'k', 'kh', 'g', 'gh', 'ch', 'chh', 'j', 'jh', 't', 'th', 'd', 'dh', 's', 'sh'};
  static const _nasalAfterM = {'p', 'ph', 'b', 'bh'};

  /// Single-letter initials as Telugu speakers write them: K. → కె.
  static const _initials = {
    'a': 'ఎ', 'b': 'బి', 'c': 'సి', 'd': 'డి', 'e': 'ఇ', 'f': 'ఎఫ్',
    'g': 'జి', 'h': 'హెచ్', 'i': 'ఐ', 'j': 'జె', 'k': 'కె', 'l': 'ఎల్',
    'm': 'ఎం', 'n': 'ఎన్', 'o': 'ఓ', 'p': 'పి', 'q': 'క్యూ', 'r': 'ఆర్',
    's': 'ఎస్', 't': 'టి', 'u': 'యు', 'v': 'వి', 'w': 'డబ్ల్యు', 'x': 'ఎక్స్',
    'y': 'వై', 'z': 'జెడ్',
  };

  /// Common Telugu names, surnames, places and words that rules get wrong.
  static const _dictionary = {
    'sri': 'శ్రీ', 'shri': 'శ్రీ', 'sree': 'శ్రీ', 'mr': 'శ్రీ', 'mrs': 'శ్రీమతి',
    'smt': 'శ్రీమతి', 'and': 'మరియు', 'family': 'కుటుంబం', 'families': 'కుటుంబాలు',
    'srinivas': 'శ్రీనివాస్', 'srinivasa': 'శ్రీనివాస', 'srinivasu': 'శ్రీనివాసు',
    'venkat': 'వెంకట్', 'venkata': 'వెంకట', 'venkatesh': 'వెంకటేష్',
    'venkateswara': 'వేంకటేశ్వర', 'venkateswarlu': 'వెంకటేశ్వర్లు',
    'venkateswararao': 'వెంకటేశ్వరరావు', 'lakshmi': 'లక్ష్మి', 'laxmi': 'లక్ష్మి',
    'krishna': 'కృష్ణ', 'rao': 'రావు', 'reddy': 'రెడ్డి', 'naidu': 'నాయుడు',
    'chowdary': 'చౌదరి', 'choudary': 'చౌదరి', 'sharma': 'శర్మ', 'sastry': 'శాస్త్రి',
    'sastri': 'శాస్త్రి', 'shastri': 'శాస్త్రి', 'varma': 'వర్మ', 'raju': 'రాజు',
    'kumar': 'కుమార్', 'kumari': 'కుమారి', 'devi': 'దేవి', 'rama': 'రామ',
    'ram': 'రామ్', 'sai': 'సాయి', 'durga': 'దుర్గ', 'padma': 'పద్మ', 'sita': 'సీత',
    'seetha': 'సీత', 'sitha': 'సీత', 'geetha': 'గీత', 'gita': 'గీత', 'ravi': 'రవి',
    'ramesh': 'రమేష్', 'suresh': 'సురేష్', 'mahesh': 'మహేష్', 'ganesh': 'గణేష్',
    'naresh': 'నరేష్', 'rajesh': 'రాజేష్', 'swathi': 'స్వాతి', 'swati': 'స్వాతి',
    'anand': 'ఆనంద్', 'priya': 'ప్రియ', 'kavya': 'కావ్య', 'divya': 'దివ్య',
    'sravani': 'శ్రావణి', 'sravan': 'శ్రావణ్', 'sravya': 'శ్రావ్య', 'aditya': 'ఆదిత్య',
    'arjun': 'అర్జున్', 'rahul': 'రాహుల్', 'kiran': 'కిరణ్', 'praveen': 'ప్రవీణ్',
    'pavan': 'పవన్', 'prasad': 'ప్రసాద్', 'murthy': 'మూర్తి', 'murty': 'మూర్తి',
    'satyanarayana': 'సత్యనారాయణ', 'narayana': 'నారాయణ', 'subbarao': 'సుబ్బారావు',
    'bhavani': 'భవాని', 'saraswathi': 'సరస్వతి', 'parvathi': 'పార్వతి',
    'annapurna': 'అన్నపూర్ణ', 'vijaya': 'విజయ', 'jyothi': 'జ్యోతి', 'jyoti': 'జ్యోతి',
    'chaitanya': 'చైతన్య', 'sujatha': 'సుజాత', 'kalyan': 'కళ్యాణ్', 'kalyani': 'కళ్యాణి',
    'teja': 'తేజ', 'sindhu': 'సింధు', 'mounika': 'మౌనిక', 'harika': 'హారిక',
    'sneha': 'స్నేహ', 'anusha': 'అనూష', 'srujana': 'సృజన', 'bhargav': 'భార్గవ్',
    'sudha': 'సుధ', 'radha': 'రాధ', 'rani': 'రాణి', 'vani': 'వాణి',
    'gopal': 'గోపాల్', 'madhavi': 'మాధవి', 'swamy': 'స్వామి', 'swami': 'స్వామి',
    'kumaraswamy': 'కుమారస్వామి', 'yadav': 'యాదవ్', 'goud': 'గౌడ్', 'gupta': 'గుప్తా',
    'hyderabad': 'హైదరాబాద్', 'secunderabad': 'సికింద్రాబాద్', 'vijayawada': 'విజయవాడ',
    'guntur': 'గుంటూరు', 'visakhapatnam': 'విశాఖపట్నం', 'vizag': 'వైజాగ్',
    'tirupati': 'తిరుపతి', 'warangal': 'వరంగల్', 'nellore': 'నెల్లూరు',
    'kakinada': 'కాకినాడ', 'rajahmundry': 'రాజమండ్రి', 'karimnagar': 'కరీంనగర్',

    // Venue / address words — English words as Telugu cards spell them.
    'function': 'ఫంక్షన్', 'hall': 'హాల్', 'halls': 'హాల్స్', 'convention': 'కన్వెన్షన్',
    'conventions': 'కన్వెన్షన్స్', 'centre': 'సెంటర్', 'center': 'సెంటర్',
    'banquet': 'బాంక్వెట్', 'banquets': 'బాంక్వెట్స్', 'palace': 'ప్యాలెస్',
    'garden': 'గార్డెన్', 'gardens': 'గార్డెన్స్', 'resort': 'రిసార్ట్', 'resorts': 'రిసార్ట్స్',
    'hotel': 'హోటల్', 'temple': 'దేవాలయం', 'kalyana': 'కళ్యాణ', 'mandapam': 'మండపం',
    'kalyanamandapam': 'కళ్యాణమండపం', 'community': 'కమ్యూనిటీ', 'club': 'క్లబ్',
    'grand': 'గ్రాండ్', 'royal': 'రాయల్', 'imperial': 'ఇంపీరియల్', 'classic': 'క్లాసిక్',
    'nilayam': 'నిలయం', 'bhavan': 'భవన్', 'bhavanam': 'భవనం',
    'sadan': 'సదన్', 'kshetram': 'క్షేత్రం', 'vari': 'వారి',
    'road': 'రోడ్', 'rd': 'రోడ్', 'street': 'స్ట్రీట్', 'st': 'స్ట్రీట్', 'main': 'మెయిన్',
    'cross': 'క్రాస్', 'circle': 'సర్కిల్', 'junction': 'జంక్షన్', 'colony': 'కాలనీ',
    'nagar': 'నగర్', 'layout': 'లేఅవుట్', 'phase': 'ఫేజ్', 'sector': 'సెక్టార్',
    'plot': 'ప్లాట్', 'no': 'నెం', 'opp': 'ఎదురుగా', 'opposite': 'ఎదురుగా',
    'beside': 'పక్కన', 'near': 'దగ్గర', 'behind': 'వెనుక', 'hills': 'హిల్స్',
    'park': 'పార్క్', 'city': 'సిటీ', 'town': 'టౌన్',
    // A family's own house is written స్వగృహం on invitations (ఇల్లు offered as a chip).
    'house': 'స్వగృహం', 'home': 'స్వగృహం', 'residence': 'స్వగృహం', 'swagruham': 'స్వగృహం',
    'illu': 'ఇల్లు', 'nivasam': 'నివాసం',
    'residency': 'రెసిడెన్సీ', 'apartment': 'అపార్ట్‌మెంట్', 'apartments': 'అపార్ట్‌మెంట్స్',
    'towers': 'టవర్స్', 'enclave': 'ఎన్‌క్లేవ్', 'village': 'గ్రామం', 'district': 'జిల్లా',
    'dist': 'జిల్లా', 'mandal': 'మండలం', 'post': 'పోస్ట్', 'pin': 'పిన్', 'the': 'ది',
    'x': 'ఎక్స్', 'roads': 'రోడ్స్', 'new': 'న్యూ', 'old': 'ఓల్డ్', 'east': 'ఈస్ట్',
    'west': 'వెస్ట్', 'north': 'నార్త్', 'south': 'సౌత్', 'complex': 'కాంప్లెక్స్',
    'jubilee': 'జూబ్లీ', 'banjara': 'బంజారా', 'gachibowli': 'గచ్చిబౌలి',
    'kukatpally': 'కూకట్‌పల్లి', 'madhapur': 'మాదాపూర్', 'ameerpet': 'అమీర్‌పేట్',
    'dilsukhnagar': 'దిల్‌సుఖ్‌నగర్', 'hitech': 'హైటెక్', 'manikonda': 'మణికొండ',
    'kondapur': 'కొండాపూర్', 'uppal': 'ఉప్పల్', 'miyapur': 'మియాపూర్', 'lb': 'ఎల్బీ',
    'kompally': 'కొంపల్లి', 'shamshabad': 'శంషాబాద్', 'nizampet': 'నిజాంపేట్',
    'ongole': 'ఒంగోలు', 'kurnool': 'కర్నూలు', 'anantapur': 'అనంతపురం', 'kadapa': 'కడప',
    'eluru': 'ఏలూరు', 'khammam': 'ఖమ్మం', 'nizamabad': 'నిజామాబాద్', 'nalgonda': 'నల్గొండ',
    'srikakulam': 'శ్రీకాకుళం', 'vizianagaram': 'విజయనగరం', 'machilipatnam': 'మచిలీపట్నం',
    'bhimavaram': 'భీమవరం', 'tenali': 'తెనాలి', 'chittoor': 'చిత్తూరు',

    // Relationship words for "Invited by" lines (translated, respectful forms).
    'his': 'వారి', 'her': 'వారి', 'their': 'వారి', 'members': 'సభ్యులు',
    'relatives': 'బంధువులు', 'friends': 'స్నేహితులు', 'parents': 'తల్లిదండ్రులు',
    'children': 'పిల్లలు', 'son': 'కుమారుడు', 'sons': 'కుమారులు', 'daughter': 'కుమార్తె',
    'daughters': 'కుమార్తెలు', 'brother': 'సోదరుడు', 'brothers': 'సోదరులు',
    'sister': 'సోదరి', 'sisters': 'సోదరీమణులు', 'grandson': 'మనవడు',
    'granddaughter': 'మనవరాలు', 'garu': 'గారు', 'gaaru': 'గారు',
    // Common Telugu names whose long vowels (ా ీ ూ ే ో) English spelling hides.
    'naga': 'నాగ', 'nagarjuna': 'నాగార్జున', 'nagarjun': 'నాగార్జున్', 'nageswara': 'నాగేశ్వర',
    'nageswararao': 'నాగేశ్వరరావు', 'nageswari': 'నాగేశ్వరి', 'nagendra': 'నాగేంద్ర',
    'nagesh': 'నాగేష్', 'nagaiah': 'నాగయ్య', 'nagamma': 'నాగమ్మ', 'nagaraju': 'నాగరాజు',
    'nagamani': 'నాగమణి', 'arjuna': 'అర్జున', 'chiranjeevi': 'చిరంజీవి',
    'balakrishna': 'బాలకృష్ణ', 'bala': 'బాల', 'balaraju': 'బాలరాజు', 'balu': 'బాలు',
    'raja': 'రాజ', 'rajasekhar': 'రాజశేఖర్', 'rajashekar': 'రాజశేఖర్', 'rajendra': 'రాజేంద్ర',
    'rajini': 'రజిని', 'rajani': 'రజని', 'sekhar': 'శేఖర్', 'shekar': 'శేఖర్', 'shekhar': 'శేఖర్',
    'chandrasekhar': 'చంద్రశేఖర్', 'chandra': 'చంద్ర', 'bhaskar': 'భాస్కర్', 'prakash': 'ప్రకాష్',
    'prabhakar': 'ప్రభాకర్', 'sudhakar': 'సుధాకర్', 'diwakar': 'దివాకర్', 'vasu': 'వాసు',
    'vasavi': 'వాసవి', 'madhu': 'మధు', 'madhusudhan': 'మధుసూదన్', 'sambasiva': 'సాంబశివ',
    'sambasivarao': 'సాంబశివరావు', 'santhosh': 'సంతోష్', 'santosh': 'సంతోష్', 'sandeep': 'సందీప్',
    'sathish': 'సతీష్', 'satish': 'సతీష్', 'sankar': 'శంకర్', 'shankar': 'శంకర్',
    'anjali': 'అంజలి', 'anjaneyulu': 'ఆంజనేయులు', 'anjaneya': 'ఆంజనేయ', 'apparao': 'అప్పారావు',
    'bhagya': 'భాగ్య', 'bhagyalakshmi': 'భాగ్యలక్ష్మి', 'dhanalakshmi': 'ధనలక్ష్మి',
    'mahalakshmi': 'మహాలక్ష్మి', 'varalakshmi': 'వరలక్ష్మి', 'vijayalakshmi': 'విజయలక్ష్మి',
    'jagadish': 'జగదీష్', 'jagadeesh': 'జగదీష్', 'narasimha': 'నరసింహ', 'narasimharao': 'నరసింహారావు',
    'narsimha': 'నర్సింహ', 'prasanna': 'ప్రసన్న', 'pallavi': 'పల్లవి', 'ramya': 'రమ్య',
    'rekha': 'రేఖ', 'sailaja': 'శైలజ', 'sarala': 'సరళ', 'saritha': 'సరిత', 'sowjanya': 'సౌజన్య',
    'swapna': 'స్వప్న', 'usha': 'ఉష', 'vasantha': 'వసంత', 'yamuna': 'యమున', 'gowri': 'గౌరి',
    'gouri': 'గౌరి', 'gauri': 'గౌరి', 'govind': 'గోవింద్', 'govinda': 'గోవింద', 'gopi': 'గోపి',
    'hari': 'హరి', 'harish': 'హరీష్', 'haritha': 'హరిత', 'jaya': 'జయ', 'jayaram': 'జయరాం',
    'kamala': 'కమల', 'kishore': 'కిషోర్', 'krishnaveni': 'కృష్ణవేణి', 'lalitha': 'లలిత',
    'malathi': 'మాలతి', 'manjula': 'మంజుల', 'murali': 'మురళి', 'nirmala': 'నిర్మల',
    'padmavathi': 'పద్మావతి', 'padmaja': 'పద్మజ', 'radhika': 'రాధిక', 'raghavendra': 'రాఘవేంద్ర',
    'ranganath': 'రంగనాథ్', 'ratna': 'రత్న', 'seshu': 'శేషు', 'sesha': 'శేష', 'siva': 'శివ',
    'shiva': 'శివ', 'srikanth': 'శ్రీకాంత్', 'srilatha': 'శ్రీలత', 'subrahmanyam': 'సుబ్రహ్మణ్యం',
    'sunitha': 'సునీత', 'suneetha': 'సునీత', 'surya': 'సూర్య', 'suryanarayana': 'సూర్యనారాయణ',
    'tirupathi': 'తిరుపతి', 'uma': 'ఉమ', 'balaji': 'బాలాజీ', 'umamaheswara': 'ఉమామహేశ్వర', 'umamaheswararao': 'ఉమామహేశ్వరరావు',
    'vamsi': 'వంశీ', 'vamshi': 'వంశీ', 'veera': 'వీర', 'veeraiah': 'వీరయ్య', 'veerayya': 'వీరయ్య',
    'venu': 'వేణు', 'vinod': 'వినోద్', 'ramana': 'రమణ', 'ramaiah': 'రామయ్య', 'ramakrishna': 'రామకృష్ణ',
    'ravindra': 'రవీంద్ర', 'jayaprakash': 'జయప్రకాష్', 'koteswara': 'కోటేశ్వర',
    'koteswararao': 'కోటేశ్వరరావు', 'koti': 'కోటి', 'subba': 'సుబ్బ', 'satya': 'సత్య',
    'vijay': 'విజయ్', 'durgaprasad': 'దుర్గాప్రసాద్', 'sivaprasad': 'శివప్రసాద్',
    'babu': 'బాబు', 'prabhas': 'ప్రభాస్', 'charan': 'చరణ్',
    'ramcharan': 'రామ్‌చరణ్', 'pawan': 'పవన్', 'kalyanram': 'కళ్యాణ్‌రామ్', 'mohan': 'మోహన్',
    'david': 'డేవిడ్', 'john': 'జాన్', 'mary': 'మేరీ', 'joseph': 'జోసెఫ్', 'paul': 'పాల్',
    'peter': 'పీటర్', 'samuel': 'శామ్యూల్', 'daniel': 'డేనియల్', 'sarah': 'సారా', 'esther': 'ఎస్తేరు',
    'ruth': 'రూతు', 'grace': 'గ్రేస్', 'joy': 'జాయ్', 'prasanth': 'ప్రశాంత్', 'prashanth': 'ప్రశాంత్',
    'mohammed': 'మహమ్మద్', 'mohammad': 'మహమ్మద్', 'muhammad': 'ముహమ్మద్', 'abdul': 'అబ్దుల్',
    'ahmed': 'అహ్మద్', 'ahmad': 'అహ్మద్', 'khan': 'ఖాన్', 'shaik': 'షేక్', 'shaikh': 'షేక్',
    'sheikh': 'షేక్', 'syed': 'సయ్యద్', 'fatima': 'ఫాతిమా', 'ayesha': 'ఆయేషా', 'begum': 'బేగం',
    'rahim': 'రహీమ్', 'rahman': 'రెహమాన్', 'imran': 'ఇమ్రాన్', 'salma': 'సల్మా', 'nazia': 'నాజియా',
    'irfan': 'ఇర్ఫాన్', 'yusuf': 'యూసుఫ్', 'ibrahim': 'ఇబ్రహీం', 'hussain': 'హుస్సేన్', 'ali': 'అలీ',
    // Names that keep a final మ్.
    'sriram': 'శ్రీరామ్', 'seetharam': 'సీతారామ్', 'sitaram': 'సీతారామ్',
    'balram': 'బలరామ్', 'balaram': 'బలరామ్', 'raghuram': 'రఘురామ్', 'atmaram': 'ఆత్మారామ్',
    'shyam': 'శ్యామ్', 'gautam': 'గౌతమ్', 'gowtham': 'గౌతమ్', 'goutham': 'గౌతమ్', 'gautham': 'గౌతమ్',
    'pritam': 'ప్రీతమ్', 'preetam': 'ప్రీతమ్', 'uttam': 'ఉత్తమ్', 'purushottam': 'పురుషోత్తమ్',
    'hisham': 'హిషామ్', 'adam': 'ఆడమ్', 'abraham': 'అబ్రహామ్', 'william': 'విలియమ్', 'sam': 'సామ్',
    'kalam': 'కలామ్', 'salam': 'సలామ్', 'islam': 'ఇస్లాం', 'shivam': 'శివమ్', 'satyam': 'సత్యం',
    'vikram': 'విక్రమ్', 'shubham': 'శుభమ్', 'akram': 'అక్రమ్', 'ikram': 'ఇక్రమ్', 'pradyumnam': 'ప్రద్యుమ్నమ్',
    // Exceptions to the retroflex-n rule.
    'rohan': 'రోహన్', 'aryan': 'ఆర్యన్', 'raghu': 'రఘు', 'raghunath': 'రఘునాథ్',
    'raghunadh': 'రఘునాథ్', 'roshan': 'రోషన్', 'karthik': 'కార్తీక్',
  };

  /// First parts of compound names, longest first.
  static const _compoundHeads = [
    'venkata', 'lakshmi', 'krishna', 'satya', 'surya', 'naga', 'rama', 'siva', 'shiva',
    'bala', 'veera', 'raja', 'durga', 'vijaya', 'jaya', 'padma', 'subba', 'sai', 'uma', 'ravi',
  ];

  static final _wordPattern = RegExp(r'[A-Za-z]+');

  /// English phrases that must be *translated*, not sound-converted, written
  /// the respectful way Telugu invitations say them. Checked before words.
  static final _phrases = <(RegExp, String)>[
    for (final (pattern, te) in const [
      (r'(?:and|&)\s+(?:his|her|their)\s+famil(?:y|ies)', 'మరియు వారి కుటుంబ సభ్యులు'),
      (r'(?:and|&)\s+famil(?:y|ies)(?:\s+members)?', 'మరియు కుటుంబ సభ్యులు'),
      (r'(?:his|her|their)\s+famil(?:y|ies)', 'వారి కుటుంబ సభ్యులు'),
      (r'family\s+members', 'కుటుంబ సభ్యులు'),
      (r'(?:friends\s+(?:and|&)\s+relatives|relatives\s+(?:and|&)\s+friends)', 'బంధుమిత్రులు'),
      (r'with\s+best\s+(?:compliments|wishes)\s+from', 'శుభాకాంక్షలతో'),
      // Own house: 'our house', 'at our residence', 'own home' → స్వగృహం.
      (r'(?:at\s+)?(?:our|my|own|our\s+own|my\s+own)\s+(?:house|home|residence)', 'స్వగృహం'),
      (r'late(?![A-Za-z])\.?', 'కీ.శే.'), // Late Sri Ramaiah → కీ.శే. శ్రీ రామయ్య
    ])
      // Letter-boundaries instead of \b, so phrases starting with '&' match too.
      (RegExp('(?<![A-Za-z])$pattern(?![A-Za-z])', caseSensitive: false), te),
  ];

  /// Best-guess Telugu for a whole string; non-letters pass through.
  static String toTelugu(String input) {
    var text = input;
    for (final (re, te) in _phrases) {
      text = text.replaceAll(re, te);
    }
    // Telugu inserted above has no Latin letters, so it passes through untouched.
    return text.replaceAllMapped(_wordPattern, (m) => _word(m[0]!.toLowerCase(), const _Opts()));
  }

  // ---------------------------------------------------------------- places --

  /// English words in addresses written the way Telugu invitations write
  /// them (meaning or the usual Telugu spelling), not sounded out letter by
  /// letter. Used only for venues and addresses.
  static const _placeWords = {
    'church': 'చర్చి', 'churches': 'చర్చిలు', 'cathedral': 'కేథడ్రల్', 'chapel': 'చాపెల్',
    'temple': 'దేవాలయం', 'gudi': 'గుడి', 'mosque': 'మసీదు', 'masjid': 'మసీదు', 'dargah': 'దర్గా',
    'eidgah': 'ఈద్గా', 'idgah': 'ఈద్గా', 'mandir': 'మందిర్',
    'function': 'ఫంక్షన్', 'hall': 'హాల్', 'halls': 'హాల్స్', 'convention': 'కన్వెన్షన్',
    'centre': 'సెంటర్', 'center': 'సెంటర్', 'garden': 'గార్డెన్', 'gardens': 'గార్డెన్స్',
    'resort': 'రిసార్ట్', 'resorts': 'రిసార్ట్స్', 'hotel': 'హోటల్', 'banquet': 'బాంకెట్',
    'banquets': 'బాంకెట్స్', 'palace': 'ప్యాలెస్', 'mahal': 'మహల్', 'kalyana': 'కళ్యాణ',
    'mandapam': 'మండపం', 'mantapam': 'మండపం', 'mandapa': 'మండపం', 'community': 'కమ్యూనిటీ',
    'auditorium': 'ఆడిటోరియం', 'club': 'క్లబ్', 'grand': 'గ్రాండ్', 'royal': 'రాయల్',
    'road': 'రోడ్డు', 'rd': 'రోడ్డు', 'street': 'వీధి', 'lane': 'లేన్', 'colony': 'కాలనీ',
    'nagar': 'నగర్', 'village': 'గ్రామం', 'vill': 'గ్రామం', 'district': 'జిల్లా', 'dist': 'జిల్లా',
    'mandal': 'మండలం', 'town': 'పట్టణం', 'city': 'నగరం', 'main': 'మెయిన్', 'cross': 'క్రాస్',
    'junction': 'జంక్షన్', 'bus': 'బస్', 'stand': 'స్టాండ్', 'station': 'స్టేషన్', 'railway': 'రైల్వే',
    'school': 'స్కూల్', 'college': 'కాలేజీ', 'ground': 'గ్రౌండ్', 'grounds': 'గ్రౌండ్స్', 'beach': 'బీచ్',
    'park': 'పార్క్', 'apartment': 'అపార్ట్‌మెంట్', 'apartments': 'అపార్ట్‌మెంట్స్', 'flat': 'ఫ్లాట్',
    'floor': 'అంతస్తు', 'plot': 'ప్లాట్', 'no': 'నెం.', 'door': 'డోర్', 'post': 'పోస్ట్',
    'house': 'ఇల్లు', 'residence': 'నివాసం', 'home': 'ఇల్లు', 'new': 'నూతన', 'old': 'పాత',
    'st': 'సెయింట్', 'saint': 'సెయింట్', 'csi': 'సి.ఎస్.ఐ.', 'rcm': 'ఆర్.సి.ఎం.', 'baptist': 'బాప్టిస్ట్',
    'lutheran': 'లూథరన్', 'methodist': 'మెథడిస్ట్', 'pentecostal': 'పెంతెకోస్తు', 'mission': 'మిషన్',
    'prayer': 'ప్రార్థన', 'jama': 'జామా', 'noor': 'నూర్',
    'hyderabad': 'హైదరాబాద్', 'secunderabad': 'సికింద్రాబాద్', 'vijayawada': 'విజయవాడ',
    'visakhapatnam': 'విశాఖపట్నం', 'vizag': 'వైజాగ్', 'guntur': 'గుంటూరు', 'nellore': 'నెల్లూరు',
    'tirupati': 'తిరుపతి', 'warangal': 'వరంగల్', 'kakinada': 'కాకినాడ', 'rajahmundry': 'రాజమండ్రి',
    'eluru': 'ఏలూరు', 'ongole': 'ఒంగోలు', 'khammam': 'ఖమ్మం', 'karimnagar': 'కరీంనగర్',
    'kurnool': 'కర్నూలు', 'kadapa': 'కడప', 'anantapur': 'అనంతపురం', 'nizamabad': 'నిజామాబాద్',
    'bhimavaram': 'భీమవరం', 'tanuku': 'తణుకు', 'tenali': 'తెనాలి', 'machilipatnam': 'మచిలీపట్నం',
    'kotha': 'కొత్త', 'kottha': 'కొత్త', 'pedda': 'పెద్ద', 'chinna': 'చిన్న',
    'ganta': 'గంట', 'gandhi': 'గాంధీ', 'nehru': 'నెహ్రూ', 'ambedkar': 'అంబేద్కర్',
    'marys': 'మేరీస్', 'johns': 'జాన్స్', 'pauls': 'పాల్స్', 'peters': 'పీటర్స్', 'josephs': 'జోసెఫ్స్',
    'thomas': 'థామస్', 'marks': 'మార్క్స్', 'lukes': 'లూక్స్', 'andrews': 'ఆండ్రూస్',
  };

  /// Endings of Telugu village / town names (Gantavarigudem → గంటవారిగూడెం).
  static const _placeEndings = [
    ('gudem', 'గూడెం'), ('guda', 'గూడ'), ('palem', 'పాలెం'), ('palli', 'పల్లి'), ('pally', 'పల్లి'),
    ('palle', 'పల్లె'), ('puram', 'పురం'), ('peta', 'పేట'), ('pet', 'పేట'), ('nagar', 'నగర్'),
    ('wada', 'వాడ'), ('vada', 'వాడ'), ('varam', 'వరం'), ('padu', 'పాడు'), ('kota', 'కోట'),
    ('konda', 'కొండ'), ('cheruvu', 'చెరువు'), ('pudi', 'పూడి'), ('lanka', 'లంక'), ('vari', 'వారి'),
    ('gunta', 'గుంట'), ('ooru', 'ూరు'),
  ];

  /// "at the X" → "X వద్ద", "near X" → "X దగ్గర" …
  static final _placeLead = RegExp(
      r'^(at|near|opp\.?|opposite\s+(?:to\s+)?|beside|next\s+to|behind|in)\s+(?:the\s+)?(.+)$',
      caseSensitive: false);

  static String _placePost(String lead) {
    final l = lead.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    if (l == 'at') return ' వద్ద';
    if (l == 'near') return ' దగ్గర';
    if (l.startsWith('opp')) return ' ఎదురుగా';
    if (l == 'beside' || l == 'next to') return ' పక్కన';
    if (l == 'behind') return ' వెనుక';
    if (l == 'in') return 'లో';
    return '';
  }

  static String _placeWord(String w, _Opts o) {
    final known = _placeWords[w] ?? _dictionary[w];
    if (known != null) return known;
    // Possessive / plural of a known word: Mary's → మేరీస్.
    if (w.length > 3 && w.endsWith('s')) {
      final stem = _placeWords[w.substring(0, w.length - 1)] ?? _dictionary[w.substring(0, w.length - 1)];
      if (stem != null) return '$stemస్';
    }
    for (final (end, te) in _placeEndings) {
      if (w.length > end.length + 1 && w.endsWith(end)) {
        final stem = w.substring(0, w.length - end.length);
        var head = _placeWord(stem, o);
        // వారి / ూరు attach to a stem ending in a vowel sound.
        if (te.startsWith('ూ') && head.endsWith(_virama)) head = head.substring(0, head.length - 1);
        return '$head$te';
      }
    }
    return _word(w, o.asPlace);
  }

  /// Telugu for a venue / address: known words are translated (Church →
  /// చర్చి), "at the …" becomes "… వద్ద", village names keep their Telugu
  /// endings (-గూడెం, -పల్లి, -పేట …), the rest is sounded out.
  /// "At The Church, Gantavarigudem" → "చర్చి వద్ద, గంటవారిగూడెం".
  static String toTeluguPlace(String input) => _place(input);

  /// [vary]: (word number, options) — that one word is spelled with other
  /// options (for "Other spellings").
  static String _place(String input, [(int, _Opts)? vary]) {
    var text = input;
    for (final (re, te) in _phrases) {
      text = text.replaceAll(re, te);
    }
    var n = 0;
    final parts = text.split(',');
    return [
      for (final raw in parts)
        () {
          var seg = raw.trim();
          var post = '';
          final m = _placeLead.firstMatch(seg);
          if (m != null) {
            post = _placePost(m[1]!);
            seg = m[2]!.trim();
          }
          seg = seg.replaceAll(RegExp(r"'s(?![A-Za-z])", caseSensitive: false), 's');
          seg = seg.replaceAll(RegExp(r'(?<![A-Za-z])the(?![A-Za-z])\s*', caseSensitive: false), '');
          final te = seg.replaceAllMapped(_wordPattern, (m) {
            final o = vary != null && vary.$1 == n ? vary.$2 : const _Opts();
            n++;
            return _placeWord(m[0]!.toLowerCase(), o);
          });
          return '${te.trim()}$post';
        }(),
    ].where((x) => x.isNotEmpty).join(', ');
  }

  static const _placeVariantOpts = [
    _Opts(d: _Mode.dental),
    _Opts(d: _Mode.retroflex),
    _Opts(oe: _Mode.short),
    _Opts(oe: _Mode.long),
    _Opts(t: _Mode.retroflex),
    _Opts(t: _Mode.dental),
    _Opts(n: _Mode.dental),
    _Opts(n: _Mode.retroflex),
    _Opts(retroL: true),
    _Opts(keepM: true),
  ];

  /// Alternative spellings for a venue: one word changed at a time.
  static List<String> placeAlternatives(String input, {int max = 5}) {
    final base = toTeluguPlace(input);
    final out = <String>[];
    final words = _wordPattern.allMatches(input).length + 2;
    for (var i = 0; i < words; i++) {
      for (final o in _placeVariantOpts) {
        final full = _place(input, (i, o));
        if (full != base && !out.contains(full)) out.add(full);
        if (out.length >= max) return out;
      }
    }
    return out;
  }

  /// Up to [max] alternative spellings for the whole string (best guess not
  /// included). Each alternative changes one word, so the user can fix the
  /// surname without breaking the first name.
  static List<String> alternatives(String input, {int max = 5}) {
    final base = toTelugu(input);
    final matches = _wordPattern.allMatches(input).toList();
    final out = <String>[];
    for (final m in matches) {
      final w = m[0]!.toLowerCase();
      for (final alt in _wordVariants(w)) {
        final candidate = input.replaceRange(m.start, m.end, '\u0000');
        final full = toTelugu(candidate).replaceFirst('\u0000', alt);
        if (full != base && !out.contains(full)) out.add(full);
        if (out.length >= max) return out;
      }
    }
    return out;
  }

  /// Hand-picked alternatives for dictionary words that have more than one
  /// correct Telugu form.
  static const _dictionaryAlternatives = {
    'house': ['ఇల్లు', 'నివాసం', 'హౌస్'],
    'home': ['ఇల్లు', 'నివాసం', 'హోమ్'],
    'residence': ['నివాసం', 'ఇల్లు'],
  };

  /// Variants of a single word, most plausible first.
  static List<String> _wordVariants(String w) {
    final picked = _dictionaryAlternatives[w];
    if (picked != null) return picked;
    if (_dictionary.containsKey(w) || w.length == 1) return const [];
    final base = _word(w, const _Opts());
    final results = <String>[];
    void tryOpts(_Opts o, [String? word]) {
      final x = _word(word ?? w, o);
      if (x != base && !results.contains(x)) results.add(x);
    }

    tryOpts(const _Opts(d: _Mode.dental));
    tryOpts(const _Opts(d: _Mode.retroflex));
    tryOpts(const _Opts(oe: _Mode.short));
    tryOpts(const _Opts(oe: _Mode.long));
    // Native Telugu words often need both (Kondapalli → కొండపల్లి).
    tryOpts(const _Opts(d: _Mode.retroflex, oe: _Mode.short));
    tryOpts(const _Opts(d: _Mode.dental, oe: _Mode.long));
    // Lengthen one 'a' at a time (Gopal → గోపాల్, Madhavi → మాధవి).
    // The final letter is skipped: long ా at the end of a name is rare.
    var count = 0;
    for (var i = 0; i < w.length - 1 && count < 3; i++) {
      final isLoneA = w[i] == 'a' &&
          (i == 0 || w[i - 1] != 'a') &&
          w[i + 1] != 'a' &&
          w[i + 1] != 'i' &&
          w[i + 1] != 'u';
      if (isLoneA) {
        tryOpts(const _Opts(), '${w.substring(0, i)}aa${w.substring(i + 1)}');
        count++;
      }
    }
    // Two long ā together (Nagarjun → నాగార్జున్, Ramarao → రామారావు).
    final lone = <int>[
      for (var i = 0; i < w.length - 1; i++)
        if (w[i] == 'a' && (i == 0 || w[i - 1] != 'a') && !'aiu'.contains(w[i + 1])) i,
    ];
    for (var a = 0; a < lone.length && a < 3; a++) {
      for (var b = a + 1; b < lone.length && b < 3; b++) {
        final i = lone[a], j = lone[b];
        tryOpts(const _Opts(), '${w.substring(0, i)}aa${w.substring(i + 1, j)}aa${w.substring(j + 1)}');
      }
    }
    tryOpts(const _Opts(t: _Mode.retroflex));
    tryOpts(const _Opts(t: _Mode.dental));
    tryOpts(const _Opts(n: _Mode.dental));
    tryOpts(const _Opts(n: _Mode.retroflex));
    tryOpts(const _Opts(retroL: true));
    tryOpts(const _Opts(keepM: true)); // సుంకరమ్ if wanted
    return results;
  }

  static String _word(String w, _Opts o) {
    final known = _dictionary[w];
    if (known != null) return known;
    if (w.length == 1) return _initials[w] ?? w;

    // "-rao" names: Ramarao → రామారావు, Subbarao → సుబ్బారావు,
    // Srinivasarao → శ్రీనివాసరావు, Mohanrao → మోహన్‌రావు.
    if (w.length > 4 && w.endsWith('rao')) {
      final stem = w.substring(0, w.length - 3);
      var te = _word(stem, o);
      if (te.endsWith(_virama)) {
        te = '$te\u200C'; // ZWNJ: keep న్ + రా apart instead of a conjunct
      } else if (stem.endsWith('a') && !stem.endsWith('aa') && stem.length <= 5) {
        te = '$teా'; // short stems take a long vowel: రామ + రావు → రామారావు
      }
      return '$teరావు';
    }

    // Name compounds: a known first part + a fresh word
    // (Saikumar → సాయికుమార్, Balaraju → బాలరాజు, Venkataramana → వెంకటరమణ).
    for (final p in _compoundHeads) {
      if (w.length <= p.length + 1 || !w.startsWith(p)) continue;
      final rest = w.substring(p.length);
      final restKnown = _dictionary.containsKey(rest) || (rest.length > 4 && rest.endsWith('rao'));
      // Otherwise the rest must look like a word start: consonant + vowel.
      final c = _matchConsonant(rest, 0);
      final looksLikeWord = rest.length >= 4 && c != null && _matchVowel(rest, c.$1.length) != null;
      if (restKnown || looksLikeWord) return '${_dictionary[p]}${_word(rest, o)}';
    }

    // Sri / Shri / Sree prefix (Sridevi → శ్రీదేవి): the rest is a fresh word.
    for (final p in const ['shri', 'sree', 'sri']) {
      if (w.length > p.length && w.startsWith(p) && !_latinVowels.contains(w[p.length])) {
        return 'శ్రీ${_word(w.substring(p.length), o)}';
      }
    }

    final out = StringBuffer();
    var i = 0;
    // Retroflex-n rule (ణత్వం): after an 'r' (or క్ష), a later 'n' becomes ణ
    // unless a dental/palatal consonant comes between them:
    // Arani → అరణి, Varun → వరుణ్, Pranav → ప్రణవ్, but Rajini → రజిని.
    var natva = false;
    while (i < w.length) {
      final c = _matchConsonant(w, i);
      if (c != null) {
        final key = c.$1;
        final j = i + key.length;
        final prev = i > 0 ? w[i - 1] : '';
        final next = j < w.length ? w[j] : '';
        var letter = c.$2;

        if (key == 'sh' && i == 0) letter = 'శ'; // Shiva → శివ, Ramesh → రమేష్
        if (key == 'd') {
          // Between vowels or doubled, Telugu 'd' is usually retroflex డ
          // (Chidibomma → చిడిబొమ్మ, Reddy → రెడ్డి); elsewhere dental ద.
          final auto = (_isVowel(prev) && _isVowel(next)) || next == 'd' || prev == 'd' || (o.place && prev == 'n');
          if (_pick(o.d, auto)) letter = c.$3;
        }
        if (key == 't') {
          final auto = next == 't' || prev == 't' || (o.place && prev == 'n'); // Chitti → చిట్టి
          if (_pick(o.t, auto)) letter = c.$3;
        }
        if (key == 'l' && o.retroL) letter = c.$3; // Kalyan → కళ్యాణ్

        final v = _matchVowel(w, j);
        final nextC = v == null ? _matchConsonant(w, j) : null;
        final anusvara = v == null && out.isNotEmpty && nextC != null && _becomesAnusvara(key, nextC.$1);
        if (key == 'n' && !anusvara && (v != null || j == w.length) && _pick(o.n, natva)) letter = c.$3;
        if (_natvaTriggers.contains(key)) {
          natva = true;
        } else if (_natvaBlockers.contains(key)) {
          natva = false;
        }

        if (v != null) {
          out
            ..write(letter)
            ..write(_vowelSign(w, j, v, o));
          i = j + v.$1.length;
          continue;
        }
        // Telugu words ending in a short "-am" end in ం:
        // Sunkaram → సుంకరం, Navaratnam → నవరత్నం, Puram → పురం.
        final finalAm = key == 'm' &&
            j == w.length &&
            i >= 2 &&
            w[i - 1] == 'a' &&
            w[i - 2] != 'a' &&
            out.isNotEmpty &&
            !o.keepM;
        if (anusvara || finalAm) {
          out.write(_anusvara);
        } else {
          out
            ..write(letter)
            ..write(_virama);
        }
        i = j;
      } else {
        final v = _matchVowel(w, i);
        if (v != null) {
          final short = _shortVowel[v.$1];
          out.write(short != null && _isShort(w, i + 1, o) ? short.$1 : v.$2);
          i += v.$1.length;
        } else {
          out.write(w[i]);
          i++;
        }
      }
    }
    return out.toString();
  }

  static String _vowelSign(String w, int j, (String, String, String) v, _Opts o) {
    final short = _shortVowel[v.$1];
    if (short != null && _isShort(w, j + 1, o)) return short.$2;
    return v.$3;
  }

  /// e / o are short before a doubled consonant or cluster (Bomma → బొమ్మ,
  /// Reddy → రెడ్డి) and long otherwise (Ramesh → రమేష్, Gopi → గోపి).
  /// Before a nasal cluster they stay long (Hemanth → హేమంత్).
  static bool _isShort(String w, int afterVowel, _Opts o) {
    if (o.oe == _Mode.short) return true;
    if (o.oe == _Mode.long) return false;
    final c1 = _matchConsonant(w, afterVowel);
    if (c1 == null) return false;
    final c2 = _matchConsonant(w, afterVowel + c1.$1.length);
    if (c2 == null) return false;
    return !_becomesAnusvara(c1.$1, c2.$1);
  }

  static const _natvaTriggers = {'r', 'ksh'};
  static const _natvaBlockers = {'c', 'ch', 'chh', 'j', 'jh', 't', 'th', 'd', 'dh', 'l', 's', 'sh', 'z', 'x'};

  static bool _becomesAnusvara(String c, String next) =>
      (c == 'n' && _nasalAfterN.contains(next)) || (c == 'm' && _nasalAfterM.contains(next));

  static bool _pick(_Mode mode, bool auto) => switch (mode) {
        _Mode.auto => auto,
        _Mode.retroflex || _Mode.short => true,
        _Mode.dental || _Mode.long => false,
      };

  static bool _isVowel(String ch) => ch.isNotEmpty && _latinVowels.contains(ch);

  static (String, String, String)? _matchConsonant(String w, int i) {
    if (i >= w.length) return null;
    for (final c in _consonants) {
      if (w.startsWith(c.$1, i)) return c;
    }
    return null;
  }

  static (String, String, String)? _matchVowel(String w, int i) {
    if (i >= w.length) return null;
    for (final v in _vowels) {
      if (w.startsWith(v.$1, i)) return v;
    }
    return null;
  }
}

enum _Mode { auto, dental, retroflex, short, long }

class _Opts {
  final _Mode d;
  final _Mode t;
  final _Mode oe;
  final _Mode n;
  final bool retroL;

  /// Place names: 'nt' / 'nd' are retroflex (Ganta → గంట, Konda → కొండ).
  final bool place;

  /// Keep a final 'm' as మ్ (Gautam → గౌతమ్) instead of ం (Sunkaram → సుంకరం).
  final bool keepM;
  const _Opts({
    this.d = _Mode.auto,
    this.t = _Mode.auto,
    this.oe = _Mode.auto,
    this.n = _Mode.auto,
    this.retroL = false,
    this.place = false,
    this.keepM = false,
  });

  _Opts get asPlace => _Opts(d: d, t: t, oe: oe, n: n, retroL: retroL, place: true, keepM: keepM);
}
