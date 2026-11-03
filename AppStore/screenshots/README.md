# App Store screenshots (Klyra)

- `en/01..04.png` — framed marketing screenshots, **1206×2622** (iPhone 6.3"
  "medium display" — one of the sizes App Store Connect accepts). Upload in order.
  For the 6.9" slot pass `1320 2868` to the framing script instead.
- `raw/` — the plain device captures used to build them (iPhone 17 Pro Max, 1320×2868).
- Built with **demo data only**: invented channel names + abstract logos, **no real
  brands** (App Review 5.2.3). The player frame uses the Creative-Commons film
  *Tears of Steel* as sample footage.

## Regenerate

1. **Demo content + local server**

   ```bash
   python3 scripts/store/make_demo_content.py /tmp/klyra_demo
   cd /tmp/klyra_demo && python3 -m http.server 8099 --bind 127.0.0.1
   ```

2. **Seed the app** (iPhone simulator): Add playlist → URL → `http://localhost:8099/klyra_demo.m3u`.

3. **Capture the raw screens** (one per store slide) into a folder, e.g. `raw/`:

   ```bash
   DEV=<simulator-udid>
   xcrun simctl io $DEV screenshot raw/cap1_channels.png   # Channels (with content)
   xcrun simctl io $DEV screenshot raw/cap4_add.png        # Add playlist
   xcrun simctl io $DEV screenshot raw/cap3_settings.png   # Settings
   xcrun simctl io $DEV screenshot raw/cap2_player.png     # Player (open "Cinema One")
   ```

   For the **player** shot, open *Cinema One*, let it buffer, **tap once to show the
   controls**, then capture within ~4s (they auto-hide). If that's too tight, raise
   `scheduleHide()` in `Klyra/Views/Player/PlayerScreen.swift` (`.now() + 4` →
   `.now() + 600`), rebuild, capture, then revert.

4. **Frame them** (default 1206×2622; pass `W H` for another slot):

   ```bash
   python3 scripts/store/frame_screenshots.py raw AppStore/screenshots/en 1206 2622
   ```

   Edit the headline / subcaption map (`CAPTIONS`) at the top of
   `scripts/store/frame_screenshots.py`.

## Notes
- App is **iPhone-only** → no iPad screenshots needed.
- The player footage has a small burned-in bitrate label + "Unified Streaming"
  watermark (from the Tears of Steel demo stream). Swap for your own demo clip to
  remove it. Optional extra slides: Car mode, EPG grid.
