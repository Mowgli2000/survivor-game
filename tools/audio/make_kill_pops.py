"""Synthesizes the monster-death "pop" sounds (original, no samples): a short
downward sine sweep (the bubble bursting), a click, and a soft noise puff (the smoke).
Writes assets/audio/sfx/combat/kill_pop_1..6.wav. Standard library only.
Run: python tools/audio/make_kill_pops.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx" / "combat"
# Start frequencies (Hz) of the six variants: never the same pop twice in a row.
STARTS = [520, 580, 640, 700, 760, 820]


def pop(f0: float, seed: int) -> list[float]:
    rng = random.Random(seed)
    length = int(RATE * 0.22)
    samples = []
    phase = 0.0
    low = 0.0
    for i in range(length):
        t = i / RATE
        # Bubble: the pitch falls fast, the level dies in ~40 ms.
        freq = f0 * (0.38 + 0.62 * math.exp(-t / 0.028))
        phase += 2.0 * math.pi * freq / RATE
        attack = min(1.0, t / 0.002)
        body = math.sin(phase) * math.exp(-t / 0.034) * attack
        # Click: a few ms of noise at the start.
        click = (rng.random() * 2.0 - 1.0) * math.exp(-t / 0.004) * 0.5
        # Puff: low-passed noise, a little longer and softer.
        low += 0.12 * ((rng.random() * 2.0 - 1.0) - low)
        puff = low * math.exp(-t / 0.055) * 1.6
        samples.append(body * 0.9 + click + puff * 0.55)
    peak = max(abs(s) for s in samples)
    fade = int(RATE * 0.01)
    for i in range(fade):
        samples[-1 - i] *= i / fade
    return [s / peak * 0.8 for s in samples]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for n, f0 in enumerate(STARTS, start=1):
        data = pop(f0, 100 + n)
        path = OUT / f"kill_pop_{n}.wav"
        with wave.open(str(path), "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes(b"".join(struct.pack("<h", int(s * 32767)) for s in data))
        print("wrote", path.name)


if __name__ == "__main__":
    main()
