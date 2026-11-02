# Ahvanam music library

Background music for Ahvanam video invitations. The app reads `catalog.json`
and downloads a track (from `tracks/`) only when the user picks it.

All tracks are **Ahvanam Originals**: synthesised from scratch by
`tools/synth.py` (no samples, no existing tunes), free to use and share.

## Add a track
1. Put an `.m4a` (AAC, 44.1 kHz, ~112 kbps, 30–90 s) in `tracks/`.
   Only use music you made yourself or that is CC0 / public domain.
2. Add an entry to `catalog.json`:
   `{"id": "my-track", "title": "My Track", "titleTe": "...", "mood": "wedding", "file": "tracks/my-track.m4a", "seconds": 60}`
3. Push. The app shows it the next time the Music section opens.

Moods: wedding · celebration · festive · devotional · soft · christian · eid · birthday.
