#!/usr/bin/env python3
"""Count App Store field lengths from metadata.md.

Parses each **Field** marker followed by a ```text ... ``` block and checks it
against Apple's App Store Connect limits. Re-run after editing any copy:

    python3 AppStore/count_metadata.py
"""
import re, sys, pathlib

LIMITS = {
    "App Name": 30,
    "Subtitle": 30,
    "Promotional Text": 170,
    "Keywords": 100,
    "Description": 4000,
    "What's New": 4000,
}

MARKERS = [
    ("App Name", r"\*\*App Name\*\*"),
    ("Subtitle", r"\*\*Subtitle\*\*"),
    ("Promotional Text", r"\*\*Promotional Text\*\*"),
    ("Keywords", r"\*\*Keywords\*\*"),
    ("Description", r"\*\*Description\*\*"),
    ("What's New", r"\*\*What's New"),
]

def grab_block(text, marker):
    m = re.search(marker, text)
    if not m:
        return None
    fence = re.search(r"```text\n(.*?)\n```", text[m.end():], re.S)
    return fence.group(1) if fence else None

def main():
    md = pathlib.Path(__file__).with_name("metadata.md").read_text(encoding="utf-8")
    ok = True
    print(f"{'Field':18} {'Len':>5} {'Limit':>6}  Status")
    print("-" * 40)
    for name, marker in MARKERS:
        block = grab_block(md, marker)
        if block is None:
            print(f"{name:18} {'—':>5} {LIMITS[name]:>6}  MISSING"); ok = False; continue
        n = len(block)
        lim = LIMITS[name]
        status = "OK" if n <= lim else "OVER"
        if n > lim:
            ok = False
        print(f"{name:18} {n:>5} {lim:>6}  {status}")
    sys.exit(0 if ok else 1)

if __name__ == "__main__":
    main()
