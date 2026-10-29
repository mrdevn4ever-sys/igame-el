import SwiftUI
import PencilKit

struct AtelierState: Codable {
    enum Mode: String, Codable { case paths, free }
    var mode: Mode?
    // Wege
    var pathIDs: [Int] = []
    var pathIndex: Int = 0
    var progress: TraceProgress?
    // Freies Malen
    var artworkID: UUID?
    var drawing: Data?
    var background: CanvasBackground = .leer
    var canvasWidth: Double?
}

/// Spiel 12: Spurenatelier und freies Malen.
struct AtelierGameView: View {
    let host: GameHost
    @State private var model: AtelierModel
    @Environment(AppModel.self) private var app

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: AtelierModel(host: host))
    }

    var body: some View {
        Group {
            switch model.mode {
            case .none: chooser
            case .paths: pathsView
            case .free: FreeDrawingView(model: model)
            }
        }
        .onAppear { model.start() }
        .onDisappear { model.leave() }
    }

    private var chooser: some View {
        HStack(spacing: 40) {
            if host.options.atelierModes.contains("paths") {
                modeButton(emoji: "🐝 ➰ 🌼", title: "Wege nachfahren") { model.choose(.paths) }
            }
            if host.options.atelierModes.contains("free") {
                modeButton(emoji: "🖍️", title: "Frei malen") { model.choose(.free) }
                VStack(spacing: 20) {
                    Button {
                        app.audio.effect(.tap)
                        app.screen = .gallery
                    } label: {
                        Label("Meine Bilder", systemImage: "photo.on.rectangle.angled")
                    }
                    .buttonStyle(BigButtonStyle(color: Theme.lightYellow, foreground: Theme.darkGreen))
                    Text("\(app.gallery.count) Bilder")
                        .font(Theme.rounded(18, .medium))
                        .foregroundStyle(Theme.darkGreen.opacity(0.7))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func modeButton(emoji: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            app.audio.effect(.tap)
            action()
        } label: {
            VStack(spacing: 16) {
                Text(emoji).font(.system(size: 80))
                Text(title).font(Theme.rounded(28, .bold)).foregroundStyle(Theme.darkGreen)
            }
            .frame(width: 300, height: 300)
            .background(RoundedRectangle(cornerRadius: 40).fill(Theme.lightYellow).shadow(color: .black.opacity(0.12), radius: 8, y: 4))
        }
        .buttonStyle(PressableStyle())
    }

    private var pathsView: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.98
            if let path = model.currentPath {
                TraceBoard(
                    samples: model.samples,
                    progress: model.progress,
                    style: model.traceStyle,
                    demoPoint: model.demoPoint,
                    lineColor: Palette.orange.color,
                    startEmoji: path.start,
                    goalEmoji: path.goal
                ) { p in
                    model.feed(p)
                }
                .frame(width: side, height: side)
                .background(PlayfieldBackground(color: Theme.lightYellow.opacity(0.5)))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

/// Freies Malen mit überschaubaren Werkzeugen.
private struct FreeDrawingView: View {
    @Bindable var model: AtelierModel

    private let colors: [Palette] = [.red, .orange, .yellow, .green, .blue, .purple, .brown, .black]
    private let widths: [CGFloat] = [6, 14, 30]

    var body: some View {
        HStack(spacing: 16) {
            toolbar
            GeometryReader { geo in
                let w = min(geo.size.width, geo.size.height * 4 / 3)
                let h = w * 3 / 4
                ZStack {
                    CanvasBackgroundView(background: model.background)
                    PencilCanvas(drawing: $model.drawing, tool: model.tool) { d in
                        model.strokeFinished(d)
                    }
                }
                .frame(width: w, height: h)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.12), radius: 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { model.canvasWidthChanged(w) }
                .onChange(of: w) { _, nw in model.canvasWidthChanged(nw) }
            }
            sideActions
        }
    }

    private var toolbar: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                ForEach(colors, id: \.self) { c in
                    Button {
                        model.selectColor(c)
                    } label: {
                        Circle()
                            .fill(c.color)
                            .frame(width: 56, height: 56)
                            .overlay(Circle().stroke(Theme.darkGreen, lineWidth: model.color == c && !model.erasing ? 5 : 0).padding(-5))
                    }
                    .accessibilityLabel("Farbe \(c.name)")
                }
                Divider().frame(width: 50)
                ForEach(widths, id: \.self) { w in
                    Button {
                        model.selectWidth(w)
                    } label: {
                        Circle()
                            .fill(Theme.darkGreen)
                            .frame(width: w + 6, height: w + 6)
                            .frame(width: 64, height: 56)
                            .background(RoundedRectangle(cornerRadius: 14).fill(model.width == w && !model.erasing ? Theme.highlight.opacity(0.5) : .white))
                    }
                    .accessibilityLabel(w < 10 ? "Dünn" : w < 20 ? "Mittel" : "Dick")
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 80)
    }

    private var sideActions: some View {
        VStack(spacing: 14) {
            CircleIconButton(systemName: "eraser.fill", label: "Radierer", tint: model.erasing ? .white : Theme.darkGreen,
                             background: model.erasing ? Theme.darkGreen : .white) {
                model.toggleEraser()
            }
            CircleIconButton(systemName: "arrow.uturn.backward", label: "Rückgängig") {
                model.undo()
            }
            .opacity(model.canUndo ? 1 : 0.4)
            Menu {
                ForEach(CanvasBackground.allCases, id: \.self) { bg in
                    Button("\(bg.icon) \(bg.title)") { model.setBackground(bg) }
                }
            } label: {
                Text(model.background.icon)
                    .font(.system(size: 30))
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
            }
            .accessibilityLabel("Hintergrund wählen")
            Spacer()
            Button {
                model.finishDrawing()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 34))
                    Text("Fertig").font(Theme.rounded(20, .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 100, height: 100)
                .background(RoundedRectangle(cornerRadius: 26).fill(Theme.success))
            }
            .buttonStyle(PressableStyle())
        }
        .frame(width: 104)
    }
}

@MainActor
@Observable
final class AtelierModel {
    @ObservationIgnored let host: GameHost
    var mode: AtelierState.Mode?

    // Wege
    var pathIDs: [Int] = []
    var pathIndex = 0
    var progress = TraceProgress(strokeCount: 1)
    var samples: [[NPoint]] = []
    var demoPoint: NPoint?
    @ObservationIgnored private var lastPoint: NPoint?
    @ObservationIgnored private var solved = false
    @ObservationIgnored private var demoTask: Task<Void, Never>?

    // Freies Malen
    var drawing = PKDrawing()
    var background: CanvasBackground = .leer
    var color: Palette = .blue
    var width: CGFloat = 14
    var erasing = false
    var artworkID: UUID?
    @ObservationIgnored private var undoStack: [PKDrawing] = []
    @ObservationIgnored private var lastCommitted = PKDrawing()
    @ObservationIgnored private var canvasWidth: Double = 0
    var canUndo = false

    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var currentPath: AtelierPath? {
        guard let id = pathIDs[safe: pathIndex] else { return nil }
        return AtelierPaths.all.first { $0.id == id }
    }

    var tool: PKTool {
        if erasing { return PKEraserTool(.bitmap) }
        return PKInkingTool(.pen, color: color.uiColor, width: width)
    }

    var traceStyle: TraceStyle {
        switch host.difficulty {
        case .entdecken: return TraceStyle(trackWidth: 0.16, showCenterLine: true, showArrows: true, trackOpacity: 1.2)
        case .ueben: return TraceStyle(trackWidth: 0.12, showCenterLine: true, showArrows: true, trackOpacity: 1)
        case .knobeln: return TraceStyle(trackWidth: 0.09, showCenterLine: true, showArrows: false, trackOpacity: 0.8)
        }
    }

    private var tolerance: Double {
        switch host.difficulty {
        case .entdecken: return 0.09
        case .ueben: return 0.07
        case .knobeln: return 0.05
        }
    }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.nextPath() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Im Atelier gespielt.") }
            if self.mode == .free {
                return RoundSummary(text: "Ein Bild frei gemalt.", practiced: ["frei"])
            }
            return RoundSummary(text: "Drei Wege nachgefahren (\(self.host.difficulty.title)).", practiced: ["Wege \(self.host.difficulty.title)"])
        }

        // Ein Bild aus der Galerie weiterbearbeiten
        if let editID = host.app.editArtworkID, let art = host.app.gallery.first(where: { $0.id == editID }) {
            host.app.editArtworkID = nil
            loadArtwork(art)
            return
        }

        if let saved = host.takeRestoredPayload(AtelierState.self) {
            mode = saved.mode
            switch saved.mode {
            case .paths:
                pathIDs = saved.pathIDs
                pathIndex = min(saved.pathIndex, max(pathIDs.count - 1, 0))
                loadPath(keeping: saved.progress)
                if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
                if host.awaitingNext { host.next(); return }
                if progress.isComplete { completePath(); return }
            case .free:
                artworkID = saved.artworkID
                background = saved.background
                if let data = saved.drawing, let d = try? PKDrawing(data: data) {
                    drawing = d
                    lastCommitted = d
                }
                canvasWidth = saved.canvasWidth ?? 0
                host.setInstruction("Male weiter. Tippe auf «Fertig», wenn dein Bild fertig ist.")
            case .none:
                chooseInstruction()
            }
        } else {
            let modes = host.options.atelierModes
            if modes.count == 1, let only = modes.first, let m = AtelierState.Mode(rawValue: only) {
                choose(m)
            } else {
                chooseInstruction()
            }
        }
    }

    private func chooseInstruction() {
        host.setInstruction("Möchtest du Wege nachfahren oder frei malen?")
    }

    func choose(_ m: AtelierState.Mode) {
        mode = m
        switch m {
        case .paths:
            pathIDs = AtelierPaths.paths(for: host.difficulty).shuffled().prefix(host.tasksPerRound).map(\.id)
            pathIndex = 0
            loadPath(keeping: nil)
        case .free:
            drawing = PKDrawing()
            lastCommitted = drawing
            artworkID = nil
            undoStack = []
            canUndo = false
            save()
            host.setInstruction("Male, was du möchtest. Tippe auf «Fertig», wenn dein Bild fertig ist.")
        }
    }

    func leave() {
        demoTask?.cancel()
        if mode == .free && !drawing.strokes.isEmpty && !host.roundComplete {
            // Verlassen des Bildes: Es landet in der Galerie und kann später weiterbearbeitet werden.
            storeArtwork()
            save()
        }
    }

    private func save() {
        var state = AtelierState(mode: mode)
        state.pathIDs = pathIDs
        state.pathIndex = pathIndex
        state.progress = mode == .paths ? progress : nil
        state.artworkID = artworkID
        state.drawing = mode == .free ? drawing.dataRepresentation() : nil
        state.background = background
        state.canvasWidth = canvasWidth
        host.persist(state)
    }

    // MARK: Wege

    private func loadPath(keeping saved: TraceProgress?) {
        guard let path = currentPath else { return }
        samples = TraceShape(strokes: [path.points]).resampled()
        if let saved, saved.confirmed.count == samples.count {
            progress = saved
        } else {
            progress = TraceProgress(strokeCount: samples.count)
        }
        solved = false
        lastPoint = nil
        save()
        host.setInstruction(path.task)
    }

    private func nextPath() {
        pathIndex = min(pathIndex + 1, pathIDs.count - 1)
        loadPath(keeping: nil)
    }

    func feed(_ p: NPoint) {
        guard mode == .paths, !solved, !progress.isComplete else { return }
        if p.x < -5 {
            lastPoint = nil
            save()
            return
        }
        demoTask?.cancel()
        demoPoint = nil
        var points = [p]
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
        for q in points { progress.feed(q, samples: samples, tolerance: tolerance, lookahead: 8) }
        if progress.isComplete { completePath() }
    }

    private func completePath() {
        guard !solved, currentPath != nil else { return }
        solved = true
        save()
        host.taskSolved("Geschafft, du hast den Weg gefunden!")
    }

    // MARK: Freies Malen

    func canvasWidthChanged(_ w: CGFloat) {
        let newWidth = Double(w)
        guard newWidth > 0 else { return }
        if canvasWidth > 0, abs(canvasWidth - newWidth) > 1, !drawing.strokes.isEmpty {
            // Nach einer Drehung die Zeichnung an die neue Fläche anpassen.
            let s = newWidth / canvasWidth
            drawing = drawing.transformed(using: CGAffineTransform(scaleX: s, y: s))
            lastCommitted = drawing
            undoStack = []
            canUndo = false
        }
        canvasWidth = newWidth
    }

    func strokeFinished(_ d: PKDrawing) {
        undoStack.append(lastCommitted)
        if undoStack.count > 40 { undoStack.removeFirst() }
        lastCommitted = d
        canUndo = true
        save()
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        host.audio.effect(.tap)
        drawing = prev
        lastCommitted = prev
        canUndo = !undoStack.isEmpty
        save()
    }

    func selectColor(_ c: Palette) {
        host.audio.effect(.tap)
        color = c
        erasing = false
    }

    func selectWidth(_ w: CGFloat) {
        host.audio.effect(.tap)
        width = w
        erasing = false
    }

    func toggleEraser() {
        host.audio.effect(.tap)
        erasing.toggle()
    }

    func setBackground(_ bg: CanvasBackground) {
        host.audio.effect(.tap)
        background = bg
        save()
    }

    func finishDrawing() {
        guard !drawing.strokes.isEmpty else {
            host.showBunny("Dein Blatt ist noch leer. Male zuerst etwas.")
            return
        }
        storeArtwork()
        host.audio.say("Dein Bild ist in deiner Galerie.")
        host.finishRound()
    }

    private func loadArtwork(_ art: Artwork) {
        mode = .free
        artworkID = art.id
        background = CanvasBackground(rawValue: art.background) ?? .leer
        if let d = try? PKDrawing(data: art.drawing) {
            drawing = d
            lastCommitted = d
        }
        canvasWidth = art.canvasWidth ?? 0
        save()
        host.setInstruction("Male weiter an deinem Bild.")
    }

    /// Speichert bearbeitbare Striche und eine Vorschau. Leere Bilder erzeugen keinen Eintrag.
    private func storeArtwork() {
        guard !drawing.strokes.isEmpty else { return }
        let id = artworkID ?? UUID()
        artworkID = id
        let thumb = makeThumbnail()
        let existing = host.app.gallery.first { $0.id == id }
        let art = Artwork(
            id: id,
            created: existing?.created ?? Date(),
            modified: Date(),
            background: background.rawValue,
            drawing: drawing.dataRepresentation(),
            thumbnail: thumb,
            canvasWidth: canvasWidth
        )
        host.app.saveArtwork(art)
    }

    private func makeThumbnail() -> Data {
        let w = canvasWidth > 0 ? canvasWidth : 800
        let h = w * 3 / 4
        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        let strokes = drawing.image(from: rect, scale: 1)
        let view = ZStack {
            CanvasBackgroundView(background: background)
            Image(uiImage: strokes).resizable()
        }
        .frame(width: w, height: h)
        let renderer = ImageRenderer(content: view)
        renderer.scale = CGFloat(400 / w)
        return renderer.uiImage?.pngData() ?? Data()
    }

    // MARK: Hilfe

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        switch mode {
        case .none:
            choose(DemoMode.value("-atelier") == "free" ? .free : .paths)
        case .paths:
            guard !progress.isComplete, let pts = samples.first else { return }
            for p in pts { progress.feed(p, samples: samples, tolerance: 0.02, lookahead: 3) }
            if progress.isComplete { completePath() }
        case .free:
            if drawing.strokes.isEmpty {
                let points = (0..<40).map { i -> PKStrokePoint in
                    let t = Double(i) / 39
                    return PKStrokePoint(location: CGPoint(x: 120 + 420 * t, y: 220 + 90 * sin(t * 6)), timeOffset: t,
                                         size: CGSize(width: 14, height: 14), opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
                }
                let stroke = PKStroke(ink: PKInk(.pen, color: .systemBlue), path: PKStrokePath(controlPoints: points, creationDate: Date()))
                drawing = PKDrawing(strokes: [stroke])
                strokeFinished(drawing)
            } else {
                finishDrawing()
            }
        }
    }

    private func help(_ level: Int) {
        switch mode {
        case .none:
            host.showBunny("Tippe auf eines der grossen Bilder.")
        case .free:
            host.showBunny("Wähle eine Farbe und male mit dem Finger. Hier gibt es kein Richtig oder Falsch.")
        case .paths:
            guard !progress.isComplete else { return }
            let pts = samples[0]
            let from = max(0, progress.confirmed[0])
            switch level {
            case 1:
                host.showBunny("Beginne beim Tier und fahre den Weg entlang.")
                demo(from: from, to: min(pts.count - 1, from + pts.count / 3))
            case 2:
                host.showBunny("Schau, so geht der Weg.")
                demo(from: from, to: pts.count - 1)
            default:
                host.showBunny("Wir fahren den Weg gemeinsam.")
                demoTask?.cancel()
                demoTask = Task { @MainActor [weak self] in
                    guard let self else { return }
                    var i = from
                    while i < pts.count, !Task.isCancelled, !self.progress.isComplete {
                        self.demoPoint = pts[i]
                        self.progress.feed(pts[i], samples: self.samples, tolerance: 0.02, lookahead: 3)
                        i += 1
                        try? await Task.sleep(nanoseconds: 25_000_000)
                    }
                    self.demoPoint = nil
                    if self.progress.isComplete { self.completePath() }
                }
            }
        }
    }

    private func demo(from: Int, to: Int) {
        let pts = samples[0]
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
}
