# Assets für Ellies Entdeckerinsel

**Nichts davon ist Pflicht.** Die App läuft ohne diese Dateien (Emojis + iOS-Systemstimme).
Jede Datei, die mit dem richtigen Namen im richtigen Ordner liegt, wird automatisch verwendet –
einzeln, du kannst also schrittweise liefern. Kein Code-Änderung nötig, Xcode übernimmt neue Dateien von selbst.

| Was | Ordner im Repo | Liste mit allen Dateinamen |
|---|---|---|
| Sprachaufnahmen (1064 Sätze) | `EllieInsel/Audio/` | [`assets/Sprachaufnahmen.csv`](assets/Sprachaufnahmen.csv) |
| Tierlaute (16) | `EllieInsel/Audio/` | am Ende derselben CSV (`tier_kuh_1.m4a` …) |
| Bilder (134) | `EllieInsel/Images/` | [`assets/Bilder.csv`](assets/Bilder.csv) |

Die CSV-Dateien sind mit `;` getrennt: `Datei;Text;Bereich` bzw. `Datei;Motiv;Verwendung;Grösse`.
Ordner flach halten (keine Unterordner nötig). Dateinamen genau so übernehmen: klein, ohne Umlaute.

## Sprachaufnahmen

- **Format:** `.m4a` (AAC), mono, 44,1 kHz. `.mp3` / `.wav` gehen auch – dann nur die Endung ändern.
- **Eine Stimme für alles**, ruhig, freundlich, Hochdeutsch, eher langsam. Zahlwörter besonders deutlich.
- Stille am Anfang/Ende abschneiden (max. ~0,15 s), Lautstärke angleichen (ca. −16 LUFS).
- Jede Zeile = **ein Satz**. Die App setzt längere Ansagen aus mehreren Sätzen zusammen.
  Fehlt ein Satz, spricht an dieser Stelle die Systemstimme.
- Text exakt so sprechen, wie er in der Spalte `Text` steht («Du hast bis drei gezählt.»).

**Empfohlene Reihenfolge** (Spalte `Bereich`): Zahlwörter → Allgemein/UI/Onboarding/Einführung →
Zahlen nachzeichnen → Apfel-Rechnen → Memory → Snake → Zählgarten → Rest.

## Tierlaute

`tier_<tier>_1.m4a` und `tier_<tier>_2.m4a` für `kuh, schaf, hahn, hund, katze, frosch, schwein, esel`:
echte (oder realistisch generierte) Tiergeräusche, 1–3 Sekunden, **ohne Sprache**, rechtlich frei verwendbar.

## Bilder

- **Format:** `.png` mit **transparentem Hintergrund** (ausser `puzzle_*`), quadratisch, Grösse siehe CSV.
- **Stil (für alle gleich):** warme Bilderbuch-Illustration, klare Formen, weiche Konturen, freundlich,
  keine Schrift im Bild, Motiv mittig und formatfüllend (wenig Rand).
- `puzzle_*.png`: **ganze Szene ohne Transparenz**, Querformat 3:2 (z. B. 1800 × 1200), Tier gross in der Mitte.
- `natur_*.png`: Antwortbilder (z. B. `natur_nuesse.png`, `natur_wueste.png`) – Gegenstand/Ort klar erkennbar.
- `tier_*.png` werden im Bildermodus auch als schwarzer Schatten gezeigt → klare Silhouette wichtig.

## Nachlieferungen

Wenn neue Spielinhalte neue Sätze brauchen, kommt eine zusätzliche Liste mit **nur den neuen Dateien** dazu
(bestehende Aufnahmen bleiben gültig):

| Datei | Inhalt |
|---|---|
| `assets/Sprachaufnahmen_Nachlieferung_1.csv` | 499 Sätze für die Niveau-Stufen (Rechnen und Zählen bis 20, Zahlen 11–20 nachzeichnen, Apfelbaum-Aufstieg) |

Gleicher Ordner (`EllieInsel/Audio/`), gleiches Format, gleiche Stimme.

## Liste neu erzeugen

Wenn sich Texte in der App ändern: `python3 tools/asset_manifest.py` (erzeugt beide CSV-Dateien neu).
