#!/usr/bin/env python3
"""Compose framed App Store marketing screenshots (1320x2868, iPhone 6.9").

Takes raw device captures and places each on a brand-gradient background with a
headline + subcaption. Capture the raw screens first with:
    xcrun simctl io booted screenshot <raw_dir>/<name>.png

Usage:
    python3 scripts/store/frame_screenshots.py <raw_dir> <out_dir>

Map a headline/subcaption to each raw file in CAPTIONS below (keyed by filename).
"""
import sys, os, math, numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1320, 2868
def hx(h): return ((h >> 16) & 255, (h >> 8) & 255, h & 255)
SKY, BLUE, INDIGO = hx(0x4FB0F6), hx(0x2E7BF0), hx(0x223FC0)

# filename (in raw_dir) -> (headline lines, subcaption)
CAPTIONS = {
    "cap1_channels.png": (["Your channels,", "organized"],
                          "Groups, search, favorites & health at a glance"),
    "cap4_add.png":      (["Add M3U, Xtream", "or a QR code"],
                          "Your own playlists — login kept in the Keychain"),
    "cap3_settings.png": (["Guide, health &", "parental lock"],
                          "EPG now/next, A-Z, data saver, 16 languages"),
    "cap2_player.png":   (["A player built", "for watching"],
                          "Picture in Picture, subtitles, car mode, sleep timer"),
}
ORDER = ["cap1_channels.png", "cap4_add.png", "cap3_settings.png", "cap2_player.png"]

def grad(stops, angle=120):
    ar = math.radians(angle); dx, dy = math.cos(ar), math.sin(ar)
    X, Y = np.meshgrid(np.arange(W), np.arange(H)); p = X * dx + Y * dy
    p = (p - p.min()) / (p.max() - p.min())
    r = np.zeros_like(p); g = np.zeros_like(p); b = np.zeros_like(p)
    for i in range(len(stops) - 1):
        t0, c0 = stops[i]; t1, c1 = stops[i + 1]
        m = (p >= t0) & (p <= t1); f = (p - t0) / (t1 - t0 + 1e-9)
        for ch, a in zip(range(3), (r, g, b)): a[m] = c0[ch] + (c1[ch] - c0[ch]) * f[m]
    for ch, a in zip(range(3), (r, g, b)):
        a[p < stops[0][0]] = stops[0][1][ch]; a[p > stops[-1][0]] = stops[-1][1][ch]
    return Image.fromarray(np.dstack([r, g, b]).astype(np.uint8), "RGB")

def font(sz, bold=True):
    base = "Arial Bold.ttf" if bold else "Arial.ttf"
    for p in (f"/System/Library/Fonts/Supplemental/{base}", f"/Library/Fonts/{base}"):
        try: return ImageFont.truetype(p, sz)
        except OSError: pass
    return ImageFont.load_default()

def rounded(img, rad):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, *img.size], radius=rad, fill=255)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0)); out.paste(img, (0, 0), m); return out

def frame(raw_path, head, sub):
    bg = grad([(0.0, SKY), (0.5, BLUE), (1.0, INDIGO)], 120).convert("RGBA")
    d = ImageDraw.Draw(bg)
    HEAD, SUB = font(96), font(46, bold=False)
    y = 150
    for ln in head:
        bb = d.textbbox((0, 0), ln, font=HEAD); w = bb[2] - bb[0]
        d.text((W / 2 - w / 2 - bb[0], y), ln, font=HEAD, fill=(255, 255, 255))
        y += (bb[3] - bb[1]) + 14
    bb = d.textbbox((0, 0), sub, font=SUB)
    d.text((W / 2 - (bb[2] - bb[0]) / 2, y + 6), sub, font=SUB, fill=(234, 242, 255))
    shot = Image.open(raw_path).convert("RGB")
    tw = 1040; th = int(tw * shot.size[1] / shot.size[0])
    shot = rounded(shot.resize((tw, th), Image.LANCZOS), 62)
    sx, sy = (W - tw) // 2, 560
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh.paste(Image.new("RGBA", (tw, th), (0, 0, 0, 120)), (sx, sy + 18),
             rounded(Image.new("RGB", (tw, th)), 62))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(40)))
    bg.alpha_composite(shot, (sx, sy))
    return bg.convert("RGB")

def main(raw, out):
    os.makedirs(out, exist_ok=True)
    for i, fn in enumerate(ORDER, 1):
        src = os.path.join(raw, fn)
        if not os.path.exists(src):
            print("skip (missing):", fn); continue
        head, sub = CAPTIONS[fn]
        outp = os.path.join(out, f"{i:02d}_{fn.split('_', 1)[1]}")
        frame(src, head, sub).save(outp); print("wrote", outp)

if __name__ == "__main__":
    raw = sys.argv[1] if len(sys.argv) > 1 else "caps"
    out = sys.argv[2] if len(sys.argv) > 2 else "AppStore/screenshots/en"
    main(raw, out)
