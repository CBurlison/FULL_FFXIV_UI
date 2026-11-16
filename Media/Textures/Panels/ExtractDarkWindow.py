import argparse
from pathlib import Path

try:
    from PIL import Image, ImageChops, ImageDraw, ImageOps
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
REFERENCE = ROOT.parent.parent / "References" / "Dark-Social-Friend-List.png"
REFERENCE_SIZE = (1000, 814)
WINDOW_BOUNDS = (6, 6, 995, 811)
HEADER_BOUNDS = (350, 14, 650, 64)
BACKGROUND_BOUNDS = (400, 590, 464, 654)


def crop_reference(source, bounds):
    left, top, right, bottom = bounds
    scale_x, scale_y = source.width / REFERENCE_SIZE[0], source.height / REFERENCE_SIZE[1]
    return source.crop((round(left * scale_x), round(top * scale_y), round(right * scale_x), round(bottom * scale_y)))


def rounded_mask(size, inset, radius):
    scale = 4
    mask = Image.new("L", (size[0] * scale, size[1] * scale), 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (inset * scale, inset * scale, (size[0] - inset) * scale - 1, (size[1] - inset) * scale - 1),
        radius=radius * scale, fill=255
    )
    return mask.resize(size, Image.Resampling.LANCZOS)


def nine_slice(source, cap):
    atlas = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    source_x = ((0, cap), (source.width // 2 - cap, source.width // 2 + cap), (source.width - cap, source.width))
    source_y = ((0, cap), (source.height // 2 - cap, source.height // 2 + cap), (source.height - cap, source.height))
    target = ((0, 16), (16, 48), (48, 64))
    for row in range(3):
        for column in range(3):
            if row == 1 and column == 1:
                continue
            left, right = source_x[column]
            top, bottom = source_y[row]
            piece = source.crop((left, top, right, bottom))
            destination = (target[column][0], target[row][0])
            dimensions = (target[column][1] - target[column][0], target[row][1] - target[row][0])
            atlas.paste(piece.resize(dimensions, Image.Resampling.LANCZOS), destination)
    return atlas


def make_background(source):
    sample = crop_reference(source, BACKGROUND_BOUNDS).resize((64, 64), Image.Resampling.LANCZOS)
    tile = Image.new("RGBA", (128, 128))
    tile.paste(sample, (0, 0))
    tile.paste(ImageOps.mirror(sample), (64, 0))
    tile.paste(ImageOps.flip(sample), (0, 64))
    tile.paste(ImageOps.flip(ImageOps.mirror(sample)), (64, 64))
    return tile


def make_header(source):
    header_light = crop_reference(source, HEADER_BOUNDS).resize((256, 64), Image.Resampling.LANCZOS)
    fade = Image.new("L", header_light.size, 255)
    fade_draw = ImageDraw.Draw(fade)
    fade_start = header_light.height - 16
    for vertical in range(fade_start, header_light.height):
        opacity = round(255 * (header_light.height - 1 - vertical) / (header_light.height - 1 - fade_start))
        fade_draw.line((0, vertical, header_light.width - 1, vertical), fill=opacity)
    header_light.putalpha(fade)
    return header_light


def preview(rim, header, background):
    image = Image.new("RGBA", (512, 384), (0, 0, 0, 0))
    for vertical in range(0, image.height, background.height):
        for horizontal in range(0, image.width, background.width):
            image.paste(background, (horizontal, vertical))
    image.alpha_composite(header.resize((image.width, 48), Image.Resampling.LANCZOS), (0, 0))
    image.putalpha(rounded_mask(image.size, 0, 8))
    source = ((0, 16), (16, 48), (48, 64))
    target_x = ((0, 8), (8, image.width - 8), (image.width - 8, image.width))
    target_y = ((0, 8), (8, image.height - 8), (image.height - 8, image.height))
    for row in range(3):
        for column in range(3):
            if row == 1 and column == 1:
                continue
            piece = rim.crop((source[column][0], source[row][0], source[column][1], source[row][1]))
            dimensions = (target_x[column][1] - target_x[column][0], target_y[row][1] - target_y[row][0])
            piece = piece.resize(dimensions, Image.Resampling.LANCZOS)
            image.alpha_composite(piece, (target_x[column][0], target_y[row][0]))
    return image


def main():
    parser = argparse.ArgumentParser(description="Extract a Dark-only window skin from the FFXIV Social reference.")
    parser.add_argument("--overwrite", action="store_true", help="Replace generated assets, never the reference screenshots.")
    arguments = parser.parse_args()
    if not REFERENCE.is_file():
        raise SystemExit(f"Reference not found: {REFERENCE}")
    with Image.open(REFERENCE) as raw:
        source = raw.convert("RGBA")
    window = crop_reference(source, WINDOW_BOUNDS)
    scale = source.width / REFERENCE_SIZE[0]
    cap = max(8, round(16 * scale))
    outer = rounded_mask(window.size, 0, max(1, round(14 * scale)))
    inner = rounded_mask(window.size, max(1, round(7 * scale)), max(1, round(7 * scale)))
    window.putalpha(ImageChops.subtract(outer, inner))
    rim = nine_slice(window, cap)
    header = make_header(source)
    background = make_background(source)
    assets = {
        "Window-Rim-Dark": rim,
        "Window-Header-Dark": header,
        "Window-Background-Dark": background,
    }
    if rim.getchannel("A").crop((16, 16, 48, 48)).getbbox() is not None:
        raise RuntimeError("Nine-slice rim center must be transparent")
    if rim.getchannel("A").getbbox() is None:
        raise RuntimeError("Extracted rim is blank")
    if header.getpixel((header.width // 2, 0))[3] != 255 or header.getpixel((header.width // 2, header.height - 1))[3] != 0:
        raise RuntimeError("Header lighting must fade from opaque to transparent without a hard lower edge")
    composed = preview(rim, header, background)
    corners = nine_slice(composed, 8)
    frame = rim.copy()
    for left, top, right, bottom in ((0, 0, 16, 16), (48, 0, 64, 16), (0, 48, 16, 64), (48, 48, 64, 64)):
        frame.paste(corners.crop((left, top, right, bottom)), (left, top))
    for point in ((15, 15), (48, 15), (15, 48), (48, 48)):
        if frame.getpixel(point)[3] != 255:
            raise RuntimeError("Frame corner interior must be opaque; only the outer rounding may be transparent")
    if frame.getchannel("A").crop((16, 16, 48, 48)).getbbox() is not None:
        raise RuntimeError("Composited frame center must remain transparent")
    for point in ((15, 32), (48, 32), (32, 15), (32, 48)):
        if frame.getpixel(point)[3] != 0:
            raise RuntimeError("Straight frame slices must leave their inner edge transparent for header lighting")
    assets["Window-Rim-Dark"] = frame
    assets["Window-Preview-Dark"] = composed
    for name, image in assets.items():
        extensions = ("png",) if "Preview" in name else ("png", "tga")
        for extension in extensions:
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