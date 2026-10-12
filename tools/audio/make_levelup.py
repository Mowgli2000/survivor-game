"""Synthesizes the level-up jingle (original, no samples): four rising bell notes, low to high
(C5 E5 G5 C6), the last one held and ringing, like a classic RPG level gain. Each note is a soft
attack plus a few inharmonic partials with their own decay. Writes assets/audio/sfx/level_up.wav.
Standard library only. Run: python tools/audio/make_levelup.py"""
import math
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "assets" / "audio" / "sfx" / "level_up.wav"
NOTES = [(523.25, 0.00), (659.25, 0.13), (783.99, 0.26), (1046.50, 0.39)]
PARTIALS = [(1.0, 1.0, 0.55), (2.0, 0.45, 0.35), (3.01, 0.22, 0.22), (4.2, 0.1, 0.12), (0.5, 0.25, 0.7)]
TOTAL = 1.5


def main() -> None:
    n = int(RATE * TOTAL)
    out = [0.0] * n
    for index, (freq, start) in enumerate(NOTES):
        last = index == len(NOTES) - 1
        gain = 1.0 + 0.15 * index
        for ratio, amp, decay in PARTIALS:
            tau = decay * (1.8 if last else 1.0)
            begin = int(start * RATE)
            for i in range(begin, n):
                t = (i - begin) / RATE
                env = min(1.0, t / 0.004) * math.exp(-t / tau)
                if t > 0.01 and env < 1e-4:
                    break
                out[i] += math.sin(2 * math.pi * freq * ratio * t) * amp * env * gain
    peak = max(abs(s) for s in out)
    fade = int(RATE * 0.05)
    for i in range(fade):
        out[-1 - i] *= i / fade
    with wave.open(str(OUT), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.8 * 32767)) for s in out))
    print(OUT)


if __name__ == "__main__":
    main()
