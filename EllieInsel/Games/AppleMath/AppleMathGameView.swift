import SwiftUI

struct MathTask: Codable, Equatable {
    enum Op: String, Codable { case plus, minus }
    var a: Int
    var b: Int
    var op: Op
    var motif: CountMotif
    var story: Bool
    var options: [Int]

    var answer: Int { op == .plus ? a + b : a - b }

    var question: String {
        if story { return storyText }
        switch op {
        case .plus:
            return "\(motif.phrase(a).capitalizedFirst) und \(motif.phrase(b)). Wie viele sind es zusammen?"
        case .minus:
            let verb = b == 1 ? "wird" : "werden"
            return "\(motif.phrase(a).capitalizedFirst). \(motif.phrase(b).capitalizedFirst) \(verb) weggenommen. Wie viele bleiben?"
        }
    }

    private var storyText: String {
        let A = motif.phrase(a).capitalizedFirst
        let B = motif.phrase(b).capitalizedFirst
        switch (op, motif.isAnimal) {
        case (.plus, true):
            return "\(A) \(a == 1 ? "sitzt" : "sitzen") auf dem Blatt. \(B) \(b == 1 ? "fliegt" : "fliegen") dazu. Wie viele sind es jetzt?"
        case (.minus, true):
            return "\(A) \(a == 1 ? "sitzt" : "sitzen") auf dem Blatt. \(B) \(b == 1 ? "fliegt" : "fliegen") weg. Wie viele bleiben?"
        case (.plus, false):
            return "\(A) \(a == 1 ? "liegt" : "liegen") im Korb. Der Hase bringt \(motif.accusative(b)) dazu. Wie viele sind es jetzt?"
        case (.minus, false):
            return "\(A) \(a == 1 ? "liegt" : "liegen") im Korb. Der Hase nimmt \(motif.accusative(b)) heraus. Wie viele bleiben?"
        }
    }

    var practiceLabel: String {
        op == .plus ? "\(a) + \(b) = \(answer)" : "\(a) − \(b) = \(answer)"
    }
}

enum MathTaskFactory {
    /// 24 redaktionell geprüfte Beispielaufgaben (Einträge: a, b, Operation, Motiv, Stufe).
    static let curated: [(Int, Int, MathTask.Op, CountMotif, Difficulty)] = [
        (2, 1, .plus, .apfel, .entdecken), (1, 1, .plus, .karotte, .entdecken), (2, 2, .plus, .kaefer, .entdecken),
        (3, 1, .plus, .karotte, .entdecken), (1, 3, .plus, .apfel, .entdecken), (3, 2, .plus, .apfel, .entdecken),
        (4, 1, .plus, .kaefer, .entdecken), (2, 3, .plus, .karotte, .entdecken),
        (4, 3, .plus, .apfel, .ueben), (5, 2, .plus, .karotte, .ueben), (6, 3, .plus, .kaefer, .ueben),
        (5, 5, .plus, .karotte, .ueben), (5, 2, .minus, .apfel, .ueben), (7, 3, .minus, .apfel, .ueben),
        (6, 1, .minus, .kaefer, .ueben), (8, 4, .minus, .karotte, .ueben),
        (3, 4, .plus, .kaefer, .knobeln), (6, 2, .minus, .kaefer, .knobeln), (4, 4, .plus, .apfel, .knobeln),
        (9, 3, .minus, .apfel, .knobeln), (7, 2, .plus, .karotte, .knobeln), (10, 4, .minus, .karotte, .knobeln),
        (5, 3, .plus, .apfel, .knobeln), (8, 5, .minus, .kaefer, .knobeln)
    ]

    static func round(difficulty: Difficulty, operations: Set<String>, count: Int) -> [MathTask] {
        var tasks: [MathTask] = []
        let allowPlus = operations.contains("plus") || difficulty == .entdecken
        let allowMinus = operations.contains("minus") && difficulty != .entdecken
        var pool = curated.filter { $0.4 == difficulty }.filter {
            ($0.2 == .plus && allowPlus) || ($0.2 == .minus && allowMinus)
        }.shuffled()
        var lastAnswerIndex = -1
        while tasks.count < count {
            let base: (Int, Int, MathTask.Op, CountMotif)
            if tasks.count < 2, let c = pool.popLast() {
                base = (c.0, c.1, c.2, c.3)
            } else {
                base = generate(difficulty: difficulty, allowPlus: allowPlus, allowMinus: allowMinus)
            }
            let candidate = makeTask(a: base.0, b: base.1, op: base.2, motif: base.3, difficulty: difficulty, avoidIndex: lastAnswerIndex)
            if tasks.contains(where: { $0.a == candidate.a && $0.b == candidate.b && $0.op == candidate.op }) { continue }
            lastAnswerIndex = candidate.options.firstIndex(of: candidate.answer) ?? -1
            tasks.append(candidate)
        }
        return tasks
    }

    /// Motive beim Rechnen: Äpfel, Karotten und Käfer.
    static let motifs: [CountMotif] = [.apfel, .karotte, .kaefer]

    static func generate(difficulty: Difficulty, allowPlus: Bool, allowMinus: Bool) -> (Int, Int, MathTask.Op, CountMotif) {
        let maxTotal = difficulty == .entdecken ? 5 : 10
        let useMinus = allowMinus && (!allowPlus || Bool.random())
        let motif = motifs.randomElement()!
        if useMinus {
            let a = Int.random(in: 2...maxTotal)
            let b = Int.random(in: 1...(a - 1))
            return (a, b, .minus, motif)
        } else {
            let total = Int.random(in: 2...maxTotal)
            let a = Int.random(in: 1...(total - 1))
            return (a, total - a, .plus, motif)
        }
    }

    static func makeTask(a: Int, b: Int, op: MathTask.Op, motif: CountMotif, difficulty: Difficulty, avoidIndex: Int) -> MathTask {
        let answer = op == .plus ? a + b : a - b
        let optionCount = difficulty == .entdecken ? 2 : 3
        let maxValue = difficulty == .entdecken ? 6 : 12
        var options = [answer]
        var candidates = [answer + 1, answer - 1, answer + 2, answer - 2, answer + 3].filter { $0 >= 0 && $0 <= maxValue }
        candidates.shuffle()
        // Häufiger Fehler: bei Subtraktion den Ausgangswert nennen.
        if op == .minus, !candidates.contains(a), a != answer { candidates.insert(a, at: 0) }
        for c in candidates where options.count < optionCount && !options.contains(c) {
            options.append(c)
        }
        options.shuffle()
        // Richtige Antwort nicht immer an derselben Position.
        if options.firstIndex(of: answer) == avoidIndex, options.count > 1 {
            options.append(options.removeFirst())
        }
        return MathTask(a: a, b: b, op: op, motif: motif, story: difficulty == .knobeln, options: options)
    }
}

struct AppleMathState: Codable {
    var tasks: [MathTask]
    var index: Int
    var tried: [Int]
}

/// Spiel 2: Apfel-Rechnen.
struct AppleMathGameView: View {
    let host: GameHost
    @State private var model: AppleMathModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: AppleMathModel(host: host))
    }

    var body: some View {
        VStack(spacing: 24) {
            if let task = model.task {
                sceneView(task)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(PlayfieldBackground(color: Theme.apricot.opacity(0.35)))
                HStack(spacing: 28) {
                    ForEach(task.options, id: \.self) { value in
                        AnswerCard(state: model.state(for: value), minSize: 130) {
                            model.choose(value)
                        } content: {
                            Text("\(value)")
                                .font(Theme.answerFont)
                                .foregroundStyle(Theme.darkGreen)
                        }
                        .pulseHighlight(model.highlightAnswer && value == task.answer)
                        .accessibilityLabel("\(value)")
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    @ViewBuilder
    private func sceneView(_ task: MathTask) -> some View {
        let itemSize: CGFloat = host.difficulty == .knobeln ? 50 : 64
        HStack(spacing: 30) {
            switch task.op {
            case .plus:
                group(count: task.a, offset: 0, motif: task.motif, size: itemSize)
                Text("+")
                    .font(Theme.rounded(60, .heavy))
                    .foregroundStyle(Theme.darkGreen)
                group(count: task.b, offset: task.a, motif: task.motif, size: itemSize)
            case .minus:
                minusGroup(task, size: itemSize)
            }
        }
        .padding(30)
    }

    private func group(count: Int, offset: Int, motif: CountMotif, size: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.fixed(size + 10), spacing: 6), count: min(max(count, 1), 5))
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                CountableItem(emoji: motif.emoji, size: size, marked: model.marked.contains(offset + i), number: model.showNumbers ? offset + i + 1 : nil, asset: motif.asset)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white.opacity(0.75)))
    }

    private func minusGroup(_ task: MathTask, size: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.fixed(size + 10), spacing: 6), count: min(max(task.a, 1), 5))
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<task.a, id: \.self) { i in
                let removed = i >= task.answer
                CountableItem(emoji: task.motif.emoji, size: size, marked: model.marked.contains(i), number: model.showNumbers && !removed ? i + 1 : nil, asset: task.motif.asset)
                    .opacity(removed && model.takenAway ? 0.18 : 1)
                    .offset(y: removed && model.takenAway ? -26 : 0)
                    .overlay {
                        if removed && model.takenAway {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.darkGreen.opacity(0.5))
                                .offset(y: -40)
                        }
                    }
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white.opacity(0.75)))
        .animation(.easeInOut(duration: 0.8), value: model.takenAway)
    }
}

struct CountableItem: View {
    let emoji: String
    let size: CGFloat
    var marked: Bool
    var number: Int?
    var asset: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Pic(asset ?? "", emoji, size: size)
                .padding(4)
                .background(Circle().fill(marked ? Theme.highlight.opacity(0.45) : .clear))
            if let number, marked {
                Text("\(number)")
                    .font(Theme.rounded(20, .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(Theme.darkGreen))
                    .offset(x: 6, y: -6)
            }
        }
        .animation(.spring(response: 0.25), value: marked)
    }
}

@MainActor
@Observable
final class AppleMathModel {
    @ObservationIgnored let host: GameHost
    var tasks: [MathTask] = []
    var index = 0
    var tried: [Int] = []
    var solved = false
    var marked: Set<Int> = []
    var showNumbers = true
    var takenAway = false
    var highlightAnswer = false
    @ObservationIgnored private var started = false
    @ObservationIgnored private var countTask: Task<Void, Never>?

    init(host: GameHost) { self.host = host }

    var task: MathTask? { tasks[safe: index] }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Rechenaufgaben gelöst.") }
            let maxN = self.host.difficulty == .entdecken ? 5 : 10
            let hasMinus = self.tasks.contains { $0.op == .minus }
            let kind = hasMinus ? "Plus- und Minusaufgaben" : "Plusaufgaben"
            return RoundSummary(text: "Vier \(kind) mit Mengen bis \(NumberWords.word(maxN)) gelöst.", practiced: self.tasks.map(\.practiceLabel))
        }
        if let saved = host.takeRestoredPayload(AppleMathState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, saved.tasks.count - 1)
            tried = saved.tried
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            present()
        } else {
            tasks = MathTaskFactory.round(difficulty: host.difficulty, operations: host.options.mathOperations, count: host.tasksPerRound)
            index = 0
            present()
        }
    }

    func stop() { countTask?.cancel() }

    private func present() {
        solved = false
        marked = []
        highlightAnswer = false
        takenAway = false
        showNumbers = host.difficulty != .knobeln
        save()
        guard let task else { return }
        host.setInstruction(task.question)
        if task.op == .minus {
            countTask?.cancel()
            countTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                withAnimation { self?.takenAway = true }
            }
        }
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        tried = []
        present()
    }

    private func save() {
        host.persist(AppleMathState(tasks: tasks, index: index, tried: tried))
    }

    func state(for value: Int) -> AnswerState {
        guard let task else { return .normal }
        if solved && value == task.answer { return .correct }
        if tried.contains(value) { return .tried }
        return .normal
    }

    func choose(_ value: Int) {
        guard let task, !solved else { return }
        if value == task.answer {
            solved = true
            takenAway = true
            countTask?.cancel()
            host.taskSolved("Richtig, \(task.motif.phrase(task.answer)).")
        } else {
            if !tried.contains(value) { tried.append(value) }
            save()
            host.wrong("Schauen wir es gemeinsam an. Zählen wir zusammen.")
            countTogether(highlightAfter: false)
        }
    }

    // MARK: Hilfe

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        if let task, !solved { choose(task.answer) }
    }

    private func help(_ level: Int) {
        switch level {
        case 1:
            host.showBunny("Zähle die Dinge einzeln.")
            countTogether(highlightAfter: false)
        case 2:
            host.showBunny("Ich zähle mit dir.")
            countTogether(highlightAfter: false)
        default:
            countTogether(highlightAfter: true)
        }
    }

    /// Markiert die relevanten Gegenstände einzeln und zählt sie geordnet.
    private func countTogether(highlightAfter: Bool) {
        guard let task else { return }
        countTask?.cancel()
        takenAway = true
        marked = []
        let total = task.answer
        countTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            await self.host.audio.waitUntilQuiet()
            if total > 0 {
                for i in 0..<total {
                    guard !Task.isCancelled else { return }
                    self.showNumbers = true
                    self.marked.insert(i)
                    self.host.audio.enqueue(NumberWords.word(i + 1))
                    try? await Task.sleep(nanoseconds: 700_000_000)
                }
            }
            if highlightAfter {
                await self.host.audio.waitUntilQuiet()
                self.highlightAnswer = true
                self.host.showBunny("Wir haben \(NumberWords.word(total)) gezählt. Tippe auf die \(total).")
            }
        }
    }
}
