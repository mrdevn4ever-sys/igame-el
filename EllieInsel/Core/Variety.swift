import Foundation

/// Abwechslung über Runden: Was in den letzten Runden dran war, kommt erst wieder, wenn alles andere dran war.
enum Variety {
    /// So viele Einträge merkt sich jedes Spiel (reicht für deutlich mehr als sechs Runden).
    static let memory = 60

    /// Wie lange ein Inhalt her ist: nie gesehen = sehr lange, gerade eben = 0.
    static func age(_ key: String, in recent: [String]) -> Int {
        recent.firstIndex(of: key) ?? Int.max
    }

    /// Ordnet Kandidaten: noch nie dran (zufällig gemischt), dann die, die am längsten her sind.
    static func freshFirst<T>(_ items: [T], recent: [String], key: (T) -> String) -> [T] {
        items.shuffled()
            .map { ($0, age(key($0), in: recent)) }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    /// War der Inhalt in den letzten `rounds` Runden (bei `perRound` Inhalten pro Runde) schon dran?
    static func isRecent(_ key: String, in recent: [String], perRound: Int, rounds: Int = 6) -> Bool {
        age(key, in: recent) < perRound * rounds
    }
}
