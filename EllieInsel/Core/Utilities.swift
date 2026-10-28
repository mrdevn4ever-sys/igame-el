import Foundation
import CryptoKit
import CoreGraphics

/// Reproduzierbarer Zufallsgenerator (SplitMix64).
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

extension String {
    /// Stabiler Hash (unabhängig vom Prozess, im Gegensatz zu `hashValue`).
    var stableHash: UInt64 {
        var h: UInt64 = 1_469_598_103_934_665_603
        for b in utf8 {
            h ^= UInt64(b)
            h = h &* 1_099_511_628_211
        }
        return h
    }

    /// Dateiname für vorproduzierte Sprachaufnahmen.
    var voiceSlug: String {
        var s = lowercased()
        let map: [String: String] = ["ä": "ae", "ö": "oe", "ü": "ue", "ß": "ss", "é": "e", "è": "e", "à": "a"]
        for (k, v) in map { s = s.replacingOccurrences(of: k, with: v) }
        var out = ""
        var lastUnderscore = false
        for ch in s.unicodeScalars {
            if CharacterSet.alphanumerics.contains(ch) && ch.isASCII {
                out.unicodeScalars.append(ch)
                lastUnderscore = false
            } else if !lastUnderscore && !out.isEmpty {
                out.append("_")
                lastUnderscore = true
            }
        }
        while out.hasSuffix("_") { out.removeLast() }
        if out.count > 80 {
            // Lange Sätze: gekürzt plus Prüfsumme, damit sich keine Namen überschneiden.
            return String(out.prefix(60)) + "_" + String(String(out.stableHash, radix: 16).prefix(8))
        }
        return out
    }
}

enum CodeHasher {
    static func hash(_ code: String) -> String {
        let digest = SHA256.hash(data: Data(("ellie-insel-" + code).utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

enum NumberWords {
    static let words = [
        "null", "eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht", "neun", "zehn",
        "elf", "zwölf", "dreizehn", "vierzehn", "fünfzehn", "sechzehn", "siebzehn", "achtzehn", "neunzehn", "zwanzig"
    ]

    /// Zahlwort zum Zählen («eins, zwei, drei»).
    static func word(_ n: Int) -> String {
        n >= 0 && n < words.count ? words[n] : "\(n)"
    }

    /// Zahlwort vor einem Nomen («ein Apfel», «drei Äpfel»).
    static func cardinal(_ n: Int, feminine: Bool = false, neuter: Bool = false) -> String {
        if n == 1 { return feminine ? "eine" : "ein" }
        return word(n)
    }

    /// Grossgeschriebene Ziffernbezeichnung («die Drei»).
    static func digitName(_ n: Int) -> String {
        let names = ["Null", "Eins", "Zwei", "Drei", "Vier", "Fünf", "Sechs", "Sieben", "Acht", "Neun"]
        return n >= 0 && n < names.count ? names[n] : "\(n)"
    }
}

extension CGPoint {
    func distance(to p: CGPoint) -> CGFloat {
        hypot(x - p.x, y - p.y)
    }

    static func + (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x + b.x, y: a.y + b.y) }
    static func - (a: CGPoint, b: CGPoint) -> CGPoint { CGPoint(x: a.x - b.x, y: a.y - b.y) }
    static func * (a: CGPoint, s: CGFloat) -> CGPoint { CGPoint(x: a.x * s, y: a.y * s) }
}

/// Codierbarer Punkt in normalisierten Koordinaten (0...1).
struct NPoint: Codable, Equatable, Hashable {
    var x: Double
    var y: Double

    init(_ x: Double, _ y: Double) {
        self.x = x
        self.y = y
    }

    var cg: CGPoint { CGPoint(x: x, y: y) }

    func scaled(in rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

extension Collection where Element: Equatable {
    /// Alle Elemente verschieden?
    var allDistinct: Bool {
        var seen: [Element] = []
        for e in self {
            if seen.contains(e) { return false }
            seen.append(e)
        }
        return true
    }
}
