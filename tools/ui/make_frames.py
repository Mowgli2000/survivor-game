"""Writes the 9-slice UI frames and ornaments of the "Azure Crystal" theme (T3) as SVG.

Frames are drawn in light, near-white lines so that UiTheme can tint them with the accent
color (StyleBoxTexture.modulate_color); the dark fill darkens with the tint.
Usage: python tools/ui/make_frames.py   then   Godot --headless -s res://tools/ui/bake_frames.gd
Output: assets_src/ui_frames/*.svg  (baked to assets/ui/frames/*.png)
"""
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets_src", "ui_frames")

LINE = "#eaf8ff"
GOLD = "#f0cd7c"
FILL_TOP = "#0c1b44"
FILL_BOT = "#050d26"


def chamfer(w: float, h: float, inset: float, cut: float) -> str:
    i, c = inset, cut
    pts = [(i + c, i), (w - i - c, i), (w - i, i + c), (w - i, h - i - c),
           (w - i - c, h - i), (i + c, h - i), (i, h - i - c), (i, i + c)]
    return "M" + " L".join("%.1f %.1f" % p for p in pts) + " Z"


def svg(w: int, h: int, body: str, defs: str = "") -> str:
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">'
            '<defs>%s</defs>%s</svg>\n' % (w, h, w, h, defs, body))


def grad(gid: str, top: str, bot: str, ta: float = 1.0, ba: float = 1.0) -> str:
    return ('<linearGradient id="%s" x1="0" y1="0" x2="0" y2="1">'
            '<stop offset="0" stop-color="%s" stop-opacity="%.2f"/>'
            '<stop offset="1" stop-color="%s" stop-opacity="%.2f"/></linearGradient>' % (gid, top, ta, bot, ba))


def corners(w: int, h: int, group: str) -> str:
    """The same top-left corner group mirrored to the four corners."""
    return ('<g>%s</g><g transform="translate(%d,0) scale(-1,1)">%s</g>'
            '<g transform="translate(0,%d) scale(1,-1)">%s</g>'
            '<g transform="translate(%d,%d) scale(-1,-1)">%s</g>' % (group, w, group, h, group, w, h, group))


def diamond(cx: float, cy: float, r: float, fill: str, stroke: str = "none", sw: float = 1.0) -> str:
    return ('<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="%s" stroke="%s" stroke-width="%.1f"/>'
            % (cx, cy - r, cx + r, cy, cx, cy + r, cx - r, cy, fill, stroke, sw))


def glow_lines(path: str, color: str, width: float, alpha: float) -> str:
    """Soft glow without filters: stacked wide, faint strokes."""
    out = ""
    for k, a in ((4.0, 0.05), (2.6, 0.08), (1.6, 0.13)):
        out += ('<path d="%s" fill="none" stroke="%s" stroke-width="%.1f" stroke-opacity="%.2f" '
                'stroke-linejoin="round"/>' % (path, color, width * k, a * alpha))
    return out


def panel(size: int = 192, cut: int = 24, alpha: float = 0.95, bracket: bool = True) -> str:
    i = 7
    shape = chamfer(size, size, i, cut)
    body = '<path d="%s" fill="url(#f)"/>' % shape
    body += glow_lines(shape, LINE, 3.0, 1.0)
    body += '<path d="%s" fill="none" stroke="%s" stroke-width="2.4" stroke-linejoin="round"/>' % (shape, LINE)
    body += ('<path d="%s" fill="none" stroke="%s" stroke-opacity="0.38" stroke-width="1.2" stroke-linejoin="round"/>'
             % (chamfer(size, size, i + 7, cut - 4), LINE))
    if bracket:
        c = cut
        mid = i + c / 2
        corner = ('<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f" fill="none" stroke="%s" stroke-width="4" '
                  'stroke-linecap="round" stroke-linejoin="round"/>'
                  % (i, i + c + 20, i, i + c, i + c, i, i + c + 20, i, GOLD))
        corner += diamond(mid, mid, 5.5, "#cdf3ff", GOLD, 1.6)
        corner += diamond(i + c + 20, i, 2.4, GOLD) + diamond(i, i + c + 20, 2.4, GOLD)
        body += corners(size, size, corner)
    return svg(size, size, body, grad("f", FILL_TOP, FILL_BOT, alpha, alpha))


def card(size: int = 128, cut: int = 14, alpha: float = 0.92, ticks: bool = True) -> str:
    i = 4
    shape = chamfer(size, size, i, cut)
    body = '<path d="%s" fill="url(#f)"/>' % shape
    body += glow_lines(shape, LINE, 2.0, 0.9)
    body += '<path d="%s" fill="none" stroke="%s" stroke-width="2" stroke-linejoin="round"/>' % (shape, LINE)
    body += ('<path d="%s" fill="none" stroke="%s" stroke-opacity="0.25" stroke-width="1" stroke-linejoin="round"/>'
             % (chamfer(size, size, i + 5, cut - 3), LINE))
    if ticks:
        c = cut
        corner = ('<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f L%.1f %.1f" fill="none" stroke="%s" stroke-width="3" '
                  'stroke-linecap="round" stroke-linejoin="round"/>'
                  % (i, i + c + 9, i, i + c, i + c, i, i + c + 9, i, "#ffffff"))
        corner += diamond(i + c / 2 - 0.5, i + c / 2 - 0.5, 3.2, "#ffffff")
        body += corners(size, size, corner)
    return svg(size, size, body, grad("f", FILL_TOP, FILL_BOT, alpha, alpha))


def button(w: int = 192, h: int = 64, state: str = "normal", cut: int = 15) -> str:
    i = 4
    shape = chamfer(w, h, i, cut)
    if state == "normal":
        top, bot, line, la, ga = "#0d2352", "#071433", "#5db4ff", 0.85, 0.5
    elif state == "hover":
        top, bot, line, la, ga = "#2a7cf5", "#0f3fa6", "#bff1ff", 1.0, 1.2
    elif state == "pressed":
        top, bot, line, la, ga = "#0e3b9a", "#08205f", "#8adfff", 1.0, 0.8
    elif state == "cta":
        top, bot, line, la, ga = "#3a8bff", "#1048c0", "#ffe3a0", 1.0, 1.3
    else:  # disabled
        top, bot, line, la, ga = "#0b1530", "#080f24", "#42587e", 0.55, 0.0
    body = '<path d="%s" fill="url(#f)"/>' % shape
    if ga > 0:
        body += glow_lines(shape, line, 2.2, ga)
    body += ('<path d="%s" fill="none" stroke="%s" stroke-opacity="%.2f" stroke-width="2.2" stroke-linejoin="round"/>'
             % (shape, line, la))
    body += ('<path d="%s" fill="none" stroke="%s" stroke-opacity="0.22" stroke-width="1" stroke-linejoin="round"/>'
             % (chamfer(w, h, i + 5, cut - 3), line))
    if state in ("hover", "cta", "pressed"):
        # Top highlight band
        body += ('<path d="M%.1f %.1f L%.1f %.1f" stroke="#ffffff" stroke-opacity="0.35" stroke-width="1.5" '
                 'stroke-linecap="round"/>' % (i + cut + 2, i + 3.5, w - i - cut - 2, i + 3.5))
    if state in ("cta", "hover"):
        corner = diamond(i + cut / 2 - 0.5, i + cut / 2 - 0.5, 3.0, line)
        body += corners(w, h, corner)
    return svg(w, h, body, grad("f", top, bot))


def bar(w: int = 96, h: int = 28, fill: bool = False) -> str:
    """Progress bar: slanted ends. The fill is light grey so modulate_color gives its color."""
    sk = 9
    if fill:
        pts = "M%d 3 L%d 3 L%d %d L3 %d Z" % (sk + 3, w - 3, w - sk - 3, h - 3, h - 3)
        body = '<path d="%s" fill="url(#f)"/>' % pts
        body += ('<path d="M%d 6 L%d 6" stroke="#ffffff" stroke-opacity="0.45" stroke-width="2" stroke-linecap="round"/>'
                 % (sk + 8, w - 12))
        return svg(w, h, body, grad("f", "#ffffff", "#9aa6c0"))
    pts = "M%d 2 L%d 2 L%d %d L%d %d Z" % (sk + 2, w - 2, w - sk - 2, h - 2, 2, h - 2)
    body = '<path d="%s" fill="#050b1c" fill-opacity="0.92"/>' % pts
    body += '<path d="%s" fill="none" stroke="#4fa3ec" stroke-opacity="0.8" stroke-width="1.8" stroke-linejoin="round"/>' % pts
    return svg(w, h, body)


def focus(size: int = 160, cut: int = 20) -> str:
    """Outline-only frame for keyboard / gamepad focus (bright, glowing)."""
    i = 8
    shape = chamfer(size, size, i, cut)
    body = glow_lines(shape, "#ffffff", 4.0, 1.4)
    body += '<path d="%s" fill="none" stroke="#ffffff" stroke-width="3" stroke-linejoin="round"/>' % shape
    corner = diamond(i + cut / 2 - 0.5, i + cut / 2 - 0.5, 4.5, "#ffffff")
    body += corners(size, size, corner)
    return svg(size, size, body)


def divider(w: int = 512, h: int = 28) -> str:
    cy = h / 2
    defs = ('<linearGradient id="l" x1="0" y1="0" x2="1" y2="0">'
            '<stop offset="0" stop-color="%s" stop-opacity="0"/>'
            '<stop offset="0.35" stop-color="%s" stop-opacity="0.9"/>'
            '<stop offset="0.65" stop-color="%s" stop-opacity="0.9"/>'
            '<stop offset="1" stop-color="%s" stop-opacity="0"/></linearGradient>' % (LINE, LINE, LINE, LINE))
    body = '<rect x="0" y="%.1f" width="%d" height="2" fill="url(#l)"/>' % (cy - 1, w)
    body += diamond(w / 2, cy, 9, "#cdf3ff", GOLD, 2)
    body += diamond(w / 2 - 28, cy, 4, GOLD) + diamond(w / 2 + 28, cy, 4, GOLD)
    body += diamond(w / 2 - 44, cy, 2.5, LINE) + diamond(w / 2 + 44, cy, 2.5, LINE)
    return svg(w, h, body, defs)


def crown(w: int = 220, h: int = 56) -> str:
    """Crystal ornament sitting on the top edge of a window."""
    cx = w / 2
    defs = ('<linearGradient id="c" x1="0" y1="0" x2="0" y2="1">'
            '<stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#5cc8ff"/></linearGradient>')
    body = ('<path d="M%.1f 2 L%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="url(#c)" stroke="%s" stroke-width="2" '
            'stroke-linejoin="round"/>' % (cx, cx + 13, h * 0.5, cx, h - 8, cx - 13, h * 0.5, GOLD))
    for dx, s in ((-1, 1), (1, 1)):
        x0 = cx + dx * 26
        body += ('<path d="M%.1f %.1f L%.1f %.1f L%.1f %.1f Z" fill="url(#c)" stroke="%s" stroke-width="1.6" '
                 'stroke-linejoin="round"/>' % (x0, h * 0.34, x0 + dx * 6, h * 0.62, x0 - dx * 5, h * 0.62, GOLD))
    body += ('<path d="M%.1f %.1f L%.1f %.1f M%.1f %.1f L%.1f %.1f" stroke="%s" stroke-width="2" '
             'stroke-linecap="round"/>' % (cx - 34, h - 10, 6, h - 10, cx + 34, h - 10, w - 6, h - 10, LINE))
    body += diamond(cx, h - 10, 4, GOLD)
    return svg(w, h, body, defs)


def scheme(files: dict, suffix: str) -> None:
    """Frames drawn with the current LINE color (white: tinted by UiTheme; cyan: used as is, gold stays gold)."""
    files["panel" + suffix] = panel()
    files["window" + suffix] = panel(192, 28, 0.97)
    files["card" + suffix] = card()
    files["slot" + suffix] = card(96, 10, 0.9, False)


def main() -> None:
    global LINE
    os.makedirs(OUT, exist_ok=True)
    files: dict = {}
    scheme(files, "")
    LINE = "#5fd4ff"
    scheme(files, "_cyan")
    files["divider"] = divider()
    files["crown"] = crown()
    LINE = "#eaf8ff"
    files.update({
        "button_normal": button(state="normal"),
        "button_hover": button(state="hover"),
        "button_pressed": button(state="pressed"),
        "button_cta": button(state="cta"),
        "button_disabled": button(state="disabled"),
        "bar_bg": bar(),
        "bar_fill": bar(fill=True),
        "focus": focus(),
    })
    for name, content in files.items():
        with open(os.path.join(OUT, name + ".svg"), "w", encoding="utf-8", newline="") as f:
            f.write(content)
        print(name)


if __name__ == "__main__":
    main()
