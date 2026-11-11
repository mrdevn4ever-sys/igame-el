# Auftrag für Hermes: Korrektur Haus und Garten (Wohnstube, Bausätze, Gartenzwerg)

Repository `mrdevn4ever-sys/igame-el`, Branch `claude/eloquent-galileo-0bwpqo`. Nicht auf `main`, kein Force-Push.
Am App-Code änderst du nichts. Regeln wie in `assets/HERMES_HAUS_GARTEN.md` und `assets/AGENT_PROMPT.md`.
Alle Dateien **ersetzen** bestehende Dateien gleichen Namens in `EllieInsel/Images/` (gleiche Pixelmasse, gleiches Format).

Abgenommen und **nicht anfassen**: Garten-Szene, Bach-Szenen, Pflanzhügel, Picknickdecken, die übrigen 23 Gartenschmuck-Bilder,
Reh, Baumhaus-Stufen, Wasserrad, Schleuse, Quelle, Einläufe, Florian-Sätze, Türklang.

## Stilreferenz (in jede Generierung laden)

`gw_szene_kueche_innen.jpg`, `gw_szene_garten_tag.jpg`, `garten2_baumstumpf.png`, `gw_werkbank.png`, `gw_dino_stehen.png`.
Weiche Knete-/Vinyl-3D-Optik: runde Kanten, satte warme Farben, sanfte Glanzlichter, Licht von oben links.
Kein flacher Low-Poly-Look, keine harten Kanten, keine blassen oder grauen Flächen, kein Text.

---

## 1. Wohnstube neu (2 Dateien)

`gw_szene_haus_innen.jpg` und `gw_szene_haus_innen_abend.jpg`, je 2732 × 2048, deckend, progressives JPG.

**Warum neu:** Das gelieferte Bild ist flach und kantig (wirkt wie ein Rohmodell), hat kein Kuschelbett (stattdessen eine Truhe und
eine grüne Kiste) und einen winzigen Tisch mit Mini-Stühlen. Es passt nicht zur Küche nebenan.

**Stil und Kamera:** wie `gw_szene_kueche_innen.jpg` – gleiche Hölzer, cremefarbene Wände, grüne Akzente, Pflanzen, weiches Licht.
Blick gerade in den Raum auf Augenhöhe eines Kindes. Rückwand bis y 62 %, darunter Holzboden.

**Was die App darüberlegt:** Spielbilder in die 15 Regalfächer, das Erinnerungsbuch auf das Tischchen, Printatops auf den Teppich
(am Abend ins Bett). Diese Flächen müssen deshalb genau liegen und **leer** sein. Angaben in Prozent der Bildbreite (x) und Bildhöhe (y):

| Element | Lage | Vorgabe |
|---|---|---|
| Spielregal | x 24–62, y 8–60 | **Geometrie des jetzigen Bildes beibehalten.** 5 Spalten × 3 Reihen gleich grosser, leerer Fächer. Linke Fachkanten bei x 25,35 / 32,57 / 39,79 / 47,01 / 54,23; jedes Fach mindestens 6,2 breit. Obere Fachkanten bei y 10,5 / 27,0 / 43,5; jedes Fach mindestens 14 hoch. Helles warmes Holz, Fachrückwand etwas dunkler, nichts in den Fächern |
| Gartentür | x 2–14, y 18–72 | offene Rundbogentür mit Blick ins Grüne (Wiese, Himmel), Holzrahmen |
| Durchgang zur Küche | x 84–98, y 14–72 | Rundbogen; dahinter sind die grünen Küchenschränke und der Herd aus `gw_szene_kueche_innen.jpg` zu erkennen |
| Staffelei | x 66–80, y 28–74 | Holzstaffelei mit leerer weisser Leinwand |
| Kuschelbett | x 4–28, y 72–94 | **ein richtiges kleines Kinderbett**: Holzrahmen, dicke Matratze, grosses Kissen am linken Ende, weiche Decke. Die Liegefläche ist frei und von vorne-oben gut sichtbar (dort schläft abends die Figur). Keine Truhe, keine Kiste |
| Tischchen | x 44–60, y 70–84 | niedriges Holztischchen mit **leerer, gut sichtbarer Platte**. Keine Stühle, nichts darauf |
| Teppich | x 34–82, y 84–99 | runder oder ovaler Teppich, darauf nichts |

Sonst höchstens Dekoration, die keine dieser Flächen berührt (Pflanze, Bild ohne Motivtext, Lampe). Keine Figuren, kein Spielzeug,
keine Buchstaben oder Zahlen.

**Abend:** deckungsgleich mit dem Tagbild; Stehlampe oder Lichterkette leuchtet warm, draussen vor der Gartentür dunkelblau mit Sternen.
Das Bett bleibt gut erkennbar.

**Prüfen:** die obigen Flächen als Rechtecke über das Bild legen – jedes Element muss sein Rechteck füllen und darf kein fremdes
berühren; die 15 Fächer müssen leer und gleich gross sein; Tag und Abend im Differenzbild ohne verschobene Kanten.

---

## 2. Bausätze kräftiger (alle `gw_bau_*`, dazu `gw_wimpelkette.png`, `gw_laterne_papier.png`)

**Warum:** Formen und Maserung sind gut, aber alles ist blass graubeige. Neben dem kräftigen Garten wirken die Bauten ausgewaschen
und unfertig.

**Was ändern – nur das Material, nicht die Form:**
- Sattes, warmes Honigholz wie `garten2_baumstumpf.png` und `gw_werkbank.png`: Lichtseite etwa RGB 222/160/90,
  Schattenseite etwa RGB 160/98/48, deutlich sichtbare weiche Maserung, sanfte Glanzlichter, etwas dunklere Kanten.
- Metallteile (Scharniere, Haken) dunkel und klein; Füllungen (Insektenhotel) in Naturtönen, nicht grau.
- Umfärbbare Flächen (Dach bzw. Korpus laut Maske) bleiben **hell und warm** (heller Holzton, etwa RGB 235/200/150), damit die
  App-Farbe darauf sauber wirkt – aber nicht grau.

**Was gleich bleiben muss:** Umriss, Lage, Grösse und Fusslinie jedes Bildes **pixelgleich** (Alpha-Kanal unverändert). Dann bleiben
Masken und Einzelteile gültig und müssen nicht neu erzeugt werden. Betroffen sind die `_fertig`-Bilder (auch `_v2`, `_v3`) und alle
Einzelteile; die `_maske_*`-Dateien nur dann, wenn sich ein Umriss doch ändert.

**Prüfen:** jedes `_fertig`-Bild in 11 % der Szenenbreite auf `gw_szene_garten_tag.jpg` setzen (Wiese bei y 90 %): Es muss so
kräftig wirken wie Haus, Schuppen und Beetrand daneben. Alpha alt gegen neu vergleichen (identisch). Einzelteile übereinander
ergeben weiterhin das fertige Bild.

---

## 3. Gartenzwerg neu (1 Datei)

`garten2_gartenzwerg.png`, 1024 × 1024, transparent.

**Warum:** Der Zwerg ist zusammengequetscht: riesiger Kopf mit Mütze direkt auf einem flachgedrückten Körper, Beine kaum vorhanden.

**Neu:** stehender Gartenzwerg in natürlichen Zwergen-Proportionen – ohne Mütze etwa drei Kopfhöhen gross, mit sichtbarem
Oberkörper, erkennbaren Beinen und Stiefeln. Die Figur ist deutlich höher als breit (Höhe zu Breite etwa 1,6 : 1), füllt rund
80 % der Bildhöhe, steht aufrecht, Füsse auf der Fusslinie bei 92 %, waagrecht zentriert. Gleiche freundliche Art wie jetzt:
rote Zipfelmütze, weisser Bart, grüne Jacke, braune Hose. Knete-3D-Stil wie die anderen `garten2_*`-Bilder, keine Umrisslinien.

**Prüfen:** neben `garten2_vogelscheuche.png` und `gw_dino_stehen.png` stellen – die Proportionen müssen zusammenpassen.

---

## 4. Florian: Kostenangabe nachtragen (kein neuer Ton)

In `assets/Azure_Florian_Nachlieferung_6_Provenienz.json` fehlen die verlangten Angaben. Bitte nachtragen und melden:
Tarif der Speech-Ressource, freies Kontingent vor und nach der Tranche, verbrauchte Zeichen und ob Kosten entstanden sind
(`"cost_incurred": true/false`). **Dafür nichts neu synthetisieren.** Für diesen Korrekturauftrag wird Florian nicht gebraucht.

---

## Reihenfolge und Commit

1. Wohnstube, 2. Gartenzwerg, 3. Bausätze, 4. Kostenangabe.
Je Teil ein Commit, gezielt stagen, Provenienz-JSON `assets/Haus_Garten_Korrektur_<Teil>_Provenienz.json`.
Medien-Commits mit `[skip ci]`, der letzte ohne. Vor dem Push `git fetch` und auf den aktuellen Branch-Stand setzen.
`python3 tools/check_assets.py` ohne FEHLER. Kein TestFlight.

Am Ende melden: SHAs, Prüfergebnisse je Teil, Abweichungen von den Vorgaben, Florian-Kostenangabe.
