"""Листы с миниатюрами всех картинок по категориям — чтобы просмотреть контент разом.

    python contact_sheet.py ../content out

Под каждой картинкой — её номер в конце id: его понимает `python bot.py remove <номер>`.
"""
import json, sys, os
from PIL import Image, ImageDraw
root, out = sys.argv[1], sys.argv[2]
items = json.load(open(os.path.join(root, "catalog.json"), encoding="utf-8"))["items"]
groups = {}
for it in items: groups.setdefault(it["type"], []).append(it)
for t, its in groups.items():
    cols = 5; cell = (300, 320)
    for page in range(0, len(its), 20):
        chunk = its[page:page+20]
        rows = (len(chunk) + cols - 1) // cols
        sheet = Image.new("RGB", (cols*cell[0], rows*cell[1]), "white")
        d = ImageDraw.Draw(sheet)
        for i, it in enumerate(chunk):
            im = Image.open(os.path.join(root, it["thumb"])); im.thumbnail((290, 290))
            x, y = (i % cols)*cell[0], (i // cols)*cell[1]
            sheet.paste(im, (x+5, y+5))
            d.text((x+5, y+300), "%d %s" % (page+i, it["id"].split("-")[-1]), fill="black")
        sheet.save(os.path.join(out, "sheet_%s_%d.jpg" % (t, page//20)), quality=80)
        print(t, page//20, len(chunk))
