"""Generate Panel-Border-Dark.tga, a 32x32 nine-slice outline (8px corners).

Dark ring all around; a light ring just outside it fades in over the bottom
corner rows so the bottom edge reads as dark line over light line.
"""
import argparse
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError as error:
    raise SystemExit("Pillow is required: pip install pillow") from error

SIZE, SCALE, RADIUS = 32, 8, 8
DARK = (0, 0, 0, 217)
LIGHT = (255, 255, 255, 102)
FADE_START = 24


def ring(inset, radius, inner_radius=None):
    big = SIZE * SCALE
    mask = Image.new("L", (big, big), 0)
    outer = ImageDraw.Draw(mask)
    pad = inset * SCALE
    outer.rounded_rectangle((pad, pad, big - 1 - pad, big - 1 - pad), radius * SCALE, fill=255)
    inner = Image.new("L", (big, big), 0)
    pad += SCALE
    ImageDraw.Draw(inner).rounded_rectangle(
        (pad, pad, big - 1 - pad, big - 1 - pad), (inner_radius or max(1, radius - 1)) * SCALE, fill=255)
    return Image.composite(Image.new("L", (big, big), 0), mask, inner).resize(
        (SIZE, SIZE), Image.Resampling.LANCZOS)


def tint(mask, color, fade):
    layer = Image.new("RGBA", (SIZE, SIZE), color[:3] + (0,))
    pixels, source = layer.load(), mask.load()
    for y in range(SIZE):
        factor = fade(y)
        for x in range(SIZE):
            pixels[x, y] = color[:3] + (round(source[x, y] / 255 * color[3] * factor),)
    return layer


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=Path(__file__).with_name("Panel-Border-Dark.tga"))
    args = parser.parse_args()
    def ramp(y):
        return 0 if y < FADE_START else (y - FADE_START + 1) / (SIZE - FADE_START)

    light = tint(ring(0, RADIUS), LIGHT, ramp)
    # The dark line hugs the panel edge on top and sides, then steps in over the light line.
    # A tighter outer radius darkens the corner pixels where panel fill would show through.
    dark_edge = tint(ring(0, RADIUS - 2, RADIUS - 1), DARK, lambda y: 1 - ramp(y))
    dark_inset = tint(ring(1, RADIUS - 1), DARK, ramp)
    image = Image.alpha_composite(Image.alpha_composite(light, dark_edge), dark_inset)
    image.save(args.output)
    print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
