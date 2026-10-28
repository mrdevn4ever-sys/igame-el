#!/usr/bin/env python3
"""Prüft, ob alle Assets aus assets/*.csv vorhanden und korrekt sind.

Aufruf im Repo-Hauptordner:  python3 tools/check_assets.py
Benötigt für Bildprüfungen: Pillow (pip install pillow). Für Audiolängen optional: ffprobe.
Exit-Code 0 = alles vollständig, 1 = Fehler.
"""
import csv, os, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AUDIO = os.path.join(ROOT, "EllieInsel", "Audio")
IMAGES = os.path.join(ROOT, "EllieInsel", "Images")
errors, warnings = [], []

def rows(name):
    with open(os.path.join(ROOT, "assets", name), encoding="utf-8") as fh:
        return list(csv.DictReader(fh, delimiter=";"))

# --- Audio ---
audio_rows = rows("Sprachaufnahmen.csv")
expected_audio = {r["Datei"] for r in audio_rows}
present_audio = set(os.listdir(AUDIO)) if os.path.isdir(AUDIO) else set()
missing = sorted(expected_audio - present_audio)
extra = sorted(f for f in present_audio - expected_audio if not f.startswith("."))
if missing:
    errors.append(f"{len(missing)} Audiodateien fehlen, z. B. {missing[:5]}")
if extra:
    warnings.append(f"{len(extra)} unbekannte Dateien in EllieInsel/Audio: {extra[:5]}")

ffprobe = shutil.which("ffprobe")
if ffprobe:
    for f in sorted(expected_audio & present_audio):
        try:
            out = subprocess.run([ffprobe, "-v", "error", "-show_entries", "format=duration:stream=channels,sample_rate",
                                  "-of", "default=nw=1", os.path.join(AUDIO, f)], capture_output=True, text=True, timeout=20).stdout
            info = dict(l.split("=", 1) for l in out.strip().splitlines() if "=" in l)
            dur = float(info.get("duration", 0))
            if dur <= 0.15:
                errors.append(f"{f}: leer oder zu kurz ({dur:.2f}s)")
            if f.startswith("tier_") and dur > 4:
                warnings.append(f"{f}: Tierlaut länger als 4 s ({dur:.1f}s)")
            if not f.startswith("tier_") and dur > 12:
                warnings.append(f"{f}: ungewöhnlich lang ({dur:.1f}s)")
            if info.get("channels") not in (None, "1"):
                warnings.append(f"{f}: nicht mono")
        except Exception as e:
            errors.append(f"{f}: nicht lesbar ({e})")
else:
    warnings.append("ffprobe nicht gefunden – Audiolängen nicht geprüft")

# --- Bilder ---
image_rows = rows("Bilder.csv")
present_img = set(os.listdir(IMAGES)) if os.path.isdir(IMAGES) else set()
try:
    from PIL import Image
except ImportError:
    Image = None
    warnings.append("Pillow fehlt – Bildgrössen/Transparenz nicht geprüft")
for r in image_rows:
    f = r["Datei"]
    if f not in present_img:
        errors.append(f"Bild fehlt: {f}")
        continue
    if Image is None:
        continue
    try:
        im = Image.open(os.path.join(IMAGES, f))
        w, h = im.size
        if im.format != "PNG":
            errors.append(f"{f}: kein PNG ({im.format})")
        if f.startswith("puzzle_"):
            if abs(w / h - 1.5) > 0.02:
                errors.append(f"{f}: Seitenverhältnis {w}x{h}, erwartet 3:2")
            if w < 1500:
                warnings.append(f"{f}: Auflösung klein ({w}x{h})")
        else:
            if w != h:
                errors.append(f"{f}: nicht quadratisch ({w}x{h})")
            if w < 500:
                errors.append(f"{f}: zu klein ({w}x{h})")
            if im.mode not in ("RGBA", "LA") and not (im.mode == "P" and "transparency" in im.info):
                errors.append(f"{f}: kein transparenter Hintergrund (Modus {im.mode})")
            else:
                alpha = im.convert("RGBA").getchannel("A")
                corners = [alpha.getpixel(p) for p in [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)]]
                if max(corners) > 10:
                    errors.append(f"{f}: Ecken nicht transparent – Hintergrund entfernen")
    except Exception as e:
        errors.append(f"{f}: nicht lesbar ({e})")
extra_img = sorted(f for f in present_img - {r["Datei"] for r in image_rows} if not f.startswith("."))
if extra_img:
    warnings.append(f"{len(extra_img)} unbekannte Dateien in EllieInsel/Images: {extra_img[:5]}")

# --- Doppelte Namen über beide Ordner (Xcode legt alles flach ins Bundle) ---
dupes = present_audio & present_img
if dupes:
    errors.append(f"Gleicher Dateiname in Audio und Images: {sorted(dupes)}")

print(f"Audio: {len(expected_audio & present_audio)}/{len(expected_audio)}   Bilder: {len(present_img & {r['Datei'] for r in image_rows})}/{len(image_rows)}")
for w in warnings:
    print("WARNUNG:", w)
for e in errors[:200]:
    print("FEHLER:", e)
if len(errors) > 200:
    print(f"... und {len(errors) - 200} weitere Fehler")
sys.exit(1 if errors else 0)
