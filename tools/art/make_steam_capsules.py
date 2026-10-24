"""Builds the Steam store images from the key art (steam_assets/source_artwork/key_art_a1.png) and the logos.

Run: python tools/art/make_steam_capsules.py
Crops are given in key-art pixels (1536 x 1024); the logo goes on top of the crop at a given centre and width.
Each image gets a soft dark halo behind the logo so it stays readable (it is part of the picture, not a border).
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
ART = ROOT / "steam_assets" / "source_artwork" / "key_art_a1.png"
BRAND = ROOT / "assets" / "branding"
OUT = ROOT / "steam_assets"

# name: (output folder, size, crop box in key-art px, logo file or None, logo width in output px, logo centre in output px)
JOBS = {
    "header_capsule": ("capsules", (920, 430), (0, 110, 1536, 828), "title.png", 300, (752, 128)),
    "main_capsule": ("capsules", (1232, 706), (0, 50, 1536, 930), "title.png", 440, (990, 200)),
    "small_capsule": ("capsules", (462, 174), (430, 230, 1330, 796), "title.png", 150, (231, 87)),
    "vertical_capsule": ("capsules", (748, 896), (110, 0, 965, 1024), "title.png", 440, (330, 140)),
    "library_capsule": ("library", (600, 900), (190, 0, 873, 1024), "title.png", 380, (255, 125)),
    "page_background": ("capsules", (1438, 810), (0, 80, 1536, 944), None, 0, (0, 0)),
}


def halo(size, centre, logo_size):
    """Soft dark ellipse behind the logo."""
    layer = Image.new("RGBA", size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    w, h = logo_size
    cx, cy = centre
    d.ellipse([cx - w * 0.62, cy - h * 0.62, cx + w * 0.62, cy + h * 0.62], fill=(6, 8, 20, 150))
    return layer.filter(ImageFilter.GaussianBlur(max(w, h) * 0.12))


def build(name, folder, size, crop, logo_name, logo_w, centre, art):
    img = art.crop(crop).resize(size, Image.LANCZOS).convert("RGBA")
    if name == "page_background":
        img = Image.alpha_composite(img, Image.new("RGBA", size, (4, 6, 16, 150)))  # subtle, not too bright
    if logo_name:
        logo = Image.open(BRAND / logo_name).convert("RGBA")
        h = round(logo.height * logo_w / logo.width)
        logo = logo.resize((logo_w, h), Image.LANCZOS)
        img = Image.alpha_composite(img, halo(size, centre, logo.size))
        img.alpha_composite(logo, (round(centre[0] - logo_w / 2), round(centre[1] - h / 2)))
    dest = OUT / folder
    dest.mkdir(parents=True, exist_ok=True)
    img.convert("RGB").save(dest / f"{name}.png")
    return dest / f"{name}.png"


def extras():
    """Library header (= header capsule), library logo, app icon (jpg, solid background) and shortcut icon."""
    lib = OUT / "library"
    lib.mkdir(parents=True, exist_ok=True)
    Image.open(OUT / "capsules" / "header_capsule.png").save(lib / "library_header.png")
    logo = Image.open(BRAND / "title.png").convert("RGBA")
    # 1280 wide max, 5 % safety margin around the logo
    inner = round(1280 * 0.9)
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
    art = Image.open(ART).convert("RGB")
    for name, (folder, size, crop, logo, logo_w, centre) in JOBS.items():
        print(build(name, folder, size, crop, logo, logo_w, centre, art))
    extras()


if __name__ == "__main__":
    main()
