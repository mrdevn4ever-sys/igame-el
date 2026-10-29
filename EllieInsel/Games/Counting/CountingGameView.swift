import SwiftUI

struct CountingTask: Codable, Equatable {
    enum Mode: String, Codable { case howMany, giveMe }
    var mode: Mode
    var motif: CountMotif
    /// A: Anzahl Gegenstände; B: gewünschte Menge.
    var count: Int
    /// B: verfügbare Gegenstände.
    var available: Int
    var positions: [NPoint]
    var options: [Int]
}

enum CountingFactory {
    static let motifs: [CountMotif] = [.kaefer, .karotte, .apfel, .pilz, .blume, .eichel]

    static func range(level: Int) -> ClosedRange<Int> {
        LevelCatalog.counting(level).range
    }

    /// Zählanordnung: lockeres Raster mit Versatz, damit sich nichts überdeckt.
    static func arrangement(count: Int, seed: UInt64) -> [NPoint] {
        var rng = SeededGenerator(seed: seed)
        // Grössere Mengen brauchen ein dichteres Raster.
        let cols = count > 15 ? 6 : 5
        let rows = count > 15 ? 4 : count > 10 ? 4 : 3
        var cells = Array(0..<(cols * rows)).shuffled(using: &rng)
        var pts: [NPoint] = []
        for _ in 0..<min(count, cells.count) {
            let c = cells.removeFirst()
            let cx = (Double(c % cols) + 0.5) / Double(cols)
            let cy = (Double(c / cols) + 0.5) / Double(rows)
            let jx = Double.random(in: -0.03...0.03, using: &rng)
            let jy = Double.random(in: -0.04...0.04, using: &rng)
            pts.append(NPoint(cx + jx, cy + jy))
        }
        return pts
    }

    static func round(level: Int, modes: Set<String>, count: Int) -> [CountingTask] {
        let r = range(level: level)
        let optionCount = LevelCatalog.counting(level).options
        var allowed: [CountingTask.Mode] = []
        if modes.contains("howMany") { allowed.append(.howMany) }
        if modes.contains("giveMe") { allowed.append(.giveMe) }
        if allowed.isEmpty { allowed = [.howMany] }
        var tasks: [CountingTask] = []
        var lastCount = -1
        for i in 0..<count {
            let mode = allowed[i % allowed.count]
            var n = Int.random(in: r)
            if n == lastCount { n = n == r.upperBound ? n - 1 : n + 1 }
            n = max(r.lowerBound, n)
            lastCount = n
            let motif = motifs.randomElement()!
            switch mode {
            case .howMany:
                let positions = arrangement(count: n, seed: UInt64.random(in: 1...UInt64.max))
                tasks.append(CountingTask(mode: .howMany, motif: motif, count: n, available: n, positions: positions,
                                          options: options(for: n, count: optionCount)))
            case .giveMe:
                let extra = level <= 2 ? 2 : 3
                let available = min(n + extra, 24)
                let positions = arrangement(count: available, seed: UInt64.random(in: 1...UInt64.max))
                tasks.append(CountingTask(mode: .giveMe, motif: motif, count: n, available: available, positions: positions, options: []))
            }
        }
        return tasks
    }

    static func options(for n: Int, count wanted: Int) -> [Int] {
        var opts = [n]
        for c in [n + 1, n - 1, n + 2, n - 2].shuffled() where c >= 1 && opts.count < wanted && !opts.contains(c) {
            opts.append(c)
        }
        return opts.shuffled()
    }
}

struct CountingState: Codable {
    var tasks: [CountingTask]
    var index: Int
    var counted: [Int]
    var basket: [Int]
    var tried: [Int]
}

/// Spiel 5: Zählgarten.
struct CountingGameView: View {
    let host: GameHost
    @State private var model: CountingModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: CountingModel(host: host))
    }

    var body: some View {
        VStack(spacing: 18) {
            if let task = model.task {
                switch task.mode {
                case .howMany: howMany(task)
                case .giveMe: giveMe(task)
                }
            }
        }
        .onAppear { model.start() }
    }

    // MARK: Modus A

    @ViewBuilder
    private func howMany(_ task: CountingTask) -> some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 36).fill(Theme.meadow)
                ForEach(0..<task.count, id: \.self) { i in
                    let p = task.positions[i]
                    let order = model.counted.firstIndex(of: i)
                    CountTarget(emoji: task.motif.emoji, asset: task.motif.asset, number: order.map { $0 + 1 }, hinted: model.hintIndex == i,
                                size: task.count > 12 ? 50 : 64)
                        .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                        .onTapGesture { model.countItem(i) }
                }
            }
        }
        .frame(maxHeight: .infinity)

        HStack(spacing: 24) {
            if model.allCounted {
                ForEach(task.options, id: \.self) { v in
                    AnswerCard(state: model.answerState(v), minSize: 120) {
                        model.answer(v)
                    } content: {
                        Text("\(v)").font(Theme.answerFont).foregroundStyle(Theme.darkGreen)
                    }
                    .pulseHighlight(model.highlightAnswer && v == task.count)
                }
            } else {
                Text("Gezählt: \(model.counted.count)")
                    .font(Theme.rounded(30, .heavy))
                    .foregroundStyle(Theme.darkGreen)
                    .frame(minHeight: 120)
            }
        }
        .animation(.spring(), value: model.allCounted)
    }

    // MARK: Modus B

    @ViewBuilder
    private func giveMe(_ task: CountingTask) -> some View {
        HStack(spacing: 24) {
            GeometryReader { geo in
                ZStack {
                    RoundedRectangle(cornerRadius: 36).fill(Theme.meadow)
                    ForEach(0..<task.available, id: \.self) { i in
                        if !model.basket.contains(i) {
                            let p = task.positions[i]
                            Pic(task.motif.asset, task.motif.emoji, size: task.available > 12 ? 50 : 64)
                                .frame(width: task.available > 12 ? 78 : 96, height: task.available > 12 ? 78 : 96)
                                .contentShape(Rectangle())
                                .position(x: p.x * geo.size.width, y: p.y * geo.size.height)
                                .onTapGesture { model.toBasket(i) }
                                .accessibilityLabel(task.motif.singular)
                        }
                    }
                }
            }
            VStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 36).fill(Theme.creamDark)
                    VStack {
                        Text("🧺").font(.system(size: 80))
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(task.available > 12 ? 44 : 64)), count: task.available > 12 ? 6 : 4), spacing: 8) {
                            ForEach(Array(model.basket.enumerated()), id: \.element) { pos, i in
                                ZStack(alignment: .topTrailing) {
                                    Pic(task.motif.asset, task.motif.emoji, size: task.available > 12 ? 32 : 46)
                                    Text("\(pos + 1)")
                                        .font(Theme.rounded(16, .heavy))
                                        .foregroundStyle(.white)
                                        .frame(width: 26, height: 26)
                                        .background(Circle().fill(Theme.darkGreen))
                                }
                                .frame(width: task.available > 12 ? 44 : 64, height: task.available > 12 ? 44 : 64)
                                .onTapGesture { model.fromBasket(i) }
                            }
                        }
                        .padding(.horizontal, 10)
                        Spacer(minLength: 0)
                    }
                    .padding(.top, 10)
                }
                .pulseHighlight(model.highlightBasket)
                Button {
                    model.finishBasket()
                } label: {
                    Label("Fertig", systemImage: "checkmark.circle.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.success))
                .disabled(model.solved)
            }
            .frame(width: 330)
        }
    }
}

struct CountTarget: View {
    let emoji: String
    var asset: String = ""
    let number: Int?
    var hinted: Bool
    var size: CGFloat = 64

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Pic(asset, emoji, size: size)
                .frame(width: size * 1.55, height: size * 1.55)
                .background(Circle().fill(number != nil ? Theme.highlight.opacity(0.4) : .white.opacity(0.001)))
                .overlay(Circle().stroke(Theme.highlight, lineWidth: hinted ? 6 : 0))
            if let number {
                Text("\(number)")
                    .font(Theme.rounded(24, .heavy))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.darkGreen))
                    .transition(.scale)
            }
        }
        .contentShape(Circle())
        .animation(.spring(response: 0.25), value: number)
    }
}

@MainActor
@Observable
final class CountingModel {
    @ObservationIgnored let host: GameHost
    var tasks: [CountingTask] = []
    var index = 0
    var counted: [Int] = []
    var basket: [Int] = []
    var tried: [Int] = []
    var solved = false
    var hintIndex: Int?
    var highlightAnswer = false
    var highlightBasket = false
    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var task: CountingTask? { tasks[safe: index] }
    var allCounted: Bool { (task?.count ?? 0) > 0 && counted.count >= (task?.count ?? 0) }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Im Zählgarten gezählt.") }
            let maxN = CountingFactory.range(level: self.host.level).upperBound
            return RoundSummary(
                text: "Vier Zählaufgaben mit Mengen bis \(NumberWords.word(maxN)) abgeschlossen.",
                practiced: self.tasks.map { $0.mode == .howMany ? "\($0.count) gezählt" : "\($0.count) abgegeben" }
            )
        }
        if let saved = host.takeRestoredPayload(CountingState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            counted = saved.counted
            basket = saved.basket
            tried = saved.tried
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            instruct()
        } else {
            tasks = CountingFactory.round(level: host.level, modes: host.options.countingModes, count: host.tasksPerRound)
            index = 0
            present()
        }
    }

    private func present() {
        counted = []
        basket = []
        tried = []
        solved = false
        hintIndex = nil
        highlightAnswer = false
        highlightBasket = false
        save()
        instruct()
    }

    private func instruct() {
        guard let task else { return }
        switch task.mode {
        case .howMany:
            let what = task.motif.plural
            let each = (task.motif.feminine ? "jede " : "jeden ") + task.motif.singular
            host.setInstruction(allCounted ? "Wie viele \(what) sind es?" : "Tippe \(each) einmal an. Wie viele \(what) sind es?")
        case .giveMe:
            host.setInstruction("Gib mir \(task.motif.accusative(task.count)).")
        }
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    private func save() {
        host.persist(CountingState(tasks: tasks, index: index, counted: counted, basket: basket, tried: tried))
    }

    // MARK: Modus A

    /// Jeder Gegenstand wird genau einmal gezählt; die Anzeige reagiert sofort, Zahlwörter folgen geordnet.
    func countItem(_ i: Int) {
        guard let task, !solved, !counted.contains(i), i < task.count else { return }
        counted.append(i)
        hintIndex = nil
        host.audio.effect(.tap)
        host.audio.enqueue(NumberWords.word(counted.count))
        save()
        if allCounted {
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.host.audio.waitUntilQuiet()
                guard self.task == task else { return }
                self.host.setInstruction("Wie viele \(task.motif.plural) sind es?")
            }
        }
    }

    func answerState(_ v: Int) -> AnswerState {
        if solved && v == task?.count { return .correct }
        if tried.contains(v) { return .tried }
        return .normal
    }

    func answer(_ v: Int) {
        guard let task, !solved else { return }
        if v == task.count {
            solved = true
            host.taskSolved("Genau, \(task.motif.phrase(task.count)). Du hast alle gezählt.")
        } else {
            if !tried.contains(v) { tried.append(v) }
            save()
            host.wrong("Schauen wir es gemeinsam an. Die letzte Zahl beim Zählen verrät es.")
        }
    }

    // MARK: Modus B

    func toBasket(_ i: Int) {
        guard !solved, !basket.contains(i) else { return }
        basket.append(i)
        host.audio.effect(.snap)
        host.audio.enqueue(NumberWords.word(basket.count))
        save()
    }

    func fromBasket(_ i: Int) {
        guard !solved else { return }
        basket.removeAll { $0 == i }
        host.audio.effect(.tap)
        save()
    }

    func finishBasket() {
        guard let task, !solved else { return }
        let n = basket.count
        if n == task.count {
            solved = true
            highlightBasket = false
            host.taskSolved("Danke! Das sind genau \(task.motif.accusative(n).replacingOccurrences(of: "einen ", with: "ein ")).")
        } else if n < task.count {
            host.wrong("Im Korb \(n == 1 ? "ist" : "sind") \(NumberWords.word(n)). Wir brauchen \(NumberWords.word(task.count)). Leg noch etwas dazu.")
        } else {
            host.wrong("Im Korb sind \(NumberWords.word(n)). Wir brauchen nur \(NumberWords.word(task.count)). Tippe im Korb auf eines, dann kommt es zurück.")
        }
    }

    // MARK: Hilfe

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        guard let task, !solved else { return }
        switch task.mode {
        case .howMany:
            if !allCounted {
                for i in 0..<task.count { countItem(i) }
            } else {
                answer(task.count)
            }
        case .giveMe:
            while basket.count > task.count { basket.removeLast() }
            var i = 0
            while basket.count < task.count && i < task.available {
                if !basket.contains(i) { basket.append(i) }
                i += 1
            }
            finishBasket()
        }
    }

    private func help(_ level: Int) {
        guard let task else { return }
        switch task.mode {
        case .howMany:
            if !allCounted {
                let next = (0..<task.count).first { !counted.contains($0) }
                switch level {
                case 1:
                    hintIndex = next
                    host.showBunny("Tippe jedes einmal an. Hier fehlt noch eines.")
                case 2:
                    hintIndex = next
                    if let next { countItem(next) }
                    host.showBunny("So zählt man: eines nach dem anderen.")
                default:
                    host.showBunny("Wir zählen gemeinsam.")
                    countAllTogether()
                }
            } else {
                switch level {
                case 1: host.showBunny("Welche Zahl hast du zuletzt gesagt?")
                case 2: host.showBunny("Du hast bis \(NumberWords.word(task.count)) gezählt.")
                default:
                    highlightAnswer = true
                    host.showBunny("Wir haben \(NumberWords.word(task.count)) gezählt. Tippe auf die \(task.count).")
                }
            }
        case .giveMe:
            switch level {
            case 1:
                host.showBunny("Leg eines nach dem anderen in den Korb und zähle mit.")
            case 2:
                host.showBunny("Wir brauchen \(NumberWords.word(task.count)). Im Korb \(basket.count == 1 ? "ist" : "sind") \(NumberWords.word(basket.count)).")
            default:
                // Gemeinsam lösen: Korb auf die richtige Menge bringen.
                while basket.count > task.count { basket.removeLast() }
                var i = 0
                while basket.count < task.count && i < task.available {
                    if !basket.contains(i) { basket.append(i) }
                    i += 1
                }
                highlightBasket = true
                save()
                host.showBunny("Jetzt stimmt es. Tippe auf «Fertig».")
            }
        }
    }

    private func countAllTogether() {
        guard let task else { return }
        Task { @MainActor [weak self] in
            for i in 0..<task.count {
                guard let self, self.task == task else { return }
                if !self.counted.contains(i) {
                    self.countItem(i)
                    try? await Task.sleep(nanoseconds: 650_000_000)
                }
            }
        }
    }
}
