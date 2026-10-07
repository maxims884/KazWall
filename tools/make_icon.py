"""Рисует иконку приложения.

    python tools/make_icon.py          # «Казахстан обои»: золотое солнце над снежными горами на бирюзовом фоне
    python tools/make_icon.py uzb      # «Узбекистан обои»: бирюзовый купол под полумесяцем на синем фоне

Кладёт значки всех размеров в android/app/src/main/res и 512×512 для Google Play в store_listing
(для Узбекистана — в android/app/src/uzb/res и store_listing/uzb).
"""
import math
import os
import sys

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
UZB = sys.argv[1:] == ["uzb"]
RES = os.path.join(ROOT, "android", "app", "src", "uzb" if UZB else "main", "res")
STORE = os.path.join(ROOT, "store_listing", "uzb") if UZB else os.path.join(ROOT, "store_listing")
SKY_TOP, SKY_BOTTOM = ((16, 58, 150), (64, 140, 222)) if UZB else ((0, 163, 196), (64, 205, 226))
GOLD = (255, 199, 44)
S = 1024  # рисуем крупно, потом уменьшаем — так края гладкие


def sky(size):
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / (size - 1)
        draw.line([(0, y), (size, y)], fill=tuple(int(SKY_TOP[i] + (SKY_BOTTOM[i] - SKY_TOP[i]) * t) for i in range(3)))
    return image.convert("RGBA")


def dome(size, scale):
    """Купол самаркандского медресе с полумесяцем и звёздами, как на флаге Узбекистана"""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    c = size / 2
    u = size * scale / 2
    sand, sand_dark, tile, tile_dark = (238, 208, 158), (205, 168, 112), (40, 196, 204), (16, 146, 164)

    # Полумесяц и три звезды слева вверху
    mx, my, mr = c - u * 0.50, c - u * 0.52, u * 0.22
    draw.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill="white")
    draw.ellipse((mx - mr * 0.45, my - mr * 0.95, mx + mr * 1.35, my + mr * 0.85), fill=(0, 0, 0, 0))
    for sx, sy, r in ((c + u * 0.02, c - u * 0.74, 0.060), (c + u * 0.46, c - u * 0.60, 0.075),
                      (c + u * 0.70, c - u * 0.22, 0.055)):
        points = []
        for i in range(10):
            a = -math.pi / 2 + math.pi * i / 5
            rr = u * r * (1 if i % 2 == 0 else 0.42)
            points.append((sx + rr * math.cos(a), sy + rr * math.sin(a)))
        draw.polygon(points, fill="white")

    # Купол: чуть шире барабана и сходится в остриё
    base, top, radius = c + u * 0.34, c - u * 0.42, u * 0.44
    profile = []
    for i in range(61):
        h = i / 60
        w = radius * (0.88 + 0.24 * math.sin(math.pi * min(h / 0.55, 1))) * math.cos(h * math.pi / 2) ** 0.62
        profile.append((w, base - (base - top) * h))
    draw.polygon([(c - w, y) for w, y in profile] + [(c + w, y) for w, y in reversed(profile)], fill=tile)
    # Рёбра купола
    for k in (-0.62, -0.22, 0.22, 0.62):
        draw.line([(c + w * k, y) for w, y in profile], fill=tile_dark, width=max(2, int(u * 0.022)))
    # Шпиль
    draw.line([(c, top + u * 0.02), (c, top - u * 0.16)], fill=GOLD, width=max(2, int(u * 0.03)))
    draw.ellipse((c - u * 0.045, top - u * 0.13, c + u * 0.045, top - u * 0.04), fill=GOLD)

    # Барабан с поясом изразцов и стена с аркой; низ уходит за край холста — маска иконки обрежет
    draw.rectangle((c - radius * 0.94, base - u * 0.01, c + radius * 0.94, base + u * 0.22), fill=sand)
    draw.rectangle((c - radius * 0.94, base + u * 0.05, c + radius * 0.94, base + u * 0.13), fill=(27, 85, 173))
    for i in range(7):
        x = c - radius * 0.94 + radius * 1.88 * (i + 0.5) / 7
        d = u * 0.028
        draw.polygon([(x, base + u * 0.09 - d), (x + d, base + u * 0.09), (x, base + u * 0.09 + d),
                      (x - d, base + u * 0.09)], fill=GOLD)
    wall = base + u * 0.22
    draw.rectangle((c - u * 0.86, wall, c + u * 0.86, size), fill=sand)
    draw.rectangle((c - u * 0.86, wall, c + u * 0.86, wall + u * 0.05), fill=sand_dark)
    # Стрельчатая арка
    arch_w, arch_top, spring = u * 0.27, wall + u * 0.16, wall + u * 0.46
    side = [(arch_w * math.cos(t * math.pi / 40) ** 0.75, spring - (spring - arch_top) * math.sin(t * math.pi / 40))
            for t in range(21)]
    draw.polygon([(c - arch_w, size)] + [(c - x, y) for x, y in side] + [(c + x, y) for x, y in reversed(side)]
                 + [(c + arch_w, size)], fill=(27, 85, 173))
    return layer


def artwork(size, scale):
    """Солнце и горы на прозрачном фоне; scale — какую долю холста занимает рисунок"""
    if UZB:
        return dome(size, scale)
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    c = size / 2
    u = size * scale / 2  # половина стороны рисунка

    # Солнце с лучами, как на флаге
    sx, sy, r = c, c - u * 0.30, u * 0.27
    for i in range(24):
        a = math.tau * i / 24
        spread = math.tau / 24 * 0.32
        inner, outer = r * 1.22, r * 1.75
        draw.polygon([
            (sx + inner * math.cos(a - spread), sy + inner * math.sin(a - spread)),
            (sx + outer * math.cos(a), sy + outer * math.sin(a)),
            (sx + inner * math.cos(a + spread), sy + inner * math.sin(a + spread)),
        ], fill=GOLD)
    draw.ellipse((sx - r, sy - r, sx + r, sy + r), fill=GOLD)

    # Горы: дальняя гряда и ближняя со снежными шапками
    # Подножие уходит за край холста: маска иконки обрежет его сама
    base = size
    far = [(c - u * 0.55 - (base - c - u * 0.12) * 1.25, base), (c - u * 0.55, c + u * 0.12), (c - u * 0.15, c + u * 0.5),
           (c + u * 0.45, c - u * 0.02), (c + u * 0.45 + (base - c + u * 0.02) * 1.1, base)]
    draw.polygon(far, fill=(0, 104, 128))
    near = [(c - u * 0.2 - (base - c - u * 0.2) * 1.5, base), (c - u * 0.2, c + u * 0.2), (c + u * 0.25, c + u * 0.62),
            (c + u * 0.62, c + u * 0.35), (c + u * 0.62 + (base - c - u * 0.35) * 1.5, base)]
    draw.polygon(near, fill=(0, 72, 92))
    # Снег на вершинах
    draw.polygon([(c - u * 0.55, c + u * 0.12), (c - u * 0.72, c + u * 0.36), (c - u * 0.58, c + u * 0.30),
                  (c - u * 0.50, c + u * 0.40), (c - u * 0.40, c + u * 0.27)], fill="white")
    draw.polygon([(c + u * 0.45, c - u * 0.02), (c + u * 0.24, c + u * 0.26), (c + u * 0.38, c + u * 0.20),
                  (c + u * 0.47, c + u * 0.32), (c + u * 0.60, c + u * 0.18)], fill="white")
    draw.polygon([(c - u * 0.2, c + u * 0.2), (c - u * 0.40, c + u * 0.40), (c - u * 0.24, c + u * 0.36),
                  (c - u * 0.16, c + u * 0.46), (c - u * 0.03, c + u * 0.38)], fill=(236, 248, 251))
    return layer


def save(image, folder, name, size):
    path = os.path.join(RES, folder)
    os.makedirs(path, exist_ok=True)
    image.resize((size, size), Image.LANCZOS).save(os.path.join(path, name), optimize=True)


def main():
    # Обычная иконка (старые Android и Google Play): скруглённый квадрат
    full = Image.alpha_composite(sky(S), artwork(S, 0.86))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), int(S * 0.22), fill=255)
    rounded = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rounded.paste(full, (0, 0), mask)
    # Адаптивная иконка: рисунок помещается в безопасную середину, фон заливает всё
    foreground = artwork(S, 0.56)
    background = sky(S)

    for density, legacy, adaptive in (("mdpi", 48, 108), ("hdpi", 72, 162), ("xhdpi", 96, 216),
                                      ("xxhdpi", 144, 324), ("xxxhdpi", 192, 432)):
        save(rounded, "mipmap-" + density, "ic_launcher.png", legacy)
        save(foreground, "mipmap-" + density, "ic_launcher_foreground.png", adaptive)
        save(background, "mipmap-" + density, "ic_launcher_background.png", adaptive)

    os.makedirs(os.path.join(RES, "mipmap-anydpi-v26"), exist_ok=True)
    with open(os.path.join(RES, "mipmap-anydpi-v26", "ic_launcher.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="utf-8"?>\n'
                '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
                '    <background android:drawable="@mipmap/ic_launcher_background" />\n'
                '    <foreground android:drawable="@mipmap/ic_launcher_foreground" />\n'
                '</adaptive-icon>\n')

    os.makedirs(STORE, exist_ok=True)
    full.convert("RGB").resize((512, 512), Image.LANCZOS).save(os.path.join(STORE, "icon_512.png"), optimize=True)
    print("готово")


if __name__ == "__main__":
    main()
