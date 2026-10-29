import SwiftUI

/// Spiel 1: Zahlen nachzeichnen.
struct TracingGameView: View {
    let host: GameHost
    @State private var model: TracingModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: TracingModel(host: host))
    }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width * 0.55, geo.size.height) * 0.95
            HStack(spacing: 30) {
                TraceBoard(
                    samples: model.samples,
                    progress: model.progress,
                    style: model.style,
                    demoPoint: model.demoPoint,
                    lineColor: Theme.success,
                    startEmoji: nil
                ) { p in
                    model.feed(p)
                }
                .frame(width: side, height: side)
                .background(PlayfieldBackground())

                VStack(spacing: 20) {
                    Text("\(model.digit)")
                        .font(Theme.rounded(110, .heavy))
                        .foregroundStyle(Theme.darkGreen)
                    if model.showQuantity {
                        QuantityView(count: model.digit, highlighted: model.countedSoFar, emoji: model.quantityEmoji)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { model.start() }
        .onDisappear { model.stopTasks() }
    }
}

/// Mengenbild unter der Ziffer (z. B. drei Äpfel), die beim Zählen nacheinander aufleuchten.
struct QuantityView: View {
    let count: Int
    let highlighted: Int
    let emoji: String

    var body: some View {
        let cell: CGFloat = count > 10 ? 44 : 70
        let columns = Array(repeating: GridItem(.fixed(cell), spacing: count > 10 ? 6 : 10), count: min(max(count, 1), 5))
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(0..<count, id: \.self) { i in
                Text(emoji)
                    .font(.system(size: cell * 0.77))
                    .scaleEffect(i < highlighted ? 1.15 : 0.95)
                    .opacity(i < highlighted ? 1 : 0.55)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: highlighted)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 26).fill(.white))
    }
}

struct TraceStyle: Equatable {
    var trackWidth: Double // normalisiert
    var showCenterLine: Bool
    var showArrows: Bool
    var trackOpacity: Double
}

/// Zeichenfläche: Spur, bestätigte Abschnitte, Startpunkt und Richtungshilfen.
struct TraceBoard: View {
    let samples: [[NPoint]]
    let progress: TraceProgress
    let style: TraceStyle
    let demoPoint: NPoint?
    let lineColor: Color
    var startEmoji: String?
    var goalEmoji: String?
    let onPoint: (NPoint) -> Void

    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let rect = CGRect(origin: .zero, size: geo.size).insetBy(dx: geo.size.width * 0.04, dy: geo.size.height * 0.04)
            ZStack {
                Canvas { ctx, _ in
                    let width = style.trackWidth * rect.width
                    for (s, pts) in samples.enumerated() {
                        let path = makePath(pts, in: rect)
                        // Spur
                        ctx.stroke(path, with: .color(Theme.darkGreen.opacity(0.12 * style.trackOpacity + 0.04)),
                                   style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
                        if style.showCenterLine {
                            ctx.stroke(path, with: .color(Theme.darkGreen.opacity(0.35)),
                                       style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [8, 10]))
                        }
                        // Bestätigter Teil
                        let done = progress.confirmed[safe: s] ?? -1
                        if done > 0 {
                            let donePath = makePath(Array(pts.prefix(done + 1)), in: rect)
                            ctx.stroke(donePath, with: .color(lineColor),
                                       style: StrokeStyle(lineWidth: width * 0.7, lineCap: .round, lineJoin: .round))
                        }
                        // Richtungspfeile
                        if style.showArrows && s >= progress.currentStroke {
                            drawArrows(ctx: ctx, pts: pts, rect: rect, from: max(done, 0))
                        }
                    }
                }

                // Startpunkt des aktuellen Strichs
                if !progress.isComplete, let first = samples[safe: progress.currentStroke]?.first {
                    let p = first.scaled(in: rect)
                    let done = progress.confirmed[progress.currentStroke]
                    if done < 0 {
                        ZStack {
                            Circle()
                                .fill(Theme.highlight)
                                .frame(width: 46, height: 46)
                                .scaleEffect(pulse ? 1.25 : 0.9)
                            if let startEmoji {
                                Text(startEmoji).font(.system(size: 50))
                            }
                        }
                        .position(p)
                        .allowsHitTesting(false)
                    } else if let current = samples[progress.currentStroke][safe: done] {
                        Circle()
                            .fill(lineColor)
                            .frame(width: 30, height: 30)
                            .overlay(Circle().stroke(.white, lineWidth: 4))
                            .position(current.scaled(in: rect))
                            .allowsHitTesting(false)
                    }
                }

                if let goalEmoji, let last = samples.last?.last {
                    Text(goalEmoji)
                        .font(.system(size: 64))
                        .position(last.scaled(in: rect))
                        .allowsHitTesting(false)
                }

                if let demoPoint {
                    Text("👆")
                        .font(.system(size: 54))
                        .position(demoPoint.scaled(in: rect) + CGPoint(x: 10, y: 28))
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { v in
                        onPoint(NPoint((v.location.x - rect.minX) / rect.width, (v.location.y - rect.minY) / rect.height))
                    }
                    .onEnded { _ in
                        onPoint(NPoint(-10, -10)) // Finger abgehoben
                    }
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
        }
    }

    private func makePath(_ pts: [NPoint], in rect: CGRect) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first.scaled(in: rect))
        for p in pts.dropFirst() { path.addLine(to: p.scaled(in: rect)) }
        return path
    }

    private func drawArrows(ctx: GraphicsContext, pts: [NPoint], rect: CGRect, from: Int) {
        let step = 14
        var i = from + 6
        while i + 2 < pts.count {
            let a = pts[i].scaled(in: rect)
            let b = pts[i + 2].scaled(in: rect)
            let angle = atan2(b.y - a.y, b.x - a.x)
            var arrow = Path()
            let size: CGFloat = 9
            arrow.move(to: CGPoint(x: a.x + cos(angle) * size, y: a.y + sin(angle) * size))
            arrow.addLine(to: CGPoint(x: a.x + cos(angle + 2.5) * size, y: a.y + sin(angle + 2.5) * size))
            arrow.addLine(to: CGPoint(x: a.x + cos(angle - 2.5) * size, y: a.y + sin(angle - 2.5) * size))
            arrow.closeSubpath()
            ctx.fill(arrow, with: .color(Theme.darkGreen.opacity(0.45)))
            i += step
        }
    }
}

struct TracingState: Codable {
    var digits: [Int]
    var index: Int
    var progress: TraceProgress
}

@MainActor
@Observable
final class TracingModel {
    @ObservationIgnored let host: GameHost
    var digits: [Int] = []
    var index = 0
    var progress = TraceProgress(strokeCount: 1)
    var samples: [[NPoint]] = []
    var showQuantity = false
    var countedSoFar = 0
    var demoPoint: NPoint?
    @ObservationIgnored private var lastPoint: NPoint?
    @ObservationIgnored private var started = false
    @ObservationIgnored private var demoTask: Task<Void, Never>?
    @ObservationIgnored private var countTask: Task<Void, Never>?
    @ObservationIgnored private var solved = false

    init(host: GameHost) {
        self.host = host
    }

    var digit: Int { digits[safe: index] ?? 3 }
    var quantityEmoji: String { ["🍎", "🍓", "🐞", "🌼", "🍐"][index % 5] }

    var spec: LevelCatalog.TracingSpec { LevelCatalog.tracing(host.level) }
    /// Höchste Stufe: Die Spur verblasst kurz nach dem Zeigen.
    var trackFaded = false
    @ObservationIgnored private var fadeTask: Task<Void, Never>?

    var style: TraceStyle {
        let s = spec
        let twoDigits = digit >= 10
        return TraceStyle(
            trackWidth: twoDigits ? s.width * 0.75 : s.width,
            showCenterLine: s.showCenterLine,
            showArrows: s.showArrows,
            trackOpacity: trackFaded ? 0.12 : (host.level <= 2 ? 1.2 : 1)
        )
    }

    var tolerance: Double { digit >= 10 ? spec.tolerance * 0.8 : spec.tolerance }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] level in self?.help(level) }
        host.nextTaskHandler = { [weak self] in self?.nextDigit() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Zahlen nachgezeichnet.") }
            let list = self.digits.map(String.init).joined(separator: ", ")
            return RoundSummary(text: "Zahlen \(list) nachgezeichnet.", practiced: self.digits.sorted().map { "Ziffer \($0)" })
        }

        if let saved = host.takeRestoredPayload(TracingState.self) {
            digits = saved.digits
            index = saved.index
            samples = DigitPaths.number(digit).resampled()
            progress = saved.progress.confirmed.count == samples.count ? saved.progress : TraceProgress(strokeCount: samples.count)
            if host.tasksDone >= host.tasksPerRound {
                host.resumeIfNeeded()
                return
            }
            if host.awaitingNext {
                // Bereits gelöste Aufgabe: direkt zur nächsten.
                host.next()
                return
            }
            if progress.isComplete {
                completeDigit()
                return
            }
            introduce()
        } else {
            digits = makeDigits()
            index = 0
            loadDigit()
        }
    }

    func stopTasks() {
        demoTask?.cancel()
        countTask?.cancel()
        fadeTask?.cancel()
    }

    private func makeDigits() -> [Int] {
        let pool = spec.numbers
        // Die allererste Runde beginnt mit der gut vorbereiteten Drei.
        if pool.contains(3), (host.app.data.roundsCompleted[GameID.tracing.rawValue] ?? 0) == 0 {
            return [3] + Array(pool.filter { $0 != 3 }.shuffled().prefix(host.tasksPerRound - 1))
        }
        return Array(pool.shuffled().prefix(host.tasksPerRound))
    }

    private func loadDigit() {
        samples = DigitPaths.number(digit).resampled()
        progress = TraceProgress(strokeCount: samples.count)
        trackFaded = false
        showQuantity = false
        countedSoFar = 0
        solved = false
        lastPoint = nil
        save()
        introduce()
    }

    private func introduce() {
        host.setInstruction("Das ist die \(NumberWords.digitName(digit)). Beginne beim Punkt.")
        fadeTask?.cancel()
        trackFaded = false
        if spec.fadeTrack {
            fadeTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.8)) { self?.trackFaded = true }
            }
        }
    }

    private func nextDigit() {
        index += 1
        if index >= digits.count { index = digits.count - 1 }
        loadDigit()
    }

    private func save() {
        host.persist(TracingState(digits: digits, index: index, progress: progress))
    }

    func feed(_ p: NPoint) {
        guard !solved, !progress.isComplete else { return }
        if p.x < -5 {
            lastPoint = nil
            save()
            return
        }
        demoTask?.cancel()
        demoPoint = nil
        // Zwischenpunkte einfügen, damit schnelle Bewegungen nichts überspringen.
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
        var changed = false
        for q in points {
            if progress.feed(q, samples: samples, tolerance: tolerance, lookahead: 9) { changed = true }
        }
        if progress.currentStroke != strokeBefore {
            host.audio.effect(.tap)
            lastPoint = nil
        }
        if progress.isComplete {
            completeDigit()
        } else if changed && progress.confirmed[progress.currentStroke] % 25 == 0 {
            save()
        }
    }

    private func completeDigit() {
        guard !solved else { return }
        solved = true
        save()
        host.audio.effect(.snap)
        withAnimation(.spring()) { showQuantity = true }
        countTask?.cancel()
        countTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.host.audio.sayAndWait("Super! Das ist die \(NumberWords.digitName(self.digit)).")
            if self.digit > 0 {
                for i in 1...self.digit {
                    guard !Task.isCancelled else { return }
                    withAnimation { self.countedSoFar = i }
                    self.host.audio.enqueue(NumberWords.word(i))
                    try? await Task.sleep(nanoseconds: self.digit > 10 ? 380_000_000 : 650_000_000)
                }
            }
            guard !Task.isCancelled else { return }
            await self.host.audio.waitUntilQuiet()
            self.host.taskSolved(self.digit == 0 ? "Null heisst: gar nichts. Gut gezeichnet!" : "Gut gezeichnet!")
        }
    }

    // MARK: Hilfe

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        solveTogether()
    }

    private func help(_ level: Int) {
        switch level {
        case 1:
            host.showBunny("Beginne beim gelben Punkt und folge den Pfeilen.")
            demo(partial: true)
        case 2:
            host.showBunny("Schau, so geht es.")
            demo(partial: false)
        default:
            host.showBunny("Wir zeichnen den nächsten Strich gemeinsam.")
            solveTogether()
        }
    }

    private func demo(partial: Bool) {
        guard !progress.isComplete else { return }
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

    private func solveTogether() {
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
                try? await Task.sleep(nanoseconds: 25_000_000)
            }
            self.demoPoint = nil
            self.lastPoint = nil
            if self.progress.isComplete { self.completeDigit() } else { self.save() }
        }
    }
}
