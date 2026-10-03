"""Writes the placeholder weapon and item icons (SVG, 128x128) to assets/icons/.

Style of the RGS_Dev character pack: thick black outline, flat light/grey fills,
one neon accent per icon (weapon color, or the color of the item's main stat).
Weapons are drawn in profile, barrel pointing right, centered: the same image is
the shop icon and the in-game sprite (rotated toward the target).
Usage: python tools/icons/make_icons.py
"""
import os

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "icons")
K = 'stroke="#000" stroke-width="6" stroke-linejoin="round" stroke-linecap="round"'
L = "#e8e8ee"
D = "#9a9aa6"
DK = "#5d5d6b"


def svg(body: str) -> str:
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" '
            'viewBox="0 0 128 128">\n' + body.strip() + "\n</svg>\n")


def item(accent: str, body: str) -> str:
    aura = f'<circle cx="64" cy="64" r="50" fill="{accent}" fill-opacity="0.16"/>\n'
    return aura + body


ICONS = {}

c = "#ffeb73"
ICONS["weapons/pulse"] = f'''
<rect x="18" y="46" width="56" height="40" rx="12" fill="{L}" {K}/>
<path d="M24 76 h44 v6 a6 6 0 0 1 -6 6 h-32 a6 6 0 0 1 -6 -6z" fill="{D}"/>
<rect x="30" y="54" width="22" height="8" rx="4" fill="{c}" {K}/>
<circle cx="90" cy="66" r="22" fill="{c}" fill-opacity="0.3"/>
<circle cx="88" cy="66" r="16" fill="{DK}" {K}/>
<circle cx="88" cy="66" r="9" fill="{c}" stroke="#fff8c4" stroke-width="3"/>
<path d="M106 54 l10 -6 M108 66 h12 M106 78 l10 6" stroke="{c}" stroke-width="5" stroke-linecap="round"/>
'''
c = "#ff33cc"
ICONS["weapons/katana"] = f'''
<path d="M50 70 L112 52 Q120 50 122 54 L56 80z" fill="{c}" fill-opacity="0.35" stroke="{c}" stroke-opacity="0.4" stroke-width="10" stroke-linejoin="round"/>
<path d="M50 70 L112 52 Q120 50 122 54 L56 80z" fill="#ffd6f4" {K}/>
<path d="M54 74 L116 54" stroke="{c}" stroke-width="5" stroke-linecap="round"/>
<rect x="40" y="58" width="10" height="34" rx="4" fill="{DK}" {K} transform="rotate(-16 45 75)"/>
<path d="M8 86 L42 76 L46 88 L12 98z" fill="{D}" {K}/>
<path d="M18 84 l4 12 M28 81 l4 12 M37 78 l3 11" stroke="#000" stroke-width="3"/>
'''
c = "#33f2ff"
ICONS["weapons/laser_pistol"] = f'''
<path d="M36 62 h30 l-6 34 h-20z" fill="{D}" {K}/>
<path d="M30 44 h62 q10 0 10 10 v14 q0 6 -6 6 h-66z" fill="{L}" {K}/>
<path d="M102 52 h14 v10 h-14z" fill="{c}" {K}/>
<rect x="40" y="50" width="44" height="8" rx="3" fill="{c}"/>
<circle cx="122" cy="57" r="6" fill="{c}" fill-opacity="0.6"/>
<path d="M66 74 q8 4 4 12 h-6" fill="none" stroke="#000" stroke-width="5"/>
'''
c = "#fff233"
ICONS["weapons/shuriken"] = f'''
<path d="M64 10 L76 52 L118 64 L76 76 L64 118 L52 76 L10 64 L52 52z" fill="{c}" fill-opacity="0.3" stroke="{c}" stroke-opacity="0.35" stroke-width="12" stroke-linejoin="round"/>
<path d="M64 10 L76 52 L118 64 L76 76 L64 118 L52 76 L10 64 L52 52z" fill="{L}" {K}/>
<path d="M64 18 L70 56 L64 64z M110 64 L72 70 L64 64z M64 110 L58 72 L64 64z M18 64 L56 58 L64 64z" fill="{D}"/>
<path d="M64 16 L64 40 M112 64 L88 64 M64 112 L64 88 M16 64 L40 64" stroke="{c}" stroke-width="4" stroke-linecap="round"/>
<circle cx="64" cy="64" r="11" fill="{DK}" {K}/>
<circle cx="64" cy="64" r="4" fill="{c}"/>
'''
c = "#8cff4d"
ICONS["weapons/smg"] = f'''
<path d="M8 58 l20 -6 v22 l-20 -4z" fill="{D}" {K}/>
<rect x="56" y="70" width="16" height="34" rx="3" fill="{D}" {K} transform="rotate(8 64 87)"/>
<path d="M34 70 h14 l-4 22 h-12z" fill="{DK}" {K}/>
<rect x="26" y="46" width="66" height="26" rx="6" fill="{L}" {K}/>
<rect x="92" y="52" width="26" height="12" rx="3" fill="{DK}" {K}/>
<path d="M32 56 h52" stroke="{c}" stroke-width="6" stroke-linecap="round"/>
<path d="M118 52 v12" stroke="{c}" stroke-width="5" stroke-linecap="round"/>
'''
c = "#ff8026"
ICONS["weapons/bazooka"] = f'''
<path d="M44 74 h14 l-4 24 h-12z" fill="{DK}" {K}/>
<rect x="34" y="34" width="22" height="14" rx="3" fill="{DK}" {K}/>
<rect x="10" y="46" width="90" height="30" rx="8" fill="{L}" {K}/>
<path d="M100 40 h14 q6 0 6 6 v30 q0 6 -6 6 h-14z" fill="{D}" {K}/>
<path d="M114 51 q10 10 0 20" fill="{c}" stroke="#000" stroke-width="5"/>
<path d="M18 55 h70" stroke="{c}" stroke-width="6" stroke-linecap="round"/>
<path d="M18 67 h40" stroke="{D}" stroke-width="5" stroke-linecap="round"/>
'''

ICONS["items/sharpened_edge"] = item("#ff4d5e", f'''
<path d="M30 98 L92 24 Q104 18 102 32 L46 104z" fill="{L}" {K}/>
<path d="M98 24 Q104 22 101 32 L50 98" fill="none" stroke="#ff4d5e" stroke-width="6" stroke-linecap="round"/>
<path d="M22 92 l20 18" stroke="#000" stroke-width="16" stroke-linecap="round"/>
<path d="M22 92 l20 18" stroke="{DK}" stroke-width="6" stroke-linecap="round"/>
''')
ICONS["items/neon_coil"] = item("#ffd23f", f'''
<rect x="54" y="12" width="20" height="12" rx="3" fill="{DK}" {K}/>
<rect x="38" y="22" width="52" height="84" rx="10" fill="{L}" {K}/>
<path d="M46 40 q18 -10 36 0 M46 56 q18 -10 36 0 M46 72 q18 -10 36 0 M46 88 q18 -10 36 0" fill="none" stroke="#ffd23f" stroke-width="7" stroke-linecap="round"/>
''')
ICONS["items/kevlar_weave"] = item("#4da6ff", f'''
<path d="M40 20 L52 30 h24 L88 20 L108 34 L98 58 L94 108 H34 L30 58 L20 34z" fill="{L}" {K}/>
<path d="M38 62 l52 40 M50 54 l46 36 M90 62 l-52 40 M78 54 l-46 36" stroke="#4da6ff" stroke-width="4"/>
<path d="M52 30 q12 14 24 0" fill="none" stroke="#000" stroke-width="5"/>
''')
ICONS["items/nano_stims"] = item("#a6ff4d", f'''
<g transform="rotate(-40 64 64)">
<path d="M64 90 v26" stroke="#000" stroke-width="5" stroke-linecap="round"/>
<rect x="60" y="6" width="8" height="14" fill="{DK}" {K}/>
<rect x="50" y="26" width="28" height="64" rx="6" fill="{L}" {K}/>
<rect x="56" y="50" width="16" height="34" rx="3" fill="#a6ff4d"/>
<rect x="44" y="18" width="40" height="10" rx="3" fill="{D}" {K}/>
</g>
''')
ICONS["items/exo_knees"] = item("#4de6ff", f'''
<path d="M44 14 h24 l4 46 h-30z" fill="{L}" {K}/>
<path d="M44 66 h30 l-6 48 h-22z" fill="{L}" {K}/>
<circle cx="58" cy="63" r="14" fill="{DK}" {K}/>
<circle cx="58" cy="63" r="6" fill="#4de6ff"/>
<path d="M78 24 v28 M80 74 l-4 30" stroke="#4de6ff" stroke-width="6" stroke-linecap="round"/>
''')
ICONS["items/magnet_glove"] = item("#3dffc5", f'''
<path d="M30 30 v38 a34 34 0 0 0 68 0 v-38 h-22 v38 a12 12 0 0 1 -24 0 v-38z" fill="{L}" {K}/>
<rect x="30" y="20" width="22" height="18" fill="#3dffc5" {K}/>
<rect x="76" y="20" width="22" height="18" fill="#3dffc5" {K}/>
<path d="M16 12 l7 8 M112 12 l-7 8 M64 2 v10" stroke="#3dffc5" stroke-width="5" stroke-linecap="round"/>
''')
ICONS["items/targeting_chip"] = item("#ff8c1a", f'''
<path d="M40 30 v-10 M56 30 v-10 M72 30 v-10 M88 30 v-10 M40 98 v10 M56 98 v10 M72 98 v10 M88 98 v10 M30 40 h-10 M30 56 h-10 M30 72 h-10 M30 88 h-10 M98 40 h10 M98 56 h10 M98 72 h10 M98 88 h10" stroke="#000" stroke-width="5" stroke-linecap="round"/>
<rect x="30" y="30" width="68" height="68" rx="8" fill="{DK}" {K}/>
<circle cx="64" cy="64" r="18" fill="none" stroke="#ff8c1a" stroke-width="5"/>
<path d="M64 40 v14 M64 74 v14 M40 64 h14 M74 64 h14" stroke="#ff8c1a" stroke-width="5" stroke-linecap="round"/>
<circle cx="64" cy="64" r="4" fill="#ff8c1a"/>
''')
ICONS["items/heavy_core"] = item("#5cff8a", f'''
<circle cx="64" cy="64" r="40" fill="{D}" {K}/>
<path d="M28 50 h72 M28 78 h72" stroke="#000" stroke-width="5"/>
<circle cx="64" cy="64" r="16" fill="#5cff8a" {K}/>
<path d="M57 64 h14 M64 57 v14" stroke="#000" stroke-width="5" stroke-linecap="round"/>
''')
ICONS["items/focus_lens"] = item("#b366ff", f'''
<path d="M84 84 l24 24" stroke="#000" stroke-width="16" stroke-linecap="round"/>
<path d="M84 84 l24 24" stroke="{DK}" stroke-width="7" stroke-linecap="round"/>
<circle cx="54" cy="54" r="34" fill="{L}" {K}/>
<circle cx="54" cy="54" r="24" fill="#b366ff" stroke="#000" stroke-width="4"/>
<path d="M42 44 q6 -8 16 -8" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>
''')
ICONS["items/shock_absorber"] = item("#4da6ff", f'''
<rect x="57" y="36" width="14" height="58" fill="{DK}" stroke="#000" stroke-width="4"/>
<path d="M44 46 h40 l-40 12 h40 l-40 12 h40 l-40 12 h40" fill="none" stroke="#000" stroke-width="12" stroke-linejoin="round" stroke-linecap="round"/>
<path d="M44 46 h40 l-40 12 h40 l-40 12 h40 l-40 12 h40" fill="none" stroke="#4da6ff" stroke-width="5" stroke-linejoin="round" stroke-linecap="round"/>
<rect x="46" y="12" width="36" height="26" rx="5" fill="{D}" {K}/>
<rect x="46" y="90" width="36" height="26" rx="5" fill="{D}" {K}/>
''')
ICONS["items/ronin_seal"] = item("#ff4d5e", f'''
<circle cx="64" cy="64" r="42" fill="{L}" {K}/>
<circle cx="64" cy="64" r="32" fill="none" stroke="#ff4d5e" stroke-width="5"/>
<path d="M50 44 h28 M64 44 v40 M48 62 h32 M52 84 l12 -10 l12 10" fill="none" stroke="#ff4d5e" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/>
''')
ICONS["items/split_barrel"] = item("#cfe8ff", f'''
<path d="M50 56 L108 34 l6 14 l-56 18z" fill="{L}" {K}/>
<path d="M50 74 L108 96 l6 -14 l-56 -18z" fill="{L}" {K}/>
<rect x="14" y="50" width="42" height="30" rx="6" fill="{D}" {K}/>
<circle cx="113" cy="41" r="6" fill="#cfe8ff" stroke="#000" stroke-width="4"/>
<circle cx="113" cy="89" r="6" fill="#cfe8ff" stroke="#000" stroke-width="4"/>
''')
ICONS["items/plasma_ring"] = item("#ff4dd2", f'''
<circle cx="64" cy="64" r="38" fill="none" stroke="#000" stroke-width="26"/>
<circle cx="64" cy="64" r="38" fill="none" stroke="{L}" stroke-width="14"/>
<circle cx="64" cy="64" r="38" fill="none" stroke="#ff4dd2" stroke-width="5" stroke-dasharray="14 10"/>
<circle cx="64" cy="26" r="9" fill="#ff4dd2" {K}/>
''')
ICONS["items/oni_mask"] = item("#ff8c1a", f'''
<path d="M32 32 L22 8 L48 24z M96 32 L106 8 L80 24z" fill="{L}" {K}/>
<path d="M28 34 q36 -22 72 0 v36 q0 40 -36 46 q-36 -6 -36 -46z" fill="#e8504d" {K}/>
<path d="M40 54 l18 8 l-18 6z M88 54 l-18 8 l18 6z" fill="#ff8c1a" stroke="#000" stroke-width="4" stroke-linejoin="round"/>
<path d="M44 90 q20 -12 40 0 v10 h-40z" fill="{L}" {K}/>
<path d="M54 89 v11 M64 86 v14 M74 89 v11" stroke="#000" stroke-width="3"/>
''')
ICONS["items/phantom_drive"] = item("#ffd23f", f'''
<path d="M4 50 h14 M2 64 h12 M4 78 h14" stroke="#ffd23f" stroke-width="5" stroke-linecap="round"/>
<circle cx="64" cy="64" r="38" fill="{D}" {K}/>
<circle cx="64" cy="64" r="26" fill="{DK}" stroke="#000" stroke-width="4"/>
<path d="M64 64 L64 40 Q78 44 80 56z M64 64 L88 64 Q84 78 72 80z M64 64 L64 88 Q50 84 48 72z M64 64 L40 64 Q44 50 56 48z" fill="#ffd23f" stroke="#000" stroke-width="3" stroke-linejoin="round"/>
<circle cx="64" cy="64" r="6" fill="{L}" stroke="#000" stroke-width="3"/>
''')

if __name__ == "__main__":
    for key, body in ICONS.items():
        path = os.path.join(ROOT, key + ".svg")
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(svg(body))
    print(f"{len(ICONS)} icons written")
