"""Generate sound effects with the ElevenLabs sound generation API.

Usage:
  python tools/audio/gen_sfx.py --list                 # show the list and the credit counter
  python tools/audio/gen_sfx.py --test --dry-run       # what the 5-sound trial would call (no network)
  python tools/audio/gen_sfx.py --test                 # PAID: one generation per test sound
  python tools/audio/gen_sfx.py --ids level_up         # PAID: only these ids

Rules (docs/design/audio-refonte.md): one take per sound, a sound already generated is skipped
(use --again to redo it), nothing is sent without the dev's OK. The API key is read from the
ELEVENLABS_API_KEY environment variable (Windows user registry as a fallback) and never printed.
Files go to art_tests/audio/<id>.mp3 (ignored by git). The credit counter is an estimate kept in
tools/audio/generated.json: the key has no user_read permission, so the real balance is only
visible on the ElevenLabs website.
"""
import argparse
import json
import os
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LIST_PATH = os.path.join(ROOT, "tools", "audio", "sound_list.json")
STATE_PATH = os.path.join(ROOT, "tools", "audio", "generated.json")
OUT_DIR = os.path.join(ROOT, "art_tests", "audio")
URL = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128"
# Documented cost: about 20 credits per second when the duration is set. Counted pessimistically.
CREDITS_PER_SECOND = 20
PROMPT_INFLUENCE = 0.5


def get_key() -> str:
    key = os.environ.get("ELEVENLABS_API_KEY", "")
    if not key and sys.platform == "win32":
        import winreg
        try:
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Environment") as reg:
                key = winreg.QueryValueEx(reg, "ELEVENLABS_API_KEY")[0]
        except OSError:
            key = ""
    return key


def load_json(path: str, default):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    return default


def estimate(sound: dict) -> int:
    return int(round(sound["duration"] * CREDITS_PER_SECOND)) * int(sound.get("variations", 1))


def generate(key: str, sound: dict, style: str, index: int) -> bytes:
    body = json.dumps({
        "text": f"{sound['prompt']}. {style}",
        "duration_seconds": sound["duration"],
        "prompt_influence": PROMPT_INFLUENCE,
        "model_id": "eleven_text_to_sound_v2",
    }).encode("utf-8")
    request = urllib.request.Request(URL, data=body, method="POST", headers={
        "xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
    with urllib.request.urlopen(request, timeout=120) as response:
        return response.read()


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--test", action="store_true", help="only sounds flagged test=true")
    parser.add_argument("--ids", nargs="*", default=[])
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--again", action="store_true", help="redo sounds already generated")
    parser.add_argument("--takes", type=int, default=1, help="generations per sound (default 1)")
    args = parser.parse_args()

    data = load_json(LIST_PATH, {})
    sounds = data["sounds"]
    style = data.get("style", "")
    state = load_json(STATE_PATH, {"credits_estimated": 0, "done": {}})

    if args.list or not (args.test or args.ids):
        for s in sounds:
            mark = "done" if s["id"] in state["done"] else "    "
            print(f"[{mark}] p{s['priority']} {s['id']:<16} {s['duration']:>4}s x{s.get('variations', 1)}  ~{estimate(s)} credits")
        print(f"Credits spent so far (estimate): {state['credits_estimated']} / 30000 per month")
        return 0

    chosen = [s for s in sounds if (args.test and s.get("test")) or s["id"] in args.ids]
    chosen = [s for s in chosen if args.again or s["id"] not in state["done"]]
    # One take per sound: variations are made later, after the dev validated the style.
    total = sum(int(round(s["duration"] * CREDITS_PER_SECOND)) * args.takes for s in chosen)
    print(f"{len(chosen)} sound(s), {args.takes} take(s) each, about {total} credits (upper estimate).")
    for s in chosen:
        print(f"  - {s['id']} ({s['duration']}s): {s['prompt']}")
    if args.dry_run or not chosen:
        return 0

    key = get_key()
    if not key:
        print("No ELEVENLABS_API_KEY found.")
        return 1
    os.makedirs(OUT_DIR, exist_ok=True)
    for s in chosen:
        for take in range(args.takes):
            name = s["id"] if args.takes == 1 else f"{s['id']}_t{take + 1}"
            try:
                audio = generate(key, s, style, take)
            except urllib.error.HTTPError as error:
                detail = error.read().decode("utf-8", "replace")[:300]
                print(f"FAILED {s['id']}: HTTP {error.code} {detail}")
                return 1
            with open(os.path.join(OUT_DIR, name + ".mp3"), "wb") as f:
                f.write(audio)
            state["credits_estimated"] += int(round(s["duration"] * CREDITS_PER_SECOND))
            state["done"][s["id"]] = {"file": name + ".mp3", "bytes": len(audio)}
            with open(STATE_PATH, "w", encoding="utf-8", newline="\n") as f:
                json.dump(state, f, indent=2)
            print(f"ok {name}.mp3 ({len(audio)} bytes)")
    print(f"Credits spent so far (estimate): {state['credits_estimated']} / 30000")
    return 0


if __name__ == "__main__":
    sys.exit(main())
