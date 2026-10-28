"""Synthesizes the shuriken throw (original, no samples): a dry metallic "shing" at the release, a band of wind that
rises and falls as the star flies past, and a fast spinning flutter on top. Writes art_tests/audio/shuriken_synth.wav (an alternative, not used in game).
Standard library only. Run: python tools/audio/make_shuriken.py"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "art_tests" / "audio" / "shuriken_synth.wav"
LENGTH = 0.46
# Inharmonic partials of a small steel blade: (Hz, level, decay seconds).
PARTIALS = [(2900.0, 0.5, 0.07), (4370.0, 0.45, 0.055), (6130.0, 0.35, 0.045), (8420.0, 0.22, 0.03)]


def synth(seed: int) -> list[float]:
    rng = random.Random(seed)
    count = int(RATE * LENGTH)
    out = []
    low = band = 0.0
    prev_noise = 0.0
    phases = [rng.uniform(0.0, 6.28) for _ in PARTIALS]
    for i in range(count):
        t = i / RATE
        u = t / LENGTH
        noise = rng.random() * 2.0 - 1.0
        # Wind: state-variable band-pass whose center rises then falls (the star passes), bell-shaped level.
        center = 1100.0 + 2600.0 * math.sin(math.pi * min(1.0, u * 1.1)) ** 1.5
        f = 2.0 * math.sin(math.pi * center / RATE)
        low += f * band
        high = noise - low - 0.45 * band
        band += f * high
        wind = band * math.sin(math.pi * u) ** 1.6 * 0.9
        # Spin: a quick flutter on the wind, strongest at the start (the throw), fading as it flies away.
        flutter = 0.65 + 0.35 * math.sin(2.0 * math.pi * 38.0 * t)
        wind *= flutter
        # Flick: a click (high-passed noise, ~8 ms) then the ringing blade.
        click = (noise - prev_noise) * math.exp(-t / 0.006) * 0.9
        prev_noise = noise
        ring = 0.0
        for k, (freq, level, decay) in enumerate(PARTIALS):
            phases[k] += 2.0 * math.pi * freq / RATE
            ring += math.sin(phases[k]) * level * math.exp(-t / decay)
        out.append(wind * 1.6 + click + ring * 0.55)
    peak = max(abs(s) for s in out)
    fade = int(RATE * 0.03)
    for i in range(fade):
        out[-1 - i] *= i / fade
    return [s / peak * 0.9 for s in out]


def main() -> None:
    samples = synth(7)
    with wave.open(str(OUT), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in samples))
    print(OUT)


if __name__ == "__main__":
    main()
