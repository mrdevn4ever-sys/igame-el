# Auftrag an Hermes: «Mein Körper» komplett neu (erst nach ABC)

Die erste Fassung wird verworfen. Gründe:
- der geisterhafte, blasse Körper wirkt unheimlich;
- die Zöpfe waren hautfarben;
- die Muskel-Ebene war grob;
- Printatops war orange;
- Arm und Bein als Einzelbild waren schwach.

**Massstab ist Gartenwelt-Paket 1a. Nichts darf gruselig, blass oder halb durchsichtig wirken.**

## Neues Grundprinzip

- Das Mädchen ist **immer das fertige, schöne 3D-Mädchen**: Gesicht, Haare, Augen und Hautfarbe sind voll gerendert wie in `koerper_aussen`.
- Ins Innere schaut man nur durch ein **rundes Fenster**: die Zauberlupe, oder ein «Bauchfenster» im Rumpf.
- Es gibt **keine Ganzkörper-Geisterbilder mehr**. Die App zeigt die Innenansicht nur im Fenster. Der Rest bleibt das normale Mädchen.

## Bilder

### 1. Mädchen
`koerper_aussen.png` (1536 × 2048, transparent): wie bisher, sie ist gelungen. Behalte genau dieses Mädchen.

### 2. Innenansichten
`koerper_innen_organe`, `koerper_innen_knochen` und `koerper_innen_adern` (je 1536 × 2048, transparent, pixelgenau deckungsgleich mit `koerper_aussen`):
- Alles ist **deckend**, nichts halb durchsichtig.
- Die Haut ist eine warme, satte Pfirsichfläche mit weichem 3D-Schatten, wie ein Schnitt durch eine Knetfigur.
- Darin liegen die Organe, die Knochen oder die Adern in derselben Knete-Qualität wie die Einzelbilder.
- Kopf, Gesicht und Haare sind identisch mit `koerper_aussen`, also voll gerendert. Ausnahme: Bei den Knochen darf im Schädelbereich der freundliche Schädel sichtbar sein, das Gesicht bleibt aber erkennbar.
- Die Lageangaben aus `assets/Koerper.csv` gelten weiter: Das Herz liegt auf unserer rechten Seite.

### 3. Puzzle
`koerper_puzzle_rumpf.png`: das Mädchen in Unterwäsche-freier, puppenhaft glatter Haut, Kleidung weggelassen. Im Rumpf ist ein leeres, warmes «Fenster» mit sanft vertiefter Fläche, in das die Organe gelegt werden. Gesicht und Haare voll gerendert.

### 4. Muskel-Ebene
Entfällt. Statt der Muskel-Ebene gibt es nur das Einzelbild `koerper_teil_muskeln` (bleibt).

### 5. Einzelbilder neu
`koerper_teil_arm` und `koerper_teil_bein`: das ganze Kind von vorne, Arm bzw. Bein leuchtend hervorgehoben. **Kein abgetrenntes Körperteil.**

### 6. Printatops
Printatops (alle `koerper_dino_*`, `spiel_koerper`) ist **mintgrün wie in der Referenz**, nie orange.

## Prüfen vor dem Push

1. Jede Innenansicht mit 50 % Deckkraft über `koerper_aussen` legen. Der Umriss muss deckungsgleich sein.
2. Bei jedem Bild fragen: Würde ein 5-jähriges Kind das gerne anschauen? Wirkt nichts unheimlich?
