# Auftrag für Hermes: Garten 2 (ruhigerer Bach, neue Bau-Modelle)

Repository `mrdevn4ever-sys/igame-el`, Branch `claude/ellies-entdeckerinsel`. Nicht auf `main`, kein Force-Push.
Am App-Code änderst du nichts. Regeln wie in `assets/AGENT_PROMPT.md` (Dateinamen exakt, Provenienz, Freigabe).
Stil: wie die bestehende Gartenwelt (weiche 3D-Knete-Optik, Licht von oben links, satte warme Farben).

Hintergrund: Der Eigentümer findet den Garten überladen. Im Code sind bereits entfernt bzw. neu:
Textschilder in den Szenen, doppelte Knöpfe, schweben ohne Schatten, Beete versetzt, Wasserrinnen mit Lücken
(Rinnen zeichnet die App jetzt selbst nahtlos – dafür braucht es **keine** neuen Rinnenbilder).

---

## A. Bach und Teich ohne gemaltes Kachelraster (2 Bilder)

Dateien (ersetzen): `EllieInsel/Images/gw_szene_bach_teich.jpg` und `gw_szene_bach_teich_abend.jpg`
(2732 × 2048, deckend, progressives JPG wie jetzt).

Problem: Im Bild sind 24 braune Erdkacheln mit Graslücken gemalt. Das wirkt wie ein Spielbrett auf der Wiese.

Neu:
- **Gleiche Komposition** wie jetzt: Wasserfall/Quelle oben links, Teich mit Steg unten rechts, Holzbrücke links,
  Blumen und Steine am Rand. Diese Stellen dürfen sich höchstens wenige Pixel verschieben.
- Im Bereich des Wasserbaukastens (x 30 %–77 %, y 19 %–59 % der Bildfläche) **keine Kacheln, keine Linien,
  kein Raster**: eine ruhige, etwas kürzere, leicht hellere Wiese (oder ein sanft ausgetretener Erdweg ohne Muster),
  damit die gezeichneten Holzrinnen gut sichtbar sind. Keine Blumen oder Steine in diesem Bereich.
- Der Zulauf von der Quelle endet an der linken Kante dieses Bereichs auf Höhe y ≈ 24 %; der Teicheinlauf liegt
  rechts unten auf Höhe y ≈ 58 %.
- Abendversion: gleiche Komposition, Abendlicht wie die anderen `_abend`-Szenen.

## B. Mehr Modelle in der Werkstatt (je 2 Varianten, 5 Bausätze = 10 Modelle)

Für **vogelhaus, bank, futterstelle, insektenhotel, blumentopf** je zwei zusätzliche Modelle:

| Bausatz | Variante v2 | Variante v3 |
|---|---|---|
| vogelhaus | Pilzhaus (runder Hut als Dach) | kleiner Turm mit spitzem Dach |
| bank | Schaukelbank mit Seilen | Baumstamm-Bank |
| futterstelle | Futterhäuschen mit Laterne-Form | hängende Futterschale |
| insektenhotel | rundes Insektenhotel | Hotel in Herzform |
| blumentopf | Giesskannen-Topf | gestapelte Töpfe (3 übereinander) |

Je Modell drei Dateien, **gleicher Bildrahmen wie das bestehende Modell (1024 × 1024, transparent, Fuss unten mittig
auf gleicher Höhe)**:
- `gw_bau_<bausatz>_v2_fertig.png`
- `gw_bau_<bausatz>_v2_maske_dach.png` (weiss = umfärbbares Dach, sonst transparent)
- `gw_bau_<bausatz>_v2_maske_korpus.png` (weiss = umfärbbarer Korpus)
Dasselbe für `_v3_`. Die Masken müssen pixelgenau auf das `fertig`-Bild passen (wie bei den bestehenden Masken).
Neutralfarben im `fertig`-Bild (helles Holz), damit das Umfärben sauber wirkt.

Prüfen: Grösse 1024², Alpha vorhanden, Masken decken nur Dach bzw. Korpus, Fusslinie gleich wie beim Original.

## C. Grössen der Gartenbewohner prüfen (nur melden, nicht ändern)

Bitte schau dir `gw_tier_*`, `gw_dino_*` und den Gartenschmuck (`garten_*`) an und melde, welche Bilder im Verhältnis
deutlich zu gross/zu klein gezeichnet sind (z. B. Rotkehlchen grösser als eine Sonnenblume). Die Grössen im
Spiel stellt Claude im Code ein.

---

## Commit
- A und B je ein Commit, gezielt stagen, Provenienz-JSON wie üblich.
- Medien-Commits `[skip ci]`, letzter Commit ohne, damit Build und Simulator-Test laufen.
- Kein TestFlight. Am Ende melden: SHAs, `check_assets.py`-Ergebnis, Liste aus C.
