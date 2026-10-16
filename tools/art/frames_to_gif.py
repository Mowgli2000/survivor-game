"""Assembles a PNG sequence (Godot --write-movie out.png) into an animated GIF.

Usage: python tools/art/frames_to_gif.py --dir <folder> --out <file.gif> [--width 720] [--every 1] [--fps 15]
"""

import argparse
import glob
import os

from PIL import Image


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--dir", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--width", type=int, default=720)
    parser.add_argument("--every", type=int, default=1, help="keep one frame out of N")
    parser.add_argument("--fps", type=float, default=15.0, help="fps of the source sequence")
    args = parser.parse_args()
    files = sorted(glob.glob(os.path.join(args.dir, "*.png")))[::args.every]
    frames = []
    for path in files:
        image = Image.open(path).convert("RGB")
        height = round(image.height * args.width / image.width)
        frames.append(image.resize((args.width, height), Image.LANCZOS).quantize(colors=128, dither=Image.Dither.NONE))
    duration = int(1000 * args.every / args.fps)
    frames[0].save(args.out, save_all=True, append_images=frames[1:], duration=duration, loop=0, optimize=True)
    print("%d frames, %.1f MB" % (len(frames), os.path.getsize(args.out) / 1e6))


main()
