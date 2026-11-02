# Auftrag an Hermes: Bilder für das Spiel «ABC lernen»

Neues Spiel in «Ellies Entdeckerinsel». Das Kind zeichnet Buchstaben nach («A wie Apfel»), erkennt Anlaute und schreibt später ganze Wörter.

Die Buchstaben selbst zeichnet die App. Von dir braucht es nur die **Bilder zu den Wörtern** und die **Spielkachel**.

- Liste: `assets/Abc.csv` (40 Bilder). Dateinamen exakt übernehmen.
- Stil: wie Gartenwelt-Paket 1a (`assets/HERMES_GARTENWELT.md`, Abschnitt 1). Weiche 3D-Knete-Optik, Licht von oben links, freundlich. Nimm 2–3 Bilder aus Paket 1 als Stilreferenz.
- **Auf den Wortbildern: kein Text, keine Buchstaben.** Das Kind soll das Wort selbst schreiben.
- Jedes Bild ist eindeutig: Man muss sofort sehen, welches Wort gemeint ist. Zum Beispiel: Wecker = «Uhr», Ohr ohne Kopf = «Ohr».
- Format 1024 × 1024, transparent, Motiv mittig, füllt ca. 80 %, Ecken 100 % transparent.
- Ablage: `EllieInsel/Images/`. Ein Push genügt: `ABC: 40 Bilder [skip ci]`.
- Vor dem Push: `python3 tools/clean_images.py --check abc_…` und `spiel_abc`.

Das Spiel erscheint in der App automatisch, sobald `abc_apfel.png` vorhanden ist.
