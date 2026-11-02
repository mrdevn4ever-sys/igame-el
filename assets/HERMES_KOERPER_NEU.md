# Auftrag an Hermes: «Mein Körper» – alle Bilder neu, anatomisch genau (nach ABC)

Die erste Fassung wird komplett ersetzt. Das Prinzip bleibt gleich:
- Das Kind sieht mit der Zauberlupe durch den Körper.
- Die Ebenen Organe, Knochen, Adern und Muskeln liegen deckungsgleich übereinander.
- Dateinamen, Grössen und Ablage bleiben wie in `assets/Koerper.csv`.

**Arbeite penibel genau.** Jedes Bild muss anatomisch stimmen, schön sein und kindgerecht wirken. Massstab ist Gartenwelt-Paket 1a. Lieber ein Bild fünfmal neu erzeugen als ein falsches abgeben.

## Was in der ersten Fassung falsch war (darf nicht wieder vorkommen)

1. **Gehirn über den Haaren.** Das Gehirn lag wie ein Hut auf dem Kopf. Richtig: Das Gehirn liegt **im Schädel**, ganz innerhalb des Kopfes, unter der Schädeldecke. Es ist kleiner als der Kopf, und rundherum ist Kopf bzw. Schädel sichtbar.
2. **Monsterhände.** Die Hände waren riesig, mit gespreizten Fingern. Richtig: Eine Kinderhand ist etwa so gross wie das Gesicht vom Kinn bis zur Augenbraue. Die Finger liegen locker beieinander.
3. **Falsche Proportionen.** Arme, Hände und Organe passten nicht zum Körper. Die Organe schwebten. Die Haare waren auf den Innen-Ebenen hautfarbene Flächen.
4. **Grobe Muskel-Ebene.** Die Muskeln waren nur rote Flecken.
5. **Printatops orange.** Er ist immer mintgrün wie in der Referenz (`EllieInsel/Images/gw_dino_stehen.png`).
6. **Einzelbilder Arm und Bein** waren abgetrennte, dünne Glieder.

## Proportionen der Figur (5-jähriges Mädchen, freundlich, leicht kindlich stilisiert)

- **Körperhöhe = 4,5 Kopfhöhen.** Kopf vom Scheitel bis zum Kinn ca. 21 % der Figurhöhe.
- **Haltung:** aufrecht, von vorne, Arme **locker hängend**, ca. 15–20° vom Körper weg. Handflächen leicht nach vorne, Finger zusammen, Beine leicht auseinander.
- **Lage (Anteil von Bildbreite x und Bildhöhe y), bitte genau einhalten:**
  - Kopf: Scheitel y 3 %, Kinn y 24 %, Augen y 14 %
  - Schultern y 29 %
  - Ellbogen y 43 %, bei x 31 % und 69 %
  - Handgelenk y 54 %; Handmitte y 58 %, bei x 28 % und 72 %
  - Hüfte y 55 %, Knie y 73 %, Fusssohlen y 97 %
- **Hand:** Länge ca. 9 % der Figurhöhe, Breite ca. 5 % der Bildbreite. Nicht grösser.
- **Füsse:** Länge ca. 8 % der Figurhöhe.

## Die Innen-Ebenen

Für `koerper_organe`, `koerper_knochen`, `koerper_adern`, `koerper_muskeln` und `koerper_umriss` gilt:

- Exakt derselbe Umriss wie `koerper_aussen`. Prüfung: 50 % Deckkraft übereinanderlegen, Abweichung höchstens 1 % der Bildbreite.
- **Haut:** zart durchscheinend wie bisher, aber sauber und warm, nicht geisterhaft. Das Gesicht ist freundlich und deutlich gezeichnet.
- **Haare:** echte braune Haare und Zöpfe, leicht durchscheinend, damit man den Kopfinhalt sieht. Niemals hautfarbene Zopf-Flächen.
- **Organe in natürlicher Grösse und Lage**, kindgerecht vereinfacht:

| Organ | Lage und Grösse |
|---|---|
| Gehirn | füllt den oberen Teil des Schädels (y ca. 5–13 %), liegt vollständig innerhalb des Kopfumrisses, rundherum Abstand zur Kopfkante |
| Lunge | zwei Flügel, füllen den Brustkorb von y 29 % bis 43 %; der linke Flügel des Kindes (unsere rechte Seite) ist etwas kleiner wegen des Herzens |
| Herz | Grösse einer Kinderfaust (ca. 6 % der Bildbreite), Mitte leicht links im Körper des Kindes = unsere rechte Seite (x 53 %, y 37 %), liegt zwischen den Lungenflügeln |
| Speiseröhre | dünn, hinter dem Herzen vom Hals zum Magen |
| Magen | unter dem linken Rippenbogen des Kindes (unsere rechte Seite, x 55 %, y 45 %) |
| Leber | rotbraun, unter dem rechten Rippenbogen des Kindes (unsere linke Seite, x 44 %, y 44 %), damit der Bauch nicht leer wirkt |
| Darm | Dünndarm in der Bauchmitte, umrahmt vom Dickdarm, innerhalb des Beckens (y 48–58 %) |

- **Knochen:** Skelett exakt in den Körper eingepasst.
  - Schädel = Kopfform.
  - Brustkorb mit 12 Rippenpaaren, Wirbelsäule durchgehend vom Schädel bis zum Becken, Becken auf Hüfthöhe.
  - Arm-, Bein-, Hand- und Fussknochen in richtiger Länge. Die Handknochen sind so klein wie die Hand.
  - Freundlich, nie gruselig: der Schädel sanft und lächelnd.
- **Adern:** Herz in der Mitte (wie oben). Rote Arterien und blaue Venen verzweigen sich gleichmässig in Kopf, Arme bis in die Finger und Beine bis in die Zehen, klar und nicht zu dicht.
- **Muskeln:** schöne, glatte Muskelstränge in der richtigen Form, nicht nur Flecken:
  - Bizeps und Trizeps;
  - Schulter- und Brustmuskel, Bauchmuskeln;
  - Oberschenkel- und Wadenmuskeln.

  Rosa-rot, weich, wie Knete, kindgerecht und nicht blutig.
- **`koerper_umriss`:** leerer, durchscheinender Körper mit Gesicht und echten Haaren. Darin werden im Puzzle die Organe abgelegt.

## Einzelbilder

- **`koerper_teil_*`:** Grösse und Form passend zu den Organen in `koerper_organe`. Die App legt sie im Puzzle genau dorthin.
  - `koerper_teil_arm` und `koerper_teil_bein`: das ganze Mädchen, der Arm bzw. das Bein leuchtet hervorgehoben. Kein abgetrenntes Glied.
  - `koerper_teil_hand`: normale Kinderhand, Finger zusammen.
- **`koerper_dino_*` und `spiel_koerper`:** Printatops mintgrün, exakt wie `gw_dino_stehen.png`.
- Alle übrigen Funktions-, Sinnes- und Symbolbilder ebenfalls neu, in derselben Sorgfalt.

## Prüfung vor jedem Push (Pflicht)

1. Alle 6 Figur-Ebenen nebeneinander und mit 50 % Deckkraft übereinander ansehen: deckungsgleich?
2. Proportionen nachmessen: Kopf ca. 21 %, Hand ca. 9 % der Höhe, Herz faustgross, Gehirn ganz im Kopf.
3. Jedes Bild mit den Augen eines 5-jährigen Kindes und seiner Eltern ansehen: schön, freundlich, nichts unheimlich?
4. Fehlerhafte Bilder neu erzeugen, nicht nachbessern.

Ablage und Commits wie bisher: `Körper neu Paket <n>: … [skip ci]`.
