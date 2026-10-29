import SwiftUI
import UIKit

/// Start-Argumente für automatische Screenshots und Durchläufe im Simulator (nur Debug-Builds).
///
/// Beispiele:
///   -demo -screen hub -page 1
///   -demo -screen game -game memory -difficulty ueben -autoplay
///   -demo -screen setup -step 2
enum DemoMode {
    static let arguments = ProcessInfo.processInfo.arguments

    static var isActive: Bool {
        #if DEBUG
        return arguments.contains("-demo")
        #else
        return false
        #endif
    }

    static func value(_ key: String) -> String? {
        guard isActive, let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    static func flag(_ key: String) -> Bool { isActive && arguments.contains(key) }

    static var autoplay: Bool { flag("-autoplay") }

    /// Vorbereiteter Zustand mit ein paar Inhalten für aussagekräftige Screenshots.
    static func makeData() -> AppData {
        var d = AppData()
        d.setupComplete = value("-screen") != "setup"
        d.setupStep = Int(value("-step") ?? "0") ?? 0
        d.tutorialDone = true
        d.parentCodeHash = CodeHasher.hash("123456")
        d.sound.masterMuted = true
        d.profile = Profile(name: "Ellie", avatar: .fuchs)
        if let raw = value("-difficulty"), let diff = Difficulty(rawValue: raw) {
            for g in GameID.allCases { d.difficulties[g.rawValue] = diff }
        }
        if let raw = value("-level"), let l = Int(raw) {
            for g in GameID.allCases {
                d.skills[g.rawValue] = SkillState(level: min(max(l, 1), LevelCatalog.maxLevel(g)))
            }
        }
        d.lastGame = GameID.memory.rawValue
        d.garden.placed = [
            PlacedDecoration(item: "🌳", x: 0.15, y: 0.45), PlacedDecoration(item: "🌷", x: 0.3, y: 0.7),
            PlacedDecoration(item: "🏡", x: 0.55, y: 0.4), PlacedDecoration(item: "🦋", x: 0.7, y: 0.25),
            PlacedDecoration(item: "🌻", x: 0.45, y: 0.75)
        ]
        d.garden.inventory = Array(d.garden.inventory.dropFirst(3))
        d.garden.pendingRewards = [PendingReward(id: "demo", game: .memory, options: ["🦔", "🐸", "🌈"])]
        let stats = HelpStats(instructionRepeats: 2, hints: 1, demonstrations: 0, solvedTogether: 0)
        d.activities = [
            ActivityEntry(date: Date(), game: .tracing, difficulty: .entdecken, text: "Zahlen 3, 1, 5, 2 nachgezeichnet.", stats: stats),
            ActivityEntry(date: Date().addingTimeInterval(-3600), game: .memory, difficulty: .ueben, text: "Memory mit sechs Paaren (Waldtiere) gelöst.", stats: HelpStats())
        ]
        d.roundsCompleted = [GameID.tracing.rawValue: 3, GameID.memory.rawValue: 2]
        d.practicedItems = [GameID.tracing.rawValue: ["Ziffer 1", "Ziffer 2", "Ziffer 3"]]
        return d
    }

    static var startScreen: Screen {
        switch value("-screen") ?? "hub" {
        case "setup": return .setup
        case "tutorial": return .tutorial
        case "game": return .game(GameID(rawValue: value("-game") ?? "") ?? .tracing)
        case "garden": return .garden
        case "gallery": return .gallery
        case "parents": return .parents
        default: return .hub
        }
    }

    /// Dreht das Fenster ins Querformat (Standardnutzung auf dem iPad).
    @MainActor
    static func applyOrientation() {
        guard isActive, !flag("-portrait") else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { _ in }
    }
}
