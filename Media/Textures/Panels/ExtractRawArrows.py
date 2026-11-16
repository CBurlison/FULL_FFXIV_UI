import argparse
from collections import Counter
from pathlib import Path
from statistics import median

try:
    from PIL import Image
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
SOURCES = {
    "Disabled": "RawLeftArrow-Disabled.png",
    "Enabled": "RawRightArrow-Enabled.png",
}


def extract(source):
    pixels = source.load()
    width, height = source.size
    border = [pixels[x, y][:3] for y in range(height) for x in range(width)
              if x < 4 or x >= width - 4 or y < 4 or y >= height - 4]
    background = tuple(round(median(pixel[channel] for pixel in border)) for channel in range(3))

    foreground_pixels = [pixels[x, y][:3] for y in range(height) for x in range(width)
                         if sum((pixels[x, y][channel] - background[channel]) ** 2
                                for channel in range(3)) >= 25 ** 2]
    foreground = Counter(foreground_pixels).most_common(1)[0][0]
    direction = tuple(foreground[channel] - background[channel] for channel in range(3))
    direction_length = sum(channel ** 2 for channel in direction)

    result = Image.new("RGBA", source.size, (0, 0, 0, 0))
    output = result.load()
    for y in range(height):
        for x in range(width):
            pixel = pixels[x, y][:3]
            offset = tuple(pixel[channel] - background[channel] for channel in range(3))
            alpha = max(0, min(1, sum(offset[channel] * direction[channel]
                                       for channel in range(3)) / direction_length))
            if alpha < 0.08:
                continue
            color = tuple(max(0, min(255, round((pixel[channel] - background[channel] * (1 - alpha)) / alpha)))
                          for channel in range(3))
            output[x, y] = color + (round(alpha * 255),)

    if result.getchannel("A").getbbox() is None:
        raise RuntimeError("Arrow extraction produced an empty image")
    return result


def main():
    parser = argparse.ArgumentParser(description="Extract enabled and disabled left/right arrow textures.")
    parser.add_argument("--overwrite", action="store_true", help="Replace previously extracted textures.")
    arguments = parser.parse_args()

    extracted = {}
    for state, filename in SOURCES.items():
        with Image.open(ROOT / filename) as raw:
            extracted[state] = extract(raw.convert("RGBA"))

    images = {
        ("Left", "Disabled"): extracted["Disabled"],
        ("Right", "Disabled"): extracted["Disabled"].transpose(Image.Transpose.FLIP_LEFT_RIGHT),
        ("Right", "Enabled"): extracted["Enabled"],
        ("Left", "Enabled"): extracted["Enabled"].transpose(Image.Transpose.FLIP_LEFT_RIGHT),
    }
    for (direction, state), image in images.items():
        for extension in ("png", "tga"):
            destination = ROOT / f"Arrow-{direction}-{state}.{extension}"
            if destination.exists() and not arguments.overwrite:
                print(f"Keeping existing {destination.name}")
                continue
            image.save(destination)
            with Image.open(destination) as exported:
                exported.load()
                if exported.convert("RGBA").tobytes() != image.tobytes():
                    raise RuntimeError(f"Export verification failed: {destination}")
            print(f"Created {destination.name}: {image.width}x{image.height}")


if __name__ == "__main__":
    main()