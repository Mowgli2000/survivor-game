"""Synthesizes three original "wave cleared" sound candidates (no samples) into art_tests/audio/ (dev, 2026-10-11: the
rising level-up jingle did not fit the end of a wave): a = deep gong with a soft shimmer, b = two warm marimba notes
resolving, c = wind chimes. The chosen one is copied to assets/audio/sfx/wave_clear.wav. Standard library only.
Run: python tools/audio/make_wave_clear.py"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "art_tests" / "audio"


def partial(buf: list, freq: float, start: float, gain: float, decay: float, attack: float = 0.004) -> None:
    begin = int(start * RATE)
    for i in range(begin, len(buf)):
        t = (i - begin) / RATE
        if t > attack and math.exp(-t / decay) < 1e-4:
            break
        buf[i] += math.sin(2 * math.pi * freq * t) * gain * min(1.0, t / attack) * math.exp(-t / decay)


def gong(buf: list, freq: float, start: float, gain: float, decay: float) -> None:
    for ratio, amp, d in ((1.0, 1.0, 1.0), (1.51, 0.55, 0.8), (2.0, 0.5, 0.7), (2.63, 0.35, 0.5), (3.4, 0.2, 0.4)):
        partial(buf, freq * ratio, start, gain * amp, decay * d, 0.012)


def marimba(buf: list, freq: float, start: float, gain: float) -> None:
    partial(buf, freq, start, gain, 0.45)
    partial(buf, freq * 4.0, start, gain * 0.25, 0.08)  # the woody click
    partial(buf, freq * 10.0, start, gain * 0.05, 0.03)


def chime(buf: list, freq: float, start: float, gain: float) -> None:
    for ratio, amp, d in ((1.0, 1.0, 1.0), (2.76, 0.35, 0.5), (5.4, 0.12, 0.3)):
        partial(buf, freq * ratio, start, gain * amp, 0.9 * d, 0.002)


def write(name: str, buf: list) -> None:
    peak = max(abs(s) for s in buf)
    fade = int(RATE * 0.08)
    for i in range(fade):
        buf[-1 - i] *= i / fade
    path = OUT / (name + ".wav")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.7 * 32767)) for s in buf))
    print(path)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    random.seed(7)
    a = [0.0] * int(RATE * 2.2)
    gong(a, 98.0, 0.0, 1.0, 1.1)          # G2
    gong(a, 196.0, 0.0, 0.35, 0.9)        # G3 body
    for k, ratio in enumerate((3.0, 4.0, 5.0)):
        chime(a, 98.0 * 2 * ratio, 0.25 + 0.11 * k, 0.12)   # a soft shimmer that settles
    write("wave_clear_a", a)
    b = [0.0] * int(RATE * 1.6)
    marimba(b, 392.0, 0.0, 0.8)           # G4
    marimba(b, 523.25, 0.22, 0.9)         # C5: it resolves
    marimba(b, 659.25, 0.22, 0.4)         # E5 over it
    write("wave_clear_b", b)
    c = [0.0] * int(RATE * 2.4)
    notes = [880.0, 1318.5, 1046.5, 1568.0, 987.8, 1174.7]
    random.shuffle(notes)
    for k, freq in enumerate(notes):
        chime(c, freq, 0.17 * k + random.uniform(0.0, 0.03), 0.3)
    write("wave_clear_c", c)


if __name__ == "__main__":
    main()
