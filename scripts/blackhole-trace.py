#!/usr/bin/env python3
"""Ray-trace the fastfetch black hole once, into blackhole-map.json.

Not run on install: the map only holds brightness, so it never changes with
the colours - blackhole.py paints it in the current palette in a few ms.
Rerun this only to change the picture itself (takes ~30 s, plain Python).

Model: a Schwarzschild black hole (M = 1, shadow radius 3*sqrt(3)) with a
thin disk from r = 6 to r = R_OUT, seen from INCLINATION degrees off its
axis - just above the disk plane, the Interstellar/Gargantua angle. Each ray
follows the orbit equation u'' = -u + 3u^2 (u = 1/r) in its own plane; the
first time it crosses the disk plane inside the disk, it takes the disk's
light there. That alone draws everything: the flat front of the disk, the
back of the disk bent up over the top and under the bottom, and the thin
photon ring hugging the shadow.
"""
import json, math, os

COLS, ROWS = 50, 16
ASPECT = 2.2                   # a kitty cell is 2.2x taller than wide
SUB = 3                        # SUB x SUB rays per cell
INCLINATION = 84.0             # degrees from the disk's axis; 90 = edge-on
R_IN, R_OUT = 6.0, 14.0
HALF_W = 14.0                  # half the picture's width, in units of M
B_CENTRE = 0.62               # nudge, so the picture sits in the middle
DOPPLER = 1.2                  # the side turning towards us is brighter
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "blackhole-map.json")

i = math.radians(INCLINATION)
C = (0.0, -math.sin(i), math.cos(i))       # towards the camera
X = (1.0, 0.0, 0.0)                        # screen right
Y = (0.0, math.cos(i), math.sin(i))        # screen up


def trace(a, b):
    """Sky offset (a right, b up) -> (intensity, emission radius) or None."""
    imp = math.hypot(a, b)
    if imp < 1e-6:
        return None
    ez = (a * X[2] + b * Y[2]) / imp
    u, w = 1.0 / 1000.0, None
    w = math.sqrt(max(0.0, 1.0 / imp ** 2 - u * u + 2 * u ** 3))
    phi, h = 0.0, 0.01
    s_prev = C[2]
    f = lambda u: -u + 3 * u * u
    while phi < 7 * math.pi:
        # RK4 on (u, w)
        k1u, k1w = w, f(u)
        k2u, k2w = w + h / 2 * k1w, f(u + h / 2 * k1u)
        k3u, k3w = w + h / 2 * k2w, f(u + h / 2 * k2u)
        k4u, k4w = w + h * k3w, f(u + h * k3u)
        u_new = u + h / 6 * (k1u + 2 * k2u + 2 * k3u + k4u)
        w = w + h / 6 * (k1w + 2 * k2w + 2 * k3w + k4w)
        phi += h
        if u_new <= 0:
            return None                          # escaped: black sky
        if u_new >= 0.5:
            return "hole"                        # fell in: the shadow
        s = math.cos(phi) * C[2] + math.sin(phi) * ez
        if (s > 0) != (s_prev > 0):
            # crossed the disk plane between the last step and this one
            t = s_prev / (s_prev - s)
            r = 1.0 / (u + (u_new - u) * t)
            if R_IN <= r <= R_OUT:
                lam = -a * math.sin(i)            # photon's angular momentum
                omega = r ** -1.5
                g = math.sqrt(1 - 3 / r) / (1 - omega * lam)
                edge = min(1.0, (r - R_IN) / 0.7 + 0.35)
                fade = min(1.0, (R_OUT - r) / 3.0)
                return (R_IN / r) ** 2.2 * edge * fade * g ** DOPPLER, r
        s_prev, u = s, u_new
    return None


def main():
    half_h = HALF_W * ROWS * ASPECT / COLS
    vals, temps, rings, holes = [], [], [], []
    B_C = 3 * math.sqrt(3)                  # where the photon ring sits
    for row in range(ROWS):
        vrow, trow, grow, hrow = [], [], [], []
        for col in range(COLS):
            total, rsum, glow, hole, n = 0.0, 0.0, 0.0, 0, 0
            for sy in range(SUB):
                for sx in range(SUB):
                    a = ((col + (sx + 0.5) / SUB) / COLS * 2 - 1) * HALF_W
                    b = (1 - (row + (sy + 0.5) / SUB) / ROWS * 2) * half_h + B_CENTRE
                    hit = trace(a, b)
                    n += 1
                    # light that orbits the hole piles up just outside the
                    # shadow: too thin to catch with 9 rays a cell, so it is
                    # added from its known place, the critical impact parameter
                    glow += math.exp(-((math.hypot(a, b) - B_C) / 0.32) ** 2)
                    if hit == "hole":
                        hole += 1
                    elif hit:
                        total += hit[0]
                        rsum += hit[0] * hit[1]
            vrow.append(total / n)
            grow.append(glow / n)
            hrow.append(round(hole / n, 2))
            trow.append((rsum / total - R_IN) / (R_OUT - R_IN) if total else 0.0)
        vals.append(vrow)
        temps.append(trow)
        rings.append(grow)
        holes.append(hrow)
        print(f"\rrow {row + 1}/{ROWS}", end="", flush=True)
    print()
    # tone-map: the brightest few percent saturate, the rest keeps its shape
    lit = sorted(v for r in vals for v in r if v > 0)
    ref = lit[int(len(lit) * 0.93)] if lit else 1.0
    vals = [[round(max(1 - math.exp(-1.6 * v / ref), 0.85 * g), 3) for v, g in zip(r, gr)]
            for r, gr in zip(vals, rings)]
    temps = [[round(t, 3) for t in r] for r in temps]
    with open(OUT, "w") as fh:
        json.dump({"cols": COLS, "rows": ROWS, "inclination": INCLINATION,
                   "light": vals, "radius": temps, "hole": holes}, fh, separators=(",", ":"))
    print("wrote", OUT)


if __name__ == "__main__":
    main()
