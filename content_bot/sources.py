"""Где брать картинки законно.

Wikimedia Commons — фото Казахстана под свободными лицензиями. Для CC BY / CC BY-SA
обязательно указывать автора и лицензию: приложение показывает их под картинкой.
Openverse — только CC0 и public domain: никаких условий, поэтому из них делаем фоны открыток.
"""
import html
import random
import re
import time

import requests

USER_AGENT = "KazWallContentBot/1.0 (https://github.com/maxims884/KazWall)"
COMMONS_API = "https://commons.wikimedia.org/w/api.php"
OPENVERSE_API = "https://api.openverse.org/v1/images/"

session = requests.Session()
session.headers["User-Agent"] = USER_AGENT

# Отобранные сообществом Commons фото: с них начинаем, обычные берём, когда эти кончатся
BEST = ' incategory:"Quality images"'

# Запросы по категориям приложения. Порядок важен: сначала самые красивые места
COMMONS_QUERIES = {
    "nature": [
        'deepcat:"Landscapes of Kazakhstan" filew:>1800',
        'deepcat:"Charyn national park" filew:>1800',
        'deepcat:"Kolsay Lakes national park" filew:>1800',
        'deepcat:"Kaindy Lake" filew:>1800',
        'deepcat:"Bolshoye Almatinskoye lake" filew:>1800',
        'deepcat:"Burabay National Park" filew:>1800',
        'deepcat:"Tulips in Kazakhstan" filew:>1800',
        'deepcat:"Lakes of Kazakhstan" filew:>1800',
        'deepcat:"Mountains of Kazakhstan" filew:>1800',
        'deepcat:"National parks of Kazakhstan" filew:>1800',
        'deepcat:"Rivers of Kazakhstan" filew:>1800',
        'deepcat:"Protected areas of Kazakhstan" filew:>1800',
    ],
    "animals": [
        'deepcat:"Mammals of Kazakhstan" filew:>1800',
        'deepcat:"Birds of Kazakhstan" filew:>1800',
        'deepcat:"Horses of Kazakhstan" filew:>1800',
        'deepcat:"Camels in Kazakhstan" filew:>1800',
    ],
    # Архитектура — только известные места: в общих категориях зданий слишком много случайных кадров
    "arch": [
        'deepcat:"Bayterek Tower" filew:>1800',
        'deepcat:"Khan Shatyry Entertainment Center" filew:>1800',
        'deepcat:"Astana Opera" filew:>1800',
        'deepcat:"Palace of Peace and Reconciliation" filew:>1800',
        'deepcat:"Ak Orda Presidential Palace" filew:>1800',
        'deepcat:"Kazakh Eli monument" filew:>1800',
        'deepcat:"Hazrat Sultan Mosque" filew:>1800',
        'deepcat:"Skyscrapers in Astana" filew:>1800',
        'deepcat:"Kök Töbe" filew:>1800',
        'deepcat:"Medeu" filew:>1800',
        'deepcat:"Hotel Kazakhstan" filew:>1800',
        'deepcat:"Almaty Tower" filew:>1800',
        'deepcat:"Park of the First President" filew:>1800',
        'deepcat:"Republic Square, Almaty" filew:>1800',
        'deepcat:"Almaty Opera & Ballet Theatre" filew:>1800',
        'deepcat:"Views of Astana" filew:>1800',
        'deepcat:"Views of Almaty" filew:>1800',
        'deepcat:"Bridges in Kazakhstan" filew:>1800',
    ],
    "relig": [
        'deepcat:"Mosques in Kazakhstan" filew:>1800',
        'deepcat:"Astana Grand Mosque" filew:>1800',
        'deepcat:"Ascension Cathedral, Almaty" filew:>1800',
        'deepcat:"Mausoleum of Khoja Ahmed Yasawi" filew:>1800',
        'deepcat:"Mausoleums in Kazakhstan" filew:>1800',
        'deepcat:"Churches in Kazakhstan" filew:>1800',
    ],
    "culture": [
        'deepcat:"Yurts in Kazakhstan" filew:>1800',
        'deepcat:"Petroglyphs in Kazakhstan" filew:>1800',
        'deepcat:"Dombra" filew:>1800',
        'deepcat:"Ala kiyiz" filew:>1800',
        'deepcat:"Kazakh ornaments" filew:>1800',
        'deepcat:"Kazakh Museum of Folk Musical Instruments" filew:>1800',
    ],
}

# Фото с узнаваемыми людьми в коммерческом приложении без их согласия не берём
PEOPLE_WORDS = ("people", "portrait", "women", "men ", "men of", "children", "girls", "boys",
                "persons", "faces", "selfie", "musicians", "dancers", "wrestlers", "athletes",
                "politicians", "presidents", "singers", "actors", "actresses", "births", "deaths",
                "soldiers", "meetings", "visits", "ceremonies", "weddings", "prayer", "praying",
                "salah", "worship", "pilgrim", "tourists", "crowd", "festival", "events in", "demonstrat")

# Не обои: карты, схемы, документы, значки, детали зданий, транспорт и т.п.
JUNK_WORDS = ("maps of", "map of", "diagram", "logos", "coats of arms", "flags of", "stamps", "banknotes",
              "coins", "documents", "screenshots", "plaques", "signs", "text", "herbarium",
              "specimens", "skulls", "graves", "cemeter", "license plates", "black and white",
              "historical images", "old photographs", "panoramio needing",
              "manhole", "door", "window", "fence", "gate", "detail", "brick", "paving", "pipe", "stairs",
              "train", "locomotive", "railway", "rail transport", "rolling stock", "tram", "bus", "trolley",
              "automobile", "cars", "truck", "vehicle", "aircraft", "airport", "military", "missile", "weapon",
              "tank", "rocket", "graffiti", "garbage", "waste", "interior", "construction", "abandoned",
              "ruins", "market", "shop", "kiosk", "advertis", "parking", "bench", "street furniture",
              "taxiderm", "stuffed", "zoo", "skeleton", "dishes", "cuisine", "meat", "factory", "industr",
              "power line", "power station", "pipeline", "mine", "quarry",
              "360", "spherical", "photosphere", "satellite", "curtain", "restaurant", "cafe")

# В категорию фото попадает, только если в его названии или категориях Commons есть одно из этих слов.
# Иначе deepcat приносит всё подряд: в "пейзажах" оказываются люки и заборы
REQUIRE_WORDS = {
    "nature": ("lake", "mountain", "river", "canyon", "gorge", "valley", "steppe", "forest", "waterfall",
               "peak", "glacier", "landscape", "sunset", "sunrise", "desert", "dune", "nature reserve",
               "pass", "ridge", "alatau", "tian shan", "altai", "burabay", "kolsai", "kaindy", "charyn",
               "sea", "coast", "shore", "meadow", "hills", "rock formation", "cliff", "plateau", "reservoir",
               "island", "tulip", "sharyn", "kolsay", "almatinskoye", "aktau mountains", "bozzhyra", "ustyurt", "mangystau"),
    "animals": (),
    "arch": ("mosque", "cathedral", "church", "tower", "palace", "theatre", "theater", "opera", "monument",
             "memorial", "skyline", "bayterek", "baiterek", "khan shatyr", "pyramid", "museum", "university",
             "hotel", "square", "bridge", "mausoleum", "skyscraper", "panorama", "cityscape", "fountain",
             "triumphal", "circus", "library", "concert hall", "akorda", "nur alem", "expo", "medeu",
             "night in", "at night", "views of", "aerial", "bayterek", "shatyr", "park", "kök töbe", "kok tobe", "astana", "almaty"),
    "relig": ("mosque", "mausoleum", "church", "cathedral", "minaret", "temple", "monastery", "synagogue"),
    "culture": ("yurt", "ornament", "dombra", "carpet", "felt", "petroglyph", "balbal", "golden man",
                "handicraft", "craft", "saddle", "musical instrument", "jewel", "embroider", "tamgaly",
                "nauryz", "nowruz", "shanyrak", "kobyz", "tapestr"),
}

# В природу не берём снимки животных крупным планом: для них своя категория
FAUNA_WORDS = ("birds", "mammals", "reptil", "insect", "fauna", "animals", "lizard", "snake", "butterfl",
               "rodent", "aves", "spider", "beetle", "amphibia", "fish")

# Служебные категории Commons — для поиска бесполезны
SERVICE_CATEGORIES = (r"^(Images |Self-published|Uploaded|Files |Media |CC-|Taken with|Photographs by|"
                      r"Pages |Quality images|Featured|Valued|Wiki Loves|Supported by|Created with|"
                      r"License|GFDL|Photos by|Panoramics|Pictures by|Scans|Photographs taken|"
                      r"Flickr|Lens focal|Exposure|ISO speed|F-number|Uploads|Template|PD |Items with|"
                      r"Cultural heritage monuments|\d{4} in )")

# Перевод частых тегов, чтобы поиск в приложении находил их по-русски и по-казахски
TAG_TRANSLATIONS = {
    "lake": ["озеро", "көл"], "mountain": ["горы", "тау"], "river": ["река", "өзен"],
    "astana": ["Астана"], "almaty": ["Алматы"], "shymkent": ["Шымкент"], "turkistan": ["Туркестан", "Түркістан"],
    "turkestan": ["Туркестан", "Түркістан"], "aktau": ["Актау", "Ақтау"],
    "charyn": ["Чарын", "Шарын", "каньон", "шатқал"], "kolsai": ["Кольсай", "Көлсай"],
    "kaindy": ["Каинды", "Қайыңды"], "burabay": ["Боровое", "Бурабай"], "borovoe": ["Боровое", "Бурабай"],
    "balkhash": ["Балхаш", "Балқаш"], "caspian": ["Каспий"], "altai": ["Алтай"], "tian shan": ["Тянь-Шань"],
    "alatau": ["Алатау"], "medeu": ["Медеу"], "shymbulak": ["Шымбулак", "Шымбұлақ"],
    "big almaty": ["Большое Алматинское озеро", "Үлкен Алматы көлі"], "mangystau": ["Мангистау", "Маңғыстау"],
    "ustyurt": ["Устюрт", "Үстірт"], "bozzhyra": ["Бозжыра"], "altyn-emel": ["Алтын-Эмель", "Алтынемел"],
    "baikonur": ["Байконур", "Байқоңыр"], "bayterek": ["Байтерек", "Бәйтерек"], "baiterek": ["Байтерек", "Бәйтерек"],
    "khan shatyr": ["Хан Шатыр"], "yasawi": ["Яссауи", "Ясауи"], "steppe": ["степь", "дала"],
    "desert": ["пустыня", "шөл"], "yurt": ["юрта", "киіз үй"], "horse": ["лошадь", "жылқы", "ат"],
    "camel": ["верблюд", "түйе"], "eagle": ["орёл", "беркут", "бүркіт"], "saiga": ["сайгак", "ақбөкен"],
    "winter": ["зима", "қыс"], "snow": ["снег", "қар"], "sunset": ["закат", "күн батуы"],
    "forest": ["лес", "орман"], "canyon": ["каньон", "шатқал"], "waterfall": ["водопад", "сарқырама"],
    "glacier": ["ледник", "мұздық"], "valley": ["долина", "алқап"], "mosque": ["мечеть", "мешіт"],
    "mausoleum": ["мавзолей", "кесене"], "church": ["церковь", "шіркеу"], "cathedral": ["собор"],
    "monument": ["памятник", "ескерткіш"], "bridge": ["мост", "көпір"], "museum": ["музей"],
    "night": ["ночь", "түн"], "flower": ["цветы", "гүл"], "tulip": ["тюльпан", "қызғалдақ"],
}


def _clean(text):
    return html.unescape(re.sub(r"<[^>]+>", "", text or "")).strip()


def _tags(categories, title):
    text = " ".join(categories + [title]).lower()
    tags = []
    for key, translations in TAG_TRANSLATIONS.items():
        if key in text:
            tags += [key.title()] + translations
    for c in categories[:12]:
        if re.match(SERVICE_CATEGORIES, c):
            continue
        short = re.sub(r"\s+(of|in|from)\s+(the\s+)?Kazakhstan.*$", "", c).strip()
        if 2 < len(short) < 30:
            tags.append(short)
    return list(dict.fromkeys(tags))[:15]


def _search(query, offset):
    for attempt in range(3):
        r = session.get(COMMONS_API, params={
            "action": "query", "format": "json", "generator": "search", "gsrsearch": query,
            "gsrnamespace": 6, "gsrlimit": 50, "gsroffset": offset,
            "prop": "imageinfo", "iiprop": "url|size|extmetadata|mime",
            "iiurlwidth": 4000, "iiurlheight": 2400,
        }, timeout=60)
        if r.status_code == 429:
            time.sleep(5 * (attempt + 1))
            continue
        r.raise_for_status()
        return r.json()
    return {}


def commons_candidates(picture_type, used, limit=10, rnd=random):
    """Свободные по лицензии и ещё не использованные фото с Commons для категории приложения"""
    found = []
    # Запросы каждый раз в новом порядке, чтобы в приложении чередовались разные места
    queries = list(COMMONS_QUERIES[picture_type])
    rnd.shuffle(queries)
    # Два прохода: сначала отобранные сообществом "качественные изображения", потом остальные
    for suffix in (BEST, ""):
        for query in queries:
            offset = 0
            while len(found) < limit and offset < 1000:
                data = _search(query + suffix, offset)
                if "error" in data:
                    # Слишком большое дерево категорий для deepcat — пропускаем запрос
                    print("  commons:", data["error"].get("info", "")[:120])
                    break
                pages = data.get("query", {}).get("pages", {})
                if not pages:
                    break
                for page in sorted(pages.values(), key=lambda p: p.get("index", 0)):
                    # Без отметки качества берём только крупные снимки: мелкие — обычно старые "мыльницы"
                    item = _commons_item(page, picture_type, min_side=1200 if suffix else 2000)
                    if item and item["id"] not in used and item["id"] not in [f["id"] for f in found]:
                        found.append(item)
                if "continue" not in data:
                    break
                offset = data["continue"]["gsroffset"]
            if len(found) >= limit:
                return found
    return found


def _commons_item(page, picture_type, min_side=1200):
    info = (page.get("imageinfo") or [{}])[0]
    meta = info.get("extmetadata", {})
    value = lambda key: meta.get(key, {}).get("value", "")
    if info.get("mime") != "image/jpeg":
        return None
    width, height = info.get("width", 0), info.get("height", 0)
    if min(width, height) < min_side:
        return None
    # Очень широкие панорамы на экране телефона превращаются в узкую полоску
    if width > height * 2.2 or height > width * 2.5:
        return None
    if "personality" in value("Restrictions").lower():
        return None
    license_name = _clean(value("LicenseShortName"))
    if not re.match(r"^(CC0|Public domain|PD|CC BY(-SA)? [\d.]+)", license_name, re.I):
        return None
    categories = [c.strip() for c in value("Categories").split("|") if c.strip()]
    title = page["title"].replace("File:", "")
    text = " ".join(categories + [title]).lower()
    if any(w in text for w in PEOPLE_WORDS) or any(w in text for w in JUNK_WORDS):
        return None
    required = REQUIRE_WORDS[picture_type]
    if required and not any(w in text for w in required):
        return None
    if picture_type == "nature" and any(w in text for w in FAUNA_WORDS):
        return None
    return {
        "id": "commons-%s" % page["pageid"],
        # Серии почти одинаковых кадров называются одинаково и отличаются номером
        "series": re.sub(r"[\W\d_]+", "", re.sub(r"\.\w+$", "", title).lower())[:40],
        "download": info.get("thumburl") or info["url"],
        "type": picture_type,
        "tags": _tags(categories, title),
        "author": _clean(value("Artist"))[:120] or "Wikimedia Commons",
        "license": license_name,
        "sourceUrl": info.get("descriptionurl", ""),
    }


def openverse_candidates(query, used, portrait=None, limit=20):
    """Фото без каких-либо условий использования (CC0 и public domain)"""
    # Только фотографии с фотостоков: в остальных источниках много музейных предметов
    params = {"q": query, "license": "cc0,pdm", "size": "large", "page_size": 20,
              "category": "photograph", "source": "stocksnap,rawpixel,wordpress",
              "page": random.randint(1, 3), "mature": "false"}
    if portrait is not None:
        params["aspect_ratio"] = "tall" if portrait else "wide"
    r = session.get(OPENVERSE_API, params=params, timeout=60)
    if r.status_code != 200 and params["page"] > 1:
        params["page"] = 1
        r = session.get(OPENVERSE_API, params=params, timeout=60)
    r.raise_for_status()
    items = []
    for x in r.json().get("results", []):
        item_id = "openverse-" + x["id"]
        if item_id in used or not x.get("url"):
            continue
        if min(x.get("width") or 0, x.get("height") or 0) < 1080:
            continue
        tags = [t["name"] for t in (x.get("tags") or []) if t.get("name")]
        text = " ".join(tags + [x.get("title") or ""]).lower()
        # Поиск Openverse широкий: берём фото, только если запрос есть в его описании
        if not any(re.search(r"\b%s" % re.escape(w), text) for w in query.lower().split()):
            continue
        if re.search(r"\b(people|person|persons|woman|women|man|men|girl|girls|boy|boys|child|children|"
                     r"portrait|face|selfie|bride|groom|couple|family|model|hands?)\b", text):
            continue
        # На Rawpixel много старинных гравюр и рисунков — для открыток нужны современные фото
        if re.search(r"\b(illustration|drawing|engraving|vintage|antique|painting|sketch|print|poster|"
                     r"lithograph|etching|museum|manuscript|plate|watercolor|art)\b", text):
            continue
        items.append({
            "id": item_id,
            "download": x["url"],
            "tags": tags[:10],
            "author": _clean(x.get("creator"))[:120],
            "license": "CC0" if x.get("license") == "cc0" else "Public domain",
            "sourceUrl": x.get("foreign_landing_url") or "",
        })
        if len(items) >= limit:
            break
    return items


def download(url):
    for attempt in range(3):
        r = session.get(url, timeout=120)
        if r.status_code == 429:
            time.sleep(10 * (attempt + 1))
            continue
        r.raise_for_status()
        return r.content
    r.raise_for_status()
