import Foundation

/// Gesamter lokal gespeicherter Zustand (ohne Zeichnungen, die separat liegen).
struct AppData: Codable {
    var version: Int = 1

    // Einrichtung
    var setupStep: Int = 0
    var setupComplete: Bool = false
    var tutorialDone: Bool = false

    var profile = Profile()
    var sound = SoundSettings()
    var difficulties: [String: Difficulty] = [:]
    var hiddenGames: Set<String> = []
    var options = GameOptions()

    // Elternzugang
    var parentCodeHash: String = ""
    var breakReminderMinutes: Int = 0 // 0 = aus

    // Spielstände
    var lastGame: String?
    var saves: [String: Data] = [:]

    // Fortschritt
    var activities: [ActivityEntry] = []
    var roundsCompleted: [String: Int] = [:]
    var practicedItems: [String: [String]] = [:]

    var garden = GardenData()

    func difficulty(for game: GameID) -> Difficulty {
        difficulties[game.rawValue] ?? .entdecken
    }

    func isVisible(_ game: GameID) -> Bool {
        !hiddenGames.contains(game.rawValue)
    }

    init() {}

    // Tolerantes Dekodieren, damit spätere Updates alte Spielstände nicht verlieren.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = AppData.blank
        version = (try? c.decode(Int.self, forKey: .version)) ?? d.version
        setupStep = (try? c.decode(Int.self, forKey: .setupStep)) ?? d.setupStep
        setupComplete = (try? c.decode(Bool.self, forKey: .setupComplete)) ?? d.setupComplete
        tutorialDone = (try? c.decode(Bool.self, forKey: .tutorialDone)) ?? d.tutorialDone
        profile = (try? c.decode(Profile.self, forKey: .profile)) ?? d.profile
        sound = (try? c.decode(SoundSettings.self, forKey: .sound)) ?? d.sound
        difficulties = (try? c.decode([String: Difficulty].self, forKey: .difficulties)) ?? d.difficulties
        hiddenGames = (try? c.decode(Set<String>.self, forKey: .hiddenGames)) ?? d.hiddenGames
        options = (try? c.decode(GameOptions.self, forKey: .options)) ?? d.options
        parentCodeHash = (try? c.decode(String.self, forKey: .parentCodeHash)) ?? d.parentCodeHash
        breakReminderMinutes = (try? c.decode(Int.self, forKey: .breakReminderMinutes)) ?? d.breakReminderMinutes
        lastGame = try? c.decode(String.self, forKey: .lastGame)
        saves = (try? c.decode([String: Data].self, forKey: .saves)) ?? d.saves
        activities = (try? c.decode([ActivityEntry].self, forKey: .activities)) ?? d.activities
        roundsCompleted = (try? c.decode([String: Int].self, forKey: .roundsCompleted)) ?? d.roundsCompleted
        practicedItems = (try? c.decode([String: [String]].self, forKey: .practicedItems)) ?? d.practicedItems
        garden = (try? c.decode(GardenData.self, forKey: .garden)) ?? d.garden
    }

    private static let blank = AppData()
}

struct Profile: Codable, Equatable {
    var name: String = "Ellie"
    var avatar: Avatar = .hase
}

enum Avatar: String, Codable, CaseIterable, Identifiable {
    case hase, fuchs, igel, eule, schildkroete, reh

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .hase: return "🐰"
        case .fuchs: return "🦊"
        case .igel: return "🦔"
        case .eule: return "🦉"
        case .schildkroete: return "🐢"
        case .reh: return "🦌"
        }
    }

    var name: String {
        switch self {
        case .hase: return "Hase"
        case .fuchs: return "Fuchs"
        case .igel: return "Igel"
        case .eule: return "Eule"
        case .schildkroete: return "Schildkröte"
        case .reh: return "Reh"
        }
    }
}

struct SoundSettings: Codable, Equatable {
    var voiceOn: Bool = true
    var voiceVolume: Double = 1.0
    var effectsOn: Bool = true
    var effectsVolume: Double = 0.35
    var animalOn: Bool = true
    var animalVolume: Double = 0.9
    var musicOn: Bool = false
    var musicVolume: Double = 0.25
    /// Gemeinsamer Ton-Schalter: schaltet alles stumm, ohne die Einzeleinstellungen zu verändern.
    var masterMuted: Bool = false
    var speechRate: Double = 0.85

    var voiceAudible: Bool { !masterMuted && voiceOn }
    var effectsAudible: Bool { !masterMuted && effectsOn }
    var animalAudible: Bool { !masterMuted && animalOn }
    var musicAudible: Bool { !masterMuted && musicOn }
}

struct GameOptions: Codable, Equatable {
    var countingModes: Set<String> = ["howMany", "giveMe"]
    var sortingFeatures: Set<String> = ["color", "shape", "size"]
    var natureRelations: Set<String> = ["food", "habitat", "plantPart"]
    var atelierModes: Set<String> = ["paths", "free"]
    var mathOperations: Set<String> = ["plus", "minus"]
    var calmMemory: Bool = false
    var snakeSwipe: Bool = true
    var animalPictureModeAllowed: Bool = true

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = GameOptions()
        countingModes = (try? c.decode(Set<String>.self, forKey: .countingModes)) ?? d.countingModes
        sortingFeatures = (try? c.decode(Set<String>.self, forKey: .sortingFeatures)) ?? d.sortingFeatures
        natureRelations = (try? c.decode(Set<String>.self, forKey: .natureRelations)) ?? d.natureRelations
        atelierModes = (try? c.decode(Set<String>.self, forKey: .atelierModes)) ?? d.atelierModes
        mathOperations = (try? c.decode(Set<String>.self, forKey: .mathOperations)) ?? d.mathOperations
        calmMemory = (try? c.decode(Bool.self, forKey: .calmMemory)) ?? d.calmMemory
        snakeSwipe = (try? c.decode(Bool.self, forKey: .snakeSwipe)) ?? d.snakeSwipe
        animalPictureModeAllowed = (try? c.decode(Bool.self, forKey: .animalPictureModeAllowed)) ?? d.animalPictureModeAllowed
    }
}

/// Ein Eintrag in der Elternübersicht.
struct ActivityEntry: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var game: GameID
    var difficulty: Difficulty?
    var text: String
    var stats: HelpStats
}

/// Getrennte Erfassung der Hilfearten.
struct HelpStats: Codable, Equatable {
    var instructionRepeats: Int = 0
    var hints: Int = 0
    var demonstrations: Int = 0
    var solvedTogether: Int = 0
    var silentMode: Bool = false

    var summary: String {
        var parts: [String] = []
        if instructionRepeats > 0 { parts.append("\(instructionRepeats)× Anweisung nochmals gehört") }
        if hints > 0 { parts.append("\(hints)× Hinweis") }
        if demonstrations > 0 { parts.append("\(demonstrations)× Schritt vorgezeigt") }
        if solvedTogether > 0 { parts.append("\(solvedTogether)× gemeinsam gelöst") }
        if silentMode { parts.append("ohne Ton gespielt") }
        return parts.isEmpty ? "Ohne Hilfe" : parts.joined(separator: ", ")
    }
}

// MARK: - Garten

struct GardenData: Codable, Equatable {
    var inventory: [String] = GardenCatalog.starterItems
    var placed: [PlacedDecoration] = []
    var pendingRewards: [PendingReward] = []
    var rewardedRounds: Set<String> = []
    var undoStack: [GardenUndo] = []
}

struct PlacedDecoration: Codable, Equatable, Identifiable {
    var id = UUID()
    var item: String
    var x: Double
    var y: Double
}

struct PendingReward: Codable, Equatable, Identifiable {
    var id: String // Runden-ID
    var game: GameID
    var options: [String]
}

enum GardenUndo: Codable, Equatable {
    case placed(UUID)
    case moved(UUID, Double, Double)
    case removed(PlacedDecoration)
}

// MARK: - Gespeicherter Spielstand

/// Hülle für den Stand eines laufenden Spiels: Rundenfortschritt und spielspezifische Daten.
struct SavedGame: Codable {
    var roundID: String
    var difficulty: Difficulty
    var tasksDone: Int
    var stats: HelpStats
    var payload: Data
    /// Aufgabe gelöst, «Weiter» noch nicht gewählt.
    var awaitingNext: Bool?
}
