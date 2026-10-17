"""Finale attacks of the final bosses (phase 3): two attacks of the kit played together (ComboPattern). Parts share the
windup and the repeat interval of the combo, so every warning is exactly the attack that follows it.
boss: {combo key: (props of the combo, [(attack key, props of that part)])}"""


def timing(windup: float, repeats: int, interval: float, recovery: float) -> str:
    text = "windup = %s\nrepeats = %d\n" % (windup, repeats)
    if repeats > 1:
        text += "repeat_interval = %s\n" % interval
    return text + "recovery = %s\n" % recovery


COMBOS = {
    "iron_boss_final": {"ruin": (timing(1.2, 3, 0.6, 1.6), [
        ("crack", timing(1.2, 3, 0.6, 1.6) + "projectile_damage = 14.0\nrays = 8\n"),
        ("pillar", timing(1.2, 3, 0.6, 1.6) + "projectile_damage = 14.0\n")])},
    "silver_boss_final": {"whiteout": (timing(1.0, 5, 0.55, 1.6), [
        ("wall", timing(1.0, 2, 0.55, 1.6) + "projectile_damage = 16.0\n"),
        ("hail", timing(1.0, 5, 0.55, 1.6) + "projectile_damage = 12.0\n")])},
    "gold_boss_final": {"inferno": (timing(1.0, 2, 0.7, 1.6), [
        ("checker", timing(1.0, 2, 0.7, 1.6) + "projectile_damage = 16.0\n"),
        ("wings", timing(1.0, 1, 0.0, 1.6) + "projectile_damage = 20.0\n")])},
    "obsidian_boss_final": {"brood": (timing(1.0, 5, 0.5, 1.6), [
        ("pools", timing(1.0, 5, 0.5, 1.6) + "projectile_damage = 6.0\n"),
        ("cage", timing(1.0, 2, 0.5, 1.6) + "projectile_damage = 16.0\n")])},
    "astral_boss_final": {"cataclysm": (timing(1.5, 1, 0.0, 1.8), [
        ("meteors", timing(1.5, 1, 0.0, 1.8) + "projectile_damage = 24.0\n"),
        ("tail", timing(1.5, 1, 0.0, 1.8) + "projectile_damage = 20.0\ninner = 260.0\n")])},
}
