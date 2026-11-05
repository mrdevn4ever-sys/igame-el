import Foundation

/// Ein Buchstabe mit Anlautwort («A wie Apfel»).
struct LetterInfo: Codable, Equatable, Hashable {
    var upper: String
    var word: String     // Anlautwort, so wie es geschrieben wird
    var emoji: String

    var lower: String { upper.lowercased() }
    var picture: String { "abc_" + word.voiceSlug }

    // Gesprochene Sätze (gleiche Muster stehen in tools/asset_manifest.py)
    var intro: String { "Das ist das \(upper). \(upper) wie \(word)." }
    var introSmall: String { "Das ist das kleine \(lower). \(upper) wie \(word)." }
    var startsWith: String { "Womit beginnt \(word)?" }
    var startsWithRight: String { "Ja! \(word) beginnt mit \(upper)." }
    var whereIs: String { "Wo ist das \(upper)?" }
    var pairQuestion: String { "Welcher kleine Buchstabe gehört zum grossen \(upper)?" }
    var pairRight: String { "Genau, das grosse \(upper) und das kleine \(lower) gehören zusammen." }
}

/// Ein Wort zum Schreiben.
struct WordInfo: Codable, Equatable, Hashable {
    var word: String     // so geschrieben, wie es richtig ist (Nomen gross)
    var emoji: String

    var picture: String { "abc_" + word.voiceSlug }
    var upper: String { word.uppercased() }
    var prompt: String { "Schreib das Wort \(word)." }
    var lay: String { "Leg das Wort \(word)." }
    var done: String { "Toll, du hast \(word) geschrieben!" }
}

enum LetterCatalog {
    private static func L(_ u: String, _ w: String, _ e: String) -> LetterInfo { LetterInfo(upper: u, word: w, emoji: e) }

    /// Anlautwörter: Der Anfangslaut ist klar zu hören (keine Wörter mit Sch, Ch, Ei am Anfang).
    static let letters: [LetterInfo] = [
        L("A", "Apfel", "🍎"), L("B", "Ball", "⚽️"), L("C", "Clown", "🤡"), L("D", "Dino", "🦕"),
        L("E", "Esel", "🫏"), L("F", "Fisch", "🐟"), L("G", "Gabel", "🍴"), L("H", "Hund", "🐕"),
        L("I", "Igel", "🦔"), L("J", "Jacke", "🧥"), L("K", "Katze", "🐱"), L("L", "Löwe", "🦁"),
        L("M", "Maus", "🐭"), L("N", "Nase", "👃"), L("O", "Ohr", "👂"), L("P", "Pinguin", "🐧"),
        L("Q", "Qualle", "🪼"), L("R", "Rakete", "🚀"), L("S", "Sonne", "☀️"), L("T", "Tomate", "🍅"),
        L("U", "Uhr", "⏰"), L("V", "Vogel", "🐦"), L("W", "Wal", "🐋"), L("X", "Xylofon", "🎶"),
        L("Y", "Yak", "🐂"), L("Z", "Zebra", "🦓")
    ]

    static func info(_ letter: String) -> LetterInfo {
        letters.first { $0.upper == letter.uppercased() } ?? letters[0]
    }

    // Lernreihenfolge der Grossbuchstaben: gerade Striche, Bögen, Schräge.
    static let straight = ["L", "T", "I", "H", "E", "F"]
    static let curved = ["O", "C", "U", "D", "P", "B", "R", "J", "S", "G"]
    static let diagonal = ["A", "V", "M", "N", "W", "K", "X", "Y", "Z", "Q"]
    static var allUpper: [String] { straight + curved + diagonal }

    /// Niveau 1: alle Grossbuchstaben nur aus geraden Strichen (auch schräge), 15 Stück –
    /// genug, damit aufeinanderfolgende Runden nie dieselben Buchstaben haben.
    static var lineLetters: [String] { straight + diagonal.filter { $0 != "Q" } }
    /// Niveau 2: alle Grossbuchstaben mit Bögen (11 Stück).
    static var roundLetters: [String] { curved + ["Q"] }

    // Kleinbuchstaben: zuerst die einfachen.
    static let easyLower = ["l", "i", "o", "c", "a", "e", "u", "n", "m", "h", "r", "s", "t"]
    static let hardLower = ["b", "d", "p", "q", "g", "j", "k", "f", "v", "w", "x", "y", "z"]
    static var allLower: [String] { easyLower + hardLower }

    private static func W(_ w: String, _ e: String) -> WordInfo { WordInfo(word: w, emoji: e) }

    /// Kurze, lautgetreue Wörter ohne Umlaute (in Grossbuchstaben geschrieben).
    static let shortWords: [WordInfo] = [
        W("Mama", "👩"), W("Papa", "👨"), W("Oma", "👵"), W("Opa", "👴"), W("Auto", "🚗"), W("Eis", "🍦"),
        W("Ast", "🌿"), W("Ohr", "👂"), W("Uhr", "⏰"), W("Bus", "🚌"), W("Zoo", "🦒"), W("Dino", "🦕")
    ]
    static let longerWords: [WordInfo] = [
        W("Maus", "🐭"), W("Hund", "🐕"), W("Ball", "⚽️"), W("Nase", "👃"), W("Igel", "🦔"), W("Esel", "🫏"),
        W("Rose", "🌹"), W("Baum", "🌳"), W("Haus", "🏠"), W("Sonne", "☀️"), W("Tomate", "🍅"), W("Banane", "🍌")
    ]

    static let nameIntro = "Jetzt schreibst du deinen Namen."
    static let start = "Beginne beim Punkt."
    static let wellDone = "Super geschrieben!"
    static let tryAgain = "Das ist ein anderer Buchstabe. Schau nochmals genau."
    static let listen = "Hör nochmals genau hin."
    static let wordWrong = "Dieser Buchstabe kommt noch nicht. Hör genau hin."
}
