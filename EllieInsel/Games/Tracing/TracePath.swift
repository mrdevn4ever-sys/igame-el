import Foundation
import CoreGraphics

/// Ein nachzuzeichnender Pfad aus einem oder mehreren Strichen in normalisierten Koordinaten (0...1).
struct TraceShape {
    var strokes: [[NPoint]]

    /// Gleichmässig verteilte Prüfpunkte je Strich.
    func resampled(spacing: Double = 0.012) -> [[NPoint]] {
        strokes.map { TraceShape.resample($0, spacing: spacing) }
    }

    static func resample(_ pts: [NPoint], spacing: Double) -> [NPoint] {
        guard pts.count > 1 else { return pts }
        var out: [NPoint] = [pts[0]]
        var carry = 0.0
        for i in 1..<pts.count {
            let a = pts[i - 1], b = pts[i]
            let len = hypot(b.x - a.x, b.y - a.y)
            guard len > 0 else { continue }
            var d = spacing - carry
            while d <= len {
                let t = d / len
                out.append(NPoint(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t))
                d += spacing
            }
            carry = len - (d - spacing)
        }
        if let last = pts.last, out.last != last { out.append(last) }
        return out
    }
}

/// Bausteine zum Beschreiben von Pfaden.
enum PathBuilder {
    static func line(_ pts: (Double, Double)...) -> [NPoint] {
        pts.map { NPoint($0.0, $0.1) }
    }

    /// Ellipsenbogen; Winkel in Grad, 0° = rechts, 90° = unten (Bildschirmkoordinaten).
    static func arc(cx: Double, cy: Double, rx: Double, ry: Double, from: Double, to: Double, steps: Int = 40) -> [NPoint] {
        (0...steps).map { i in
            let a = (from + (to - from) * Double(i) / Double(steps)) * .pi / 180
            return NPoint(cx + rx * cos(a), cy + ry * sin(a))
        }
    }

    static func arc(cx: Double, cy: Double, r: Double, from: Double, to: Double, steps: Int = 40) -> [NPoint] {
        arc(cx: cx, cy: cy, rx: r, ry: r, from: from, to: to, steps: steps)
    }

    /// Quadratische Bézierkurve.
    static func quad(_ a: (Double, Double), _ c: (Double, Double), _ b: (Double, Double), steps: Int = 24) -> [NPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            let u = 1 - t
            return NPoint(u * u * a.0 + 2 * u * t * c.0 + t * t * b.0,
                          u * u * a.1 + 2 * u * t * c.1 + t * t * b.1)
        }
    }

    static func join(_ parts: [NPoint]...) -> [NPoint] {
        var out: [NPoint] = []
        for p in parts {
            if let last = out.last, let first = p.first, last == first {
                out.append(contentsOf: p.dropFirst())
            } else {
                out.append(contentsOf: p)
            }
        }
        return out
    }
}

/// Ziffernvorlagen 0–9 mit Startpunkt (erster Punkt) und Zeichenrichtung (Punktfolge).
enum DigitPaths {
    /// Zahl 0–20; zweistellige Zahlen bestehen aus zwei verkleinerten Ziffern nebeneinander.
    static func number(_ n: Int) -> TraceShape {
        guard n >= 10 else { return shape(for: n) }
        let tens = shape(for: n / 10).strokes.map { $0.map { NPoint($0.x * 0.52 - 0.02, $0.y) } }
        let ones = shape(for: n % 10).strokes.map { $0.map { NPoint($0.x * 0.52 + 0.48, $0.y) } }
        return TraceShape(strokes: tens + ones)
    }

    static func shape(for digit: Int) -> TraceShape {
        typealias P = PathBuilder
        switch digit {
        case 0:
            return TraceShape(strokes: [P.arc(cx: 0.5, cy: 0.5, rx: 0.25, ry: 0.38, from: -90, to: -450, steps: 60)])
        case 1:
            return TraceShape(strokes: [P.line((0.33, 0.28), (0.56, 0.1), (0.56, 0.9))])
        case 2:
            return TraceShape(strokes: [P.join(
                P.arc(cx: 0.5, cy: 0.32, r: 0.21, from: -170, to: 25),
                P.line((0.5 + 0.21 * cos(25 * .pi / 180), 0.32 + 0.21 * sin(25 * .pi / 180)), (0.28, 0.9), (0.76, 0.9))
            )])
        case 3:
            return TraceShape(strokes: [P.join(
                P.arc(cx: 0.48, cy: 0.3, r: 0.19, from: -160, to: 90),
                P.arc(cx: 0.48, cy: 0.695, r: 0.205, from: -90, to: 160)
            )])
        case 4:
            return TraceShape(strokes: [
                P.line((0.56, 0.1), (0.24, 0.64), (0.8, 0.64)),
                P.line((0.62, 0.38), (0.62, 0.92))
            ])
        case 5:
            return TraceShape(strokes: [
                P.join(
                    P.line((0.36, 0.1), (0.33, 0.46)),
                    P.arc(cx: 0.5, cy: 0.66, r: 0.22, from: -130, to: 145)
                ),
                P.line((0.36, 0.1), (0.72, 0.1))
            ])
        case 6:
            return TraceShape(strokes: [P.join(
                P.quad((0.66, 0.1), (0.32, 0.25), (0.29, 0.68)),
                P.arc(cx: 0.5, cy: 0.68, r: 0.21, from: 180, to: -180, steps: 50)
            )])
        case 7:
            return TraceShape(strokes: [P.line((0.26, 0.1), (0.74, 0.1), (0.42, 0.92))])
        case 8:
            return TraceShape(strokes: [P.join(
                P.arc(cx: 0.5, cy: 0.3, rx: 0.17, ry: 0.19, from: -90, to: -270, steps: 30),
                P.arc(cx: 0.5, cy: 0.7, rx: 0.21, ry: 0.21, from: -90, to: 270, steps: 50),
                P.arc(cx: 0.5, cy: 0.3, rx: 0.17, ry: 0.19, from: 90, to: -90, steps: 30)
            )])
        default: // 9
            return TraceShape(strokes: [P.join(
                P.arc(cx: 0.5, cy: 0.32, r: 0.21, from: 0, to: -360, steps: 50),
                P.line((0.71, 0.32), (0.66, 0.92))
            )])
        }
    }
}

/// Vergleicht Fingerbewegungen mit einem Pfad. Bestätigte Abschnitte bleiben erhalten;
/// es zählt nur ein Fortschreiten in der vorgesehenen Reihenfolge (kein Überspringen).
struct TraceProgress: Codable, Equatable {
    /// Bestätigter Index je Strich (-1 = noch nicht begonnen).
    var confirmed: [Int]
    var currentStroke: Int = 0

    init(strokeCount: Int) {
        confirmed = Array(repeating: -1, count: strokeCount)
    }

    var isComplete: Bool { currentStroke >= confirmed.count }

    /// - Parameters:
    ///   - point: Fingerposition (normalisiert)
    ///   - samples: dichte Prüfpunkte je Strich
    ///   - tolerance: zulässige Abweichung (normalisiert)
    ///   - lookahead: wie viele Prüfpunkte maximal auf einmal übersprungen werden dürfen
    /// - Returns: `true`, wenn sich der Fortschritt verändert hat.
    @discardableResult
    mutating func feed(_ point: NPoint, samples: [[NPoint]], tolerance: Double, lookahead: Int) -> Bool {
        guard !isComplete else { return false }
        let pts = samples[currentStroke]
        var idx = confirmed[currentStroke]
        let start = idx + 1
        guard start < pts.count else { return false }
        // Beginn eines Strichs: nur in der Nähe des Startpunkts.
        let end = min(pts.count - 1, idx < 0 ? 2 : idx + lookahead)
        var advanced = false
        var best = -1
        for j in start...end {
            let p = pts[j]
            if hypot(p.x - point.x, p.y - point.y) <= tolerance {
                best = j
            }
        }
        if best >= 0 {
            idx = best
            advanced = true
        }
        confirmed[currentStroke] = idx
        // Strich fertig, wenn das Ende (fast) erreicht ist.
        if idx >= pts.count - 2 {
            confirmed[currentStroke] = pts.count - 1
            currentStroke += 1
        }
        return advanced
    }

    func fraction(stroke: Int, samples: [[NPoint]]) -> Double {
        let n = samples[stroke].count
        guard n > 1 else { return 0 }
        return Double(max(0, confirmed[stroke])) / Double(n - 1)
    }
}
