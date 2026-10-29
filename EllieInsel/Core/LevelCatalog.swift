import Foundation

/// Niveau-Leitern aller Spiele: konkrete Werte pro Stufe und verständliche Beschreibung.
enum LevelCatalog {
    static func maxLevel(_ game: GameID) -> Int {
        switch game {
        case .tracing: return 9
        case .appleMath: return 10
        case .memory: return 8
        case .snake: return 8
        case .counting: return 8
        case .shapes: return 7
        case .puzzle: return 8
        case .pattern: return 7
        case .animalSounds: return 5
        case .naturePairs: return 5
        case .sorting: return 7
        case .atelier: return 6
        }
    }

    /// Startwert in Sekunden für «zügig gelöst», bis persönliche Zeiten vorliegen.
    static func targetSeconds(_ game: GameID, level: Int) -> Double {
        switch game {
        case .tracing: return 14 + Double(level)
        case .appleMath: return 8 + Double(level)
        case .memory: return Double(memoryPairs(level)) * 8
        case .snake: return 12
        case .counting: return 6 + Double(counting(level).range.upperBound)
        case .shapes: return Double(shapes(level).count) * 5
        case .puzzle: return Double(puzzle(level).pieces) * 5
        case .pattern: return 8 + Double(level)
        case .animalSounds: return 9
        case .naturePairs: return 9
        case .sorting: return Double(sorting(level).items) * 3
        case .atelier: return 12 + Double(level) * 2
        }
    }

    /// Kurze Beschreibung für Eltern («Niveau 4: Puzzle mit 12 Teilen»).
    static func describe(_ game: GameID, level: Int) -> String {
        switch game {
        case .tracing:
            let t = tracing(level)
            let numbers = t.numbers.count > 10 ? "Zahlen 10 bis 20" : "Ziffern \(t.numbers.min()!) bis \(t.numbers.max()!)"
            var extra: [String] = []
            if !t.showArrows { extra.append("ohne Pfeile") }
            if !t.showCenterLine { extra.append("ohne Mittellinie") }
            if t.fadeTrack { extra.append("Spur verblasst") }
            return ([numbers] + extra).joined(separator: ", ")
        case .appleMath:
            let m = math(level)
            switch m.kind {
            case .basic: return "\(m.allowMinus ? "Plus und Minus" : "Plus") bis \(m.maxTotal)\(m.story ? ", Bildgeschichten" : "")\(m.showNumbers ? "" : ", ohne Zählhilfe")"
            case .missing: return "Fehlende Zahl finden bis \(m.maxTotal)"
            case .twoStep: return "Zwei Rechenschritte bis \(m.maxTotal)"
            case .symbols: return "Rechnen mit Ziffern bis \(m.maxTotal)"
            }
        case .memory:
            return "\(memoryPairs(level)) Paare\(level >= 8 ? ", kurz aufgedeckt" : "")"
        case .snake:
            let s = snake(level)
            return "\(s.fruits) Früchte, \(s.wraps ? "offener Rand" : "Mauern")\(s.obstacles > 0 ? ", \(s.obstacles) Steine" : ""), Feld \(s.grid)×\(s.grid)"
        case .counting:
            let c = counting(level)
            return "Mengen \(c.range.lowerBound) bis \(c.range.upperBound)"
        case .shapes:
            let s = shapes(level)
            return "\(s.count) Formen\(s.similar ? ", ähnliche Konturen" : "")"
        case .puzzle:
            return "Puzzle mit \(puzzle(level).pieces) Teilen"
        case .pattern:
            return "Muster \(pattern(level).unitLabel), \(pattern(level).options) Antworten"
        case .animalSounds:
            return "\(animals(level).choices) Tiere zur Auswahl\(animals(level).similar ? ", ähnliche Stimmen" : "")"
        case .naturePairs:
            let n = nature(level)
            return "\(n.options) Bilder\(n.multi ? ", mehrere passen" : "")"
        case .sorting:
            let s = sorting(level)
            return "\(s.baskets) Körbe, \(s.items) Dinge\(s.fine ? ", feine Unterschiede" : "")"
        case .atelier:
            return "Wege \(atelier(level).pathLevel.title), Spurbreite \(Int(atelier(level).width * 100))"
        }
    }

    // MARK: - Werte pro Spiel

    struct TracingSpec {
        var numbers: [Int]
        var width: Double
        var tolerance: Double
        var showArrows: Bool
        var showCenterLine: Bool
        var fadeTrack: Bool
    }

    static func tracing(_ l: Int) -> TracingSpec {
        switch l {
        case ...1: return TracingSpec(numbers: [1, 2, 3], width: 0.2, tolerance: 0.1, showArrows: true, showCenterLine: true, fadeTrack: false)
        case 2: return TracingSpec(numbers: Array(1...5), width: 0.2, tolerance: 0.1, showArrows: true, showCenterLine: true, fadeTrack: false)
        case 3: return TracingSpec(numbers: Array(0...9), width: 0.2, tolerance: 0.1, showArrows: true, showCenterLine: true, fadeTrack: false)
        case 4: return TracingSpec(numbers: Array(0...9), width: 0.16, tolerance: 0.08, showArrows: true, showCenterLine: true, fadeTrack: false)
        case 5: return TracingSpec(numbers: Array(0...9), width: 0.16, tolerance: 0.08, showArrows: false, showCenterLine: true, fadeTrack: false)
        case 6: return TracingSpec(numbers: Array(0...9), width: 0.13, tolerance: 0.065, showArrows: false, showCenterLine: false, fadeTrack: false)
        case 7: return TracingSpec(numbers: Array(10...20), width: 0.13, tolerance: 0.06, showArrows: true, showCenterLine: true, fadeTrack: false)
        case 8: return TracingSpec(numbers: Array(10...20), width: 0.11, tolerance: 0.05, showArrows: false, showCenterLine: false, fadeTrack: false)
        default: return TracingSpec(numbers: Array(0...20), width: 0.11, tolerance: 0.05, showArrows: false, showCenterLine: false, fadeTrack: true)
        }
    }

    struct MathSpec {
        enum Kind { case basic, missing, twoStep, symbols }
        var kind: Kind
        var maxTotal: Int
        var allowMinus: Bool
        var options: Int
        var showNumbers: Bool
        var story: Bool
    }

    static func math(_ l: Int) -> MathSpec {
        switch l {
        case ...1: return MathSpec(kind: .basic, maxTotal: 3, allowMinus: false, options: 2, showNumbers: true, story: false)
        case 2: return MathSpec(kind: .basic, maxTotal: 5, allowMinus: false, options: 2, showNumbers: true, story: false)
        case 3: return MathSpec(kind: .basic, maxTotal: 5, allowMinus: true, options: 3, showNumbers: true, story: false)
        case 4: return MathSpec(kind: .basic, maxTotal: 10, allowMinus: true, options: 3, showNumbers: true, story: false)
        case 5: return MathSpec(kind: .basic, maxTotal: 10, allowMinus: true, options: 3, showNumbers: false, story: false)
        case 6: return MathSpec(kind: .basic, maxTotal: 10, allowMinus: true, options: 3, showNumbers: false, story: true)
        case 7: return MathSpec(kind: .basic, maxTotal: 20, allowMinus: true, options: 3, showNumbers: false, story: false)
        case 8: return MathSpec(kind: .missing, maxTotal: 10, allowMinus: false, options: 3, showNumbers: false, story: false)
        case 9: return MathSpec(kind: .twoStep, maxTotal: 10, allowMinus: true, options: 3, showNumbers: false, story: false)
        default: return MathSpec(kind: .symbols, maxTotal: 20, allowMinus: true, options: 4, showNumbers: false, story: false)
        }
    }

    static func memoryPairs(_ l: Int) -> Int {
        [3, 4, 6, 8, 10, 12, 15, 15][min(max(l, 1), 8) - 1]
    }

    struct SnakeSpec {
        var stepSeconds: Double
        var wraps: Bool
        var obstacles: Int
        var grid: Int
        var fruits: Int
    }

    static func snake(_ l: Int) -> SnakeSpec {
        switch l {
        case ...1: return SnakeSpec(stepSeconds: 0.65, wraps: true, obstacles: 0, grid: 12, fruits: 5)
        case 2: return SnakeSpec(stepSeconds: 0.55, wraps: true, obstacles: 0, grid: 12, fruits: 5)
        case 3: return SnakeSpec(stepSeconds: 0.45, wraps: true, obstacles: 0, grid: 12, fruits: 6)
        case 4: return SnakeSpec(stepSeconds: 0.45, wraps: false, obstacles: 0, grid: 12, fruits: 6)
        case 5: return SnakeSpec(stepSeconds: 0.4, wraps: false, obstacles: 4, grid: 12, fruits: 7)
        case 6: return SnakeSpec(stepSeconds: 0.35, wraps: false, obstacles: 5, grid: 14, fruits: 8)
        case 7: return SnakeSpec(stepSeconds: 0.3, wraps: false, obstacles: 7, grid: 14, fruits: 8)
        default: return SnakeSpec(stepSeconds: 0.25, wraps: false, obstacles: 10, grid: 16, fruits: 10)
        }
    }

    struct CountingSpec {
        var range: ClosedRange<Int>
        var options: Int
    }

    static func counting(_ l: Int) -> CountingSpec {
        switch l {
        case ...1: return CountingSpec(range: 1...3, options: 2)
        case 2: return CountingSpec(range: 1...5, options: 2)
        case 3: return CountingSpec(range: 2...8, options: 3)
        case 4: return CountingSpec(range: 3...10, options: 3)
        case 5: return CountingSpec(range: 5...12, options: 3)
        case 6: return CountingSpec(range: 8...15, options: 3)
        case 7: return CountingSpec(range: 10...18, options: 3)
        default: return CountingSpec(range: 12...20, options: 4)
        }
    }

    struct ShapesSpec {
        var count: Int
        var similar: Bool
        var snap: Double
    }

    static func shapes(_ l: Int) -> ShapesSpec {
        switch l {
        case ...1: return ShapesSpec(count: 2, similar: false, snap: 1.0)
        case 2: return ShapesSpec(count: 3, similar: false, snap: 1.0)
        case 3: return ShapesSpec(count: 4, similar: false, snap: 0.9)
        case 4: return ShapesSpec(count: 4, similar: true, snap: 0.85)
        case 5: return ShapesSpec(count: 5, similar: true, snap: 0.8)
        case 6: return ShapesSpec(count: 6, similar: true, snap: 0.75)
        default: return ShapesSpec(count: 6, similar: true, snap: 0.6)
        }
    }

    struct PuzzleSpec {
        var pieces: Int
        var rows: Int
        var cols: Int
    }

    static func puzzle(_ l: Int) -> PuzzleSpec {
        let table: [(Int, Int, Int)] = [(4, 2, 2), (6, 2, 3), (9, 3, 3), (12, 3, 4), (16, 4, 4), (20, 4, 5), (24, 4, 6), (30, 5, 6)]
        let t = table[min(max(l, 1), table.count) - 1]
        return PuzzleSpec(pieces: t.0, rows: t.1, cols: t.2)
    }

    /// Puzzle-Raster zu einer Teilezahl (für gespeicherte Spielstände).
    static func puzzleGrid(pieces: Int) -> (rows: Int, cols: Int) {
        for l in 1...8 where puzzle(l).pieces == pieces { return (puzzle(l).rows, puzzle(l).cols) }
        return (2, 2)
    }

    struct PatternSpec {
        /// Bausteine der Wiederholung, z. B. [0, 1] = AB
        var units: [[Int]]
        var options: Int
        var innerGap: Bool

        var unitLabel: String {
            units.map { u in String(u.map { Character(UnicodeScalar(65 + $0)!) }) }.joined(separator: "/")
        }
    }

    static func pattern(_ l: Int) -> PatternSpec {
        switch l {
        case ...1: return PatternSpec(units: [[0, 1]], options: 2, innerGap: false)
        case 2: return PatternSpec(units: [[0, 1]], options: 3, innerGap: false)
        case 3: return PatternSpec(units: [[0, 0, 1], [0, 1, 1]], options: 3, innerGap: false)
        case 4: return PatternSpec(units: [[0, 1, 2]], options: 3, innerGap: false)
        case 5: return PatternSpec(units: [[0, 0, 1, 1]], options: 3, innerGap: false)
        case 6: return PatternSpec(units: [[0, 1, 2, 3]], options: 4, innerGap: false)
        default: return PatternSpec(units: [[0, 1, 2], [0, 0, 1, 1]], options: 4, innerGap: true)
        }
    }

    struct AnimalSpec {
        var choices: Int
        var similar: Bool
    }

    static func animals(_ l: Int) -> AnimalSpec {
        switch l {
        case ...1: return AnimalSpec(choices: 2, similar: false)
        case 2: return AnimalSpec(choices: 3, similar: false)
        case 3: return AnimalSpec(choices: 4, similar: false)
        case 4: return AnimalSpec(choices: 4, similar: true)
        default: return AnimalSpec(choices: 6, similar: true)
        }
    }

    struct NatureSpec {
        var options: Int
        var multi: Bool
    }

    static func nature(_ l: Int) -> NatureSpec {
        switch l {
        case ...1: return NatureSpec(options: 2, multi: false)
        case 2: return NatureSpec(options: 3, multi: false)
        case 3: return NatureSpec(options: 4, multi: false)
        case 4: return NatureSpec(options: 4, multi: true)
        default: return NatureSpec(options: 5, multi: true)
        }
    }

    struct SortingSpec {
        var baskets: Int
        var items: Int
        var fine: Bool
    }

    static func sorting(_ l: Int) -> SortingSpec {
        switch l {
        case ...1: return SortingSpec(baskets: 2, items: 4, fine: false)
        case 2: return SortingSpec(baskets: 2, items: 6, fine: false)
        case 3: return SortingSpec(baskets: 3, items: 6, fine: false)
        case 4: return SortingSpec(baskets: 3, items: 8, fine: false)
        case 5: return SortingSpec(baskets: 3, items: 9, fine: true)
        case 6: return SortingSpec(baskets: 4, items: 10, fine: false)
        default: return SortingSpec(baskets: 4, items: 12, fine: true)
        }
    }

    struct AtelierSpec {
        var pathLevel: Difficulty
        var width: Double
        var tolerance: Double
        var showArrows: Bool
    }

    static func atelier(_ l: Int) -> AtelierSpec {
        switch l {
        case ...1: return AtelierSpec(pathLevel: .entdecken, width: 0.18, tolerance: 0.1, showArrows: true)
        case 2: return AtelierSpec(pathLevel: .entdecken, width: 0.14, tolerance: 0.08, showArrows: true)
        case 3: return AtelierSpec(pathLevel: .ueben, width: 0.14, tolerance: 0.08, showArrows: true)
        case 4: return AtelierSpec(pathLevel: .ueben, width: 0.11, tolerance: 0.065, showArrows: true)
        case 5: return AtelierSpec(pathLevel: .knobeln, width: 0.09, tolerance: 0.05, showArrows: true)
        default: return AtelierSpec(pathLevel: .knobeln, width: 0.07, tolerance: 0.045, showArrows: false)
        }
    }
}
