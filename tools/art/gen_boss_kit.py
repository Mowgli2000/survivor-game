"""Generates the art of one final boss of the seals 2-6 from its brief in boss_kits.py.
Usage:
  python tools/art/gen_boss_kit.py <boss> sheets [job ...]   character sheets (default: windup idle walk entrance_a phase_a death)
  python tools/art/gen_boss_kit.py <boss> chain <job> <png>   a chained sheet (strike, entrance_b, phase_b) from the last pose png
  python tools/art/gen_boss_kit.py <boss> fx [fx1 ...]        the five painted attack effects (default: all)
2 candidates per job in art_tests/boss_anim/<boss>/<job>_1.png / _2.png (effects: art_tests/vfx_hd/<boss>_<fx>_1.png / _2.png).
Cut by tools/art/make_boss_anim.py (sheets) and baked by tools/art/bake_vfx.py (effects)."""
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from boss_kits import FX_GRID, FX_STYLE, FX_TIMELINE, GRID, KITS  # noqa: E402

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_SHEETS = ["windup", "idle", "walk", "entrance_a", "phase_a", "death"]
CHAINED = ["strike", "entrance_b", "phase_b"]


def run(command: list, label: str) -> None:
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    print(label, result.returncode, result.stderr[-200:].replace("\n", " "), flush=True)


def sheets(boss: str, jobs: list) -> None:
    kit = KITS[boss]
    out = ROOT / "art_tests/boss_anim" / boss
    out.mkdir(parents=True, exist_ok=True)
    for job in jobs:
        if (out / (job + "_2.png")).exists():
            continue
        prompt = kit["look"] + kit["motion"] + GRID + kit[job]
        run([sys.executable, "tools/art/gen_image.py", "--out", "art_tests/boss_anim/%s/%s.png" % (boss, job), "--n", "2",
             "--size", "2048x2048", "--quality", "high", "--image", kit["ref"], "--prompt", prompt], "%s %s" % (boss, job))


def chain(boss: str, job: str, last_pose: str) -> None:
    kit = KITS[boss]
    out = ROOT / "art_tests/boss_anim" / boss
    if (out / (job + "_2.png")).exists():
        return
    prompt = kit["look"] + kit["motion"] + GRID + kit[job]
    run([sys.executable, "tools/art/gen_image.py", "--out", "art_tests/boss_anim/%s/%s.png" % (boss, job), "--n", "2",
         "--size", "2048x2048", "--quality", "high", "--image", kit["ref"], last_pose, "--prompt", prompt], "%s %s" % (boss, job))


def fx(boss: str, names: list) -> None:
    kit = KITS[boss]
    out = ROOT / "art_tests/vfx_hd"
    refs = ["art_tests/vfx_hd/knight_flame_1.png", "art_tests/vfx_hd/explosion_fire_2.png"]
    for name in names or list(kit["fx"]):
        label = "%s_%s" % (boss, name)
        if (out / (label + "_2.png")).exists():
            continue
        prompt = FX_STYLE + FX_GRID + kit["fx"][name] + FX_TIMELINE
        run([sys.executable, "tools/art/gen_image.py", "--out", "art_tests/vfx_hd/%s.png" % label, "--n", "2", "--size", "2048x1536",
             "--quality", "high", "--opaque", "--image", *refs, "--prompt", prompt], label)


def main() -> None:
    boss, mode = sys.argv[1], sys.argv[2]
    rest = sys.argv[3:]
    if mode == "sheets":
        sheets(boss, rest or DEFAULT_SHEETS)
    elif mode == "chain":
        chain(boss, rest[0], rest[1])
    elif mode == "fx":
        fx(boss, rest)
    print("ALLDONE", boss, mode, flush=True)


if __name__ == "__main__":
    main()
