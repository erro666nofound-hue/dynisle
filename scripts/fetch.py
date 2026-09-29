#!/usr/bin/env python3
"""The greeting every new terminal prints (hooked from fish/config.fish).

The black hole sits in the middle; hardware on its left, software on its
right, each behind a single edge that faces the hole. fastfetch still finds
the facts (`--format json`, ~10 ms); this only lays them out, because
fastfetch itself can put its logo on one side only.

Narrower windows fall back step by step: the hole on top with the two
columns under it, then just the columns.
"""
import json, os, re, shutil, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.expanduser("~/.config/fastfetch/blackhole.ansi")

grey = lambda v: f"\033[38;2;{v};{v};{v + 6}m"
EDGE, DIM, TEXT, ICON, HEAD = grey(92), grey(128), grey(206), grey(238), "\033[1m" + grey(186)
RESET = "\033[0m"
ANSI = re.compile(r"\033\[[0-9;]*m")


def width(s):
    return len(ANSI.sub("", s))


def facts():
    modules = "host:cpu:gpu:memory:disk:battery:os:kernel:wm:shell:terminal:packages:uptime:title"
    try:
        out = subprocess.run(["fastfetch", "--config", "none", "--format", "json", "-s", modules],
                             capture_output=True, text=True, timeout=3).stdout
        return {m["type"]: m.get("result") for m in json.loads(out)}
    except Exception:
        return {}


def gib(n):
    return f"{n / 2 ** 30:.1f}".rstrip("0").rstrip(".")


def cpu_name(s):
    s = re.sub(r"\((R|TM|tm)\)|\bCPU\b|\bProcessor\b|@.*$|\d+-Core|with Radeon.*$", "", s)
    return " ".join(s.split())


def pct(used, total):
    p = round(100 * used / total) if total else 0
    return f"{p}%", p >= 90


def parent_shell():
    """fastfetch would report THIS script as the shell (it is its parent),
    so ask for the process that started us instead."""
    try:
        name = open(f"/proc/{os.getppid()}/comm").read().strip()
    except OSError:
        return None
    if name not in ("fish", "zsh", "bash", "sh", "dash", "nu", "elvish", "xonsh"):
        return None
    try:
        out = subprocess.run([name, "--version"], capture_output=True, text=True, timeout=1).stdout
        version = re.search(r"\d+(\.\d+)+", out)
    except Exception:
        version = None
    return {"prettyName": name, "version": version.group(0) if version else ""}


def hardware(f):
    rows = []
    host = f.get("Host") or {}
    name = host.get("name") or host.get("family")
    if name and "O.E.M" not in name:
        rows.append(("\U000F0322", name, ""))
    cpu = f.get("CPU") or {}
    if cpu.get("cpu"):
        rows.append(("\U000F0EE0", cpu_name(cpu["cpu"]), ""))
    gpus = f.get("GPU") or []
    if gpus and gpus[0].get("name"):
        rows.append(("\U000F08AE", gpus[0]["name"][:28], ""))
    mem = f.get("Memory") or {}
    if mem.get("total"):
        p, hot = pct(mem["used"], mem["total"])
        rows.append(("\U000F035B", f"{gib(mem['used'])} / {gib(mem['total'])} GiB", p, hot))
    for d in f.get("Disk") or []:
        if d.get("mountpoint") == "/":
            b = d["bytes"]
            p, hot = pct(b["used"], b["total"])
            rows.append(("\U000F02CA", f"{gib(b['used'])} / {gib(b['total'])} GiB", p, hot))
    for bat in (f.get("Battery") or [])[:1]:
        status = ", ".join(bat.get("status") or []).lower().replace("ac connected, ", "")
        rows.append(("\U000F0079", f"{round(bat.get('capacity', 0))}%", status))
    return rows


def software(f):
    rows = []
    os_ = f.get("OS") or {}
    if os_:
        rows.append(("\U000F08C7", os_.get("prettyName") or os_.get("name", ""), ""))
    kernel = f.get("Kernel") or {}
    if kernel:
        rows.append(("\U000F033D", kernel.get("release", ""), ""))
    f["Shell"] = parent_shell() or f.get("Shell")
    for key, icon in (("WM", "\U000F056E"), ("Shell", "\U000F018D"), ("Terminal", "\U000F07B7")):
        m = f.get(key) or {}
        if m.get("prettyName"):
            rows.append((icon, f"{m['prettyName']} {m.get('version', '')}".strip(), ""))
    pk = f.get("Packages") or {}
    if pk.get("all"):
        rows.append(("\U000F03D6", str(pk["all"]), "packages"))
    return rows


def cell(value, note, hot=False):
    tail = f"  {('\033[38;2;255;138;128m' if hot else DIM)}{note}" if note else ""
    return f"{TEXT}{value}{tail}"


def left_block(title, rows):
    """Right-aligned rows, the edge on their right - it faces the hole."""
    body = [(cell(r[1], r[2], r[3] if len(r) > 3 else False), r[0]) for r in rows]
    w = max([width(b) for b, _ in body] + [len(title) + 2])
    lines = [f"{EDGE}{'─' * (w + 2 - len(title))} {HEAD}{title}{RESET}{EDGE} ─╮"]
    for n, (b, icon) in enumerate(body):
        edge = "╯" if n == len(body) - 1 else "│"
        lines.append(" " * (w - width(b)) + f"{b}  {ICON}{icon}  {EDGE}{edge}")
    return lines


def right_block(title, rows):
    """Left-aligned rows, the edge on their left."""
    body = [(cell(r[1], r[2]), r[0]) for r in rows]
    w = max([width(b) for b, _ in body] + [len(title) + 2])
    lines = [f"{EDGE}╭─ {HEAD}{title}{RESET}{EDGE} {'─' * (w + 2 - len(title))}"]
    for n, (b, icon) in enumerate(body):
        edge = "╰" if n == len(body) - 1 else "│"
        lines.append(f"{EDGE}{edge}  {ICON}{icon}  {b}")
    return lines


def pad(lines, w):
    """Every line exactly w columns wide, so columns can sit side by side."""
    return [l + RESET + " " * max(0, w - width(l)) for l in lines]


def beside(blocks, gap):
    """Blocks side by side, each vertically centred on the tallest."""
    tall = max(len(b) for b, _ in blocks)
    cols = []
    for lines, w in blocks:
        top = (tall - len(lines)) // 2
        cols.append([" " * w] * top + pad(lines, w) + [" " * w] * (tall - top - len(lines)))
    return [(" " * gap).join(parts) for parts in zip(*cols)]


def uptime(ms):
    m = ms // 60000
    d, h, mi = m // 1440, m // 60 % 24, m % 60
    return " ".join(p for p in (f"{d}d" if d else "", f"{h}h" if h else "", f"{mi}m") if p)


def main():
    f = facts()
    try:
        art = open(ART).read().rstrip("\n").split("\n")
    except OSError:
        art = []
    art_w = max((width(l) for l in art), default=0)
    left = left_block("HARDWARE", hardware(f))
    right = right_block("SOFTWARE", software(f))
    lw, rw = max(map(width, left)), max(map(width, right))
    cols = shutil.get_terminal_size((120, 40)).columns

    if art and cols >= lw + rw + art_w + 6:
        body = beside([(left, lw), (art, art_w), (right, rw)], 3)
    elif art and cols >= max(art_w, lw + rw + 4):
        body = [l + RESET for l in art] + [""] + beside([(left, lw), (right, rw)], 4)
    else:
        body = left + [""] + right

    t = f.get("Title") or {}
    up = (f.get("Uptime") or {}).get("uptime")
    footer = [f"\033[1m{grey(230)}{t.get('userName', '')}{RESET}{EDGE} @ \033[1m{grey(230)}{t.get('hostName', '')}"
              + (f"{RESET}{EDGE}  ·  {DIM}up {uptime(up)}" if up else ""),
              " ".join(f"\033[{c}m●" for c in range(30, 38))]

    block_w = max(width(l) for l in body)
    indent = " " * max(0, (cols - block_w) // 2)
    out = ["", *(indent + l.rstrip() + RESET for l in body), ""]
    for l in footer:
        out.append(" " * max(0, (cols - width(l)) // 2) + l + RESET)
    sys.stdout.write("\n".join(out) + "\n\n")


if __name__ == "__main__":
    main()
