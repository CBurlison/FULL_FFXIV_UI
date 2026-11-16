import argparse
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageOps
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
SOURCE_ROOT = ROOT.parent / "Panels"
ARROWS = (
    ("Down", "RawDownArrow.png", (43, 36), (4, 3, 36, 35)),
    ("Side", "RawSideArrow.png", (37, 35), (2, 1, 35, 34)),
)
THEMES = {
    "Dark": (0.25, 0.25, 0.24),
    "Light": (0.45, 0.34, 0.24),
    "Classic FF": (0.2, 0.15, 0.8),
    "Clear Blue": (0.23, 0.34, 0.54),
    "Clear White": (0.55, 0.56, 0.56),
    "Clear Green": (0.18, 0.37, 0.07),
    "Clear Grey": (0.3, 0.3, 0.3),
    "Clear Pink": (0.88, 0.4, 0.74),
}


def extract(source, reference_size, bounds):
    scale_x = source.width / reference_size[0]
    scale_y = source.height / reference_size[1]
    left, top, right, bottom = bounds
    crop = (round(left * scale_x), round(top * scale_y), round(right * scale_x), round(bottom * scale_y))
    image = source.crop(crop).resize((64, 64), Image.Resampling.LANCZOS)
    mask = Image.new("L", (256, 256), 0)
    ImageDraw.Draw(mask).ellipse((4, 4, 251, 251), fill=255)
    image.putalpha(mask.resize(image.size, Image.Resampling.LANCZOS))
    return image


def themed_arrow(image, theme):
    if theme == "Light":
        return image.copy()
    base = THEMES[theme]
    shadow = tuple(round(channel * 255 * 0.15) for channel in base)
    highlight = tuple(round((channel + (1 - channel) * 0.8) * 255) for channel in base)
    shades = ImageOps.grayscale(image).point([round((value / 255) ** 1.8 * 255) for value in range(256)])
    result = ImageOps.colorize(shades, shadow, highlight)
    result.putalpha(image.getchannel("A"))
    if result.getchannel("A").tobytes() != image.getchannel("A").tobytes():
        raise RuntimeError("Recoloring changed the circular transparency mask")
    return result


def main():
    parser = argparse.ArgumentParser(description="Extract transparent FFXIV arrow buttons from the Light-mode sources.")
    parser.add_argument("--all-themes", action="store_true", help="Generate both arrows for all eight themes.")
    parser.add_argument("--overwrite", action="store_true", help="Replace generated arrows; source images are never modified.")
    arguments = parser.parse_args()
    for direction, filename, reference_size, bounds in ARROWS:
        source_path = SOURCE_ROOT / filename
        if not source_path.is_file():
            raise SystemExit(f"Source image not found: {source_path}")
    for direction, filename, reference_size, bounds in ARROWS:
        with Image.open(SOURCE_ROOT / filename) as raw:
            image = extract(raw.convert("RGBA"), reference_size, bounds)
        for theme in THEMES if arguments.all_themes else ("Light",):
            themed = themed_arrow(image, theme)
            if themed.getchannel("A").getextrema() != (0, 255):
                raise RuntimeError("Extracted arrow must have transparent corners and an opaque center")
            suffix = theme.replace(" ", "-")
            for extension in ("png", "tga"):
                destination = ROOT / f"Arrow-{direction}-{suffix}.{extension}"
                if destination.exists() and not arguments.overwrite:
                    print(f"Keeping existing {destination.name}")
                    continue
                themed.save(destination)
                with Image.open(destination) as exported:
                    exported.load()
                    if exported.size != (64, 64) or exported.convert("RGBA").tobytes() != themed.tobytes():
                        raise RuntimeError(f"Export verification failed: {destination}")
                print(f"Created {destination.name}: 64x64")


if __name__ == "__main__":
    main()