#!/usr/bin/env python3
"""Paint the fastfetch black hole in the shell's current colours.

The picture itself - how bright each terminal cell is, and how far out in
the disk its light came from - is ray-traced once by blackhole-trace.py into
blackhole-map.json. This only picks a character for the brightness
(. ' - : = + * # % @) and a colour for it, from matugen's palette: the hot
inner disk runs towards white, the cool outer disk is the primary colour.
So it takes a few milliseconds and reruns on every recolour.

    blackhole.py [out.ansi]      default ~/.config/fastfetch/blackhole.ansi
    PREVIEW=x.png blackhole.py   also save a picture of it (needs Pillow)
"""
import json, os, random, sys

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.expanduser(sys.argv[1] if len(sys.argv) > 1 else "~/.config/fastfetch/blackhole.ansi")
PALETTE = os.path.expanduser("~/.local/state/quickshell/user/generated/colors.json")
RAMP = " .'-:=+*#%@"


def hex_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def palette():
    try:
        p = json.load(open(PALETTE))
        return hex_rgb(p["primary"]), hex_rgb(p["tertiary"])
    except Exception:
        return (255, 196, 120), (255, 150, 80)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


COOL, WARM = palette()
HOT = (255, 250, 242)


def colour(v, far):
    """v: brightness 0..1; far: 0 = inner edge of the disk, 1 = outer."""
    base = mix(mix(WARM, HOT, 0.55), COOL, far ** 0.7)
    lit = mix(mix(base, (0, 0, 0), 0.72), base, v / 0.6)
    return mix(lit, HOT, (v - 0.8) / 0.2 * 0.6) if v > 0.8 else lit


def render():
    m = json.load(open(os.path.join(HERE, "blackhole-map.json")))
    random.seed(7)                       # the same stars every time
    rows = []
    for light, radius, hole in zip(m["light"], m["radius"], m["hole"]):
        line = []
        for v, far, dark in zip(light, radius, hole):
            if v < 0.04:
                # a few stars - in the sky, never inside the shadow
                if dark == 0 and random.random() < 0.012:
                    line.append((random.choice(".·+*"), mix((90, 95, 110), COOL, 0.3)))
                else:
                    line.append((" ", None))
                continue
            ch = RAMP[min(len(RAMP) - 1, 1 + int(v ** 0.85 * (len(RAMP) - 1)))]
            line.append((ch, colour(v, far)))
        rows.append(line)
    return rows


def ansi(rows):
    out = []
    for line in rows:
        s, last = "", None
        for ch, col in line:
            if col and col != last:
                s += "\033[38;2;%d;%d;%dm" % col
                last = col
            s += ch
        out.append(s.rstrip() + "\033[0m")
    return "\n".join(out) + "\n"


def preview(rows, path):
    from PIL import Image, ImageDraw, ImageFont
    font = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf", 17)
    cw, chh = 10, 22
    img = Image.new("RGB", (len(rows[0]) * cw + 40, len(rows) * chh + 40), (17, 19, 24))
    draw = ImageDraw.Draw(img)
    for r, line in enumerate(rows):
        for c, (ch, col) in enumerate(line):
            if col:
                draw.text((20 + c * cw, 20 + r * chh), ch, font=font, fill=col)
    img.save(path)


if __name__ == "__main__":
    rows = render()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    tmp = OUT + ".tmp"
    with open(tmp, "w") as f:
        f.write(ansi(rows))
    os.replace(tmp, OUT)
    if os.environ.get("PREVIEW"):
        preview(rows, os.environ["PREVIEW"])
