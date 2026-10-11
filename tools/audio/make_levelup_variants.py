"""Synthesizes three original level-up jingle candidates (no samples) into art_tests/audio/:
a = harp arpeggio rising two octaves then a ringing chord, b = bell chime with shimmer,
c = short bright fanfare. The dev picks one, then it is baked as assets/audio/sfx/level_up.wav.
Standard library only. Run: python tools/audio/make_levelup_variants.py"""
import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parents[2] / "art_tests" / "audio"


def pluck(buf: list, freq: float, start: float, gain: float, decay: float) -> None:
    """Harp-like pluck: bright harmonics that die faster than the fundamental."""
    begin = int(start * RATE)
    for i in range(begin, len(buf)):
        t = (i - begin) / RATE
        env = min(1.0, t / 0.003)
        if t > 0.01 and math.exp(-t / decay) < 1e-4:
            break
        s = 0.0
        for k, amp in ((1, 1.0), (2, 0.5), (3, 0.3), (4, 0.18), (5, 0.1)):
            s += math.sin(2 * math.pi * freq * k * t) * amp * math.exp(-t * k / decay)
        buf[i] += s * env * gain


def bell(buf: list, freq: float, start: float, gain: float, decay: float) -> None:
    begin = int(start * RATE)
    for i in range(begin, len(buf)):
        t = (i - begin) / RATE
        if t > 0.01 and math.exp(-t / decay) < 1e-4:
            break
        env = min(1.0, t / 0.002) * math.exp(-t / decay)
        s = 0.0
        for ratio, amp, d in ((1.0, 1.0, 1.0), (2.76, 0.4, 0.6), (5.4, 0.2, 0.4), (0.5, 0.3, 1.2)):
            s += math.sin(2 * math.pi * freq * ratio * t) * amp * math.exp(-t / (decay * d))
        buf[i] += s * min(1.0, t / 0.002) * gain * (env / max(env, 1e-9) if env > 0 else 0)


def brass(buf: list, freq: float, start: float, length: float, gain: float) -> None:
    begin = int(start * RATE)
    for i in range(begin, min(len(buf), begin + int((length + 0.5) * RATE))):
        t = (i - begin) / RATE
        env = min(1.0, t / 0.02) * (1.0 if t < length else math.exp(-(t - length) / 0.12))
        s = 0.0
        for k in range(1, 9):
            s += math.sin(2 * math.pi * freq * k * t + 0.3 * k) / k
        buf[i] += s * env * gain


def write(name: str, buf: list) -> None:
    peak = max(abs(s) for s in buf)
    fade = int(RATE * 0.05)
    for i in range(fade):
        buf[-1 - i] *= i / fade
    path = OUT / (name + ".wav")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.8 * 32767)) for s in buf))
    print(path)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    c5 = 523.25
    # a: harp arpeggio C major pentatonic up, then a held chord with a sparkle on top
    a = [0.0] * int(RATE * 2.0)
    steps = [1.0, 9 / 8, 5 / 4, 3 / 2, 5 / 3, 2.0, 9 / 4, 5 / 2, 3.0]
    for index, ratio in enumerate(steps):
        pluck(a, c5 * ratio, 0.065 * index, 0.8, 0.5)
    end = 0.065 * len(steps)
    for ratio in (1.0, 5 / 4, 3 / 2, 2.0):
        pluck(a, c5 * ratio * 2, end, 0.7, 1.1)
    pluck(a, c5 * 6.0, end + 0.05, 0.35, 0.9)
    write("level_up_a", a)
    # b: bell chime, notes overlapping, shimmer
    b = [0.0] * int(RATE * 2.0)
    for index, ratio in enumerate([1.0, 5 / 4, 3 / 2, 2.0, 5 / 2]):
        bell(b, c5 * ratio, 0.09 * index, 0.8 + 0.1 * index, 0.7)
    bell(b, c5 * 4.0, 0.5, 0.35, 1.0)
    write("level_up_b", b)
    # c: short bright fanfare, C-E-G then high C held
    c = [0.0] * int(RATE * 1.8)
    brass(c, c5 / 2, 0.0, 0.1, 0.5)
    brass(c, c5 * 5 / 8, 0.11, 0.1, 0.5)
    brass(c, c5 * 3 / 4, 0.22, 0.1, 0.5)
    for ratio in (1.0, 5 / 4, 3 / 2):
        brass(c, c5 * ratio, 0.34, 0.55, 0.45)
    pluck(c, c5 * 4.0, 0.34, 0.5, 0.9)
    write("level_up_c", c)


if __name__ == "__main__":
    main()
