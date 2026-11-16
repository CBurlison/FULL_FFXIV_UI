"""Generate Bar-Pill.tga: a 32x16 white pill used as a 3-slice (8px caps, 16px middle)."""
from pathlib import Path

try:
    from PIL import Image, ImageDraw
except ImportError as error:
    raise SystemExit("Pillow is required: pip install pillow") from error

WIDTH, HEIGHT, SCALE = 32, 16, 8


def main():
    big = Image.new("L", (WIDTH * SCALE, HEIGHT * SCALE), 0)
    ImageDraw.Draw(big).rounded_rectangle(
        (0, 0, WIDTH * SCALE - 1, HEIGHT * SCALE - 1), HEIGHT * SCALE // 2, fill=255)
    alpha = big.resize((WIDTH, HEIGHT), Image.Resampling.LANCZOS)
    image = Image.new("RGBA", (WIDTH, HEIGHT), (255, 255, 255, 0))
    image.putalpha(alpha)
    output = Path(__file__).with_name("Bar-Pill.tga")
    image.save(output)
    print(f"Wrote {output}")


if __name__ == "__main__":
    main()
