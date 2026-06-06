"""Local firebox patch: keep original layer, replace only flame tongues."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parents[1]

VARIANTS = {
    "family": {
        "orig": ROOT / "assets/art/characters/scene_01/scene1_family_group_v2.png",
        "nano": ROOT / "assets/art/characters/scene_01/Remove_static_flame_shapes_202606052250.jpeg",
        "out": ROOT / "assets/art/characters/scene_01/scene1_family_group_v2_no_fire.png",
    },
    "amulets": {
        "orig": ROOT / "assets/art/characters/scene_01/scene1_family_group_amulets.png",
        "nano": ROOT / "assets/art/characters/scene_01/Edit_image_remove_flames_202606052327.jpeg",
        "out": ROOT / "assets/art/characters/scene_01/scene1_family_group_amulets_no_fire.png",
    },
}

# Stove firebox ellipse in original 1280x714 coordinates.
STOVE_CX = 968
STOVE_CY = 400
STOVE_RX = 78
STOVE_RY = 62
PATCH_BLUR_RADIUS = 2.0


def _resize_to_match(source: Image.Image, target_size: tuple[int, int]) -> Image.Image:
    if source.size == target_size:
        return source
    return source.resize(target_size, Image.Resampling.LANCZOS)


def _build_stove_mask(width: int, height: int) -> np.ndarray:
    yy, xx = np.ogrid[:height, :width]
    return ((xx - STOVE_CX) ** 2 / STOVE_RX**2 + (yy - STOVE_CY) ** 2 / STOVE_RY**2) <= 1.0


def _build_flame_mask(orig: np.ndarray, stove_mask: np.ndarray) -> np.ndarray:
    red = orig[:, :, 0]
    green = orig[:, :, 1]
    blue = orig[:, :, 2]
    alpha = orig[:, :, 3]
    max_channel = np.maximum(np.maximum(red, green), blue)
    min_channel = np.minimum(np.minimum(red, green), blue)
    chroma = max_channel - min_channel

    flame_orange = (
        stove_mask
        & (alpha > 200)
        & (red > 150)
        & (red > green + 25)
        & (green > blue + 10)
        & (chroma > 55)
        & (max_channel > 160)
    )
    flame_core = (
        stove_mask
        & (alpha > 200)
        & (red > 180)
        & (green > 140)
        & (blue < 100)
        & (red.astype(np.int16) + green.astype(np.int16) > 320)
    )
    return flame_orange | flame_core


def _is_checkerboard_pixel(rgb: np.ndarray) -> np.ndarray:
    """Ignore fake-transparency checkerboard from Nano JPEG exports."""
    red = rgb[:, :, 0]
    green = rgb[:, :, 1]
    blue = rgb[:, :, 2]
    max_channel = np.maximum(np.maximum(red, green), blue)
    min_channel = np.minimum(np.minimum(red, green), blue)
    chroma = max_channel.astype(np.int16) - min_channel.astype(np.int16)
    avg = (red.astype(np.int16) + green.astype(np.int16) + blue.astype(np.int16)) / 3
    light_gray = (chroma < 18) & (avg >= 118) & (avg <= 198)
    dark_gray = (chroma < 18) & (avg >= 35) & (avg <= 95)
    return light_gray | dark_gray


def _build_patch_weight(flame_mask: np.ndarray, nano_rgb: np.ndarray) -> np.ndarray:
    safe_flame = flame_mask & ~_is_checkerboard_pixel(nano_rgb.astype(np.uint8))
    mask_img = Image.fromarray((safe_flame.astype(np.uint8) * 255), mode="L")
    blurred = mask_img.filter(ImageFilter.GaussianBlur(radius=PATCH_BLUR_RADIUS))
    return np.asarray(blurred, dtype=np.float32) / 255.0


def patch_layer(orig_path: Path, nano_path: Path, out_path: Path) -> Path:
    orig_img = Image.open(orig_path).convert("RGBA")
    nano_img = Image.open(nano_path).convert("RGB")
    nano_img = _resize_to_match(nano_img, orig_img.size)

    orig = np.array(orig_img, dtype=np.float32)
    nano = np.array(nano_img, dtype=np.float32)
    height, width = orig.shape[:2]

    stove_mask = _build_stove_mask(width, height)
    flame_mask = _build_flame_mask(orig.astype(np.uint8), stove_mask)
    weight = _build_patch_weight(flame_mask, nano)

    result = orig.copy()
    inv_weight = 1.0 - weight
    for channel in range(3):
        result[:, :, channel] = orig[:, :, channel] * inv_weight + nano[:, :, channel] * weight
    result[:, :, 3] = orig[:, :, 3]
    result = np.clip(result, 0, 255).astype(np.uint8)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    Image.fromarray(result, mode="RGBA").save(out_path)
    return out_path


def _print_stats(orig_path: Path, out_path: Path) -> None:
    orig = np.array(Image.open(orig_path).convert("RGBA"))
    out = np.array(Image.open(out_path).convert("RGBA"))
    alpha_match = np.array_equal(orig[:, :, 3], out[:, :, 3])
    opaque = orig[:, :, 3] > 0
    semi = (orig[:, :, 3] > 0) & (orig[:, :, 3] < 255)
    rgb_diff = np.abs(orig[:, :, :3].astype(int) - out[:, :, :3].astype(int)).sum(axis=2)
    changed = (rgb_diff > 5) & opaque

    height, width = orig.shape[:2]
    yy, xx = np.ogrid[:height, :width]
    outside = ((xx - STOVE_CX) ** 2 / (STOVE_RX * 1.2) ** 2 + (yy - STOVE_CY) ** 2 / (STOVE_RY * 1.2) ** 2) > 1.0

    print(f"alpha identical: {alpha_match}")
    print(f"changed opaque pixels: {changed.sum()} / {opaque.sum()}")
    print(f"semi-transparent changed: {(rgb_diff[semi] > 0).sum()} / {semi.sum()}")
    print(f"outside stove changed: {(rgb_diff[outside] > 0).sum()} / {outside.sum()}")


def main() -> None:
    parser = argparse.ArgumentParser(description="Patch static flames inside stove firebox.")
    parser.add_argument(
        "variant",
        choices=sorted(VARIANTS),
        nargs="?",
        default="amulets",
        help="Layer variant to patch (default: amulets)",
    )
    args = parser.parse_args()
    cfg = VARIANTS[args.variant]
    out = patch_layer(cfg["orig"], cfg["nano"], cfg["out"])
    print(f"saved {out}")
    _print_stats(cfg["orig"], cfg["out"])


if __name__ == "__main__":
    main()
