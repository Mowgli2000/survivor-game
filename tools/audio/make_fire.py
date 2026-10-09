"""Synthesizes the fire-crackle sound played when the mouse lights a brazier (original, no samples):
low-passed noise (the roar), band-passed hiss and random short pops (the crackles). 1.6 s with a
seamless loop (played while the fire is hovered). Writes assets/audio/sfx/fire_crackle.wav. Standard library only.
Run: python tools/audio/make_fire.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
SECONDS = 1.6
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx" / "fire_crackle.wav"


def main() -> None:
    rng = random.Random(7)
    total = int(RATE * SECONDS)
    samples = [0.0] * total
    # Roar: noise low-passed twice, slowly swelling.
    low1 = 0.0
    low2 = 0.0
    hiss_prev = 0.0
    for i in range(total):
        t = i / RATE
        n = rng.random() * 2.0 - 1.0
        low1 += 0.035 * (n - low1)
        low2 += 0.05 * (low1 - low2)
        swell = 0.75 + 0.25 * math.sin(t * 6.0) * math.sin(t * 2.3 + 1.0)
        roar = low2 * 5.5 * swell
        # Hiss: high-passed noise, quiet.
        hiss = (n - hiss_prev) * 0.08
        hiss_prev = n
        samples[i] = roar + hiss
    # Crackles: short pops at random times, each a burst of noise with a fast decay.
    pops = 26
    for _ in range(pops):
        start = rng.randrange(0, total - 2000)
        length = rng.randrange(120, 900)
        amp = rng.uniform(0.15, 0.55)
        tone = rng.uniform(0.2, 0.8)
        prev = 0.0
        for k in range(length):
            n = rng.random() * 2.0 - 1.0
            prev += tone * (n - prev)
            samples[start + k] += (n - prev * 0.5) * amp * math.exp(-k / (length * 0.22))
    # Seamless loop: the last `xf` samples are blended into the first ones, then cut off.
    xf = int(RATE * 0.25)
    looped = samples[:total - xf]
    for i in range(xf):
        w = i / xf
        looped[i] = samples[i] * w + samples[total - xf + i] * (1.0 - w)
    peak = max(abs(s) for s in looped)
    out = [max(-1.0, min(1.0, s / peak * 0.8)) for s in looped]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(v * 32767)) for v in out))
    print(OUT)


if __name__ == "__main__":
    main()
