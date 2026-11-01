import Foundation

/// Ergebnis einer gelösten Aufgabe – Grundlage für die automatische Anpassung.
struct TaskResult: Codable, Equatable {
    var level: Int
    /// Fehlversuche (unpassende Wahl, Zusammenstoss, falsch gelegtes Teil …)
    var errors: Int
    /// Höchste genutzte Hilfestufe (0 = keine, 1 = Hinweis, 2 = vorgezeigt, 3 = gemeinsam gelöst)
    var help: Int
    /// Aktive Zeit in Sekunden (ohne Pausen)
    var seconds: Double
}

/// Lernstand eines Spiels.
struct SkillState: Codable, Equatable {
    var level: Int
    var results: [TaskResult] = []
    var abortStreak: Int = 0
    var history: [LevelStep] = []

    struct LevelStep: Codable, Equatable {
        var date: Date
        var level: Int
    }
}

enum TaskRating {
    case strong, good, weak
}

enum LevelChange: Equatable {
    case none
    case up(Int)
    case down
}

/// Bewertet Aufgaben und entscheidet nach jeder Runde über das Niveau.
/// Bewusst ohne Oberfläche, damit sich die Regeln mit simulierten Kindern prüfen lassen.
enum LevelEngine {
    static let historyLimit = 40

    /// Persönliche Referenzzeit: Median der letzten gelösten Aufgaben auf diesem Niveau.
    static func referenceSeconds(_ state: SkillState, level: Int, fallback: Double) -> Double {
        let times = state.results.filter { $0.level == level }.suffix(10).map(\.seconds).sorted()
        guard times.count >= 3 else { return fallback }
        return times[times.count / 2]
    }

    static func rate(_ r: TaskResult, reference: Double) -> TaskRating {
        if r.errors >= 2 || r.help >= 2 { return .weak }
        if r.errors == 0 && r.help == 0 && r.seconds <= reference * 1.25 { return .strong }
        return .good
    }

    /// Wird nach einer abgeschlossenen Runde aufgerufen.
    /// - Parameters:
    ///   - tasksPerRound: Aufgaben pro Runde (bestimmt, wie viele Ergebnisse für einen Aufstieg nötig sind)
    ///   - targetSeconds: Startwert für «zügig» auf dem aktuellen Niveau
    static func finishRound(state: inout SkillState, round: [TaskResult], maxLevel: Int,
                            tasksPerRound: Int, targetSeconds: Double) -> LevelChange {
        state.abortStreak = 0
        // Bewertung mit der Referenz vor dieser Runde (sonst würde sich die Runde selbst messen)
        let reference = referenceSeconds(state, level: state.level, fallback: targetSeconds)
        state.results.append(contentsOf: round)
        if state.results.count > historyLimit {
            state.results.removeFirst(state.results.count - historyLimit)
        }
        let atLevel = state.results.filter { $0.level == state.level }
        let ratings = atLevel.map { rate($0, reference: reference) }

        // Aufstieg: genügend Ergebnisse auf diesem Niveau, fast alle stark, keines schwach.
        let window = tasksPerRound >= 3 ? 5 : 3
        let needed = tasksPerRound >= 3 ? 4 : 2
        let recent = Array(ratings.suffix(window))
        let strong = recent.filter { $0 == .strong }.count
        let weak = recent.filter { $0 == .weak }.count

        // Abstieg: 2 der letzten 4 schwach
        let last4 = ratings.suffix(4)
        if last4.filter({ $0 == .weak }).count >= 2 && state.level > 1 {
            return apply(&state, to: state.level - 1, change: .down)
        }

        if recent.count >= needed && weak == 0 && strong >= needed && state.level < maxLevel {
            // Zwei Runden in Folge nur stark und deutlich schneller: zwei Stufen.
            let lastEight = ratings.suffix(8)
            let fast = atLevel.suffix(8).allSatisfy { $0.seconds <= reference * 0.8 }
            if tasksPerRound >= 3, lastEight.count == 8, lastEight.allSatisfy({ $0 == .strong }), fast,
               state.level + 2 <= maxLevel {
                return apply(&state, to: state.level + 2, change: .up(2))
            }
            return apply(&state, to: state.level + 1, change: .up(1))
        }
        return .none
    }

    /// Runde über das Haus verlassen, nachdem schon etwas gelöst war.
    static func noteAbort(state: inout SkillState) -> LevelChange {
        state.abortStreak += 1
        if state.abortStreak >= 3 && state.level > 1 {
            state.abortStreak = 0
            return apply(&state, to: state.level - 1, change: .down)
        }
        return .none
    }

    private static func apply(_ state: inout SkillState, to level: Int, change: LevelChange) -> LevelChange {
        // Auf dem neuen Niveau frisch beginnen, damit alte Ergebnisse nicht sofort wieder umschalten.
        state.results.removeAll { $0.level == level }
        state.level = level
        state.history.append(.init(date: Date(), level: level))
        if state.history.count > 60 { state.history.removeFirst() }
        return change
    }

    /// Startniveau aus der bisherigen Dreistufen-Einstellung.
    static func startLevel(for d: Difficulty, maxLevel: Int) -> Int {
        switch d {
        case .entdecken: return 1
        case .ueben: return min(maxLevel, max(2, maxLevel * 4 / 10))
        case .knobeln: return min(maxLevel, max(3, maxLevel * 7 / 10))
        }
    }
}
