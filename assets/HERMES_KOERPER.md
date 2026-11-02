# Auftrag an Hermes: Bilder und Klänge für das Spiel «Mein Körper»

Neues Lernspiel in «Ellies Entdeckerinsel» (Kind: 5 Jahre). Das Kind lernt den Körper kennen: wo das Herz ist, wie es aussieht und was es macht. Dazu kommen Lunge, Gehirn, Magen, Darm, Knochen, Adern, Muskeln und die Sinne.

- Repository: `mrdevn4ever-sys/igame-el`
- Branch: `claude/ellies-entdeckerinsel`

**Listen (jede Zeile = genau eine Datei, Namen exakt übernehmen):**
- Bilder: `assets/Koerper.csv` (63 Dateien)
- Klänge: `assets/Koerper_Klaenge.csv` (6 Dateien)

## 1. Stil

Es gilt derselbe Stil wie in der Gartenwelt (`assets/HERMES_GARTENWELT.md`, Abschnitt 1):
- weiche 3D-Knete-Optik;
- Licht von oben links;
- Printatops exakt wie in der Referenz;
- kein Text.

**Qualitätsmassstab ist Gartenwelt-Paket 1a.** Lade 2–3 Bilder aus Paket 1 als Stilreferenz in jede Generierung.

Kindgerecht heisst hier:
- sachlich richtig, aber freundlich wie ein gutes Kinder-Sachbuch;
- nichts Blutiges, nichts Gruseliges;
- Skelett und Schädel sanft und lächelnd, nicht unheimlich;
- die Figur ohne Kleidung ist puppenhaft glatt, ohne Geschlechtsmerkmale.

## 2. Die Figur: das Wichtigste

Die sechs Figurbilder `koerper_aussen`, `koerper_organe`, `koerper_knochen`, `koerper_adern`, `koerper_muskeln` und `koerper_umriss` sind **Ebenen derselben Figur**.

In der App fährt das Kind mit einer runden **Zauberlupe** über das Mädchen. In der Lupe sieht es dieselbe Stelle als Organ-, Knochen-, Adern- oder Muskelbild. Das funktioniert nur, wenn alle sechs Bilder **pixelgenau deckungsgleich** sind:
- gleicher Bildrahmen (1536 × 2048);
- gleiche Haltung;
- gleiche Umrisslinie;
- gleiche Grösse.

So gehst du vor:
1. Zuerst `koerper_aussen` erzeugen, genau nach den Lageangaben in der Beschreibung (Prozent von Bildbreite und Bildhöhe).
2. Alle anderen Ebenen auf Basis von `koerper_aussen` erzeugen, zum Beispiel per Bild-zu-Bild oder Inpainting innerhalb der Silhouette, damit der Umriss identisch bleibt.
3. Prüfen: Lege jede Ebene mit 50 % Deckkraft über `koerper_aussen`. Der Umriss darf nirgends mehr als etwa 1 % der Bildbreite abweichen.

Weitere Regeln zur Figur:
- **Lageangaben einhalten.** Das Herz liegt auf **unserer rechten Bildseite**, denn das Mädchen schaut uns an und das Herz liegt in ihrer linken Brust. Der Magen liegt ebenfalls rechts der Mitte.
- Hintergrund überall echt transparent. Die Ecken sind 100 % transparent.

## 3. Einzelbilder

- `koerper_teil_*`, `koerper_funktion_*`, `koerper_sinn_*` und `koerper_dino_*`: 1024 × 1024, transparent, Motiv mittig, füllt etwa 80 %.
- Das Herz in `koerper_teil_herz` ist ein **echtes, vereinfachtes Herz** und kein ♥-Symbol. Es ist auch die Vorlage für `koerper_funktion_pumpen` und für die schlagenden Herzen in der App.
- Die Organbilder werden im Puzzle in `koerper_umriss` gelegt. Ihre Form muss deshalb zu den Organen in `koerper_organe` passen.
- `spiel_koerper` passt im Stil zu den anderen Spielkacheln (`EllieInsel/Images/spiel_*.png`).

## 4. Klänge

Es gelten dieselben Regeln wie in der Gartenwelt:
- Format `.m4a`, mono, etwa −16 LUFS;
- Quelle Pixabay oder selbst erzeugt;
- keine Sprache.

Trage die Quellen in `assets/Koerper_Quellen.csv` ein, mit den Spalten `Datei;Quelle-Link;Titel;Urheber`.

## 5. Ablage und Lieferung

- Bilder kommen nach `EllieInsel/Images/`, Klänge nach `EllieInsel/Audio/`.
- Liefere paketweise nach der Spalte «Paket»: 1 (Figur, Kachel, Klänge) → 2 (Körperteile) → 3 (Funktionen, Sinne, Dino, Symbole).
- Nach jedem Paket: commit und push mit der Nachricht `Körper Paket <n>: <Anzahl> Bilder, <Anzahl> Klänge [skip ci]`.
- Vor jedem Push:
  - `python3 tools/clean_images.py --check koerper_…` laufen lassen;
  - die Figur-Ebenen übereinander prüfen (Abschnitt 2);
  - fehlerhafte Bilder neu erzeugen, nicht nachbessern.

Das Spiel erscheint in der App automatisch, sobald `koerper_aussen.png` vorhanden ist.

## 6. Sprachaufnahmen (Florian)

Die neuen Sätze stehen in `assets/Sprachaufnahmen_Nachlieferung_4.csv` (166 Sätze, vor allem «Mein Körper»).

Sie werden aufgenommen wie bisher (`assets/AGENT_PROMPT.md`):
- Stimme `de-DE-FlorianMultilingualNeural`;
- ablegen in `EllieInsel/Audio/`;
- Dateinamen exakt aus der Spalte «Datei».
