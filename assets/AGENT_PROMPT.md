# Auftrag: Alle Assets für «Ellies Entdeckerinsel» erstellen und ins Repo hochladen

## 1. Worum es geht

«Ellies Entdeckerinsel» ist eine native iPad-App (SwiftUI) für ein Kind von **4 bis 6 Jahren**.
Es ist eine ruhige, freundliche Lern- und Spielwelt mit Tieren, Pflanzen, Zahlen und Formen und zwölf Mini-Spielen.
Das Kind kann noch nicht lesen. **Bilder und Stimme sind deshalb das wichtigste Bedienelement.**

Die App ist fertig programmiert. Sie sucht Bilder und Tonaufnahmen über **feste Dateinamen**.
Deine Aufgabe ist es, **alle** Dateien aus den zwei Listen zu erzeugen, technisch zu prüfen und ins Repo zu committen.
Am App-Code änderst du **nichts**.

- Repository: `mrdevn4ever-sys/igame-el`
- Branch: `claude/ellies-entdeckerinsel` (dort arbeiten und pushen, nicht auf `main`)
- Masterliste Sprache und Tierlaute: `assets/Sprachaufnahmen.csv` (1080 Zeilen)
- Masterliste Bilder: `assets/Bilder.csv` (134 Zeilen)
- Prüfskript: `python3 tools/check_assets.py` (muss am Ende **ohne FEHLER** durchlaufen)

Die CSV-Dateien sind mit Semikolon getrennt und in UTF-8 kodiert. **Die Spalte `Datei` ist der exakte Dateiname.**
Nichts umbenennen, keine Grossbuchstaben, keine Umlaute, keine Unterordner.

## 2. Zielordner

| Asset | Ordner | Anzahl |
|---|---|---|
| Sprachaufnahmen (`*.m4a`, ausser `tier_*`) | `EllieInsel/Audio/` | 1064 |
| Tierlaute (`tier_<tier>_1.m4a`, `tier_<tier>_2.m4a`) | `EllieInsel/Audio/` | 16 |
| Bilder (`*.png`) | `EllieInsel/Images/` | 134 |

Xcode übernimmt die Ordner automatisch, eine Projektdatei musst du nicht anpassen.
Xcode legt alle Dateien flach ins App-Bundle. Ein Dateiname darf deshalb nur **einmal** vorkommen.
Das ist durch die Listen bereits gegeben, also nichts zusätzlich dazulegen.

---

## 3. Sprachaufnahmen (1064 Dateien)

### Was gesprochen wird
Jede Zeile der CSV mit Bereich ungleich `Tierlaute` enthält **genau einen Satz** in der Spalte `Text`.
Die App setzt längere Ansagen aus diesen Sätzen zusammen. Beispiel: «Zwei Äpfel und ein Apfel.» und danach «Wie viele sind es zusammen?».

**Regeln:**
1. **Den Text exakt so sprechen, wie er dasteht.** Kein Wort hinzufügen, weglassen oder umstellen.
2. Für alle 1064 Dateien **dieselbe Stimme mit denselben Einstellungen**. Sie werden direkt hintereinander abgespielt und müssen nahtlos zusammenpassen.
3. **Sprache:** Hochdeutsch (de-DE oder eine neutrale de-CH-Hochdeutsch-Stimme), keine Mundart.
   Die Schreibweise ist schweizerisch (immer «ss», nie «ß»), gesprochen wird normales Hochdeutsch («gross» = «groß»).
4. **Charakter:** Das ist der Hase, der dem Kind hilft: warm, ruhig, freundlich, geduldig, leicht lächelnd.
   Er klingt nie hektisch, nie übertrieben kindlich, nie wie Werbung. Eine weibliche oder männliche Stimme ist beides in Ordnung, aber es muss **eine** sein.
5. **Tempo:** eher langsam, etwa 10–15 % langsamer als normale Erzählgeschwindigkeit. **Zahlwörter** («eins», «zwei», «sieben») besonders deutlich.
   «eins» ist das Zahlwort zum Zählen, nicht «ein».
6. **Betonung:** Fragen («Wie viele sind es?») klingen wie Fragen. Lob («Super!», «Geschafft!») klingt herzlich, aber nicht schrill.
7. Einzelne Wörter wie «drei», «Fuchs» oder «Blatt» werden beim Zählen und Benennen einzeln abgespielt. Sie bekommen eine **neutrale, abschliessende** Betonung.
8. Zeilen mit «Mjam!», «Muuuuh!», «Kikeriki!» usw. spricht der Hase **verspielt nach**. Das ist keine echte Tieraufnahme.
9. «Fertig» in einem Text ist der Name eines Knopfes und wird ganz normal «Fertig» gesprochen.

**Werkzeug:** Eine hochwertige neuronale Sprachsynthese mit deutscher Stimme (z. B. ElevenLabs, Azure Neural TTS, Google Cloud TTS oder OpenAI TTS).
Verarbeite die CSV automatisiert in einem Durchlauf: Zeile für Zeile, Text rein, Datei mit dem Namen aus `Datei` raus.
Fixiere Stimme, Modell und Seed oder Stabilitätswerte, damit alle Dateien gleich klingen.
Bevor du alles erzeugst, erstelle eine **Hörprobe** aus diesen Zeilen der CSV und prüfe, ob sie direkt hintereinander natürlich klingen:
«Das ist die Drei.» + «Beginne beim Punkt.», «Gib mir drei Karotten.», «Du hast alle Paare gefunden.», «eins», «zwei», «drei».
Erst wenn das passt, erzeugst du den Rest.

### Technisches Format (Pflicht)
- Container und Codec: **`.m4a` mit AAC**, **mono**, **44,1 kHz**, 96–128 kbit/s
- Lautheit einheitlich auf etwa **−16 LUFS**, Spitzen höchstens −1 dBTP
- **Stille am Anfang und Ende entfernen**, höchstens etwa 0,1 s Rest. Sonst entstehen beim Zusammensetzen Pausen.
- Kein Hall, keine Musik, kein Rauschen, kein Klicken am Anfang oder Ende

Beispiel-Nachbearbeitung mit ffmpeg (aus einer WAV- oder MP3-Rohdatei):
```bash
ffmpeg -y -i roh.wav -af "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.05,areverse,silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.08,areverse,loudnorm=I=-16:TP=-1.5:LRA=7" -ac 1 -ar 44100 -c:a aac -b:a 112k EllieInsel/Audio/<Datei>
```

### Kontrolle
- Höre mindestens alle Zeilen der Bereiche `Zahlwörter`, `Allgemein`, `UI`, `Onboarding` und `Einführung` sowie je 20 zufällige Zeilen der übrigen Bereiche an.
- Achte besonders auf die Aussprache von «Käfer», «Eichhörnchen», «Grashüpfer», «Kastanie», «Weinrebe», «Bananenstaude», «Quadrat», «Oval» und «I-aah».
- Ist ein Satz falsch betont, erzeuge ihn neu. Den Text änderst du dabei nicht.

---

## 4. Tierlaute (16 Dateien)

`tier_kuh_1.m4a`, `tier_kuh_2.m4a`, `tier_schaf_1.m4a`, `tier_schaf_2.m4a`, `tier_hahn_1.m4a`, `tier_hahn_2.m4a`,
`tier_hund_1.m4a`, `tier_hund_2.m4a`, `tier_katze_1.m4a`, `tier_katze_2.m4a`, `tier_frosch_1.m4a`, `tier_frosch_2.m4a`,
`tier_schwein_1.m4a`, `tier_schwein_2.m4a`, `tier_esel_1.m4a`, `tier_esel_2.m4a`

- **Echte, realistische Tiergeräusche** (Muhen, Blöken, Krähen, Bellen, Miauen, Quaken, Grunzen, Iahen), **keine Sprache, keine Imitation durch Menschen**
- Variante 1 und 2 sind **zwei verschiedene Aufnahmen** desselben Tiers. Beide müssen eindeutig erkennbar sein.
- Länge **1–3 Sekunden**, Tier deutlich im Vordergrund, kaum Umgebungsgeräusche, keine anderen Tiere
- Nicht erschreckend: kein aggressives Knurren, kein lautes Kläffen, kein panisches Kreischen. Das Kind ist 4 bis 6 Jahre alt.
- Format wie oben (m4a, AAC, mono, 44,1 kHz), Lautheit etwa −18 LUFS, Stille am Rand gekürzt
- **Lizenz:** nur Quellen, die eine Weitergabe in einer App ohne Namensnennung oder mit dokumentierter Namensnennung erlauben (z. B. CC0 auf freesound.org, eigene Aufnahmen oder KI-generiert mit kommerziell nutzbarer Lizenz).
  **Trage jede Quelle in `assets/LIZENZEN.md` ein:** Datei, Quelle (URL), Urheber, Lizenz.

---

## 5. Bilder (134 Dateien)

### Gemeinsamer Stil (für ALLE Bilder gleich, das ist entscheidend)
Alle Bilder sollen aussehen wie aus **einem** Bilderbuch:
- **Warme, freundliche Bilderbuch-Illustration** in klaren, einfachen, runden Formen, flach mit sanften Schattierungen. Stil etwa wie hochwertige Kinderbuch-Vektorillustration oder weiche Gouache-Anmutung.
- **Weiche, dunkelgrüne bis dunkelbraune Konturen** (nicht schwarz), gleiche Linienstärke über alle Bilder
- **Farbwelt:** natürliche, leicht gedämpfte Farben mit gutem Kontrast. Passend zur App-Palette: Creme `#FFF8EC`, Dunkelgrün `#2E5E3E`,
  Sanftgrün `#B8E0B0`, Apricot `#FFD5B0`, Hellblau `#C3E4F6`, Flieder `#DCCEF1`, Hellgelb `#FFF1B0`.
  Keine Neonfarben, keine starken Verläufe.
- **Tiere** freundlich, mit grossen ruhigen Augen und einem leichten Lächeln. Nicht gruselig, keine Zähne oder Krallen betont.
  Trotzdem **sachlich richtig erkennbar**: Ein Marienkäfer hat Punkte, ein Igel Stacheln, ein Reh kein Geweih.
- **Keine Schrift, keine Zahlen, keine Buchstaben, kein Wasserzeichen** im Bild (Ausnahme: `spiel_tracing` darf eine grosse «3» zeigen)
- **Ein Motiv pro Bild**, mittig, **formatfüllend** (Motiv nutzt etwa 80–90 % der Fläche), Ansicht frontal oder leicht seitlich
- Das Motiv muss auch **klein** (ca. 70 × 70 Punkte auf dem iPad) sofort erkennbar sein. Also keine feinen Details, klare Silhouette.
- Gleiche Motive sehen überall gleich aus (der Fuchs in `memory_fuchs`, `avatar_fuchs` und `puzzle_fuchs` ist derselbe Fuchs-Charakter)

### Technische Vorgaben
- **PNG**, Farbraum sRGB
- **Alle Bilder ausser `puzzle_*`: quadratisch und mit transparentem Hintergrund (RGBA).** Alle vier Ecken müssen vollständig transparent sein.
  Keinen weissen Kasten und keinen Schatten-Kasten, nur ein weicher Bodenschatten direkt unter dem Motiv ist erlaubt.
- Grössen laut Spalte `Grösse`: `1024x1024` bzw. `512x512`. Grösser ist erlaubt, wenn das Bild quadratisch bleibt (mindestens 500 px).
- **`puzzle_*.png`:** **ganze Szene, ohne Transparenz**, Querformat **3:2**, 1800 × 1200 px.
  Das Tier steht gross in der Mitte, dahinter ist sein Lebensraum klar zu sehen. Die Szene ist bis in die Ecken farbig gestaltet,
  damit jedes der 4, 6 oder 9 Puzzleteile etwas Erkennbares zeigt. Kein Rahmen.

### Die Gruppen im Detail (Dateinamen siehe `assets/Bilder.csv`, Spalte `Motiv` beschreibt den Inhalt)

| Gruppe | Dateien | Inhalt und Hinweise |
|---|---|---|
| Begleiter | `hase_begleiter` | **Der Hase**, die Hauptfigur, die das Kind durch alle Spiele begleitet. Ganzer Körper, sitzend oder stehend, winkt freundlich. Hellbraun oder creme mit weissem Bauch, lange Ohren, ein **grünes Halstuch** als Erkennungsmerkmal. Zuerst gestalten, er gibt den Stil für alle anderen Bilder vor. |
| Avatare | `avatar_hase/fuchs/igel/eule/schildkroete/reh` | Kopf- oder Brustbild, rund komponiert (wird in einem Kreis gezeigt), alle im selben Ausschnitt. Der Avatar-Hase ist **ohne** Halstuch, damit er sich vom Begleiter unterscheidet. |
| Hub-Kacheln | `spiel_*` (12) | Das Symbolbild für jedes Spiel auf der Startseite. Inhalt steht in `Motiv`. Es wird gross und auf farbiger Kachel gezeigt, also transparent und gut lesbar. |
| Memory | `memory_*` (24) | Waldtiere, Wiesentiere und Naturmotive. Jedes Motiv muss sich **deutlich** von den anderen unterscheiden. |
| Tierstimmen | `tier_*` (8) | Kuh, Schaf, Hahn, Hund, Katze, Frosch, Schwein, Esel, jeweils das **ganze Tier seitlich** mit typischer, eindeutiger Silhouette. Die App zeigt sie auch als schwarzen Schatten, das Kind muss das Tier am Umriss erkennen. |
| Musterzug | `muster_*` (12) | Einfache Naturmotive als Waggon-Ladung. Sie müssen sich **auch in der Form** unterscheiden, nicht nur in der Farbe (Farbsehschwäche). |
| Rechnen und Zählen | `motiv_*` (8) | Einzelne Gegenstände, die mehrfach nebeneinander gezählt werden: genau **ein** Apfel, **eine** Karotte, **ein** Käfer usw. Kompakt und rundlich. |
| Naturpaare | `natur_*` (48) | Tiere, Pflanzen, Nahrung und Lebensräume. Lebensräume (`natur_wueste`, `natur_wald`, `natur_meer`, `natur_see`, `natur_teich`, `natur_weide`, `natur_bauernhof`, `natur_eis`, `natur_wasser`) als **kleine runde Vignette** (Landschaftsausschnitt in Kreisform) mit transparentem Rand. Pflanzen wie `natur_apfelbaum`, `natur_kastanienbaum`, `natur_kirschbaum`, `natur_weinrebe`, `natur_bananenstaude` und `natur_erdbeerpflanze` müssen **eindeutig** an ihren Früchten oder Blättern erkennbar sein. |
| Tierpuzzle | `puzzle_*` (12) | Siehe oben: ganze Szene im Format 3:2. Fuchs, Eule und Bär im Wald, Hase, Schmetterling und Marienkäfer auf der Wiese, Frosch, Ente und Fisch am oder im Wasser, Kuh, Schwein und Hahn auf dem Bauernhof. |
| Einführung | `einfuehrung_schmetterling`, `einfuehrung_blume`, `korb` | Ein bunter Schmetterling, eine grosse offene Blume (er sitzt darauf), ein Weidenkorb, leer und von schräg vorne. |

### Vorgehen bei den Bildern
1. Zuerst `hase_begleiter`, `memory_fuchs`, `motiv_apfel`, `natur_wueste` und `puzzle_fuchs` als **Stilprobe** erzeugen und auf Einheitlichkeit prüfen.
2. Dann alle übrigen Bilder **mit demselben Stil-Prompt** erzeugen. Verwende einen festen Stil-Baustein und hänge nur das Motiv an. Beispiel:
   > «Children's picture book illustration, warm friendly flat style with soft shading, rounded simple shapes, soft dark green outlines, muted natural colors, centered single subject filling the frame, plain transparent background, no text, no letters, no watermark. Subject: a friendly red fox sitting, front view.»
3. Hintergrund freistellen (z. B. mit `rembg` oder einem Generator, der transparente PNGs ausgibt), dann auf das Zielformat zuschneiden. Das Motiv soll mittig sitzen und rundherum etwa 5–8 % Rand haben.
4. Bilder mit fehlerhafter Anatomie (zusätzliche Beine, verschmolzene Ohren), Text-Artefakten oder Stilbrüchen neu erzeugen.

---

## 6. Abschlussprüfung (Pflicht)

```bash
pip install pillow            # falls nötig
python3 tools/check_assets.py
```
- Das Skript muss **0 FEHLER** melden und `Audio: 1080/1080   Bilder: 134/134` anzeigen.
- WARNUNGEN prüfen und nach Möglichkeit beheben.
- Zusätzlich die Bilder einer Gruppe nebeneinander als Kontaktbogen ansehen, um die Einheitlichkeit zu prüfen.

## 7. Abgeben

1. Alles auf den Branch `claude/ellies-entdeckerinsel` committen. Gerne in mehreren Commits, z. B. «Assets: Sprachaufnahmen», «Assets: Tierlaute», «Assets: Bilder».
2. `assets/LIZENZEN.md` mit allen Quellen (Tierlaute; bei generierten Inhalten das verwendete Werkzeug und dessen Nutzungsbedingungen) mitcommitten.
3. **Nicht ändern:** `*.swift`, `EllieInsel.xcodeproj`, `assets/*.csv`, `tools/*`.
   Wenn dir ein Text in der CSV falsch vorkommt, liste ihn in deinem Abschlussbericht auf, statt ihn zu ändern. Die App findet die Datei sonst nicht.
4. Kurzer Abschlussbericht: verwendete Stimme und Werkzeuge, Ausgabe von `check_assets.py`, offene Punkte.
