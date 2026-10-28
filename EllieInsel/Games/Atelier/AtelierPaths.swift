import Foundation

struct AtelierPath {
    var id: Int
    var difficulty: Difficulty
    var start: String
    var goal: String
    var task: String
    var points: [NPoint]
}

/// Fünfzehn Wege, fünf pro Stufe.
enum AtelierPaths {
    typealias P = PathBuilder

    private static let pairs: [(String, String, String)] = [
        ("🐝", "🌼", "Hilf der Biene zur Blume."),
        ("🐌", "🍃", "Hilf der Schnecke zum Blatt."),
        ("🐞", "🌸", "Hilf dem Marienkäfer zur Blüte."),
        ("🐿️", "🌰", "Hilf dem Eichhörnchen zur Nuss."),
        ("🐇", "🥕", "Hilf dem Hasen zur Karotte."),
        ("🦋", "🌻", "Hilf dem Schmetterling zur Sonnenblume.")
    ]

    private static func wave(from x0: Double, to x1: Double, y: Double, amp: Double, periods: Double, steps: Int = 60) -> [NPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            return NPoint(x0 + (x1 - x0) * t, y + amp * sin(t * periods * 2 * .pi))
        }
    }

    private static let shapes: [(Difficulty, [NPoint])] = [
        // Entdecken: breite, kurze, einfache Wege
        (.entdecken, P.line((0.15, 0.5), (0.85, 0.5))),
        (.entdecken, P.line((0.18, 0.78), (0.82, 0.22))),
        (.entdecken, P.quad((0.15, 0.65), (0.5, 0.15), (0.85, 0.65))),
        (.entdecken, P.line((0.5, 0.15), (0.5, 0.85))),
        (.entdecken, P.line((0.22, 0.22), (0.22, 0.75), (0.8, 0.75))),
        // Üben: Kurven und Richtungswechsel
        (.ueben, P.join(P.quad((0.12, 0.3), (0.3, 0.0), (0.5, 0.5)), P.quad((0.5, 0.5), (0.7, 1.0), (0.88, 0.7)))),
        (.ueben, P.line((0.1, 0.7), (0.3, 0.3), (0.5, 0.7), (0.7, 0.3), (0.9, 0.7))),
        (.ueben, wave(from: 0.1, to: 0.9, y: 0.5, amp: 0.18, periods: 1.5)),
        (.ueben, P.join(P.line((0.22, 0.2), (0.22, 0.55)), P.arc(cx: 0.5, cy: 0.55, r: 0.28, from: 180, to: 0), P.line((0.78, 0.55), (0.78, 0.2)))),
        (.ueben, P.line((0.1, 0.82), (0.3, 0.82), (0.3, 0.62), (0.5, 0.62), (0.5, 0.42), (0.7, 0.42), (0.7, 0.22), (0.9, 0.22))),
        // Knobeln: längere und genauere Verläufe
        (.knobeln, P.join(P.line((0.1, 0.5), (0.3, 0.5)), P.arc(cx: 0.45, cy: 0.5, r: 0.15, from: 180, to: -180), P.line((0.3, 0.5), (0.3, 0.52), (0.9, 0.52)))),
        (.knobeln, wave(from: 0.08, to: 0.92, y: 0.5, amp: 0.25, periods: 2.5, steps: 90)),
        (.knobeln, P.line((0.08, 0.15), (0.92, 0.15), (0.92, 0.4), (0.08, 0.4), (0.08, 0.65), (0.92, 0.65), (0.92, 0.88))),
        (.knobeln, P.line((0.1, 0.8), (0.22, 0.2), (0.34, 0.8), (0.46, 0.2), (0.58, 0.8), (0.7, 0.2), (0.82, 0.8), (0.9, 0.5))),
        (.knobeln, P.join(P.arc(cx: 0.5, cy: 0.5, r: 0.38, from: 180, to: 450, steps: 70), P.arc(cx: 0.5, cy: 0.68, r: 0.2, from: 90, to: 360, steps: 50)))
    ]

    static let all: [AtelierPath] = shapes.enumerated().map { i, entry in
        let pair = pairs[i % pairs.count]
        return AtelierPath(id: i, difficulty: entry.0, start: pair.0, goal: pair.1, task: pair.2, points: entry.1)
    }

    static func paths(for d: Difficulty) -> [AtelierPath] {
        all.filter { $0.difficulty == d }
    }
}
