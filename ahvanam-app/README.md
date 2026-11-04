# Ahvanam: Invitation Maker (ఆహ్వానం)

Vums Labs · Flutter · MVP step 1: ceremony picker → details form → live card → share on WhatsApp.

## First run (in Antigravity / terminal, inside this folder)

```bash
flutter create . --project-name ahvanam --org com.vumslabs --platforms android,ios
rm test/widget_test.dart          # the generated sample test references MyApp, which doesn't exist here
flutter pub get
flutter test                      # wording + transliteration tests
flutter run
```

`flutter create .` only adds the missing platform folders; it keeps the `lib/`, `pubspec.yaml` and `test/` files already here.

**Release builds need internet permission** (Google Fonts are downloaded once, then cached). Add this line to
`android/app/src/main/AndroidManifest.xml`, just above `<application`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Also set `android:label="Ahvanam"` on `<application>`.

**Save to gallery (gal plugin)** — Android, same file:

```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```
and add `android:requestLegacyExternalStorage="true"` to `<application>`.
iOS `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Save your invitation cards to Photos.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Save your invitation cards to the Ahvanam album.</string>
```

Small APKs: `flutter build appbundle` for Play, or `flutter build apk --release --split-per-abi` to check per-device size.

**App identity:** name **Ahvanam: Invitation Maker** (home-screen label *Ahvanam*), app ID `com.vumslabs.ahvanam`, Dart package `ahvanam`. Flow: Tradition (Hindu / Muslim / Christian) → Category (Celebrations · వేడుకలు / Remembrance · సంస్మరణ) → Ceremony → Details → Preview. Remembrance cards (Pedda Karma, Vardhanthi = death anniversary, Jayanthi = birth anniversary of the departed, Chehlum, Barsi, Memorial Service, Remembrance Anniversary, Birth Anniversary Remembrance) get solemn headers, respectful wording (కీ.శే. / మర్హూమ్ / దివంగత, దుఃఖతప్త హృదయాలతో), sober designs (Deepam, Crescent, Candle & Lilies, Serene) and quiet colours (Shanti, Grey Blue, Sandal) only.

## What's built

| Area | File | Notes |
|---|---|---|
| 10 ceremonies | `lib/models/ceremony.dart` | Wedding, Nischitartham, Gruhapravesam, Barasala, Annaprasana, Seemantham, Upanayanam, Shashtipoorthi, Satyanarayana Vratham, Birthday. Each defines its own fields. |
| Telugu + English wording | `lib/wording/wording_engine.dart` | Offline. Telugu follows శుభలేఖ structure (శ్రీరస్తు…, deity line, చి॥ / చి॥ల॥సౌ॥ / సౌ॥, muhurtham sentence, ఆహ్వానించువారు). English has Traditional (Chi./S/o/Sri/Smt.) and Modern tones. |
| Lagnam / nakshatram | `lib/models/astro.dart` | Picked from lists (12 + 27), never typed → no misspelt Telugu terms. |
| Name auto-Telugu | `lib/wording/transliterator.dart` | Type "Chidibomma" → "చిడిబొమ్మ" appears, editable. Venue / function-hall names auto-fill too (dictionary of hall & address words + AP/Telangana areas: Sri Lakshmi Function Hall, Kukatpally → శ్రీ లక్ష్మి ఫంక్షన్ హాల్, కూకట్‌పల్లి). Telugu-tuned rules (retroflex డ between vowels, short ొ/ె before double consonants, శ్రీ prefix) + dictionary of ~110 names/surnames/cities. **"Other spellings" chips** under every Telugu field offer the ambiguous alternatives (ద/డ, ో/ొ, అ/ఆ, న్/ణ్, ల/ళ) — one tap to fix. |
| Multi-event wedding | `lib/models/event_item.dart`, `lib/widgets/event_editor.dart` | Pellikuthuru, Pellikoduku, Haldi, Mehendi, Sangeet, Snathakam, Muhurtham, Reception, Vratham or custom. Each with date, time, venue (defaults to main venue), map link. Rendered as an extra **Schedule** card page per language, sorted by date; listed with map links in the WhatsApp caption. |
| Gallery + PDF | `lib/services/export_service.dart` | Save PNGs to an album "Ahvanam"; print-ready PDF (4.5 × 8 in pages, ~320 dpi). |
| Telugu date/time | `lib/wording/dates.dart` | "ది. 12-12-2026 శనివారం ఉదయం 10:30 గం॥లకు" |
| 8 designs × 4 colours + fonts | `lib/templates/` | 4 design families × 2 variations: **Toran / Garland**, **Temple Arch / Gopuram**, **Kalasam / Deepam**, **Modern / Wreath**. Colours: Kumkum, Pasupu, Kanchi Silk, Malle. Fonts (`card_fonts.dart`): 7 Telugu (Ramabhadra, Suranna, NTR, Tenali, Gidugu, Mallanna, Timmana) and 5 English pairings (Royal, Elegant, Script, Classic, Clean). All drawn in code / Google Fonts → 0 KB of assets. Preview shows all 8 designs at once as live thumbnails of the user's own card. |
| Online designs + Refresh | `lib/services/template_catalog.dart`, `lib/config.dart`, `template-catalog/` | Illustrated artwork designs downloaded from a free catalog (GitHub + jsDelivr), cached on the phone, **refresh button** + NEW badges, shown with the user's own text. Add designs with the Ahvanam Template Studio web tool — no app update needed. Classic code-drawn designs remain as the offline fallback. Set your repo URL in `lib/config.dart`. |
| Card | `lib/widgets/invitation_card.dart` | 360×640 design, exported at 3× = 1080×1920 PNG. Text auto-shrinks to fit. Telugu gets taller line height. |
| Share + RSVP | `lib/services/` | Shares PNG(s) with a caption containing a free Google Maps link and a `wa.me` RSVP link with a pre-filled reply. No backend, no API keys. |

"Both" language mode produces two images (Telugu face + English face) shared together.

## Before release — must do
1. **Native-speaker review of every Telugu string** in `wording_engine.dart` (ideally also a purohit for wedding/upanayanam wording).
2. Test long names + ॥ marks on all 4 templates on a small phone.
3. Consider bundling Mandali + Ramabhadra (~few hundred KB) under `assets/fonts` so the first card works offline.

## Next steps (suggested order)
1. Photo of couple/baby on the card.
2. 15–20 s MP4 via Android MediaCodec / iOS AVAssetWriter platform channel (no FFmpeg — FFmpegKit is retired and adds tens of MB).
3. Monetisation: free cards with small "Made with Ahvanam" mark; one-time unlock per premium template (no subscriptions).
