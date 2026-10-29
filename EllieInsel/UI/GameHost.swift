import SwiftUI
import Observation

struct RoundSummary {
    var text: String
    var practiced: [String] = []
}

/// Gemeinsamer Rahmen eines Spiels: Anweisungen, Hilfestufen, Rundenfortschritt und Speichern.
@MainActor
@Observable
final class GameHost {
    let game: GameID
    @ObservationIgnored let app: AppModel

    private(set) var difficulty: Difficulty
    private(set) var roundID: String
    private(set) var tasksDone: Int
    private(set) var stats: HelpStats
    private(set) var instruction: String = ""
    private(set) var helpLevel = 0
    private(set) var awaitingNext = false
    private(set) var roundComplete = false
    private(set) var completionText = ""
    var bunnyMessage: String?
    var feedback: String?
    /// Erhöht sich bei jedem Rundenstart (für `.id` in Spielansichten).
    private(set) var roundToken = 0

    var tasksPerRound: Int { game.tasksPerRound }

    @ObservationIgnored private var restored: SavedGame?
    @ObservationIgnored private var lastPayload: Data?
    @ObservationIgnored private var bunnyTask: Task<Void, Never>?
    @ObservationIgnored private var completeTask: Task<Void, Never>?

    // Von den Spielen gesetzt
    @ObservationIgnored var helpHandler: ((Int) -> Void)?
    @ObservationIgnored var nextTaskHandler: (() -> Void)?
    @ObservationIgnored var newRoundHandler: (() -> Void)?
    @ObservationIgnored var summaryProvider: (() -> RoundSummary)?
    /// Löst den nächsten Schritt automatisch (nur für automatische Durchläufe im Simulator).
    @ObservationIgnored var debugSolveHandler: (() -> Void)?

    init(game: GameID, app: AppModel) {
        self.game = game
        self.app = app
        let saved = app.savedGame(for: game)
        restored = saved
        difficulty = saved?.difficulty ?? app.data.difficulty(for: game)
        roundID = saved?.roundID ?? UUID().uuidString
        tasksDone = saved?.tasksDone ?? 0
        stats = saved?.stats ?? HelpStats()
        awaitingNext = saved?.awaitingNext ?? false
        lastPayload = saved?.payload
    }

    var audio: AudioManager { app.audio }
    var options: GameOptions { app.data.options }
    var soundOn: Bool { app.data.sound.voiceAudible }

    // MARK: - Wiederaufnahme

    /// Liefert den gespeicherten Spielzustand genau einmal.
    func takeRestoredPayload<T: Decodable>(_ type: T.Type) -> T? {
        guard let saved = restored else { return nil }
        restored = nil
        return try? Persistence.decoder.decode(T.self, from: saved.payload)
    }

    func persist<T: Encodable>(_ payload: T) {
        guard !roundComplete else { return }
        lastPayload = try? Persistence.encoder.encode(payload)
        writeSave()
    }

    private func writeSave() {
        guard let lastPayload, !roundComplete else { return }
        let saved = SavedGame(
            roundID: roundID,
            difficulty: difficulty,
            tasksDone: tasksDone,
            stats: stats,
            payload: lastPayload,
            awaitingNext: awaitingNext
        )
        app.storeGame(saved, for: game)
    }

    // MARK: - Sprache

    func say(_ text: String) {
        audio.say(text)
    }

    func setInstruction(_ text: String, speak: Bool = true) {
        instruction = text
        if speak { audio.say(text) }
    }

    func repeatInstruction() {
        stats.instructionRepeats += 1
        audio.say(instruction)
        writeSave()
    }

    func showBunny(_ text: String, speak: Bool = true, seconds: Double = 4) {
        bunnyMessage = text
        if speak { audio.say(text) }
        bunnyTask?.cancel()
        bunnyTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation { self?.bunnyMessage = nil }
        }
    }

    // MARK: - Hilfe

    /// Hilfe steigert sich: 1 Hinweis, 2 nächster Schritt vorgezeigt, 3 gemeinsame Lösung.
    func requestHelp() {
        guard !awaitingNext, !roundComplete else { return }
        helpLevel = min(helpLevel + 1, 3)
        switch helpLevel {
        case 1: stats.hints += 1
        case 2: stats.demonstrations += 1
        default: stats.solvedTogether += 1
        }
        helpHandler?(helpLevel)
        writeSave()
    }

    func markSilentPlay() {
        stats.silentMode = true
    }

    // MARK: - Rückmeldung

    func wrong(_ text: String = "Schauen wir es gemeinsam an.") {
        audio.effect(.gentle)
        showBunny(text)
    }

    /// Eine Aufgabe ist gelöst.
    /// - Parameter needsNext: «Weiter»-Knopf zeigen (bei fortlaufenden Spielen wie Snake nicht).
    func taskSolved(_ text: String, needsNext: Bool = true) {
        guard !roundComplete else { return }
        tasksDone += 1
        helpLevel = 0
        audio.effect(.success)
        if !text.isEmpty { audio.say(text) }
        feedback = text
        if tasksDone >= tasksPerRound {
            awaitingNext = false
            completeTask?.cancel()
            completeTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                guard !Task.isCancelled else { return }
                self?.finishRound()
            }
        } else {
            awaitingNext = needsNext
        }
        writeSave()
    }

    func next() {
        guard awaitingNext else { return }
        awaitingNext = false
        feedback = nil
        helpLevel = 0
        nextTaskHandler?()
    }

    /// Setzt die Hilfestufe für eine neue Aufgabe zurück (bei Spielen ohne «Weiter»).
    func resetHelp() {
        helpLevel = 0
    }

    /// Nach dem Wiederherstellen: eine bereits gelöste Aufgabe wartet noch auf «Weiter».
    func resumeIfNeeded() {
        if tasksDone >= tasksPerRound {
            finishRound()
        }
    }

    func finishRound() {
        guard !roundComplete else { return }
        let summary = summaryProvider?() ?? RoundSummary(text: "\(game.title) gespielt.")
        completionText = summary.text
        roundComplete = true
        awaitingNext = false
        feedback = nil
        audio.effect(.complete)
        audio.say("Geschafft! Das hast du toll gemacht.")
        app.logRound(
            game: game,
            difficulty: game == .atelier && summary.practiced.contains("frei") ? nil : difficulty,
            text: summary.text,
            stats: stats,
            roundID: roundID,
            practiced: summary.practiced
        )
        app.clearGame(game)
    }

    /// Neue Runde (nach «Nochmals» oder bestätigtem Neustart). Übernimmt eine geänderte Schwierigkeit.
    func startNewRound() {
        completeTask?.cancel()
        roundID = UUID().uuidString
        tasksDone = 0
        stats = HelpStats()
        helpLevel = 0
        awaitingNext = false
        roundComplete = false
        completionText = ""
        feedback = nil
        bunnyMessage = nil
        restored = nil
        lastPayload = nil
        difficulty = app.data.difficulty(for: game)
        roundToken += 1
        app.clearGame(game)
        newRoundHandler?()
    }

    var pendingReward: PendingReward? {
        app.pendingReward(for: roundID)
    }
}
