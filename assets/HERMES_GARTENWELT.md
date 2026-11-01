# Auftrag an Hermes: Bilder und Klänge für «Ellies lebendiger Garten»

Du erstellst alle Bilder und Klänge für die neue Gartenwelt der iPad-Kinderapp «Ellies Entdeckerinsel» (Kind: 5 Jahre).
Repository: `mrdevn4ever-sys/igame-el`, Branch `claude/ellies-entdeckerinsel`.

**Vollständige Liste mit Dateinamen, Grössen und Beschreibungen:**
- Bilder: `assets/Gartenwelt.csv` (358 Dateien)
- Klänge: `assets/Gartenwelt_Klaenge.csv` (34 Dateien)

Jede Zeile der CSV ist genau eine Datei. Dateinamen exakt übernehmen. Nichts weglassen, nichts umbenennen.

---

## 1. Stil (gilt für ALLES)

- **Referenz:** der grüne Baby-Triceratops aus dem Printatops-Logo und das App-Icon `EllieInsel/Assets.xcassets/AppIcon.appiconset/AppIcon.png` (Dino und Hase auf der Wiese). Lade beide als Stilreferenz in jede Generierung.
- Weiche 3D-Optik wie aus Knete/Vinyl: runde Formen, glatte Oberflächen, sanfte Glanzlichter.
- Licht immer von oben links, warm und freundlich, weiche Schatten im Objekt selbst.
- Farbwelt: Creme (#FFF6E5), Wiesengrün, Apfelrot, Himmelblau, Sonnengelb. Satt, aber nicht neon.
- Kindgerecht und freundlich: nichts Gruseliges, nichts Trauriges, keine Waffen, kein Text, keine Buchstaben, keine Zahlen, keine Logos.
- Alle Tiere sind niedlich, aber naturgetreu erkennbar (richtige Farben und Körperform). Sie haben grosse freundliche Augen wie der Dino.
- **Der Dino** muss in allen Posen exakt derselbe sein wie in der Referenz: mintgrün, hellgelber Bauch, cremefarbene Hörner und Nackenschild, grosse dunkle Augen.

## 2. Technische Regeln

| Typ (Spalte «Grösse») | Format |
|---|---|
| `2732x2048 deckend` | Szene/Hintergrund im iPad-Querformat, PNG, KEINE Transparenz |
| `1024x1024 transparent` | Objekt, Figur oder Pflanze, PNG mit transparentem Hintergrund |
| `2048x2048 transparent` | grosses Objekt (Decke, Baumhaus, Fest), PNG transparent |
| `512x512 transparent` | kleines Objekt, Symbol, Ernte, Wasserbau-Kachel, PNG transparent |

- **Transparente Bilder:** echte Transparenz. Die Ecken müssen 100 % transparent sein. Kein weisser oder karierter Hintergrund. Keine Schlagschatten auf den Boden, die setzt die App.
- **Grundlinie:** Alles, was steht (Figuren, Pflanzen, Bauwerke), berührt mit den Füssen bzw. dem Boden eine gedachte Linie bei **92 % der Bildhöhe** und ist **waagrecht zentriert**. So stehen alle Dinge in der App korrekt.
- **Rand:** Das Motiv füllt etwa 80 % der Bildfläche, mit mindestens 6 % Rand rundherum.
- **Gleiche Ansicht in Serien:** Alle Bilder einer Serie haben dieselbe Kamera, dieselbe Grösse des Motivs und dieselbe Position. Das gilt für:
  - Wachstumsstufen `pflanze_<x>_1…4`
  - Laufbilder `dino_laufen_1…4`
  - Wasserrad 1–4 und Wasser-Animationsbilder
  - Beet-Zustände
  - Bauteile und `_fertig`
  - Färbemasken
  - Tag- und Abendszene

  Nur das, was sich verändern soll, verändert sich.
- **Perspektive:** Szenen und Objekte haben eine leicht erhöhte Sicht (ca. 30° von oben). Ausnahmen: Wasserbau-Kacheln, Boote und Fische sind reine **Draufsicht**. Bei Laufbildern und Flug-Animationen sieht man die Figur **von der Seite und nach rechts schauend**; die App spiegelt sie.
- **Szenen:** Die Szenen sind leer. Keine Tiere, keine Beete, keine Werkzeuge darin, ausser es steht ausdrücklich in der Beschreibung. Die genannten freien Flächen müssen frei bleiben.
- **Abendszenen:** Jede Abendszene ist exakt dieselbe Szene wie die Tagszene, nur mit anderem Licht und anderen Farben.
- **Bemalbare Teile** («unbemaltes helles Holz», «REINWEISS», «wird eingefärbt»): hell und neutral, ohne Farbstich. Die Färbemasken `bau_*_maske_*` sind reines Weiss (#FFFFFF) in genau der Form des Teils. Alles andere ist transparent, und die Position ist pixelgenau wie bei `bau_*_fertig`.
- **Wasserbau-Kacheln:** Rinnen enden genau mittig an den Kachelrändern, damit Kacheln nahtlos aneinanderpassen. Die Rinnenbreite ist in allen Kacheln gleich (ca. 30 % der Kachel). Die Wasserbilder passen exakt in die zugehörige Rinne.

## 3. Klänge

- Format: `.m4a` (AAC), mono, 44,1 kHz, normalisiert auf etwa −16 LUFS.
- Kein Rauschen, keine Stille am Anfang, Ausklang mit kurzem Fade-out.
- Loops (in der Beschreibung «loopbar») müssen nahtlos sein.
- Quellen: Pixabay Sound Effects / Pixabay Music (lizenzfrei) oder selbst erzeugt. Keine Sprache, kein Gesang.
- Für jede Datei die Quelle eintragen in `assets/Gartenwelt_Quellen.csv` mit den Spalten `Datei;Quelle-Link;Titel;Urheber`.

## 4. Ablage

| Was | Wohin |
|---|---|
| Alle Bilder | `EllieInsel/Images/` (flach, keine Unterordner) |
| Alle Klänge | `EllieInsel/Audio/` |
| Quellen und Lizenzen | `assets/Gartenwelt_Quellen.csv` und zusätzlich ein Abschnitt in `assets/LIZENZEN.md` |

## 5. Reihenfolge und Lieferung

Liefere **paketweise** in der Reihenfolge der Spalte «Paket»: 1 → 2 → 3 → 4 → 5.

- Ein Paket ist fertig, wenn alle seine Zeilen aus beiden CSV-Dateien vorhanden sind.
- Nach jedem fertigen Paket: commit und push. Commit-Nachricht: `Gartenwelt Paket <n>: <Anzahl> Bilder, <Anzahl> Klänge [skip ci]`.
- Paket 1 hat Vorrang. Damit beginnt der Bau sofort.

## 6. Qualitätsprüfung vor jedem Push

1. `python3 tools/clean_images.py --check gw_…` für einzelne Dateien, oder alle gw_-Dateien prüfen: Ecken transparent, keine Reste.
2. Serien nebeneinander ansehen: Position, Grösse und Grundlinie identisch?
3. Dino-Posen mit der Referenz vergleichen: gleiche Farben, gleiche Proportionen?
4. Wasserbau-Kacheln zu einem Probe-Raster zusammensetzen: Gehen die Rinnen nahtlos über?
5. Fehlerhafte Bilder neu erzeugen, nicht nachbessern lassen.

Wenn eine Beschreibung unklar ist, triff eine kindgerechte, naheliegende Entscheidung. Halte sie in einer Zeile in `assets/Gartenwelt_Notizen.md` fest und arbeite weiter.
