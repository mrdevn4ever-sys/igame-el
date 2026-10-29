import SwiftUI
import Observation

enum Screen: Equatable {
    case setup
    case tutorial
    case hub
    case game(GameID)
    case garden
    case gallery
    case parents
}

@MainActor
@Observable
final class AppModel {
    private(set) var data: AppData
    private(set) var gallery: [Artwork]
    var screen: Screen
    var hubPage: Int = 0
    var showParentGate = false
    /// Bild aus der Galerie, das im Atelier weiterbearbeitet werden soll.
    var editArtworkID: UUID?
    var breakHintVisible = false
    /// Spiel, aus dem der Garten geöffnet wurde (für den Rückweg).
    var playStart = Date()

    @ObservationIgnored let audio = AudioManager.shared
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init() {
        let loaded = DemoMode.isActive ? DemoMode.makeData() : (Persistence.loadData() ?? AppData())
        data = loaded
        gallery = Persistence.loadGallery()
        if !loaded.setupComplete {
            screen = .setup
        } else if !loaded.tutorialDone {
            screen = .tutorial
        } else {
            screen = .hub
        }
        if DemoMode.isActive {
            if loaded.setupComplete { screen = DemoMode.startScreen }
            hubPage = Int(DemoMode.value("-page") ?? "0") ?? 0
            if DemoMode.value("-screen") == "tutorial" { screen = .tutorial }
        }
        audio.apply(loaded.sound)
    }

    // MARK: - Ändern und Speichern

    func update(_ change: (inout AppData) -> Void) {
        change(&data)
        audio.apply(data.sound)
        scheduleSave()
    }

    /// Binding auf einen Teil der Daten, das automatisch speichert.
    func binding<T>(_ keyPath: WritableKeyPath<AppData, T>) -> Binding<T> {
        Binding(
            get: { self.data[keyPath: keyPath] },
            set: { newValue in self.update { $0[keyPath: keyPath] = newValue } }
        )
    }

    private func scheduleSave() {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard let self, !Task.isCancelled else { return }
            Persistence.write(self.data)
        }
    }

    func saveNow() {
        saveTask?.cancel()
        Persistence.write(data)
        Persistence.flush()
    }

    // MARK: - Navigation

    func open(_ game: GameID) {
        update { $0.lastGame = game.rawValue }
        audio.stopAll()
        withAnimation(.easeInOut(duration: 0.25)) { screen = .game(game) }
    }

    func goHome() {
        audio.stopAll()
        withAnimation(.easeInOut(duration: 0.25)) {
            if case .game(let g) = screen { hubPage = g.page }
            screen = .hub
        }
        checkBreakReminder()
    }

    func checkBreakReminder() {
        let minutes = data.breakReminderMinutes
        guard minutes > 0 else { return }
        if Date().timeIntervalSince(playStart) >= Double(minutes) * 60 {
            breakHintVisible = true
        }
    }

    func dismissBreakHint() {
        breakHintVisible = false
        playStart = Date()
    }

    var visibleGames: [GameID] {
        GameID.allCases.filter { data.isVisible($0) }
    }

    var continueGame: GameID? {
        guard let raw = data.lastGame, let g = GameID(rawValue: raw), data.isVisible(g) else { return nil }
        return g
    }

    // MARK: - Spielstände

    func savedGame(for game: GameID) -> SavedGame? {
        guard let raw = data.saves[game.rawValue] else { return nil }
        return try? Persistence.decoder.decode(SavedGame.self, from: raw)
    }

    func storeGame(_ saved: SavedGame, for game: GameID) {
        guard let raw = try? Persistence.encoder.encode(saved) else { return }
        update { $0.saves[game.rawValue] = raw }
    }

    func clearGame(_ game: GameID) {
        update { $0.saves[game.rawValue] = nil }
    }

    // MARK: - Fortschritt

    func logRound(game: GameID, difficulty: Difficulty?, text: String, stats: HelpStats, roundID: String, practiced: [String]) {
        update { d in
            d.activities.insert(ActivityEntry(date: Date(), game: game, difficulty: difficulty, text: text, stats: stats), at: 0)
            if d.activities.count > 400 { d.activities.removeLast(d.activities.count - 400) }
            d.roundsCompleted[game.rawValue, default: 0] += 1
            var items = d.practicedItems[game.rawValue] ?? []
            for p in practiced where !items.contains(p) { items.append(p) }
            d.practicedItems[game.rawValue] = items
            // Höchstens eine Gartenvergabe pro Runde.
            if !d.garden.rewardedRounds.contains(roundID),
               !d.garden.pendingRewards.contains(where: { $0.id == roundID }) {
                let options = GardenCatalog.rewardOptions(roundID: roundID, owned: d.garden.inventory + d.garden.placed.map(\.item))
                d.garden.pendingRewards.append(PendingReward(id: roundID, game: game, options: options))
            }
        }
    }

    func pendingReward(for roundID: String) -> PendingReward? {
        data.garden.pendingRewards.first { $0.id == roundID }
    }

    func claimReward(_ reward: PendingReward, item: String) {
        update { d in
            guard let idx = d.garden.pendingRewards.firstIndex(where: { $0.id == reward.id }) else { return }
            d.garden.pendingRewards.remove(at: idx)
            d.garden.rewardedRounds.insert(reward.id)
            d.garden.inventory.append(item)
        }
    }

    // MARK: - Galerie

    func saveArtwork(_ art: Artwork) {
        if let idx = gallery.firstIndex(where: { $0.id == art.id }) {
            gallery[idx] = art
        } else {
            gallery.insert(art, at: 0)
        }
        Persistence.write(gallery)
    }

    func deleteArtwork(_ id: UUID) {
        gallery.removeAll { $0.id == id }
        Persistence.write(gallery)
    }

    // MARK: - Sicherung

    func makeBackup() -> BackupFile {
        BackupFile(app: data, gallery: gallery)
    }

    func restore(from backup: BackupFile) {
        data = backup.app
        gallery = backup.gallery
        audio.apply(data.sound)
        Persistence.write(data)
        Persistence.write(gallery)
    }

    func resetEverything() {
        data = AppData()
        gallery = []
        audio.apply(data.sound)
        Persistence.write(data)
        Persistence.write(gallery)
        screen = .setup
    }
}
