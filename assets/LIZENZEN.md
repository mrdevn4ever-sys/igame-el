# Lizenzen und Herkunft der Assets

Stand: 2. November 2026

## Bilder

Dieser Stand enthält 349 Bilddateien unter `EllieInsel/Images/`. Sie wurden für «Ellies Entdeckerinsel» neu erzeugt oder aus freigegebenen Projektassets technisch abgeleitet. Es wurden keine fremden Illustrationen, Fotos, Logos oder Markenassets übernommen.

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

### «ABC lernen»

Am 2. November 2026 wurden 40 transparente Illustrationen gemäß `assets/Abc.csv` ergänzt. 28 Dateien wurden mit `gpt-image-2` über den Hermes-Adapter für ChatGPT/Codex OAuth und ausschließlich mit freigegebenen, projekteigenen Gartenwelt- und «Mein Körper»-Referenzen erzeugt; 12 Motive wurden deterministisch aus bereits freigegebenen Projektassets abgeleitet. Bei den 28 Generierungen wurde die hohe Qualitätsstufe angefordert; der Server meldete für 26 Originale `low` und für zwei `medium`. Diese tatsächlich gemeldeten Werte werden nicht als ausgelieferte hohe Qualität dargestellt. Alle finalen Dateien wurden lokal zu 1024 × 1024 Pixel großen RGBA-PNGs mit transparentem Hintergrund verarbeitet und bestanden die technische sowie vollständige visuelle Prüfung auf Creme und `#202020`. Einzelhashes, Herkunft, Provider-Metadaten und Prüfstatus stehen in `assets/Abc_Provenienz.json`.

### «Mein Körper» – Paket 1

Am 2. November 2026 wurden sieben transparente Paket-1-Illustrationen gemäß `assets/Koerper.csv` ergänzt: sechs pixelgenau registrierte Ebenen derselben Kinderfigur sowie die Spielkachel. Zwei Dateien wurden mit `gpt-image-2` über den Hermes-Adapter für ChatGPT/Codex OAuth neu erzeugt; fünf Ebenen wurden deterministisch aus den projekteigenen Paket-1-Generierungen und Anatomiekomponenten zusammengesetzt. Alle sieben Dateien bestanden die technische und visuelle Prüfung. Die sechs Figur-Ebenen sind 1536 × 2048 Pixel groß und besitzen exakt dieselbe Alpha-Silhouette mit null abweichenden Pixeln. Einzelhashes, Herkunft und Prüfstatus stehen in `assets/Koerper_Paket1_Provenienz.json`.

### «Mein Körper» – Paket 2

Am 2. November 2026 wurden 22 transparente Körperteil-Illustrationen gemäß `assets/Koerper.csv` ergänzt. Davon wurden 15 deterministisch aus den freigegebenen Paket-1-Figur- und Anatomiekomponenten abgeleitet, sechs mit `gpt-image-2` über den Hermes-Adapter für ChatGPT/Codex OAuth neu erzeugt und eine Illustration kontrolliert aus einer neu erzeugten Hautpose plus freigegebener Anatomiekomponente zusammengesetzt. Als Stilreferenzen dienten ausschließlich freigegebene, projekteigene Gartenwelt-Paket-1a- und «Mein Körper»-Paket-1-Assets. Alle 22 Dateien bestanden die technische Prüfung sowie die visuelle Prüfung auf Creme und `#202020`; korrigierte Grenzfälle wurden zusätzlich bei der vorgesehenen Darstellungsgröße von 150 px geprüft. Einzelhashes, Herkunftsklasse und Prüfstatus stehen in `assets/Koerper_Paket2_Provenienz.json`.

### «Mein Körper» – Paket 3

Ebenfalls am 2. November 2026 wurden 34 transparente Illustrationen für Körperfunktionen, Sinne, Dino-Animationen und Bedienelemente gemäß `assets/Koerper.csv` ergänzt. 29 Dateien wurden mit `gpt-image-2` über denselben Hermes-Adapter neu erzeugt; fünf Bedienelemente wurden deterministisch aus freigegebenen Paket-1-Komponenten abgeleitet. Verwendet wurden ausschließlich projekteigene Stil- und Identitätsreferenzen. Alle 34 Dateien bestanden die technische und visuelle Prüfung auf Creme und `#202020`; Dino-, Symbol- und Bedienelemente wurden zusätzlich bei ihren vorgesehenen Darstellungsgrößen geprüft. Einzelhashes, Herkunftsklasse und Prüfstatus stehen in `assets/Koerper_Paket3_Provenienz.json`.

## Audio: «Mein Körper»

Dieser Stand enthält sechs gehörte und vom App-Eigentümer freigegebene Körperklänge gemäß `assets/Koerper_Klaenge.csv`. Alle Dateien liegen als M4A/AAC-LC, mono und mit 44,1 kHz vor; die finalen Hashes, technischen Messwerte und Entscheidungen stehen in `assets/Koerper_Audiofreigabe.json`, die Quellenzuordnung in `assets/Koerper_Quellen.csv`.

- Drei Herzschlag-Ziele verwenden bearbeitete Ausschnitte aus **SW002_Stethoscope_Chest_Heart_Heartbeat_Clean_At_Heart.wav** von shapingwaves, <https://freesound.org/people/shapingwaves/sounds/362374/>, lizenziert unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Änderungen: Auswahl unterschiedlicher Ausschnitte, Filterung, Puls-/Kadenzschnitt, Fades, Lautheitsnormalisierung und AAC-Kodierung. Keine Unterstützung oder Empfehlung durch den Urheber wird behauptet.
- `koerper_sfx_atmen.m4a` verwendet einen bearbeiteten Ausschnitt aus **Girl, female, inhale, exhale, sigh, breathing.wav** von SpliceSound, <https://freesound.org/people/SpliceSound/sounds/218309/>, freigegeben unter [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). Änderungen: Zuschnitt, sanfte tempoerhaltende Anpassung, Filterung, Fades, Lautheitsnormalisierung und AAC-Kodierung. Die Quelle beschreibt eine Jugendliche; der App-Eigentümer hat den finalen Klang nach Anhören freigegeben.
- `koerper_sfx_schlucken.m4a` verwendet einen bearbeiteten Ausschnitt aus **Drinking and swallow** von dersuperanton, <https://freesound.org/people/dersuperanton/sounds/433645/>, lizenziert unter [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Änderungen: Zuschnitt, Filterung, Fades, Lautheitsnormalisierung und AAC-Kodierung. Keine Unterstützung oder Empfehlung durch den Urheber wird behauptet.
- `koerper_sfx_zauber.m4a` ist eine projekteigene lokale, deterministische Python-/NumPy-/SciPy-Synthese (Seed 31006) ohne fremdes Audiosample. Die bereits in Runde 1 freigegebene Datei wurde byteidentisch übernommen.
- Hörfreigabe: fünf korrigierte Dateien in Runde 2 und der unveränderte Zauberklang aus Runde 1; insgesamt 6/6 freigegeben, keine Beanstandung und keine offene Entscheidung.

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
