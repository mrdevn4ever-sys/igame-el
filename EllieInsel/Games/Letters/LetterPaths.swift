import Foundation

/// Buchstabenvorlagen (Druckschrift wie im Kindergarten): Startpunkt = erster Punkt, Strichfolge und Richtung
/// wie beim Schreibenlernen (von oben nach unten, links vor rechts).
/// Grossbuchstaben: Oberlinie 0.12, Grundlinie 0.88. Kleinbuchstaben: Oberlänge 0.14, Mittellinie 0.42,
/// Grundlinie 0.8, Unterlänge 0.98.
enum LetterPaths {
    typealias P = PathBuilder

    static func shape(_ letter: String) -> TraceShape {
        TraceShape(strokes: strokes(letter))
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    static func strokes(_ l: String) -> [[NPoint]] {
        switch l {
        // MARK: Grossbuchstaben
        case "A": return [P.line((0.5, 0.12), (0.22, 0.88)), P.line((0.5, 0.12), (0.78, 0.88)), P.line((0.33, 0.6), (0.67, 0.6))]
        case "B": return [P.line((0.3, 0.12), (0.3, 0.88)),
                          P.join(P.line((0.3, 0.12), (0.48, 0.12)), P.arc(cx: 0.48, cy: 0.31, r: 0.19, from: -90, to: 90), P.line((0.48, 0.5), (0.3, 0.5))),
                          P.join(P.line((0.3, 0.5), (0.5, 0.5)), P.arc(cx: 0.5, cy: 0.69, r: 0.19, from: -90, to: 90), P.line((0.5, 0.88), (0.3, 0.88)))]
        case "C": return [P.arc(cx: 0.55, cy: 0.5, rx: 0.3, ry: 0.38, from: -40, to: -320, steps: 50)]
        case "D": return [P.line((0.3, 0.12), (0.3, 0.88)),
                          P.join(P.line((0.3, 0.12), (0.4, 0.12)), P.arc(cx: 0.4, cy: 0.5, rx: 0.33, ry: 0.38, from: -90, to: 90, steps: 50), P.line((0.4, 0.88), (0.3, 0.88)))]
        case "E": return [P.line((0.32, 0.12), (0.32, 0.88)), P.line((0.32, 0.12), (0.72, 0.12)), P.line((0.32, 0.5), (0.64, 0.5)), P.line((0.32, 0.88), (0.72, 0.88))]
        case "F": return [P.line((0.34, 0.12), (0.34, 0.88)), P.line((0.34, 0.12), (0.72, 0.12)), P.line((0.34, 0.5), (0.64, 0.5))]
        case "G": return [P.join(P.arc(cx: 0.53, cy: 0.5, rx: 0.3, ry: 0.38, from: -40, to: -360, steps: 55), P.line((0.83, 0.5), (0.6, 0.5)))]
        case "H": return [P.line((0.28, 0.12), (0.28, 0.88)), P.line((0.72, 0.12), (0.72, 0.88)), P.line((0.28, 0.5), (0.72, 0.5))]
        case "I": return [P.line((0.5, 0.12), (0.5, 0.88))]
        case "J": return [P.join(P.line((0.62, 0.12), (0.62, 0.68)), P.arc(cx: 0.45, cy: 0.68, r: 0.17, from: 0, to: 180))]
        case "K": return [P.line((0.3, 0.12), (0.3, 0.88)), P.line((0.72, 0.12), (0.3, 0.55), (0.74, 0.88))]
        case "L": return [P.line((0.32, 0.12), (0.32, 0.88), (0.72, 0.88))]
        case "M": return [P.line((0.22, 0.12), (0.22, 0.88)), P.line((0.22, 0.12), (0.5, 0.62), (0.78, 0.12), (0.78, 0.88))]
        case "N": return [P.line((0.27, 0.12), (0.27, 0.88)), P.line((0.27, 0.12), (0.73, 0.88), (0.73, 0.12))]
        case "O": return [P.arc(cx: 0.5, cy: 0.5, rx: 0.3, ry: 0.38, from: -90, to: -450, steps: 60)]
        case "P": return [P.line((0.3, 0.12), (0.3, 0.88)),
                          P.join(P.line((0.3, 0.12), (0.45, 0.12)), P.arc(cx: 0.45, cy: 0.32, r: 0.2, from: -90, to: 90), P.line((0.45, 0.52), (0.3, 0.52)))]
        case "Q": return [P.arc(cx: 0.5, cy: 0.5, rx: 0.3, ry: 0.38, from: -90, to: -450, steps: 60), P.line((0.56, 0.68), (0.8, 0.92))]
        case "R": return [P.line((0.3, 0.12), (0.3, 0.88)),
                          P.join(P.line((0.3, 0.12), (0.45, 0.12)), P.arc(cx: 0.45, cy: 0.32, r: 0.2, from: -90, to: 90), P.line((0.45, 0.52), (0.3, 0.52))),
                          P.line((0.44, 0.52), (0.74, 0.88))]
        case "S": return [P.join(P.arc(cx: 0.5, cy: 0.31, rx: 0.22, ry: 0.19, from: -20, to: -270, steps: 34),
                                 P.arc(cx: 0.5, cy: 0.69, rx: 0.24, ry: 0.19, from: -90, to: 160, steps: 34))]
        case "T": return [P.line((0.24, 0.12), (0.76, 0.12)), P.line((0.5, 0.12), (0.5, 0.88))]
        case "U": return [P.join(P.line((0.28, 0.12), (0.28, 0.62)), P.arc(cx: 0.5, cy: 0.62, r: 0.22, from: 180, to: 0), P.line((0.72, 0.62), (0.72, 0.12)))]
        case "V": return [P.line((0.22, 0.12), (0.5, 0.88), (0.78, 0.12))]
        case "W": return [P.line((0.14, 0.12), (0.32, 0.88), (0.5, 0.36), (0.68, 0.88), (0.86, 0.12))]
        case "X": return [P.line((0.25, 0.12), (0.75, 0.88)), P.line((0.75, 0.12), (0.25, 0.88))]
        case "Y": return [P.line((0.25, 0.12), (0.5, 0.5)), P.line((0.75, 0.12), (0.5, 0.5), (0.5, 0.88))]
        case "Z": return [P.line((0.25, 0.12), (0.75, 0.12), (0.25, 0.88), (0.75, 0.88))]

        // MARK: Kleinbuchstaben
        case "a": return [P.arc(cx: 0.47, cy: 0.61, rx: 0.18, ry: 0.19, from: -30, to: -390, steps: 50), P.line((0.65, 0.42), (0.65, 0.8))]
        case "b": return [P.line((0.33, 0.14), (0.33, 0.8)), P.arc(cx: 0.51, cy: 0.61, rx: 0.18, ry: 0.19, from: 180, to: 540, steps: 50)]
        case "c": return [P.arc(cx: 0.52, cy: 0.61, rx: 0.18, ry: 0.19, from: -40, to: -320, steps: 40)]
        case "d": return [P.arc(cx: 0.47, cy: 0.61, rx: 0.18, ry: 0.19, from: -30, to: -390, steps: 50), P.line((0.65, 0.14), (0.65, 0.8))]
        case "e": return [P.join(P.line((0.32, 0.61), (0.68, 0.61)), P.arc(cx: 0.5, cy: 0.61, rx: 0.18, ry: 0.19, from: 0, to: -320, steps: 44))]
        case "f": return [P.join(P.arc(cx: 0.58, cy: 0.27, r: 0.12, from: -20, to: -180), P.line((0.46, 0.27), (0.46, 0.8))), P.line((0.32, 0.44), (0.62, 0.44))]
        case "g": return [P.arc(cx: 0.47, cy: 0.61, rx: 0.18, ry: 0.19, from: -30, to: -390, steps: 50),
                          P.join(P.line((0.65, 0.42), (0.65, 0.86)), P.arc(cx: 0.48, cy: 0.86, rx: 0.17, ry: 0.12, from: 0, to: 160))]
        case "h": return [P.line((0.33, 0.14), (0.33, 0.8)), P.join(P.arc(cx: 0.5, cy: 0.6, r: 0.17, from: 180, to: 360), P.line((0.67, 0.6), (0.67, 0.8)))]
        case "i": return [P.line((0.5, 0.42), (0.5, 0.8)), P.line((0.5, 0.26), (0.5, 0.3))]
        case "j": return [P.join(P.line((0.55, 0.42), (0.55, 0.86)), P.arc(cx: 0.42, cy: 0.86, rx: 0.13, ry: 0.12, from: 0, to: 160)), P.line((0.55, 0.26), (0.55, 0.3))]
        case "k": return [P.line((0.33, 0.14), (0.33, 0.8)), P.line((0.64, 0.42), (0.33, 0.64), (0.67, 0.8))]
        case "l": return [P.line((0.5, 0.14), (0.5, 0.8))]
        case "m": return [P.line((0.24, 0.42), (0.24, 0.8)),
                          P.join(P.arc(cx: 0.37, cy: 0.56, rx: 0.13, ry: 0.14, from: 180, to: 360), P.line((0.5, 0.56), (0.5, 0.8))),
                          P.join(P.arc(cx: 0.63, cy: 0.56, rx: 0.13, ry: 0.14, from: 180, to: 360), P.line((0.76, 0.56), (0.76, 0.8)))]
        case "n": return [P.line((0.33, 0.42), (0.33, 0.8)), P.join(P.arc(cx: 0.5, cy: 0.58, rx: 0.17, ry: 0.16, from: 180, to: 360), P.line((0.67, 0.58), (0.67, 0.8)))]
        case "o": return [P.arc(cx: 0.5, cy: 0.61, rx: 0.18, ry: 0.19, from: -90, to: -450, steps: 50)]
        case "p": return [P.line((0.33, 0.42), (0.33, 0.98)), P.arc(cx: 0.51, cy: 0.61, rx: 0.18, ry: 0.19, from: 180, to: 540, steps: 50)]
        case "q": return [P.arc(cx: 0.47, cy: 0.61, rx: 0.18, ry: 0.19, from: -30, to: -390, steps: 50), P.line((0.65, 0.42), (0.65, 0.98))]
        case "r": return [P.line((0.36, 0.42), (0.36, 0.8)), P.arc(cx: 0.52, cy: 0.56, rx: 0.16, ry: 0.14, from: 180, to: 300)]
        case "s": return [P.join(P.arc(cx: 0.5, cy: 0.52, rx: 0.15, ry: 0.1, from: -20, to: -270, steps: 28),
                                 P.arc(cx: 0.5, cy: 0.71, rx: 0.16, ry: 0.09, from: -90, to: 160, steps: 28))]
        case "t": return [P.join(P.line((0.46, 0.2), (0.46, 0.72)), P.arc(cx: 0.56, cy: 0.72, rx: 0.1, ry: 0.08, from: 180, to: 30)), P.line((0.32, 0.42), (0.62, 0.42))]
        case "u": return [P.join(P.line((0.33, 0.42), (0.33, 0.62)), P.arc(cx: 0.5, cy: 0.62, rx: 0.17, ry: 0.18, from: 180, to: 0), P.line((0.67, 0.62), (0.67, 0.42))),
                          P.line((0.67, 0.42), (0.67, 0.8))]
        case "v": return [P.line((0.3, 0.42), (0.5, 0.8), (0.7, 0.42))]
        case "w": return [P.line((0.2, 0.42), (0.35, 0.8), (0.5, 0.52), (0.65, 0.8), (0.8, 0.42))]
        case "x": return [P.line((0.32, 0.42), (0.68, 0.8)), P.line((0.68, 0.42), (0.32, 0.8))]
        case "y": return [P.line((0.3, 0.42), (0.5, 0.8)), P.line((0.7, 0.42), (0.38, 0.98))]
        case "z": return [P.line((0.32, 0.42), (0.68, 0.42), (0.32, 0.8), (0.68, 0.8))]
        default: return [P.line((0.5, 0.12), (0.5, 0.88))]
        }
    }
}
