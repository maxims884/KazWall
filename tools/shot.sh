#!/usr/bin/env bash
# Снимок экрана эмулятора: tools/shot.sh <имя> — кладёт store_listing/raw/<имя>.png
# Эмулятор — планшет, экран телефона на нём задан командами: adb shell wm size 900x1600; wm density 350
ADB="${ADB:-$HOME/AppData/Local/Android/Sdk/platform-tools/adb}"
mkdir -p store_listing/raw
"$ADB" exec-out screencap -p > store_listing/raw/_full.png
python - "$1" <<'PY'
import sys
from PIL import Image
im = Image.open("store_listing/raw/_full.png").convert("RGB")
# На планшетном экране телефон стоит по центру, по бокам чёрные поля
left = (im.width - 900) // 2
im.crop((left, 0, left + 900, 1600)).save("store_listing/raw/%s.png" % sys.argv[1])
print(sys.argv[1])
PY
rm -f store_listing/raw/_full.png
