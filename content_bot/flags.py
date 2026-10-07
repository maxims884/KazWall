"""Обои с флагом страны: бот рисует их сам, потому что хороших фото флага на Commons почти нет.

Флаг (он в общественном достоянии) берётся с Commons, ему добавляются складки, как у ткани на ветру.
Два вида обоев: флаг во весь экран и фото страны из уже добавленных обоев, над которым развевается флаг.
"""
import io
import math
import random

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps

import country
import sources

SIZE = (1080, 1920)
FLAG_URL = "https://commons.wikimedia.org/wiki/Special:FilePath/%s?width=2400"

_flag = None


def flag():
    global _flag
    if _flag is None:
        _flag = Image.open(io.BytesIO(sources.download(FLAG_URL % country.data.FLAG_FILE))).convert("RGB")
    return _flag


def wave(image, rnd, amplitude=0.03, waves=2.2):
    """Складки ткани: столбцы картинки сдвигаются по синусоиде, склоны волны темнее и светлее.

    Возвращает картинку с прозрачными полями сверху и снизу: край ткани получается волнистым"""
    w, h = image.size
    a = h * amplitude
    length = w / waves
    phase = rnd.uniform(0, math.tau)
    pad = int(a * 1.4) + 2
    out = Image.new("RGBA", (w, h + pad * 2), (0, 0, 0, 0))
    light = Image.new("L", (w, 1))
    step = 4
    for x in range(0, w, step):
        angle = math.tau * x / length + phase
        # Вторая, более мелкая волна делает складки неровными
        dy = a * (math.sin(angle) + 0.35 * math.sin(angle * 2.3 + 1))
        out.paste(image.crop((x, 0, x + step, h)), (x, pad + int(dy)))
        shade = 128 + 34 * (math.cos(angle) + 0.35 * math.cos(angle * 2.3 + 1))
        for i in range(step):
            if x + i < w:
                light.putpixel((x + i, 0), max(0, min(255, int(shade))))
    light = light.resize(out.size).filter(ImageFilter.GaussianBlur(8))
    # Свет и тень поверх ткани
    lit = ImageChops.overlay(out.convert("RGB"), Image.merge("RGB", (light, light, light)))
    lit.putalpha(out.getchannel("A"))
    return lit


def vignette(image, strength=120):
    w, h = image.size
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).ellipse((-w * 0.35, -h * 0.2, w * 1.35, h * 1.2), fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(w // 4))
    dark = Image.new("RGB", (w, h), (0, 0, 0))
    return Image.composite(image, Image.blend(image, dark, strength / 255), mask)


def full(rnd):
    """Флаг во весь экран: видна его часть с главным символом"""
    w, h = SIZE
    source = flag()
    scale = h * 1.2 / source.height
    big = source.resize((int(source.width * scale), int(source.height * scale)), Image.LANCZOS)
    big = wave(big, rnd, amplitude=rnd.uniform(0.015, 0.025), waves=rnd.uniform(5, 8)).convert("RGB")
    # focus — где по ширине флага его символ; небольшой случайный сдвиг делает обои разными
    centre = big.width * (country.data.FLAG_FOCUS + rnd.uniform(-0.03, 0.03))
    left = int(max(0, min(big.width - w, centre - w / 2)))
    top = (big.height - h) // 2
    return vignette(big.crop((left, top, left + w, top + h)))


def over_photo(photo, rnd):
    """Фото страны, а над ним — флаг целиком, свисающий сверху, с волнистым нижним краем и тенью"""
    w, h = SIZE
    card = ImageOps.fit(photo.convert("RGB"), SIZE, Image.LANCZOS).convert("RGBA")
    source = flag()
    cloth = source.resize((w, int(source.height * w / source.width)), Image.LANCZOS)
    cloth = wave(cloth, rnd, amplitude=rnd.uniform(0.04, 0.06), waves=rnd.uniform(1.6, 2.6))
    # Верхний волнистый край уходит за экран
    top = -int(cloth.height * 0.17)
    shadow = Image.new("RGBA", SIZE, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, 150), (0, top + 26), cloth.getchannel("A"))
    card = Image.alpha_composite(card, shadow.filter(ImageFilter.GaussianBlur(22)))
    card.alpha_composite(cloth, (0, top))
    return card.convert("RGB")


def make(store, rnd):
    """Возвращает (картинку, поля для каталога, id) или None, если фото для фона ещё нет"""
    number = sum(1 for i in store.used if i.startswith("flag-")) + 1
    tags = list(country.data.FLAG_TAGS)
    # Каждые третьи обои — просто флаг, остальные — флаг с фото
    photos = [i for i in store.items if i["type"] in ("nature", "arch") and i.get("sourceUrl")]
    if number % 3 == 1 or not photos:
        return full(rnd), {"tags": tags}, "flag-%d" % number
    item = rnd.choice(photos)
    import os
    photo = Image.open(os.path.join(store.root, item["file"]))
    # Фон — чужое фото под свободной лицензией: автор и лицензия остаются при картинке
    fields = {"tags": tags + item.get("tags", [])[:8], "author": item.get("author"),
              "license": item.get("license"), "sourceUrl": item.get("sourceUrl")}
    return over_photo(photo, rnd), fields, "flag-%d" % number
