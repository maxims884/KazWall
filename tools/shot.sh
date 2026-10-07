#!/usr/bin/env bash
# Снимок экрана эмулятора: tools/shot.sh <имя> — кладёт store_listing/raw/<имя>.png
# (папка — переменная RAW: для «Узбекистан обои» это store_listing/uzb/raw)
# Эмулятор — планшет, экран телефона на нём задан командами: adb shell wm size 900x1600; wm density 350
ADB="${ADB:-$HOME/AppData/Local/Android/Sdk/platform-tools/adb}"
RAW="${RAW:-store_listing/raw}"
mkdir -p "$RAW"
"$ADB" exec-out screencap -p > "$RAW/_full.png"
python - "$RAW" "$1" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1] + "/_full.png").convert("RGB")
# На планшетном экране телефон стоит по центру, по бокам чёрные поля
left = (im.width - 900) // 2
im.crop((left, 0, left + 900, 1600)).save("%s/%s.png" % (sys.argv[1], sys.argv[2]))
print(sys.argv[2])
PY
rm -f "$RAW/_full.png"
