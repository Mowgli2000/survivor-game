"""Synthesizes the stormy rumble of the last seal's portal (original, no samples): deep thunder
that rolls and breaks in irregular swells, with a few heavy low claps. Everything is low in pitch
(sub sines around 30-50 Hz, noise low-passed at about 120-400 Hz so small speakers still carry
it), nothing high. 8 s, seamless loop (the noise tail is cross-faded into its start, claps stay
clear of the seam). Writes assets/audio/sfx/portal_rumble.wav. Standard library only.
Run: python tools/audio/make_rumble.py
"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 22050
SECONDS = 8.0
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx" / "portal_rumble.wav"


def lowpass(source: list[float], k: float) -> list[float]:
    out = []
    y = 0.0
    for x in source:
        y += k * (x - y)
        out.append(y)
    return out


def main() -> None:
    rng = random.Random(33)
    total = int(RATE * SECONDS)
    fade = int(RATE * 0.8)
    raw = [rng.random() * 2.0 - 1.0 for _ in range(total + fade)]
    # Two bands: a heavy body (~120 Hz) and a rougher mid-low layer (~400 Hz) for small speakers.
    body = lowpass(lowpass(raw, 0.035), 0.05)
    rough = lowpass(lowpass(raw, 0.11), 0.2)
    body_peak = max(abs(v) for v in body)
    rough_peak = max(abs(v) for v in rough)
    body = [v / body_peak for v in body]
    rough = [v / rough_peak for v in rough]
    # Irregular rolling swells: a few random bumps on top of a slow chaotic base.
    swell = [0.35] * (total + fade)
    for _ in range(9):
        centre = rng.random() * (total + fade)
        width = RATE * (0.25 + rng.random() * 0.7)
        height = 0.4 + rng.random() * 0.6
        for i in range(max(0, int(centre - 3 * width)), min(total + fade, int(centre + 3 * width))):
            swell[i] += height * math.exp(-((i - centre) / width) ** 2)
    for i in range(total + fade):
        t = i / RATE
        swell[i] *= 0.8 + 0.2 * math.sin(2 * math.pi * 1.3 * t + 0.4) * math.sin(2 * math.pi * 0.7 * t)
    mix = [(body[i] * 0.85 + rough[i] * 0.45) * swell[i] for i in range(total + fade)]
    # Seamless: the tail beyond `total` is cross-faded into the start.
    for i in range(fade):
        w = i / fade
        mix[i] = mix[i] * w + mix[total + i] * (1.0 - w)
    samples = mix[:total]
    # Heavy low claps: a short crack of low noise and a falling sub sine, long decay.
    for centre in (1.4, 3.3, 5.1, 6.4):
        start = int(centre * RATE)
        phase = 0.0
        low = 0.0
        for j in range(int(RATE * 1.6)):
            t = j / RATE
            low += 0.12 * (rng.random() * 2.0 - 1.0 - low)
            phase += 2 * math.pi * (30.0 + 40.0 * math.exp(-t / 0.18)) / RATE
            clap = low * math.exp(-t / 0.35) * 4.0 + math.sin(phase) * math.exp(-t / 0.5) * 1.3
            samples[start + j] += clap * min(1.0, t / 0.006)
    # Constant deep sub: whole number of cycles over the loop (30 and 45 Hz in 8 s).
    for i in range(total):
        t = i / RATE
        samples[i] += math.sin(2 * math.pi * 30.0 * t) * 0.35 + math.sin(2 * math.pi * 45.0 * t + 1.1) * 0.2
    peak = max(abs(s) for s in samples)
    with wave.open(str(OUT), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.9 * 32767)) for s in samples))
    print(OUT)


if __name__ == "__main__":
    main()
