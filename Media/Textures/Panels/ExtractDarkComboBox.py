import argparse
from pathlib import Path
from statistics import median

try:
    from PIL import Image, ImageDraw
except ModuleNotFoundError:
    raise SystemExit("Install Pillow first: py -m pip install Pillow")


ROOT = Path(__file__).resolve().parent
REFERENCES = ROOT.parent.parent / "References"


def scaled_crop(source, reference_size, bounds):
    scale_x = source.width / reference_size[0]
    scale_y = source.height / reference_size[1]
    left, top, right, bottom = bounds
    return source.crop((round(left * scale_x), round(top * scale_y),
                        round(right * scale_x), round(bottom * scale_y)))


def header(source, reference_size, bounds):
    image = scaled_crop(source, reference_size, bounds).resize((339, 32), Image.Resampling.LANCZOS)
    pixels = image.load()
    for vertical in range(image.height):
        samples = [image.getpixel((horizontal, vertical)) for horizontal in range(100, 240)]
        color = tuple(round(median(sample[channel] for sample in samples)) for channel in range(3)) + (255,)
        for horizontal in range(26, 323):
            pixels[horizontal, vertical] = color
    mask = Image.new("L", (339 * 4, 32 * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 339 * 4 - 1, 32 * 4 - 1), radius=16 * 4, fill=255)
    image.putalpha(mask.resize(image.size, Image.Resampling.LANCZOS))
    canvas = Image.new("RGBA", (512, 32))
    canvas.paste(image, (0, 0))
    return canvas


def menu_panel(source):
    image = scaled_crop(source, (347, 389), (14, 39, 335, 380))
    width, height = image.size
    sample = scaled_crop(source, (347, 389), (270, 200, 300, 240))
    color = tuple(round(median(pixel[channel] for pixel in sample.getdata())) for channel in range(3)) + (255,)
    pixels = image.load()
    border = max(4, round(width * 6 / 321))
    for vertical in range(border, height - border):
        for horizontal in range(border, width - border):
            pixels[horizontal, vertical] = color
    clean_edge = image.crop((width - border, 0, width, height))
    image.paste(clean_edge.transpose(Image.Transpose.FLIP_LEFT_RIGHT), (0, 0))
    mask = Image.new("L", image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, width - 1, height - 1), radius=border, fill=255)
    image.putalpha(mask)
    canvas = Image.new("RGBA", (64, 64))
    source_columns = (0, border, width - border, width)
    source_rows = (0, border, height - border, height)
    target_edges = (0, 8, 56, 64)
    for row in range(3):
        for column in range(3):
            piece = image.crop((source_columns[column], source_rows[row],
                                source_columns[column + 1], source_rows[row + 1]))
            size = (target_edges[column + 1] - target_edges[column],
                    target_edges[row + 1] - target_edges[row])
            canvas.paste(piece.resize(size, Image.Resampling.LANCZOS),
                         (target_edges[column], target_edges[row]))
    left_edge = canvas.crop((0, 0, 8, 64))
    right_edge = canvas.crop((56, 0, 64, 64)).transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    if left_edge.tobytes() != right_edge.tobytes():
        raise RuntimeError("Menu border verification failed: extracted side edges do not match")
    return canvas


def main():
    parser = argparse.ArgumentParser(description="Extract text-free FFXIV combo-box textures from the Dark references.")
    parser.add_argument("--overwrite", action="store_true", help="Replace previously extracted textures.")
    arguments = parser.parse_args()
    with Image.open(REFERENCES / "Dark-Combo-Box-1-Closed.png") as raw:
        closed = raw.convert("RGBA")
    with Image.open(REFERENCES / "Dark-Combo-Box-1-Open.png") as raw:
        opened = raw.convert("RGBA")
    images = {
        "ComboBox-Closed-Dark": header(closed, (351, 43), (5, 6, 344, 38)),
        "ComboBox-Open-Dark": header(opened, (347, 389), (5, 6, 342, 38)),
        "ComboBox-Menu-Dark": menu_panel(opened),
    }
    for name, image in images.items():
        for extension in ("png", "tga"):
            destination = ROOT / f"{name}.{extension}"
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