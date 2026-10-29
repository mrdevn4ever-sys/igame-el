#!/usr/bin/env python3
"""Erzeugt die Listen aller Sprachaufnahmen und Bilder, die die App verwenden kann.

Aufruf (im Repo-Hauptordner):  python3 tools/asset_manifest.py
Ergebnis: assets/Sprachaufnahmen.csv und assets/Bilder.csv

Die Dateinamen entsprechen genau der Suche in der App (String.voiceSlug in Utilities.swift).
"""
import csv, os, re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "EllieInsel")

# --- Spiegel von String.voiceSlug / stableHash ---------------------------------
def stable_hash(s):
    h = 1469598103934665603
    for b in s.encode("utf-8"):
        h ^= b
        h = (h * 1099511628211) & 0xFFFFFFFFFFFFFFFF
    return h

def slug(text):
    s = text.lower()
    for k, v in {"ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss", "é": "e", "è": "e", "à": "a"}.items():
        s = s.replace(k, v)
    out, last = "", False
    for ch in s:
        if ch.isascii() and ch.isalnum():
            out += ch; last = False
        elif not last and out:
            out += "_"; last = True
    out = out.rstrip("_")
    if len(out) > 80:
        return out[:60] + "_" + format(stable_hash(out), "x")[:8]
    return out

# --- Spiegel von AudioManager.sentences ----------------------------------------
def sentences(text):
    res, cur = [], ""
    for i, ch in enumerate(text):
        cur += ch
        if ch in ".!?" and i + 1 < len(text) and text[i + 1] == " ":
            t = cur.strip()
            if t: res.append(t)
            cur = ""
    if cur.strip(): res.append(cur.strip())
    return res

lines = {}  # Satz -> Bereich
def add(text, area):
    for s in sentences(text):
        lines.setdefault(s, area)

# --- Zahlwörter und Motive ------------------------------------------------------
WORDS = ["null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn",
         "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn", "zwanzig",
         "einundzwanzig", "zweiundzwanzig", "dreiundzwanzig", "vierundzwanzig"]
DIGITS = ["Null", "Eins", "Zwei", "Drei", "Vier", "Fünf", "Sechs", "Sieben", "Acht", "Neun"]
MOTIFS = {  # rawValue: (Einzahl, Mehrzahl, weiblich)
    "apfel": ("Apfel", "Äpfel", False), "karotte": ("Karotte", "Karotten", True), "kaefer": ("Käfer", "Käfer", False),
    "birne": ("Birne", "Birnen", True), "erdbeere": ("Erdbeere", "Erdbeeren", True), "blume": ("Blume", "Blumen", True),
    "pilz": ("Pilz", "Pilze", False), "eichel": ("Eichel", "Eicheln", True)}
def word(n): return WORDS[n] if 0 <= n < len(WORDS) else str(n)
def phrase(m, n):
    sg, pl, fem = MOTIFS[m]
    return (("eine " if fem else "ein ") + sg) if n == 1 else f"{word(n)} {pl}"
def acc(m, n):
    sg, pl, fem = MOTIFS[m]
    return (("eine " if fem else "einen ") + sg) if n == 1 else f"{word(n)} {pl}"
def cap(s): return s[:1].upper() + s[1:]

for w in WORDS: add(w, "Zahlwörter")

# --- Feste Sätze direkt aus dem Quellcode ---------------------------------------
CALL = re.compile(r"\b(say|sayAndWait|enqueue|setInstruction|showBunny|taskSolved|wrong)\(")
LIT = re.compile(r'"((?:[^"\\]|\\.)*)"')
for dirpath, _, files in os.walk(SRC):
    for f in files:
        if not f.endswith(".swift"): continue
        area = os.path.basename(dirpath)
        for line in open(os.path.join(dirpath, f), encoding="utf-8"):
            if CALL.search(line) and "\\(" not in line:
                for lit in LIT.findall(line):
                    if len(lit) > 3 and lit[0].isupper(): add(lit, area)
# Sätze in Variablen
src = lambda p: open(os.path.join(SRC, p), encoding="utf-8").read()
for lit in re.findall(r'case \d: return "([^"]+)"', src("Onboarding/TutorialView.swift")): add(lit, "Einführung")
for lit in re.findall(r'label = "([^"]+)"', src("Games/NaturePairs/NaturePairsGameView.swift")): add(lit, "Naturpaare")
add("Schauen wir es gemeinsam an.", "Allgemein")
add("Hallo! Schön, dass du da bist. Gemeinsam entdecken wir deine Insel.", "Einrichtung")
add("Zeit für eine kleine Pause? Du hast schon schön gespielt.", "Hub")
add("Geschafft! Das hast du toll gemacht.", "Allgemein")

# --- Spiel 1: Zahlen nachzeichnen ---
for n in range(0, 21):
    d = DIGITS[n] if n < 10 else cap(word(n))
    add(f"Das ist die {d}. Beginne beim Punkt.", "Zahlen nachzeichnen")
    add(f"Super! Das ist die {d}.", "Zahlen nachzeichnen")

# --- Spiel 2: Apfel-Rechnen (Äpfel, Karotten, Käfer; bis 10) ---
for m in ["apfel", "karotte", "kaefer"]:
    animal = m == "kaefer"
    for a in range(1, 11):
        for b in range(1, 11):
            if a + b <= 10:
                add(f"{cap(phrase(m, a))} und {phrase(m, b)}. Wie viele sind es zusammen?", "Apfel-Rechnen")
            if b < a:
                verb = "wird" if b == 1 else "werden"
                add(f"{cap(phrase(m, a))}. {cap(phrase(m, b))} {verb} weggenommen. Wie viele bleiben?", "Apfel-Rechnen")
        A = cap(phrase(m, a))
        if animal:
            add(f"{A} {'sitzt' if a == 1 else 'sitzen'} auf dem Blatt.", "Apfel-Rechnen")
            add(f"{A} {'fliegt' if a == 1 else 'fliegen'} dazu.", "Apfel-Rechnen")
            add(f"{A} {'fliegt' if a == 1 else 'fliegen'} weg.", "Apfel-Rechnen")
        else:
            add(f"{A} {'liegt' if a == 1 else 'liegen'} im Korb.", "Apfel-Rechnen")
            add(f"Der Hase bringt {acc(m, a)} dazu.", "Apfel-Rechnen")
            add(f"Der Hase nimmt {acc(m, a)} heraus.", "Apfel-Rechnen")
    for n in range(1, 21):
        add(f"Richtig, {phrase(m, n)}.", "Apfel-Rechnen")
        add(f"{cap(phrase(m, n))}.", "Apfel-Rechnen")
        add(f"{cap(phrase(m, n))} {'wird' if n == 1 else 'werden'} weggenommen.", "Apfel-Rechnen")
        add(f"Dazu {'kommt' if n == 1 else 'kommen'} {phrase(m, n)}.", "Apfel-Rechnen")
        add(f"Dann {'wird' if n == 1 else 'werden'} {phrase(m, n)} weggenommen.", "Apfel-Rechnen")
add("Wie viele sind es jetzt?", "Apfel-Rechnen")
add("Wie viel ist das?", "Apfel-Rechnen")
for t in range(3, 21):
    add(f"Wie viele fehlen bis {word(t)}?", "Apfel-Rechnen")
for n in range(1, 21):
    add(f"Wir haben {word(n)} gezählt. Tippe auf die {n}.", "Rechnen/Zählen")

# --- Spiel 3: Memory ---
MEMORY = re.findall(r'MemoryMotif\(emoji: "[^"]+", name: "([^"]+)"\)', src("Games/Memory/MemoryGameView.swift"))
for n in MEMORY:
    add(n, "Memory"); add(f"Zwei gleiche: {n}!", "Memory"); add(f"Wo hast du schon {n} gesehen?", "Memory")

# --- Spiel 4: Snake ---
for n in range(1, 10): add(f"Mjam! {cap(word(n))}.", "Snake")
for n in range(5, 11): add(f"Sammle {word(n)} Früchte. Tippe auf einen Pfeil.", "Snake")

# --- Spiel 5: Zählgarten ---
for m in ["kaefer", "karotte", "apfel", "pilz", "blume", "eichel"]:
    sg, pl, fem = MOTIFS[m]
    add(f"Tippe {'jede' if fem else 'jeden'} {sg} einmal an. Wie viele {pl} sind es?", "Zählgarten")
    for n in range(1, 21):
        add(f"Gib mir {acc(m, n)}.", "Zählgarten")
        add(f"Genau, {phrase(m, n)}. Du hast alle gezählt.", "Zählgarten")
        add(f"Danke! Das sind genau {acc(m, n).replace('einen ', 'ein ')}.", "Zählgarten")
for n in range(0, 25):
    add(f"Im Korb {'ist' if n == 1 else 'sind'} {word(n)}.", "Zählgarten")
for n in range(1, 21):
    add(f"Wir brauchen {word(n)}.", "Zählgarten"); add(f"Wir brauchen nur {word(n)}.", "Zählgarten")
    add(f"Du hast bis {word(n)} gezählt.", "Zählgarten")
add("Leg noch etwas dazu.", "Zählgarten"); add("Tippe im Korb auf eines, dann kommt es zurück.", "Zählgarten")

# --- Spiel 6: Formenhaus ---
SHAPES = [("Kreis", "der"), ("Quadrat", "das"), ("Dreieck", "das"), ("Rechteck", "das"), ("Oval", "das"), ("Stern", "der")]
for name, art in SHAPES:
    add(f"{cap(art)} {name}. Wo passt {'er' if art == 'der' else 'es'} hin?", "Formenhaus")
    add(f"{cap(art)} {name} passt.", "Formenhaus")
    add(f"Das ist ein {name}. Die Form passt hier nicht.", "Formenhaus")
    add(f"{cap(art)} {name} gehört hierhin.", "Formenhaus")
    add(f"Wir setzen {'den' if art == 'der' else 'das'} {name} gemeinsam ein.", "Formenhaus")

# --- Spiel 7: Sortiergarten ---
for noun in ["Blätter", "Äpfel", "Pilze", "Kastanien"]:
    add(f"Sortiere nach Grösse: kleine, mittlere und grosse {noun}.", "Sortiergarten")
    add(f"Leg die grossen {noun} zum grossen Bild und die kleinen zum kleinen.", "Sortiergarten")

# --- Spiel 8: Musterzug ---
def pattern_art(n):
    if n in ["Blume", "Kastanie", "Schnecke", "Tanne", "Biene", "Erdbeere"]: return "die"
    return "das" if n == "Blatt" else "der"
for n in re.findall(r'PatternMotif\(emoji: "[^"]+", name: "([^"]+)"\)', src("Games/Pattern/PatternGameView.swift")):
    add(n, "Musterzug")
    add(f"Genau, {pattern_art(n)} {n}. Der Zug fährt weiter.", "Musterzug")
    add(f"In die Lücke gehört {pattern_art(n)} {n}.", "Musterzug")

# --- Spiel 9: Tierstimmen ---
ANIMALS = [("kuh", "Kuh", "die", "Muuuuh!"), ("schaf", "Schaf", "das", "Mäh, mäh!"), ("hahn", "Hahn", "der", "Kikeriki!"),
           ("hund", "Hund", "der", "Wau, wau!"), ("katze", "Katze", "die", "Miau!"), ("frosch", "Frosch", "der", "Quak, quak!"),
           ("schwein", "Schwein", "das", "Grunz, grunz!"), ("esel", "Esel", "der", "I-aah, i-aah!"),
           ("pferd", "Pferd", "das", "Hü-hü-hüüü!"), ("ziege", "Ziege", "die", "Meck, meck!"), ("ente", "Ente", "die", "Nak, nak, nak!"),
           ("gans", "Gans", "die", "Schnatter, schnatter!"), ("eule", "Eule", "die", "Huhu, huhu!"),
           ("kuckuck", "Kuckuck", "der", "Kuckuck, kuckuck!"), ("biene", "Biene", "die", "Summ, summ, summ!"), ("wolf", "Wolf", "der", "Auuuuh!")]
for raw, name, art, imit in ANIMALS:
    add(f"Richtig, das war {art} {name}.", "Tierstimmen"); add(f"{art} {name}", "Tierstimmen")
    add(f"{cap(art)} {name} ist es nicht.", "Tierstimmen"); add(f"Das war {art} {name}. {imit}", "Tierstimmen")

# --- Spiel 10: Naturpaare ---
nat = src("Games/NaturePairs/NaturePairsGameView.swift")
for q in re.findall(r'question: "([^"]+)"', nat):
    add(q, "Naturpaare"); add(f"{q} Finde etwas, das dazu passt.", "Naturpaare")
for e in re.findall(r'explanation: "([^"]+)"', nat):
    add(f"Ja, das passt! {e}", "Naturpaare"); add(f"Diese Bilder passen. {e}", "Naturpaare")
NATURE_ITEMS = sorted(set(re.findall(r'i\("[^"]+", "([^"]+)"\)', nat)))
for n in NATURE_ITEMS:
    add(f"{n} passt hier nicht. Schauen wir es gemeinsam an.", "Naturpaare"); add(f"{n} passt sicher nicht.", "Naturpaare")

# --- Spiel 11: Tierpuzzle ---
PUZZLE = re.findall(r'PuzzleScene\(animal: "[^"]+", name: "([^"]+)", habitat: "([^"]+)"', src("Games/Puzzle/PuzzleGameView.swift"))
def puzzle_art(n):
    if n in ["Eule", "Ente", "Kuh", "Biene", "Schnecke", "Ziege", "Katze"]: return "die"
    return "das" if n in ["Schwein", "Eichhörnchen", "Reh", "Pferd", "Schaf"] else "der"
for n, _ in PUZZLE:
    add(f"Schau dir das Bild genau an. Das ist {puzzle_art(n)} {n}.", "Tierpuzzle")
    add(f"Das ganze Bild ist fertig: {puzzle_art(n)} {n}!", "Tierpuzzle")

# --- Spiel 12: Atelier ---
for t in re.findall(r'"[^"]+", "[^"]+", "(Hilf [^"]+)"', src("Games/Atelier/AtelierPaths.swift")): add(t, "Spurenatelier")

# --- Ausgabe Sprache ---
os.makedirs(os.path.join(ROOT, "assets"), exist_ok=True)
rows = sorted(((slug(t) + ".m4a", t, a) for t, a in lines.items()), key=lambda r: (r[2], r[0]))
# Gleicher Dateiname heisst gleicher Wortlaut (nur Gross-/Kleinschreibung oder Satzzeichen verschieden).
seen, unique = set(), []
for r in rows:
    if r[0] not in seen:
        seen.add(r[0]); unique.append(r)
rows = unique
with open(os.path.join(ROOT, "assets", "Sprachaufnahmen.csv"), "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh, delimiter=";")
    w.writerow(["Datei", "Text", "Bereich"])
    w.writerows(rows)
    for raw, name, _, _ in ANIMALS:
        for v in (1, 2):
            w.writerow([f"tier_{raw}_{v}.m4a", f"ECHTE TIERAUFNAHME: {name} (Variante {v}, 1–3 Sekunden, keine Sprache)", "Tierlaute"])

# --- Ausgabe Bilder ---
img = []
def I(name, motif, use, size="1024x1024"): img.append((name + ".png", motif, use, size))
I("hase_begleiter", "Freundlicher Hase (Begleiter), ganzer Körper, winkend", "Begleiter überall")
for raw, n in [("hase", "Hase"), ("fuchs", "Fuchs"), ("igel", "Igel"), ("eule", "Eule"), ("schildkroete", "Schildkröte"), ("reh", "Reh")]:
    I(f"avatar_{raw}", f"{n}, Kopf/Brustbild, rund komponiert", "Avatar")
GAMES = [("tracing", "grosse Ziffer 3 mit Stift"), ("appleMath", "Äpfel mit Plus-Zeichen"), ("memory", "zwei Karten mit Fuchs"),
         ("snake", "freundliche grüne Schlange mit Erdbeere"), ("counting", "Marienkäfer auf Wiese"), ("shapes", "Haus mit Kreis, Dreieck, Quadrat"),
         ("puzzle", "Bärenbild als Puzzle"), ("pattern", "kleiner Zug mit Blatt/Blume"), ("animalSounds", "Kuh mit Schallwellen"),
         ("naturePairs", "Eichhörnchen mit Nuss"), ("sorting", "Korb mit Blättern"), ("atelier", "Biene, Pinsel und Farben")]
for raw, d in GAMES: I(f"spiel_{raw}", d, "Hub-Kachel")
for n in MEMORY: I("memory_" + slug(n), n, "Memory-Karte")
for raw, name, _, _ in ANIMALS: I(f"tier_{raw}", name, "Tierstimmen (auch als Schatten)")
for n in re.findall(r'PatternMotif\(emoji: "[^"]+", name: "([^"]+)"\)', src("Games/Pattern/PatternGameView.swift")):
    I("muster_" + slug(n), n, "Musterzug")
for m, (sg, _, _) in MOTIFS.items(): I(f"motiv_{m}", f"{sg} (einzeln)", "Rechnen/Zählen", "512x512")
subjects = sorted(set(re.findall(r'subject: i\("[^"]+", "([^"]+)"\)', nat)))
for n in sorted(set(subjects) | set(NATURE_ITEMS)):
    I("natur_" + slug(n), n, "Naturpaare", "512x512")
for n, hab in PUZZLE: I("puzzle_" + slug(n), f"{n} in Landschaft ({hab}), ganze Szene, detailreich: jede Ecke mit eigenem Inhalt, keine grossen leeren Flächen", "Tierpuzzle", "1800x1200 (3:2)")
I("einfuehrung_schmetterling", "Schmetterling", "Einführung", "512x512")
garden = re.findall(r'"([^"]+)": "([a-z]+)"', src("Garden/GardenCatalog.swift"))
GARDEN_DESC = {"aehren": "Getreideähren", "kraeuter": "Kräuterbusch", "gaensebluemchen": "Gänseblümchen", "huette": "kleine Holzhütte",
               "brunnen": "kleiner Gartenbrunnen", "drachen": "Kinderdrachen (Flugdrachen)", "ballon": "Luftballon", "stern": "goldener Stern",
               "haus": "kleines Haus", "nest": "Vogelnest mit Eiern", "kleeblatt": "vierblättriges Kleeblatt"}
for emoji, name in garden:
    I("garten_" + name, GARDEN_DESC.get(name, name.replace("ae", "ä").replace("oe", "ö").replace("ue", "ü").capitalize()), "Garten-Dekoration", "512x512")
I("snake_heidelbeeren", "kleines Büschel Heidelbeeren", "Garten-Snake (Frucht)", "512x512")
I("einfuehrung_blume", "grosse Blume", "Einführung", "512x512")
I("korb", "Weidenkorb", "Einführung", "512x512")
uniq = {}
for r in img: uniq.setdefault(r[0], r)
with open(os.path.join(ROOT, "assets", "Bilder.csv"), "w", newline="", encoding="utf-8") as fh:
    w = csv.writer(fh, delimiter=";")
    w.writerow(["Datei", "Motiv", "Verwendung", "Grösse"])
    w.writerows(uniq.values())

print(f"Sprachaufnahmen: {len(rows)} (+16 Tierlaute)  Bilder: {len(uniq)}")
