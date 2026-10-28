import SwiftUI

struct PatternMotif: Codable, Equatable, Hashable {
    var emoji: String
    var name: String
}

enum PatternCatalog {
    /// Zwölf Naturmotive, die sich auch in der Form deutlich unterscheiden.
    static let motifs: [PatternMotif] = [
        PatternMotif(emoji: "🍃", name: "Blatt"), PatternMotif(emoji: "🌼", name: "Blume"),
        PatternMotif(emoji: "🍄", name: "Pilz"), PatternMotif(emoji: "🌰", name: "Kastanie"),
        PatternMotif(emoji: "🐞", name: "Käfer"), PatternMotif(emoji: "🐌", name: "Schnecke"),
        PatternMotif(emoji: "🌲", name: "Tanne"), PatternMotif(emoji: "🍎", name: "Apfel"),
        PatternMotif(emoji: "🦋", name: "Schmetterling"), PatternMotif(emoji: "🐝", name: "Biene"),
        PatternMotif(emoji: "🪨", name: "Stein"), PatternMotif(emoji: "🍓", name: "Erdbeere")
    ]

    /// 36 geprüfte Musteraufgaben, zwölf pro Stufe.
    static func tasks(for difficulty: Difficulty) -> [PatternTask] {
        var rng = SeededGenerator(seed: 4000 + UInt64(Difficulty.allCases.firstIndex(of: difficulty)!))
        var result: [PatternTask] = []
        while result.count < 12 {
            let picked = Array(motifs.shuffled(using: &rng).prefix(3))
            let unit: [Int]
            switch difficulty {
            case .entdecken: unit = [0, 1]
            case .ueben: unit = result.count % 2 == 0 ? [0, 0, 1] : [0, 1, 1]
            case .knobeln: unit = [0, 1, 2]
            }
            let reps = 3
            var seq: [Int] = []
            for _ in 0..<reps { seq.append(contentsOf: unit) }
            // Lücke nach mindestens zwei vollständigen Wiederholungen.
            let gap: Int
            if difficulty == .knobeln && result.count % 3 != 0 {
                gap = unit.count * 2 + (result.count % 3) - 1 // innerhalb des letzten Blocks
            } else {
                gap = unit.count * 2 + (difficulty == .entdecken ? 1 : unit.count - 1)
            }
            let shown = Array(seq.prefix(max(gap + 1, difficulty == .knobeln ? seq.count : gap + 1)))
            let sequence = shown.map { picked[$0] }
            let answer = sequence[gap]
            let distinctInPattern = Array(Set(unit)).sorted().map { picked[$0] }
            var options = distinctInPattern
            let optionCount = difficulty == .entdecken ? 2 : 3
            if options.count < optionCount {
                let extra = motifs.filter { !options.contains($0) }.shuffled(using: &rng)
                options.append(contentsOf: extra.prefix(optionCount - options.count))
            }
            options = Array(options.prefix(optionCount))
            if !options.contains(answer) { options[0] = answer }
            options.shuffle(using: &rng)
            let task = PatternTask(sequence: sequence, gap: gap, options: options, unitLength: unit.count)
            if !result.contains(task) { result.append(task) }
        }
        return result
    }
}

struct PatternTask: Codable, Equatable {
    var sequence: [PatternMotif]
    var gap: Int
    var options: [PatternMotif]
    var unitLength: Int

    var answer: PatternMotif { sequence[gap] }

    var label: String {
        switch unitLength {
        case 2: return "ABAB"
        case 3 where sequence[0] == sequence[1]: return "AAB"
        case 3 where sequence[1] == sequence[2]: return "ABB"
        default: return "ABC"
        }
    }
}

struct PatternState: Codable {
    var tasks: [PatternTask]
    var index: Int
    var tried: [String]
}

/// Spiel 8: Musterzug.
struct PatternGameView: View {
    let host: GameHost
    @State private var model: PatternModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: PatternModel(host: host))
    }

    var body: some View {
        VStack(spacing: 30) {
            if let task = model.task {
                GeometryReader { geo in
                    let count = task.sequence.count
                    let car = min((geo.size.width - 120) / CGFloat(count) - 8, 130)
                    VStack {
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(Array(task.sequence.enumerated()), id: \.offset) { i, motif in
                                trainCar(motif: motif, isGap: i == task.gap, index: i, task: task, size: car)
                            }
                            Text("🚂")
                                .font(.system(size: car * 0.9))
                                .scaleEffect(x: -1, y: 1)
                        }
                        .offset(x: model.trainOffset)
                        .animation(.easeInOut(duration: 1.2), value: model.trainOffset)
                        // Schienen
                        Rectangle()
                            .fill(Theme.darkGreen.opacity(0.5))
                            .frame(height: 6)
                            .overlay(
                                HStack(spacing: 22) {
                                    ForEach(0..<40, id: \.self) { _ in
                                        Rectangle().fill(Theme.darkGreen.opacity(0.35)).frame(width: 8, height: 18)
                                    }
                                }
                            )
                            .clipped()
                        Spacer()
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }
                .background(PlayfieldBackground(color: Theme.lilac.opacity(0.4)))

                HStack(spacing: 30) {
                    ForEach(task.options, id: \.self) { m in
                        AnswerCard(state: model.state(for: m), minSize: 130) {
                            model.choose(m)
                        } content: {
                            Text(m.emoji).font(.system(size: 76))
                        }
                        .pulseHighlight(model.highlightAnswer && m == task.answer)
                        .accessibilityLabel(m.name)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func trainCar(motif: PatternMotif, isGap: Bool, index: Int, task: PatternTask, size: CGFloat) -> some View {
        let group = index / task.unitLength
        let highlighted = model.highlightGroup == group
        return ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(highlighted ? Theme.highlight.opacity(0.6) : (group % 2 == 0 ? Color.white : Theme.cream))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.darkGreen.opacity(0.5), lineWidth: 3))
            if isGap && !model.solved {
                Text("?")
                    .font(Theme.rounded(size * 0.5, .heavy))
                    .foregroundStyle(Theme.darkGreen)
            } else {
                Text(motif.emoji).font(.system(size: size * 0.55))
            }
        }
        .frame(width: size, height: size)
        .overlay(alignment: .bottom) {
            HStack(spacing: size * 0.3) {
                Circle().fill(Theme.darkGreen).frame(width: size * 0.18, height: size * 0.18)
                Circle().fill(Theme.darkGreen).frame(width: size * 0.18, height: size * 0.18)
            }
            .offset(y: size * 0.1)
        }
        .animation(.easeInOut(duration: 0.3), value: highlighted)
    }
}

@MainActor
@Observable
final class PatternModel {
    @ObservationIgnored let host: GameHost
    var tasks: [PatternTask] = []
    var index = 0
    var tried: [String] = []
    var solved = false
    var highlightGroup: Int?
    var highlightAnswer = false
    var trainOffset: CGFloat = 0
    @ObservationIgnored private var started = false
    @ObservationIgnored private var helpTask: Task<Void, Never>?

    init(host: GameHost) { self.host = host }

    var task: PatternTask? { tasks[safe: index] }

    func start() {
        guard !started else { return }
        started = true
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Muster fortgesetzt.") }
            let kinds = Array(Set(self.tasks.map(\.label))).sorted()
            return RoundSummary(text: "Vier Muster (\(kinds.joined(separator: ", "))) fortgesetzt.", practiced: kinds.map { "Muster \($0)" })
        }
        if let saved = host.takeRestoredPayload(PatternState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            tried = saved.tried
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            instruct()
        } else {
            tasks = Array(PatternCatalog.tasks(for: host.difficulty).shuffled().prefix(host.tasksPerRound))
            index = 0
            present()
        }
    }

    func stop() { helpTask?.cancel() }

    private func present() {
        tried = []
        solved = false
        highlightGroup = nil
        highlightAnswer = false
        trainOffset = 0
        save()
        instruct()
    }

    private func instruct() {
        host.setInstruction("Was kommt in die Lücke? Schau, was sich wiederholt.")
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    private func save() {
        host.persist(PatternState(tasks: tasks, index: index, tried: tried))
    }

    func state(for m: PatternMotif) -> AnswerState {
        if solved && m == task?.answer { return .correct }
        if tried.contains(m.name) { return .tried }
        return .normal
    }

    func choose(_ m: PatternMotif) {
        guard let task, !solved else { return }
        if m == task.answer {
            solved = true
            highlightGroup = nil
            helpTask?.cancel()
            trainOffset = 40
            host.taskSolved("Genau, \(article(m)) \(m.name). Der Zug fährt weiter.")
        } else {
            if !tried.contains(m.name) { tried.append(m.name) }
            save()
            host.wrong("Schauen wir es gemeinsam an.")
            showGroups(speak: true)
        }
    }

    private func article(_ m: PatternMotif) -> String {
        switch m.name {
        case "Blume", "Kastanie", "Schnecke", "Tanne", "Biene", "Erdbeere": return "die"
        case "Blatt": return "das"
        default: return "der"
        }
    }

    /// Hebt die wiederkehrenden Gruppen nacheinander hervor und nennt die Folge.
    private func showGroups(speak: Bool) {
        guard let task else { return }
        helpTask?.cancel()
        helpTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.host.audio.waitUntilQuiet()
            let groups = Int(ceil(Double(task.sequence.count) / Double(task.unitLength)))
            for g in 0..<groups {
                guard !Task.isCancelled else { return }
                self.highlightGroup = g
                if speak {
                    let names = task.sequence.enumerated()
                        .filter { $0.offset / task.unitLength == g && $0.offset != task.gap }
                        .map(\.element.name)
                    self.host.audio.enqueue(names.joined(separator: ", "))
                }
                try? await Task.sleep(nanoseconds: 1_300_000_000)
            }
            self.highlightGroup = nil
        }
    }

    private func help(_ level: Int) {
        guard let task else { return }
        switch level {
        case 1:
            host.showBunny("Diese Gruppen wiederholen sich.", speak: false)
            showGroups(speak: false)
        case 2:
            host.showBunny("Hör die Folge.", speak: false)
            showGroups(speak: true)
        default:
            highlightAnswer = true
            host.showBunny("In die Lücke gehört \(article(task.answer)) \(task.answer.name).")
        }
    }
}
