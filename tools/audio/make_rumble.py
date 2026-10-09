"""Synthesizes the constant deep rumble of the last seal's portal (original, no samples): two
low sines (about 36 and 54 Hz) beating slowly, plus noise low-passed hard, with a slow swell.
4 s with a seamless loop (every sine has a whole number of cycles; the noise is cross-faded with
its own start). Writes assets/audio/sfx/portal_rumble.wav. Standard library only.
Run: python tools/audio/make_rumble.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
SECONDS = 4.0
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx" / "portal_rumble.wav"


def main() -> None:
    rng = random.Random(21)
    total = int(RATE * SECONDS)
    fade = int(RATE * 0.5)
    noise = []
    low1 = low2 = low3 = 0.0
    for _ in range(total + fade):
        n = rng.random() * 2.0 - 1.0
        low1 += 0.02 * (n - low1)
        low2 += 0.03 * (low1 - low2)
        low3 += 0.05 * (low2 - low3)
        noise.append(low3)
    # Seamless noise: the tail beyond `total` is cross-faded into the start.
    for i in range(fade):
        w = i / fade
        noise[i] = noise[i] * w + noise[total + i] * (1.0 - w)
    samples = []
    for i in range(total):
        t = i / RATE
        deep = math.sin(2 * math.pi * 36.0 * t) * 0.55 + math.sin(2 * math.pi * 54.0 * t + 1.1) * 0.3
        swell = 0.8 + 0.2 * math.sin(2 * math.pi * 0.5 * t) * math.sin(2 * math.pi * 0.25 * t + 0.6)
        samples.append((deep * swell + noise[i] * 9.0))
    peak = max(abs(s) for s in samples)
    with wave.open(str(OUT), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.85 * 32767)) for s in samples))
    print(OUT)


if __name__ == "__main__":
    main()
