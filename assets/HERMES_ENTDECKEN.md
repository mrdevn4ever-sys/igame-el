# Auftrag für Hermes: Entdecken – Eismaschine, Eis und Mädchensachen

Repository `mrdevn4ever-sys/igame-el`, Branch `claude/eloquent-galileo-0bwpqo` (zuerst `git fetch` und vorspulen).
Nicht auf `main`, kein Force-Push. Am App-Code änderst du nichts.
Liste: **`assets/Entdecken.csv` (28 Bilder)**. Jede Zeile ist genau eine Datei in `EllieInsel/Images/`, Name exakt.

## Worum es geht

Ellie (5) spielt am liebsten Entdeckerspiele: Dinge in die Hand nehmen, herumtragen und schauen, was passiert.
Ihre Lieblinge sind **Eis** und **Mädchensachen** (rosa, Glitzer, Krönchen, Schleifen, Einhörner).
Die App bekommt dafür eine Eismaschine: Das Kind wirft Früchte aus dem Korb hinein, heraus kommt ein Eis, das es
Tieren oder Printatops geben kann. Dazu Verkleidungen für Printatops und Schmuck fürs Haus.

## Stil

Wie die abgenommenen Bilder: `gw_dino_stehen.png`, `garten2_baumstumpf.png`, `garten2_gartenzwerg.png`, `gw_szene_garten_tag.jpg`
als Referenz laden. Weiche Knete-3D-Optik, satte warme Farben, Licht von oben links. Mädchensachen ruhig **rosa, lila,
mint und gold mit etwas Glitzer** – fröhlich und kindlich, aber nicht grell und kein Neon. Kein Text, keine Marken, keine
bekannten Figuren (kein Einhorn einer bestimmten Serie, keine Prinzessin aus Filmen).

## Pakete

| Paket | Dateien | Wichtig |
|---|---|---|
| A Eismaschine | `gw_station_eismaschine.png`, `gw_station_eismaschine_laeuft.png` | beide deckungsgleich; Einfüllschale oben gut sichtbar und offen |
| B Eis | 9 Sorten `gw_eis_*` + leere Waffel | **alle gleiche Waffel, gleiche Grösse und Lage** – nur die Kugel ändert sich |
| C Verkleidung | 8 × `gw_kostuem_*` | jedes Teil so gezeichnet, dass es genau auf `gw_dino_stehen.png` passt (Krone auf den Kopf zwischen die Hörner, Tutu um den Bauch, Flügel hinter den Rücken). Prüfen: Teil über `gw_dino_stehen.png` legen – sitzt es ohne Verschieben? |
| D Haus-Schmuck | 8 × `garten2_*` | wie die übrigen `garten2_*`-Bilder |

Reihenfolge: **A und B zuerst** (die Eismaschine ist der Hauptspass), dann C, dann D. **Jedes Paket einzeln committen und pushen.**

## Prüfen

- Grössen laut CSV, echte Transparenz, Ecken 100 % transparent, Fusslinie 92 %, waagrecht zentriert.
- Eis: alle 10 `gw_eis_*` übereinanderlegen – die Waffel ist pixelgleich.
- Eismaschine: beide Bilder im Differenzbild ohne verschobene Kanten.
- `python3 tools/check_assets.py` ohne FEHLER.

## Commit

Je Paket ein Commit, gezielt stagen, Provenienz `assets/Entdecken_<Paket>_Provenienz.json`.
Medien-Commits mit `[skip ci]`, der letzte ohne. Kein TestFlight.
Am Ende melden: SHAs, Prüfergebnisse, Abweichungen.
