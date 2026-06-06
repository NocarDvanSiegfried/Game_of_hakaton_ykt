from __future__ import annotations

import colorsys
from pathlib import Path

from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "assets" / "art" / "effects" / "scene_01" / "fire"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SHEET_CANDIDATES = [
    ROOT / "Create_transparent_PNG_files_202606051237.png",
    ROOT / "Create_transparent_PNG_files_202606051237.jpeg",
]
OUTPUT_NAMES = [
    "fire_01.png",
    "fire_02.png",
    "fire_03.png",
    "fire_04.png",
]

ALPHA_BLUR_RADIUS = 0.85
ALPHA_CUTOFF = 14


def is_bright_flame_pixel(r: int, g: int, b: int) -> bool:
    """Strict mask: only vivid yellow / orange / red flame."""
    max_c = max(r, g, b)
    min_c = min(r, g, b)
    chroma = max_c - min_c
    avg = (r + g + b) / 3.0

    # Checkerboard, smoke, wood, shadows.
    if chroma < 48 and max_c < 175:
        return False
    if chroma < 36 and 45 <= avg <= 135:
        return False
    if max_c < 95:
        return False

    hue, sat, val = colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)

    if val < 0.44:
        return False
    if sat < 0.40:
        return False
    if not (hue <= 0.17 or hue >= 0.97):
        return False

    # Hot yellow core.
    if r >= 165 and g >= 125 and b <= 95 and g >= b + 20:
        return True

    # Bright orange / red flame body.
    if r >= 135 and r >= g + 42 and r >= b + 38 and val >= 0.48:
        return True

    # High-energy orange fringe.
    if r >= 115 and g >= 55 and r >= g + 50 and val >= 0.55 and sat >= 0.48:
        return True

    return False


def build_strict_flame(img: Image.Image) -> Image.Image:
    src = img.convert("RGBA")
    out = Image.new("RGBA", src.size, (0, 0, 0, 0))
    src_px = src.load()
    out_px = out.load()
    w, h = src.size

    for y in range(h):
        for x in range(w):
            r, g, b, _a = src_px[x, y]
            if is_bright_flame_pixel(r, g, b):
                out_px[x, y] = (r, g, b, 255)

    return out


def _warm_neighbor_color(strict: Image.Image, x: int, y: int) -> tuple[int, int, int]:
    px = strict.load()
    w, h = strict.size
    total_r = 0
    total_g = 0
    total_b = 0
    weight = 0

    for ny in range(max(0, y - 2), min(h, y + 3)):
        for nx in range(max(0, x - 2), min(w, x + 3)):
            r, g, b, a = px[nx, ny]
            if a < 200:
                continue
            dist = ((nx - x) ** 2 + (ny - y) ** 2) ** 0.5
            wgt = 1.0 / (1.0 + dist)
            total_r += int(r * wgt)
            total_g += int(g * wgt)
            total_b += int(b * wgt)
            weight += wgt

    if weight <= 0.0:
        return (255, 145, 45)

    return (
        min(255, int(total_r / weight)),
        min(255, int(total_g / weight)),
        min(255, int(total_b / weight)),
    )


def soften_alpha_edges(strict: Image.Image) -> Image.Image:
    """Blur alpha only; fringe RGB comes from nearby warm pixels, never gray/black."""
    alpha = strict.split()[3].filter(ImageFilter.GaussianBlur(radius=ALPHA_BLUR_RADIUS))
    out = Image.new("RGBA", strict.size, (0, 0, 0, 0))
    alpha_px = alpha.load()
    out_px = out.load()
    w, h = strict.size

    for y in range(h):
        for x in range(w):
            a = int(alpha_px[x, y])
            if a < ALPHA_CUTOFF:
                continue
            r, g, b = _warm_neighbor_color(strict, x, y)
            out_px[x, y] = (r, g, b, a)

    return out


def extract_warm_flame(img: Image.Image) -> Image.Image:
    strict = build_strict_flame(img)
    return soften_alpha_edges(strict)


def crop_to_content(img: Image.Image, padding: int = 3) -> Image.Image:
    px = img.load()
    w, h = img.size
    minx, miny, maxx, maxy = w, h, 0, 0
    found = False
    for y in range(h):
        for x in range(w):
            if px[x, y][3] > 10:
                found = True
                minx = min(minx, x)
                miny = min(miny, y)
                maxx = max(maxx, x)
                maxy = max(maxy, y)
    if not found:
        return img
    minx = max(0, minx - padding)
    miny = max(0, miny - padding)
    maxx = min(w - 1, maxx + padding)
    maxy = min(h - 1, maxy + padding)
    return img.crop((minx, miny, maxx + 1, maxy + 1))


def load_sheet_frames() -> list[Image.Image] | None:
    sheet_path = next((p for p in SHEET_CANDIDATES if p.exists()), None)
    if sheet_path is None:
        return None
    sheet = Image.open(sheet_path)
    sw, sh = sheet.size
    fw, fh = sw // 2, sh // 2
    return [
        sheet.crop((0, 0, fw, fh)),
        sheet.crop((fw, 0, sw, fh)),
        sheet.crop((0, fh, fw, sh)),
        sheet.crop((fw, fh, sw, sh)),
    ]


def load_existing_outputs() -> list[Image.Image]:
    return [Image.open(OUT_DIR / name) for name in OUTPUT_NAMES]


def audit_frame(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    px = img.load()
    warm = neutral = dark = black_halo = 0
    for y in range(img.size[1]):
        for x in range(img.size[0]):
            r, g, b, a = px[x, y]
            if a < 12:
                continue
            chroma = max(r, g, b) - min(r, g, b)
            avg = (r + g + b) / 3.0
            if r + g + b < 40:
                black_halo += 1
            elif chroma <= 36 and 45 <= avg <= 135:
                neutral += 1
            elif max(r, g, b) < 95:
                dark += 1
            else:
                warm += 1
    print(
        f"audit {path.name}: warm={warm} neutral={neutral} dark={dark} "
        f"black_halo={black_halo} size={img.size}"
    )


def main() -> None:
    frames = load_sheet_frames()
    if frames is None:
        print("Spritesheet not found, reprocessing existing fire_01..fire_04 PNGs.")
        frames = load_existing_outputs()

    for index, frame in enumerate(frames):
        processed = crop_to_content(extract_warm_flame(frame))
        out_path = OUT_DIR / OUTPUT_NAMES[index]
        processed.save(out_path)
        audit_frame(out_path)

    print("Saved to", OUT_DIR)


if __name__ == "__main__":
    main()
