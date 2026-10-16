"""Writes data/enemies/<boss>.tres of the final bosses of the seals 2-6: their own attack kit (patterns in
src/enemies/boss/), phases, and, once the art exists, the painted effects (data/vfx/<boss>_fx<n>.tres) and the
animation sheet (assets/sprites/<boss>_attack.tres). Usage: python tools/art/write_boss_data.py [boss ...]
Run again after baking the art: the lines of art that does not exist yet are left out."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# Attack animation timing shared by every boss (windup poses 1-9, 11, 13, 15, 16 then strike poses 3-10: 21 frames).
ATTACK_WEIGHTS = "0.9, 0.9, 0.9, 0.35, 0.35, 0.35, 0.35, 0.35, 0.7, 0.9, 0.9, 0.9, 0.9, 0.15, 0.25, 0.3, 0.3, 0.3, 0.4, 0.4, 0.4"
STRIKE_FRAME = 14

SCRIPTS = {
    "crack": "crack_rays_pattern", "pillar": "pillar_drop_pattern", "rings": "shock_rings_pattern", "seal": "rune_seal_pattern",
    "whirl": "blade_whirl_pattern",
    "spikes": "ice_spike_line_pattern", "wall": "frost_wall_pattern", "patch": "freezing_patch_pattern",
    "club": "club_shockwave_pattern", "hail": "hail_pattern",
    "beam": "fire_beam_pattern", "checker": "flame_checker_pattern", "chains": "chain_lash_pattern", "wings": "wing_blast_pattern",
    "pools": "venom_pools_pattern", "eggs": "egg_clutch_pattern", "net": "web_net_pattern", "cage": "leg_cage_pattern",
    "spit": "venom_spit_pattern",
    "breath": "fire_breath_pattern", "storm": "storm_front_pattern", "meteors": "meteor_shower_pattern", "tail": "tail_sweep_pattern",
    "flyby": "dragon_flyby_pattern", "summon": "summon_pattern",
}

# pattern key: (properties, fx number or 0)
BOSSES = {
    "iron_boss_final": {
        "color": "Color(0.2, 0.9, 1, 1)", "style": 21, "scale": 1.32,
        "summon": "iron_runner",
        "patterns": {
            "crack": ("windup = 1.0\nrepeats = 2\nrepeat_interval = 0.7\nrecovery = 1.3\nprojectile_damage = 16.0\nrays = 6\n", 1),
            "pillar": ("windup = 0.9\nrepeats = 4\nrepeat_interval = 0.6\nrecovery = 1.3\nprojectile_damage = 16.0\n", 2),
            "rings": ("windup = 1.0\nrepeats = 4\nrepeat_interval = 0.45\nrecovery = 1.4\nprojectile_damage = 14.0\n", 3),
            "seal": ("windup = 1.4\nrecovery = 1.4\nprojectile_damage = 24.0\n", 4),
            "whirl": ("windup = 0.8\nrepeats = 4\nrepeat_interval = 0.4\nrecovery = 1.2\nprojectile_damage = 12.0\n", 5),
            "summon": ("windup = 0.8\nrecovery = 1.0\ncount = 4\n", 0),
        },
        "phases": [(1.0, 1.0, ["crack", "pillar"]), (0.6, 1.15, ["rings", "whirl", "crack", "seal"]),
                   (0.3, 1.3, ["seal", "pillar", "rings", "summon", "whirl"])],
    },
    "silver_boss_final": {
        "color": "Color(0.45, 0.9, 1.0, 1)", "style": 18, "scale": 1.3,
        "summon": "silver_runner",
        "patterns": {
            "spikes": ("windup = 0.9\nrepeats = 7\nrepeat_interval = 0.12\nrecovery = 1.3\nprojectile_damage = 15.0\nspikes = 7\n", 1),
            "wall": ("windup = 1.0\nrepeats = 2\nrepeat_interval = 0.55\nrecovery = 1.3\nprojectile_damage = 18.0\n", 3),
            "patch": ("windup = 0.9\nrepeats = 6\nrepeat_interval = 0.5\nrecovery = 1.3\nprojectile_damage = 8.0\n", 4),
            "club": ("windup = 1.1\nrecovery = 1.3\nprojectile_damage = 24.0\n", 2),
            "hail": ("windup = 0.9\nrepeats = 5\nrepeat_interval = 0.55\nrecovery = 1.3\nprojectile_damage = 14.0\n", 5),
            "summon": ("windup = 0.8\nrecovery = 1.0\ncount = 4\n", 0),
        },
        "phases": [(1.0, 1.0, ["spikes", "club"]), (0.6, 1.15, ["wall", "hail", "patch", "spikes"]),
                   (0.3, 1.3, ["patch", "club", "wall", "summon", "hail"])],
    },
    "gold_boss_final": {
        "color": "Color(1.0, 0.3, 0.2, 1)", "style": 19, "scale": 1.29,
        "summon": "gold_kamikaze",
        "patterns": {
            "beam": ("windup = 1.0\nrepeats = 12\nrepeat_interval = 0.13\nrecovery = 1.4\nprojectile_damage = 10.0\n", 4),
            "checker": ("windup = 1.0\nrepeats = 2\nrepeat_interval = 0.7\nrecovery = 1.3\nprojectile_damage = 18.0\n", 1),
            "chains": ("windup = 0.9\nrepeats = 3\nrepeat_interval = 0.35\nrecovery = 1.2\nprojectile_damage = 16.0\n", 3),
            "wings": ("windup = 1.0\nrecovery = 1.3\nprojectile_damage = 22.0\n", 2),
            "summon": ("windup = 0.8\nrecovery = 1.0\ncount = 4\n", 0),
        },
        "phases": [(1.0, 1.0, ["checker", "chains"]), (0.6, 1.15, ["beam", "wings", "chains", "checker"]),
                   (0.3, 1.3, ["beam", "wings", "summon", "checker", "chains"])],
    },
    "obsidian_boss_final": {
        "color": "Color(0.6, 1.0, 0.3, 1)", "style": 20, "scale": 1.4,
        "summon": "obsidian_runner",
        "patterns": {
            "pools": ("windup = 1.0\nrepeats = 5\nrepeat_interval = 0.5\nrecovery = 1.3\nprojectile_damage = 7.0\n", 1),
            "eggs": ("windup = 1.2\nrecovery = 1.4\nprojectile_damage = 14.0\nlarva = ExtResource(\"larva\")\n", 4),
            "net": ("windup = 1.0\nrecovery = 1.3\nprojectile_damage = 16.0\n", 3),
            "cage": ("windup = 1.0\nrepeats = 2\nrepeat_interval = 0.6\nrecovery = 1.3\nprojectile_damage = 18.0\n", 5),
            "spit": ("windup = 0.8\nrepeats = 6\nrepeat_interval = 0.22\nrecovery = 1.2\nprojectile_damage = 9.0\n", 0),
        },
        "extra": {"larva": "obsidian_runner"},
        "phases": [(1.0, 1.0, ["pools", "spit"]), (0.6, 1.15, ["net", "eggs", "cage", "spit"]),
                   (0.3, 1.3, ["cage", "pools", "eggs", "net", "spit"])],
    },
    "astral_boss_final": {
        "color": "Color(1.0, 0.35, 0.2, 1)", "style": 19, "scale": 1.32,
        "summon": "astral_runner",
        "patterns": {
            "breath": ("windup = 1.1\nrepeats = 9\nrepeat_interval = 0.11\nrecovery = 1.5\nprojectile_damage = 9.0\n", 1),
            "storm": ("windup = 1.0\nrepeats = 8\nrepeat_interval = 0.28\nrecovery = 1.3\nprojectile_damage = 16.0\n", 3),
            "meteors": ("windup = 1.5\nrecovery = 1.5\nprojectile_damage = 26.0\n", 4),
            "tail": ("windup = 0.9\nrecovery = 1.3\nprojectile_damage = 22.0\n", 5),
            "flyby": ("windup = 0.9\nrecovery = 1.2\n", 0),
        },
        "phases": [(1.0, 1.0, ["breath", "storm"]), (0.6, 1.15, ["flyby", "tail", "meteors", "breath"]),
                   (0.3, 1.3, ["meteors", "storm", "tail", "flyby", "breath"])],
    },
}


def write(boss: str) -> None:
    spec = BOSSES[boss]
    old = (ROOT / "data/enemies" / (boss + ".tres")).read_text(encoding="utf-8")
    max_hp = [line for line in old.splitlines() if line.startswith("max_hp = ")][0]
    sheet = ROOT / "assets/sprites" / (boss + "_attack.tres")
    exts, subs = [], []
    ext_ids = {}

    def ext(path: str, kind: str, key: str) -> str:
        if key not in ext_ids:
            ext_ids[key] = key
            exts.append('[ext_resource type="%s" path="%s" id="%s"]' % (kind, path, key))
        return key

    ext("res://src/enemies/enemy_data.gd", "Script", "1_enemy")
    ext("res://src/enemies/boss/boss_phase.gd", "Script", "2_phase")
    ext("res://src/enemies/boss/boss_pattern.gd", "Script", "7_pattern")
    ext("res://data/chests/big.tres", "Resource", "c_chest")
    used = [key for _, _, keys in spec["phases"] for key in keys]
    for key in dict.fromkeys(used):
        props, fx = spec["patterns"][key]
        script = SCRIPTS[key]
        ext("res://src/enemies/boss/%s.gd" % script, "Script", "s_" + key)
        lines = ['script = ExtResource("s_%s")' % key]
        if key == "summon":
            ext("res://data/enemies/%s.tres" % spec["summon"], "Resource", "m_summon")
            lines.append('enemy = ExtResource("m_summon")')
        if fx and (ROOT / "data/vfx" / ("%s_fx%d.tres" % (boss, fx))).exists():
            ext("res://data/vfx/%s_fx%d.tres" % (boss, fx), "Resource", "v_%s" % key)
            lines.append('effect = ExtResource("v_%s")' % key)
        if "larva" in props:
            ext("res://data/enemies/%s.tres" % spec["extra"]["larva"], "Resource", "larva")
        subs.append('[sub_resource type="Resource" id="P_%s"]\n%s\n%s' % (key, "\n".join(lines), props))
    phase_ids = []
    for i, (ratio, speed, keys) in enumerate(spec["phases"]):
        refs = ", ".join('SubResource("P_%s")' % key for key in keys)
        subs.append('[sub_resource type="Resource" id="Phase_%d"]\nscript = ExtResource("2_phase")\nhp_ratio = %s\n'
                    'patterns = Array[ExtResource("7_pattern")]([%s])\nspeed_multiplier = %s\n' % (i + 1, ratio, refs, speed))
        phase_ids.append('SubResource("Phase_%d")' % (i + 1))
    body = ["[resource]", 'script = ExtResource("1_enemy")', 'id = &"%s"' % boss, 'name_key = "ENEMY_%s"' % boss.upper(), "boss = true",
            max_hp, "speed = 75.0", "contact_damage = 30.0", "armor = 8.0", "radius = 48.0", "knockback_taken = 0.0", "xp_value = 0",
            "color = %s" % spec["color"], "shape_sides = 8", 'sprite_id = &"%s"' % boss, "sprite_scale = 1.15"]
    if sheet.exists():
        ext("res://assets/sprites/%s_attack.tres" % boss, "Resource", "9_attack")
        body += ['attack_sheet = ExtResource("9_attack")', "attack_scale = %s" % spec["scale"],
                 "attack_frame_weights = PackedFloat32Array(%s)" % ATTACK_WEIGHTS, "attack_strike_frame = %d" % STRIKE_FRAME]
    body += ['phases = Array[ExtResource("2_phase")]([%s])' % ", ".join(phase_ids), "projectile_style = %d" % spec["style"],
             'chest = ExtResource("c_chest")']
    text = '[gd_resource type="Resource" script_class="EnemyData" format=3]\n\n' + "\n".join(exts) + "\n\n" + "\n".join(subs) + "\n" + "\n".join(body) + "\n"
    (ROOT / "data/enemies" / (boss + ".tres")).write_text(text, encoding="utf-8", newline="\n")
    print("written", boss)


if __name__ == "__main__":
    for name in sys.argv[1:] or list(BOSSES):
        write(name)
