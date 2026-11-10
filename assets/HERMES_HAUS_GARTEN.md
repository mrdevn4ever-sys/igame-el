# Auftrag für Hermes: Haus und Garten neu (Garten 3) – Bilder, Stimme, Klang

Repository `mrdevn4ever-sys/igame-el`, Branch `claude/eloquent-galileo-0bwpqo`. Nicht auf `main`, kein Force-Push.
Am App-Code änderst du nichts. Regeln wie in `assets/AGENT_PROMPT.md` und `assets/HERMES_GARTENWELT.md`
(Dateinamen exakt, echte Transparenz, Fusslinie bei 92 %, Provenienz-JSON, Freigabe).

**Bilder: `assets/Haus_Garten.csv` (150 Dateien, Pakete A–F).** Jede Zeile ist genau eine Datei.
**Stimme: `assets/Sprachaufnahmen_Nachlieferung_6.csv` (37 Sätze, Abschnitt G).** **Klang:** 1 Geräusch (Abschnitt H).
Lageskizzen: `assets/skizzen/garten_layout.png` und `assets/skizzen/haus_innen_layout.png`
(Raster in Prozent der Bildbreite/-höhe; die Flächen sind verbindlich, die Farben der Skizze nicht).

## Warum

Der Eigentümer möchte Haus und Garten als Zuhause des Spiels: Das Kind geht durch die Haustür ins Haus,
pflanzt im Gemüsebeet, baut im Schuppen. Die Prüfung aller 450 Gartenbilder hat ergeben:

| Bereich | Urteil | Grund |
|---|---|---|
| Dino, Tiere (ausser Reh), alle Pflanzen, Ernte, Samentüten, Küchen-Dinge, Fundstücke, Klangdinge, Fantasieblumen, UI-Symbole, Inselkarte, Küche innen, Werkstatt innen, Tierlichtung, Baumhaus-Szene, Wunderlichtung | **bleibt** | einheitlicher Knete-3D-Stil, sauber freigestellt |
| Hausgarten-Szene | **neu** | Haus klein und angeschnitten in der Ecke, Tür nur 4 % breit (nicht antippbar); Teich und Weg belegen die halbe Spielfläche; als einzige Szene im Bilderbuch-Malstil mit feiner Grasstruktur |
| Haus innen | **fehlt** | es gibt keine Wohnstube |
| Bach-Szene | **neu** | kein Bach im Bild (die Brücke steht auf der Wiese), zwei Malfehler vom letzten Umbau, Rinnen liegen wie Strassen im Gras |
| Bausätze `gw_bau_*` (alle 96) | **neu** | graue, kantige Rohlinge wie aus einem CAD-Programm, passen nicht zur Knete-Welt |
| Gartenschmuck `garten_*` (alle 48) | **neu als `garten2_*`** | 2D-Bilderbuchstil mit Umrisslinien, falsche Motive für einen Garten (Palme, Kaktus, Ballon, Schaf …) |
| Hochbeete `gw_beet_*`, Picknickdecken | **neu** | von steil oben gezeichnet, Szene ist auf Augenhöhe: sie kippen aus dem Bild |
| Reh | **neu** | Strichbeine, anderer Stil als alle anderen Tiere |
| Baumhaus-Stufen | **neu** | flacher, einfacher als Szene und Kartenbild |
| Wasserrad, Schleuse, Quelle, Einläufe | **neu** | flache braune Bänder; müssen an die von der App gezeichneten Rinnen anschliessen |

## Stil (gilt für alles)

- Weiche Knete-/Vinyl-3D-Optik wie `gw_dino_stehen.png`, `gw_szene_tierlichtung.jpg`, `gw_szene_kueche_innen.jpg`.
  Diese drei Bilder plus das App-Icon als Stilreferenz in jede Generierung laden.
- Licht von oben links, warme satte Farben, runde Kanten, keine Umrisslinien, kein Text, keine Buchstaben, keine Zahlen.
- **Eine Kamera für Garten und Gegenstände:** Augenhöhe eines Kindes, leicht von oben (ca. 20°), Horizont bei 22 %
  der Bildhöhe – genau wie `gw_szene_tierlichtung.jpg`. Nur der Bach und seine Wasserbau-Teile bleiben in Draufsicht.
- Freigestellte Bilder: keine Schlagschatten auf den Boden (die setzt die App), Ecken 100 % transparent.

## Pakete und Reihenfolge

| Paket | Inhalt | Dateien | Wichtig |
|---|---|---|---|
| **A** | 6 Szenen: Garten Tag/Abend (neu), Wohnstube Tag/Abend (neu), Bach Tag/Abend (ersetzen) | 6 | Tag- und Abendbild deckungsgleich. Flächen aus den Skizzen einhalten: die App legt Tür, Regal, Beetplätze und Tor als Tippflächen genau dorthin |
| **B** | 4 Pflanzhügel `gw_erde_*`, 3 Picknickdecken | 7 | flach, Kamera wie Garten-Szene |
| **C** | alle Bausätze: fertig, Masken, Einzelteile, Varianten | 98 | warmes helles Holz; Masken pixelgenau; Teile deckungsgleich mit dem fertigen Bild |
| **D** | 24 neue Gartenschmuck-Bilder `garten2_*` | 24 | Knete-Stil, sinnvolle Gartenmotive |
| **E** | Reh (2), Baumhaus-Stufen (4) | 6 | Baumhaus exakt gleiche Lage wie bisher |
| **F** | Wasserrad (4), Schleuse (2), Quelle, 2 Einläufe | 9 | Rinnenbreite und Farben laut CSV, bündig bis zur Kante |

Bitte in dieser Reihenfolge liefern; **A und B zuerst**, damit Haus und Garten spielbar werden.
Die App schaltet automatisch auf das neue Layout um, sobald `gw_szene_garten_tag.jpg` im Bundle liegt;
bis dahin läuft der alte Hausgarten weiter. Die alten Dateien `gw_szene_hausgarten_*`, `gw_beet_*` und `garten_*`
bitte **nicht löschen** (das räumt Claude nach der Umstellung auf).

## G. Stimme: 37 neue Sätze für Florian

Liste: `assets/Sprachaufnahmen_Nachlieferung_6.csv` (Semikolon, UTF-8, Spalte `Datei` = exakter Dateiname,
37 Dateien, zusammen 840 Zeichen Text). Zielordner `EllieInsel/Audio/`.

### Zuerst: Kontingent prüfen – Florian darf keine Kosten erzeugen

**Bevor auch nur ein Satz synthetisiert wird:**

1. Im Azure-Portal die Speech-Ressource prüfen (zuletzt `ellie-entdeckerinsel-speech`, Region `switzerlandnorth`,
   laut letzter Provenienz Tarif **Standard S0**): Welcher Tarif gilt heute, wie viel kostenloses Kontingent
   für neuronale Stimmen ist in diesem Abrechnungsmonat noch frei, und wie viel wurde schon verbraucht?
2. Den Bedarf dagegenhalten: 840 Zeichen Text plus SSML-Rahmen plus Hörprobe und mögliche Wiederholungen,
   also **höchstens 3000 Zeichen** für die ganze Tranche.
3. **Nur synthetisieren, wenn die ganze Tranche sicher im kostenlosen Kontingent liegt.** Entstehen Kosten
   (auch kleine), oder lässt sich das Kontingent nicht zweifelsfrei ablesen: **nichts erzeugen, stoppen und dem
   Eigentümer melden** – mit Tarif, freiem Kontingent, Verbrauch und einem Vorschlag (z. B. kostenlose
   F0-Ressource oder Warten auf den nächsten Monat). Keine andere kostenpflichtige Stimme oder Plattform als Ersatz.
4. Während der Arbeit mitzählen und bei 3000 Zeichen abbrechen. Kein Batch-Neuversuch in Schleife.
5. Im Provenienz-JSON festhalten: Tarif, freies Kontingent vor und nach der Tranche, verbrauchte Zeichen,
   `"cost_incurred": false`.

### Stimme und Format (wie Nachlieferung 5)

- Azure `de-DE-FlorianMultilingualNeural`, `de-DE`, `<prosody rate="-12%">`, Tonhöhe 0 %.
- AAC/M4A, mono, 24 kHz, etwa 48 kbit/s, etwa −16 LUFS, Spitzen ≤ −1 dBTP, Stille am Anfang/Ende ≤ 0,1 s.
- Text **exakt** sprechen. Die 14 Spielnamen (Bereich `Spielnamen`) sind keine Sätze: ruhig und freundlich
  als Titel sprechen, ohne Frageton am Ende. «Memory» und «Snake» englisch wie im Deutschen üblich,
  «Atelier» als «Atteljee», «ABC» als «A-Be-Ce».
- Hörprobe vor dem Rest (zählt zum Kontingent): «Willkommen zu Hause!» + «Tippe auf die Tür, dann gehen wir hinein.»,
  direkt danach die vorhandene Datei `such_dir_einen_samen_aus.m4a` – muss nahtlos klingen.
- Danach `assets/Azure_Florian_Nachlieferung_6_Provenienz.json` (Hash je Datei) und die 37 Zeilen in
  `assets/Sprachaufnahmen.csv` übernehmen, damit der Prüfer sie mitzählt.

## H. Klang: 1 Geräusch

`EllieInsel/Audio/gw_sfx_tuer.m4a`: eine Holztür geht auf, weich und freundlich (kein Knarren wie im Gruselfilm,
kein Zuschlagen), 0,6–1,0 s. Format wie die anderen `gw_sfx_*`. Quelle wie bisher lizenzfrei (Pixabay Sound
Effects) oder selbst erzeugt, **kostenlos**; Eintrag in `assets/Gartenwelt_Quellen.csv` und `assets/LIZENZEN.md`.

## Prüfen vor dem Commit

- Szenen: 2732 × 2048, deckend, progressives JPG, Tag/Abend deckungsgleich (Differenzbild nur Farbe, keine Kanten).
- Garten-Szene: Haustür mindestens 9 % der Bildbreite; Gemüsebeet leer; die sechs Pflanzplätze
  (x/y in Prozent: 36/69, 52/69, 68/69, 33/81, 52/81, 71/81) liegen auf Erde; Baumplatz bei 89/66 frei.
- Wohnstube: 15 leere Regalfächer, jedes mindestens 6 % breit und 13 % hoch.
- Freigestellte Bilder: Grösse laut CSV, Alpha vorhanden, Fusslinie 92 %, waagrecht zentriert.
- Bausätze: Masken decken nur Dach bzw. Korpus; alle Einzelteile übereinander ergeben das fertige Bild.
- `python3 tools/check_assets.py` ohne FEHLER.

## Commit

- Je Paket (A–F) ein Commit, gezielt stagen, Provenienz-JSON `assets/Garten3_<Paket>_Provenienz.json`.
- Stimme (G) und Klang (H) je ein eigener Commit.
- Medien-Commits mit `[skip ci]`, der letzte ohne.
- Kein TestFlight. Am Ende melden: SHAs, Ergebnis von `check_assets.py`, Abweichungen von den Skizzen,
  Azure-Kontingent vor und nach der Tranche und die Bestätigung, dass keine Kosten entstanden sind.
