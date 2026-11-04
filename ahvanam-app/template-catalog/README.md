# Ahvanam template catalog

This folder is what the app downloads when users tap **Refresh** on the design screen.
It holds illustrated designs (artwork + text area + colours + fonts). Add designs here
any time — no app update or Play Store review needed.

```
template-catalog/
  catalog.json        list of designs (the app reads this)
  art/<id>.webp       full artwork, 1080 × 1920, ideally < 250 KB
  thumbs/<id>.webp    thumbnail, 270 × 480, ~20 KB
```

## Add a design
1. Open **Ahvanam Template Studio** (the web tool), upload the artwork.
2. Drag the text box to where the wording should sit, pick colours/fonts, check
   the Telugu and English preview.
3. Save the artwork → `art/`, thumbnail → `thumbs/`, load + save `catalog.json` here.
4. Commit and push.

## Free hosting (GitHub + jsDelivr)
1. Create a **public** GitHub repo, e.g. `ahvanam-templates`, and push this folder's
   contents to its root.
2. In the app, set `lib/config.dart`:
   `https://cdn.jsdelivr.net/gh/<github-user>/ahvanam-templates@main/catalog.json`
3. After every push, clear the CDN cache so phones see it immediately (otherwise
   up to ~12 hours) by opening:
   `https://purge.jsdelivr.net/gh/<github-user>/ahvanam-templates@main/catalog.json`
   (Artwork files never need purging: each new version gets a new file name in the
   app's cache because the `version` number is part of it.)

When you change an existing design's artwork, bump its `version` in the Studio
(it does this automatically when you re-add the same id).

Note: a public repo means anyone can download the artwork. If that matters later,
move the same folder to Cloudflare R2 (free tier: 10 GB, no bandwidth charges) and
change only the URL in `lib/config.dart`.

## Artwork rights — important
Only use artwork you own or are licensed to use **inside an app's editable
templates**. Do not use cards downloaded from websites/WhatsApp designers.
Good sources: commissioned illustrators (buy full commercial rights), AI image
tools whose terms allow commercial use, or stock with an extended/template licence.
Leave clear space in the artwork for the text (the Studio shows you).
