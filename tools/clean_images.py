#!/usr/bin/env python3
"""Räumt freigestellte Bilder automatisch auf (alle ausser puzzle_*).

- entfernt kleine, vom Motiv getrennte Reste (z. B. cremefarbene Hintergrundinseln)
- entfernt fast unsichtbare Halbtransparenz am Rand
- macht die Ecken sicher transparent
- zentriert das Motiv mit ca. 6 % Rand und bringt das Bild auf die Zielgrösse aus der CSV

Aufruf im Repo-Hauptordner:
  python3 tools/clean_images.py                 # alle vorhandenen Bilder aus den Nachlieferungen
  python3 tools/clean_images.py memory_otter    # nur bestimmte Dateien (ohne .png)
  python3 tools/clean_images.py --check         # nur melden, nichts ändern

Benötigt: pip install pillow numpy
"""
import csv, os, sys
from collections import deque

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
IMAGES = os.path.join(ROOT, "EllieInsel", "Images")
CHECK = "--check" in sys.argv
names = [a for a in sys.argv[1:] if not a.startswith("--")]


def target_sizes():
    sizes = {}
    for f in ("Bilder.csv",):  # vollständige Liste
        with open(os.path.join(ROOT, "assets", f), encoding="utf-8") as fh:
            for r in csv.DictReader(fh, delimiter=";"):
                s = r["Grösse"].split()[0]
                if "x" in s:
                    sizes[r["Datei"]] = int(s.split("x")[0])
    return sizes


def components(mask):
    """Zusammenhängende Flächen (4er-Nachbarschaft) – ohne SciPy."""
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes = [0]
    current = 0
    ys, xs = np.nonzero(mask)
    for y0, x0 in zip(ys, xs):
        if labels[y0, x0]:
            continue
        current += 1
        count = 0
        q = deque([(y0, x0)])
        labels[y0, x0] = current
        while q:
            y, x = q.popleft()
            count += 1
            for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
                if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and not labels[ny, nx]:
                    labels[ny, nx] = current
                    q.append((ny, nx))
        sizes.append(count)
    return labels, sizes


def clean(path, size):
    im = Image.open(path).convert("RGBA")
    # Analyse verkleinert (schneller), Ergebnis als Maske hochskalieren
    scale = 256 / max(im.size)
    small = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.BILINEAR)
    a = np.array(small)[:, :, 3]
    mask = a > 40
    labels, sizes = components(mask)
    if len(sizes) <= 1:
        return "leer"
    biggest = max(sizes[1:])
    # Behalten: alles, was mindestens 4 % der grössten Fläche hat (Motivteile wie Flügel, Fühler)
    keep = np.zeros_like(mask)
    removed = 0
    for i, s in enumerate(sizes[1:], start=1):
        if s >= biggest * 0.04:
            keep |= labels == i
        else:
            removed += 1
    # Maske leicht erweitern, damit feine Kanten erhalten bleiben
    k = Image.fromarray((keep * 255).astype(np.uint8)).resize(im.size, Image.BILINEAR)
    from PIL import ImageFilter
    k = k.filter(ImageFilter.MaxFilter(9))
    full = np.array(im)
    alpha = full[:, :, 3].astype(np.float32) * (np.array(k).astype(np.float32) / 255.0)
    alpha[alpha < 12] = 0  # Halbtransparenz-Schleier am Rand
    full[:, :, 3] = alpha.astype(np.uint8)
    out = Image.fromarray(full)
    bbox = out.getchannel("A").getbbox()
    if not bbox:
        return "leer"
    motif = out.crop(bbox)
    # Zentrieren mit 6 % Rand auf Zielgrösse
    inner = int(size * 0.88)
    if max(motif.size) != inner:
        f = inner / max(motif.size)
        motif = motif.resize((max(1, int(motif.width * f)), max(1, int(motif.height * f))), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(motif, ((size - motif.width) // 2, (size - motif.height) // 2), motif)
    if not CHECK:
        canvas.save(path, optimize=True)
    return f"{removed} Reste entfernt" if removed else "ok"


def main():
    sizes = target_sizes()
    if names:
        files = [n + ".png" for n in names]
    else:
        # Standard: nur Bilder aus den Nachlieferungen (bereits abgenommene Bilder bleiben unberührt)
        files = []
        for f in sorted(os.listdir(os.path.join(ROOT, "assets"))):
            if f.startswith("Bilder_Nachlieferung") and f.endswith(".csv"):
                with open(os.path.join(ROOT, "assets", f), encoding="utf-8") as fh:
                    files += [r["Datei"] for r in csv.DictReader(fh, delimiter=";")]
    for f in files:
        if f.startswith("puzzle_"):
            continue
        p = os.path.join(IMAGES, f)
        if not os.path.exists(p):
            if names:
                print(f"fehlt   {f}")
            continue
        result = clean(p, sizes.get(f, 1024))
        print(f"{'geprüft' if CHECK else 'bereinigt'} {f}: {result}")


if __name__ == "__main__":
    main()
