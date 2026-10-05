#!/usr/bin/env bash
# Снимает шесть экранов приложения для скриншотов Google Play на одном языке:
#     tools/capture.sh ru|kk|en
# Нужен запущенный эмулятор с экраном 900x1600 (adb shell wm size 900x1600; adb shell wm density 350),
# отладочная сборка с --dart-define=NO_ADS=true --dart-define=DEMO_NAME=…, тёмная тема
# и одна вертикальная картинка в избранном (она попадёт на экран "просмотр").
# Снимки кладутся в store_listing/raw/<язык>/, дальше их собирает store_listing/make_screenshots.py
set -e
LANG_CODE="$1"
ONLY="$2"   # необязательно: снять только один экран, например editor
ADB="${ADB:-$HOME/AppData/Local/Android/Sdk/platform-tools/adb}"
PKG=kz.black13.kazakhstanwallpaper
case "$LANG_CODE" in ru) LANG_Y=764; NATURE_X=740 ;; kk) LANG_Y=886; NATURE_X=798 ;; en) LANG_Y=1009; NATURE_X=635 ;; *) echo "язык: ru, kk или en"; exit 1 ;; esac

tap() { "$ADB" shell input tap "$1" "$2"; sleep "${3:-2}"; }
back() { "$ADB" shell input keyevent 4; sleep 1; }
restart() {
  "$ADB" shell am force-stop $PKG
  "$ADB" shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
  sleep 14
}
shot() { if [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; then tools/shot.sh "$LANG_CODE/$1"; fi; }
mkdir -p "store_listing/raw/$LANG_CODE"

restart
tap 847 115          # настройки
tap 450 1468         # язык
tap 380 $LANG_Y
shot settings
back
restart
tap 50 226 4         # избранное
tap 230 650 7        # первая картинка
shot viewer
back
tap 400 226 5        # открытки
shot cards
tap 668 650 6        # вторая открытка
tap 223 1398 6       # открытка с именем
tap 168 1243 1       # жёлтый текст
shot editor
back; back
restart
tap $NATURE_X 226 5  # первый скриншот — вкладка "Природа": в ленте порядок каждый раз случайный
shot feed
tap 847 115          # настройки → светлая тема
tap 450 1243
back
restart
shot feed_light
tap 847 115          # вернуть тёмную
tap 727 1243
back
