"""Generate music loops with the ElevenLabs Eleven Music API (POST /v1/music).

Usage:
  python tools/audio/gen_music.py --list                 # the tracks and the credit counter
  python tools/audio/gen_music.py --ids combat_dungeon   # PAID: one generation per id
  python tools/audio/gen_music.py --ids combat_dungeon --dry-run

Same rules as gen_sfx.py (docs/design/audio-musique-licence.md): nothing is sent without the dev's OK, one take
per track, a track already generated is skipped (--again to redo). The key is read from ELEVENLABS_API_KEY (never
printed). Files go to art_tests/audio/music/<id>.mp3 (ignored by git). The cost is a pessimistic estimate (the
sources disagree: 5 to 900 credits per minute): the real balance is only visible on the ElevenLabs website.
Prompts never name an artist, a song or a label (forbidden by the Eleven Music terms).
"""
import argparse
import json
import os
import sys
import urllib.request

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from gen_sfx import get_key, load_json, ROOT  # noqa: E402

LIST_PATH = os.path.join(ROOT, "tools", "audio", "music_list.json")
STATE_PATH = os.path.join(ROOT, "tools", "audio", "generated_music.json")
OUT_DIR = os.path.join(ROOT, "art_tests", "audio", "music")
URL = "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128"
CREDITS_PER_MINUTE = 900


def estimate(track: dict) -> int:
    return int(round(track["seconds"] / 60.0 * CREDITS_PER_MINUTE))


def generate(key: str, track: dict, style: str) -> bytes:
    body = json.dumps({
        "prompt": f"{track['prompt']} {style}",
        "music_length_ms": int(track["seconds"] * 1000),
        "model_id": "music_v1",
        "force_instrumental": True,
    }).encode("utf-8")
    request = urllib.request.Request(URL, data=body, method="POST", headers={
        "xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with urllib.request.urlopen(request, timeout=600) as response:
        return response.read()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--ids", nargs="*", default=[])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--again", action="store_true")
    args = parser.parse_args()

    data = load_json(LIST_PATH, {})
    tracks = data["tracks"]
    state = load_json(STATE_PATH, {"done": [], "credits": 0})
    if args.list or not args.ids:
        for t in tracks:
            mark = "done" if t["id"] in state["done"] else "    "
            print(f"[{mark}] {t['id']:<22} {t['seconds']:>4}s  ~{estimate(t):>5} credits  {t['place']}")
        print(f"estimated credits spent so far: {state['credits']}")
        return 0
    chosen = [t for t in tracks if t["id"] in args.ids]
    missing = set(args.ids) - {t["id"] for t in chosen}
    if missing:
        print("unknown ids:", ", ".join(sorted(missing)))
        return 1
    chosen = [t for t in chosen if args.again or t["id"] not in state["done"]]
    total = sum(estimate(t) for t in chosen)
    print(f"{len(chosen)} track(s), ~{total} credits (estimate)")
    if args.dry_run:
        return 0
    key = get_key()
    if not key:
        print("no ELEVENLABS_API_KEY")
        return 1
    os.makedirs(OUT_DIR, exist_ok=True)
    for t in chosen:
        audio = generate(key, t, data["style"])
        with open(os.path.join(OUT_DIR, t["id"] + ".mp3"), "wb") as f:
            f.write(audio)
        if t["id"] not in state["done"]:
            state["done"].append(t["id"])
        state["credits"] += estimate(t)
        with open(STATE_PATH, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
        print("done", t["id"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
