import argparse
from pathlib import Path
import random
from statistics import median

try:
    from PIL import Image, ImageChops, ImageDraw
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT.parent.parent / "References" / "Dark-Tooltip-Ability.png"
ATLAS_SIZE = 64
CAP = 16
SCALE = 4


def make_outline():
    size = ATLAS_SIZE * SCALE
    border = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(border)
    layers = (
        (0, (5, 5, 5, 255)),
        (1, (83, 84, 85, 255)),
        (2, (25, 26, 27, 255)),
    )
    for inset, color in layers:
        inset *= SCALE
        draw.rounded_rectangle(
            (inset, inset, size - inset - 1, size - inset - 1),
            radius=(12 * SCALE - inset), fill=color,
        )
    inset = 3 * SCALE
    draw.rounded_rectangle(
        (inset, inset, size - inset - 1, size - inset - 1),
        radius=9 * SCALE, fill=(0, 0, 0, 0),
    )
    return border.resize((ATLAS_SIZE, ATLAS_SIZE), Image.Resampling.LANCZOS)


def make_background():
    reference_path = ROOT.parent.parent / "References" / "Dark-Tooltip-Ability.png"
    if not reference_path.is_file():
        raise SystemExit(f"Tooltip reference not found: {reference_path}")
    with Image.open(reference_path) as raw:
        source = raw.convert("RGBA")
    interior = source.crop((64, 48, 496, 247)).convert("RGB")
    pixels = list(interior.getdata())
    base = tuple(round(median(pixel[channel] for pixel in pixels)) for channel in range(3))
    randomizer = random.Random(21021)
    tile = Image.new("RGBA", (128, 128))
    tile_pixels = []
    for y in range(tile.height):
        vertical_lift = round(0.7 * (1 - y / (tile.height - 1)))
        for _ in range(tile.width):
            grain = randomizer.choice((-1, 0, 0, 0, 1))
            color = tuple(max(0, min(255, channel + vertical_lift + grain)) for channel in base)
            tile_pixels.append((*color, 255))
    tile.putdata(tile_pixels)
    sample = tile.crop((32, 32, 96, 96))
    scale = 4
    mask = Image.new("L", (ATLAS_SIZE * scale, ATLAS_SIZE * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle((12, 12, ATLAS_SIZE * scale - 13, ATLAS_SIZE * scale - 13),
                                           radius=36, fill=255)
    background = sample.copy()
    background.putalpha(mask.resize((ATLAS_SIZE, ATLAS_SIZE), Image.Resampling.LANCZOS))
    return make_atlas(background, include_center=True), tile


def make_atlas(outline, include_center=False):
    atlas = Image.new("RGBA", (ATLAS_SIZE, ATLAS_SIZE), (0, 0, 0, 0))
    parts = (
        ((0, 0, CAP, CAP), (0, 0)),
        ((ATLAS_SIZE - CAP, 0, ATLAS_SIZE, CAP), (ATLAS_SIZE - CAP, 0)),
        ((0, ATLAS_SIZE - CAP, CAP, ATLAS_SIZE), (0, ATLAS_SIZE - CAP)),
        ((ATLAS_SIZE - CAP, ATLAS_SIZE - CAP, ATLAS_SIZE, ATLAS_SIZE),
         (ATLAS_SIZE - CAP, ATLAS_SIZE - CAP)),
        ((CAP, 0, ATLAS_SIZE - CAP, CAP), (CAP, 0)),
        ((CAP, ATLAS_SIZE - CAP, ATLAS_SIZE - CAP, ATLAS_SIZE), (CAP, ATLAS_SIZE - CAP)),
        ((0, CAP, CAP, ATLAS_SIZE - CAP), (0, CAP)),
        ((ATLAS_SIZE - CAP, CAP, ATLAS_SIZE, ATLAS_SIZE - CAP), (ATLAS_SIZE - CAP, CAP)),
    )
    if include_center:
        parts += (((CAP, CAP, ATLAS_SIZE - CAP, ATLAS_SIZE - CAP), (CAP, CAP)),)
    for bounds, position in parts:
        atlas.alpha_composite(outline.crop(bounds), position)
    return atlas


def draw_preview(background, fill, rim):
    width, height = 448, 224
    preview = Image.new("RGBA", (width, height), (29, 29, 29, 255))
    for y in range(0, height, fill.height):
        for x in range(0, width, fill.width):
            preview.alpha_composite(fill, (x, y))
    slices = (
        ((0, 0, CAP, CAP), (0, 0, CAP, CAP)),
        ((48, 0, 64, 16), (width - CAP, 0, width, CAP)),
        ((0, 48, 16, 64), (0, height - CAP, CAP, height)),
        ((48, 48, 64, 64), (width - CAP, height - CAP, width, height)),
        ((16, 0, 48, 16), (CAP, 0, width - CAP, CAP)),
        ((16, 48, 48, 64), (CAP, height - CAP, width - CAP, height)),
        ((0, 16, 16, 48), (0, CAP, CAP, height - CAP)),
        ((48, 16, 64, 48), (width - CAP, CAP, width, height - CAP)),
    )
    for atlas in (background, rim):
        for source, destination in slices:
            piece = atlas.crop(source)
            box = destination[2] - destination[0], destination[3] - destination[1]
            if piece.size != box:
                piece = piece.resize(box, Image.Resampling.LANCZOS)
            preview.alpha_composite(piece, destination[:2])
    return preview


def main():
    parser = argparse.ArgumentParser(description="Create a clean, uniform Dark tooltip outline from the visual reference.")
    parser.add_argument("--overwrite", action="store_true", help="Replace generated assets; the reference screenshot is never modified.")
    arguments = parser.parse_args()
    if not REFERENCE.is_file():
        raise SystemExit(f"Tooltip reference not found: {REFERENCE}")

    atlas = make_atlas(make_outline())
    if atlas.getchannel("A").crop((CAP, CAP, ATLAS_SIZE - CAP, ATLAS_SIZE - CAP)).getbbox() is not None:
        raise RuntimeError("Tooltip outline center must be transparent")
    if atlas.getpixel((0, 0))[3] != 0 or atlas.getpixel((1, 10))[3] == 0:
        raise RuntimeError("Tooltip corner alpha is not continuous")
    mirrored = atlas.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if ImageChops.difference(atlas, mirrored).getbbox() is not None:
        raise RuntimeError("Tooltip outline corners and sides must be horizontally symmetric")
    mirrored = atlas.transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    if ImageChops.difference(atlas, mirrored).getbbox() is not None:
        raise RuntimeError("Tooltip outline corners and sides must be vertically symmetric")
    background, fill = make_background()
    if background.getchannel("A").getpixel((0, 0)) != 0:
        raise RuntimeError("Tooltip background corners must be rounded and transparent")
    if background.getchannel("A").getpixel((32, 32)) != 255:
        raise RuntimeError("Tooltip background center must be opaque")
    assets = {
        "Tooltip-Rim-Dark": atlas,
        "Tooltip-Background-Dark": background,
        "Tooltip-Fill-Dark": fill,
        "Tooltip-Preview-Dark": draw_preview(background, fill, atlas),
    }
    for name, image in assets.items():
        for extension in (("png",) if "Preview" in name else ("png", "tga")):
            destination = ROOT / f"{name}.{extension}"
            if destination.exists() and not arguments.overwrite:
                print(f"Keeping existing {destination.name}")
                continue
            image.save(destination)
            with Image.open(destination) as exported:
                exported.load()
                if exported.size != image.size or exported.convert("RGBA").tobytes() != image.tobytes():
                    raise RuntimeError(f"Export verification failed: {destination}")
            print(f"Created {destination.name}: {image.width}x{image.height}")


if __name__ == "__main__":
    main()