import argparse
from pathlib import Path
from statistics import median

try:
    from PIL import Image, ImageDraw, ImageOps
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
REFERENCE_SIZE = (866, 59)
TABS = (
    {
        "name": "Tab-Selected-Dark",
        "crop": (3, 11, 436, 54),
        "label": (185, 18, 260, 47),
        "sample": (85, 145),
        "outline": ((20, 13), (425, 13), (434, 22), (417, 49), (11, 49), (4, 39)),
    },
    {
        "name": "Tab-Inactive-Dark",
        "crop": (429, 11, 863, 54),
        "label": (530, 18, 762, 47),
        "sample": (475, 520),
        "outline": ((446, 13), (849, 13), (860, 24), (843, 50), (439, 50), (430, 40)),
    },
)
THEMES = {
    "Dark": ((0.25, 0.25, 0.24), (0.12, 0.12, 0.11)),
    "Light": ((0.45, 0.34, 0.24), (0.25, 0.16, 0.07)),
    "Classic FF": ((0.2, 0.15, 0.8), (0.05, 0.02, 0.38)),
    "Clear Blue": ((0.23, 0.34, 0.54), (0.05, 0.15, 0.36)),
    "Clear White": ((0.55, 0.56, 0.56), (0.36, 0.37, 0.37)),
    "Clear Green": ((0.18, 0.37, 0.07), (0.05, 0.19, 0.01)),
    "Clear Grey": ((0.3, 0.3, 0.3), (0.15, 0.15, 0.15)),
    "Clear Pink": ((0.88, 0.4, 0.74), (0.72, 0.23, 0.57)),
}


def extract(source, specification):
    scale_x = source.width / REFERENCE_SIZE[0]
    scale_y = source.height / REFERENCE_SIZE[1]

    def point(coordinates):
        horizontal, vertical = coordinates
        return round(horizontal * scale_x), round(vertical * scale_y)

    image = source.copy()
    left, top = point(specification["label"][:2])
    right, bottom = point(specification["label"][2:])
    sample_left, sample_right = (
        round(coordinate * scale_x) for coordinate in specification["sample"]
    )
    pixels = image.load()
    for vertical in range(top, bottom):
        samples = [source.getpixel((horizontal, vertical)) for horizontal in range(sample_left, sample_right)]
        color = tuple(round(median(sample[channel] for sample in samples)) for channel in range(3)) + (255,)
        for horizontal in range(left, right):
            pixels[horizontal, vertical] = color

    mask = Image.new("L", (image.width * 4, image.height * 4), 0)
    outline = [point(coordinates) for coordinates in specification["outline"]]
    ImageDraw.Draw(mask).polygon([(horizontal * 4, vertical * 4) for horizontal, vertical in outline], fill=255)
    image.putalpha(mask.resize(image.size, Image.Resampling.LANCZOS))
    crop = (*point(specification["crop"][:2]), *point(specification["crop"][2:]))
    return image.crop(crop)


def themed_tab(tab, theme, selected, specification, source_size):
    if theme == "Dark":
        return tab.copy()
    inactive_color, selected_color = THEMES[theme]
    base = selected_color if selected else inactive_color
    shadow = tuple(round(channel * 255 * 0.35) for channel in base)
    highlight = tuple(round((channel + (1 - channel) * 0.5) * 255) for channel in base)
    shaded = ImageOps.colorize(ImageOps.grayscale(tab), shadow, highlight, blackpoint=0, whitepoint=125)
    shaded.putalpha(tab.getchannel("A"))
    if selected:
        scale_x = source_size[0] / REFERENCE_SIZE[0]
        scale_y = source_size[1] / REFERENCE_SIZE[1]
        crop_left = round(specification["crop"][0] * scale_x)
        crop_top = round(specification["crop"][1] * scale_y)
        indicator = (round(4 * scale_x) - crop_left, round(29 * scale_y) - crop_top,
                     round(28 * scale_x) - crop_left, round(49 * scale_y) - crop_top)
        original = tab.crop(indicator)
        gold_mask = Image.new("L", original.size, 0)
        gold_mask.putdata([
            max(0, min(255, round((min(red, green) - blue - 8) * 255 / 32)))
            for red, green, blue, alpha in original.getdata()
        ])
        shaded.paste(original, indicator, gold_mask)
    return shaded


def main():
    parser = argparse.ArgumentParser(description="Extract text-free FFXIV tabs and optionally export all addon themes.")
    parser.add_argument("--all-themes", action="store_true", help="Export selected/inactive PNG and TGA files for all eight themes.")
    parser.add_argument("--overwrite", action="store_true", help="Replace existing generated tabs; RawTabs.png is never modified.")
    arguments = parser.parse_args()
    source_path = ROOT / "RawTabs.png"
    if not source_path.is_file():
        raise SystemExit(f"Source image not found: {source_path}")
    with Image.open(source_path) as raw:
        source = raw.convert("RGBA")
    for specification in TABS:
        tab = extract(source, specification)
        selected = specification["name"] == "Tab-Selected-Dark"
        for theme in THEMES if arguments.all_themes else ("Dark",):
            themed = themed_tab(tab, theme, selected, specification, source.size)
            canvas_size = tuple(1 << (dimension - 1).bit_length() for dimension in themed.size)
            canvas = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
            offset = tuple((outer - inner) // 2 for outer, inner in zip(canvas_size, themed.size))
            canvas.paste(themed, offset)
            theme_name = theme.replace(" ", "-")
            state = "Selected" if selected else "Inactive"
            for extension in ("png", "tga"):
                destination = ROOT / f"Tab-{state}-{theme_name}.{extension}"
                if destination.exists() and not arguments.overwrite:
                    print(f"Keeping existing {destination.name}")
                    continue
                canvas.save(destination)
                with Image.open(destination) as exported:
                    exported.load()
                    if exported.size != canvas.size or exported.convert("RGBA").tobytes() != canvas.tobytes():
                        raise RuntimeError(f"Export verification failed: {destination}")
                print(f"Created {destination.name}: {canvas.width}x{canvas.height}")


if __name__ == "__main__":
    main()