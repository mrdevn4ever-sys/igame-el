import SwiftUI

struct MathTask: Codable, Equatable {
    enum Op: String, Codable {
        case plus, minus
        /// a + ? = a + b
        case missing
        /// a + b − c
        case twoStep
    }
    var a: Int
    var b: Int
    var op: Op
    var motif: CountMotif
    var story: Bool
    var options: [Int]
    /// Zweiter Schritt (weggenommen)
    var c: Int?
    /// Nur Ziffern, ohne Gegenstände
    var symbols: Bool?

    var isSymbols: Bool { symbols ?? false }
    var total: Int { a + b }

    var answer: Int {
        switch op {
        case .plus: return a + b
        case .minus: return a - b
        case .missing: return b
        case .twoStep: return a + b - (c ?? 0)
        }
    }

    var question: String {
        // Ziffernaufgaben stehen gross auf dem Bildschirm.
        if isSymbols { return "Wie viel ist das?" }
        if story && (op == .plus || op == .minus) { return storyText }
        switch op {
        case .plus:
            if a + b > 10 {
                // Zahlenraum bis 20: kurze Einzelsätze (überschaubare Zahl an Sprachaufnahmen)
                let verb = b == 1 ? "kommt" : "kommen"
                return "\(motif.phrase(a).capitalizedFirst). Dazu \(verb) \(motif.phrase(b)). Wie viele sind es zusammen?"
            }
            return "\(motif.phrase(a).capitalizedFirst) und \(motif.phrase(b)). Wie viele sind es zusammen?"
        case .minus:
            let verb = b == 1 ? "wird" : "werden"
            return "\(motif.phrase(a).capitalizedFirst). \(motif.phrase(b).capitalizedFirst) \(verb) weggenommen. Wie viele bleiben?"
        case .missing:
            return "\(motif.phrase(a).capitalizedFirst). Wie viele fehlen bis \(NumberWords.word(total))?"
        case .twoStep:
            let c = c ?? 0
            let verb = c == 1 ? "wird" : "werden"
            return "\(motif.phrase(a).capitalizedFirst) und \(motif.phrase(b)). Dann \(verb) \(motif.phrase(c)) weggenommen. Wie viele bleiben?"
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
        case (.minus, false):
            return "\(A) \(a == 1 ? "liegt" : "liegen") im Korb. Der Hase nimmt \(motif.accusative(b)) heraus. Wie viele bleiben?"
        default:
            return "\(A) \(a == 1 ? "liegt" : "liegen") im Korb. Der Hase bringt \(motif.accusative(b)) dazu. Wie viele sind es jetzt?"
        }
    }

    var practiceLabel: String {
        switch op {
        case .plus: return "\(a) + \(b) = \(answer)"
        case .minus: return "\(a) − \(b) = \(answer)"
        case .missing: return "\(a) + ? = \(total)"
        case .twoStep: return "\(a) + \(b) − \(c ?? 0) = \(answer)"
        }
    }
}

enum MathTaskFactory {
    /// 24 redaktionell geprüfte Beispielaufgaben (a, b, Operation, Motiv). Verwendet, wenn sie zur Stufe passen.
    static let curated: [(Int, Int, MathTask.Op, CountMotif)] = [
        (2, 1, .plus, .apfel), (1, 1, .plus, .karotte), (2, 2, .plus, .kaefer),
        (3, 1, .plus, .karotte), (1, 3, .plus, .apfel), (3, 2, .plus, .apfel),
        (4, 1, .plus, .kaefer), (2, 3, .plus, .karotte),
        (4, 3, .plus, .apfel), (5, 2, .plus, .karotte), (6, 3, .plus, .kaefer),
        (5, 5, .plus, .karotte), (5, 2, .minus, .apfel), (7, 3, .minus, .apfel),
        (6, 1, .minus, .kaefer), (8, 4, .minus, .karotte),
        (3, 4, .plus, .kaefer), (6, 2, .minus, .kaefer), (4, 4, .plus, .apfel),
        (9, 3, .minus, .apfel), (7, 2, .plus, .karotte), (10, 4, .minus, .karotte),
        (5, 3, .plus, .apfel), (8, 5, .minus, .kaefer)
    ]

    /// Motive beim Rechnen: Äpfel, Karotten und Käfer.
    static let motifs: [CountMotif] = [.apfel, .karotte, .kaefer]

    static func round(level: Int, operations: Set<String>, count: Int) -> [MathTask] {
        let spec = LevelCatalog.math(level)
        let allowMinus = spec.allowMinus && operations.contains("minus")
        let allowPlus = operations.contains("plus") || !allowMinus
        var kind = spec.kind
        if kind == .twoStep && !allowMinus { kind = .basic }
        var curatedPool = curated.filter { c in
            spec.kind == .basic && (c.2 == .plus ? allowPlus && c.0 + c.1 <= spec.maxTotal : allowMinus && c.0 <= spec.maxTotal)
        }.shuffled()
        var tasks: [MathTask] = []
        var lastAnswerIndex = -1
        var attempts = 0
        while tasks.count < count && attempts < 300 {
            attempts += 1
            let motif = motifs.randomElement()!
            var a = 1, b = 1, c: Int?
            var op: MathTask.Op = .plus
            switch kind {
            case .basic, .symbols:
                if tasks.count < 2, kind == .basic, let cur = curatedPool.popLast() {
                    a = cur.0; b = cur.1; op = cur.2
                } else {
                    let useMinus = allowMinus && (!allowPlus || Bool.random())
                    if useMinus {
                        a = Int.random(in: 2...spec.maxTotal)
                        b = Int.random(in: 1...(a - 1))
                        op = .minus
                    } else {
                        let total = Int.random(in: 2...spec.maxTotal)
                        a = Int.random(in: 1...(total - 1))
                        b = total - a
                    }
                }
            case .missing:
                let total = Int.random(in: 3...spec.maxTotal)
                a = Int.random(in: 1...(total - 1))
                b = total - a
                op = .missing
            case .twoStep:
                let total = Int.random(in: 3...spec.maxTotal)
                a = Int.random(in: 1...(total - 1))
                b = total - a
                c = Int.random(in: 1...(total - 1))
                op = .twoStep
            }
            var task = MathTask(a: a, b: b, op: op, motif: motif,
                                story: spec.story && (op == .plus || op == .minus), options: [],
                                c: c, symbols: kind == .symbols ? true : nil)
            if tasks.contains(where: { $0.a == task.a && $0.b == task.b && $0.op == task.op && $0.c == task.c }) { continue }
            task.options = options(for: task, count: spec.options, maxValue: spec.maxTotal + 2, avoidIndex: lastAnswerIndex)
            lastAnswerIndex = task.options.firstIndex(of: task.answer) ?? -1
            tasks.append(task)
        }
        return tasks
    }

    /// Genau eine richtige Antwort, keine doppelten Werte, wechselnde Position.
    static func options(for task: MathTask, count: Int, maxValue: Int, avoidIndex: Int) -> [Int] {
        let answer = task.answer
        var options = [answer]
        var candidates = [answer + 1, answer - 1, answer + 2, answer - 2, answer + 3, answer - 3].filter { $0 >= 0 && $0 <= maxValue }
        candidates.shuffle()
        // Typische Fehler als Ablenker: Ausgangswert bei Minus, Gesamtmenge beim Ergänzen.
        if task.op == .minus, task.a != answer, task.a <= maxValue { candidates.insert(task.a, at: 0) }
        if task.op == .missing, task.total != answer { candidates.insert(task.total, at: 0) }
        for c in candidates where options.count < count && !options.contains(c) {
            options.append(c)
        }
        options.shuffle()
        if options.firstIndex(of: answer) == avoidIndex, options.count > 1 {
            options.append(options.removeFirst())
        }
        return options
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
        let biggest = max(task.op == .minus ? task.a : max(task.a, task.b), 1)
        let itemSize: CGFloat = biggest <= 3 ? 96 : biggest <= 5 ? 80 : biggest <= 10 ? 62 : 44
        HStack(spacing: 26) {
            if task.isSymbols && !model.showObjects {
                Text(task.op == .minus ? "\(task.a) − \(task.b) = ?" : "\(task.a) + \(task.b) = ?")
                    .font(Theme.rounded(110, .heavy))
                    .foregroundStyle(Theme.darkGreen)
            } else {
                switch task.op {
                case .plus:
                    group(count: task.a, offset: 0, motif: task.motif, size: itemSize)
                    sign("+")
                    group(count: task.b, offset: task.a, motif: task.motif, size: itemSize)
                case .minus:
                    minusGroup(task, size: itemSize)
                case .missing:
                    group(count: task.a, offset: 0, motif: task.motif, size: itemSize)
                    sign("+")
                    if model.revealMissing {
                        group(count: task.b, offset: task.a, motif: task.motif, size: itemSize, localNumbers: true)
                    } else {
                        Text("?")
                            .font(Theme.rounded(80, .heavy))
                            .foregroundStyle(Theme.darkGreen.opacity(0.6))
                            .frame(width: 140, height: 140)
                            .background(RoundedRectangle(cornerRadius: 28).strokeBorder(Theme.darkGreen.opacity(0.4), style: StrokeStyle(lineWidth: 4, dash: [10, 8])))
                    }
                    sign("=")
                    Text("\(task.total)")
                        .font(Theme.rounded(90, .heavy))
                        .foregroundStyle(Theme.darkGreen)
                case .twoStep:
                    group(count: task.a, offset: 0, motif: task.motif, size: itemSize, removedFrom: task.answer)
                    sign("+")
                    group(count: task.b, offset: task.a, motif: task.motif, size: itemSize, removedFrom: task.answer)
                }
            }
        }
        .padding(30)
        .animation(.easeInOut(duration: 0.8), value: model.takenAway)
    }

    private func sign(_ s: String) -> some View {
        Text(s)
            .font(Theme.rounded(60, .heavy))
            .foregroundStyle(Theme.darkGreen)
    }

    /// Gruppe von Gegenständen. `removedFrom`: ab diesem Gesamtindex gelten sie als weggenommen.
    private func group(count: Int, offset: Int, motif: CountMotif, size: CGFloat, removedFrom: Int? = nil, localNumbers: Bool = false) -> some View {
        let columns = Array(repeating: GridItem(.fixed(size * 1.25 + 8), spacing: 6), count: min(max(count, 1), 5))
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                let index = offset + i
                let removed = removedFrom.map { index >= $0 } ?? false
                let number = localNumbers ? i + 1 : index + 1
                CountableItem(emoji: motif.emoji, size: size, marked: model.marked.contains(index),
                              number: model.showNumbers && !removed ? number : nil, asset: motif.asset)
                    .opacity(removed && model.takenAway ? 0.18 : 1)
                    .offset(y: removed && model.takenAway ? -26 : 0)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 28).fill(.white.opacity(0.75)))
    }

    private func minusGroup(_ task: MathTask, size: CGFloat) -> some View {
        let columns = Array(repeating: GridItem(.fixed(size * 1.25 + 8), spacing: 6), count: min(max(task.a, 1), 5))
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
                .frame(width: size * 1.2, height: size * 1.2)
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
    /// Ergänzen: Die fehlenden Gegenstände werden bei der Hilfe sichtbar.
    var revealMissing = false
    /// Ziffernaufgaben: Gegenstände als Hilfe einblenden.
    var showObjects = false
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
            let spec = LevelCatalog.math(self.host.level)
            let kind: String
            switch spec.kind {
            case .basic, .symbols: kind = self.tasks.contains { $0.op == .minus } ? "Plus- und Minusaufgaben" : "Plusaufgaben"
            case .missing: kind = "Ergänzungsaufgaben"
            case .twoStep: kind = "Aufgaben mit zwei Schritten"
            }
            return RoundSummary(text: "Vier \(kind) mit Mengen bis \(NumberWords.word(spec.maxTotal)) gelöst.", practiced: self.tasks.map(\.practiceLabel))
        }
        if let saved = host.takeRestoredPayload(AppleMathState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, saved.tasks.count - 1)
            tried = saved.tried
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            present()
        } else {
            tasks = MathTaskFactory.round(level: host.level, operations: host.options.mathOperations, count: host.tasksPerRound)
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
        revealMissing = false
        showObjects = false
        showNumbers = LevelCatalog.math(host.level).showNumbers
        save()
        guard let task else { return }
        host.setInstruction(task.question)
        if task.op == .minus || task.op == .twoStep {
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
        showObjects = true
        marked = []
        let total = task.answer
        // Beim Ergänzen werden die fehlenden Gegenstände gezeigt und gezählt.
        let first = task.op == .missing ? task.a : 0
        if task.op == .missing { revealMissing = true }
        countTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 900_000_000)
            await self.host.audio.waitUntilQuiet()
            if total > 0 {
                for i in 0..<total {
                    guard !Task.isCancelled else { return }
                    self.showNumbers = true
                    self.marked.insert(first + i)
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
