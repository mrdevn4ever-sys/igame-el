#!/bin/bash
# Startet die App im iPad-Simulator mit Demo-Argumenten, spielt Runden automatisch durch,
# macht Screenshots und sammelt Abstürze. Läuft in GitHub Actions (macOS).
set -u
APP="$1"          # Pfad zur EllieInsel.app (Simulator-Build)
UDID="$2"
OUT="${3:-shots}"
BUNDLE=ch.ellie.entdeckerinsel
mkdir -p "$OUT/logs"
REPORT="$OUT/bericht.txt"
: > "$REPORT"

# Simulator auf Apple Silicon verlangt eine (Ad-hoc-)Signatur
codesign --force --deep --sign - "$APP" 2>&1 | tee -a "$REPORT"
xcrun simctl install "$UDID" "$APP" 2>&1 | tee -a "$REPORT"

ONLY="${ONLY:-}"   # optional: nur Durchläufe, deren Name dieses Muster enthält (z. B. «garten»)
run() {  # run <name> <wartezeit> <zwischenbild-nach> <args...>
  local name="$1" wait="$2" mid="$3"; shift 3
  if [ -n "$ONLY" ] && ! echo "$name" | grep -qE "$ONLY"; then return; fi
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1
  local pid
  pid=$(xcrun simctl launch "$UDID" "$BUNDLE" -demo "$@" 2>>"$OUT/logs/$name.launch" | awk -F': ' '{print $2}')
  if [ "$mid" -gt 0 ]; then
    sleep "$mid"
    xcrun simctl io "$UDID" screenshot --type=png "$OUT/${name}_a.png" >/dev/null 2>&1
    sleep $((wait - mid))
  else
    sleep "$wait"
  fi
  xcrun simctl io "$UDID" screenshot --type=png "$OUT/${name}.png" >/dev/null 2>&1
  if [ -z "$pid" ]; then
    echo "STARTFEHLER $name: $(cat "$OUT/logs/$name.launch")" | tee -a "$REPORT"
  elif xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE"; then
    echo "OK      $name" | tee -a "$REPORT"
  else
    echo "ABSTURZ $name (pid $pid)" | tee -a "$REPORT"
  fi
}

# Einrichtung und Einführung
for s in 0 1 2 3 4 5; do run "01_einrichtung_$s" 4 0 -screen setup -step $s; done
run 02_einfuehrung 5 0 -screen tutorial
# Hub, Garten, Galerie, Elternbereich
run 03_hub_seite1 5 0 -screen hub -page 0
run 03_hub_seite2 5 0 -screen hub -page 1
run 03_hub_hochformat 5 0 -screen hub -page 0 -portrait
run 04_garten 5 0 -screen garden
run 05_galerie 4 0 -screen gallery
run 06_eltern 5 0 -screen parents

# Jedes Spiel: Start (Entdecken) und automatisch durchgespielte Runde
i=10
for g in tracing appleMath memory snake counting shapes puzzle pattern animalSounds naturePairs sorting atelier; do
  run "${i}_${g}" 45 6 -screen game -game "$g" -autoplay
  i=$((i+1))
done
# Freies Malen
run 22_atelier_frei 20 8 -screen game -game atelier -atelier free -autoplay
run 22b_atelier_glitzer 12 0 -screen game -game atelier -atelier free -autoplay -steps 2
run 22c_atelier_live 12 0 -screen game -game atelier -atelier free -autoplay -steps 2 -livestroke
# Schwierigste Stufe: Startbild jedes Spiels
i=30
for g in tracing appleMath memory snake counting shapes puzzle pattern animalSounds naturePairs sorting atelier; do
  run "${i}_${g}_knobeln" 7 0 -screen game -game "$g" -difficulty knobeln
  i=$((i+1))
done

# Fortsetzen: Runde anfangen, App beenden, wieder öffnen
for g in memory tracing appleMath puzzle; do
  run "50_${g}_angefangen" 12 0 -screen game -game "$g" -autoplay -steps 2
  run "51_${g}_hub_danach" 5 0 -keep -screen hub
  run "52_${g}_fortgesetzt" 6 0 -keep -screen game -game "$g"
done
# Hilfe-Stufen sichtbar (Hinweis, dann Vorzeigen)
for g in tracing appleMath memory counting shapes sorting pattern naturePairs puzzle snake; do
  run "60_${g}_hilfe" 8 4 -screen game -game "$g" -autoplay -helpfirst -steps 1
done
# Garten mit Geschenk und Elternbereich-Unterseiten
run 70_garten_geschenk 5 0 -screen garden

# Höchste Stufe jedes Spiels
i=80
for g in tracing appleMath memory snake counting shapes puzzle pattern animalSounds naturePairs sorting atelier; do
  run "${i}_${g}_hoechste_stufe" 9 0 -screen game -game "$g" -level 99
  i=$((i+1))
done
# Mittlere Stufen ausgewählter Spiele
run 95_appleMath_stufe8_ergaenzen 7 0 -screen game -game appleMath -level 8
run 96_appleMath_stufe9_zwei_schritte 8 0 -screen game -game appleMath -level 9
run 97_puzzle_stufe5 9 0 -screen game -game puzzle -level 5
run 98_tracing_stufe7 6 0 -screen game -game tracing -level 7

# Anpassung: schnell und fehlerfrei -> Baum wächst; viel Hilfe -> Niveau sinkt
run 100_anpassung_stark 64 22 -screen game -game appleMath -autoplay -rounds 3
run 101_hub_nach_aufstieg 5 0 -keep -screen hub
run 102_eltern_spiele 6 0 -keep -screen parents -section games
run 103_anpassung_schwach 48 40 -screen game -game counting -level 5 -autoplay -helpfirst
run 104_hub_nach_schwach 5 0 -keep -screen hub
run 105_puzzle_runden 70 30 -screen game -game puzzle -autoplay -rounds 3

# Neue Inhalte: Memory-Themen, neue Tiere und Naturpaare auf mehreren Stufen
run 110_memory_stufe4 6 0 -screen game -game memory -level 4
run 111_animalSounds_stufe5_bild 8 0 -screen game -game animalSounds -level 5
run 112_naturePairs_runde 40 0 -screen game -game naturePairs -level 3 -autoplay
run 113_garten_bilder 5 0 -screen garden

# Gartenwelt: alle Orte, Abend, Überlagerungen und ein automatischer Durchlauf
run 120_garten_start 7 0 -screen garden -world start
run 121_garten_haus_mitte 6 0 -screen garden -world mitte -area haus
run 122_garten_haus_voll 6 0 -screen garden -world voll -area haus
run 123_garten_haus_abend 6 0 -screen garden -world voll -area haus -abend
run 124_garten_bach 6 0 -screen garden -world voll -area bach
run 125_garten_lichtung 6 0 -screen garden -world voll -area lichtung
run 126_garten_baumhaus 6 0 -screen garden -world voll -area baumhaus
run 127_garten_wunder 6 0 -screen garden -world voll -area wunder
run 128_garten_bach_mitte 6 0 -screen garden -world mitte -area bach
run 130_garten_kueche 6 0 -screen garden -world voll -overlay kitchen
run 131_garten_werkstatt 6 0 -screen garden -world voll -overlay workshop
run 132_garten_karte 6 0 -screen garden -world mitte -overlay map
run 133_garten_buch 6 0 -screen garden -world voll -overlay book
run 134_garten_samen 6 0 -screen garden -world voll -overlay seeds
run 135_garten_picknick 6 0 -screen garden -world voll -overlay picnic
run 136_garten_lichtspiel 6 0 -screen garden -world voll -overlay light
run 137_garten_fantasie 6 0 -screen garden -world voll -overlay fantasy
run 138_garten_fest 6 0 -screen garden -world voll -overlay fest
run 139_garten_durchlauf 75 30 -screen garden -world start -gardenplay

# Absturzberichte einsammeln
mkdir -p "$OUT/crashes"
find ~/Library/Logs/DiagnosticReports -iname "*EllieInsel*" -exec cp {} "$OUT/crashes/" \; 2>/dev/null || true
echo "Absturzberichte: $(ls "$OUT/crashes" | wc -l)" | tee -a "$REPORT"
