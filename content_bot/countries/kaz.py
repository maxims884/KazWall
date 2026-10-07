"""Казахстан: что искать на Commons, поздравления для открыток и даты праздников.

Казахские тексты стоит показать носителю языка и поправить прямо здесь.
"""

# Как страна называется в категориях Commons
TITLE = "Kazakhstan"
# Папка с контентом рядом с ботом (ветка content, подключённая как git worktree)
CONTENT_DIR = "content"
# Подпись приложения на открытке
BRAND = {"kk": "Қазақстан тұсқағаздары", "ru": "Казахстан обои"}
# Открытки делаются на этом языке и на русском
LOCAL_LANG = "kk"
CARD_TAGS = ["открытка", "ашық хат", "card"]
# Строгий отбор: без людей, только известные места в архитектуре (списки слов — в sources.py)
STRICT = True

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

# Флаг для обоев с флагом (flags.py): файл на Commons и где по ширине флага его главный символ
FLAG_FILE = "Flag_of_Kazakhstan.svg"
FLAG_FOCUS = 0.5
FLAG_TAGS = ["Flag", "флаг", "ту", "байрақ", "Казахстан", "Қазақстан"]

# Особая подборка: яркие, колоритные кадры. Ключ — категория приложения, куда они попадут.
# Отбор у неё нестрогий (люди, еда, базары и праздники разрешены), но цвета должны быть насыщенными
SPECIAL_QUERIES = {
    "colorful": {
        "nature": [
            'deepcat:"Sunsets of Kazakhstan" filew:>1800',
            'deepcat:"Autumn in Kazakhstan" filew:>1800',
            'deepcat:"Tulips in Kazakhstan" filew:>1800',
        ],
        "culture": [
            'deepcat:"Nowruz in Kazakhstan" filew:>1800',
            'deepcat:"Traditional clothing of Kazakhstan" filew:>1800',
            'deepcat:"Kazakh yurts" filew:>1800',
            'deepcat:"Yurts in Kazakhstan" filew:>1800',
            'deepcat:"Markets in Kazakhstan" filew:>1800',
            'deepcat:"Horse riding in Kazakhstan" filew:>1800',
            'deepcat:"Kazakh ornaments" filew:>1800',
        ],
        "arch": [
            'deepcat:"Views of Astana" filew:>1800',
            'deepcat:"Views of Almaty" filew:>1800',
            'deepcat:"Skyscrapers in Astana" filew:>1800',
        ],
    },
}

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

# Перевод частых тегов, чтобы поиск в приложении находил их по-русски и по-казахски
TAG_TRANSLATIONS = {
    "flag": ["флаг", "ту"],
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

# Поводы для открыток: заголовок и пожелание на казахском и русском,
# плюс запросы для поиска фона (фото CC0 / public domain на Openverse)
OCCASIONS = {
    "morning": {
        "kk": [("Қайырлы таң!", "Күніңіз сәтті өтсін"), ("Таңыңыз қайырлы болсын!", "Жақсы көңіл күй тілеймін"),
               ("Қайырлы таң!", "Көңіл күйіңіз көтеріңкі болсын")],
        "ru": [("Доброе утро!", "Хорошего дня и отличного настроения"), ("С добрым утром!", "Пусть день будет удачным"),
               ("Доброго утра!", "Улыбок и тепла")],
        "backgrounds": ["sunrise", "morning flowers", "morning coffee", "sunrise mountains"],
    },
    "evening": {
        "kk": [("Қайырлы түн!", "Тыныш ұйықтаңыз"), ("Қайырлы кеш!", "Жақсы демалыңыз"),
               ("Тәтті түс көріңіз!", "Қайырлы түн тілеймін")],
        "ru": [("Спокойной ночи!", "Сладких снов"), ("Добрый вечер!", "Уютного вечера"),
               ("Доброй ночи!", "Пусть сны будут светлыми")],
        "backgrounds": ["night sky stars", "moon night", "starry night", "candle evening"],
    },
    "friday": {
        "kk": [("Жұма мүбәрак болсын!", "Дұғаларыңыз қабыл болсын"),
               ("Жұмаңыз қабыл болсын!", "Үйіңізге береке, тыныштық тілеймін")],
        "ru": [("Благословенной пятницы!", "Пусть молитвы будут приняты"),
               ("Жума мубарак!", "Мира и благополучия вашему дому")],
        "backgrounds": ["mosque", "mosque sunset", "mosque night", "crescent moon"],
    },
    "birthday": {
        "kk": [("Туған күніңізбен!", "Бақыт, денсаулық, табыс тілеймін"),
               ("Туған күніңмен!", "Армандарың орындалсын"),
               ("Туған күніңіз құтты болсын!", "Ұзақ өмір, мол бақыт тілеймін")],
        "ru": [("С днём рождения!", "Счастья, здоровья и удачи"), ("С днём рождения!", "Пусть сбываются мечты"),
               ("Поздравляю с днём рождения!", "Радости и тепла каждый день")],
        "backgrounds": ["birthday cake", "balloons", "flowers bouquet", "roses"],
    },
    "nauryz": {
        "kk": [("Наурыз мейрамы құтты болсын!", "Ақ мол болсын, ұлыс оң болсын!"),
               ("Наурыз құтты болсын!", "Жаңа жыл береке әкелсін")],
        "ru": [("С праздником Наурыз!", "Пусть весна принесёт счастье и достаток"),
               ("Наурыз мейрамы!", "Мира, добра и благополучия вашему дому")],
        "backgrounds": ["tulips", "spring flowers", "blossom"],
    },
    "oraza_ait": {
        "kk": [("Ораза айт мүбәрак болсын!", "Оразаңыз, дұғаңыз қабыл болсын")],
        "ru": [("С праздником Ораза айт!", "Пусть пост и молитвы будут приняты")],
        "backgrounds": ["mosque", "crescent moon", "ramadan"],
    },
    "kurban_ait": {
        "kk": [("Құрбан айт мүбәрак болсын!", "Құрбандығыңыз қабыл болсын")],
        "ru": [("С праздником Курбан айт!", "Пусть жертва будет принята")],
        "backgrounds": ["mosque", "mosque sunset", "crescent moon"],
    },
    "new_year": {
        "kk": [("Жаңа жылыңызбен!", "Жаңа бақыт, жаңа табыс тілеймін")],
        "ru": [("С Новым годом!", "Пусть год будет счастливым")],
        "backgrounds": ["christmas lights", "snow winter", "fireworks"],
    },
    "mar8": {
        "kk": [("8 Наурыз мерекесімен!", "Әрдайым сұлу, бақытты болыңыз")],
        "ru": [("С 8 Марта!", "Весеннего настроения и улыбок")],
        "backgrounds": ["tulips", "flowers bouquet", "mimosa"],
    },
    "unity": {
        "kk": [("Бірлік күні құтты болсын!", "Еліміз аман, жұртымыз тыныш болсын")],
        "ru": [("С Днём единства народа Казахстана!", "Мира, дружбы и согласия")],
        "backgrounds": ["spring flowers", "tulips", "blossom"],
    },
    "defender": {
        "kk": [("Отан қорғаушылар күнімен!", "Күш-қуат, зор денсаулық тілеймін")],
        "ru": [("С Днём защитника Отечества!", "Силы, здоровья и удачи")],
        "backgrounds": ["mountains", "snow mountains"],
    },
    "victory": {
        "kk": [("Жеңіс күні құтты болсын!", "Батырлар ерлігі ұмытылмайды")],
        "ru": [("С Днём Победы!", "Помним и гордимся")],
        "backgrounds": ["fireworks", "carnations", "red tulips"],
    },
    "capital": {
        "kk": [("Астана күні құтты болсын!", "Елордамыз гүлдене берсін")],
        "ru": [("С Днём столицы!", "Пусть Астана растёт и процветает")],
        "backgrounds": ["fireworks", "city night", "skyline"],
    },
    "constitution": {
        "kk": [("Конституция күні құтты болсын!", "Еліміз өркендей берсін")],
        "ru": [("С Днём Конституции!", "Мира и благополучия нашему Казахстану")],
        "backgrounds": ["mountains", "steppe", "blue sky"],
    },
    "republic": {
        "kk": [("Республика күні құтты болсын!", "Қазақстаным, гүлдене бер!")],
        "ru": [("С Днём Республики!", "Процветания нашему Казахстану")],
        "backgrounds": ["mountains", "fireworks", "blue sky"],
    },
    "independence": {
        "kk": [("Тәуелсіздік күні құтты болсын!", "Тәуелсіздігіміз тұғырлы болсын!")],
        "ru": [("С Днём независимости!", "Мира и процветания Казахстану")],
        "backgrounds": ["snow mountains", "fireworks", "snow winter"],
    },
}

# Те же даты, что и в приложении (lib/services/holidays.dart).
# Айты — по объявлению ДУМК (муфтията), сверять каждый год
HOLIDAYS = {
    "new_year": ["01-01"],
    "mar8": ["03-08"],
    "nauryz": ["03-21"],
    "unity": ["05-01"],
    "defender": ["05-07"],
    "victory": ["05-09"],
    "capital": ["07-06"],
    "constitution": ["08-30"],
    "republic": ["10-25"],
    "independence": ["12-16"],
    "oraza_ait": ["2027-03-10", "2028-02-27", "2029-02-14", "2030-02-05"],
    "kurban_ait": ["2027-05-16", "2028-05-05", "2029-04-24", "2030-04-13"],
}

EVERYDAY = ["morning", "birthday", "evening", "morning", "birthday", "friday"]
