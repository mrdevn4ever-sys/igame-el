import SwiftUI
import Combine

enum SoundAnimal: String, Codable, CaseIterable {
    case kuh, schaf, hahn, hund, katze, frosch, schwein, esel
    case pferd, ziege, ente, gans, eule, kuckuck, biene, wolf

    var emoji: String {
        switch self {
        case .kuh: return "🐄"
        case .schaf: return "🐑"
        case .hahn: return "🐓"
        case .hund: return "🐕"
        case .katze: return "🐈"
        case .frosch: return "🐸"
        case .schwein: return "🐖"
        case .esel: return "🫏"
        case .pferd: return "🐎"
        case .ziege: return "🐐"
        case .ente: return "🦆"
        case .gans: return "🪿"
        case .eule: return "🦉"
        case .kuckuck: return "🐦"
        case .biene: return "🐝"
        case .wolf: return "🐺"
        }
    }

    var name: String {
        switch self {
        case .kuh: return "Kuh"
        case .schaf: return "Schaf"
        case .hahn: return "Hahn"
        case .hund: return "Hund"
        case .katze: return "Katze"
        case .frosch: return "Frosch"
        case .schwein: return "Schwein"
        case .esel: return "Esel"
        case .pferd: return "Pferd"
        case .ziege: return "Ziege"
        case .ente: return "Ente"
        case .gans: return "Gans"
        case .eule: return "Eule"
        case .kuckuck: return "Kuckuck"
        case .biene: return "Biene"
        case .wolf: return "Wolf"
        }
    }

    var article: String {
        switch self {
        case .kuh, .katze, .ziege, .ente, .gans, .eule, .biene: return "die"
        case .schaf, .schwein, .pferd: return "das"
        default: return "der"
        }
    }

    /// Nachgesprochenes Geräusch, falls keine Aufnahme mitgeliefert ist.
    var imitation: String {
        switch self {
        case .kuh: return "Muuuuh!"
        case .schaf: return "Mäh, mäh!"
        case .hahn: return "Kikeriki!"
        case .hund: return "Wau, wau!"
        case .katze: return "Miau!"
        case .frosch: return "Quak, quak!"
        case .schwein: return "Grunz, grunz!"
        case .esel: return "I-aah, i-aah!"
        case .pferd: return "Hü-hü-hüüü!"
        case .ziege: return "Meck, meck!"
        case .ente: return "Nak, nak, nak!"
        case .gans: return "Schnatter, schnatter!"
        case .eule: return "Huhu, huhu!"
        case .kuckuck: return "Kuckuck, kuckuck!"
        case .biene: return "Summ, summ, summ!"
        case .wolf: return "Auuuuh!"
        }
    }

    var pitch: Float {
        switch self {
        case .kuh: return 0.6
        case .schaf: return 1.4
        case .hahn: return 1.6
        case .hund: return 0.9
        case .katze: return 1.7
        case .frosch: return 0.75
        case .schwein: return 0.65
        case .esel: return 1.0
        case .pferd: return 1.2
        case .ziege: return 1.5
        case .ente: return 1.3
        case .gans: return 1.1
        case .eule: return 0.8
        case .kuckuck: return 1.3
        case .biene: return 1.0
        case .wolf: return 0.7
        }
    }

    /// Grobe Klanggruppe, um in «Entdecken» sehr unterschiedliche Tiere zu kombinieren.
    var soundGroup: Int {
        switch self {
        case .kuh, .schwein, .esel, .pferd: return 0
        case .schaf, .katze, .ziege: return 1
        case .hahn, .ente, .gans, .eule, .kuckuck: return 2
        case .hund, .wolf: return 3
        case .frosch: return 4
        case .biene: return 5
        }
    }

    /// Dateiname der Aufnahme (zwei Varianten je Tier, z. B. `tier_kuh_1.m4a`).
    func file(variant: Int) -> String { "tier_\(rawValue)_\(variant)" }
}

struct AnimalTask: Codable, Equatable {
    var animal: SoundAnimal
    var variant: Int
    var choices: [SoundAnimal]
}

struct AnimalSoundsState: Codable {
    var tasks: [AnimalTask]
    var index: Int
    var tried: [SoundAnimal]
    var pictureMode: Bool
}

/// Spiel 9: Tierstimmen erkennen.
struct AnimalSoundsGameView: View {
    let host: GameHost
    @State private var model: AnimalSoundsModel
    @Environment(AppModel.self) private var app

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: AnimalSoundsModel(host: host))
    }

    var body: some View {
        VStack(spacing: 28) {
            if let task = model.task {
                Spacer(minLength: 0)
                if model.pictureMode {
                    VStack(spacing: 8) {
                        Text("Bildermodus: Wessen Schatten ist das?")
                            .font(Theme.rounded(22, .semibold))
                            .foregroundStyle(Theme.darkGreen)
                        Pic("tier_\(task.animal.rawValue)", task.animal.emoji, size: 150)
                            .colorMultiply(.black)
                            .opacity(0.85)
                    }
                } else if !app.data.sound.animalAudible {
                    soundOffNotice
                } else {
                    listenButton
                }
                Spacer(minLength: 0)
                HStack(spacing: 26) {
                    ForEach(task.choices, id: \.self) { a in
                        AnswerCard(state: model.state(for: a), minSize: task.choices.count > 4 ? 118 : 150) {
                            model.choose(a)
                        } content: {
                            VStack(spacing: 4) {
                                Pic("tier_\(a.rawValue)", a.emoji, size: task.choices.count > 4 ? 66 : 90)
                                if model.showNames {
                                    Text(a.name).font(Theme.rounded(20, .semibold)).foregroundStyle(Theme.darkGreen)
                                }
                            }
                        }
                        .pulseHighlight(model.highlightAnswer && a == task.animal)
                        .accessibilityLabel(a.name)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(PlayfieldBackground(color: Theme.apricot.opacity(0.3)))
        .onAppear { model.start() }
        .onDisappear { model.stop() }
        .onReceive(NotificationCenter.default.publisher(for: .ellieAudioInterrupted)) { _ in
            model.interrupted()
        }
    }

    private var listenButton: some View {
        Button {
            model.play()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: model.playing ? "ear.fill" : "play.circle.fill")
                    .font(.system(size: 90, weight: .bold))
                    .symbolEffect(.pulse, isActive: model.playing)
                Text(model.playing ? "Hör genau hin …" : "Nochmals hören")
                    .font(Theme.rounded(24, .semibold))
            }
            .foregroundStyle(.white)
            .frame(width: 260, height: 220)
            .background(RoundedRectangle(cornerRadius: 40).fill(Theme.darkGreen))
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Tierstimme abspielen")
    }

    private var soundOffNotice: some View {
        VStack(spacing: 16) {
            Image(systemName: "speaker.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(Theme.darkGreen)
            Text("Für dieses Spiel brauchst du Ton.")
                .font(Theme.rounded(24, .semibold))
                .foregroundStyle(Theme.darkGreen)
            HStack(spacing: 18) {
                Button {
                    app.update {
                        $0.sound.masterMuted = false
                        $0.sound.animalOn = true
                    }
                    model.play()
                } label: {
                    Label("Ton einschalten", systemImage: "speaker.wave.2.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.success))
                if host.options.animalPictureModeAllowed {
                    Button {
                        model.enablePictureMode()
                    } label: {
                        Label("Bildermodus", systemImage: "photo.fill")
                    }
                    .buttonStyle(BigButtonStyle())
                }
            }
        }
    }
}

@MainActor
@Observable
final class AnimalSoundsModel {
    @ObservationIgnored let host: GameHost
    var tasks: [AnimalTask] = []
    var index = 0
    var tried: [SoundAnimal] = []
    var solved = false
    var playing = false
    var pictureMode = false
    var showNames = false
    var highlightAnswer = false
    @ObservationIgnored private var playTask: Task<Void, Never>?
    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var task: AnimalTask? { tasks[safe: index] }

    var choiceCount: Int { LevelCatalog.animals(host.level).choices }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Tierstimmen erkannt.") }
            let names = self.tasks.map(\.animal.name)
            let mode = self.pictureMode ? "im Bildermodus (ohne Ton)" : "am Geräusch"
            return RoundSummary(text: "Vier Tiere \(mode) erkannt: \(names.joined(separator: ", ")).", practiced: names)
        }
        host.audio.setMusicSuspended(true)
        if let saved = host.takeRestoredPayload(AnimalSoundsState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            tried = saved.tried
            pictureMode = saved.pictureMode
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            // Nach einer Unterbrechung startet die Aufnahme erst nach einer bewussten Aktion.
            host.setInstruction(pictureMode ? "Welches Tier hat diesen Schatten?" : "Tippe auf den Knopf und hör genau hin.")
        } else {
            tasks = makeTasks()
            index = 0
            present()
        }
    }

    func stop() {
        playTask?.cancel()
        host.audio.stopAnimal()
        host.audio.setMusicSuspended(false)
    }

    private func makeTasks() -> [AnimalTask] {
        var animals = SoundAnimal.allCases.shuffled()
        var result: [AnimalTask] = []
        for _ in 0..<host.tasksPerRound {
            let target = animals.removeFirst()
            animals.append(target)
            var others = SoundAnimal.allCases.filter { $0 != target }.shuffled()
            let similar = LevelCatalog.animals(host.level).similar
            if host.level <= 2 {
                // Sehr unterschiedliche Geräusche kombinieren
                others = others.filter { $0.soundGroup != target.soundGroup }
            } else if similar {
                // Anspruchsvoller: ähnliche Klanggruppen bevorzugen
                others.sort { ($0.soundGroup == target.soundGroup ? 0 : 1) < ($1.soundGroup == target.soundGroup ? 0 : 1) }
            }
            let choices = ([target] + others.prefix(choiceCount - 1)).shuffled()
            result.append(AnimalTask(animal: target, variant: Int.random(in: 1...2), choices: choices))
        }
        return result
    }

    private func present() {
        tried = []
        solved = false
        highlightAnswer = false
        showNames = false
        save()
        if pictureMode {
            host.setInstruction("Welches Tier hat diesen Schatten?")
            return
        }
        host.setInstruction("Hör genau hin. Welches Tier ist das?", speak: false)
        guard host.app.data.sound.animalAudible else {
            host.audio.say("Für dieses Spiel brauchst du Ton.")
            return
        }
        playTask?.cancel()
        playTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.host.audio.sayAndWait("Hör genau hin. Welches Tier ist das?")
            guard !Task.isCancelled else { return }
            self.play()
        }
    }

    /// Erneutes Antippen startet die Aufnahme verständlich neu; nichts überlagert sich.
    func play() {
        guard let task, !pictureMode else { return }
        playTask?.cancel()
        playing = true
        playTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            await self.host.audio.playAnimal(file: task.animal.file(variant: task.variant), imitation: task.animal.imitation, pitch: task.animal.pitch)
            if !Task.isCancelled { self.playing = false }
        }
    }

    func interrupted() {
        playTask?.cancel()
        playing = false
    }

    func enablePictureMode() {
        pictureMode = true
        host.markSilentPlay()
        save()
        host.setInstruction("Welches Tier hat diesen Schatten?", speak: false)
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    private func save() {
        host.persist(AnimalSoundsState(tasks: tasks, index: index, tried: tried, pictureMode: pictureMode))
    }

    func state(for a: SoundAnimal) -> AnswerState {
        if solved && a == task?.animal { return .correct }
        if tried.contains(a) { return .tried }
        return .normal
    }

    func choose(_ a: SoundAnimal) {
        guard let task, !solved else { return }
        playTask?.cancel()
        host.audio.stopAnimal()
        playing = false
        if a == task.animal {
            solved = true
            host.taskSolved("Richtig, das war \(a.article) \(a.name).")
        } else {
            if !tried.contains(a) { tried.append(a) }
            save()
            host.wrong(pictureMode ? "Schau dir den Schatten nochmals an." : "Hör nochmals genau hin.")
        }
    }

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        if let task, !solved { choose(task.animal) }
    }

    private func help(_ level: Int) {
        guard let task else { return }
        switch level {
        case 1:
            showNames = true
            host.showBunny("Ich sage dir die Namen der Tiere.", speak: false)
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.host.audio.sayAndWait("Ich sage dir die Namen der Tiere.")
                for c in task.choices { self.host.audio.enqueue("\(c.article) \(c.name)") }
            }
        case 2:
            showNames = true
            if let wrong = task.choices.first(where: { $0 != task.animal && !tried.contains($0) }) {
                tried.append(wrong)
                save()
                host.showBunny("\(wrong.article.capitalizedFirst) \(wrong.name) ist es nicht.")
            } else {
                host.showBunny("Hör nochmals hin.")
            }
        default:
            highlightAnswer = true
            host.showBunny("Das war \(task.animal.article) \(task.animal.name). \(task.animal.imitation)")
        }
    }
}
