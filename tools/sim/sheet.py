"""Contact sheet of extracted frames (f_<ms>.png)."""
import argparse
import os

from PIL import Image, ImageDraw

ap = argparse.ArgumentParser()
ap.add_argument("src")
ap.add_argument("out")
ap.add_argument("--cols", type=int, default=5)
ap.add_argument("--crop", type=int, nargs=4)
ap.add_argument("--every", type=int, default=1)
ap.add_argument("--scale", type=float, default=0.35)
ap.add_argument("--t0", type=float, default=-1)
ap.add_argument("--t1", type=float, default=1e9)
ap.add_argument("--times", type=str, default="")
a = ap.parse_args()

names = sorted(n for n in os.listdir(a.src) if n.endswith((".png", ".jpg")))
names = [n for n in names if a.t0 <= int(n[2:9]) / 1000 <= a.t1]
if a.times:
    want = [float(v) for v in a.times.split(",")]
    names = [n for n in names if any(abs(int(n[2:9]) / 1000 - w) < 0.0005 for w in want)]
names = names[:: a.every]
tiles = []
for n in names:
    im = Image.open(os.path.join(a.src, n)).convert("RGB")
    if a.crop:
        im = im.crop(tuple(a.crop))
    im = im.resize((int(im.width * a.scale), int(im.height * a.scale)), Image.LANCZOS)
    d = ImageDraw.Draw(im)
    d.rectangle((0, 0, 90, 16), fill=(0, 0, 0))
    d.text((3, 2), f"{int(n[2:9]) / 1000:.3f}s", fill=(255, 255, 0))
    tiles.append(im)
if not tiles:
    raise SystemExit("no frames")
w, h = tiles[0].size
rows = (len(tiles) + a.cols - 1) // a.cols
sheet = Image.new("RGB", (a.cols * w + (a.cols - 1) * 4, rows * h + (rows - 1) * 4), (40, 40, 40))
for i, t in enumerate(tiles):
    sheet.paste(t, ((i % a.cols) * (w + 4), (i // a.cols) * (h + 4)))
sheet.save(a.out)
print(a.out, len(tiles), sheet.size)
