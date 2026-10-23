"""wallgen -- calm, procedurally generated wallpapers at native resolution.

One landscape per day (seeded by the date), relit for each phase of the day:
dawn, day, dusk, night. The phase follows the real sun at the configured
location, so the light changes when it does outside -- late and briefly in a
Danish December, early and long in June. The generated image is handed to
DMS, which reruns matugen, so the desktop palette follows the light a few
times a day instead of jumping between unrelated pictures.

Variety comes from the day's recipe: drawing style (painted landscape or one
of several technical styles), scene type, season (from the date), weather, a
palette variant per phase, sun placement, birds, aurora, and the actual phase
of the moon.

Packaged and scheduled by modules/nixos/wallgen.nix, which substitutes the
location below.
"""

import argparse
import colorsys
import datetime as dt
import math
import os
import shutil
import subprocess
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

# "LAT LON" in degrees (east positive) -- replaced at build time by
# modules/nixos/wallgen.nix. The fallback is Copenhagen.
LOCATION = "@location@"
DEFAULT_LOCATION = "55.676 12.568"

WIDTH, HEIGHT = 5120, 2160
OUT_DIR = Path.home() / "Pictures/Wallpapers/generated"
KEEP_DIR = Path.home() / "Pictures/Wallpapers/highres"
STATE_DIR = Path(os.environ.get("XDG_STATE_HOME",
                                Path.home() / ".local/state")) / "wallgen"
STATE = STATE_DIR / "applied"        # the phase slot last handled
HISTORY = STATE_DIR / "history"      # applied image paths, newest last
HISTORY_LEN = 50
KEEP_DAYS = 7

# DMS's light/dark state. Settings -> Theme -> Theme schedule "Wallpaper" is
# matugenSmartMode: DMS picks light or dark from the image, so wallgen draws
# the natural light. Any other schedule (Manual, Schedule, Location) means DMS
# decides, and wallgen tones the picture to match the mode DMS is in.
# `wallgen mode` switches between the three in one step.
TONES = ("natural", "dark", "light")
MODES = {"auto": "natural", "dark": "dark", "light": "light"}

# Sun elevation (degrees) where night ends / day begins. Below -6 is past
# civil twilight; above 6 the light has lost its warm low-sun colour. A
# Copenhagen winter noon barely reaches 11, so "day" there is a few hours.
NIGHT_BELOW, DAY_ABOVE = -6.0, 6.0

SCENES = {"ridges": 0.17, "forest": 0.17, "lake": 0.17, "hills": 0.14,
          "sea": 0.12, "archipelago": 0.13, "dunes": 0.10}
# About a third of days get a technical drawing style instead of a painted
# landscape. lowpoly and wireframe still use the landscape's sky; the rest
# draw on a full-frame sky gradient. All of them keep the phase palette, so
# matugen still follows the light.
STYLES = {"landscape": 0.64, "contour": 0.05, "signal": 0.05,
          "circuit": 0.05, "wireframe": 0.05, "lowpoly": 0.06, "flow": 0.05,
          "graph": 0.05}
WEATHER = {"clear": 0.25, "wisps": 0.35, "banks": 0.25, "overcast": 0.15}
SEASONS = ("spring", "summer", "autumn", "winter")
PHASES = ("dawn", "day", "dusk", "night")


# --- palettes ---------------------------------------------------------------
# Muted on purpose: matugen pulls its accent from the image, and a saturated
# wallpaper drags the whole desktop with it (see the scheme note in dms.nix).
# Each phase has variants; the day's recipe picks one per phase.
#   sky:   (position, colour) stops from the top of the frame to the horizon
#   light: far -> near land tones under this light; blended with the season
#          (LIGHT_MIX says how much the light wins over the season's colours)

def hexrgb(h):
    return np.array([int(h[i:i + 2], 16) / 255 for i in (1, 3, 5)],
                    dtype=np.float32)


PALETTES = {
    "dawn": [
        {"name": "rose",
         "sky": [(0.0, "#3b4a6b"), (0.45, "#9a8aa8"), (0.8, "#e3b4a4"),
                 (1.0, "#f2d0b0")],
         "sun": "#fff0d8", "glow": "#f6c9a0", "haze": "#e6c2b4",
         "light": ["#b49aa8", "#8c7896", "#665a7c", "#463f5c", "#2c2a40"],
         "water": "#4a4a66", "sand": "#c9a48e", "shadow": "#5a4a62"},
        {"name": "golden",
         "sky": [(0.0, "#4a5878"), (0.45, "#a8a0a0"), (0.8, "#f0c890"),
                 (1.0, "#fbe3b0")],
         "sun": "#fff4dc", "glow": "#ffd79a", "haze": "#efd6b4",
         "light": ["#b8a48c", "#90806e", "#6c5e56", "#4c4240", "#30282c"],
         "water": "#5a5a6a", "sand": "#d8b48c", "shadow": "#6a5048"},
        {"name": "mist",
         "sky": [(0.0, "#46586e"), (0.45, "#8ea0b0"), (0.8, "#c8cfd2"),
                 (1.0, "#e8dcd0")],
         "sun": "#fff6ea", "glow": "#f4e6d4", "haze": "#d6dadb",
         "light": ["#a4aeb8", "#84909c", "#667280", "#4a5462", "#323a46"],
         "water": "#56626e", "sand": "#c4bcb0", "shadow": "#6a6e78"},
    ],
    "day": [
        {"name": "clear",
         "sky": [(0.0, "#5f88b0"), (0.5, "#93b4cc"), (1.0, "#d8e2e0")],
         "sun": "#fffbf0", "glow": "#eef0e6", "haze": "#d4dfde",
         "light": ["#a9bcc4", "#8aa3a6", "#6c8a84", "#536f66", "#3c544c"],
         "water": "#4f7488", "sand": "#d9c7a6", "shadow": "#9a876c"},
        {"name": "hazy",
         "sky": [(0.0, "#7aa0c4"), (0.5, "#b0c8d8"), (1.0, "#ece8dc")],
         "sun": "#fffbf0", "glow": "#fbf6e8", "haze": "#e6e6dc",
         "light": ["#b8c4bc", "#98aa9e", "#7a8e80", "#5e7264", "#44564a"],
         "water": "#5e8a9a", "sand": "#e2d0ac", "shadow": "#a8926c"},
        {"name": "crisp",
         "sky": [(0.0, "#3c6c9c"), (0.5, "#6c9cc4"), (1.0, "#c4d8e4")],
         "sun": "#ffffff", "glow": "#e8f0f4", "haze": "#c4d6e0",
         "light": ["#94aabc", "#72909e", "#56747e", "#3e5a62", "#2a4048"],
         "water": "#3a6480", "sand": "#d0c09c", "shadow": "#8a7a60"},
    ],
    "dusk": [
        {"name": "amber",
         "sky": [(0.0, "#2a2a52"), (0.4, "#6c4a78"), (0.75, "#c46e72"),
                 (1.0, "#eea56a")],
         "sun": "#ffe2b0", "glow": "#f08a5a", "haze": "#d88a7a",
         "light": ["#a8667a", "#7c4a6a", "#583a5c", "#3a2a48", "#221c32"],
         "water": "#3a2c4c", "sand": "#b97a66", "shadow": "#4a2e48"},
        {"name": "crimson",
         "sky": [(0.0, "#1e1e3c"), (0.4, "#4a2a50"), (0.75, "#a43c4c"),
                 (1.0, "#e8704c")],
         "sun": "#ffd8a0", "glow": "#f06440", "haze": "#c86a5c",
         "light": ["#94566a", "#6c3c58", "#4c2c48", "#321e36", "#1c1424"],
         "water": "#2e2036", "sand": "#a8604e", "shadow": "#3c2234"},
        {"name": "lavender",
         "sky": [(0.0, "#3c4470"), (0.4, "#7c74a0"), (0.75, "#c898b0"),
                 (1.0, "#f0c4b0")],
         "sun": "#fff0dc", "glow": "#f4b8a0", "haze": "#d4a8b4",
         "light": ["#a88aa4", "#846c8c", "#625470", "#443c54", "#2c283a"],
         "water": "#4a4262", "sand": "#c09ca0", "shadow": "#584660"},
    ],
    "night": [
        {"name": "navy",
         "sky": [(0.0, "#070b18"), (0.55, "#101c34"), (1.0, "#1f3448")],
         "sun": "#e8eef4", "glow": "#3c5470", "haze": "#2a4054",
         "light": ["#24364a", "#1c2c3e", "#152232", "#0f1926", "#0a111c"],
         "water": "#0c1624", "sand": "#2c3444", "shadow": "#121826"},
        {"name": "teal",
         "sky": [(0.0, "#040e14"), (0.55, "#0a2028"), (1.0, "#163a40")],
         "sun": "#e4f0ec", "glow": "#2c5450", "haze": "#1e3c40",
         "light": ["#1c3a3c", "#162e32", "#112428", "#0c1a1e", "#081216"],
         "water": "#081a1e", "sand": "#24363a", "shadow": "#0e1a1c"},
        {"name": "violet",
         "sky": [(0.0, "#0a0816"), (0.55, "#181430"), (1.0, "#2c2644")],
         "sun": "#ece8f4", "glow": "#4a4068", "haze": "#2c2846",
         "light": ["#26243e", "#1e1c34", "#17152a", "#100e20", "#0a0916"],
         "water": "#0e0c1c", "sand": "#2e2a40", "shadow": "#141224"},
    ],
}

# Land tones in plain daylight, far -> near.
SEASON_LAND = {
    "spring": ["#b4c8b4", "#94b094", "#729676", "#567a5a", "#3c5e42"],
    "summer": ["#a4bcac", "#82a08a", "#62846a", "#466850", "#2e4c38"],
    "autumn": ["#c4b4a0", "#ac9070", "#93704e", "#74523a", "#523628"],
    "winter": ["#c4ccd6", "#a4aebc", "#84909e", "#647080", "#465262"],
}
LIGHT_MIX = {"dawn": 0.6, "day": 0.25, "dusk": 0.65, "night": 0.85}

# Where the sun (moon at night) sits: y as a fraction of the horizon height,
# x drawn from a range so it is not always in the same spot.
SUN = {
    "dawn": {"y": (0.80, 0.92), "x": (0.10, 0.42), "size": 0.020,
             "glow": 0.30},
    "day": {"y": (0.12, 0.30), "x": (0.25, 0.80), "size": 0.0,
            "glow": 0.35},
    "dusk": {"y": (0.84, 0.94), "x": (0.58, 0.90), "size": 0.026,
             "glow": 0.34},
    "night": {"y": (0.12, 0.40), "x": (0.15, 0.85), "size": 0.014,
              "glow": 0.22},
}


def shift_hue(rgb, shift):
    h, lum, s = colorsys.rgb_to_hls(*rgb)
    return np.array(colorsys.hls_to_rgb((h + shift) % 1.0, lum, s),
                    dtype=np.float32)


def lerp(a, b, t):
    return a + (b - a) * t


# Tone: how far a phase is pulled toward the mode DMS is in -- dark mode
# blends a bright phase toward that day's night palette, light mode a dark
# phase toward its day palette. Blending between designed palettes (rather
# than scaling lightness) keeps the colours clean: a dimmed pale sky turns
# murky olive, a blended one turns blue-hour.
TONE_PULL = {"dark": ("night", {"dawn": 0.5, "day": 0.62, "dusk": 0.35}),
             "light": ("day", {"dawn": 0.3, "dusk": 0.45, "night": 0.58})}


def apply_tone(pal, phase, recipe):
    tone = recipe.get("tone", "natural")
    if tone not in TONE_PULL or phase not in TONE_PULL[tone][1]:
        return
    target_phase, pull = TONE_PULL[tone]
    t = pull[phase]
    target = palette(target_phase, {**recipe, "tone": "natural",
                                    "events": ()})
    pos = [s[0] for s in pal["sky"]]
    goal = gradient(target["sky"], np.array(pos, np.float32))
    pal["sky"] = [(p, lerp(c, goal[i], t))
                  for i, (p, c) in enumerate(pal["sky"])]
    pal["land"] = [lerp(a, b, t) for a, b in zip(pal["land"], target["land"])]
    for key in ("glow", "haze", "water", "sand", "shadow"):
        pal[key] = lerp(pal[key], target[key], t)
    if pal["snow"] is not None:
        pal["snow"] = lerp(pal["snow"], target["snow"], t)


def dms_tone():
    """'natural' while DMS takes its mode from the wallpaper, otherwise the
    mode DMS is in right now. Asked over IPC rather than read from DMS's
    files, which lag a mode switch; no answer (DMS down) means natural."""
    if dms("settings", "get", "matugenSmartMode") != "false":
        return "natural"
    mode = dms("theme", "getMode")
    return mode if mode in ("dark", "light") else "natural"


def palette(phase, recipe):
    v = PALETTES[phase][recipe["variant"][phase]]
    hue = recipe["hue"]
    c = lambda h: shift_hue(hexrgb(h), hue)  # noqa: E731
    k = LIGHT_MIX[phase]
    season = SEASON_LAND[recipe["season"]]
    pal = {
        "sky": [(t, c(h)) for t, h in v["sky"]],
        "land": [lerp(hexrgb(s), c(li), k)
                 for s, li in zip(season, v["light"])],
        **{key: c(v[key]) for key in ("sun", "glow", "haze", "water", "sand",
                                      "shadow")},
        "name": v["name"],
    }
    pal["snow"] = (lerp(np.array([0.95, 0.96, 0.98], np.float32),
                        pal["haze"], k * 0.55)
                   if recipe["season"] == "winter" else None)
    s = SUN[phase]
    pal["sun_pos"] = recipe["sun"][phase]
    pal["sun_size"], pal["glow_size"] = s["size"], s["glow"]

    weather = recipe["weather"]
    pal["weather"] = weather
    pal["mist"] = 1.7 if weather == "overcast" else 1.0
    if weather == "overcast":
        # Flat light: pull everything toward its own grey and hide the disc.
        for key in ("glow", "haze", "sun"):
            pal[key] = lerp(pal[key], pal[key].mean(), 0.45)
        pal["sky"] = [(t, lerp(col, col.mean(), 0.5)) for t, col in pal["sky"]]
        pal["land"] = [lerp(col, col.mean(), 0.3) for col in pal["land"]]
        if phase != "night":
            pal["sun_size"] = 0.0
        pal["glow_size"] *= 1.4
    apply_tone(pal, phase, recipe)
    if "halloween" in recipe.get("events", ()) and phase in ("dusk", "night"):
        # A big, low amber hunter's moon.
        pal["sun"] = hexrgb("#f4c27a")
        pal["glow"] = lerp(pal["glow"], hexrgb("#d08040"), 0.5)
        pal["sun_size"], pal["glow_size"] = 0.045, 0.30
        pal["sun_pos"] = (pal["sun_pos"][0], 0.78)
    return pal


# --- sun, moon and phase ------------------------------------------------------

def location():
    spec = DEFAULT_LOCATION if LOCATION.startswith("@") else LOCATION
    lat, lon = (float(x) for x in spec.split())
    return lat, lon


def solar(when):
    """(elevation, hour angle) in degrees for an aware datetime.

    NOAA's low-precision formulae -- good to a fraction of a degree, which is
    far more than a phase boundary needs.
    """
    lat, lon = location()
    t = when.astimezone(dt.timezone.utc)
    hour = t.hour + t.minute / 60 + t.second / 3600
    g = 2 * math.pi / 365 * (t.timetuple().tm_yday - 1 + (hour - 12) / 24)
    eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(g)
                       - 0.032077 * math.sin(g) - 0.014615 * math.cos(2 * g)
                       - 0.040849 * math.sin(2 * g))
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g)
            - 0.006758 * math.cos(2 * g) + 0.000907 * math.sin(2 * g)
            - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g))
    ha = ((hour * 60 + eqtime + 4 * lon) / 4 - 180 + 180) % 360 - 180
    la = math.radians(lat)
    cos_zen = (math.sin(la) * math.sin(decl)
               + math.cos(la) * math.cos(decl) * math.cos(math.radians(ha)))
    elev = 90 - math.degrees(math.acos(max(-1.0, min(1.0, cos_zen))))
    return elev, ha


def phase_at(when):
    elev, ha = solar(when)
    if elev < NIGHT_BELOW:
        return "night"
    if elev >= DAY_ABOVE:
        return "day"
    return "dawn" if ha < 0 else "dusk"


def moon_age(when):
    """Fraction of the synodic month: 0 new, 0.5 full."""
    ref = dt.datetime(2000, 1, 6, 18, 14, tzinfo=dt.timezone.utc)
    days = (when - ref).total_seconds() / 86400
    return (days % 29.530589) / 29.530589


def season_of(day):
    return SEASONS[((day.month - 3) % 12) // 3]


# --- noise --------------------------------------------------------------------

def noise2d(rng, w, h, cells_x, cells_y):
    """Smooth value noise in [0, 1]: a small random grid, bicubic upscaled."""
    grid = rng.random((cells_y + 3, cells_x + 3)).astype(np.float32)
    img = Image.fromarray(grid)
    # Crop the outer cells so the image edges are not pinned to grid points.
    sx, sy = w / cells_x, h / cells_y
    big = img.resize((int((cells_x + 3) * sx), int((cells_y + 3) * sy)),
                     Image.BICUBIC)
    a = np.asarray(big)[int(sy):int(sy) + h, int(sx):int(sx) + w]
    return np.clip(a, 0.0, 1.0)


def fbm2d(rng, w, h, cells_x, cells_y, octaves=4):
    total = np.zeros((h, w), np.float32)
    amp, norm = 1.0, 0.0
    for i in range(octaves):
        total += amp * noise2d(rng, w, h, cells_x * 2 ** i, cells_y * 2 ** i)
        norm += amp
        amp *= 0.5
    return total / norm


def fbm1d(rng, n, cells, octaves=6, gain=0.5):
    """1D fractal value noise in roughly [0, 1], smoothstep-interpolated."""
    x = np.linspace(0.0, 1.0, n, dtype=np.float32)
    total = np.zeros(n, np.float32)
    amp, norm = 1.0, 0.0
    for i in range(octaves):
        k = cells * 2 ** i
        pts = rng.random(k + 2).astype(np.float32)
        u = x * k
        i0 = np.floor(u).astype(int)
        f = u - i0
        f = f * f * (3 - 2 * f)
        total += amp * (pts[i0] * (1 - f) + pts[i0 + 1] * f)
        norm += amp
        amp *= gain
    return total / norm


# --- compositing helpers ------------------------------------------------------

def rows(h):
    return np.arange(h, dtype=np.float32)[:, None]


def mix(dst, colour, alpha):
    """Blend a flat colour into dst (h, w, 3) through alpha (h, w)."""
    dst += (colour[None, None, :] - dst) * alpha[..., None]


def below(curve, ys):
    """Antialiased mask: 1 below the curve (screen y grows downward)."""
    return np.clip(ys - curve[None, :] + 0.5, 0.0, 1.0)


def gradient(stops, t):
    out = np.empty(t.shape + (3,), np.float32)
    pos = [s[0] for s in stops]
    for ch in range(3):
        out[..., ch] = np.interp(t, pos, [s[1][ch] for s in stops])
    return out


def land_colour(pal, depth, haze=0.4):
    land = pal["land"]
    col = land[round(depth * (len(land) - 1))]
    return lerp(col, pal["haze"], haze * (1 - depth) ** 1.5)


def treeline(rng, curve, height, gaps=0.06):
    """Conifer silhouettes standing on a ridge curve; returns the new top."""
    w = curve.shape[0]
    top = curve.copy()
    idx = np.arange(w, dtype=np.float32)
    x = rng.random() * height
    while x < w:
        hw = height * (0.16 + 0.10 * rng.random())
        ht = height * (0.55 + 0.6 * rng.random())
        lo, hi = max(int(x - hw), 0), min(int(x + hw) + 2, w)
        t = np.abs(idx[lo:hi] - x) / hw
        # Spire with a few tiers, so it reads as a spruce rather than a spike.
        prof = ht * np.clip(1 - t, 0, 1) * (0.88 + 0.12 * np.cos(t * 18))
        top[lo:hi] = np.minimum(top[lo:hi], curve[lo:hi] - prof)
        x += hw * (0.6 + 1.1 * rng.random())
        if rng.random() < gaps:
            x += height * (2 + 8 * rng.random())          # a clearing
    return top


def blobs(rng, curve, height, count):
    """Rounded deciduous trees along a curve; returns the new top."""
    w = curve.shape[0]
    top = curve.copy()
    idx = np.arange(w, dtype=np.float32)
    for _ in range(count):
        cx = rng.random() * w
        for _ in range(int(rng.integers(1, 5))):            # small clumps
            r = height * (0.3 + 0.4 * rng.random())
            x0 = cx + (rng.random() - 0.5) * height * 2.5
            lo, hi = max(int(x0 - r), 0), min(int(x0 + r) + 2, w)
            if lo >= hi:
                continue
            base = curve[min(max(int(x0), 0), w - 1)]
            dx = idx[lo:hi] - x0
            cap = np.sqrt(np.clip(r * r - dx * dx, 0, None))
            top[lo:hi] = np.minimum(top[lo:hi], base - r * 0.9 - cap)
            # Trunk keeps the crown attached to the ground.
            tlo, thi = max(int(x0 - r * 0.08), 0), min(int(x0 + r * 0.08) + 1, w)
            top[tlo:thi] = np.minimum(top[tlo:thi], base - r)
    return top


def snowcaps(img, rng, pal, curve, base, ys, h, strength):
    # Only the top of this ridge's own profile holds snow, so caps sit on
    # the summits instead of rimming every crest.
    height = base - curve
    line = np.quantile(height, 0.6)
    peak = np.clip((height - line) / max(height.max() - line, 1.0), 0, 1)
    jag = 0.4 + 0.6 * fbm1d(rng, curve.shape[0], 90, octaves=4)
    depth = h * 0.07 * peak ** 0.7 * jag
    under = ys - curve[None, :]
    cap = np.clip(1 - under / np.maximum(depth, 1e-3)[None, :], 0, 1)
    cap *= (under >= 0) * (peak[None, :] > 0.02)
    mix(img, pal["snow"], cap * strength)


def reflect(img, rng, pal, w, h, line, calm=0.25, darken=0.65):
    """Mirror everything above `line` into water below it."""
    ys = rows(h)
    water = ys >= line
    src = np.clip(2 * line - np.arange(h), 0, h - 1).astype(int)
    ripple = fbm2d(rng, w, h, 2, 80, octaves=3)
    depth_t = np.clip((ys - line) / max(h - line, 1), 0.0, 1.0)
    refl = img[src] * ((1 - calm * 0.6) + calm * ripple[..., None])
    wcol = refl * (1 - depth_t[..., None] * darken) \
        + pal["water"][None, None, :] * depth_t[..., None] * darken
    img[:] = np.where(water[..., None], wcol, img)
    return depth_t, water


# --- sky layers ---------------------------------------------------------------

def sky(pal, w, h, horizon):
    t = np.clip(np.arange(h, dtype=np.float32) / horizon, 0.0, 1.0)
    return np.broadcast_to(gradient(pal["sky"], t)[:, None, :],
                           (h, w, 3)).copy()


def sun(img, pal, w, h, horizon, moon=None):
    sx, sy = pal["sun_pos"]
    cx, cy = sx * w, sy * horizon
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    lit = 1.0 if moon is None else (1 - math.cos(2 * math.pi * moon)) / 2
    d = np.hypot((xs - cx) / 1.7, ys - cy) / h
    mix(img, pal["glow"], np.exp(-(d / pal["glow_size"]) ** 2)
        * 0.5 * (0.3 + 0.7 * lit))
    r = pal["sun_size"] * h
    if r <= 0 or lit < 0.05:
        return
    disc = np.clip(r - np.hypot(xs - cx, ys - cy) + 0.5, 0.0, 1.0)
    disc *= np.clip((horizon - ys) / 2.0, 0.0, 1.0)  # set behind horizon
    if moon is not None:
        # Waxing is lit on the right (northern hemisphere): shadow disc slides
        # off to the left as the moon fills.
        off = 2 * r * lit * (-1 if moon < 0.5 else 1)
        shadow = np.clip(r - np.hypot(xs - cx - off, ys - cy) + 0.5, 0, 1)
        disc = disc * (1 - shadow) + disc * shadow * 0.07   # earthshine
    mix(img, pal["sun"], disc * 0.95)


def clouds(img, rng, pal, w, h, horizon):
    ys = rows(h)
    style = pal["weather"]
    if style == "clear":
        return
    if style == "wisps":
        n = fbm2d(rng, w, h, 3, 9, octaves=5)
        band = np.exp(-((ys / horizon - 0.55) / 0.28) ** 2)
        a = np.clip((n - 0.52) * 3.0, 0.0, 1.0) * band * 0.4
        col = pal["haze"]
    elif style == "banks":
        n = fbm2d(rng, w, h, 5, 4, octaves=6)
        band = np.exp(-((ys / horizon - 0.45) / 0.35) ** 2)
        a = np.clip((n - 0.5) * 2.4, 0.0, 1.0) * band * 0.6
        col = lerp(pal["haze"], pal["glow"], 0.4)
    else:                                                   # overcast
        a = 0.35 + 0.35 * fbm2d(rng, w, h, 4, 6, octaves=5)
        col = pal["haze"]
    mix(img, col, a * np.clip((horizon - ys) / (h * 0.02), 0, 1))


def stars(img, rng, w, h, horizon, amount):
    count = int(2600 * amount)
    xs = rng.integers(0, w, count)
    ys = (rng.random(count) ** 1.6 * horizon * 0.9).astype(int)
    layer = np.zeros((h, w), np.uint8)
    layer[ys, xs] = (rng.random(count) ** 3 * 0.9 + 0.1) * 255
    blurred = Image.fromarray(layer).filter(ImageFilter.GaussianBlur(1.1))
    a = np.clip(np.asarray(blurred, np.float32) / 255 * 3.0, 0.0, 1.0)
    fade = np.clip(1.0 - np.arange(h)[:, None] / horizon, 0.0, 1.0) ** 0.5
    mix(img, np.array([0.92, 0.94, 1.0], np.float32), a * fade)


def aurora(img, rng, w, h, horizon):
    ys = rows(h)
    for _ in range(1 + int(rng.random() < 0.35)):
        base = (0.55 + 0.2 * rng.random()) * horizon
        curve = base + (fbm1d(rng, w, 2, octaves=5) - 0.5) * horizon * 0.6
        height = (0.20 + 0.15 * rng.random()) * horizon
        above = curve[None, :] - ys
        # Bright at the lower edge, fading upward; soft cut-off below.
        a = np.where(above > 0, np.exp(-above / height),
                     np.exp(above / (height * 0.15)))
        rays = 0.6 + 0.4 * fbm1d(rng, w, 120, octaves=3)
        presence = np.clip((fbm1d(rng, w, 2, octaves=3) - 0.3) * 2.2, 0, 1)
        a = a * (rays * presence)[None, :] * (0.4 + 0.25 * rng.random())
        t = np.clip(above / (height * 2.5), 0.0, 1.0)
        low = np.array([0.42, 0.80, 0.66], np.float32)
        high = np.array([0.52, 0.44, 0.78], np.float32)
        col = low[None, None, :] * (1 - t[..., None]) + high * t[..., None]
        img += (col - img) * (a[..., None] * (ys < horizon)[..., None])


def birds(img, rng, pal, w, h, horizon):
    """A small, distant flock -- drawn as a mask at 2x and downsampled."""
    s = 2
    mask = Image.new("L", (w * s // 4, h * s // 4))   # flock lives in a tile
    draw = ImageDraw.Draw(mask)
    tw, th = mask.size
    for _ in range(int(rng.integers(4, 13))):
        size = h * s * (0.004 + 0.006 * rng.random())
        x = tw * (0.2 + 0.6 * rng.random())
        y = th * (0.25 + 0.5 * rng.random())
        flap = 0.2 + 0.5 * rng.random()
        pts = [(x - size, y - size * flap), (x - size * 0.45,
               y - size * (flap + 0.25)), (x, y), (x + size * 0.45,
               y - size * (flap + 0.25)), (x + size, y - size * flap)]
        draw.line(pts, fill=255, width=max(2, int(size * 0.14)),
                  joint="curve")
    tile = np.asarray(mask.resize((w // 4, h // 4), Image.LANCZOS),
                      np.float32) / 255
    ox = int(w * (0.1 + 0.55 * rng.random()))
    oy = int(horizon * (0.15 + 0.35 * rng.random()))
    full = np.zeros((h, w), np.float32)
    ph, pw = min(tile.shape[0], h - oy), min(tile.shape[1], w - ox)
    full[oy:oy + ph, ox:ox + pw] = tile[:ph, :pw]
    mix(img, lerp(pal["land"][-1], pal["haze"], 0.25), full * 0.85)


def mist(img, pal, rng, w, h, y, spread, amount):
    band = np.exp(-((rows(h) - y) / spread) ** 2)
    var = 0.6 + 0.4 * fbm2d(rng, w, h, 4, 3, octaves=3)
    mix(img, pal["haze"], band * var * min(amount * pal["mist"], 0.9))


# --- scenes -----------------------------------------------------------------

def scene_ridges(img, rng, pal, w, h, horizon, trees=False, floor=None):
    """Layered mountains. `floor` limits how far down the nearest layer sits
    (the lake scene puts water under them)."""
    ys = rows(h)
    floor = h if floor is None else floor
    layers = int(rng.integers(4, 7)) if floor == h else int(rng.integers(3, 5))
    for i in range(layers):
        depth = i / (layers - 1)                # 0 far .. 1 near
        base = horizon + (floor - horizon) * depth ** 1.3 * 0.85 - h * 0.04
        amp = h * (0.06 + 0.16 * depth) * (0.7 + 0.6 * rng.random())
        if floor != h:
            amp *= 1.3
        cells = int(rng.integers(2, 5)) + i
        curve = base - fbm1d(rng, w, cells, octaves=7, gain=0.48) * amp
        top = curve
        if trees and depth > 0.2:
            top = treeline(rng, curve, h * (0.008 + 0.045 * depth ** 1.5))
        mix(img, land_colour(pal, depth), below(top, ys))
        if pal["snow"] is not None:
            snowcaps(img, rng, pal, curve, base, ys, h, 0.3 + 0.6 * depth)
        if i < layers - 1:
            mist(img, pal, rng, w, h, base + h * 0.06, h * 0.05,
                 0.45 * (1 - depth * 0.6))


def scene_forest(img, rng, pal, w, h, horizon):
    scene_ridges(img, rng, pal, w, h, horizon, trees=True)


def scene_lake(img, rng, pal, w, h, horizon):
    ys = rows(h)
    shore = horizon + (h - horizon) * (0.28 + 0.18 * rng.random())
    scene_ridges(img, rng, pal, w, h, horizon, trees=rng.random() < 0.5,
                 floor=shore)
    reflect(img, rng, pal, w, h, shore, calm=0.12, darken=0.55)
    mist(img, pal, rng, w, h, shore, h * 0.012, 0.12)
    if rng.random() < 0.6:
        # Dark near shore in the foreground, sometimes with a few trees.
        curve = h - h * (0.02 + 0.07 * fbm1d(rng, w, 3, octaves=5))
        if rng.random() < 0.6:
            curve = treeline(rng, curve, h * 0.09, gaps=0.25)
        mix(img, lerp(pal["land"][-1], pal["water"], 0.3), below(curve, ys))


def scene_hills(img, rng, pal, w, h, horizon):
    ys = rows(h)
    layers = int(rng.integers(4, 7))
    for i in range(layers):
        depth = i / (layers - 1)
        base = horizon + (h - horizon) * depth ** 1.2 * 0.8 - h * 0.01
        amp = h * (0.03 + 0.08 * depth)
        curve = base - amp * fbm1d(rng, w, 2 + i // 2, octaves=3, gain=0.35)
        top = curve
        if depth > 0.25 and rng.random() < 0.7:
            top = blobs(rng, curve, h * (0.006 + 0.03 * depth),
                        int(rng.integers(2, 8)))
        col = land_colour(pal, depth)
        shade = lerp(col, pal["land"][-1], 0.35)
        t = np.clip((ys - curve[None, :]) / (h * 0.15), 0.0, 1.0)
        layer_col = col[None, None, :] * (1 - t[..., None]) \
            + shade * t[..., None]
        img += (layer_col - img) * below(top, ys)[..., None]
        if i < layers - 1:
            mist(img, pal, rng, w, h, base + h * 0.04, h * 0.035, 0.3)


def scene_sea(img, rng, pal, w, h, horizon):
    ys = rows(h)
    # A low headland on one side so the horizon is not a bare line.
    side = rng.random() < 0.5
    x = np.linspace(0, 1, w, dtype=np.float32)
    reach = 0.25 + 0.2 * rng.random()
    edge = np.clip((reach - (1 - x if side else x)) / 0.12, 0, 1) ** 1.5
    curve = horizon - edge * (fbm1d(rng, w, 6, octaves=6) * 0.6 + 0.4) \
        * h * 0.08
    head = lerp(pal["land"][1], pal["haze"], 0.35)
    depth_t, water = reflect(img, rng, pal, w, h, horizon)
    glitter(img, rng, pal, w, h, depth_t, water)
    mix(img, head, below(curve, ys) * (ys < horizon + 3))
    mist(img, pal, rng, w, h, horizon, h * 0.025, 0.35)


def glitter(img, rng, pal, w, h, depth_t, water):
    """Sparkle path on the water under the sun (or moon)."""
    sx = pal["sun_pos"][0] * w
    xs = np.arange(w, dtype=np.float32)[None, :]
    width = w * (0.015 + 0.10 * depth_t)
    path = np.exp(-((xs - sx) / width) ** 2) * water
    sparkle = np.clip((fbm2d(rng, w, h, 40, 160, octaves=2) - 0.45) * 3.0,
                      0, 1)
    strength = 0.15 if pal["weather"] == "overcast" else 1.0
    mix(img, pal["glow"] * 0.6 + pal["sun"] * 0.4,
        path * sparkle * (0.55 - 0.3 * depth_t) * strength)


def scene_archipelago(img, rng, pal, w, h, horizon):
    ys = rows(h)
    depth_t, water = reflect(img, rng, pal, w, h, horizon)
    glitter(img, rng, pal, w, h, depth_t, water)
    mist(img, pal, rng, w, h, horizon, h * 0.02, 0.3)
    idx = np.arange(w, dtype=np.float32)
    islands = sorted(rng.random(int(rng.integers(3, 8))))   # far -> near
    for d in islands:
        cx = w * rng.random()
        half = w * (0.03 + 0.12 * rng.random()) * (0.6 + d)
        y0 = horizon + (h - horizon) * d * 0.3 + 1
        ht = h * (0.008 + 0.03 * rng.random()) * (0.5 + d)
        t = (idx - cx) / half
        bump = np.clip(1 - t * t, 0, 1) ** 1.5
        rough = 0.75 + 0.25 * fbm1d(rng, w, 30, octaves=4)
        curve = y0 - ht * bump * rough
        if half > w * 0.06 and rng.random() < 0.6:
            curve = np.where(bump > 0.2, treeline(rng, curve, ht * 0.9,
                                                  gaps=0.15), curve)
        col = land_colour(pal, 0.35 + 0.6 * d, haze=0.6)
        mix(img, col, below(curve, ys) * (ys < y0))
        # Its reflection: a soft, darker smear under the waterline.
        refl = np.clip((2 * y0 - ys) - curve[None, :], 0, 1) * (ys >= y0)
        mix(img, lerp(col, pal["water"], 0.4), refl * 0.45)


def scene_dunes(img, rng, pal, w, h, horizon):
    ys = rows(h)
    x = np.linspace(0, 1, w, dtype=np.float32)
    layers = int(rng.integers(4, 6))
    for i in range(layers):
        depth = i / (layers - 1)
        base = horizon + (h - horizon) * depth * 0.7 - h * 0.02
        amp = h * (0.05 + 0.10 * depth)
        phase = rng.random() * 6.28
        freq = 1.0 + rng.random() * 1.5
        curve = base - amp * (0.5 + 0.5 * np.sin(x * freq * 6.28 + phase)
                              * 0.6 + (fbm1d(rng, w, 3, octaves=4) - 0.5))
        lit = lerp(pal["sand"], pal["haze"], 0.5 * (1 - depth))
        shade = lerp(pal["shadow"], pal["haze"], 0.5 * (1 - depth))
        t = np.clip((ys - curve[None, :]) / (h * 0.12), 0.0, 1.0)
        col = lit[None, None, :] * (1 - t[..., None]) + shade * t[..., None]
        img += (col - img) * below(curve, ys)[..., None]
        if i < layers - 1:
            mist(img, pal, rng, w, h, base + h * 0.04, h * 0.03, 0.2)


SCENE_FUNCS = {"ridges": scene_ridges, "forest": scene_forest,
               "lake": scene_lake, "hills": scene_hills, "sea": scene_sea,
               "archipelago": scene_archipelago, "dunes": scene_dunes}


# --- technical styles -----------------------------------------------------------
# Line work is drawn with PIL into 2x supersampled masks and box-filtered
# down, which is cheap antialiasing for thousands of strokes.

SS = 2


def ink_layer(w, h):
    m = Image.new("L", (w * SS, h * SS))
    return m, ImageDraw.Draw(m)


def resolve(m, w, h):
    return np.asarray(m.resize((w, h), Image.BOX), np.float32) / 255


def blur(mask, radius):
    im = Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8))
    return np.asarray(im.filter(ImageFilter.GaussianBlur(radius)),
                      np.float32) / 255


def inks(img, pal):
    """(ink, accent, dark) for line work on this background.

    Light lines on a dark night or dusk sky, dark lines on a pale day sky --
    whichever the background asks for, so the picture never needs a second
    palette.
    """
    dark = float(img.mean()) < 0.42
    white = np.ones(3, np.float32)
    if dark:
        return lerp(pal["haze"], white, 0.3), lerp(pal["glow"], white, 0.25), \
            True
    return lerp(pal["land"][-1], pal["sky"][0][1], 0.15), \
        lerp(pal["water"], pal["land"][-1], 0.3), False


def tech_base(pal, rng, phase, w, h, disc=False):
    """Full-frame sky. The sun or moon disc is left out (it would fight the
    line work) unless an event asks for it."""
    img = sky(pal, w, h, h)
    if phase == "night":
        stars(img, rng, w, h, h, 0.5)
    sun(img, pal if disc else {**pal, "sun_size": 0.0}, w, h, h * 0.8)
    return img


def style_contour(img, rng, pal, w, h):
    ink, accent, dark = inks(img, pal)
    hf = fbm2d(rng, w, h, 3, 2, octaves=6)
    hf = (hf - hf.min()) / (hf.max() - hf.min())
    # Faint hypsometric tint: higher ground a touch toward the ink colour.
    mix(img, accent, hf ** 2 * 0.10)
    n = int(rng.integers(26, 44))
    f = hf * n
    gy, gx = np.gradient(f)
    dist = np.abs(f - np.round(f)) / (np.hypot(gx, gy) + 1e-6)   # px to line
    major = np.round(f).astype(int) % 5 == 0
    width = np.where(major, 1.7, 0.9) * h / 2160
    mix(img, ink, np.clip(width - dist + 0.5, 0, 1)
        * np.where(major, 0.7, 0.38))
    # Survey grid with tick crosses, like a plotted map sheet.
    m, d = ink_layer(w, h)
    step = h / 8
    arm = step * 0.06 * SS
    for gxp in np.arange(step / 2, w, step) * SS:
        for gyp in np.arange(step / 2, h, step) * SS:
            d.line([(gxp - arm, gyp), (gxp + arm, gyp)], fill=255, width=SS)
            d.line([(gxp, gyp - arm), (gxp, gyp + arm)], fill=255, width=SS)
    mix(img, ink, resolve(m, w, h) * 0.45)


def style_signal(img, rng, pal, w, h):
    """Stacked waveform lines, nearer ones hiding the ones behind."""
    ink, accent, dark = inks(img, pal)
    ys = rows(h)
    n = int(rng.integers(48, 78))
    top, bottom = h * (0.18 + 0.08 * rng.random()), h * 0.88
    gap = (bottom - top) / n
    x = np.linspace(-1, 1, w, dtype=np.float32)
    env = np.zeros(w, np.float32)
    for _ in range(int(rng.integers(1, 3))):     # one or two busy regions
        c, s = (rng.random() - 0.5) * 1.2, 0.18 + 0.2 * rng.random()
        env = np.maximum(env, np.exp(-((x - c) / s) ** 2))
    lw = max(1.2, h / 1500)
    acc = np.zeros((h, w), np.float32)
    hot = int(rng.integers(n // 3, n))           # one line in the accent
    hot_acc = np.zeros((h, w), np.float32)
    for i in range(n):
        base = top + i * gap
        sig = np.clip(fbm1d(rng, w, int(rng.integers(18, 40)), octaves=4)
                      - 0.38, 0, None) ** 1.5 * 5
        jitter = fbm1d(rng, w, 400, octaves=2) - 0.5
        curve = base - gap * (np.minimum(env * sig * 4.5, 9) + jitter * 0.4)
        lo = int(max(curve.min() - 4, 0))
        hi = int(min(base + gap * 2 + 4, h))
        band = ys[lo:hi]
        occl = below(curve, band)
        acc[lo:hi] *= 1 - occl
        hot_acc[lo:hi] *= 1 - occl
        slope = np.gradient(curve)
        dist = np.abs(band - curve[None, :]) / np.sqrt(1 + slope ** 2)
        stroke = np.clip(lw - dist + 0.5, 0, 1)
        target = hot_acc if i == hot else acc
        target[lo:hi] = np.maximum(target[lo:hi], stroke)
    mix(img, ink, acc * 0.8)
    mix(img, accent, hot_acc * 0.9)
    if dark:
        mix(img, accent, blur(hot_acc, h / 300) * 0.5)


DIRS = [(1, 0), (1, 1), (0, 1), (-1, 1), (-1, 0), (-1, -1), (0, -1), (1, -1)]


def style_circuit(img, rng, pal, w, h):
    """PCB routing: chips with buses of parallel traces leaving each side."""
    ink, accent, dark = inks(img, pal)
    g = h / int(rng.integers(44, 62))
    nx, ny = int(w // g), int(h // g)
    used = np.zeros((ny, nx), bool)
    m_tr, d_tr = ink_layer(w, h)
    m_pad, d_pad = ink_layer(w, h)
    m_chip, d_chip = ink_layer(w, h)
    lw = max(2, int(g * 0.16 * SS))

    def pt(cx, cy):
        return ((cx + 0.5) * g * SS, (cy + 0.5) * g * SS)

    def run(x, y, d, plan):
        pts = [pt(x, y)]
        for turn, length in plan:
            d = (d + turn) % 8
            dx, dy = DIRS[d]
            for _ in range(length):
                x2, y2 = x + dx, y + dy
                if not (0 <= x2 < nx and 0 <= y2 < ny) or used[y2, x2]:
                    return pts
                # Do not cut diagonally between two used cells.
                if dx and dy and used[y, x2] and used[y2, x]:
                    return pts
                x, y = x2, y2
                used[y, x] = True
                pts.append(pt(x, y))
        return pts

    def pad(p, big=False):
        r = g * (0.30 if big else 0.22) * SS
        if rng.random() < 0.35:
            d_pad.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r],
                          outline=255, width=max(2, int(r * 0.45)))
        else:
            d_pad.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=255)

    def bus(cells, d, p, stub):
        k = len(cells)
        t = int(rng.choice([-1, 1]))
        lean = DIRS[(d + t) % 8][0] * DIRS[p][0] \
            + DIRS[(d + t) % 8][1] * DIRS[p][1] > 0
        l0, l1 = int(rng.integers(1, 8)), int(rng.integers(2, 14))
        l2 = int(rng.integers(3, 40))
        for i, (x, y) in enumerate(cells):
            # Inner traces turn first, so the bus stays parallel through
            # the 45-degree bends without crossing itself.
            stagger = (k - 1 - i) if lean else i
            pts = run(x, y, d, [(0, l0 + stagger), (t, l1), (-t, l2)])
            if stub:
                dx, dy = DIRS[d]
                pts.insert(0, (pts[0][0] - dx * 0.7 * g * SS,
                               pts[0][1] - dy * 0.7 * g * SS))
            else:
                pad(pts[0])
            if len(pts) > 1:
                d_tr.line(pts, fill=255, width=lw, joint="curve")
                pad(pts[-1], big=rng.random() < 0.2)

    chips = []
    for _ in range(int(rng.integers(3, 7))):
        cw, ch = int(rng.integers(4, 11)), int(rng.integers(3, 8))
        if nx - cw - 4 <= 3 or ny - ch - 4 <= 3:
            continue
        x0, y0 = int(rng.integers(3, nx - cw - 3)), \
            int(rng.integers(3, ny - ch - 3))
        if used[y0 - 3:y0 + ch + 3, x0 - 3:x0 + cw + 3].any():
            continue
        used[y0 - 1:y0 + ch + 1, x0 - 1:x0 + cw + 1] = True
        chips.append((x0, y0, cw, ch))
        inset = 0.12 * g * SS
        box = [x0 * g * SS + inset, y0 * g * SS + inset,
               (x0 + cw) * g * SS - inset, (y0 + ch) * g * SS - inset]
        d_chip.rounded_rectangle(box, radius=g * 0.25 * SS, fill=255)
        d_tr.rounded_rectangle(box, radius=g * 0.25 * SS, outline=255,
                               width=lw)
    for x0, y0, cw, ch in chips:
        sides = [([(x0 + cw, y) for y in range(y0, y0 + ch)], 0, 2),
                 ([(x0 - 1, y) for y in range(y0, y0 + ch)], 4, 2),
                 ([(x, y0 + ch) for x in range(x0, x0 + cw)], 2, 0),
                 ([(x, y0 - 1) for x in range(x0, x0 + cw)], 6, 0)]
        for cells, d, p in sides:
            if rng.random() < 0.75:
                a = int(rng.integers(0, max(len(cells) - 1, 1)))
                b = int(rng.integers(a + 1, len(cells) + 1))
                bus(cells[a:b], d, p, stub=True)
    for _ in range(int(rng.integers(25, 50))):   # loose traces between chips
        d = int(rng.choice([0, 2, 4, 6]))
        p = (d + 2) % 8
        k = int(rng.integers(1, 5))
        x, y = int(rng.integers(1, nx - 1)), int(rng.integers(1, ny - 1))
        cells = [(x + DIRS[p][0] * i, y + DIRS[p][1] * i) for i in range(k)]
        if all(0 <= cx < nx and 0 <= cy < ny and not used[cy, cx]
               for cx, cy in cells):
            for cx, cy in cells:
                used[cy, cx] = True
            bus(cells, d, p, stub=False)

    tr, pads, chip = (resolve(m, w, h) for m in (m_tr, m_pad, m_chip))
    mix(img, ink, chip * 0.14)
    mix(img, ink, tr * 0.5)
    mix(img, accent, pads * 0.75)
    if dark:
        mix(img, accent, blur(tr * 0.5 + pads, g * 0.35) * 0.35)


def bilinear(tex, u, v):
    th, tw = tex.shape
    u = np.clip(u, 0, tw - 1.001)
    v = np.clip(v, 0, th - 1.001)
    u0, v0 = u.astype(int), v.astype(int)
    fu, fv = u - u0, v - v0
    top = tex[v0, u0] * (1 - fu) + tex[v0, u0 + 1] * fu
    bot = tex[v0 + 1, u0] * (1 - fu) + tex[v0 + 1, u0 + 1] * fu
    return top * (1 - fv) + bot * fv


def style_wireframe(img, rng, pal, w, h, horizon):
    """Perspective grid over terrain, rendered per pixel so both line
    families are hidden correctly behind nearer ridges."""
    ink, accent, dark = inks(img, pal)
    f = h * 0.9
    cam = 0.5 + 0.25 * rng.random()
    zmax, span = 60.0, 180.0
    tex = fbm2d(rng, 1024, 512, 14, 8, octaves=5)
    amp = 3.0 + 2.5 * rng.random()
    valley = (0.8 + 1.5 * rng.random()) if rng.random() < 0.6 else 0.0
    z = np.geomspace(0.5, zmax, 900).astype(np.float32)
    cols = np.arange(w, dtype=np.float32)
    cx = w * (0.4 + 0.2 * rng.random())
    wx = (cols[None, :] - cx) * z[:, None] / f
    ht = np.clip(bilinear(tex, (wx / span + 0.5) * 1023,
                          np.broadcast_to((z / zmax)[:, None] * 511,
                                          wx.shape)) - 0.35, 0, None) * amp
    if valley:
        # A flat floor down the middle, rising into hills on both sides.
        ht *= np.clip((np.abs(wx) - valley * 0.4) / valley, 0, 1) ** 1.5
    # Flat ground under the camera: terrain at eye level right in front of
    # it would fill the lower frame with one degenerate grid cell.
    ht *= np.clip((z[:, None] - 1.0) / 6.0, 0, 1) ** 2
    y = horizon + (cam - ht) * f / z[:, None]
    cm = np.minimum.accumulate(y, axis=0)            # running skyline
    zbuf = np.full((h, w), np.nan, np.float32)
    qy = np.arange(h, dtype=np.float32)
    for c in range(w):
        col = cm[:, c]
        r0 = int(max(math.ceil(col[-1]), 0))
        if r0 < h:
            zbuf[r0:, c] = np.interp(-qy[r0:], -col, z)
    land = ~np.isnan(zbuf)
    zb = np.where(land, zbuf, zmax)
    fog = np.clip(zb / zmax, 0, 1) ** 0.6
    fill = lerp(lerp(pal["land"][-1], pal["sky"][0][1], 0.2)[None, None, :],
                pal["haze"][None, None, :], fog[..., None] * 0.85)
    img[:] = np.where(land[..., None], fill, img)
    cell = 0.5
    u = (cols[None, :] - cx) * zb / f / cell
    v = zb / cell
    a = np.zeros((h, w), np.float32)
    for q in (u, v):
        gy, gx = np.gradient(q)
        grad = np.hypot(gx, gy) + 1e-6
        dist = np.abs(q - np.round(q)) / grad
        line = np.clip(1.1 - dist + 0.5, 0, 1)
        # Fade lines whose cells shrink below a few pixels (no moire).
        line *= np.clip((1 / grad - 3) / 5, 0, 1) * (grad > 1e-4)
        a = np.maximum(a, line)
    a *= land * (1 - fog) ** 1.3
    # The ground is dark under any sky, so the grid is always drawn light.
    colour = lerp(pal["glow"], np.ones(3, np.float32), 0.35) if dark \
        else lerp(pal["haze"], np.ones(3, np.float32), 0.4)
    mix(img, colour, a * 0.75)
    mix(img, colour, blur(a, h / 500) * (0.3 if dark else 0.15))


def facet(img, rng, w, h):
    """Low-poly: re-draw the painted scene as flat-shaded triangles."""
    g = h / int(rng.integers(26, 44))
    nx, ny = int(w / g) + 2, int(h / g) + 2
    jx = (rng.random((ny, nx)) - 0.5) * g * 0.75
    jy = (rng.random((ny, nx)) - 0.5) * g * 0.75
    px = np.arange(nx)[None, :] * g + jx
    py = np.arange(ny)[:, None] * g + jy
    px[:, 0], px[:, -1] = -1, (nx - 1) * g + 1     # pin the frame edges
    py[0, :], py[-1, :] = -1, (ny - 1) * g + 1
    out = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(out)
    for j in range(ny - 1):
        for i in range(nx - 1):
            a, b = (px[j, i], py[j, i]), (px[j, i + 1], py[j, i + 1])
            c, e = (px[j + 1, i], py[j + 1, i]), \
                (px[j + 1, i + 1], py[j + 1, i + 1])
            tris = [(a, b, e), (a, e, c)] if rng.random() < 0.5 \
                else [(a, b, c), (b, e, c)]
            for tri in tris:
                cx = sum(q[0] for q in tri) / 3
                cy = sum(q[1] for q in tri) / 3
                samples = [(cx, cy)] + [((q[0] + cx) / 2, (q[1] + cy) / 2)
                                        for q in tri]
                col = np.mean([img[int(np.clip(sy, 0, h - 1)),
                                   int(np.clip(sx, 0, w - 1))]
                               for sx, sy in samples], axis=0)
                col = col * (0.97 + 0.06 * rng.random())
                rgb = tuple(int(np.clip(v * 255, 0, 255)) for v in col)
                d.polygon(tri, fill=rgb, outline=rgb)
    img[:] = np.asarray(out, np.float32) / 255


def style_flow(img, rng, pal, w, h):
    """Streamlines through a smooth noise field, like wind on a weather map."""
    ink, accent, dark = inks(img, pal)
    lw_, lh_ = w // 8, h // 8
    field = fbm2d(rng, lw_, lh_, 3, 2, octaves=4)
    if rng.random() < 0.6:                       # mostly one way: wind
        base = (rng.random() - 0.5) * 0.6
        ang = base + (field - 0.5) * math.pi * 1.4
    else:                                        # slow swirls
        ang = field * math.pi * (3 + 2 * rng.random())
    n = int(rng.integers(1100, 2000))
    steps = 180
    step = h / 450
    x = rng.random(n) * w
    y = rng.random(n) * h
    life = rng.integers(40, steps, n)
    trail = np.empty((steps, n, 2), np.float32)
    for s in range(steps):
        trail[s, :, 0], trail[s, :, 1] = x, y
        a = ang[np.clip((y / 8).astype(int), 0, lh_ - 1),
                np.clip((x / 8).astype(int), 0, lw_ - 1)]
        x = x + np.cos(a) * step
        y = y + np.sin(a) * step
    layers = [ink_layer(w, h) for _ in range(3)]
    for i in range(n):
        pts = trail[:life[i], i]
        inside = (pts[:, 0] > -10) & (pts[:, 0] < w + 10) \
            & (pts[:, 1] > -10) & (pts[:, 1] < h + 10)
        pts = pts[inside] * SS
        if len(pts) < 2:
            continue
        m, d = layers[int(rng.integers(0, 3))]
        d.line([tuple(p) for p in pts], fill=255,
               width=max(1, int(SS * (0.8 + 1.4 * rng.random()))))
    cols = [ink, lerp(ink, accent, 0.5), accent]
    alphas = [0.35, 0.4, 0.5]
    for (m, _), col, al in zip(layers, cols, alphas):
        mix(img, col, resolve(m, w, h) * al)


def style_graph(img, rng, pal, w, h):
    """A sparse network: nodes, nearest-neighbour edges, one lit path."""
    ink, accent, dark = inks(img, pal)
    cell = h / int(rng.integers(9, 15))
    nx, ny = int(w / cell) + 1, int(h / cell) + 1
    dens = noise2d(rng, nx, ny, 3, 2)
    pts = [((i + 0.15 + 0.7 * rng.random()) * cell,
            (j + 0.15 + 0.7 * rng.random()) * cell)
           for j in range(ny) for i in range(nx)
           if rng.random() < 0.1 + 0.9 * dens[j, i] ** 1.5]
    p = np.array(pts, np.float32)
    dist = np.hypot(p[:, None, 0] - p[None, :, 0], p[:, None, 1] - p[None, :, 1])
    edges = set()
    for a in range(len(p)):
        for b in np.argsort(dist[a])[1:1 + int(rng.integers(2, 4))]:
            if dist[a, b] < cell * 2.0:
                edges.add((min(a, int(b)), max(a, int(b))))
    deg = np.zeros(len(p), int)
    adj = {i: [] for i in range(len(p))}
    for a, b in edges:
        deg[a] += 1
        deg[b] += 1
        adj[a].append(b)
        adj[b].append(a)
    m_e, d_e = ink_layer(w, h)
    m_n, d_n = ink_layer(w, h)
    m_hot, d_hot = ink_layer(w, h)
    lw = max(2, int(h / 1400 * SS))
    for a, b in edges:
        d_e.line([tuple(p[a] * SS), tuple(p[b] * SS)], fill=255, width=lw)
    for i, (x, y) in enumerate(p * SS):
        r = cell * SS * (0.025 + 0.012 * deg[i])
        d_n.ellipse([x - r, y - r, x + r, y + r], fill=255)
        if deg[i] >= 5:
            r2 = r * 2.3
            d_n.ellipse([x - r2, y - r2, x + r2, y + r2], outline=255,
                        width=lw)
    # One "request" walking through the graph, drawn in the accent.
    cur = int(rng.integers(len(p)))
    seen = {cur}
    for _ in range(int(rng.integers(6, 14))):
        nxt = [b for b in adj[cur] if b not in seen]
        if not nxt:
            break
        b = int(rng.choice(nxt))
        d_hot.line([tuple(p[cur] * SS), tuple(p[b] * SS)], fill=255,
                   width=lw * 2)
        r = cell * SS * 0.05
        x, y = p[b] * SS
        d_hot.ellipse([x - r, y - r, x + r, y + r], fill=255)
        seen.add(b)
        cur = b
    e, nodes, hot = (resolve(m, w, h) for m in (m_e, m_n, m_hot))
    mix(img, ink, e * 0.35)
    mix(img, ink, nodes * 0.7)
    mix(img, accent, hot * 0.9)
    if dark:
        mix(img, accent, blur(nodes * 0.5 + hot, cell * 0.08) * 0.4)


TECH_FUNCS = {"contour": style_contour, "signal": style_signal,
              "circuit": style_circuit, "flow": style_flow,
              "graph": style_graph}


# --- calendar events -------------------------------------------------------------
# Occasional touches on particular dates. Each entry: the days it can happen
# and the phases it shows in. Advent snow is on about half the days so it
# stays occasional; Christmas itself always gets it.

def coin(day, pct):
    """A stable per-date coin flip, independent of the recipe draws."""
    return (day.toordinal() * 2654435761) % 100 < pct


EVENTS = {
    "snow": (lambda d: d.month == 12 and (24 <= d.day <= 26
                                          or (d.day < 24 and coin(d, 45))),
             PHASES),
    "newyear": (lambda d: d.month == 12 and d.day == 31, ("dusk", "night")),
    "sankthans": (lambda d: d.month == 6 and d.day == 23, ("dusk", "night")),
    "halloween": (lambda d: d.month == 10 and d.day == 31, ("dusk", "night")),
    # Perseids and Geminids at their peaks.
    "meteors": (lambda d: (d.month, d.day) in {(8, 11), (8, 12), (8, 13),
                                               (12, 13), (12, 14)},
                ("night",)),
}


def events_on(day, phase):
    return [name for name, (when, phases) in EVENTS.items()
            if when(day) and phase in phases]


def snowfall(img, rng, w, h):
    m, d = ink_layer(w, h)
    for _ in range(int(rng.integers(1800, 3200))):
        depth = rng.random() ** 2                 # most flakes far and small
        r = (0.6 + 3.2 * depth) * h / 2160 * SS
        x, y = rng.random() * w * SS, rng.random() * h * SS
        d.ellipse([x - r, y - r, x + r, y + r],
                  fill=int(90 + 165 * depth))
    flakes = blur(resolve(m, w, h), 0.8)
    mix(img, np.array([0.96, 0.97, 1.0], np.float32),
        np.clip(flakes * 1.6, 0, 0.9))


def fireworks(img, rng, w, h, horizon):
    colours = [hexrgb(c) for c in ("#ffd8a0", "#f4a8b8", "#a8e4d4", "#c8b8f0")]
    for _ in range(int(rng.integers(4, 9))):
        m, d = ink_layer(w, h)
        cx, cy = w * (0.08 + 0.84 * rng.random()), \
            horizon * (0.15 + 0.45 * rng.random())
        radius = h * (0.05 + 0.08 * rng.random())
        sag = radius * 0.35
        rays = int(rng.integers(36, 70))
        for k in range(rays):
            a = 2 * math.pi * (k + rng.random() * 0.5) / rays
            reach = radius * (0.75 + 0.3 * rng.random())
            pts = [((cx + math.cos(a) * reach * t) * SS,
                    (cy + math.sin(a) * reach * t + sag * t * t) * SS)
                   for t in np.linspace(0.25, 1.0, 10)]
            # Brightest at the tip, fading back toward the centre.
            for i in range(len(pts) - 1):
                d.line([pts[i], pts[i + 1]], fill=int(40 + 215 * i / 9),
                       width=max(2, int(h / 1100 * SS)))
            x, y = pts[-1]
            r = h / 900 * SS
            d.ellipse([x - r, y - r, x + r, y + r], fill=255)
        burst = resolve(m, w, h)
        col = colours[int(rng.integers(len(colours)))]
        mix(img, col, np.clip(burst * 0.85 + blur(burst, h / 120) * 0.5, 0, 1))


def meteors(img, rng, w, h, horizon):
    m, d = ink_layer(w, h)
    # One radiant: every streak points away from the same spot in the sky.
    rx, ry = w * (0.2 + 0.6 * rng.random()), -h * 0.1
    for _ in range(int(rng.integers(6, 14))):
        x, y = w * rng.random(), horizon * (0.1 + 0.6 * rng.random())
        ang = math.atan2(y - ry, x - rx)
        length = w * (0.03 + 0.07 * rng.random())
        segs = 16
        for i in range(segs):
            t0, t1 = i / segs, (i + 1) / segs
            d.line([((x + math.cos(ang) * length * t0) * SS,
                     (y + math.sin(ang) * length * t0) * SS),
                    ((x + math.cos(ang) * length * t1) * SS,
                     (y + math.sin(ang) * length * t1) * SS)],
                   fill=int(255 * t1 ** 1.5), width=max(2, int(h / 1200 * SS)))
    streaks = resolve(m, w, h)
    mix(img, np.array([0.92, 0.95, 1.0], np.float32),
        np.clip(streaks + blur(streaks, h / 400) * 0.6, 0, 1))


def bonfires(img, rng, w, h, horizon):
    """Midsummer fires on the hills: warm glows, a bright core, faint smoke."""
    ys, xs = np.mgrid[0:h, 0:w].astype(np.float32)
    for _ in range(int(rng.integers(2, 6))):
        cx = w * (0.05 + 0.9 * rng.random())
        cy = horizon + (h - horizon) * (0.04 + 0.3 * rng.random())
        size = h * (0.006 + 0.012 * (cy - horizon) / (h - horizon + 1))
        d = np.hypot(xs - cx, (ys - cy) * 1.4)
        mix(img, hexrgb("#e0783c"), np.exp(-(d / (size * 12)) ** 2) * 0.55)
        mix(img, hexrgb("#ffd890"), np.clip(size - d + 0.5, 0, 1))
        smoke = np.exp(-((xs - cx - (cy - ys) * 0.15) / (size * 2.5)) ** 2) \
            * np.clip((cy - ys) / (h * 0.08), 0, 1) \
            * np.exp(-np.clip(cy - ys, 0, None) / (h * 0.06))
        mix(img, hexrgb("#8a8088"), smoke * 0.25)


# --- recipe and render ----------------------------------------------------------

def pick(rng, weights):
    names = list(weights)
    p = np.array([weights[n] for n in names])
    return names[int(rng.choice(len(names), p=p / p.sum()))]


def recipe(day_seed, season, scene=None, weather=None, style=None,
           tone="natural", events=()):
    """Everything about the day's picture that is not the lighting.

    Fixed per day so all four phases show the same place. Draw order matters:
    adding a draw shifts every later one, which only changes future days.
    """
    r = np.random.default_rng(day_seed)
    rec = {
        "scene": pick(r, SCENES),
        "weather": pick(r, WEATHER),
        "variant": {p: int(r.integers(len(PALETTES[p]))) for p in PHASES},
        "sun": {p: (lerp(*SUN[p]["x"], r.random()),
                    lerp(*SUN[p]["y"], r.random())) for p in PHASES},
        "hue": (r.random() - 0.5) * 0.06,
        "horizon": 0.46 + 0.20 * r.random(),
        "aurora": r.random() < 0.35,
        "birds": r.random() < 0.3,
        "seeds": [int(s) for s in r.integers(1 << 32, size=4)],
        "season": season,
    }
    rec["style"] = pick(r, STYLES)          # drawn last: older days unchanged
    rec["tone"] = tone
    rec["events"] = list(events)
    if scene:
        rec["scene"] = scene
    if weather:
        rec["weather"] = weather
    if style:
        rec["style"] = style
    if rec["scene"] in ("sea", "archipelago", "lake"):
        rec["horizon"] = min(rec["horizon"], 0.58)  # leave room for water
    return rec


def paint_sky(rec, pal, phase, moon, w, h, horizon, birds_ok=True):
    _, sky_seed, star_seed, bird_seed = rec["seeds"]
    img = sky(pal, w, h, horizon)
    overcast = rec["weather"] == "overcast"
    if phase == "night":
        stars(img, np.random.default_rng(star_seed), w, h, horizon,
              0.25 if overcast else 1.0)
        if rec["aurora"] and not overcast:
            aurora(img, np.random.default_rng(star_seed + 1), w, h, horizon)
    sun(img, pal, w, h, horizon, moon if phase == "night" else None)
    clouds(img, np.random.default_rng(sky_seed), pal, w, h, horizon)
    if birds_ok and rec["birds"] and phase != "night":
        birds(img, np.random.default_rng(bird_seed), pal, w, h, horizon)
    return img


def sky_events(img, rec, w, h, horizon):
    ev = np.random.default_rng(rec["seeds"][0] + 7)
    if "meteors" in rec["events"]:
        meteors(img, ev, w, h, horizon)
    if "newyear" in rec["events"]:
        fireworks(img, ev, w, h, horizon)


def render(rec, phase, moon, w=WIDTH, h=HEIGHT):
    pal = palette(phase, rec)
    horizon = h * rec["horizon"]
    geo = rec["seeds"][0]
    style = rec["style"]
    events = rec["events"]
    if "halloween" in events:
        moon = 0.5                              # always full on the night
    rng = np.random.default_rng(geo)
    if style in ("landscape", "lowpoly", "wireframe"):
        img = paint_sky(rec, pal, phase, moon, w, h, horizon,
                        birds_ok=style != "wireframe")
        sky_events(img, rec, w, h, horizon)
        if style == "wireframe":
            style_wireframe(img, rng, pal, w, h, horizon)
        else:
            SCENE_FUNCS[rec["scene"]](img, rng, pal, w, h, horizon)
        if "sankthans" in events:
            bonfires(img, np.random.default_rng(geo + 8), w, h, horizon)
        if style == "lowpoly":
            facet(img, np.random.default_rng(geo + 1), w, h)
    else:
        img = tech_base(pal, np.random.default_rng(geo + 2), phase, w, h,
                        disc="halloween" in events)
        sky_events(img, rec, w, h, h * 0.8)
        TECH_FUNCS[style](img, rng, pal, w, h)
    if "snow" in events:
        snowfall(img, np.random.default_rng(geo + 9), w, h)

    # Triangular dither + faint grain: without it, gradients this wide band
    # visibly in 8 bits.
    q = np.random.default_rng(geo ^ 0x5EED)
    img = img * 255.0
    img += q.random(img.shape, np.float32) + q.random(img.shape, np.float32) \
        - 1.0
    img += q.normal(0.0, 0.8, img.shape[:2]).astype(np.float32)[..., None]
    return Image.fromarray(np.clip(img + 0.5, 0, 255).astype(np.uint8)), pal


# --- DMS, state, CLI --------------------------------------------------------------

def dms(*args, retry_for=0):
    deadline = time.monotonic() + retry_for
    while True:
        exe = shutil.which("dms")
        if exe:
            r = subprocess.run([exe, "ipc", "call", *args],
                               capture_output=True, text=True)
            if r.returncode == 0:
                return r.stdout.strip()
        if time.monotonic() >= deadline:
            return None
        time.sleep(3)


def gaming():
    """True while GameMode is active: a render is seconds of full CPU, and
    the timer can just as well try again ten minutes later."""
    exe = shutil.which("gamemoded")
    if not exe:
        return False
    r = subprocess.run([exe, "-s"], capture_output=True, text=True)
    return "is active" in r.stdout


def current_slot(now, tone=None):
    """(phase, day, tone, slot). The tone is part of the slot, so switching
    DMS between light and dark re-renders on the next timer run."""
    phase = phase_at(now)
    day = now.date()
    # A night that started yesterday evening keeps yesterday's landscape.
    if phase == "night" and now.hour < 12:
        day -= dt.timedelta(days=1)
    tone = tone or dms_tone()
    return phase, day, tone, f"{day.isoformat()}-{phase}-{tone}"


def apply(path, slot, wait=0, remember=True):
    if dms("wallpaper", "set", str(path), retry_for=wait) is None:
        print("DMS not reachable; image left rendered", file=sys.stderr)
        return False
    STATE_DIR.mkdir(parents=True, exist_ok=True)
    STATE.write_text(slot + "\n")
    if remember:
        hist = history()
        if not hist or hist[-1] != str(path):
            hist.append(str(path))
        HISTORY.write_text("\n".join(hist[-HISTORY_LEN:]) + "\n")
    return True


def history():
    if not HISTORY.is_file():
        return []
    return [line for line in HISTORY.read_text().splitlines() if line]


def cmd_prev():
    """Step back to the image applied before the current one."""
    cur = dms("wallpaper", "get")
    # Pruned files cannot come back; skip them.
    hist = [p for p in history() if Path(p).is_file()]
    if hist and hist[-1] == cur:
        hist.pop()
    if not hist:
        print("no earlier generated wallpaper to go back to", file=sys.stderr)
        return 1
    target = hist[-1]
    HISTORY.write_text("\n".join(hist) + "\n")
    *_, slot = current_slot(dt.datetime.now().astimezone())
    if not apply(target, slot, remember=False):
        return 1
    print(target)
    return 0


def cmd_mode(value):
    """Set DMS's light/dark behaviour; returns the tone to render with.

    auto  -> Theme schedule "Wallpaper" (DMS follows the image)
    dark  -> Manual, dark       light -> Manual, light
    cycle -> auto -> dark -> light -> auto
    No value prints the current mode and returns None.
    """
    tone = dms_tone()
    current = {v: k for k, v in MODES.items()}[tone]
    if value is None:
        print(current)
        return None
    if value == "cycle":
        order = list(MODES)
        value = order[(order.index(current) + 1) % len(order)]
    if value not in MODES:
        print(f"mode: expected one of {', '.join(MODES)}, cycle",
              file=sys.stderr)
        return None
    if value == "auto":
        ok = dms("settings", "set", "matugenSmartMode", "true")
    else:
        # theme dark/light also switch Wallpaper mode off (setLightMode).
        ok = dms("theme", value)
    if ok is None:
        print("DMS not reachable", file=sys.stderr)
        return None
    detail = {"auto": "Light or dark follows the wallpaper",
              "dark": "Forced dark", "light": "Forced light"}[value]
    dms("toast", "infoWith", f"Theme: {value}", detail, "", "wallgen-mode")
    print(value)
    return MODES[value]


def prune():
    cutoff = time.time() - KEEP_DAYS * 86400
    for f in OUT_DIR.glob("*.jpg"):
        if f.stat().st_mtime < cutoff:
            f.unlink()


def cmd_keep():
    cur = dms("wallpaper", "get")
    if not cur or Path(cur).parent != OUT_DIR:
        print("current wallpaper is not a generated one", file=sys.stderr)
        return 1
    KEEP_DIR.mkdir(parents=True, exist_ok=True)
    dest = KEEP_DIR / f"wallgen-{Path(cur).name}"
    shutil.copy2(cur, dest)
    print(dest)
    return 0


def cmd_schedule():
    """Today's phase changes, by scanning the day in two-minute steps."""
    lat, lon = location()
    start = dt.datetime.now().astimezone().replace(hour=0, minute=0,
                                                   second=0, microsecond=0)
    prev = None
    print(f"{start:%Y-%m-%d} at {lat:.3f}, {lon:.3f}")
    for m in range(0, 24 * 60, 2):
        t = start + dt.timedelta(minutes=m)
        p = phase_at(t)
        if p != prev:
            elev, _ = solar(t)
            print(f"  {t:%H:%M}  {p:<5}  (sun {elev:+.1f} deg)")
            prev = p
    noon = max((solar(start + dt.timedelta(minutes=m))[0], m)
               for m in range(0, 24 * 60, 2))
    print(f"  highest sun {noon[0]:.1f} deg at "
          f"{start + dt.timedelta(minutes=noon[1]):%H:%M}")
    return 0


def main():
    ap = argparse.ArgumentParser(
        prog="wallgen", description="Generate a calm wallpaper for the "
        "current light outside and hand it to DMS.")
    ap.add_argument("command", nargs="?",
                    choices=["keep", "schedule", "prev", "mode"],
                    help="keep: copy the current generated wallpaper into "
                    f"{KEEP_DIR}; schedule: today's phase changes; prev: go "
                    "back to the previously applied image; mode "
                    "[auto|dark|light|cycle]: set DMS light/dark and "
                    "re-render (no value: print the current mode)")
    ap.add_argument("value", nargs="?", help=argparse.SUPPRESS)
    ap.add_argument("--phase", choices=PHASES)
    ap.add_argument("--style", choices=list(STYLES))
    ap.add_argument("--scene", choices=list(SCENES))
    ap.add_argument("--season", choices=SEASONS)
    ap.add_argument("--weather", choices=list(WEATHER))
    ap.add_argument("--tone", choices=TONES,
                    help="override the light/dark tone (default: follow "
                    "DMS's theme schedule)")
    ap.add_argument("--event", action="append", choices=list(EVENTS),
                    help="add a calendar event regardless of the date "
                    "(repeatable)")
    ap.add_argument("--seed", type=int,
                    help="landscape seed (default: today's date)")
    ap.add_argument("--random", action="store_true",
                    help="a random seed: a different picture right now")
    ap.add_argument("--no-apply", action="store_true",
                    help="render only; print the path")
    ap.add_argument("--force", action="store_true",
                    help="re-render even if the image exists")
    ap.add_argument("--auto", action="store_true",
                    help="timer mode: do nothing unless the phase has "
                    "changed since the last applied image, so a wallpaper "
                    "picked by hand stays until the light changes; also "
                    "waits while GameMode is active")
    ap.add_argument("--wait-dms", type=int, default=0, metavar="SECONDS",
                    help="keep retrying the DMS IPC call (login race)")
    a = ap.parse_args()

    if a.command == "keep":
        return cmd_keep()
    if a.command == "schedule":
        return cmd_schedule()
    if a.command == "prev":
        return cmd_prev()
    mode_tone = None
    if a.command == "mode":
        mode_tone = cmd_mode(a.value)
        if mode_tone is None:
            return 0 if a.value is None else 1

    now = dt.datetime.now().astimezone()
    # The slot is the real phase outside, whatever was asked for. The timer
    # compares slots, not file names, so anything applied by hand -- another
    # seed, style or phase -- stays up until the light actually changes.
    real_phase, real_day, real_tone, slot = current_slot(now, mode_tone)
    if a.auto and STATE.is_file() and STATE.read_text().strip() == slot:
        return 0
    if a.auto and gaming():
        print("GameMode active; trying again on the next timer run")
        return 0

    phase = a.phase or real_phase
    day = now.date() if a.phase else real_day
    if a.random:
        a.seed = int.from_bytes(os.urandom(4), "little")
    seed = a.seed if a.seed is not None else day.toordinal()
    season = a.season or season_of(day)
    tone = a.tone or real_tone
    events = sorted(set(events_on(day, phase)) | set(a.event or ()))

    tag = day.isoformat() if a.seed is None else f"seed{seed}"
    extras = [x for x in (a.style, a.scene, a.season, a.weather) if x]
    extras += [tone] if tone != "natural" else []
    extras += a.event or []
    name = "-".join([tag, phase, *extras]) + ".jpg"
    path = OUT_DIR / name

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    if a.force or not path.exists():
        t0 = time.monotonic()
        rec = recipe(seed, season, a.scene, a.weather, a.style, tone, events)
        image, pal = render(rec, phase, moon_age(now))
        # 4:4:4 at q95 keeps the dither; PNG of a dithered gradient is ~25 MB.
        tmp = path.with_suffix(".tmp")
        image.save(tmp, "JPEG", quality=95, subsampling=0)
        tmp.replace(path)
        what = rec["scene"] if rec["style"] in ("landscape", "lowpoly") \
            else "-"
        notes = ", ".join([rec["style"], what, season, rec["weather"],
                           pal["name"], tone, *events])
        print(f"{path} ({notes}, {time.monotonic() - t0:.1f}s)")
    else:
        print(path)
    prune()

    if not a.no_apply:
        apply(path, slot, wait=a.wait_dms)
    return 0


if __name__ == "__main__":
    sys.exit(main())
