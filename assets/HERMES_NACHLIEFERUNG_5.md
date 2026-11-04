# Auftrag für Hermes: Nachlieferung 5 (Sprache und ein Körperbild)

Repository `mrdevn4ever-sys/igame-el`, Branch `claude/ellies-entdeckerinsel`. Nicht auf `main` pushen, kein Force-Push.
Am App-Code änderst du **nichts**. Alle bisherigen Regeln aus `assets/AGENT_PROMPT.md` gelten weiter (Dateinamen exakt, keine Unterordner, Provenienz und QA wie bei den letzten Tranchen).

Am Ende muss `python3 tools/check_assets.py` ohne `FEHLER` laufen. Die bekannten Warnungen (unbekannte Garten-Dateien, Zählerlücke bei JPG) sind kein Fehler und werden nicht durch Löschen «repariert».

---

## A. Neue Sätze für Florian (18 Dateien)

Liste: `assets/Sprachaufnahmen_Nachlieferung_5.csv` (Semikolon, UTF-8, Spalte `Datei` = exakter Dateiname).

- Stimme und Einstellungen **genau wie Tranche 2616**: Azure `de-DE-FlorianMultilingualNeural`, `de-DE`, `<prosody rate="-12%">`.
- Format wie die aktuellen Dateien: AAC/M4A, mono, 24 kHz, etwa 48 kbit/s, etwa −16 LUFS, Spitzen ≤ −1 dBTP, Stille am Anfang/Ende ≤ 0,1 s.
- Text **exakt** sprechen. «Atelier» französisch wie im Deutschen üblich («Atteljee»).
- Danach Provenienz-JSON wie bei den letzten Batches (`assets/Azure_Florian_Nachlieferung_5_Provenienz.json` mit Hash je Datei) und die Zeilen in `assets/Sprachaufnahmen.csv` übernehmen, damit der Prüfer sie mitzählt.

Hörprobe vor dem Rest: «Zähle die Punkte.» + «Wähle die Farbe mit dieser Zahl und tippe auf die Fläche.», «Das ist die drei.» (vorhandene Datei) direkt danach – muss nahtlos klingen.

## B. Falsch ausgesprochene Lautwörter neu erzeugen (2 Dateien, gleicher Dateiname)

| Datei | Text (bleibt) | Problem | So soll es klingen |
|---|---|---|---|
| `mjam.m4a` | Mjam! | Florian sagt «Miaehm» | ein kurzes, genüssliches **«mjamm»**, einsilbig, wie beim Essen |
| `pssst_der_igel_ruht_sich_in_seinem_haus_aus.m4a` | Pssst, der Igel ruht sich in seinem Haus aus. | «Pssst» wird als «Peseseste» buchstabiert | ein **leises Zischen «psst»** (kein Vokal), dann der Satz ruhig und etwas leiser |

Der **Dateiname und der CSV-Text bleiben gleich**. Nur der Eingabetext für die Synthese darf angepasst werden, bis es richtig klingt, zum Beispiel:
- `mjam`: `Mjamm!` oder `<phoneme alphabet="ipa" ph="mjam">Mjam</phoneme>!`
- `pssst`: `<phoneme alphabet="ipa" ph="pst">Pssst</phoneme>,` oder `Psst,` mit `<break time="150ms"/>`

In der Provenienz festhalten, welcher Eingabetext verwendet wurde. Jede Datei anhören, bevor sie committet wird.

**Gleich mit anhören** (gleiche Fehlerart möglich, nur neu erzeugen, wenn falsch): `klingeling.m4a`, `quak_quak.m4a`, `grunz_grunz.m4a`, `i_aah_i_aah.m4a`, `kikeriki.m4a`, `kuckuck_kuckuck.m4a`, `maeh_maeh.m4a`, `miau.m4a`, `muuuuh.m4a`, `summ_summ_summ.m4a`, `wau_wau.m4a`, `hmm_schau_nochmals_was_printatops_gerade_macht.m4a`.
Lautwörter werden **verspielt nachgemacht**, nicht buchstabiert.

## C. Mein Körper: lange Hose (1 Bild)

Datei: `EllieInsel/Images/koerper_aussen.png` (1536 × 2048, transparent, die Aussenansicht des Mädchens).

Das Mädchen trägt im Moment eine kurze Jeans-Shorts. Der Eigentümer möchte **lange Hosen**:
- Hose bis zu den **Knöcheln**, Füsse bleiben barfuss sichtbar (Trefferpunkt «Fuss» bei y ≈ 0,95).
- Farbe: dieselbe Jeansblau wie jetzt oder ein warmes Blau, Bund an der Taille, T-Shirt reicht über den Bund. Im Schritt geschlossen, keine Haut zwischen den Beinen.
- **Die Knie müssen erkennbar bleiben** (Aufgabe «Wo ist dein Knie?», Trefferpunkt x 0,43 / 0,57, y 0,73): z. B. ein runder Flicken oder eine sanfte Falte genau auf den Knien.
- **Pose, Grösse, Position und Umriss bleiben deckungsgleich** mit den anderen fünf Lagen (`koerper_organe`, `koerper_knochen`, `koerper_adern`, `koerper_muskeln`, `koerper_umriss`). Die Zauberlupe blendet zwischen den Lagen über; die Beine dürfen durch die Hose höchstens wenige Pixel breiter werden, die Lücke zwischen den Beinen bleibt.
- Stil exakt wie das jetzige Bild (weiche 3D-Optik, gleiche Beleuchtung). Nur Hose ändern, Kopf, Haare, Arme, T-Shirt pixelgleich lassen.
- Die inneren Lagen **nicht ändern** (dort ist keine Kleidung, die Lupe zeigt das Innere).

Prüfen und belegen:
1. Alpha-Umriss neu gegen alt: Abweichung nur an den Beinen, höchstens etwa 8 px nach aussen.
2. Diese Punkte liegen auf der Figur (nicht transparent): Hand (0,28 | 0,59) und (0,72 | 0,59), Knie (0,43 | 0,73) und (0,57 | 0,73), Bein (0,43 | 0,80) und (0,57 | 0,80), Fuss (0,42 | 0,95) und (0,58 | 0,95).
3. Neuer Hash in `assets/Koerper_Gesamtfreigabe.json` eintragen (mit Vermerk «lange Hose, Nachlieferung 5») und Provenienz wie bei Paket 1–3. Die Eigentümerfreigabe für dieses eine Bild holst du wie gewohnt ein.
4. Bildgrösse wie bisher optimieren (PNG mit Transparenz, pngquant/oxipng wie im Bildoptimierungs-Lauf). **Nicht** als JPG speichern (Transparenz nötig).

---

## Commit

- Je Teil (A, B, C) ein Commit, Dateien gezielt stagen (kein `git add .`).
- Medien-Commits mit `[skip ci]`; den **letzten** Commit ohne `[skip ci]`, damit Build und Simulator-Test laufen.
- Vor dem Push `git fetch` und prüfen, dass der Branch nicht weitergelaufen ist.
- Keine TestFlight-Auslösung (die macht Claude danach).
