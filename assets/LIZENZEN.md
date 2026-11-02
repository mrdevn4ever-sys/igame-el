# Lizenzen und Herkunft der Assets

Stand: 2. November 2026

## Bilder

Alle 246 Bilddateien unter `EllieInsel/Images/` wurden für «Ellies Entdeckerinsel» neu erzeugt oder aus freigegebenen Projektassets technisch abgeleitet. Es wurden keine fremden Illustrationen, Fotos, Logos oder Markenassets übernommen.

### Generierung

- **Werkzeug:** OpenAI-Bildgenerierung über den Hermes-Adapter für ChatGPT/Codex OAuth
- **Modellbezeichnung:** `gpt-image-2`
- **Stilreferenzen:** ausschließlich zuvor für dieses Projekt mit demselben Werkzeug erzeugte und vom App-Eigentümer freigegebene Projektassets (`hase_begleiter`, `memory_fuchs`, `motiv_apfel`, `natur_wueste`, `puzzle_fuchs`) sowie daraus abgeleitete kanonische Motive
- **Erzeugungszeitraum:** 28.–29. Oktober 2026
- **Nachlieferung vom 29. Oktober 2026:** 112 PNG-Dateien gemäß `assets/Bilder_Nachlieferung_1.csv`; davon 74 mit `gpt-image-2` über den Hermes-Adapter für ChatGPT/Codex OAuth neu erzeugt und 38 aus freigegebenen kanonischen Projektassets technisch abgeleitet
- **Nutzungsbedingungen:** [OpenAI Terms of Use](https://openai.com/policies/row-terms-of-use/) und [OpenAI Service Terms](https://openai.com/policies/service-terms/)

Die OpenAI Terms of Use erklären im Abschnitt zu Inhalten, dass der Nutzer – soweit gesetzlich zulässig – seine Rechte am Input behält und den Output besitzt; OpenAI tritt etwaige Rechte am Output an den Nutzer ab. Die Bedingungen weisen zugleich darauf hin, dass Ausgaben nicht zwingend einzigartig sind und der Nutzer für Inhalt und Nutzung verantwortlich bleibt. Diese Datei dokumentiert die verwendete Quelle und ersetzt keine individuelle Rechtsberatung.

Die Bilder sind synthetisch erzeugt. Diese Herkunft sollte bei einer Veröffentlichung nicht irreführend dargestellt werden.

### Nachbearbeitung

Die generierten PNG-Dateien wurden ausschließlich technisch nachbearbeitet: Hintergrundfreistellung, Alpha-Korrektur, Zuschnitt, Skalierung, sRGB-Konvertierung und Qualitätsprüfung.

- `rembg` 2.0.86 — MIT-Lizenz: <https://github.com/danielgatis/rembg/blob/main/LICENSE.txt>
- Pillow 13.0.0 — HPND-Lizenz: <https://github.com/python-pillow/Pillow/blob/main/LICENSE>
- NumPy 2.4.6 — BSD-3-Clause: <https://github.com/numpy/numpy/blob/main/LICENSE.txt>
- SciPy 1.17.1 — BSD-3-Clause: <https://github.com/scipy/scipy/blob/main/LICENSE.txt>

Die genannten Open-Source-Werkzeuge wurden nur zur Verarbeitung eingesetzt; ihre Projektlogos oder Beispieldaten sind nicht Bestandteil der App-Assets.

## Audio: Tierlaute und Gartenwelt

Dieser Stand enthält **66 gehörte und freigegebene Audiodateien** unter `EllieInsel/Audio/`: 32 Tierlaute sowie 34 Effekte, Tonfolgen und Musikstücke für die Gartenwelt. Alle Dateien liegen als M4A/AAC-LC, mono und mit 44,1 kHz vor. Die finalen Hashes und Entscheidungen stehen in `assets/Gartenwelt_Audiofreigabe.json`; jede Quellenzuordnung steht in `assets/Gartenwelt_Quellen.csv`.

### Pixabay-Aufnahmen

- 47 Zieldateien verwenden 44 verschiedene Pixabay-Audioquellen.
- Lizenz: [Pixabay Content License](https://pixabay.com/service/terms/#license); [Lizenzzusammenfassung](https://pixabay.com/service/license-summary/).
- Einzel-URL, angezeigter Titel und Urheber sind je Datei in `assets/Gartenwelt_Quellen.csv` dokumentiert. Bei über `freesound_community` bereitgestellten Dateien wird zusätzlich der von Pixabay genannte ursprüngliche Künstler aufgeführt.
- Die Aufnahmen werden zugeschnitten, normalisiert und als Bestandteil der kreativen App verwendet. Sie werden nicht als eigenständige Soundbibliothek veröffentlicht oder weiterverkauft.
- Pixabay-Metadaten und diese Dokumentation ersetzen keine individuelle Rechtsberatung. Rohdownloads und interne Bearbeitungsdateien sind nicht Bestandteil des Repositories.

### Lokal erzeugte Klänge und Musik

19 Dateien wurden eigens für dieses Projekt lokal mit Python, NumPy, SciPy und FFmpeg erzeugt. Verwendet wurden mathematische Oszillatoren, Resonanzmodelle, gefilterte prozedurale Foley-Anteile und eigene pentatonische Tonfolgen. Es wurden keine fremden Audiosamples, keine Sprach- oder Gesangssynthese, keine externen Instrument-Samplebibliotheken und kein kostenpflichtiger Generierungsdienst eingesetzt.

### Hörfreigabe

- 66/66 Dateien wurden vom App-Eigentümer freigegeben; 50 Freigaben stammen aus Runde 1 und 16 korrigierte Dateien aus Runde 2.
- Die fünf Loop-Dateien wurden in der Review-App mit aktivierter Wiederholung und dem Prüfhinweis abgespielt, mindestens zwei Übergänge auf Klick, Sprung oder Loch zu kontrollieren.
- Der Export führte `tier_katze_1.m4a` als freigegeben, enthielt jedoch noch die Notiz „Klingt falsch“. Der Eigentümer bestätigte danach ausdrücklich die Freigabe; diese Auflösung ist in `assets/Gartenwelt_Audiofreigabe.json` dokumentiert.

Die noch nicht gelieferten synthetischen Sprachaufnahmen folgen separat. Dafür gelten weiterhin die im Auftrag festgelegten Azure-Sprach-, Tarif- und Offenlegungsanforderungen.
