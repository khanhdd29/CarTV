#!/usr/bin/env python3
"""Generate demo channel logos + an M3U playlist for App Store screenshots.

Demo data only — invented channel names and abstract logos, NO real brands
(App Review 5.2.3). One channel ("Cinema One") points at the Creative-Commons
"Tears of Steel" HLS so the player screenshot shows real footage; the rest point
at Apple's public sample stream.

Usage:
    python3 scripts/store/make_demo_content.py <output_dir>
    cd <output_dir> && python3 -m http.server 8099 --bind 127.0.0.1
Then in the app: Add playlist → URL → http://localhost:8099/klyra_demo.m3u
"""
import sys, os, math
from PIL import Image, ImageDraw, ImageFont

APPLE = "https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8"
NICE  = "https://demo.unified-streaming.com/k8s/features/stable/video/tears-of-steel/tears-of-steel.ism/.m3u8"

# (name, initials, group, (gradient c1, c2)); Cinema One gets the film stream.
CHANNELS = [
    ("Nova News 24", "NN", "News",   (0x2E7BF0, 0x223FC0)),
    ("Aurora Sport", "AS", "Sports", (0x34D6F2, 0x2E7BF0)),
    ("Cinema One",   "C1", "Movies", (0x8B5CF6, 0x5B3BD0)),
    ("Pulse Music",  "PM", "Music",  (0xFF4D6D, 0xC01048)),
    ("Kids Planet",  "KP", "Kids",   (0x34D399, 0x0E9E6E)),
    ("Globe Docs",   "GD", "Docs",   (0xF5A623, 0xC97A00)),
    ("Tech Live",    "TL", "Tech",   (0x22D3EE, 0x2E7BF0)),
    ("City Weather", "CW", "News",   (0x5B8DEF, 0x3A4FC0)),
]

def hx(h): return ((h >> 16) & 255, (h >> 8) & 255, h & 255)
def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))

def font(sz):
    for p in ("/System/Library/Fonts/Supplemental/Arial Bold.ttf",
              "/Library/Fonts/Arial Bold.ttf"):
        try: return ImageFont.truetype(p, sz)
        except OSError: pass
    return ImageFont.load_default()

def main(out):
    os.makedirs(out, exist_ok=True)
    S = 256
    f = font(96)
    for name, ini, grp, (c1, c2) in CHANNELS:
        img = Image.new("RGB", (S, S)); px = img.load()
        a, b = hx(c1), hx(c2)
        for y in range(S):
            for x in range(S):
                px[x, y] = lerp(a, b, (x + y) / (2 * S))
        d = ImageDraw.Draw(img)
        bb = d.textbbox((0, 0), ini, font=f); w, h = bb[2] - bb[0], bb[3] - bb[1]
        d.text(((S - w) / 2 - bb[0], (S - h) / 2 - bb[1]), ini, font=f, fill=(255, 255, 255))
        img.save(f"{out}/logo_{ini.lower()}.png")
    lines = ["#EXTM3U"]
    for name, ini, grp, _ in CHANNELS:
        stream = NICE if name == "Cinema One" else APPLE
        lines.append(f'#EXTINF:-1 tvg-id="{ini.lower()}" '
                     f'tvg-logo="http://localhost:8099/logo_{ini.lower()}.png" '
                     f'group-title="{grp}",{name}')
        lines.append(stream)
    open(f"{out}/klyra_demo.m3u", "w").write("\n".join(lines) + "\n")
    print(f"Wrote {len(CHANNELS)} logos + klyra_demo.m3u to {out}")

if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "demo_server")
