"""Обложка для Google Play (feature graphic) 1024×500 на трёх языках.

Берёт три открытки из папки контента (ветка content, подключённая в ../content):
    python make_feature_graphic.py
"""
import json
import os

from PIL import Image, ImageDraw, ImageFilter

from make_screenshots import GOLD, HERE, background, font, rounded_mask, wrap

W, H = 1024, 500
CONTENT = os.path.join(HERE, "..", "content")
TEXTS = {
    "ru": ("Казахстан обои и открытки", "Новые картинки каждый день"),
    "kk": ("Қазақстан тұсқағаздары мен ашық хаттар", "Күн сайын жаңа суреттер"),
    "en": ("Kazakhstan Wallpapers & Cards", "New pictures every day"),
}
# Какие открытки показать на обложке
WANTED = ["nauryz", "republic", "birthday"]


def card_images(lang):
    with open(os.path.join(CONTENT, "catalog.json"), encoding="utf-8") as f:
        cards = [i for i in json.load(f)["items"] if i["type"] == "cards"]
    images = []
    for occasion in WANTED:
        same = [c for c in cards if c.get("occasion") == occasion]
        # Английских открыток нет — на английской обложке казахские
        best = [c for c in same if c.get("lang") == ("ru" if lang == "ru" else "kk")] or same
        images.append(Image.open(os.path.join(CONTENT, best[0]["file"])).convert("RGB"))
    return images


def make(lang):
    canvas = background((W, H)).convert("RGBA")
    # Три открытки веером справа
    positions = [(585, 95, -8), (700, 65, 0), (815, 95, 8)]
    for card, (x, y, angle) in zip(card_images(lang), positions):
        c = card.resize((196, 294), Image.LANCZOS).convert("RGBA")
        c.putalpha(rounded_mask(c.size, 18))
        shadow = Image.new("RGBA", (c.width + 60, c.height + 60), (0, 0, 0, 0))
        ImageDraw.Draw(shadow).rounded_rectangle((30, 40, 30 + c.width, 40 + c.height), 18, fill=(0, 0, 0, 160))
        shadow = shadow.filter(ImageFilter.GaussianBlur(14)).rotate(angle, expand=True, resample=Image.BICUBIC)
        rotated = c.rotate(angle, expand=True, resample=Image.BICUBIC)
        canvas.alpha_composite(shadow, (x - 30 - (shadow.width - c.width - 60) // 2, y - 30))
        canvas.alpha_composite(rotated, (x - (rotated.width - c.width) // 2, y - (rotated.height - c.height) // 2))

    draw = ImageDraw.Draw(canvas)
    title, subtitle = TEXTS[lang]
    size = 56
    while True:
        title_font = font("Montserrat[wght].ttf", size, b"ExtraBold")
        lines = wrap(draw, title, title_font, 470)
        if len(lines) <= 3 and all(draw.textlength(l, font=title_font) <= 470 for l in lines):
            break
        size -= 2
    y = (H - len(lines) * size * 1.12 - 90) / 2
    for line in lines:
        draw.text((56, y), line, font=title_font, fill="white")
        y += size * 1.12
    y += 22
    draw.line([(56, y), (150, y)], fill=GOLD, width=3)
    draw.polygon([(166, y - 8), (174, y), (166, y + 8), (158, y)], fill=GOLD)
    draw.line([(182, y), (276, y)], fill=GOLD, width=3)
    draw.text((56, y + 26), subtitle, font=font("Montserrat[wght].ttf", 30, b"Medium"), fill=(255, 255, 255, 220))

    out = os.path.join(HERE, "screenshots", lang)
    os.makedirs(out, exist_ok=True)
    canvas.convert("RGB").save(os.path.join(out, "feature_graphic.png"), optimize=True)
    print("готово", lang)


if __name__ == "__main__":
    for lang in TEXTS:
        make(lang)
