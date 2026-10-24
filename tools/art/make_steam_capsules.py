"""Builds the Steam store images from one painted picture per format (steam_assets/source_artwork/capsule_<name>.png,
generated for the right ratio) and the logo.

Run: python tools/art/make_steam_capsules.py
Each source is cropped to the exact ratio (centred), resized, then the logo goes on top at a given centre and width,
with a soft dark halo behind it so it stays readable. The Library Hero has no logo (Steam puts its own on it).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "steam_assets" / "source_artwork"
BRAND = ROOT / "assets" / "branding"
OUT = ROOT / "steam_assets"

# name: (source, output folder, size, logo width, logo centre in output px); logo width 0 = no logo
JOBS = {
    "header_capsule": ("capsule_header", "capsules", (920, 430), 300, (765, 125)),
    "main_capsule": ("capsule_main", "capsules", (1232, 706), 470, (975, 175)),
    "small_capsule": ("capsule_small", "capsules", (462, 174), 250, (150, 87)),
    "vertical_capsule": ("capsule_vertical", "capsules", (748, 896), 430, (374, 118)),
    "library_capsule": ("capsule_library", "library", (600, 900), 380, (300, 118)),
    "library_hero": ("capsule_hero", "library", (3840, 1240), 0, (0, 0)),
}


def halo(size, centre, logo_size, strength):
    """Soft dark ellipse behind the logo."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w, h = logo_size
    cx, cy = centre
    d.ellipse([cx - w * 0.62, cy - h * 0.62, cx + w * 0.62, cy + h * 0.62], fill=(6, 8, 20, strength))
    return layer.filter(ImageFilter.GaussianBlur(max(w, h) * 0.12))


def crop_to_ratio(img, ratio):
    w, h = img.size
    if w / h > ratio:
        cw, ch = round(h * ratio), h
    else:
        cw, ch = w, round(w / ratio)
    x0, y0 = (w - cw) // 2, (h - ch) // 2
    return img.crop((x0, y0, x0 + cw, y0 + ch))


def build(name, source, folder, size, logo_w, centre):
    img = crop_to_ratio(Image.open(SRC / f"{source}.png").convert("RGB"), size[0] / size[1])
    img = img.resize(size, Image.LANCZOS).convert("RGBA")
    if logo_w:
        logo = Image.open(BRAND / "title.png").convert("RGBA")
        h = round(logo.height * logo_w / logo.width)
        logo = logo.resize((logo_w, h), Image.LANCZOS)
        img = Image.alpha_composite(img, halo(size, centre, logo.size, 120 if name == "small_capsule" else 150))
        img.alpha_composite(logo, (round(centre[0] - logo_w / 2), round(centre[1] - h / 2)))
    dest = OUT / folder
    dest.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(dest / f"{name}.png")
    return dest / f"{name}.png"


def page_background():
    """Page background: the main picture, darkened (subtle, not too bright), no logo."""
    img = crop_to_ratio(Image.open(SRC / "capsule_main.png").convert("RGB"), 1438 / 810).resize((1438, 810), Image.LANCZOS)
    img = Image.alpha_composite(img.convert("RGBA"), Image.new("RGBA", img.size, (4, 6, 16, 150)))
    img.convert("RGB").save(OUT / "capsules" / "page_background.png")


def extras():
    """Library header (= header capsule), library logo, app icon (jpg, solid background) and shortcut icon."""
    lib = OUT / "library"
    Image.open(OUT / "capsules" / "header_capsule.png").save(lib / "library_header.png")
    logo = Image.open(BRAND / "title.png").convert("RGBA")
    inner = round(1280 * 0.9)  # 5 % safety margin around the logo
    resized = logo.resize((inner, round(logo.height * inner / logo.width)), Image.LANCZOS)
    canvas = Image.new("RGBA", (1280, round(resized.height / 0.9)), (0, 0, 0, 0))
    canvas.alpha_composite(resized, ((1280 - inner) // 2, (canvas.height - resized.height) // 2))
    canvas.save(lib / "library_logo.png")
    icons = OUT / "icons"
    icons.mkdir(parents=True, exist_ok=True)
    emblem = Image.open(BRAND / "icon_1024.png").convert("RGBA")
    base = Image.new("RGBA", emblem.size, (14, 18, 40, 255))
    base.alpha_composite(emblem)
    base.convert("RGB").resize((184, 184), Image.LANCZOS).save(icons / "app_icon.jpg", quality=95)
    emblem.resize((256, 256), Image.LANCZOS).save(icons / "shortcut_icon.png")


def main():
    for name, (source, folder, size, logo_w, centre) in JOBS.items():
        print(build(name, source, folder, size, logo_w, centre))
    page_background()
    extras()


if __name__ == "__main__":
    main()
