"""Adds in-between frames to a horizontal RGBA strip (character animation) by motion interpolation
(optical flow, no image generation). `--factor 3` turns n frames into 3 * (n - 1) + 1.
Usage: python tools/art/interpolate_strip.py --strip assets/sprites/shogun_attack.png --frames 6
           --out assets/sprites/shogun_attack_x3.png [--factor 3]
The cells keep their size; the strip gets longer. Prints the new frame count."""

import argparse

import cv2
import numpy as np


def cut(strip: np.ndarray, frames: int) -> list:
    width = strip.shape[1] // frames
    return [strip[:, i * width:(i + 1) * width] for i in range(frames)]


def premultiply(frame: np.ndarray) -> np.ndarray:
    out = frame.astype(np.float32)
    out[..., :3] *= out[..., 3:4] / 255.0
    return out


def unpremultiply(frame: np.ndarray) -> np.ndarray:
    out = frame.copy()
    alpha = np.maximum(out[..., 3:4], 1.0) / 255.0
    out[..., :3] = np.clip(out[..., :3] / alpha, 0, 255)
    return np.clip(out, 0, 255).astype(np.uint8)


def warp(image: np.ndarray, flow: np.ndarray, share: float) -> np.ndarray:
    height, width = image.shape[:2]
    grid_x, grid_y = np.meshgrid(np.arange(width, dtype=np.float32), np.arange(height, dtype=np.float32))
    return cv2.remap(image, grid_x + flow[..., 0] * share, grid_y + flow[..., 1] * share, cv2.INTER_LINEAR,
                     borderMode=cv2.BORDER_CONSTANT, borderValue=(0, 0, 0, 0))


def guide(frame: np.ndarray) -> np.ndarray:
    """Grey image the flow follows: brightness of the painted body, weighted by its opacity."""
    grey = frame[..., :3].max(axis=2) * 0.5 + frame[..., 3] * 0.5
    return cv2.GaussianBlur(np.clip(grey, 0, 255).astype(np.uint8), (0, 0), 1.2)


def between(a: np.ndarray, b: np.ndarray, shares: list) -> list:
    pa, pb = premultiply(a), premultiply(b)
    ga, gb = guide(pa), guide(pb)
    a_to_b = cv2.calcOpticalFlowFarneback(ga, gb, None, 0.5, 5, 31, 5, 7, 1.5, 0)
    b_to_a = cv2.calcOpticalFlowFarneback(gb, ga, None, 0.5, 5, 31, 5, 7, 1.5, 0)
    result = []
    for t in shares:
        from_a = warp(pa, b_to_a, t)
        from_b = warp(pb, a_to_b, 1.0 - t)
        result.append(unpremultiply((1.0 - t) * from_a + t * from_b))
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strip", required=True)
    parser.add_argument("--frames", type=int, required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--factor", type=int, default=3)
    args = parser.parse_args()
    strip = cv2.imread(args.strip, cv2.IMREAD_UNCHANGED)
    frames = cut(strip, args.frames)
    out = []
    shares = [k / args.factor for k in range(1, args.factor)]
    for k in range(len(frames) - 1):
        out.append(frames[k])
        out.extend(between(frames[k], frames[k + 1], shares))
    out.append(frames[-1])
    cv2.imwrite(args.out, np.concatenate(out, axis=1))
    print("%d frames -> %d" % (len(frames), len(out)))


main()
