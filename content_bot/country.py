"""Для какой страны сейчас работает бот: у каждой свои запросы, тексты и своя папка с контентом.

Страна — файл в папке countries: kaz.py (Казахстан), uzb.py (Узбекистан).
Выбирается ключом --country или переменной COUNTRY, по умолчанию kaz.
"""
import importlib
import os

NAMES = sorted(f[:-3] for f in os.listdir(os.path.join(os.path.dirname(os.path.abspath(__file__)), "countries"))
               if f.endswith(".py") and not f.startswith("_"))
DEFAULT = os.environ.get("COUNTRY") or "kaz"

name = None
data = None


def use(country_name):
    global name, data
    name = country_name
    data = importlib.import_module("countries." + country_name)
    return data
