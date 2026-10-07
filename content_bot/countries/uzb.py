"""Узбекистан: что искать на Commons, поздравления для открыток и даты праздников.

Узбекские тексты (латиница) стоит показать носителю языка и поправить прямо здесь.
Вместо ʻ и ʼ стоят ‘ и ’: они есть во всех шрифтах открыток.
"""

# Как страна называется в категориях Commons
TITLE = "Uzbekistan"
# Папка с контентом рядом с ботом (ветка content-uzb, подключённая как git worktree)
CONTENT_DIR = "content_uzb"
# Подпись приложения на открытке
BRAND = {"uz": "O‘zbekiston fon rasmlari", "ru": "Узбекистан обои"}
# Открытки делаются на этом языке и на русском
LOCAL_LANG = "uz"
CARD_TAGS = ["открытка", "tabriknoma", "otkritka", "card"]
# Нестрогий отбор: берём всё, кроме 18+, не-фотографий (карты, значки, сканы) и машин — см. sources.py.
# Люди, базары, еда, детали зданий, интерьеры здесь разрешены
STRICT = False
# Фото, в описании которого есть эти слова, но нет Uzbekistan, снято у соседей
FOREIGN_WORDS = ("kazakhstan", "almaty", "astana", "shymbulak", "kyrgyz", "bishkek", "issyk", "tajik", "dushanbe",
                 "turkmen", "ashgabat", "afghan", "china", "xinjiang")

# Запросы по категориям приложения
COMMONS_QUERIES = {
    "nature": [
        'deepcat:"Landscapes of Uzbekistan" filew:>1800',
        'deepcat:"Mountains of Uzbekistan" filew:>1800',
        'deepcat:"Lakes of Uzbekistan" filew:>1800',
        'deepcat:"Rivers of Uzbekistan" filew:>1800',
        'deepcat:"National parks of Uzbekistan" filew:>1800',
        'deepcat:"Protected areas of Uzbekistan" filew:>1800',
        'deepcat:"Charvak Reservoir" filew:>1800',
        'deepcat:"Chimgan" filew:>1800',
        'deepcat:"Chatkal Range" filew:>1800',
        'deepcat:"Aydar Lake" filew:>1800',
        'deepcat:"Zaamin National Park" filew:>1800',
        'deepcat:"Deserts of Uzbekistan" filew:>1800',
        'deepcat:"Kyzyl Kum" filew:>1800',
        'deepcat:"Flowers of Uzbekistan" filew:>1800',
        'deepcat:"Sunsets of Uzbekistan" filew:>1800',
        'deepcat:"Winter in Uzbekistan" filew:>1800',
        'deepcat:"Nature of Uzbekistan" filew:>1800',
    ],
    "animals": [
        'deepcat:"Animals of Uzbekistan" filew:>1800',
        'deepcat:"Mammals of Uzbekistan" filew:>1800',
        'deepcat:"Birds of Uzbekistan" filew:>1800',
        'deepcat:"Reptiles of Uzbekistan" filew:>1800',
        'deepcat:"Insects of Uzbekistan" filew:>1800',
        'deepcat:"Lepidoptera of Uzbekistan" filew:>1800',
        'deepcat:"Horses of Uzbekistan" filew:>1800',
        'deepcat:"Camels in Uzbekistan" filew:>1800',
    ],
    "arch": [
        'deepcat:"Registan" filew:>1800',
        'deepcat:"Shah-i-Zinda" filew:>1800',
        'deepcat:"Gur-e Amir" filew:>1800',
        'deepcat:"Itchan Kala" filew:>1800',
        'deepcat:"Po-i-Kalyan" filew:>1800',
        'deepcat:"Chor Minor" filew:>1800',
        'deepcat:"Lab-i Hauz" filew:>1800',
        'deepcat:"Kalta Minor" filew:>1800',
        'deepcat:"Amir Temur Square" filew:>1800',
        'deepcat:"Tashkent TV Tower" filew:>1800',
        'deepcat:"Tashkent City" filew:>1800',
        'deepcat:"Tashkent Metro" filew:>1800',
        'deepcat:"Khudayar Khan Palace" filew:>1800',
        'deepcat:"Ulugh Beg Observatory" filew:>1800',
        'deepcat:"Palaces in Uzbekistan" filew:>1800',
        'deepcat:"Fortresses in Uzbekistan" filew:>1800',
        'deepcat:"Buildings in Tashkent" filew:>1800',
        'deepcat:"Buildings in Samarkand" filew:>1800',
        'deepcat:"Buildings in Bukhara" filew:>1800',
        'deepcat:"Buildings in Khiva" filew:>1800',
        'deepcat:"Kokand" filew:>1800',
        'deepcat:"Shahrisabz" filew:>1800',
        'deepcat:"Termez" filew:>1800',
        'deepcat:"Monuments and memorials in Uzbekistan" filew:>1800',
        'deepcat:"Bridges in Uzbekistan" filew:>1800',
        'deepcat:"Fountains in Uzbekistan" filew:>1800',
        'deepcat:"Parks in Tashkent" filew:>1800',
        'deepcat:"Night in Tashkent" filew:>1800',
        'deepcat:"Domes in Uzbekistan" filew:>1800',
        'deepcat:"Iwans in Uzbekistan" filew:>1800',
        'deepcat:"Architecture of Uzbekistan" filew:>1800',
    ],
    "relig": [
        'deepcat:"Mosques in Uzbekistan" filew:>1800',
        'deepcat:"Madrasas in Uzbekistan" filew:>1800',
        'deepcat:"Mausoleums in Uzbekistan" filew:>1800',
        'deepcat:"Minarets in Uzbekistan" filew:>1800',
        'deepcat:"Bibi-Khanym Mosque" filew:>1800',
        'deepcat:"Kalyan Mosque" filew:>1800',
        'deepcat:"Minor Mosque" filew:>1800',
        'deepcat:"Mir-i-Arab Madrasa" filew:>1800',
        'deepcat:"Kukeldash Madrasah (Tashkent)" filew:>1800',
        'deepcat:"Churches in Uzbekistan" filew:>1800',
    ],
    "culture": [
        'deepcat:"Ceramics of Uzbekistan" filew:>1800',
        'deepcat:"Tiles in Uzbekistan" filew:>1800',
        'deepcat:"Mosaics in Uzbekistan" filew:>1800',
        'deepcat:"Ceilings in Uzbekistan" filew:>1800',
        'deepcat:"Doors in Uzbekistan" filew:>1800',
        'deepcat:"Bazaars in Uzbekistan" filew:>1800',
        'deepcat:"Chorsu Bazaar" filew:>1800',
        'deepcat:"Siyob Bazaar" filew:>1800',
        'deepcat:"Markets in Uzbekistan" filew:>1800',
        'deepcat:"Cuisine of Uzbekistan" filew:>1800',
        'deepcat:"Fruit of Uzbekistan" filew:>1800',
        'deepcat:"Textiles of Uzbekistan" filew:>1800',
        'deepcat:"Traditional clothing of Uzbekistan" filew:>1800',
        'deepcat:"Musical instruments of Uzbekistan" filew:>1800',
        'deepcat:"Nowruz in Uzbekistan" filew:>1800',
        'deepcat:"Art of Uzbekistan" filew:>1800',
    ],
}

# Флаг для обоев с флагом (flags.py): файл на Commons и где по ширине флага его главный символ
FLAG_FILE = "Flag_of_Uzbekistan.svg"
FLAG_FOCUS = 0.2
FLAG_TAGS = ["Flag", "флаг", "bayroq", "Узбекистан", "O‘zbekiston"]

# Особая подборка: яркие, колоритные кадры. Ключ — категория приложения, куда они попадут.
# Отбор у неё нестрогий (люди, еда, базары и праздники разрешены), но цвета должны быть насыщенными
SPECIAL_QUERIES = {
    "colorful": {
        "nature": [
            'deepcat:"Sunsets of Uzbekistan" filew:>1800',
            'deepcat:"Winter in Uzbekistan" filew:>1800',
        ],
        "culture": [
            'deepcat:"Bazaars in Uzbekistan" filew:>1800',
            'deepcat:"Chorsu Bazaar" filew:>1800',
            'deepcat:"Siyob Bazaar" filew:>1800',
            'deepcat:"Ceramics of Uzbekistan" filew:>1800',
            'deepcat:"Textiles of Uzbekistan" filew:>1800',
            'deepcat:"Silk in Uzbekistan" filew:>1800',
            'deepcat:"Souvenirs of Uzbekistan" filew:>1800',
            'deepcat:"Traditional clothing of Uzbekistan" filew:>1800',
            'deepcat:"Festivals in Uzbekistan" filew:>1800',
            'deepcat:"Nowruz in Uzbekistan" filew:>1800',
            'deepcat:"Dance of Uzbekistan" filew:>1800',
            'deepcat:"Cuisine of Uzbekistan" filew:>1800',
            'deepcat:"Fruit of Uzbekistan" filew:>1800',
            'deepcat:"Tiles in Uzbekistan" filew:>1800',
            'deepcat:"Ceilings in Uzbekistan" filew:>1800',
        ],
        "arch": [
            'deepcat:"Night in Samarkand" filew:>1800',
            'deepcat:"Registan at night" filew:>1800',
            'deepcat:"Night in Tashkent" filew:>1800',
            'deepcat:"Registan" filew:>1800',
            'deepcat:"Shah-i-Zinda" filew:>1800',
        ],
    },
}

# Перевод частых тегов, чтобы поиск в приложении находил их по-русски и по-узбекски
TAG_TRANSLATIONS = {
    "flag": ["флаг", "bayroq"],
    "tashkent": ["Ташкент", "Toshkent"], "samarkand": ["Самарканд", "Samarqand"],
    "bukhara": ["Бухара", "Buxoro"], "khiva": ["Хива", "Xiva"], "kokand": ["Коканд", "Qo‘qon"],
    "shahrisabz": ["Шахрисабз", "Shahrisabz"], "termez": ["Термез", "Termiz"],
    "fergana": ["Фергана", "Farg‘ona"], "andijan": ["Андижан", "Andijon"], "namangan": ["Наманган", "Namangan"],
    "nukus": ["Нукус", "Nukus"], "karakalpak": ["Каракалпакстан", "Qoraqalpog‘iston"],
    "registan": ["Регистан", "Registon"], "shah-i-zinda": ["Шахи-Зинда", "Shohizinda"],
    "gur-e amir": ["Гур-Эмир", "Go‘ri Amir"], "bibi-khanym": ["Биби-Ханым", "Bibixonim"],
    "itchan kala": ["Ичан-Кала", "Ichan qal’a"], "kalta minor": ["Кальта-Минар", "Kalta minor"],
    "kalyan": ["Калян", "Kalon"], "chor minor": ["Чор-Минор", "Chor Minor"],
    "lab-i hauz": ["Ляби-Хауз", "Labi hovuz"], "ulugh beg": ["Улугбек", "Ulug‘bek"],
    "amir temur": ["Амир Темур", "Amir Temur"], "timur": ["Тимур", "Temur"],
    "tashkent metro": ["метро", "metro"], "tv tower": ["телебашня", "teleminora"],
    "chimgan": ["Чимган", "Chimyon"], "charvak": ["Чарвак", "Chorvoq"], "aydar": ["Айдаркуль", "Aydarko‘l"],
    "aral sea": ["Арал", "Orol"], "kyzyl kum": ["Кызылкум", "Qizilqum"], "zaamin": ["Зааминь", "Zomin"],
    "chatkal": ["Чаткал", "Chotqol"], "amu darya": ["Амударья", "Amudaryo"], "syr darya": ["Сырдарья", "Sirdaryo"],
    "mosque": ["мечеть", "masjid"], "madrasa": ["медресе", "madrasa"], "minaret": ["минарет", "minora"],
    "mausoleum": ["мавзолей", "maqbara"], "church": ["церковь", "cherkov"], "cathedral": ["собор"],
    "dome": ["купол", "gumbaz"], "palace": ["дворец", "saroy"], "fortress": ["крепость", "qal’a"],
    "monument": ["памятник", "haykal"], "bridge": ["мост", "ko‘prik"], "museum": ["музей", "muzey"],
    "fountain": ["фонтан", "favvora"], "park": ["парк", "bog‘"], "bazaar": ["базар", "bozor"],
    "market": ["рынок", "bozor"], "ceramic": ["керамика", "kulolchilik"], "tiles in": ["плитка", "изразцы", "koshin"],
    "mosaic": ["мозаика", "mozaika"], "door": ["дверь", "eshik"], "ceiling": ["потолок", "shift"],
    "carpet": ["ковёр", "gilam"], "textile": ["ткань", "mato"], "suzani": ["сюзане", "so‘zana"],
    "plov": ["плов", "osh", "palov"], "pilaf": ["плов", "osh", "palov"], "bread": ["лепёшка", "хлеб", "non"],
    "fruit": ["фрукты", "meva"], "melon": ["дыня", "qovun"], "cuisine": ["кухня", "еда", "taom"],
    "mountain": ["горы", "tog‘"], "lake": ["озеро", "ko‘l"], "river": ["река", "daryo"],
    "desert": ["пустыня", "cho‘l", "sahro"], "reservoir": ["водохранилище", "suv ombori"],
    "waterfall": ["водопад", "sharshara"], "canyon": ["каньон", "dara"], "valley": ["долина", "vodiy"],
    "forest": ["лес", "o‘rmon"], "sunset": ["закат", "shafaq"], "winter": ["зима", "qish"], "snow": ["снег", "qor"],
    "night": ["ночь", "tun"], "flower": ["цветы", "gul"], "tulip": ["тюльпан", "lola"],
    "horse": ["лошадь", "ot"], "camel": ["верблюд", "tuya"], "bird": ["птица", "qush"],
    "stork": ["аист", "laylak"], "butterfl": ["бабочка", "kapalak"], "lizard": ["ящерица", "kaltakesak"],
    "nowruz": ["Навруз", "Navro‘z"],
}

# Поводы для открыток: заголовок и пожелание на узбекском и русском,
# плюс запросы для поиска фона (фото CC0 / public domain на Openverse)
OCCASIONS = {
    "morning": {
        "uz": [("Xayrli tong!", "Kuningiz xayrli o‘tsin"), ("Xayrli tong!", "Kayfiyatingiz doim a’lo bo‘lsin"),
               ("Assalomu alaykum!", "Bugungi kun omad olib kelsin")],
        "ru": [("Доброе утро!", "Хорошего дня и отличного настроения"), ("С добрым утром!", "Пусть день будет удачным"),
               ("Доброго утра!", "Улыбок и тепла")],
        "backgrounds": ["sunrise", "morning flowers", "morning coffee", "sunrise mountains"],
    },
    "evening": {
        "uz": [("Xayrli tun!", "Shirin tushlar ko‘ring"), ("Xayrli kech!", "Yaxshi dam oling"),
               ("Tuningiz osuda o‘tsin!", "Xayrli tun tilayman")],
        "ru": [("Спокойной ночи!", "Сладких снов"), ("Добрый вечер!", "Уютного вечера"),
               ("Доброй ночи!", "Пусть сны будут светлыми")],
        "backgrounds": ["night sky stars", "moon night", "starry night", "candle evening"],
    },
    "friday": {
        "uz": [("Juma muborak!", "Duolaringiz ijobat bo‘lsin"),
               ("Juma ayyomingiz muborak bo‘lsin!", "Xonadoningizga tinchlik va baraka tilayman")],
        "ru": [("Благословенной пятницы!", "Пусть молитвы будут приняты"),
               ("Жума мубарак!", "Мира и благополучия вашему дому")],
        "backgrounds": ["mosque", "mosque sunset", "mosque night", "crescent moon"],
    },
    "birthday": {
        "uz": [("Tug‘ilgan kuningiz bilan!", "Baxt, sog‘lik va omad tilayman"),
               ("Tug‘ilgan kuning bilan!", "Barcha orzularing ushalsin"),
               ("Tug‘ilgan kuningiz muborak bo‘lsin!", "Uzoq umr va katta baxt tilayman")],
        "ru": [("С днём рождения!", "Счастья, здоровья и удачи"), ("С днём рождения!", "Пусть сбываются мечты"),
               ("Поздравляю с днём рождения!", "Радости и тепла каждый день")],
        "backgrounds": ["birthday cake", "balloons", "flowers bouquet", "roses"],
    },
    "navruz": {
        "uz": [("Navro‘z bayrami muborak bo‘lsin!", "Yangi kun yangi baxt olib kelsin"),
               ("Navro‘z muborak!", "Xonadoningizga tinchlik va baraka tilayman")],
        "ru": [("С праздником Навруз!", "Пусть весна принесёт счастье и достаток"),
               ("Навруз муборак!", "Мира, добра и благополучия вашему дому")],
        "backgrounds": ["tulips", "spring flowers", "blossom"],
    },
    "ramazon_hayit": {
        "uz": [("Ramazon hayiti muborak bo‘lsin!", "Tutgan ro‘zalaringiz qabul bo‘lsin")],
        "ru": [("С праздником Рамазан хайит!", "Пусть пост и молитвы будут приняты")],
        "backgrounds": ["mosque", "crescent moon", "ramadan"],
    },
    "qurbon_hayit": {
        "uz": [("Qurbon hayiti muborak bo‘lsin!", "Qilgan qurbonliklaringiz qabul bo‘lsin")],
        "ru": [("С праздником Курбан хайит!", "Пусть жертва будет принята")],
        "backgrounds": ["mosque", "mosque sunset", "crescent moon"],
    },
    "new_year": {
        "uz": [("Yangi yilingiz bilan!", "Yangi yil baxt va omad olib kelsin")],
        "ru": [("С Новым годом!", "Пусть год будет счастливым")],
        "backgrounds": ["christmas lights", "snow winter", "fireworks"],
    },
    "defender": {
        "uz": [("Vatan himoyachilari kuni muborak!", "Kuch-quvvat va mustahkam sog‘lik tilayman")],
        "ru": [("С Днём защитников Родины!", "Силы, здоровья и удачи")],
        "backgrounds": ["mountains", "snow mountains"],
    },
    "mar8": {
        "uz": [("8-mart bayrami bilan!", "Doimo go‘zal va baxtli bo‘ling")],
        "ru": [("С 8 Марта!", "Весеннего настроения и улыбок")],
        "backgrounds": ["tulips", "flowers bouquet", "mimosa"],
    },
    "memory": {
        "uz": [("Xotira va qadrlash kuni", "Qahramonlar jasorati unutilmaydi")],
        "ru": [("День памяти и почестей", "Помним и гордимся")],
        "backgrounds": ["carnations", "red tulips", "candle evening"],
    },
    "independence": {
        "uz": [("Mustaqillik bayrami muborak bo‘lsin!", "Yurtimiz tinch, osmonimiz musaffo bo‘lsin")],
        "ru": [("С Днём независимости!", "Мира и процветания Узбекистану")],
        "backgrounds": ["fireworks", "mountains", "blue sky"],
    },
    "teacher": {
        "uz": [("O‘qituvchi va murabbiylar kuni muborak!", "Mehnatingiz uchun rahmat, ustoz")],
        "ru": [("С Днём учителя и наставника!", "Спасибо за ваш труд и терпение")],
        "backgrounds": ["flowers bouquet", "roses", "autumn leaves"],
    },
    "constitution": {
        "uz": [("Konstitutsiya kuni muborak bo‘lsin!", "Yurtimiz yanada obod bo‘lsin")],
        "ru": [("С Днём Конституции!", "Мира и благополучия нашему Узбекистану")],
        "backgrounds": ["snow mountains", "blue sky", "snow winter"],
    },
}

# Те же даты, что и в приложении (lib/services/holidays.dart).
# Хайиты — по объявлению Управления мусульман Узбекистана, сверять каждый год
HOLIDAYS = {
    "new_year": ["01-01"],
    "defender": ["01-14"],
    "mar8": ["03-08"],
    "navruz": ["03-21"],
    "memory": ["05-09"],
    "independence": ["09-01"],
    "teacher": ["10-01"],
    "constitution": ["12-08"],
    "ramazon_hayit": ["2027-03-10", "2028-02-27", "2029-02-14", "2030-02-05"],
    "qurbon_hayit": ["2027-05-16", "2028-05-05", "2029-04-24", "2030-04-13"],
}

EVERYDAY = ["morning", "birthday", "evening", "morning", "birthday", "friday"]
