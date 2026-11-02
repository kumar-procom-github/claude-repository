"""Ahvanam Originals: small procedural instrumentals for video invitations.

Everything here is synthesised from scratch (no samples, no existing tunes),
so the tracks are our own work and free to ship / share.
"""
import json
import subprocess
import sys

import numpy as np
from scipy.signal import butter, lfilter

SR = 44100
OUT = sys.argv[1] if len(sys.argv) > 1 else "."


def env(n, a=0.01, r=0.1, sustain=1.0):
    e = np.ones(n) * sustain
    na, nr = max(1, int(a * SR)), max(1, int(r * SR))
    na = min(na, n)
    e[:na] = np.linspace(0, sustain, na)
    nr = min(nr, n)
    e[n - nr:] *= np.linspace(1, 0, nr)
    return e


def bp(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), hi / (SR / 2)], btype="band")
    return lfilter(b, a, x)


def lp(x, cut, order=2):
    b, a = butter(order, cut / (SR / 2), btype="low")
    return lfilter(b, a, x)


def hp(x, cut, order=2):
    b, a = butter(order, cut / (SR / 2), btype="high")
    return lfilter(b, a, x)


def phase_of(freq_curve):
    return 2 * np.pi * np.cumsum(freq_curve) / SR


# ---------------------------------------------------------------- instruments --

def flute(f, dur, prev=None):
    n = int(dur * SR)
    t = np.arange(n) / SR
    fc = np.full(n, f, dtype=float)
    if prev:  # gentle glide from the previous note (meend)
        g = min(n, int(0.05 * SR))
        fc[:g] = np.linspace(prev, f, g)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.15) / 0.2, 0, 1)
    ph = phase_of(fc * vib)
    x = np.sin(ph) + 0.22 * np.sin(2 * ph) + 0.07 * np.sin(3 * ph)
    breath = lp(np.random.randn(n), 3000) * 0.04
    return (x + breath) * env(n, 0.07, min(0.2, dur * 0.4), 0.9)


def shehnai(f, dur, prev=None):
    n = int(dur * SR)
    t = np.arange(n) / SR
    fc = np.full(n, f, dtype=float)
    if prev:
        g = min(n, int(0.06 * SR))
        fc[:g] = np.linspace(prev, f, g)
    vib = 1 + 0.006 * np.sin(2 * np.pi * 6 * t) * np.clip((t - 0.12) / 0.2, 0, 1)
    ph = phase_of(fc * vib)
    x = sum(np.sin(k * ph) / k ** 0.8 for k in range(1, 11))
    x = 0.6 * bp(x, 700, 2600) + 0.4 * x  # nasal reed colour
    return x * env(n, 0.04, min(0.15, dur * 0.3), 0.8) * 0.5


def pluck(f, dur, bright=1.0, buzz=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k in range(1, 16):
        decay = 2.2 + k * 0.9 / bright
        amp = (1 / k) * (1 + buzz * (k > 5))
        x += amp * np.sin(2 * np.pi * f * k * (1 + 0.0004 * k) * t) * np.exp(-decay * t)
    return x * env(n, 0.002, 0.05) * 0.5


def bell(f, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    parts = [(1, 1, 1.4), (2.0, 0.5, 2.2), (2.76, 0.35, 2.8), (5.4, 0.2, 4.5), (8.93, 0.1, 6)]
    x = sum(a * np.sin(2 * np.pi * f * r * t) * np.exp(-d * t) for r, a, d in parts)
    return x * env(n, 0.001, 0.05) * 0.45


def piano(f, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = sum((1 / k ** 1.3) * np.sin(2 * np.pi * f * k * t) * np.exp(-(1.2 + 0.7 * k) * t) for k in range(1, 9))
    return x * env(n, 0.003, 0.12) * 0.55


def pad(f, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for det in (-0.004, 0, 0.005):
        ph = 2 * np.pi * f * (1 + det) * t
        x += sum(np.sin(k * ph) / k for k in range(1, 7))
    return lp(x, 1800) * env(n, min(0.8, dur * 0.4), min(0.8, dur * 0.4)) * 0.12


def tanpura(f, dur):
    """One plucked tanpura string: long, buzzy, shimmering."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k in range(1, 22):
        amp = (1 / k ** 0.7) * (0.6 + 0.4 * np.sin(2 * np.pi * (0.3 + 0.05 * k) * t + k))
        x += amp * np.sin(2 * np.pi * f * k * t) * np.exp(-(0.5 + 0.05 * k) * t)
    return lp(x, 4000) * env(n, 0.01, 0.4) * 0.05


def mix(*parts):
    n = max(len(p) for _, p in parts)
    out = np.zeros(n)
    for g, p in parts:
        out[:len(p)] += g * p
    return out


def drum(f0, f1, dur, decay, noise=0.0, noise_band=(1500, 6000)):
    n = int(dur * SR)
    t = np.arange(n) / SR
    fc = f1 + (f0 - f1) * np.exp(-t * 30)
    x = np.sin(phase_of(fc)) * np.exp(-decay * t)
    if noise:
        x += noise * bp(np.random.randn(n), *noise_band) * np.exp(-decay * 2.5 * t)
    return x


def tabla(stroke, sa):
    if stroke == "dha":
        return mix((0.8, drum(110, 70, 0.6, 5)), (0.5, drum(sa * 2, sa * 2, 0.4, 9, 0.2)))
    if stroke == "ge":
        return 0.9 * drum(100, 65, 0.6, 4.5)
    if stroke == "na":
        return 0.55 * drum(sa * 2, sa * 2, 0.35, 11, 0.25)
    if stroke == "tin":
        return 0.45 * drum(sa * 3, sa * 3, 0.3, 14, 0.15)
    if stroke == "ka":
        return 0.35 * drum(180, 150, 0.12, 30, 0.6)
    return np.zeros(1)


def dhol(stroke):
    if stroke == "boom":
        return drum(90, 55, 0.5, 6, 0.1)
    if stroke == "chik":
        return 0.6 * drum(400, 380, 0.12, 25, 1.0, (2000, 8000))
    return np.zeros(1)


def clap():
    n = int(0.18 * SR)
    x = bp(np.random.randn(n), 900, 3500) * np.exp(-np.arange(n) / SR * 28)
    return x * 0.5


def kick():
    return drum(150, 48, 0.4, 9) * 0.9


def snare():
    n = int(0.2 * SR)
    return mix((0.4, drum(220, 180, 0.2, 18)), (0.5, bp(np.random.randn(n), 1500, 7000) * np.exp(-np.arange(n) / SR * 22)))


def hat():
    n = int(0.06 * SR)
    return 0.25 * hp(np.random.randn(n), 7000) * np.exp(-np.arange(n) / SR * 70)


def daf(stroke):
    if stroke == "dum":
        return drum(85, 60, 0.5, 6) * 0.9
    n = int(0.15 * SR)
    jingle = bp(np.random.randn(n), 4000, 9000) * np.exp(-np.arange(n) / SR * 25)
    return mix((0.4, drum(300, 260, 0.15, 20)), (0.5, jingle))


# ------------------------------------------------------------------- music bits --

def hz(sa, semis):
    return sa * 2 ** (semis / 12)


class Track:
    def __init__(self, seconds):
        self.n = int(seconds * SR)
        self.l = np.zeros(self.n)
        self.r = np.zeros(self.n)

    def add(self, x, at, gain=1.0, pan=0.0):
        i = int(at * SR)
        if i >= self.n:
            return
        x = x[: self.n - i] * gain
        self.l[i:i + len(x)] += x * (1 - pan) * 0.5 * 2 ** 0.5
        self.r[i:i + len(x)] += x * (1 + pan) * 0.5 * 2 ** 0.5

    def reverb(self, mix=0.22):
        def comb(x, d, g):
            b = np.zeros(d + 1)
            b[0] = 1
            a = np.zeros(d + 1)
            a[0] = 1
            a[d] = -g
            return lfilter(b, a, x)

        out = []
        for ch, offs in ((self.l, 0), (self.r, 23)):
            wet = sum(comb(ch, d + offs, 0.78) for d in (1557, 1617, 1491, 1422)) / 4
            wet = lp(wet, 5000)
            out.append(ch * (1 - mix) + wet * mix)
        self.l, self.r = out

    def write(self, path, bitrate):
        st = np.stack([self.l, self.r], 1)
        st /= np.max(np.abs(st)) + 1e-9
        st *= 0.89
        pcm = (st * 32767).astype("<i2").tobytes()
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
             "-c:a", "aac", "-b:a", bitrate, "-movflags", "+faststart", path],
            input=pcm, check=True)


def melody(rng, scale, bars, steps_per_bar=8, start=0, rest_p=0.18):
    """A phrase-structured melody (A A' B A'') as (step, degree, length)."""
    def phrase(seed_deg):
        notes = []
        deg = seed_deg
        s = 0
        while s < steps_per_bar * 2:
            ln = rng.choice([1, 2, 2, 3, 4], p=[0.2, 0.35, 0.15, 0.1, 0.2])
            ln = min(ln, steps_per_bar * 2 - s)
            if rng.random() > rest_p or s == 0:
                notes.append((s, deg, ln))
            deg = int(np.clip(deg + rng.choice([-2, -1, -1, 0, 1, 1, 2]), 0, len(scale) * 2 - 1))
            s += ln
        # end on a stable note
        if notes:
            st, _, ln = notes[-1]
            notes[-1] = (st, 0 if seed_deg < len(scale) else len(scale), ln)
        return notes

    a = phrase(start)
    b = phrase(start + 2)
    a2 = [(s, min(d + (1 if i == 2 else 0), len(scale) * 2 - 1), ln) for i, (s, d, ln) in enumerate(a)]
    form = [a, a2, b, a]
    out = []
    span = steps_per_bar * 2
    for k in range(bars // 2):
        for s, d, ln in form[k % 4]:
            out.append((k * span + s, d, ln))
    return out


def deg_to_semi(scale, d):
    return scale[d % len(scale)] + 12 * (d // len(scale))


MOHANAM = [0, 2, 4, 7, 9]  # Sa Re Ga Pa Dha (pentatonic)
HAMSADHWANI = [0, 2, 4, 7, 11]
MAJOR = [0, 2, 4, 5, 7, 9, 11]
HIJAZ_PENTA = [0, 1, 4, 5, 7]
MINOR_PENTA = [0, 3, 5, 7, 10]


def render_lead(tr, notes, inst, sa, scale, step, octave=12, gain=0.5, pan=0.0):
    prev = None
    for s, d, ln in notes:
        f = hz(sa, deg_to_semi(scale, d) + octave)
        if inst in (flute, shehnai):
            x = inst(f, ln * step * 1.05, prev)
        else:
            x = inst(f, max(ln * step, 0.6) * 1.5)
        tr.add(x, s * step, gain, pan)
        prev = f


def drone(tr, sa, seconds, beat):
    pattern = [hz(sa, 7 - 12), hz(sa, 0), hz(sa, 0), hz(sa, -12)]
    t = 0.0
    i = 0
    while t < seconds:
        tr.add(tanpura(pattern[i % 4], beat * 4), t, 1.0, -0.3 + 0.2 * (i % 4))
        t += beat
        i += 1


def tabla_loop(tr, sa, seconds, beat, pattern, gain=0.6):
    step = beat / 2
    t = 0.0
    i = 0
    while t < seconds:
        st = pattern[i % len(pattern)]
        if st != "-":
            tr.add(tabla(st, sa), t, gain, 0.15)
        t += step
        i += 1


KEHERWA = ["dha", "ge", "na", "tin", "na", "ka", "dhi" if False else "dha", "na"]
DADRA = ["dha", "-", "dha", "na", "tin", "na"]


def song_mangalam(seconds=40, seed=3):
    rng = np.random.default_rng(seed)
    sa, bpm = 261.6, 84
    beat = 60 / bpm
    tr = Track(seconds)
    drone(tr, sa / 2, seconds, beat)
    notes = melody(rng, MOHANAM, int(seconds / (beat * 4)) + 2, steps_per_bar=8)
    render_lead(tr, notes, shehnai, sa, MOHANAM, beat / 2, octave=0, gain=0.55)
    tabla_loop(tr, sa, seconds, beat, KEHERWA, 0.5)
    tr.reverb(0.25)
    return tr


def song_utsavam(seconds=40, seed=11):
    rng = np.random.default_rng(seed)
    sa, bpm = 293.7, 118
    beat = 60 / bpm
    tr = Track(seconds)
    notes = melody(rng, HAMSADHWANI, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.1)
    render_lead(tr, notes, bell, sa, HAMSADHWANI, beat / 2, octave=12, gain=0.35, pan=0.2)
    render_lead(tr, notes, flute, sa, HAMSADHWANI, beat / 2, octave=0, gain=0.3, pan=-0.2)
    t = 0.0
    i = 0
    while t < seconds:
        tr.add(dhol("boom" if i % 4 in (0, 3) else "chik"), t, 0.55)
        if i % 4 == 2:
            tr.add(clap(), t, 0.5, 0.3)
        t += beat / 2
        i += 1
    tr.reverb(0.18)
    return tr


def song_sannayi(seconds=60, seed=5):
    rng = np.random.default_rng(seed)
    sa, bpm = 246.9, 70
    beat = 60 / bpm
    tr = Track(seconds)
    drone(tr, sa / 2, seconds, beat)
    notes = melody(rng, MOHANAM, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.25)
    render_lead(tr, notes, shehnai, sa, MOHANAM, beat / 2, octave=0, gain=0.6)
    tabla_loop(tr, sa, seconds, beat, DADRA, 0.45)
    tr.reverb(0.3)
    return tr


def song_deepotsavam(seconds=60, seed=21):
    rng = np.random.default_rng(seed)
    sa, bpm = 277.2, 96
    beat = 60 / bpm
    tr = Track(seconds)
    drone(tr, sa / 2, seconds, beat)
    notes = melody(rng, MOHANAM, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.12)
    step = beat / 2
    for s, d, ln in notes:
        f = hz(sa, deg_to_semi(MOHANAM, d))
        tr.add(pluck(f, 1.6, bright=1.4, buzz=0.6), s * step, 0.5, -0.1)
    tabla_loop(tr, sa, seconds, beat, KEHERWA, 0.55)
    tr.reverb(0.22)
    return tr


def song_bhakti(seconds=60, seed=8):
    rng = np.random.default_rng(seed)
    sa, bpm = 220.0, 60
    beat = 60 / bpm
    tr = Track(seconds)
    drone(tr, sa / 2, seconds, beat)
    notes = melody(rng, MOHANAM, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.3)
    render_lead(tr, notes, flute, sa, MOHANAM, beat / 2, octave=12, gain=0.45)
    t = 0.0
    while t < seconds:
        tr.add(bell(hz(sa, 24), 3), t, 0.25, 0.4)
        t += beat * 4
    tr.reverb(0.35)
    return tr


def chords_major(sa):
    return [[0, 4, 7], [9 - 12, 0, 4], [5 - 12, 9 - 12, 0], [7 - 12, 11 - 12, 2]]  # I vi IV V


def song_madhuram(seconds=60, seed=13):
    rng = np.random.default_rng(seed)
    sa, bpm = 261.6, 72
    beat = 60 / bpm
    tr = Track(seconds)
    chords = chords_major(sa)
    t, c = 0.0, 0
    while t < seconds:
        ch = chords[c % 4]
        for i, semi in enumerate(ch + [ch[0] + 12, ch[1] + 12, ch[2] + 12, ch[1] + 12]):
            tr.add(piano(hz(sa, semi), 2.5), t + i * beat / 2, 0.35, -0.2 + 0.05 * i)
        tr.add(pad(hz(sa, ch[0] - 12), beat * 4.2), t, 0.6)
        t += beat * 4
        c += 1
    notes = melody(rng, MAJOR, int(seconds / (beat * 4)) + 2, steps_per_bar=4, rest_p=0.35)
    render_lead(tr, notes, piano, sa, MAJOR, beat, octave=12, gain=0.3, pan=0.2)
    tr.reverb(0.3)
    return tr


def song_shanti_bells(seconds=60, seed=17):
    rng = np.random.default_rng(seed)
    sa, bpm = 293.7, 80
    beat = 60 / bpm
    tr = Track(seconds)
    chords = chords_major(sa)
    t, c = 0.0, 0
    while t < seconds:
        ch = chords[c % 4]
        tr.add(pad(hz(sa, ch[0]), beat * 4.3) + pad(hz(sa, ch[1]), beat * 4.3) + pad(hz(sa, ch[2]), beat * 4.3), t, 0.5)
        t += beat * 4
        c += 1
    notes = melody(rng, MAJOR, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.2)
    render_lead(tr, notes, bell, sa, MAJOR, beat / 2, octave=12, gain=0.4, pan=0.1)
    tr.reverb(0.4)
    return tr


def song_noor(seconds=60, seed=29):
    rng = np.random.default_rng(seed)
    sa, bpm = 220.0, 92
    beat = 60 / bpm
    tr = Track(seconds)
    t = 0.0
    while t < seconds:
        tr.add(pad(hz(sa, -12), beat * 8.2), t, 0.5)
        t += beat * 8
    notes = melody(rng, HIJAZ_PENTA, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.15)
    step = beat / 2
    for s, d, ln in notes:
        f = hz(sa, deg_to_semi(HIJAZ_PENTA, d) + 12)
        tr.add(pluck(f, 1.2, bright=0.8), s * step, 0.55, -0.15)
    pattern = ["dum", "-", "tek", "tek", "dum", "tek", "-", "tek"]
    t, i = 0.0, 0
    while t < seconds:
        st = pattern[i % 8]
        if st != "-":
            tr.add(daf(st), t, 0.5, 0.15)
        t += step
        i += 1
    tr.reverb(0.25)
    return tr


def song_happy_day(seconds=60, seed=31):
    rng = np.random.default_rng(seed)
    sa, bpm = 329.6, 124
    beat = 60 / bpm
    tr = Track(seconds)
    chords = chords_major(sa)
    t, c = 0.0, 0
    while t < seconds:
        ch = chords[c % 4]
        for b in range(8):
            semi = ch[b % 3] - 12
            tr.add(pluck(hz(sa, semi), 0.5, bright=2.0), t + b * beat / 2, 0.3, -0.25)
        t += beat * 4
        c += 1
    notes = melody(rng, MAJOR, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.12)
    render_lead(tr, notes, bell, sa, MAJOR, beat / 2, octave=0, gain=0.4, pan=0.2)
    t, i = 0.0, 0
    while t < seconds:
        if i % 4 == 0:
            tr.add(kick(), t, 0.7)
        if i % 4 == 2:
            tr.add(snare(), t, 0.45, 0.1)
        tr.add(hat(), t, 0.4, 0.3)
        t += beat / 2
        i += 1
    tr.reverb(0.15)
    return tr


def song_swagatham(seconds=60, seed=37):
    rng = np.random.default_rng(seed)
    sa, bpm = 277.2, 128
    beat = 60 / bpm
    tr = Track(seconds)
    drone(tr, sa / 2, seconds, beat * 2)
    notes = melody(rng, HAMSADHWANI, int(seconds / (beat * 4)) + 2, steps_per_bar=8, rest_p=0.1)
    render_lead(tr, notes, shehnai, sa, HAMSADHWANI, beat / 2, octave=0, gain=0.55)
    pattern = ["boom", "chik", "chik", "boom", "boom", "chik", "boom", "chik"]
    t, i = 0.0, 0
    while t < seconds:
        tr.add(dhol(pattern[i % 8]), t, 0.6)
        t += beat / 2
        i += 1
    tr.reverb(0.18)
    return tr


SONGS = [
    # id, title, titleTe, mood, fn, seconds, bundled
    ("mangalam", "Mangalam", "మంగళం", "wedding", song_mangalam, 40, True),
    ("utsavam", "Utsavam", "ఉత్సవం", "celebration", song_utsavam, 40, True),
    ("sannayi", "Sannayi", "సన్నాయి", "wedding", song_sannayi, 60, False),
    ("swagatham", "Swagatham", "స్వాగతం", "celebration", song_swagatham, 60, False),
    ("deepotsavam", "Deepotsavam", "దీపోత్సవం", "festive", song_deepotsavam, 60, False),
    ("bhakti", "Bhakti", "భక్తి", "devotional", song_bhakti, 60, False),
    ("madhuram", "Madhuram", "మధురం", "soft", song_madhuram, 60, False),
    ("shanti-bells", "Shanti Bells", "శాంతి గంటలు", "christian", song_shanti_bells, 60, False),
    ("noor", "Noor", "నూర్", "eid", song_noor, 60, False),
    ("happy-day", "Happy Day", "హ్యాపీ డే", "birthday", song_happy_day, 60, False),
]

if __name__ == "__main__":
    only = sys.argv[2:] or None
    meta = []
    for sid, title, te, mood, fn, secs, bundled in SONGS:
        if only and sid not in only:
            continue
        np.random.seed(abs(hash(sid)) % 2**31)
        tr = fn(secs)
        path = f"{OUT}/{sid}.m4a"
        tr.write(path, "64k" if bundled else "112k")
        meta.append({"id": sid, "title": title, "titleTe": te, "mood": mood,
                     "file": f"tracks/{sid}.m4a", "seconds": secs,
                     "credit": "Ahvanam Originals · free to use", "bundled": bundled})
        print("ok", sid)
    json.dump(meta, open(f"{OUT}/meta.json", "w"), ensure_ascii=False, indent=1)
