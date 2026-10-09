"""Turns a 3:2 background (1536x1024) into a native 16:9 one (1536x864) by painting the missing
sides with the image model (outpainting), then pastes the original back over the middle with a
soft seam, so the centre stays exactly as drawn. Needs Pillow and OPENAI_API_KEY.
Usage: python tools/art/widen.py <in.png> <out.png> [--note "what the sides show"]
The original is scaled to 1296x864 and put at x=120; the model fills the 120 px at each side (and
the unused strip at the bottom, cropped away).
"""
import argparse
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageFilter

W, H = 1536, 1024
OUT_W, OUT_H = 1536, 864
SRC_W = 1296
X0 = (W - SRC_W) // 2
FEATHER = 28


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("source")
    parser.add_argument("target")
    parser.add_argument("--note", default="")
    args = parser.parse_args()
    original = Image.open(args.source).convert("RGB")
    small = original.resize((SRC_W, OUT_H), Image.LANCZOS)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    canvas.paste(small.convert("RGBA"), (X0, 0))
    work = tempfile.mkdtemp()
    canvas_path = os.path.join(work, "canvas.png")
    result_path = os.path.join(work, "result.png")
    canvas.save(canvas_path)
    prompt = ("Outpaint this game background: continue the painting seamlessly into the transparent areas on the "
              "left, the right and the bottom. Same cel-shaded style, palette, lighting, perspective and floor. "
              "The architecture, decor and the stone floor simply continue sideways; the floor stays empty and "
              "flat; keep the same horizon height. Do not change the existing part. No text, no characters. " + args.note)
    command = [sys.executable, os.path.join(os.path.dirname(__file__), "gen_image.py"), "--out", result_path,
               "--opaque", "--size", "%dx%d" % (W, H), "--image", canvas_path, "--mask", canvas_path, "--prompt", prompt]
    if subprocess.run(command).returncode != 0:
        return 1
    result = Image.open(result_path).convert("RGB").crop((0, 0, OUT_W, OUT_H))
    # The original back over the middle, its two edges feathered into the painted sides.
    mask = Image.new("L", (OUT_W, OUT_H), 0)
    inner = Image.new("L", (SRC_W - 2 * FEATHER, OUT_H), 255)
    mask.paste(inner, (X0 + FEATHER, 0))
    mask = mask.filter(ImageFilter.GaussianBlur(FEATHER / 2))
    middle = Image.new("RGB", (OUT_W, OUT_H))
    middle.paste(small, (X0, 0))
    result.paste(middle, (0, 0), mask)
    result.save(args.target)
    print(args.target)
    return 0


if __name__ == "__main__":
    sys.exit(main())
