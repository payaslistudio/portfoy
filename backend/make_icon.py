"""Varlık Cüzdanı için basit uygulama ikonu üretir.

Konsept: yuvarlanmış-kare, sarı-turuncu gradient arkaplan, ortada beyaz cüzdan
sembolü ve içinde yükselen çubuk grafik.
"""
from __future__ import annotations

from pathlib import Path
from PIL import Image, ImageDraw

OUT_DIR = Path(__file__).parent.parent / "assets"
OUT_DIR.mkdir(parents=True, exist_ok=True)

SIZE = 1024


def gradient_bg(size: int) -> Image.Image:
    top = (255, 179, 0)      # amber
    mid = (255, 112, 67)     # orange
    bot = (171, 71, 188)     # purple
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        t = y / (size - 1)
        if t < 0.5:
            k = t / 0.5
            r = round(top[0] + (mid[0] - top[0]) * k)
            g = round(top[1] + (mid[1] - top[1]) * k)
            b = round(top[2] + (mid[2] - top[2]) * k)
        else:
            k = (t - 0.5) / 0.5
            r = round(mid[0] + (bot[0] - mid[0]) * k)
            g = round(mid[1] + (bot[1] - mid[1]) * k)
            b = round(mid[2] + (bot[2] - mid[2]) * k)
        for x in range(size):
            px[x, y] = (r, g, b, 255)
    return img


def rounded_mask(size: int, radius: int) -> Image.Image:
    m = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(m)
    d.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return m


def draw_wallet(img: Image.Image) -> None:
    d = ImageDraw.Draw(img)
    s = img.size[0]
    # Cüzdan gövdesi
    w = int(s * 0.62)
    h = int(s * 0.44)
    x = (s - w) // 2
    y = int(s * 0.34)
    r = int(s * 0.05)
    # Ana gövde beyaz
    d.rounded_rectangle((x, y, x + w, y + h), radius=r, fill=(255, 255, 255, 255))
    # Cüzdan flap (üst şerit)
    flap_h = int(h * 0.28)
    d.rounded_rectangle(
        (x, y, x + w, y + flap_h),
        radius=r, fill=(255, 244, 219, 255),
    )
    # Kilit noktası
    lock_r = int(s * 0.028)
    lock_cx = x + w - int(s * 0.09)
    lock_cy = y + h // 2
    d.ellipse(
        (lock_cx - lock_r, lock_cy - lock_r, lock_cx + lock_r, lock_cy + lock_r),
        fill=(255, 179, 0, 255),
    )
    # Yükselen çubuk grafik (varlık büyümesi)
    bars_x0 = x + int(s * 0.10)
    bars_y1 = y + h - int(s * 0.06)
    bar_w = int(s * 0.055)
    gap = int(s * 0.018)
    heights = [int(s * 0.09), int(s * 0.13), int(s * 0.18), int(s * 0.22)]
    for i, hh in enumerate(heights):
        bx = bars_x0 + i * (bar_w + gap)
        color = (
            (255, 179, 0, 255),
            (255, 152, 0, 255),
            (255, 112, 67, 255),
            (171, 71, 188, 255),
        )[i]
        d.rounded_rectangle(
            (bx, bars_y1 - hh, bx + bar_w, bars_y1),
            radius=int(s * 0.012),
            fill=color,
        )


def main() -> None:
    bg = gradient_bg(SIZE)
    # Yuvarlanmış köşe için maske
    mask = rounded_mask(SIZE, int(SIZE * 0.22))
    icon = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    icon.paste(bg, (0, 0), mask=mask)
    draw_wallet(icon)
    icon.save(OUT_DIR / "icon.png")
    print(f"Wrote {OUT_DIR / 'icon.png'}")

    # Adaptive icon foreground (transparent bg, sadece cüzdan)
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_wallet(fg)
    fg.save(OUT_DIR / "icon_foreground.png")
    print(f"Wrote {OUT_DIR / 'icon_foreground.png'}")


if __name__ == "__main__":
    main()
