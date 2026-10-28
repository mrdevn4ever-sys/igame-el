import SwiftUI

enum Theme {
    static let cream = Color(red: 1.00, green: 0.973, blue: 0.925)
    static let creamDark = Color(red: 0.965, green: 0.925, blue: 0.85)
    static let darkGreen = Color(red: 0.180, green: 0.369, blue: 0.243)
    static let softGreen = Color(red: 0.722, green: 0.878, blue: 0.690)
    static let apricot = Color(red: 1.00, green: 0.835, blue: 0.690)
    static let lightBlue = Color(red: 0.765, green: 0.894, blue: 0.965)
    static let lilac = Color(red: 0.863, green: 0.808, blue: 0.945)
    static let lightYellow = Color(red: 1.00, green: 0.945, blue: 0.690)
    static let card = Color.white
    static let success = Color(red: 0.27, green: 0.62, blue: 0.36)
    static let highlight = Color(red: 1.00, green: 0.78, blue: 0.25)
    static let gentleRed = Color(red: 0.86, green: 0.45, blue: 0.40)
    static let meadow = Color(red: 0.80, green: 0.91, blue: 0.70)
    static let sky = Color(red: 0.86, green: 0.94, blue: 0.98)

    /// Mindestgrössen aus dem Masterplan (Ausgangswerte).
    static let mainActionHeight: CGFloat = 72
    static let controlSize: CGFloat = 64

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static let titleFont = rounded(34)
    static let instructionFont = rounded(28, .semibold)
    static let tileFont = rounded(24)
    static let answerFont = rounded(56, .heavy)
    static let bodyFont = rounded(20, .medium)
}

/// Kräftige Farben für Formen, Zeichnungen und Sortieraufgaben.
enum Palette: String, Codable, CaseIterable {
    case red, orange, yellow, green, blue, purple, pink, brown, black

    var color: Color {
        switch self {
        case .red: return Color(red: 0.89, green: 0.27, blue: 0.25)
        case .orange: return Color(red: 0.98, green: 0.58, blue: 0.18)
        case .yellow: return Color(red: 0.98, green: 0.83, blue: 0.16)
        case .green: return Color(red: 0.30, green: 0.66, blue: 0.32)
        case .blue: return Color(red: 0.22, green: 0.50, blue: 0.86)
        case .purple: return Color(red: 0.58, green: 0.38, blue: 0.80)
        case .pink: return Color(red: 0.95, green: 0.52, blue: 0.70)
        case .brown: return Color(red: 0.55, green: 0.38, blue: 0.24)
        case .black: return Color(red: 0.15, green: 0.15, blue: 0.15)
        }
    }

    var uiColor: UIColor { UIColor(color) }

    var name: String {
        switch self {
        case .red: return "rot"
        case .orange: return "orange"
        case .yellow: return "gelb"
        case .green: return "grün"
        case .blue: return "blau"
        case .purple: return "violett"
        case .pink: return "rosa"
        case .brown: return "braun"
        case .black: return "schwarz"
        }
    }
}
