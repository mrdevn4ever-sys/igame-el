import SwiftUI

// MARK: - Aufgaben

enum LetterTask: Codable, Equatable {
    case trace(String)                                  // ein Buchstabe nachzeichnen
    case startsWith(LetterInfo, [String])               // Womit beginnt …? (Anlaut)
    case whereIs(String, [String])                      // Wo ist das M?
    case pair(String, [String])                         // gross → klein
    case word(WordInfo, faded: Bool, mixedCase: Bool)   // Wort Buchstabe für Buchstabe schreiben
    case lay(WordInfo, [String])                        // Wort aus Buchstabenkärtchen legen

    var isWriting: Bool {
        switch self {
        case .trace, .word: return true
        default: return false
        }
    }
}

struct LettersState: Codable {
    var tasks: [LetterTask]
    var index: Int
}

struct LetterLevelSpec {
    var width: Double
    var tolerance: Double
    var arrows: Bool
    var centerLine: Bool
}

enum LetterTasks {
    static func spec(_ level: Int) -> LetterLevelSpec {
        switch level {
        case ...2: return LetterLevelSpec(width: 0.2, tolerance: 0.1, arrows: true, centerLine: true)
        case 3: return LetterLevelSpec(width: 0.17, tolerance: 0.085, arrows: true, centerLine: true)
        case 4: return LetterLevelSpec(width: 0.16, tolerance: 0.08, arrows: false, centerLine: true)
        case 5: return LetterLevelSpec(width: 0.15, tolerance: 0.075, arrows: true, centerLine: true)
        case 6: return LetterLevelSpec(width: 0.13, tolerance: 0.065, arrows: false, centerLine: false)
        case 7: return LetterLevelSpec(width: 0.17, tolerance: 0.085, arrows: true, centerLine: true)
        case 8: return LetterLevelSpec(width: 0.15, tolerance: 0.075, arrows: false, centerLine: false)
        default: return LetterLevelSpec(width: 0.13, tolerance: 0.065, arrows: false, centerLine: false)
        }
    }

    /// Wählt bevorzugt Buchstaben, die noch nicht sicher sitzen.
    static func pick(_ pool: [String], count: Int, known: [String: Int]) -> [String] {
        var rest = pool
        var out: [String] = []
        while out.count < count, !rest.isEmpty {
            let weights = rest.map { 1.0 / Double(1 + min(known[$0] ?? 0, 4) * 2) }
            var r = Double.random(in: 0..<weights.reduce(0, +))
            var i = 0
            while i < weights.count - 1, r >= weights[i] { r -= weights[i]; i += 1 }
            out.append(rest.remove(at: i))
        }
        return out
    }

    static func options(_ answer: String, from pool: [String], count: Int) -> [String] {
        ([answer] + pool.filter { $0 != answer }.shuffled().prefix(count - 1)).shuffled()
    }

    /// Name des Kindes, wenn er nur aus A–Z besteht.
    static func nameWord(_ name: String) -> WordInfo? {
        let n = name.trimmingCharacters(in: .whitespaces)
        guard (2...8).contains(n.count), n.allSatisfy({ ("A"..."Z").contains(String($0).uppercased()) && $0.isASCII }) else { return nil }
        return WordInfo(word: n.prefix(1).uppercased() + n.dropFirst().lowercased(), emoji: "⭐️")
    }

    static func round(level: Int, known: [String: Int], name: String) -> [LetterTask] {
        let upper = LetterCatalog.allUpper
        switch level {
        case ...1:
            return pick(LetterCatalog.straight, count: 4, known: known).map { LetterTask.trace($0) }
        case 2:
            let curved = pick(LetterCatalog.curved, count: 3, known: known)
            let straight = pick(LetterCatalog.straight, count: 1, known: known)
            return (curved + straight).shuffled().map { LetterTask.trace($0) }
        case 3:
            let t = pick(upper, count: 4, known: known)
            let info = LetterCatalog.info(t[3])
            return [.trace(t[0]), .trace(t[1]), .startsWith(info, options(info.upper, from: upper, count: 3)), .trace(t[2])]
        case 4:
            let t = pick(upper, count: 4, known: known)
            let info = LetterCatalog.info(t[2])
            return [.trace(t[0]), .whereIs(t[3], options(t[3], from: upper, count: 4)),
                    .trace(t[1]), .startsWith(info, options(info.upper, from: upper, count: 4))]
        case 5:
            let t = pick(LetterCatalog.easyLower, count: 4, known: known)
            let pairLetter = t[3].uppercased()
            return [.trace(t[0]), .trace(t[1]), .pair(pairLetter, options(t[3], from: LetterCatalog.easyLower, count: 3)), .trace(t[2])]
        case 6:
            let t = pick(LetterCatalog.allLower, count: 4, known: known)
            let info = LetterCatalog.info(t[3])
            return [.trace(t[0]), .pair(t[2].uppercased(), options(t[2], from: LetterCatalog.allLower, count: 4)),
                    .trace(t[1]), .startsWith(info, options(info.upper, from: upper, count: 4))]
        case 7:
            var words = LetterCatalog.shortWords.shuffled().prefix(3).map { LetterTask.word($0, faded: false, mixedCase: false) }
            if let n = nameWord(name) { words[0] = .word(n, faded: false, mixedCase: false) }
            return words
        case 8:
            let w = LetterCatalog.shortWords.shuffled()
            let lay = LetterCatalog.longerWords.randomElement()!
            return [.word(w[0], faded: true, mixedCase: false), .lay(lay, tiles(for: lay)), .word(w[1], faded: true, mixedCase: false)]
        default:
            let w = LetterCatalog.longerWords.shuffled()
            return [.lay(w[0], tiles(for: w[0])), .word(w[1], faded: true, mixedCase: true), .word(w[2], faded: true, mixedCase: true)]
        }
    }

    /// Kärtchen: Buchstaben des Worts plus zwei andere.
    static func tiles(for w: WordInfo) -> [String] {
        let letters = w.upper.map(String.init)
        let extra = LetterCatalog.allUpper.filter { !letters.contains($0) }.shuffled().prefix(2)
        return (letters + extra).shuffled()
    }
}

// MARK: - Spiel

/// Spiel 14: ABC – Buchstaben nachzeichnen, erkennen und Wörter schreiben.
struct LettersGameView: View {
    let host: GameHost
    @State private var model: LettersModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: LettersModel(host: host))
    }

    var body: some View {
        VStack(spacing: 12) {
            LetterStrip(letters: model.stripLetters, known: host.app.data.letters, current: model.currentLetter)
            Group {
                if let task = model.task {
                    switch task {
                    case .trace, .word:
                        writingView(task)
                    case .startsWith(let info, let options):
                        choiceView(header: AnyView(pictureCard(info.picture, info.emoji, info.word)),
                                   options: options, answer: info.upper) { model.chooseLetter($0, answer: info.upper) }
                    case .whereIs(let letter, let options):
                        choiceView(header: AnyView(Button { host.repeatInstruction() } label: {
                                       VStack(spacing: 10) {
                                           Image(systemName: "speaker.wave.3.fill").font(.system(size: 80, weight: .bold))
                                           Text("Nochmals hören").font(Theme.rounded(22, .bold))
                                       }
                                       .foregroundStyle(Theme.darkGreen)
                                       .padding(30)
                                       .background(RoundedRectangle(cornerRadius: 30).fill(.white))
                                   }.buttonStyle(PressableStyle())),
                                   options: options, answer: letter) { model.chooseLetter($0, answer: letter) }
                    case .pair(let upper, let options):
                        choiceView(header: AnyView(LetterGlyph(letter: upper, color: Theme.darkGreen).frame(width: 170, height: 170)),
                                   options: options, answer: upper.lowercased()) { model.chooseLetter($0, answer: upper.lowercased()) }
                    case .lay(let w, let tiles):
                        layView(w, tiles)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { model.start() }
        .onDisappear { model.stopTasks() }
    }

    // MARK: Schreiben

    private func writingView(_ task: LetterTask) -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width * 0.55, geo.size.height) * 0.97
            HStack(spacing: 26) {
                ZStack {
                    WritingLines(lower: model.currentLetter.map { $0 == $0.lowercased() } ?? false)
                    TraceBoard(samples: model.samples, progress: model.progress, style: model.style,
                               demoPoint: model.demoPoint, lineColor: Theme.success, startEmoji: nil) { p in
                        model.feed(p)
                    }
                }
                .frame(width: side, height: side)
                .background(PlayfieldBackground())

                VStack(spacing: 18) {
                    if case .word(let w, _, let mixed) = task {
                        pictureCard(w.picture, w.emoji, nil)
                        WordRow(letters: model.wordLetters(w, mixedCase: mixed), done: model.wordIndex)
                            .frame(height: 90)
                    } else if let l = model.currentLetter {
                        let info = LetterCatalog.info(l)
                        HStack(spacing: 6) {
                            LetterGlyph(letter: info.upper, color: Theme.darkGreen).frame(width: 110, height: 110)
                            LetterGlyph(letter: info.lower, color: Theme.darkGreen.opacity(0.75)).frame(width: 110, height: 110)
                        }
                        pictureCard(info.picture, info.emoji, info.word)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func pictureCard(_ asset: String, _ emoji: String, _ word: String?) -> some View {
        VStack(spacing: 6) {
            Pic(asset, emoji, size: 110)
                .frame(width: 150, height: 140)
            if let word {
                Text(word)
                    .font(Theme.rounded(30, .heavy))
                    .foregroundStyle(Theme.darkGreen)
            }
        }
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 30).fill(.white))
    }

    // MARK: Erkennen

    private func choiceView(header: AnyView, options: [String], answer: String, choose: @escaping (String) -> Void) -> some View {
        VStack(spacing: 24) {
            header
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PlayfieldBackground(color: Theme.lightBlue.opacity(0.5)))
            HStack(spacing: 22) {
                ForEach(options, id: \.self) { o in
                    AnswerCard(state: model.state(for: o), minSize: 140) {
                        choose(o)
                    } content: {
                        LetterGlyph(letter: o, color: Theme.darkGreen).frame(width: 130, height: 130)
                    }
                    .pulseHighlight(model.highlightAnswer && o == answer)
                    .accessibilityLabel(o)
                }
            }
            .padding(.bottom, 6)
        }
    }

    // MARK: Legen

    private func layView(_ w: WordInfo, _ tiles: [String]) -> some View {
        let letters = w.upper.map(String.init)
        return VStack(spacing: 22) {
            HStack(spacing: 30) {
                pictureCard(w.picture, w.emoji, nil)
                HStack(spacing: 10) {
                    ForEach(Array(letters.enumerated()), id: \.offset) { i, l in
                        ZStack {
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(style: StrokeStyle(lineWidth: 3, dash: [9, 7]))
                                .foregroundStyle(Theme.darkGreen.opacity(0.35))
                            if i < model.laid.count {
                                LetterGlyph(letter: l, color: Theme.success).padding(6).transition(.scale)
                            }
                        }
                        .frame(width: 96, height: 110)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PlayfieldBackground(color: Theme.meadow.opacity(0.6)))

            HStack(spacing: 16) {
                ForEach(Array(tiles.enumerated()), id: \.offset) { i, t in
                    let used = model.usedTiles.contains(i)
                    AnswerCard(state: .normal, minSize: 96) {
                        model.tapTile(i, letter: t, word: w)
                    } content: {
                        LetterGlyph(letter: t, color: Theme.darkGreen).frame(width: 86, height: 86)
                    }
                    .opacity(used ? 0.2 : 1)
                    .disabled(used)
                    .pulseHighlight(model.highlightAnswer && !used && model.nextLayLetter(w) == t)
                }
            }
            .padding(.bottom, 6)
        }
    }
}

// MARK: - Bausteine

/// Buchstabe aus denselben Strichen wie die Nachzeichen-Vorlage (einheitliche Druckschrift).
struct LetterGlyph: View {
    let letter: String
    var color: Color = Theme.darkGreen

    var body: some View {
        Canvas { ctx, size in
            let rect = CGRect(origin: .zero, size: size)
            for stroke in LetterPaths.strokes(letter) {
                var path = Path()
                guard let f = stroke.first else { continue }
                path.move(to: CGPoint(x: f.x * rect.width, y: f.y * rect.height))
                for p in stroke.dropFirst() { path.addLine(to: CGPoint(x: p.x * rect.width, y: p.y * rect.height)) }
                ctx.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: max(3, size.width * 0.085), lineCap: .round, lineJoin: .round))
            }
        }
        .accessibilityLabel(letter)
    }
}

/// Wort als Reihe von Buchstaben; geschriebene sind grün, der aktuelle leuchtet.
struct WordRow: View {
    let letters: [String]
    let done: Int

    var body: some View {
        HStack(spacing: -14) {
            ForEach(Array(letters.enumerated()), id: \.offset) { i, l in
                LetterGlyph(letter: l, color: i < done ? Theme.success : (i == done ? Theme.highlight : Theme.darkGreen.opacity(0.25)))
                    .frame(width: 84, height: 84)
            }
        }
    }
}

/// Schreiblinien hinter der Zeichenfläche (gleicher Rand wie TraceBoard).
struct WritingLines: View {
    let lower: Bool

    var body: some View {
        GeometryReader { geo in
            let inset = geo.size.height * 0.04
            let h = geo.size.height - inset * 2
            let ys: [Double] = lower ? [0.14, 0.42, 0.8, 0.98] : [0.12, 0.5, 0.88]
            ForEach(Array(ys.enumerated()), id: \.offset) { i, y in
                let isMain = lower ? (i == 1 || i == 2) : (i != 1)
                Path { p in
                    p.move(to: CGPoint(x: inset, y: inset + y * h))
                    p.addLine(to: CGPoint(x: geo.size.width - inset, y: inset + y * h))
                }
                .stroke(Theme.lightBlue.opacity(isMain ? 1 : 0.7), style: StrokeStyle(lineWidth: isMain ? 3 : 2, dash: isMain ? [] : [10, 8]))
            }
        }
        .allowsHitTesting(false)
    }
}

/// Alle Buchstaben als kleine Reihe: gekonnte leuchten.
struct LetterStrip: View {
    let letters: [String]
    let known: [String: Int]
    let current: String?

    var body: some View {
        HStack(spacing: 2) {
            ForEach(letters, id: \.self) { l in
                let score = known[l] ?? 0
                LetterGlyph(letter: l, color: score >= LettersModel.masteredScore ? Theme.success : Theme.darkGreen.opacity(score > 0 ? 0.45 : 0.18))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(l == current ? Theme.lightYellow : .clear).frame(width: 34, height: 34))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Capsule().fill(.white))
        .accessibilityHidden(true)
    }
}

// MARK: - Modell

@MainActor
@Observable
final class LettersModel {
    static let masteredScore = 3

    @ObservationIgnored let host: GameHost
    var tasks: [LetterTask] = []
    var index = 0
    var samples: [[NPoint]] = []
    var progress = TraceProgress(strokeCount: 1)
    var demoPoint: NPoint?
    var wordIndex = 0
    var tried: Set<String> = []
    var chosen: String?
    var solved = false
    var highlightAnswer = false
    var laid: [String] = []
    var usedTiles: Set<Int> = []
    var trackFaded = false
    @ObservationIgnored private var lastPoint: NPoint?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var demoTask: Task<Void, Never>?
    @ObservationIgnored private var fadeTask: Task<Void, Never>?
    @ObservationIgnored private var helped = false

    init(host: GameHost) { self.host = host }

    var task: LetterTask? { tasks[safe: index] }
    var spec: LetterLevelSpec { LetterTasks.spec(host.level) }

    var style: TraceStyle {
        TraceStyle(trackWidth: spec.width * (isLower ? 0.72 : 1), showCenterLine: spec.centerLine && !trackFaded,
                   showArrows: spec.arrows && !trackFaded, trackOpacity: trackFaded ? 0.1 : 1.1)
    }

    private var isLower: Bool { currentLetter.map { $0 == $0.lowercased() } ?? false }

    /// Buchstabe, der gerade geschrieben wird.
    var currentLetter: String? {
        switch task {
        case .trace(let l): return l
        case .word(let w, _, let mixed): return wordLetters(w, mixedCase: mixed)[safe: wordIndex]
        default: return nil
        }
    }

    var stripLetters: [String] {
        (5...6).contains(host.level) ? LetterCatalog.letters.map(\.lower) : LetterCatalog.letters.map(\.upper)
    }

    func wordLetters(_ w: WordInfo, mixedCase: Bool) -> [String] {
        (mixedCase ? w.word : w.upper).map(String.init)
    }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Buchstaben geübt.") }
            let items = self.tasks.map(self.subject)
            return RoundSummary(text: "Geübt: \(items.joined(separator: ", ")).", practiced: items)
        }
        if DemoMode.flag("-abctest"), let demo = DemoMode.value("-abcaufgabe") {
            tasks = Self.demoTasks(demo)
        } else if let saved = host.takeRestoredPayload(LettersState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            host.setTasksPerRound(tasks.count)
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
        } else {
            tasks = LetterTasks.round(level: host.level, known: host.app.data.letters, name: host.app.data.profile.name)
        }
        host.setTasksPerRound(tasks.count)
        present()
    }

    func stopTasks() {
        demoTask?.cancel()
        fadeTask?.cancel()
    }

    private func subject(_ t: LetterTask) -> String {
        switch t {
        case .trace(let l): return "Buchstabe \(l)"
        case .startsWith(let i, _): return "Anlaut \(i.upper)"
        case .whereIs(let l, _): return "Buchstabe \(l) erkennen"
        case .pair(let u, _): return "\(u) und \(u.lowercased())"
        case .word(let w, _, _), .lay(let w, _): return "Wort \(w.word)"
        }
    }

    private func present() {
        solved = false
        tried = []
        chosen = nil
        highlightAnswer = false
        laid = []
        usedTiles = []
        wordIndex = 0
        helped = false
        demoPoint = nil
        host.persist(LettersState(tasks: tasks, index: index))
        loadLetter()
        instruct()
    }

    private func loadLetter() {
        lastPoint = nil
        trackFaded = false
        fadeTask?.cancel()
        guard let l = currentLetter else { samples = []; return }
        samples = LetterPaths.shape(l).resampled()
        progress = TraceProgress(strokeCount: samples.count)
        if case .word(_, let faded, _) = task, faded {
            fadeTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 1_800_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.8)) { self?.trackFaded = true }
            }
        }
    }

    private func instruct() {
        guard let task else { return }
        switch task {
        case .trace(let l):
            let info = LetterCatalog.info(l)
            host.setInstruction("\(l == info.upper ? info.intro : info.introSmall) \(LetterCatalog.start)")
        case .startsWith(let info, _): host.setInstruction(info.startsWith)
        case .whereIs(let l, _): host.setInstruction(LetterCatalog.info(l).whereIs)
        case .pair(let u, _): host.setInstruction(LetterCatalog.info(u).pairQuestion)
        case .word(let w, _, _):
            if w.emoji == "⭐️" { host.setInstruction(LetterCatalog.nameIntro) } else { host.setInstruction(w.prompt) }
        case .lay(let w, _): host.setInstruction(w.lay)
        }
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    // MARK: Schreiben

    func feed(_ p: NPoint) {
        guard !solved, task?.isWriting == true, !progress.isComplete else { return }
        if p.x < -5 { lastPoint = nil; return }
        demoTask?.cancel()
        demoPoint = nil
        var points: [NPoint] = [p]
        if let last = lastPoint {
            let d = hypot(p.x - last.x, p.y - last.y)
            let n = Int(d / 0.01)
            if n > 1 && n < 40 {
                points = (1...n).map { i in
                    let t = Double(i) / Double(n)
                    return NPoint(last.x + (p.x - last.x) * t, last.y + (p.y - last.y) * t)
                }
            }
        }
        lastPoint = p
        let strokeBefore = progress.currentStroke
        let tol = spec.tolerance * (isLower ? 0.8 : 1)
        for q in points { progress.feed(q, samples: samples, tolerance: tol, lookahead: 9) }
        if progress.currentStroke != strokeBefore {
            host.audio.effect(.tap)
            lastPoint = nil
        }
        if progress.isComplete { letterDone() }
    }

    private func letterDone() {
        guard let task else { return }
        host.audio.effect(.snap)
        if let l = currentLetter, !helped { learn(l, +1) }
        switch task {
        case .trace(let l):
            solved = true
            host.taskSolved("\(LetterCatalog.wellDone) \(LetterCatalog.info(l).upper) wie \(LetterCatalog.info(l).word).")
        case .word(let w, _, let mixed):
            wordIndex += 1
            helped = false
            if wordIndex >= wordLetters(w, mixedCase: mixed).count {
                solved = true
                host.taskSolved(w.emoji == "⭐️" ? "Toll, das ist dein Name!" : w.done)
            } else {
                loadLetter()
            }
        default:
            break
        }
    }

    /// Punkte für einen Buchstaben (gross und klein getrennt).
    private func learn(_ letter: String, _ delta: Int) {
        host.app.update { d in
            d.letters[letter] = max(0, min(9, (d.letters[letter] ?? 0) + delta))
        }
    }

    // MARK: Erkennen

    func state(for o: String) -> AnswerState {
        if solved && chosen == o { return .correct }
        if tried.contains(o) { return .tried }
        return .normal
    }

    func chooseLetter(_ o: String, answer: String) {
        guard !solved, let task else { return }
        if o == answer {
            solved = true
            chosen = o
            if tried.isEmpty { learn(answer, +1) }
            switch task {
            case .startsWith(let info, _): host.taskSolved(info.startsWithRight)
            case .pair(let u, _): host.taskSolved(LetterCatalog.info(u).pairRight)
            default: host.taskSolved("\(LetterCatalog.info(answer).intro)")
            }
        } else {
            tried.insert(o)
            learn(answer, -1)
            if case .startsWith(let info, _) = task {
                host.wrong("\(LetterCatalog.listen) \(info.startsWith)")
            } else {
                host.wrong(LetterCatalog.tryAgain)
            }
        }
    }

    // MARK: Legen

    func nextLayLetter(_ w: WordInfo) -> String? {
        w.upper.map(String.init)[safe: laid.count]
    }

    func tapTile(_ i: Int, letter: String, word: WordInfo) {
        guard !solved, !usedTiles.contains(i) else { return }
        if letter == nextLayLetter(word) {
            withAnimation(.spring(response: 0.3)) {
                laid.append(letter)
                usedTiles.insert(i)
            }
            host.audio.effect(.snap)
            if laid.count == word.upper.count {
                solved = true
                host.taskSolved(word.done)
            }
        } else {
            host.wrong(LetterCatalog.wordWrong)
        }
    }

    // MARK: Hilfe

    private func help(_ level: Int) {
        guard let task else { return }
        switch task {
        case .trace, .word:
            helped = true
            if level == 1 {
                host.showBunny("Beginne beim gelben Punkt und folge den Pfeilen.")
                demo(partial: true)
            } else if level == 2 {
                host.showBunny("Schau, so geht es.")
                demo(partial: false)
            } else {
                host.showBunny("Wir zeichnen den nächsten Strich gemeinsam.")
                solveStroke()
            }
        default:
            highlightAnswer = level >= 2
            host.showBunny(level >= 2 ? "Diese Karte leuchtet. Sie passt." : "Hör dir die Frage nochmals genau an.")
            if level == 1 { host.repeatInstruction() }
        }
    }

    private func demo(partial: Bool) {
        guard !progress.isComplete else { return }
        trackFaded = false
        let stroke = progress.currentStroke
        let pts = samples[stroke]
        let from = max(0, progress.confirmed[stroke])
        let to = partial ? min(pts.count - 1, from + pts.count / 3) : pts.count - 1
        demoTask?.cancel()
        demoTask = Task { @MainActor [weak self] in
            for i in stride(from: from, through: to, by: 2) {
                guard !Task.isCancelled else { return }
                self?.demoPoint = pts[i]
                try? await Task.sleep(nanoseconds: 30_000_000)
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            self?.demoPoint = nil
        }
    }

    private func solveStroke() {
        guard !progress.isComplete else { return }
        let stroke = progress.currentStroke
        let pts = samples[stroke]
        demoTask?.cancel()
        demoTask = Task { @MainActor [weak self] in
            guard let self else { return }
            var i = max(0, self.progress.confirmed[stroke])
            while i < pts.count, !Task.isCancelled, self.progress.currentStroke == stroke {
                self.demoPoint = pts[i]
                self.progress.feed(pts[i], samples: self.samples, tolerance: 0.02, lookahead: 3)
                i += 1
                try? await Task.sleep(nanoseconds: 20_000_000)
            }
            self.demoPoint = nil
            self.lastPoint = nil
            if self.progress.isComplete { self.letterDone() }
        }
    }

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        guard let task, !solved else { return }
        switch task {
        case .trace, .word:
            helped = true
            var guardCount = 0
            while !solved, guardCount < 40 {
                guardCount += 1
                for s in samples.indices { for p in samples[s] { progress.feed(p, samples: samples, tolerance: 0.02, lookahead: 3) } }
                if progress.isComplete { letterDone() } else { break }
            }
        case .startsWith(let info, _): chooseLetter(info.upper, answer: info.upper)
        case .whereIs(let l, _): chooseLetter(l, answer: l)
        case .pair(let u, _): chooseLetter(u.lowercased(), answer: u.lowercased())
        case .lay(let w, let tiles):
            for l in w.upper.map(String.init) {
                if let i = tiles.indices.first(where: { tiles[$0] == l && !usedTiles.contains($0) }) { tapTile(i, letter: l, word: w) }
            }
        }
    }

    static func demoTasks(_ name: String) -> [LetterTask] {
        let maus = LetterCatalog.longerWords[0]
        switch name {
        case "klein": return [.trace("a"), .trace("g"), .trace("k")]
        case "anlaut": return [.startsWith(LetterCatalog.info("M"), ["M", "S", "O"])]
        case "paar": return [.pair("B", ["d", "b", "p", "q"])]
        case "wo": return [.whereIs("W", ["M", "W", "V", "N"])]
        case "wort": return [.word(LetterCatalog.shortWords[2], faded: false, mixedCase: false)]
        case "wortfrei": return [.word(maus, faded: true, mixedCase: true)]
        case "legen": return [.lay(maus, ["S", "M", "E", "U", "A", "T"])]
        default: return [.trace("B"), .trace("M"), .trace("S")]
        }
    }
}
