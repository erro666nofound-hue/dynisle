#!/usr/bin/env python3
"""Give every screen the Hyprland scale that matches its real size.

Everything - dynisle, kitty, Chrome, nautilus - is sized in logical pixels,
and Hyprland multiplies those by each monitor's scale. dynisle was made on a
13.3" 1366x768 laptop: 118 pixels per inch, at scale 1. So a screen's scale is
its own pixels-per-inch / 118, and things come out the same physical size on
any screen, whatever its resolution. Screens that are not built in sit
farther away, so they use 110 instead (a 27" 4K monitor gets 1.5).

Writes ~/.config/hypr/monitors.lua (the file nwg-displays also writes, and
that hyprland.lua loads), backing up the old one, then reloads Hyprland.
Also writes ~/.config/hypr/hyprlock/scale.conf: hyprlock does NOT apply the
monitor scale (its sizes are real pixels - read in hyprlock v0.9.6's source),
so the lock screen's clock, date and password box get multiplied here.

    display-scale.py              every connected screen, automatically
    display-scale.py 1.5          this scale on every screen
    display-scale.py --dry-run    print the file instead of writing it
    display-scale.py --if-missing do nothing when monitors.lua exists (install.sh)

The screens come from `hyprctl monitors` when Hyprland is running, otherwise
from the EDID in /sys/class/drm - so install.sh can run it from a text console.
"""
import datetime, glob, json, math, os, shutil, subprocess, sys

MONITORS = os.path.expanduser("~/.config/hypr/monitors.lua")
LOCK = os.path.expanduser("~/.config/hypr/hyprlock/scale.conf")
BASE_BUILT_IN, BASE_EXTERNAL = 118.0, 110.0
BUILT_IN = ("eDP", "LVDS", "DSI")


def from_hyprland():
    if not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") or not shutil.which("hyprctl"):
        return []
    try:
        out = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, timeout=5).stdout
        return [{"name": m["name"], "w": m["width"], "h": m["height"],
                 "mm_w": m.get("physicalWidth", 0), "mm_h": m.get("physicalHeight", 0)}
                for m in json.loads(out)]
    except Exception:
        return []


def from_edid():
    screens = []
    for d in sorted(glob.glob("/sys/class/drm/card*-*")):
        try:
            if open(f"{d}/status").read().strip() != "connected":
                continue
            e = open(f"{d}/edid", "rb").read()
        except OSError:
            continue
        if len(e) < 128 or e[:8] != bytes([0, 255, 255, 255, 255, 255, 255, 0]):
            continue
        t = e[54:72]                                  # first detailed timing = native mode
        screens.append({
            "name": os.path.basename(d).split("-", 1)[1],   # card1-eDP-1 -> eDP-1
            "w": t[2] | ((t[4] & 0xF0) << 4), "h": t[5] | ((t[7] & 0xF0) << 4),
            "mm_w": t[12] | ((t[14] & 0xF0) << 4) or e[21] * 10,
            "mm_h": t[13] | ((t[14] & 0x0F) << 8) or e[22] * 10,
        })
    return screens


def clean(target, w, h):
    """The scale nearest `target` that divides the resolution evenly, in the
    1/120 steps Wayland uses - Hyprland refuses scales that leave a fraction
    of a logical pixel."""
    n0 = round(target * 120)
    for d in range(0, 60):
        for n in (n0 - d, n0 + d):
            if n >= 120 and (w * 120) % n == 0 and (h * 120) % n == 0:
                return n / 120
    return round(target * 4) / 4


def pick(screen):
    w, h, mm_w, mm_h = screen["w"], screen["h"], screen["mm_w"], screen["mm_h"]
    base = BASE_BUILT_IN if screen["name"].startswith(BUILT_IN) else BASE_EXTERNAL
    if mm_w < 100 or mm_h < 50 or not w or not h:
        # no believable size (some projectors and TVs): go by resolution
        dpi = None
        target = 2.0 if w >= 3840 else 1.5 if w >= 2560 else 1.0
    else:
        dpi = math.hypot(w, h) / (math.hypot(mm_w, mm_h) / 25.4)
        target = dpi / base
    return clean(min(max(target, 1.0), 3.0), w, h), dpi


def lock_text(scale):
    """hyprlock.conf's sizes at scale 1, multiplied. hyprlock.conf has the
    same numbers as defaults, so a missing file only means a small lock."""
    n = lambda v: round(v * scale)
    return "\n".join([
        f"# Written by dynisle's fix.sh: the lock screen at scale {scale:g}, because",
        "# hyprlock uses real pixels and ignores the monitor scale. Rerun fix.sh to redo.",
        f"$lock_clock_size = {n(96)}",
        f"$lock_clock_pos = 0, {n(130)}",
        f"$lock_date_size = {n(16)}",
        f"$lock_date_pos = 0, {n(52)}",
        f"$lock_field_size = {n(340)}, {n(58)}",
        f"$lock_field_round = {n(29)}",
        f"$lock_field_pos = 0, {n(-70)}",
        ""])


def write_lock(chosen, dry):
    """One size for the lock on every screen: the built-in one's, else the first."""
    if not chosen:
        return
    name, scale = next((c for c in chosen if c[0].startswith(BUILT_IN)), chosen[0])
    text = lock_text(scale)
    if dry:
        print("\n" + text)
        return
    os.makedirs(os.path.dirname(LOCK), exist_ok=True)
    with open(LOCK + ".tmp", "w") as f:
        f.write(text)
    os.replace(LOCK + ".tmp", LOCK)
    print(f"  wrote {LOCK} (lock screen at scale {scale:g}, from {name})")


def scales_in_monitors_file():
    """(output, scale) pairs from an existing monitors.lua, ours or nwg-displays'."""
    import re
    try:
        text = open(MONITORS).read()
    except OSError:
        return []
    out = []
    for block in re.findall(r"hl\.monitor\(\{(.*?)\}\)", text, re.S):
        name = re.search(r'output\s*=\s*"([^"]*)"', block)
        scale = re.search(r"scale\s*=\s*([0-9.]+)", block)
        if name and scale and name.group(1):
            out.append((name.group(1), float(scale.group(1))))
    return out


def lua(screens, forced):
    now = datetime.date.today().isoformat()
    out = [f"-- Written by dynisle's fix.sh on {now}: each screen's scale comes from its",
           "-- real size, so everything is as big as on the 13.3\" laptop dynisle was made",
           "-- on. Rerun fix.sh after plugging in another screen; nwg-displays may also",
           "-- rewrite this file. Screens not listed here get scale 1.", ""]
    chosen = []
    for s in screens:
        scale, dpi = (forced, None) if forced else pick(s)
        if forced:
            scale = clean(forced, s["w"], s["h"]) if s["w"] and s["h"] else forced
        why = f"{s['w']}x{s['h']}, {s['mm_w']}x{s['mm_h']} mm" + (f", {dpi:.0f} dpi" if dpi else "")
        out += ["hl.monitor({",
                f"    output = \"{s['name']}\",   -- {why}",
                "    mode = \"preferred\",",
                "    position = \"auto\",",
                f"    scale = {scale:.6f}".rstrip("0").rstrip(".") + ",",
                "})", ""]
        print(f"  {s['name']:<10} {why:<40} -> scale {scale:.3f}"
              f"   (looks like {round(s['w'] / scale)}x{round(s['h'] / scale)})")
        if forced and abs(scale - forced) > 0.001:
            print(f"             {forced:g} does not divide {s['w']}x{s['h']} into whole pixels;"
                  f" {scale:.3f} is the nearest that does")
        chosen.append((s["name"], scale))
    return "\n".join(out), chosen


def main():
    args = sys.argv[1:]
    dry, if_missing = "--dry-run" in args, "--if-missing" in args
    numbers = [a for a in args if not a.startswith("--")]
    forced = float(numbers[0]) if numbers else None
    if forced is not None and not 0.5 <= forced <= 4:
        sys.exit("a scale between 0.5 and 4, e.g. 1.25 or 1.5")

    if if_missing and os.path.exists(MONITORS):
        print(f"  {MONITORS} already exists - left alone")
        if not os.path.exists(LOCK):
            write_lock(scales_in_monitors_file() or [("", 1.0)], dry)
        return
    screens = from_hyprland() or from_edid()
    # Hyprland can report 0 mm; the EDID usually still has the size
    edid = {s["name"]: s for s in from_edid()}
    for s in screens:
        if (s["mm_w"] < 100 or s["mm_h"] < 50) and s["name"] in edid:
            s["mm_w"], s["mm_h"] = edid[s["name"]]["mm_w"], edid[s["name"]]["mm_h"]
    if not screens:
        sys.exit("no connected screen found (no Hyprland running and no EDID readable)")

    text, chosen = lua(screens, forced)
    if dry:
        print("\n" + text)
        write_lock(chosen, dry)
        return
    os.makedirs(os.path.dirname(MONITORS), exist_ok=True)
    if os.path.exists(MONITORS):
        backup = MONITORS + ".bak-" + datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
        shutil.copy2(MONITORS, backup)
        print(f"  old file kept as {backup}")
    tmp = MONITORS + ".tmp"
    with open(tmp, "w") as f:
        f.write(text)
    os.replace(tmp, MONITORS)
    print(f"  wrote {MONITORS}")
    write_lock(chosen, dry)
    if os.environ.get("HYPRLAND_INSTANCE_SIGNATURE") and shutil.which("hyprctl"):
        subprocess.run(["hyprctl", "reload"], capture_output=True)
        print("  Hyprland reloaded")


if __name__ == "__main__":
    main()
