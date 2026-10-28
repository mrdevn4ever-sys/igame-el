import Foundation

/// Zählbare Motive mit korrekter Einzahl/Mehrzahl.
enum CountMotif: String, Codable, CaseIterable {
    case apfel, karotte, kaefer, birne, erdbeere, blume, pilz, eichel

    var emoji: String {
        switch self {
        case .apfel: return "🍎"
        case .karotte: return "🥕"
        case .kaefer: return "🐞"
        case .birne: return "🍐"
        case .erdbeere: return "🍓"
        case .blume: return "🌼"
        case .pilz: return "🍄"
        case .eichel: return "🌰"
        }
    }

    var singular: String {
        switch self {
        case .apfel: return "Apfel"
        case .karotte: return "Karotte"
        case .kaefer: return "Käfer"
        case .birne: return "Birne"
        case .erdbeere: return "Erdbeere"
        case .blume: return "Blume"
        case .pilz: return "Pilz"
        case .eichel: return "Eichel"
        }
    }

    var plural: String {
        switch self {
        case .apfel: return "Äpfel"
        case .karotte: return "Karotten"
        case .kaefer: return "Käfer"
        case .birne: return "Birnen"
        case .erdbeere: return "Erdbeeren"
        case .blume: return "Blumen"
        case .pilz: return "Pilze"
        case .eichel: return "Eicheln"
        }
    }

    var feminine: Bool {
        switch self {
        case .apfel, .kaefer, .pilz: return false
        default: return true
        }
    }

    /// «ein Apfel», «eine Karotte», «drei Äpfel».
    func phrase(_ n: Int) -> String {
        if n == 1 { return (feminine ? "eine " : "ein ") + singular }
        return "\(NumberWords.word(n)) \(plural)"
    }

    /// Akkusativ: «einen Apfel», «eine Karotte», «drei Äpfel».
    func accusative(_ n: Int) -> String {
        if n == 1 { return (feminine ? "eine " : "einen ") + singular }
        return "\(NumberWords.word(n)) \(plural)"
    }

    /// Pronomen für «Wie viele …?»
    var isAnimal: Bool { self == .kaefer }
}

extension String {
    var capitalizedFirst: String {
        guard let f = first else { return self }
        return f.uppercased() + dropFirst()
    }
}
