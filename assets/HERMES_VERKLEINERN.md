# Auftrag an Hermes: App-Grösse verkleinern (Bilder)

## Ist-Stand

| Ordner | Grösse |
|---|---|
| `EllieInsel/Images` | 721 Dateien, **345 MB** |
| `EllieInsel/Audio` | 11 MB |

Davon:
- 37 deckende Bilder (13 `gw_szene_*`, 24 `puzzle_*`): **154 MB**, je 3–7 MB als PNG.
- 684 transparente PNG: **190 MB**.

**Ziel: Bilder unter 90 MB, ohne sichtbaren Qualitätsverlust.**

Der App-Code ist schon vorbereitet: `UIImage.app(name)` lädt `name.png` oder, falls es das nicht gibt, `name.jpg`. Auch `tools/check_assets.py` akzeptiert JPG für deckende Bilder.

## 1. Deckende Bilder → JPG (grösster Gewinn)

Betrifft alle Bilder ohne Transparenz: `gw_szene_*`, `puzzle_*` und künftige Szenen und Panoramen.

- Umwandeln in **JPEG, Qualität 85, progressive**, Grösse unverändert.
- Dateiname gleich, nur die Endung wird `.jpg`, z. B. `gw_szene_hausgarten_tag.jpg`.
- Die alte `.png` **löschen**. Beide zugleich darf es nicht geben.
- Probe: `gw_szene_hausgarten_tag` wird von 7,1 MB auf 0,95 MB kleiner, ohne sichtbaren Unterschied.
- Erwartet: 154 MB → ca. 25 MB.

## 2. Transparente PNG verlustarm verkleinern

- **`pngquant --quality 82-98 --speed 1 --strip --skip-if-larger`**, danach **`oxipng -o 4 --strip safe`**.
- Probe: `gw_bau_vogelhaus_fertig` wird von 81 KB auf ca. 12 KB kleiner.
- Dateinamen und Pixelgrössen bleiben gleich, Transparenz und weiche Kanten bleiben erhalten.
- **Ausnahmen mit höherer Qualität** (`--quality 90-100`), weil dort feine Verläufe vorkommen:
  - Figur-Ebenen `koerper_aussen|organe|knochen|adern|muskeln|umriss`;
  - `spiel_*`;
  - `avatar_*`;
  - das App-Icon bleibt ganz unverändert.
- Die 15 Bilder mit 2048 × 2048 (z. B. `gw_buch_einband`): zusätzlich auf **1536 × 1536** verkleinern (Lanczos), dann wie oben.
- Erwartet: 190 MB → ca. 50 MB.

## 3. Nicht anfassen

- **Masken** `gw_bau_*_maske_*`: nur `oxipng` (verlustfrei), kein `pngquant`. Die Masken müssen reines Weiss bleiben.
- `EllieInsel/Assets.xcassets` (App-Icon).
- Alle Klänge.

## 4. Prüfung vor dem Push (Pflicht)

1. `python3 tools/check_assets.py --bilder`: keine FEHLER.
2. Je 5 Bilder pro Gruppe vorher und nachher nebeneinander ansehen: Szenen, Puzzle, Garten-Objekte, Körper, ABC, Spielkacheln. Es darf keine Streifen (Banding) in Himmel und Verläufen geben und keine ausgefransten Kanten.
3. Masken stichprobenartig prüfen: nur die Werte 0 und 255 im Alpha-Kanal oder weiche Kanten wie vorher, Farbe reines Weiss.
4. `du -sh EllieInsel/Images` vorher und nachher melden.

Commit: `Bilder verkleinert: <vorher> MB → <nachher> MB [skip ci]`. Danach prüfe ich die App im Simulator.

## 5. Ab sofort für alle neuen Bilder

- Deckende Bilder immer als JPG Q85.
- Transparente Bilder immer durch `pngquant` und `oxipng`.

So wächst die App nicht wieder.
