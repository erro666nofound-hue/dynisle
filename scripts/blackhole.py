#!/usr/bin/env python3
"""Draw the fastfetch black hole as coloured ASCII: a dark shadow, a thin
photon ring, the lensed glow wrapped over the top, and the accretion disk
crossing in front - the Interstellar look, in characters (. - = * # %% @).

Brightness picks the character and the colour; the colours come from the
shell's matugen palette (primary for the ring, tertiary for the disk), so the
black hole follows the wallpaper like everything else. With no palette yet
it falls back to gold.

    blackhole.py [out.ansi]      default ~/.config/fastfetch/blackhole.ansi
    PREVIEW=x.png blackhole.py   also save a picture of it (needs Pillow)
"""
import json, math, os, random, sys

COLS, ROWS = 44, 17                # a terminal cell is ~2x taller than wide
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


RING, DISK = palette()
HOT = (255, 250, 242)


def colour(v, disk_share):
    """Brightness 0..1 -> dim, full accent, then white-hot at the core."""
    acc = mix(RING, DISK, disk_share)
    if v < 0.55:
        return mix(mix(acc, (0, 0, 0), 0.7), acc, v / 0.55)
    return mix(acc, HOT, (v - 0.55) / 0.45 * 0.8)


def light(x, y):
    """(brightness, share of it that is disk) at a point; the shadow's
    radius is 1. Brightness -1 means inside the shadow."""
    r = math.hypot(x, y)

    # accretion disk, nearly edge-on: a long flat ellipse through the middle
    d = math.hypot(x, y / 0.13)
    disk = 0.0
    if 1.2 < d < 3.05:
        t = (d - 1.2) / 1.85
        disk = (1 - t) ** 1.3 * (1.05 + 0.4 * (-x / 3.05))   # left side coming at us
    if r < 1.0:
        # only the near half of the disk passes in front of the shadow
        return (min(disk, 1.0), 1.0) if (disk > 0.05 and y > -0.14) else (-1.0, 0.0)

    ring = max(0.0, 1 - abs(r - 1.08) / 0.2) ** 1.1          # photon ring
    f = max(0.0, 1 - (r - 1.0) / 1.05)
    up = max(0.0, -y) / r
    halo = f ** 1.25 * (0.40 + 0.60 * up)                      # lensed far side, over the top
    halo += f ** 2.4 * 0.40 * max(0.0, y) / r                 # and a thin copy underneath
    body = max(ring, halo * 0.95)
    v = max(body, disk)
    return min(v, 1.0), (disk / v if v > 0 else 0.0)


def cell(c, r):
    # 4x4 samples per cell so the ring edge is smooth, not stepped
    lit, share, dark, n = 0.0, 0.0, 0, 0
    for sy in range(4):
        for sx in range(4):
            x = (c + (sx + 0.5) / 4 - COLS / 2) / 7.2
            y = (r + (sy + 0.5) / 4 - ROWS / 2) * 2.05 / 7.2
            v, s = light(x, y)
            n += 1
            if v < 0:
                dark += 1
            else:
                lit += v
                share += s * v
    v = lit / n
    s = share / lit if lit else 0.0
    return v, s, dark / n


def render():
    random.seed(7)                       # the same stars every time
    rows = []
    for r in range(ROWS):
        line = []
        for c in range(COLS):
            v, s, dark = cell(c, r)
            if v < 0.035 or dark > 0.7:
                x = (c - COLS / 2) / 7.2
                y = (r - ROWS / 2) * 2.05 / 7.2
                if dark == 0 and math.hypot(x, y) > 2.1 and random.random() < 0.02:
                    line.append((random.choice(".·+*"), mix((90, 95, 110), RING, 0.3)))
                else:
                    line.append((" ", None))
                continue
            ch = RAMP[min(len(RAMP) - 1, 1 + int(v ** 0.8 * (len(RAMP) - 1)))]
            line.append((ch, colour(v, s)))
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
    font = ImageFont.truetype("/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf", 20)
    cw, chh = 12, 25
    img = Image.new("RGB", (COLS * cw + 40, ROWS * chh + 40), (17, 19, 24))
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
