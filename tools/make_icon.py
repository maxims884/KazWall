"""Рисует иконку приложения.

    python tools/make_icon.py          # «Казахстан обои»: золотое солнце над снежными горами на бирюзовом фоне
    python tools/make_icon.py uzb      # «Узбекистан обои»: флаг Узбекистана

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
SKY_TOP, SKY_BOTTOM = (0, 163, 196), (64, 205, 226)
GOLD = (255, 199, 44)
S = 1024  # рисуем крупно, потом уменьшаем — так края гладкие


def sky(size):
    image = Image.new("RGB", (size, size))
    draw = ImageDraw.Draw(image)
    for y in range(size):
        t = y / (size - 1)
        draw.line([(0, y), (size, y)], fill=tuple(int(SKY_TOP[i] + (SKY_BOTTOM[i] - SKY_TOP[i]) * t) for i in range(3)))
    return image.convert("RGBA")


# Цвета флага Узбекистана
UZ_BLUE, UZ_RED, UZ_GREEN = (0, 153, 181), (206, 17, 38), (30, 181, 58)


def flag_stripes(size, box):
    """Полосы флага Узбекистана. box — какую долю холста видно: у адаптивной иконки края обрезает маска,
    поэтому полосы размечены по видимой середине, а крайние уходят за неё"""
    image = Image.new("RGBA", (size, size), UZ_GREEN + (255,))
    draw = ImageDraw.Draw(image)
    top, side = size * (1 - box) / 2, size * box
    draw.rectangle((0, 0, size, top + side * 0.47), fill=UZ_RED)
    draw.rectangle((0, 0, size, top + side * 0.44), fill=UZ_BLUE)
    draw.rectangle((0, top + side * 0.47, size, top + side * 0.63), fill="white")
    draw.rectangle((0, top + side * 0.63, size, top + side * 0.66), fill=UZ_RED)
    return image


def flag_symbols(size, box):
    """Полумесяц и двенадцать звёзд на синей полосе"""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    left = top = size * (1 - box) / 2
    side = size * box
    mx, my, mr = left + side * 0.27, top + side * 0.23, side * 0.125
    draw.ellipse((mx - mr, my - mr, mx + mr, my + mr), fill="white")
    draw.ellipse((mx - mr * 0.55, my - mr * 0.92, mx + mr * 1.3, my + mr * 0.92), fill=(0, 0, 0, 0))
    # Звёзды в три ряда: 3, 4 и 5, выровнены по правому краю
    for row, count in enumerate((3, 4, 5)):
        for i in range(count):
            sx = left + side * (0.73 - 0.082 * i)
            sy = top + side * (0.13 + 0.10 * row)
            points = []
            for k in range(10):
                angle = -math.pi / 2 + math.pi * k / 5
                r = side * (0.033 if k % 2 == 0 else 0.014)
                points.append((sx + r * math.cos(angle), sy + r * math.sin(angle)))
            draw.polygon(points, fill="white")
    return layer


def artwork(size, scale):
    """Солнце и горы на прозрачном фоне; scale — какую долю холста занимает рисунок"""
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
    full = Image.alpha_composite(flag_stripes(S, 1), flag_symbols(S, 1)) if UZB else         Image.alpha_composite(sky(S), artwork(S, 0.86))
    mask = Image.new("L", (S, S), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, S - 1, S - 1), int(S * 0.22), fill=255)
    rounded = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    rounded.paste(full, (0, 0), mask)
    # Адаптивная иконка: рисунок помещается в безопасную середину, фон заливает всё
    # (видимая часть адаптивной иконки — средние две трети холста)
    foreground = flag_symbols(S, 2 / 3) if UZB else artwork(S, 0.56)
    background = flag_stripes(S, 2 / 3) if UZB else sky(S)

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
