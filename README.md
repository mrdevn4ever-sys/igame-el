# Ellies Entdeckerinsel

Native iPad-App (SwiftUI, iPadOS 17+) – eine ruhige Lern- und Spielwelt rund um Tiere, Pflanzen, Zahlen und Formen.
Alles funktioniert offline, alle Daten bleiben lokal auf dem iPad.

## Starten

1. `EllieInsel.xcodeproj` mit **Xcode 16 oder neuer** öffnen.
2. Ziel *EllieInsel* wählen → *Signing & Capabilities* → eigenes Team eintragen
   (Bundle-ID bei Bedarf anpassen, Standard: `ch.ellie.entdeckerinsel`).
3. iPad per Kabel verbinden (Entwicklermodus aktiv) oder einen iPad-Simulator wählen → ▶︎.

Alternativ lässt sich das Projekt mit [XcodeGen](https://github.com/yonaskolb/XcodeGen) aus `project.yml` erzeugen.

> Hinweis zur Installation: Mit einem kostenlosen *Personal Team* läuft das Profil nach 7 Tagen ab,
> ein TestFlight-Build ist 90 Tage gültig. Für die Daueranwendung braucht es einen Apple-Developer-Account.

## Inhalt

| Bereich | Umsetzung |
|---|---|
| Erster Start | 6-stufige Einrichtung (Begrüssung, Profil + Tieravatar, Sprache & Ton mit Hörprobe, Startniveau, 6-stelliger Elterncode, Übergabe), setzt beim offenen Schritt fort |
| Einführung | Antippen (Schmetterling), Zuordnen (Apfel → Korb, ziehen oder tippen), Zurückfinden (Haus). «Später» überspringt |
| Hub | 2 Seiten à 6 Kacheln mit festen Positionen, Querformat 3×2 / Hochformat 2×3, Pfeil «Mehr Spiele» + Wischen, «Weiterspielen», Ton-Schalter, Elternzugang, «Mein Garten» |
| Spielrahmen | Haus (speichert automatisch), Anweisung nochmals hören, Hilfe in drei Stufen (Hinweis → Vorzeigen → gemeinsam lösen), Neustart nur mit Bestätigung, «Weiter», Rundenabschluss mit «Nochmals» / «Andere Spiele» |
| Spiele | 1 Zahlen nachzeichnen · 2 Apfel-Rechnen · 3 Tier-Memory · 4 Garten-Snake · 5 Zählgarten · 6 Formenhaus · 7 Sortiergarten · 8 Musterzug · 9 Tierstimmen · 10 Naturpaare · 11 Tierpuzzle · 12 Spurenatelier & freies Malen (PencilKit, Galerie) |
| Schwierigkeit | Entdecken / Üben / Knobeln je Spiel, wirksam ab der nächsten Runde |
| Garten | 12 Startdekorationen, nach jeder Runde höchstens eine Belohnung (1 aus 3, auch später wählbar), Platzieren per Tippen oder Halten+Ziehen, Verschieben, Rückgängig, Zurück in den Vorrat |
| Elternbereich | Übersicht mit konkreten Aktivitäten und getrennt erfassten Hilfen, Profil, Ton, Stufe/Sichtbarkeit/Modi je Spiel, Pausenhinweis, Sicherung exportieren/importieren (mit Vorschau, was ersetzt wird), Einführung neu starten, Code ändern, Code-Wiederherstellung per Rechenaufgabe |

Spielstände (konkrete Aufgaben, Antwortreihenfolge, bestätigte Zeichenabschnitte, Kartenpositionen …) werden
laufend gespeichert und beim nächsten Öffnen exakt fortgesetzt. Snake wartet nach einer Unterbrechung auf einen bewussten Start.

## Stimme und Tierlaute

Die App spricht zunächst mit der besten installierten deutschen Systemstimme
(bessere Stimmen: *Einstellungen › Bedienungshilfen › Gesprochene Inhalte › Stimmen › Deutsch*).

**Vorproduzierte Aufnahmen** werden automatisch bevorzugt: Audiodatei (`.m4a`, `.mp3`, `.wav`, `.caf`)
in einen Ordner `EllieInsel/Audio/` legen (bei Bedarf anlegen; Xcode übernimmt ihn automatisch). Der Dateiname ist der Satz in Kleinbuchstaben, Umlaute als ae/oe/ue,
alle anderen Zeichen als `_`, z. B.

- «Das ist die Drei. Beginne beim Punkt.» → `das_ist_die_drei_beginne_beim_punkt.m4a`
- «drei» → `drei.m4a`

**Tieraufnahmen** (Spiel 9): `tier_<tier>_1.m4a` und `tier_<tier>_2.m4a` mit
`kuh, schaf, hahn, hund, katze, frosch, schwein, esel`. Fehlt eine Aufnahme, wird das Geräusch nachgesprochen.

## Struktur

```
EllieInsel/
  App/          Einstieg, Bildschirmwechsel
  Core/         Datenmodell, Speicherung, Audio, Klangerzeugung, Farben
  UI/           Spielrahmen (GameHost/GameScreen), gemeinsame Bausteine
  Onboarding/   Einrichtung und Einführung
  Hub/ Garden/ Parents/
  Games/        je Spiel ein Ordner
```
