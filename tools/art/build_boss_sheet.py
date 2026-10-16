"""Builds assets/sprites/<boss>_anim.png + <boss>_attack.tres of a final boss from its chosen AI sheets in
art_tests/boss_anim/<boss>/ (the same selection for every boss of the seals 2-6). Usage:
  python tools/art/build_boss_sheet.py <boss> [--height 448]
Then: python tools/art/write_boss_data.py <boss> and the Godot --import."""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
ATTACK = "attack=windup:1@1-9,11,13,15,16+strike:1@3,4,5,7,8,11,14,16"
PARTS = [ATTACK, "entrance=entrance_a:1+entrance_b:1", "phase=phase_a:1+phase_b:1", "death=death:1", "idle=idle:1", "walk=walk:1"]
FPS = {"attack": 24, "entrance": 14, "phase": 14, "death": 8, "idle": 8, "walk": 12}


def main() -> None:
    boss = sys.argv[1]
    height = sys.argv[sys.argv.index("--height") + 1] if "--height" in sys.argv else "448"
    out = "assets/sprites/%s_anim" % boss
    result = subprocess.run([sys.executable, "tools/art/make_boss_anim.py", "--boss", boss, "--out", out, "--height", height,
                             "--columns", "8", *PARTS], cwd=ROOT, capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        raise SystemExit(result.stderr)
    cell = re.search(r"cell (\d+) x (\d+)", result.stdout)
    animations = {name: (int(first), int(frames)) for name, first, frames in re.findall(r"(\w+): first (\d+), frames (\d+)", result.stdout)}
    lines = ['&"%s": Vector3i(%d, %d, %d)' % (name, first, frames, FPS[name]) for name, (first, frames) in sorted(animations.items())]
    text = ('[gd_resource type="Resource" script_class="SpriteSheet" format=3]\n\n'
            '[ext_resource type="Script" path="res://src/core/sprite_sheet.gd" id="1_sheet"]\n'
            '[ext_resource type="Texture2D" path="res://assets/sprites/%s_anim.png" id="2_tex"]\n\n'
            '[resource]\nscript = ExtResource("1_sheet")\ntexture = ExtResource("2_tex")\ncell_size = Vector2i(%s, %s)\ncolumns = 8\n'
            'animations = Dictionary[StringName, Vector3i]({\n%s\n})\n') % (boss, cell.group(1), cell.group(2), ",\n".join(lines))
    (ROOT / "assets/sprites" / (boss + "_attack.tres")).write_text(text, encoding="utf-8", newline="\n")
    # Compressed VRAM texture like the Demon Knight's (big sheet), written once the import file exists.
    print(text)


if __name__ == "__main__":
    main()
