#!/bin/bash
# Takes the promo-video screenshots from the running emulator / phone.
# Run the app first WITHOUT ads:   flutter run --dart-define=NO_ADS=true
# Then, in a second terminal:      bash tools/promo_shots.sh
# For each screen: get it ready in the app, come back here, press Enter.
cd "$(dirname "$0")/.." || exit 1
ADB=$(command -v adb || echo "$HOME/Library/Android/sdk/platform-tools/adb")
[ -x "$ADB" ] || { echo "adb not found. Install Android platform-tools."; exit 1; }
mkdir -p store/raw
shots=(
  "01_tradition|Tradition picker (Hindu / Muslim / Christian) — use 'Change' on the start page"
  "02_start|Start page: Celebrations / Remembrance / Greetings, Video editor, My videos"
  "03_ceremonies|Celebrations list for Hindu (Wedding, Housewarming, Birthday ...)"
  "04_details_names|Wedding details: surname + groom name with the Telugu box filled"
  "05_details_photos|Wedding details: bride name, Bride photo row, spelling chips"
  "06_details_muhurtham|Date & muhurtham with lagnam / nakshatram, lunch/dinner"
  "07_card_telugu|Preview: a beautiful Telugu wedding card"
  "08_card_designs|Preview: design thumbnails + font dropdown open"
  "09_card_english|Preview: the English card (or a Christian / Muslim one)"
  "10_video_title|Video editor playing: first frame 'surname వారి వివాహ ఆహ్వానము'"
  "11_video_couple|Video editor: couple frame with photo in the gold hexagons"
  "12_video_muhurtham|Video editor: సుముహూర్తం frame with the kalasam"
  "13_video_shapes|Video editor: card clip -> Shape strip (or Style -> Watercolour look)"
  "14_video_music|Video editor: Music tray open"
  "15_custom_reel|Video editor (custom): several clips + purple text track + Text tool"
  "16_greeting|A greeting card preview (Sankranti / Ugadi / Christmas)"
  "17_my_videos|My videos list"
  "18_share|After Export: 'Your video is ready' with Share / Save buttons"
)
for s in "${shots[@]}"; do
  name="${s%%|*}"; what="${s#*|}"
  read -r -p "[$name] $what  →  ready? Enter (s = skip) " ans
  [ "$ans" = "s" ] && continue
  "$ADB" exec-out screencap -p > "store/raw/$name.png" && echo "   saved store/raw/$name.png"
done
echo "Done. Tell Claude: screenshots are ready."
