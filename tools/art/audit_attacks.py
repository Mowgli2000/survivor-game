"""Attack audit: for every attack of every phase of a final boss, plays it once with the hero standing still and the real
damage shapes drawn (--shapes), and writes a contact sheet of frames from the windup to the end of the volleys
(art_tests/audit/<boss>_p<phase>_a<index>_<key>.png). Usage: python tools/art/audit_attacks.py [boss ...]"""
import glob
import re
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "art_tests/audit"
GODOT = "C:/Program Files/Godot/Godot.exe"
BOSSES = ["shogun", "iron_boss_final", "silver_boss_final", "gold_boss_final", "obsidian_boss_final", "astral_boss_final"]
HP = [0.95, 0.5, 0.2]
FRAMES = 12


def read_kit(boss: str):
    text = (ROOT / "data/enemies" / (boss + ".tres")).read_text(encoding="utf-8")
    blocks = {m.group(1): m.group(2) for m in re.finditer(r'\[sub_resource type="Resource" id="(\w+)"\]\n(.*?)(?=\n\[|\Z)', text, re.S)}

    def number(block: str, key: str, default: float) -> float:
        m = re.search(r"^%s = ([\d.]+)" % key, block, re.M)
        return float(m.group(1)) if m else default

    phases = []
    for pid in sorted(k for k in blocks if k.startswith("Phase_")):
        refs = re.findall(r'SubResource\("(\w+)"\)', re.search(r"patterns = .*", blocks[pid]).group(0))
        phases.append([(ref, number(blocks[ref], "windup", 0.7), int(number(blocks[ref], "repeats", 1)),
                        number(blocks[ref], "repeat_interval", 0.3)) for ref in refs])
    return phases


def main() -> None:
    OUT.mkdir(exist_ok=True)
    tmp = Path(sys.argv[0]).resolve().parent / "_audit_frames"
    for boss in [a for a in sys.argv[1:]] or BOSSES:
        for p, attacks in enumerate(read_kit(boss)):
            for i, (key, windup, repeats, interval) in enumerate(attacks):
                name = "%s_p%d_a%d_%s" % (boss, p + 1, i, key.replace("P_", ""))
                if (OUT / (name + ".png")).exists():
                    continue
                lasts = 0.85 * windup + max(repeats - 1, 0) * interval + 0.6
                frames_dir = ROOT / "art_tests/_frames"
                for old in glob.glob(str(frames_dir / "*.png")):
                    Path(old).unlink()
                frames_dir.mkdir(exist_ok=True)
                subprocess.run([GODOT, "--path", str(ROOT), "--write-movie", str(frames_dir / "f.png"), "--fixed-fps", "30", "--resolution", "960x540",
                                "res://src/debug/capture.tscn", "--", "--time=%.1f" % (lasts + 0.4), "--boss=" + boss, "--bosshp=%.2f" % HP[min(p, 2)],
                                "--still", "--shapes", "--play=%d:%d" % (p, i), "--out=" + str(frames_dir / "last.png")],
                               capture_output=True, timeout=300)
                files = sorted(glob.glob(str(frames_dir / "f*.png")))
                if not files:
                    print("no frames", name, flush=True)
                    continue
                span = min(len(files) - 1, int(lasts * 30))
                picks = [int(6 + (span - 6) * k / (FRAMES - 1)) for k in range(FRAMES)]
                sheet = Image.new("RGB", (4 * 480, 3 * 270))
                for k, idx in enumerate(picks):
                    sheet.paste(Image.open(files[idx]).convert("RGB").resize((480, 270)), ((k % 4) * 480, (k // 4) * 270))
                sheet.save(OUT / (name + ".png"))
                print("done", name, "frames", len(files), flush=True)
    print("ALLDONE", flush=True)


if __name__ == "__main__":
    main()
