# App Store screenshots (Klyra)

- `en/01..04.png` — framed marketing screenshots, **1320×2868** (iPhone 6.9", the required size). Upload these to App Store Connect → 1.0 Prepare for Submission → iPhone 6.9" Display, in order.
- `raw/` — the plain device captures used to build them.
- Built with **demo data only**: invented channel names + abstract logos, **no real brands** (App Review 5.2.3). The player frame uses the Creative-Commons film *Tears of Steel* as sample footage.

## Regenerate

1. **Demo content + local server**

   ```bash
   python3 scripts/store/make_demo_content.py /tmp/klyra_demo
   cd /tmp/klyra_demo && python3 -m http.server 8099 --bind 127.0.0.1
   ```

2. **Seed the app** (iPhone simulator): Add playlist → URL → `http://localhost:8099/klyra_demo.m3u`.

3. **Capture the raw screens** (one per store slide) into a folder, e.g. `raw/`:

   ```bash
   xcrun simctl io booted screenshot raw/cap1_channels.png   # Channels (with content)
   xcrun simctl io booted screenshot raw/cap4_add.png        # Add playlist
   xcrun simctl io booted screenshot raw/cap3_settings.png   # Settings
   xcrun simctl io booted screenshot raw/cap2_player.png     # Player (open "Cinema One")
   ```

   ⚠️ For the **player** shot the controls auto-hide after 4s. Temporarily raise the
   delay in `SwiftBase/Views/Player/PlayerScreen.swift` → `scheduleHide()`
   (`.now() + 4` → `.now() + 600`), rebuild, capture, then **revert to 4**.

4. **Frame them**

   ```bash
   python3 scripts/store/frame_screenshots.py raw AppStore/screenshots/en
   ```

   Edit the headline / subcaption map (`CAPTIONS`) at the top of
   `scripts/store/frame_screenshots.py`.

## Notes
- App is **iPhone-only** → no iPad screenshots needed.
- These are a first pass ("thử"). Polish ideas: nicer demo footage without a
  burned-in bitrate label, add a Car-mode and an EPG-grid slide (5 total).
