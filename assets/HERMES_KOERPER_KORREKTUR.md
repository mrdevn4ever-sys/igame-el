# Korrektur «Mein Körper» V2 → V3

V2 hat die Anatomie verbessert:
- Proportionen und Kopfgrösse stimmen;
- die Hände sind normal gross;
- das Gehirn liegt im Kopf;
- Herz, Lunge, Leber, Magen und Darm liegen am richtigen Ort.

**Diese Lage, Pose und Umrisse beibehalten.** Die App ist bereits darauf eingestellt.

Freigeben kann ich V2 trotzdem nicht. Die Gründe stehen unten.

## 1. Stil passt nicht zur App

V2 ist flache 2D-Vektorgrafik und wirkt blass und ausgewaschen. Die ganze App ist in **weicher 3D-Knete-Optik** gestaltet, wie Gartenwelt-Paket 1a, Printatops und die `sinn_*`-Bilder dieses Pakets.

Alle Figur-Ebenen und alle `koerper_teil_*` und `koerper_funktion_*` neu in genau dieser 3D-Qualität:
- runde Formen, sanfte Glanzlichter, Licht von oben links;
- satte, warme Farben;
- **gleiche Pose und gleiche Umrisse wie V2** (Bild-zu-Bild auf V2 aufbauen, dann wieder deckungsgleich prüfen).

## 2. Figur

- Arme etwas voller (nicht stockdünn), Hals etwas kürzer.
- **Hose:** In V2 schaut unter den kurzen Hosen zwischen den Beinen ein Stück Haut hervor. Es sieht aus, als hinge der Bauch unten heraus. Richtig:
  - eine **längere Hose** bis knapp über die Knie (Bermuda/Caprihose), Bund an der Taille;
  - im Schritt geschlossen, zwischen den Beinen keine Haut sichtbar;
  - das T-Shirt reicht über den Hosenbund.

  Die Kniegelenke bleiben sichtbar, damit das Kind auf das Knie tippen kann.
- Sonst Proportionen wie V2.

## 3. Knochen-Ebene

Der «Schädel» ist eine blasse Maske über dem Gesicht und wirkt unheimlich. Richtig:
- Im Kopf ist ein **echter, freundlicher Kinderschädel** zu sehen: rund, cremeweiss, sanft angedeutete Augenhöhlen, Nasenöffnung und eine lächelnde Zahnreihe.
- Er ist durchscheinend in den Kopf eingebettet, so wie der Brustkorb im Rumpf.
- Die Haare liegen leicht durchscheinend darüber.
- **Keine Maske, kein aufgemaltes Gesicht auf dem Schädel.**

## 4. Organe, Adern, Muskeln

- Farben satt und freundlich: Herz kräftig rot, Lunge rosa, Gehirn rosa, Leber rotbraun, Magen und Darm lachsrosa. In V2 sind sie braun-grau und matt.
- Adern: rot und blau klar sichtbar.

## 5. Umriss

Warmer, durchscheinender Pfirsichton wie die anderen Innen-Ebenen. In V2 ist er grau-weiss.

## 6. Einzelbilder neu

| Bild | Problem | Neu |
|---|---|---|
| `koerper_teil_schaedel` | leere Scheibe mit zwei Kreisen | freundlicher 3D-Kinderschädel von vorne |
| `koerper_teil_wirbelsaeule` | zu dünn und blass | kräftige, gut sichtbare Wirbelsäule, füllt ca. 80 % der Höhe |
| `koerper_teil_herz` | matt braun | kräftig rotes, vereinfachtes echtes Herz |
| `koerper_teil_gehirn`, `koerper_teil_lunge`, `koerper_teil_magen`, `koerper_teil_darm` | blass | satte Farben, 3D |
| `koerper_teil_mund` | nur flache Lippen | lachender Kindermund mit Zähnen und Zunge, 3D |
| `koerper_teil_nase` | formloser Klumpen | kleine, klar erkennbare Kindernase im Gesichtsausschnitt (rund, freundlich) |
| `koerper_teil_adern` | blass | Arm mit klar sichtbaren roten und blauen Adern |
| `koerper_teil_muskeln` | – | angespannter Kinderarm, Bizeps schön geformt |
| `koerper_teil_arm`, `koerper_teil_bein`, `koerper_funktion_denken`, `koerper_funktion_stuetzen` | Figur viel zu klein im Bild | Motiv füllt ca. 80 % der Bildfläche |
| `koerper_funktion_atmen` | unklar (Stäbchen/Fächer) | Mädchen pustet eine Pusteblume an, die Samen fliegen |

## 7. Behalten (gut)

`koerper_dino_*`, `spiel_koerper`, `koerper_sinn_*`, `koerper_essen_*`, `koerper_zauberlupe`, `koerper_knopf_*`, `koerper_funktion_hoeren`, `koerper_funktion_riechen`, `koerper_funktion_schmecken`, `koerper_funktion_fuehlen`, `koerper_funktion_sehen`, `abc_nase`.

## Prüfung vor dem Push

Wie in `assets/HERMES_KOERPER_NEU.md`. Zusätzlich gilt: alle Bilder nebeneinander mit Gartenwelt-Paket 1a vergleichen. Sie müssen aussehen, als kämen sie aus derselben App.
