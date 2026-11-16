import argparse
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageOps
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
REFERENCE_SIZE = (168, 60)
ICONS = (
    ("CharacterStatus", (5, 4, 56, 56)),
    ("Titles", (59, 4, 110, 56)),
    ("EquipmentManager", (113, 4, 164, 56)),
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


def themed_icon(image, theme):
    if theme == "Dark":
        return image.copy()
    base = THEMES[theme]
    shadow = tuple(round(channel * 255 * 0.35) for channel in base)
    highlight = tuple(round((channel + (1 - channel) * 0.5) * 255) for channel in base)
    result = ImageOps.colorize(ImageOps.grayscale(image), shadow, highlight, blackpoint=0, whitepoint=125)
    result.putalpha(image.getchannel("A"))
    glyph_mask = Image.new("L", image.size, 0)
    glyph_mask.putdata([
        max(0, min(255, round((max(red, green, blue) - min(red, green, blue) - 8) * 255 / 12)))
        for red, green, blue, alpha in image.getdata()
    ])
    result.paste(image, (0, 0), glyph_mask)
    if result.getchannel("A").tobytes() != image.getchannel("A").tobytes():
        raise RuntimeError("Theme recoloring changed icon transparency")
    for original, recolored, strength in zip(image.getdata(), result.getdata(), glyph_mask.getdata()):
        if strength == 255 and original != recolored:
            raise RuntimeError("Theme recoloring changed a preserved glyph pixel")
    return result


def main():
    parser = argparse.ArgumentParser(description="Extract FFXIV character sidebar buttons from RawSidebarIcons.png.")
    parser.add_argument("--all-themes", action="store_true", help="Export all eight themes while preserving the glyph colors.")
    parser.add_argument("--overwrite", action="store_true", help="Replace existing generated icons; the source is never modified.")
    arguments = parser.parse_args()
    source_path = ROOT / "RawSidebarIcons.png"
    if not source_path.is_file():
        raise SystemExit(f"Source image not found: {source_path}")
    with Image.open(source_path) as raw:
        source = raw.convert("RGBA")
    scale_x, scale_y = source.width / REFERENCE_SIZE[0], source.height / REFERENCE_SIZE[1]
    for name, bounds in ICONS:
        left, top, right, bottom = bounds
        bounds = (round(left * scale_x), round(top * scale_y), round(right * scale_x), round(bottom * scale_y))
        image = source.crop(bounds)
        mask = Image.new("L", (image.width * 4, image.height * 4), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            (4, 4, mask.width - 5, mask.height - 5), radius=round(8 * min(scale_x, scale_y) * 4), fill=255
        )
        image.putalpha(mask.resize(image.size, Image.Resampling.LANCZOS))
        image = image.resize((64, 64), Image.Resampling.LANCZOS)
        for theme in THEMES if arguments.all_themes else ("Dark",):
            themed = themed_icon(image, theme)
            suffix = theme.replace(" ", "-")
            for extension in ("png", "tga"):
                destination = ROOT / f"Sidebar-{name}-{suffix}.{extension}"
                if destination.exists() and not arguments.overwrite:
                    print(f"Keeping existing {destination.name}")
                    continue
                themed.save(destination)
                with Image.open(destination) as exported:
                    exported.load()
                    if exported.convert("RGBA").tobytes() != themed.tobytes() or exported.size != (64, 64):
                        raise RuntimeError(f"Export verification failed: {destination}")
                print(f"Created {destination.name}: 64x64")


if __name__ == "__main__":
    main()