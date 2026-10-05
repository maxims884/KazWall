"""Бот контента для "Казахстан обои".

Каждый день добавляет 1 новые обои и 1–2 открытки. Сервера нет: картинки и список
catalog.json лежат в ветке content репозитория на GitHub, приложение читает их оттуда.
Бот только кладёт файлы в папку, а GitHub Actions делает commit и push.

    python bot.py daily                  # обычный ежедневный запуск
    python bot.py seed-cards --count 30  # первичное заполнение открыток
    python bot.py wallpapers --count 5   # добавить несколько обоев сразу
    python bot.py wallpapers --count 5 --type arch   # …в одну категорию
    python bot.py cards nauryz birthday  # открытки к выбранным поводам (названия — в texts.py)
    python bot.py remove <id> [<id>…]    # убрать картинки из приложения (второй раз бот их не возьмёт)

Папка с контентом — переменная CONTENT_DIR, по умолчанию ../content.
С --dry-run контент не трогается: картинки сохраняются в папку out/, чтобы посмотреть результат.
"""
import argparse
import datetime
import io
import json
import os
import random
import sys
import time

from PIL import Image

import cards
import sources
import texts

BRAND = {"kk": "Қазақстан тұсқағаздары", "ru": "Казахстан обои"}
WALLPAPER_TYPES = ["nature", "animals", "arch", "relig", "culture"]
# В каком порядке пополняются категории: природы больше всего, остальные по очереди
ROTATION = ["nature", "arch", "nature", "animals", "nature", "relig", "nature", "culture", "arch", "animals"]
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
MAX_PIXELS = 4_000_000  # ~1600x2500: хватает для экрана телефона, файл ~500 КБ
THUMB_WIDTH = 480       # миниатюра для сетки, ~30 КБ
# Не больше стольких кадров из одной серии почти одинаковых фото
MAX_PER_SERIES = 2


class Store:
    """Папка с контентом: images/<категория>/*.jpg, catalog.json для приложения и state.json для бота"""

    def __init__(self, dry_run):
        self.dry_run = dry_run
        self.root = OUT if dry_run else os.environ.get("CONTENT_DIR") or os.path.join(HERE, "..", "content")
        os.makedirs(self.root, exist_ok=True)
        self.catalog_path = os.path.join(self.root, "catalog.json")
        self.state_path = os.path.join(self.root, "state.json")
        self.items = self._read(self.catalog_path, {}).get("items", [])
        state = self._read(self.state_path, {})
        # Какие источники уже использованы, чтобы не загружать одно и то же дважды
        self.used = set(state.get("used", []))
        self.series = state.get("series", {})
        self.counter = state.get("counter", 0)

    @staticmethod
    def _read(path, default):
        if not os.path.exists(path):
            return default
        with open(path, encoding="utf-8") as f:
            return json.load(f)

    def save(self):
        catalog = {"version": 1, "updated": int(time.time() * 1000), "items": self.items}
        with open(self.catalog_path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(catalog, f, ensure_ascii=False, separators=(",", ":"))
        state = {"counter": self.counter, "series": self.series, "used": sorted(self.used)}
        with open(self.state_path, "w", encoding="utf-8", newline="\n") as f:
            json.dump(state, f, ensure_ascii=False, indent=0)

    def add(self, picture_type, name, image, thumb, size, fields, source_id):
        folder = os.path.join(self.root, "images", picture_type)
        os.makedirs(folder, exist_ok=True)
        with open(os.path.join(folder, name + ".jpg"), "wb") as f:
            f.write(image)
        with open(os.path.join(folder, name + "s.jpg"), "wb") as f:
            f.write(thumb)
        item = {"id": name, "type": picture_type,
                "file": "images/%s/%s.jpg" % (picture_type, name),
                "thumb": "images/%s/%ss.jpg" % (picture_type, name),
                "w": size[0], "h": size[1], "createdAt": int(time.time() * 1000)}
        item.update({k: v for k, v in fields.items() if v})
        # Новые картинки — в начале списка
        self.items.insert(0, item)
        self.used.add(source_id)
        self.save()
        print("  добавлено", picture_type, name)

    def remove(self, item_id):
        for item in self.items:
            # Можно указать id целиком или только его конец, например номер файла на Commons
            if item["id"] == item_id or item["id"].endswith("-" + item_id):
                for key in ("file", "thumb"):
                    path = os.path.join(self.root, item[key])
                    if os.path.exists(path):
                        os.remove(path)
                self.items.remove(item)
                self.save()
                print("убрано", item["id"])
                return True
        print("не найдено", item_id)
        return False


def file_name(kind, item_id):
    """Имя файла: время добавления и источник, чтобы имена не повторялись"""
    return "%d-%s-%s" % (int(time.time()), kind, item_id)


def jpeg(image, quality):
    out = io.BytesIO()
    image.save(out, "JPEG", quality=quality, optimize=True, progressive=True)
    return out.getvalue()


def prepare(image):
    """Основная картинка до ~4 Мп и миниатюра для сетки"""
    image = image.convert("RGB")
    if image.width * image.height > MAX_PIXELS:
        scale = (MAX_PIXELS / (image.width * image.height)) ** 0.5
        image = image.resize((int(image.width * scale), int(image.height * scale)), Image.LANCZOS)
    small = image.copy()
    small.thumbnail((THUMB_WIDTH, THUMB_WIDTH * 3))
    return jpeg(image, 80), jpeg(small, 72), image.size


def add_wallpaper(store, today, picture_type=None):
    picture_type = picture_type or ROTATION[store.counter % len(ROTATION)]
    store.counter += 1
    rnd = random.Random("%s-%d" % (today.isoformat(), store.counter))
    candidates = [c for c in sources.commons_candidates(picture_type, store.used, limit=40, rnd=rnd)
                  if store.series.get(c["series"], 0) < MAX_PER_SERIES]
    rnd.shuffle(candidates)
    for item in candidates:
        try:
            image = Image.open(io.BytesIO(sources.download(item["download"])))
            main, small, size = prepare(image)
        except Exception as e:
            print("  не скачалось", item["id"], e)
            continue
        name = file_name("wall", item["id"])
        fields = {k: item[k] for k in ("tags", "author", "license", "sourceUrl")}
        print("обои:", item["type"], item["license"], item["author"][:40])
        store.series[item["series"]] = store.series.get(item["series"], 0) + 1
        store.add(item["type"], name, main, small, size, fields, item["id"])
        return True
    print("обои: подходящих картинок не нашлось для", picture_type)
    store.save()
    return False


used_variants = {}


def add_card(store, occasion, today, index):
    rnd = random.Random("%s-%s-%d" % (today.isoformat(), occasion, index))
    data = texts.OCCASIONS[occasion]
    lang = "kk" if rnd.random() < 0.6 else "ru"
    # Варианты текста берём по очереди, чтобы в одной партии не было одинаковых открыток подряд
    key = (occasion, lang)
    used_variants[key] = used_variants.get(key, rnd.randrange(len(data[lang]))) + 1
    title, subtitle = data[lang][used_variants[key] % len(data[lang])]
    queries = list(data["backgrounds"])
    rnd.shuffle(queries)
    for query in queries:
        # Сначала вертикальные фото, если таких нет — любые (открытка обрежет по центру)
        try:
            candidates = sources.openverse_candidates(query, store.used, portrait=True) or \
                sources.openverse_candidates(query, store.used)
        except Exception as e:
            print("  openverse не ответил:", e)
            time.sleep(5)
            continue
        for item in candidates:
            try:
                background = sources.download(item["download"])
                if not cards.is_good_background(background):
                    print("  фон слишком тёмный или однотонный", item["id"])
                    continue
                card, text_at = cards.render(background, title, subtitle, BRAND[lang], seed=item["id"])
            except Exception as e:
                print("  фон не подошёл", item["id"], e)
                continue
            main, small, size = prepare(card)
            name = file_name(occasion, index)
            tags = [occasion, title.strip("!"), "открытка", "ашық хат", "card"]
            fields = {"tags": tags, "occasion": occasion, "lang": lang, "textAt": text_at,
                      "backgroundSource": item["sourceUrl"], "license": item["license"]}
            print("открытка:", occasion, lang, title)
            store.add("cards", name, main, small, size, fields, item["id"])
            return True
        time.sleep(1)
    print("открытка: не нашлось фона для", occasion)
    return False


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["daily", "daily-cards", "seed-cards", "wallpapers", "cards", "remove"])
    parser.add_argument("ids", nargs="*")
    parser.add_argument("--count", type=int, default=30)
    parser.add_argument("--type", choices=WALLPAPER_TYPES)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    store = Store(args.dry_run)
    today = datetime.date.today()

    if args.command in ("daily", "daily-cards"):
        if args.command == "daily":
            add_wallpaper(store, today)
        for i, occasion in enumerate(texts.occasions_for(today)):
            add_card(store, occasion, today, i)
    elif args.command == "wallpapers":
        for i in range(args.count):
            add_wallpaper(store, today, args.type)
            time.sleep(1)
    elif args.command == "seed-cards":
        # Для первичного наполнения: по одной на каждый праздник, остальное — повседневные поводы
        everyday = ["morning", "evening", "friday", "birthday"]
        plan = (list(texts.HOLIDAYS) + everyday * args.count)[:args.count]
        for i, occasion in enumerate(plan):
            add_card(store, occasion, today, 100 + i)
    elif args.command == "cards":
        for i, occasion in enumerate(args.ids):
            add_card(store, occasion, today, 200 + i)
    elif args.command == "remove":
        for item_id in args.ids:
            store.remove(item_id)
    return 0


if __name__ == "__main__":
    sys.exit(main())
