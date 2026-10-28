import SwiftUI

/// Alle zwölf Spiele der Insel. Die Reihenfolge entspricht den festen Positionen im Hub
/// (je Seite zeilenweise: oben links, oben Mitte, oben rechts, unten links, ...).
enum GameID: String, Codable, CaseIterable, Identifiable, Hashable {
    // Seite 1
    case tracing
    case appleMath
    case memory
    case snake
    case counting
    case shapes
    // Seite 2
    case puzzle
    case pattern
    case animalSounds
    case naturePairs
    case sorting
    case atelier

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tracing: return "Zahlen nachzeichnen"
        case .appleMath: return "Apfel-Rechnen"
        case .memory: return "Tier-Memory"
        case .snake: return "Garten-Snake"
        case .counting: return "Zählgarten"
        case .shapes: return "Formenhaus"
        case .puzzle: return "Tierpuzzle"
        case .pattern: return "Musterzug"
        case .animalSounds: return "Tierstimmen"
        case .naturePairs: return "Naturpaare"
        case .sorting: return "Sortiergarten"
        case .atelier: return "Spurenatelier"
        }
    }

    var emoji: String {
        switch self {
        case .tracing: return "✏️"
        case .appleMath: return "🍎"
        case .memory: return "🦊"
        case .snake: return "🐍"
        case .counting: return "🐞"
        case .shapes: return "🔷"
        case .puzzle: return "🧩"
        case .pattern: return "🚂"
        case .animalSounds: return "🐮"
        case .naturePairs: return "🐿️"
        case .sorting: return "🧺"
        case .atelier: return "🎨"
        }
    }

    /// Kleines Bild, das zusätzlich auf der Kachel erscheint.
    var tileDecoration: String {
        switch self {
        case .tracing: return "3"
        case .appleMath: return "+"
        case .memory: return "🦊"
        case .snake: return "🍓"
        case .counting: return "1 2 3"
        case .shapes: return "▲ ●"
        case .puzzle: return "🐻"
        case .pattern: return "🍃🌼🍃"
        case .animalSounds: return "🔊"
        case .naturePairs: return "🌰"
        case .sorting: return "🍂"
        case .atelier: return "🐝"
        }
    }

    var tint: Color {
        switch self {
        case .tracing, .shapes, .naturePairs: return Theme.softGreen
        case .appleMath, .animalSounds: return Theme.apricot
        case .memory, .puzzle: return Theme.lightBlue
        case .counting, .pattern, .sorting: return Theme.lilac
        case .snake, .atelier: return Theme.lightYellow
        }
    }

    var page: Int { GameID.allCases.firstIndex(of: self)! / 6 }

    /// Kurze Begrüssung beim Öffnen eines Spiels.
    var welcome: String {
        switch self {
        case .tracing: return "Wir zeichnen Zahlen nach."
        case .appleMath: return "Wir rechnen mit Äpfeln."
        case .memory: return "Wir suchen gleiche Karten."
        case .snake: return "Die Schlange sammelt Früchte."
        case .counting: return "Wir zählen im Garten."
        case .shapes: return "Welche Form passt wohin?"
        case .puzzle: return "Wir setzen ein Tierbild zusammen."
        case .pattern: return "Der Musterzug fährt los."
        case .animalSounds: return "Wir hören Tierstimmen."
        case .naturePairs: return "Was gehört zusammen?"
        case .sorting: return "Wir sortieren im Garten."
        case .atelier: return "Willkommen im Atelier."
        }
    }

    /// Anzahl Aufgaben bis zum Rundenabschluss (für Übungsspiele).
    var tasksPerRound: Int {
        switch self {
        case .memory, .puzzle: return 1
        case .snake: return 5
        case .atelier: return 3
        default: return 4
        }
    }

    /// Wird der Fortschritt mit Punkten unten angezeigt?
    var showsTaskDots: Bool {
        switch self {
        case .memory, .puzzle: return false
        default: return true
        }
    }
}

enum Difficulty: String, Codable, CaseIterable, Identifiable {
    case entdecken
    case ueben
    case knobeln

    var id: String { rawValue }

    var title: String {
        switch self {
        case .entdecken: return "Entdecken"
        case .ueben: return "Üben"
        case .knobeln: return "Knobeln"
        }
    }

    var explanation: String {
        switch self {
        case .entdecken: return "Wenig Auswahl, grosse Ziele und deutliche Hilfen."
        case .ueben: return "Mehr Mengen, Karten oder Formen, etwas weniger Hilfe."
        case .knobeln: return "Anspruchsvollere Aufgaben und Regeln."
        }
    }

    var symbol: String {
        switch self {
        case .entdecken: return "🌱"
        case .ueben: return "🌿"
        case .knobeln: return "🌳"
        }
    }
}
