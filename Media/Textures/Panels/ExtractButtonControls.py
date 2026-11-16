import argparse
from pathlib import Path
from statistics import median

try:
    from PIL import Image, ImageChops, ImageDraw
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
REFERENCES = ROOT.parent.parent / "References"
ATLAS_SIZE = (128, 32)
CAP_WIDTH = 16
SOURCE_CAP_WIDTH = 22
BUTTON_STATES = {
    "Enabled": {
        "reference": "Button-Enabled.png",
        "bounds": (7, 6, 270, 38),
        "sample_ranges": ((31, 74), (203, 246)),
        "base_level": 190,
        "contrast": 1.8,
    },
    "Disabled": {
        "reference": "Button-Disabled.png",
        "bounds": (7, 6, 150, 38),
        "sample_ranges": ((34, 52), (104, 124)),
        "base_level": 190,
        "contrast": 1.8,
    },
}
MATERIALS = ("", "-Standard", "-Classic", "-Clear")


def rounded_mask(size, inset=0):
    width, height = size
    scale = 4
    mask = Image.new("L", (width * scale, height * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (inset * scale, inset * scale, (width - inset) * scale - 1, (height - inset) * scale - 1),
        radius=(height // 2 - inset) * scale,
        fill=255,
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


def remap_gray(value, background, base_level, contrast):
    return max(0, min(255, round(base_level + (value - background) * contrast)))


def extract_control(source, specification):
    left, top, right, bottom = specification["bounds"]
    height = bottom - top
    if height != ATLAS_SIZE[1]:
        raise RuntimeError(f"Reference crop height must be {ATLAS_SIZE[1]} pixels")

    corner_samples = [source.getpixel(point)[:3] for point in ((0, 0), (source.width - 1, 0),
                                                                 (0, source.height - 1),
                                                                 (source.width - 1, source.height - 1))]
    background = round(median(sum(pixel) / 3 for pixel in corner_samples))
    pixels = source.convert("RGB").load()
    atlas = Image.new("RGBA", ATLAS_SIZE, (255, 255, 255, 0))

    for destination_x, source_left in ((0, left), (ATLAS_SIZE[0] - CAP_WIDTH, right - SOURCE_CAP_WIDTH)):
        cap = source.crop((source_left, top, source_left + SOURCE_CAP_WIDTH, bottom)).convert("L")
        cap = cap.resize((CAP_WIDTH, ATLAS_SIZE[1]), Image.Resampling.LANCZOS)
        cap = cap.point(lambda value: remap_gray(value, background, specification["base_level"],
                                                  specification["contrast"]))
        rgba = Image.merge("RGBA", (cap, cap, cap, Image.new("L", cap.size, 255)))
        atlas.alpha_composite(rgba, (destination_x, 0))

    for y in range(height):
        samples = [sum(pixels[x, top + y]) / 3
                   for start, end in specification["sample_ranges"]
                   for x in range(start, end)]
        value = remap_gray(round(median(samples)), background, specification["base_level"],
                           specification["contrast"])
        for x in range(CAP_WIDTH, ATLAS_SIZE[0] - CAP_WIDTH):
            atlas.putpixel((x, y), (value, value, value, 255))

    atlas.putalpha(rounded_mask(ATLAS_SIZE))
    return atlas


def make_border(opacity=255):
    outer = rounded_mask(ATLAS_SIZE)
    inner = rounded_mask(ATLAS_SIZE, inset=1)
    alpha = ImageChops.subtract(outer, inner)
    if opacity != 255:
        alpha = alpha.point(lambda value: round(value * opacity / 255))
    border = Image.new("RGBA", ATLAS_SIZE, (255, 255, 255, 0))
    border.putalpha(alpha)
    return border


def write_texture(name, image, overwrite):
    destination = ROOT / f"{name}.tga"
    if destination.exists() and not overwrite:
        print(f"Keeping existing {destination.name}")
        return
    image.save(destination)
    with Image.open(destination) as exported:
        exported.load()
        if exported.size != image.size or exported.convert("RGBA").tobytes() != image.tobytes():
            raise RuntimeError(f"Export verification failed: {destination}")
    print(f"Created {destination.name}: {image.width}x{image.height}")


def write_circular_controls(overwrite):
    with Image.open(REFERENCES / "Button-Enabled.png") as source:
        source = source.convert("RGBA")
        base = Image.new("RGBA", (32, 32))
        for source_left, destination_left in ((7, 0), (254, 16)):
            base.alpha_composite(source.crop((source_left, 6, source_left + 16, 38)), (destination_left, 0))
    mask = Image.new("L", (128, 128))
    ImageDraw.Draw(mask).ellipse((2, 2, 125, 125), fill=255)
    base.putalpha(mask.resize(base.size, Image.Resampling.LANCZOS))
    outer = Image.new("L", (256, 256))
    inner = outer.copy()
    ImageDraw.Draw(outer).ellipse((4, 4, 251, 251), fill=255)
    ImageDraw.Draw(inner).ellipse((12.8, 12.8, 242.2, 242.2), fill=255)
    ring = ImageChops.subtract(outer, inner).resize(base.size, Image.Resampling.LANCZOS)
    border = Image.new("RGBA", base.size)
    for vertical in range(32):
        shade = round(195 - 95 * vertical / 31)
        for horizontal in range(32):
            border.putpixel((horizontal, vertical), (shade, shade, shade, ring.getpixel((horizontal, vertical))))
    base = Image.alpha_composite(base, border)
    with Image.open(ROOT / "Arrow-Button-Base.png") as source:
        glyph = source.convert("RGBA")
    if glyph.width != glyph.height or glyph.getchannel("A").getextrema() != (0, 255):
        raise RuntimeError("The supplied arrow must be a square image with transparency")
    texture_size = 32
    while texture_size < glyph.width:
        texture_size *= 2
    glyph_size = texture_size * 3 // 4
    if glyph.size != (glyph_size, glyph_size):
        glyph = glyph.resize((glyph_size, glyph_size), Image.Resampling.LANCZOS)
    padded = Image.new("RGBA", (texture_size, texture_size))
    inset = (texture_size - glyph_size) // 2
    padded.alpha_composite(glyph, (inset, inset))
    write_texture("Arrow-Button-Circle", base, overwrite)
    write_texture("Arrow-Button-Glyph", padded, overwrite)


def main():
    parser = argparse.ArgumentParser(description="Extract button-state and search-fill textures from references.")
    parser.add_argument("--overwrite", action="store_true", help="Replace existing generated TGA textures.")
    parser.add_argument("--circular-only", action="store_true", help="Generate only the approved circular-arrow base and glyph.")
    arguments = parser.parse_args()
    if arguments.circular_only:
        write_circular_controls(arguments.overwrite)
        return

    for state, specification in BUTTON_STATES.items():
        reference = REFERENCES / specification["reference"]
        if not reference.is_file():
            raise SystemExit(f"Reference image not found: {reference}")
        with Image.open(reference) as raw:
            fill = extract_control(raw.convert("RGBA"), specification)

        state_suffix = "" if state == "Enabled" else "-Disabled"
        for material in MATERIALS:
            write_texture(f"Button-fill{state_suffix}{material}", fill, arguments.overwrite)
            opacity = 180 if material == "-Clear" else 255
            write_texture(f"Button-border{state_suffix}{material}", make_border(opacity), arguments.overwrite)
            if state == "Enabled":
                write_texture(f"Search-fill{material}", fill, arguments.overwrite)
    write_circular_controls(arguments.overwrite)


if __name__ == "__main__":
    main()