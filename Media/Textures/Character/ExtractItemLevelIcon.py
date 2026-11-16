from pathlib import Path
from statistics import median

try:
    from PIL import Image, ImageFilter
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT.parent.parent / "References" / "ItemLevelIcon.png"


def glyph_mask(image):
    candidates = set()
    for vertical in range(image.height):
        for horizontal in range(image.width):
            red, green, blue, alpha = image.getpixel((horizontal, vertical))
            if alpha and red > 65 and red - blue > 12 and green - blue > 5:
                candidates.add((horizontal, vertical))
    largest = set()
    while candidates:
        start = candidates.pop()
        component = {start}
        pending = [start]
        while pending:
            horizontal, vertical = pending.pop()
            for offset_y in (-1, 0, 1):
                for offset_x in (-1, 0, 1):
                    neighbor = (horizontal + offset_x, vertical + offset_y)
                    if neighbor in candidates:
                        candidates.remove(neighbor)
                        component.add(neighbor)
                        pending.append(neighbor)
        if len(component) > len(largest):
            largest = component
    if not largest:
        raise SystemExit("No connected gold glyph found in the reference")
    mask = Image.new("L", image.size, 0)
    for point in largest:
        mask.putpixel(point, 255)
    return mask.filter(ImageFilter.MaxFilter(3))


def main():
    with Image.open(SOURCE) as original:
        image = original.convert("RGBA")
    mask = glyph_mask(image)
    corners = [image.getpixel(point) for point in (
        (0, 0), (image.width - 1, 0),
        (0, image.height - 1), (image.width - 1, image.height - 1),
    )]
    background = tuple(median(pixel[channel] for pixel in corners) for channel in range(3))
    pixels = []
    for pixel, support in zip(image.getdata(), mask.getdata()):
        distance = max(abs(pixel[channel] - background[channel]) for channel in range(3))
        warmth = max(0.0, min(1.0, (pixel[0] - pixel[2] - 4) / 12))
        opacity = max(0.0, min(1.0, (distance - 12) / 64)) * warmth * support / 255
        if opacity == 0:
            pixels.append((0, 0, 0, 0))
            continue
        color = tuple(max(0, min(255, round(
            (pixel[channel] - background[channel] * (1 - opacity)) / opacity
        ))) for channel in range(3))
        pixels.append(color + (round(pixel[3] * opacity),))
    image.putdata(pixels)
    bounds = image.getchannel("A").getbbox()
    if not bounds:
        raise SystemExit("Background extraction produced an empty icon")
    glyph = image.crop(bounds)
    glyph.thumbnail((56, 56), Image.Resampling.LANCZOS)
    alpha = glyph.getchannel("A")
    glyph = glyph.convert("RGB").filter(ImageFilter.UnsharpMask(radius=0.7, percent=120, threshold=3))
    glyph.putalpha(alpha)
    output = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    output.paste(glyph, ((64 - glyph.width) // 2, (64 - glyph.height) // 2))
    for extension in ("png", "tga"):
        destination = ROOT / ("ItemLevel." + extension)
        output.save(destination)
        with Image.open(destination) as exported:
            if exported.size != (64, 64) or exported.convert("RGBA").tobytes() != output.tobytes():
                raise RuntimeError("Export verification failed: " + str(destination))
        print("Created " + str(destination))


if __name__ == "__main__":
    main()