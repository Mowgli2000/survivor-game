"""Synthesizes the lightning crack heard when a bolt strikes out of the last seal's portal
(original, no samples): a sharp noise click, a fast downward sine sweep and a short rumbling tail.
Writes assets/audio/sfx/lightning_zap_1..3.wav (three variants). Standard library only.
Run: python tools/audio/make_zap.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx"


def zap(seed: int) -> list[float]:
    rng = random.Random(seed)
    length = int(RATE * 0.38)
    f0 = rng.uniform(1400.0, 2400.0)
    out = []
    phase = 0.0
    low = 0.0
    prev = 0.0
    for i in range(length):
        t = i / RATE
        n = rng.random() * 2.0 - 1.0
        # Crack: high-passed noise, gone in ~30 ms.
        crack = (n - prev) * math.exp(-t / 0.012) * 1.1
        prev = n
        # Sweep: a sine falling fast, the electric "zzt".
        freq = f0 * math.exp(-t / 0.05) + 90.0
        phase += 2.0 * math.pi * freq / RATE
        sweep = math.sin(phase) * math.exp(-t / 0.07) * 0.5
        # Rumble: low-passed noise, the thunder's tail.
        low += 0.03 * (n - low)
        rumble = low * math.exp(-t / 0.16) * 5.0
        out.append(crack + sweep + rumble)
    peak = max(abs(s) for s in out)
    fade = int(RATE * 0.02)
    for i in range(fade):
        out[-1 - i] *= i / fade
    return [s / peak * 0.85 for s in out]


def main() -> None:
    for k in range(1, 4):
        samples = zap(100 + k)
        path = OUT / ("lightning_zap_%d.wav" % k)
        with wave.open(str(path), "wb") as f:
            f.setnchannels(1)
            f.setsampwidth(2)
            f.setframerate(RATE)
            f.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767)) for v in samples))
        print(path)


if __name__ == "__main__":
    main()
