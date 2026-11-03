import Foundation

/// Atelier-Schätze: Nach jeder geschafften Lernrunde kommt im Atelier etwas Neues dazu.
/// Nichts Bestehendes wird gesperrt – die Schätze sind zusätzliche Sticker und Hintergründe.
struct AtelierTreasure: Identifiable, Equatable {
    enum Content: Equatable {
        case stickers([String])
        case background(CanvasBackground)
    }

    let id: String
    let title: String
    let icon: String
    let content: Content
}

enum AtelierTreasures {
    /// Feste Reihenfolge: Sticker und Hintergründe wechseln sich ab.
    static let all: [AtelierTreasure] = [
        AtelierTreasure(id: "dinos", title: "Dino-Sticker", icon: "🦕", content: .stickers(["🦕", "🦖", "🥚", "🌋", "🐊"])),
        AtelierTreasure(id: "meer", title: "Meer-Sticker", icon: "🐳", content: .stickers(["🐳", "🐙", "🦀", "🐠", "🐬", "🦈"])),
        AtelierTreasure(id: "nacht", title: "Nachthimmel", icon: "🌙", content: .background(.nacht)),
        AtelierTreasure(id: "weltall", title: "Weltall-Sticker", icon: "🚀", content: .stickers(["🚀", "🪐", "👽", "🛸", "☄️", "🌍"])),
        AtelierTreasure(id: "fahrzeuge", title: "Fahrzeug-Sticker", icon: "🚒", content: .stickers(["🚗", "🚒", "🚜", "🚂", "🚁", "⛵️"])),
        AtelierTreasure(id: "regenbogen", title: "Regenbogen-Bild", icon: "🌈", content: .background(.regenbogen)),
        AtelierTreasure(id: "naschen", title: "Nasch-Sticker", icon: "🍩", content: .stickers(["🍓", "🍉", "🍩", "🍪", "🎂", "🍕"])),
        AtelierTreasure(id: "zauber", title: "Zauber-Sticker", icon: "🪄", content: .stickers(["🧚", "🪄", "🔮", "🧜‍♀️", "🐉", "🏰"])),
        AtelierTreasure(id: "schnee", title: "Schneebild", icon: "⛄️", content: .background(.schnee)),
        AtelierTreasure(id: "zoo", title: "Zoo-Sticker", icon: "🦁", content: .stickers(["🦁", "🐼", "🐯", "🐨", "🦒", "🐘"])),
        AtelierTreasure(id: "musik", title: "Musik-Sticker", icon: "🎸", content: .stickers(["🎵", "🎸", "🥁", "🎺", "🎉", "🎊"])),
        AtelierTreasure(id: "wetter", title: "Wetter-Sticker", icon: "🌤️", content: .stickers(["🌤️", "⛄️", "❄️", "⚡️", "☔️", "🌪️"]))
    ]

    static func treasure(_ id: String) -> AtelierTreasure? { all.first { $0.id == id } }

    /// Nächster noch nicht entdeckter Schatz.
    static func next(after unlocked: [String]) -> AtelierTreasure? {
        all.first { !unlocked.contains($0.id) }
    }

    static func stickers(unlocked: [String]) -> [String] {
        all.filter { unlocked.contains($0.id) }.flatMap { t -> [String] in
            if case .stickers(let s) = t.content { return s }
            return []
        }
    }

    static func backgrounds(unlocked: [String]) -> [CanvasBackground] {
        CanvasBackground.basic + all.filter { unlocked.contains($0.id) }.compactMap { t in
            if case .background(let b) = t.content { return b }
            return nil
        }
    }
}
