import 'package:flutter/material.dart';

import 'ceremony.dart';

/// A greeting-card occasion (festival or personal), with ready-made wishes
/// in Telugu and English. Each one becomes a [Ceremony] in the
/// "Greetings · శుభాకాంక్షలు" category, so the form, designs, preview,
/// sharing and video tools all work for greetings too.
class GreetingOccasion {
  final CeremonyId id;
  final String en; // list label: "Sankranti"
  final String te; // "సంక్రాంతి"
  final String titleEn; // card heading: "Happy Sankranti"
  final String titleTe; // "సంక్రాంతి శుభాకాంక్షలు"
  final IconData icon;
  final Set<Tradition> traditions;

  /// Preset wishes: (Telugu, English) pairs.
  final List<(String, String)> wishes;

  /// The design shown first (a CardLayout name, e.g. 'kites').
  final String design;

  const GreetingOccasion({
    required this.id,
    required this.en,
    required this.te,
    required this.titleEn,
    required this.titleTe,
    required this.icon,
    required this.traditions,
    required this.wishes,
    required this.design,
  });
}

const _h = {Tradition.hindu};
const _m = {Tradition.muslim};
const _c = {Tradition.christian};
const _all = {Tradition.hindu, Tradition.muslim, Tradition.christian};

const greetingOccasions = <GreetingOccasion>[
  // ---- Hindu festivals --------------------------------------------------------
  GreetingOccasion(
    id: CeremonyId.gSankranti,
    en: 'Sankranti',
    te: 'సంక్రాంతి',
    titleEn: 'Happy Sankranti',
    titleTe: 'సంక్రాంతి శుభాకాంక్షలు',
    icon: Icons.wb_sunny_outlined,
    traditions: _h,
    design: 'kites',
    wishes: [
      ('భోగి మంటలు, రంగవల్లులు, గాలిపటాలతో మీ ఇంట సిరిసంపదలు, ఆనందం నిండాలని కోరుకుంటూ',
          'May the Bhogi bonfires, colourful muggulu and soaring kites fill your home with joy and prosperity'),
      ('ఈ సంక్రాంతి మీ జీవితంలో కొత్త వెలుగులు నింపాలని ఆకాంక్షిస్తూ',
          'May this Sankranti bring new light and happiness into your life'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gUgadi,
    en: 'Ugadi',
    te: 'ఉగాది',
    titleEn: 'Happy Ugadi',
    titleTe: 'ఉగాది శుభాకాంక్షలు',
    icon: Icons.eco_outlined,
    traditions: _h,
    design: 'toran',
    wishes: [
      ('షడ్రుచుల ఉగాది పచ్చడిలా ఈ కొత్త సంవత్సరం మీ జీవితంలో అన్ని రుచులనూ, ఆనందాన్నీ నింపాలని కోరుకుంటూ',
          'Like the six tastes of Ugadi pachadi, may the new year bring you every flavour of joy'),
      ('ఈ నూతన సంవత్సరం మీకు ఆయురారోగ్య ఐశ్వర్యాలను ప్రసాదించాలని ఆకాంక్షిస్తూ',
          'Wishing you health, wealth and happiness in the new year'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gSriRamaNavami,
    en: 'Sri Rama Navami',
    te: 'శ్రీరామనవమి',
    titleEn: 'Happy Sri Rama Navami',
    titleTe: 'శ్రీరామనవమి శుభాకాంక్షలు',
    icon: Icons.temple_hindu_outlined,
    traditions: _h,
    design: 'temple',
    wishes: [
      ('సీతారాముల కళ్యాణ వైభవం మీ ఇంట సుఖసంతోషాలు నింపాలని కోరుకుంటూ',
          'May the blessings of Sita Rama fill your home with peace and happiness'),
      ('శ్రీరాముని ఆశీస్సులతో మీ కుటుంబం ఎల్లప్పుడూ సుఖశాంతులతో ఉండాలని ఆకాంక్షిస్తూ',
          'May Lord Rama bless your family with peace always'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gVinayakaChavithi,
    en: 'Vinayaka Chavithi',
    te: 'వినాయక చవితి',
    titleEn: 'Happy Vinayaka Chavithi',
    titleTe: 'వినాయక చవితి శుభాకాంక్షలు',
    icon: Icons.spa_outlined,
    traditions: _h,
    design: 'garland',
    wishes: [
      ('విఘ్నేశ్వరుని ఆశీస్సులతో మీరు చేపట్టే ప్రతి పనీ నిర్విఘ్నంగా సాగాలని కోరుకుంటూ',
          'May Lord Ganesha remove every obstacle and bless all your endeavours'),
      ('గణనాథుని కృపతో మీ ఇంట ఆనందం, ఐశ్వర్యం వెల్లివిరియాలని ఆకాంక్షిస్తూ',
          'May Ganapati fill your home with joy and prosperity'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gDasara,
    en: 'Dasara',
    te: 'దసరా',
    titleEn: 'Happy Dasara',
    titleTe: 'విజయదశమి శుభాకాంక్షలు',
    icon: Icons.local_fire_department_outlined,
    traditions: _h,
    design: 'garland',
    wishes: [
      ('చెడుపై మంచి సాధించిన విజయానికి ప్రతీక అయిన ఈ విజయదశమి మీకు అన్ని విజయాలనూ అందించాలని కోరుకుంటూ',
          'On Vijayadashami, the victory of good over evil, may success follow you in everything'),
      ('దుర్గమ్మ ఆశీస్సులతో మీ కుటుంబం సుఖసంతోషాలతో వర్ధిల్లాలని ఆకాంక్షిస్తూ',
          'May Goddess Durga bless your family with happiness'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gDeepavali,
    en: 'Deepavali',
    te: 'దీపావళి',
    titleEn: 'Happy Deepavali',
    titleTe: 'దీపావళి శుభాకాంక్షలు',
    icon: Icons.light_outlined,
    traditions: _h,
    design: 'deepam',
    wishes: [
      ('దీపాల వెలుగులు మీ జీవితంలో చీకట్లను తొలగించి, ఆనంద కాంతులు నింపాలని కోరుకుంటూ',
          'May the glow of the diyas drive away darkness and fill your life with light and joy'),
      ('లక్ష్మీదేవి కృపతో మీ ఇంట సిరిసంపదలు వెల్లివిరియాలని ఆకాంక్షిస్తూ',
          'May Goddess Lakshmi bless your home with wealth and prosperity'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gBathukamma,
    en: 'Bathukamma',
    te: 'బతుకమ్మ',
    titleEn: 'Happy Bathukamma',
    titleTe: 'బతుకమ్మ పండుగ శుభాకాంక్షలు',
    icon: Icons.local_florist_outlined,
    traditions: _h,
    design: 'garland',
    wishes: [
      ('పూల పండుగ బతుకమ్మ మీ జీవితంలో రంగురంగుల సంతోషాలను నింపాలని కోరుకుంటూ',
          'May the festival of flowers fill your life with colourful happiness'),
      ('గౌరమ్మ ఆశీస్సులతో మీ కుటుంబం సుఖసంతోషాలతో ఉండాలని ఆకాంక్షిస్తూ',
          'May Gauramma bless your family with joy'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gHoli,
    en: 'Holi',
    te: 'హోళీ',
    titleEn: 'Happy Holi',
    titleTe: 'హోళీ శుభాకాంక్షలు',
    icon: Icons.palette_outlined,
    traditions: _h,
    design: 'balloons',
    wishes: [
      ('రంగుల హోళీ మీ జీవితాన్ని ఆనందపు రంగులతో నింపాలని కోరుకుంటూ',
          'May the colours of Holi fill your life with happiness'),
      ('ఈ హోళీ మీకు ప్రేమ, స్నేహం, సంతోషాలను అందించాలని ఆకాంక్షిస్తూ',
          'Wishing you love, friendship and joy this Holi'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gRakhi,
    en: 'Raksha Bandhan',
    te: 'రాఖీ పండుగ',
    titleEn: 'Happy Raksha Bandhan',
    titleTe: 'రాఖీ పండుగ శుభాకాంక్షలు',
    icon: Icons.favorite_border,
    traditions: _h,
    design: 'garland',
    wishes: [
      ('అన్నాచెల్లెళ్ల, అక్కాతమ్ముళ్ల అనుబంధం ఎప్పటికీ ఇలాగే కొనసాగాలని కోరుకుంటూ',
          'May the bond between brothers and sisters grow stronger forever'),
      ('ఈ రక్షాబంధనం మీకు ప్రేమను, ఆనందాన్ని అందించాలని ఆకాంక్షిస్తూ',
          'Wishing you love and happiness this Raksha Bandhan'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gKrishnashtami,
    en: 'Krishnashtami',
    te: 'కృష్ణాష్టమి',
    titleEn: 'Happy Krishna Janmashtami',
    titleTe: 'శ్రీకృష్ణ జన్మాష్టమి శుభాకాంక్షలు',
    icon: Icons.music_note_outlined,
    traditions: _h,
    design: 'toran',
    wishes: [
      ('చిన్ని కృష్ణుని ఆశీస్సులతో మీ ఇంట ఆనందం నిండాలని కోరుకుంటూ', 'May little Krishna fill your home with joy'),
      ('శ్రీకృష్ణుని కృప మీపై ఎల్లప్పుడూ ఉండాలని ఆకాంక్షిస్తూ', 'May the grace of Lord Krishna always be with you'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gShivaratri,
    en: 'Maha Shivaratri',
    te: 'మహా శివరాత్రి',
    titleEn: 'Happy Maha Shivaratri',
    titleTe: 'మహా శివరాత్రి శుభాకాంక్షలు',
    icon: Icons.nightlight_outlined,
    traditions: _h,
    design: 'deepam',
    wishes: [
      ('ఆ పరమశివుని ఆశీస్సులు మీకు, మీ కుటుంబానికి ఎల్లప్పుడూ ఉండాలని కోరుకుంటూ',
          'May the blessings of Lord Shiva be with you and your family always'),
      ('ఓం నమః శివాయ — ఈ పవిత్ర రాత్రి మీకు శాంతిని, శక్తిని ప్రసాదించాలని ఆకాంక్షిస్తూ',
          'Om Namah Shivaya — may this holy night bring you peace and strength'),
    ],
  ),

  // ---- Muslim -------------------------------------------------------------------
  GreetingOccasion(
    id: CeremonyId.gRamadan,
    en: 'Ramadan Mubarak',
    te: 'రంజాన్ మాసం',
    titleEn: 'Ramadan Mubarak',
    titleTe: 'రంజాన్ మాస శుభాకాంక్షలు',
    icon: Icons.nightlight_round_outlined,
    traditions: _m,
    design: 'lanterns',
    wishes: [
      ('ఈ పవిత్ర రంజాన్ మాసం మీకు శాంతి, సహనం, అల్లాహ్ కరుణను ప్రసాదించాలని కోరుకుంటూ',
          'May this holy month bring you peace, patience and the mercy of Allah'),
      ('మీ రోజాలు, ప్రార్థనలు స్వీకరించబడాలని దువా చేస్తూ', 'May your fasts and prayers be accepted'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gEidUlFitr,
    en: 'Eid ul-Fitr (Ramzan)',
    te: 'రంజాన్ పండుగ',
    titleEn: 'Eid Mubarak',
    titleTe: 'రంజాన్ శుభాకాంక్షలు',
    icon: Icons.mosque_outlined,
    traditions: _m,
    design: 'lanterns',
    wishes: [
      ('ఈ ఈద్ మీ ఇంట ఆనందం, ప్రేమ, శాంతి నింపాలని కోరుకుంటూ — ఈద్ ముబారక్',
          'May this Eid fill your home with joy, love and peace'),
      ('అల్లాహ్ మీ కుటుంబానికి సుఖసంతోషాలు ప్రసాదించాలని దువా చేస్తూ', 'May Allah bless your family with happiness'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gBakrid,
    en: 'Bakrid (Eid al-Adha)',
    te: 'బక్రీద్',
    titleEn: 'Eid al-Adha Mubarak',
    titleTe: 'బక్రీద్ శుభాకాంక్షలు',
    icon: Icons.mosque_outlined,
    traditions: _m,
    design: 'mehrab',
    wishes: [
      ('త్యాగానికి ప్రతీక అయిన బక్రీద్ మీ జీవితంలో శాంతి, సమృద్ధి నింపాలని కోరుకుంటూ',
          'On this festival of sacrifice, may your life be filled with peace and plenty'),
      ('అల్లాహ్ మీ త్యాగాలను, ప్రార్థనలను స్వీకరించాలని దువా చేస్తూ', 'May Allah accept your sacrifices and prayers'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gMilad,
    en: 'Milad-un-Nabi',
    te: 'మిలాద్-ఉన్-నబీ',
    titleEn: 'Eid Milad-un-Nabi Mubarak',
    titleTe: 'మిలాద్-ఉన్-నబీ శుభాకాంక్షలు',
    icon: Icons.auto_awesome_outlined,
    traditions: _m,
    design: 'mehrab',
    wishes: [
      ('ప్రవక్త (స) బోధనలు మీ జీవితంలో శాంతి, కరుణను నింపాలని కోరుకుంటూ',
          'May the teachings of the Prophet (PBUH) fill your life with peace and kindness'),
      ('ఈ పవిత్ర దినం మీకు అల్లాహ్ కరుణను ప్రసాదించాలని దువా చేస్తూ', 'May this blessed day bring you the mercy of Allah'),
    ],
  ),

  // ---- Christian ----------------------------------------------------------------
  GreetingOccasion(
    id: CeremonyId.gChristmas,
    en: 'Christmas',
    te: 'క్రిస్మస్',
    titleEn: 'Merry Christmas',
    titleTe: 'క్రిస్మస్ శుభాకాంక్షలు',
    icon: Icons.park_outlined,
    traditions: _c,
    design: 'wreath',
    wishes: [
      ('యేసుక్రీస్తు జన్మదినం మీ ఇంట శాంతి, ప్రేమ, ఆనందాన్ని నింపాలని కోరుకుంటూ',
          'May the birth of Jesus Christ fill your home with peace, love and joy'),
      ('ప్రభువు కృప మీపై, మీ కుటుంబంపై ఎల్లప్పుడూ ఉండాలని ఆకాంక్షిస్తూ',
          "May the Lord's grace be upon you and your family always"),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gEaster,
    en: 'Easter',
    te: 'ఈస్టర్',
    titleEn: 'Happy Easter',
    titleTe: 'ఈస్టర్ శుభాకాంక్షలు',
    icon: Icons.wb_twilight_outlined,
    traditions: _c,
    design: 'chapel',
    wishes: [
      ('పునరుత్థానుడైన క్రీస్తు మీ జీవితంలో నూతన నిరీక్షణను నింపాలని కోరుకుంటూ',
          'May the risen Christ fill your life with new hope'),
      ('ఈ ఈస్టర్ మీకు శాంతి, ఆనందాన్ని అందించాలని ఆకాంక్షిస్తూ', 'Wishing you peace and joy this Easter'),
    ],
  ),

  // ---- For everyone ---------------------------------------------------------------
  GreetingOccasion(
    id: CeremonyId.gNewYear,
    en: 'New Year',
    te: 'నూతన సంవత్సరం',
    titleEn: 'Happy New Year',
    titleTe: 'నూతన సంవత్సర శుభాకాంక్షలు',
    icon: Icons.celebration_outlined,
    traditions: _all,
    design: 'fireworks',
    wishes: [
      ('ఈ నూతన సంవత్సరం మీకు ఆయురారోగ్యాలు, ఆనందం, విజయాలను అందించాలని కోరుకుంటూ',
          'Wishing you health, happiness and success in the new year'),
      ('కొత్త ఆశలు, కొత్త కలలతో ఈ ఏడాది మీకు అద్భుతంగా సాగాలని ఆకాంక్షిస్తూ',
          'May the new year bring new hopes and make your dreams come true'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gBirthday,
    en: 'Birthday Wishes',
    te: 'పుట్టినరోజు',
    titleEn: 'Happy Birthday',
    titleTe: 'పుట్టినరోజు శుభాకాంక్షలు',
    icon: Icons.cake_outlined,
    traditions: _all,
    design: 'balloons',
    wishes: [
      ('మీరు నిండు నూరేళ్లు ఆయురారోగ్యాలతో, సుఖసంతోషాలతో వర్ధిల్లాలని కోరుకుంటూ',
          'Wishing you a long, healthy and happy life'),
      ('మీ కలలన్నీ నిజం కావాలని, ప్రతి రోజూ ఆనందంగా సాగాలని ఆకాంక్షిస్తూ',
          'May all your dreams come true and every day be filled with joy'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gAnniversary,
    en: 'Anniversary Wishes',
    te: 'వివాహ వార్షికోత్సవం',
    titleEn: 'Happy Anniversary',
    titleTe: 'వివాహ వార్షికోత్సవ శుభాకాంక్షలు',
    icon: Icons.favorite_outline,
    traditions: _all,
    design: 'wreath',
    wishes: [
      ('మీ దాంపత్య జీవితం ఎల్లప్పుడూ ప్రేమ, అనురాగాలతో వర్ధిల్లాలని కోరుకుంటూ',
          'May your married life always be filled with love and togetherness'),
      ('మీ జంట నిండు నూరేళ్లు సుఖసంతోషాలతో ఉండాలని ఆకాంక్షిస్తూ', 'Wishing you both a lifetime of happiness together'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gIndependence,
    en: 'Independence Day',
    te: 'స్వాతంత్ర్య దినోత్సవం',
    titleEn: 'Happy Independence Day',
    titleTe: 'స్వాతంత్ర్య దినోత్సవ శుభాకాంక్షలు',
    icon: Icons.flag_outlined,
    traditions: _all,
    design: 'fireworks',
    wishes: [
      ('మన దేశ స్వేచ్ఛ కోసం ప్రాణాలర్పించిన వీరులను స్మరించుకుంటూ — జై హింద్!',
          'Saluting the heroes who gave us our freedom — Jai Hind!'),
      ('మన భారతదేశం ఎల్లప్పుడూ శాంతి, ప్రగతితో వర్ధిల్లాలని కోరుకుంటూ', 'May our India always prosper in peace and progress'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gRepublic,
    en: 'Republic Day',
    te: 'గణతంత్ర దినోత్సవం',
    titleEn: 'Happy Republic Day',
    titleTe: 'గణతంత్ర దినోత్సవ శుభాకాంక్షలు',
    icon: Icons.flag_outlined,
    traditions: _all,
    design: 'fireworks',
    wishes: [
      ('మన రాజ్యాంగ విలువలను గౌరవిస్తూ — జై హింద్!', 'Honouring the values of our Constitution — Jai Hind!'),
      ('భిన్నత్వంలో ఏకత్వమే మన బలం', 'Unity in diversity is our strength'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gMothersDay,
    en: "Mother's Day",
    te: 'మాతృ దినోత్సవం',
    titleEn: "Happy Mother's Day",
    titleTe: 'మాతృ దినోత్సవ శుభాకాంక్షలు',
    icon: Icons.volunteer_activism_outlined,
    traditions: _all,
    design: 'garland',
    wishes: [
      ('అమ్మ ప్రేమకు సాటి లేదు — ప్రపంచంలోని అమ్మలందరికీ వందనాలు', "There is no love like a mother's — salute to every mother"),
      ('నా జీవితానికి వెలుగైన అమ్మకు ప్రేమతో', 'To my mother, the light of my life, with love'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gFathersDay,
    en: "Father's Day",
    te: 'పితృ దినోత్సవం',
    titleEn: "Happy Father's Day",
    titleTe: 'పితృ దినోత్సవ శుభాకాంక్షలు',
    icon: Icons.volunteer_activism_outlined,
    traditions: _all,
    design: 'modern',
    wishes: [
      ('నా బలం, నా ధైర్యం అయిన నాన్నకు ప్రేమతో', 'To my father, my strength and courage, with love'),
      ('నాన్నల త్యాగానికి, ప్రేమకు వందనాలు', 'Saluting the love and sacrifice of every father'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gTeachersDay,
    en: "Teachers' Day",
    te: 'ఉపాధ్యాయ దినోత్సవం',
    titleEn: "Happy Teachers' Day",
    titleTe: 'ఉపాధ్యాయ దినోత్సవ శుభాకాంక్షలు',
    icon: Icons.school_outlined,
    traditions: _all,
    design: 'modern',
    wishes: [
      ('అక్షరం నేర్పి జీవితానికి దారి చూపిన గురువులందరికీ వందనాలు', 'Thank you to every teacher who lit the path of my life'),
      ('మీ బోధనలు ఎప్పటికీ మాకు మార్గదర్శకం', 'Your lessons will guide us forever'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gFriendship,
    en: 'Friendship Day',
    te: 'స్నేహితుల దినోత్సవం',
    titleEn: 'Happy Friendship Day',
    titleTe: 'స్నేహితుల దినోత్సవ శుభాకాంక్షలు',
    icon: Icons.people_outline,
    traditions: _all,
    design: 'balloons',
    wishes: [
      ('కష్టసుఖాల్లో తోడుండే నా ప్రియ స్నేహితునికి', 'To my dear friend, who stands by me in joy and sorrow'),
      ('మన స్నేహం ఎప్పటికీ ఇలాగే కొనసాగాలని కోరుకుంటూ', 'May our friendship last forever'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gCongrats,
    en: 'Congratulations',
    te: 'అభినందనలు',
    titleEn: 'Congratulations',
    titleTe: 'హృదయపూర్వక అభినందనలు',
    icon: Icons.emoji_events_outlined,
    traditions: _all,
    design: 'fireworks',
    wishes: [
      ('మీ విజయానికి హృదయపూర్వక అభినందనలు. మరిన్ని విజయాలు సాధించాలని కోరుకుంటూ',
          'Heartfelt congratulations on your success. Wishing you many more!'),
      ('మీ కృషికి తగిన ఫలితం దక్కింది — అభినందనలు!', 'Your hard work has paid off — congratulations!'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gThankYou,
    en: 'Thank You',
    te: 'ధన్యవాదాలు',
    titleEn: 'Thank You',
    titleTe: 'ధన్యవాదాలు',
    icon: Icons.handshake_outlined,
    traditions: _all,
    design: 'garland',
    wishes: [
      ('మీ ప్రేమకు, సహకారానికి హృదయపూర్వక ధన్యవాదాలు', 'Heartfelt thanks for your love and support'),
      ('మా వేడుకకు విచ్చేసి మమ్మల్ని ఆశీర్వదించినందుకు ధన్యవాదాలు', 'Thank you for joining our celebration and blessing us'),
    ],
  ),
  GreetingOccasion(
    id: CeremonyId.gGetWell,
    en: 'Get Well Soon',
    te: 'త్వరగా కోలుకోండి',
    titleEn: 'Get Well Soon',
    titleTe: 'త్వరగా కోలుకోవాలని',
    icon: Icons.healing_outlined,
    traditions: _all,
    design: 'wreath',
    wishes: [
      ('మీరు త్వరగా పూర్తి ఆరోగ్యంతో కోలుకోవాలని మనసారా కోరుకుంటున్నాము', 'Wishing you a speedy and complete recovery'),
      ('మీ ఆరోగ్యం కోసం ప్రార్థిస్తున్నాము', 'Our prayers are with you for your good health'),
    ],
  ),
];

GreetingOccasion? greetingFor(CeremonyId id) {
  for (final g in greetingOccasions) {
    if (g.id == id) return g;
  }
  return null;
}

/// The form for every greeting: who it's for, the wish, who it's from.
List<FieldSpec> greetingFields(GreetingOccasion g) => [
      const FieldSpec('to', 'To (optional)', 'ఎవరికి', required: false),
      FieldSpec('wish', 'Message', 'సందేశం',
          kind: FieldKind.choice,
          required: false,
          options: [
            for (var i = 0; i < g.wishes.length; i++) ChoiceOption('$i', g.wishes[i].$2, g.wishes[i].$1),
          ]),
      const FieldSpec('wishTe', 'Or write your own (Telugu, optional)', 'మీ సొంత సందేశం',
          kind: FieldKind.text, required: false),
      const FieldSpec('wishEn', 'Or write your own (English, optional)', 'ఇంగ్లీష్ సందేశం',
          kind: FieldKind.text, required: false),
      const FieldSpec('from', 'From (your name / family)', 'మీ పేరు / కుటుంబం'),
    ];

/// Every greeting occasion as a [Ceremony] in the Greetings category.
final List<Ceremony> greetingCeremonies = [
  for (final g in greetingOccasions)
    Ceremony(
      id: g.id,
      en: g.en,
      te: g.te,
      icon: g.icon,
      defaultDeity: Deity.none,
      showBlessingLine: false,
      traditions: g.traditions,
      category: CeremonyCategory.greeting,
      design: g.design,
      fields: greetingFields(g),
    ),
];
