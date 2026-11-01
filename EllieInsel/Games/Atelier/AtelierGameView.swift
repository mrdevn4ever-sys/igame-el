import SwiftUI

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
    var stickers: [PlacedSticker]?
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
                    Text(app.gallery.count == 1 ? "1 Bild" : "\(app.gallery.count) Bilder")
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

/// Freies Malen: Stifte, Glitzer, Füllen, Sticker, Radierer.
private struct FreeDrawingView: View {
    @Bindable var model: AtelierModel

    private let colors: [Palette] = [.red, .orange, .yellow, .green, .blue, .purple, .pink, .brown, .black]
    private let widths: [CGFloat] = [6, 14, 30]
    private let grid = [GridItem(.fixed(56), spacing: 6), GridItem(.fixed(56), spacing: 6)]

    var body: some View {
        HStack(spacing: 14) {
            leftPanel
            GeometryReader { geo in
                let w = min(geo.size.width, geo.size.height * 4 / 3)
                let h = w * 3 / 4
                ZStack(alignment: .topLeading) {
                    CanvasBackgroundView(background: model.background)
                    PaintCanvas(layer: model.layer, live: model.liveOp, scale: model.paintScale)
                        .frame(width: w, height: h)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                                .onChanged { v in model.paintDrag(v.location) }
                                .onEnded { _ in model.paintEnd() },
                            including: model.tool == .pen || model.tool == .eraser ? .all : .subviews
                        )
                    if model.tool == .fill || model.tool == .sticker {
                        // Fängt Tipper ab: füllen bzw. Sticker aufkleben
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture(coordinateSpace: .local) { p in
                                model.tapCanvas(at: p, size: CGSize(width: w, height: h))
                            }
                    }
                    ForEach(model.stickers) { s in
                        StickerView(sticker: s.sticker, size: s.size * w)
                            .position(x: s.x * w, y: s.y * h)
                            .gesture(
                                DragGesture(minimumDistance: 2, coordinateSpace: .named("atelierCanvas"))
                                    .onChanged { v in
                                        model.dragSticker(s.id, to: CGPoint(x: v.location.x / w, y: v.location.y / h))
                                    }
                                    .onEnded { _ in model.endStickerDrag() }
                            )
                            .onTapGesture {
                                if model.tool == .eraser { model.removeSticker(s.id) }
                            }
                            .allowsHitTesting(model.tool == .sticker || model.tool == .eraser)
                    }
                }
                .frame(width: w, height: h)
                .coordinateSpace(name: "atelierCanvas")
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.12), radius: 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear { model.canvasWidthChanged(w) }
                .onChange(of: w) { _, nw in model.canvasWidthChanged(nw) }
            }
            sideActions
        }
    }

    // MARK: Linke Leiste: Farben oder Sticker

    @ViewBuilder
    private var leftPanel: some View {
        ScrollView(showsIndicators: false) {
            if model.tool == .sticker {
                stickerPanel
            } else {
                colorPanel
            }
        }
        .frame(width: 124)
    }

    private var colorPanel: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: grid, spacing: 6) {
                ForEach(colors, id: \.self) { c in
                    Button { model.selectInk(.plain(c)) } label: {
                        InkSwatch(ink: .plain(c), selected: model.ink == .plain(c) && model.tool != .eraser)
                    }
                    .accessibilityLabel("Farbe \(c.name)")
                }
            }
            Label("Glitzer", systemImage: "sparkles")
                .font(Theme.rounded(17, .bold))
                .foregroundStyle(Theme.darkGreen)
                .padding(.top, 4)
            LazyVGrid(columns: grid, spacing: 6) {
                ForEach(Glitter.allCases, id: \.self) { g in
                    Button { model.selectInk(.glitter(g)) } label: {
                        InkSwatch(ink: .glitter(g), selected: model.ink == .glitter(g) && model.tool != .eraser)
                    }
                    .accessibilityLabel(g.name)
                }
            }
            if model.tool != .fill {
                Divider().frame(width: 100).padding(.vertical, 2)
                HStack(spacing: 4) {
                    ForEach(widths, id: \.self) { w in
                        Button { model.selectWidth(w) } label: {
                            Circle()
                                .fill(Theme.darkGreen)
                                .frame(width: min(w, 28) + 4, height: min(w, 28) + 4)
                                .frame(width: 38, height: 48)
                                .background(RoundedRectangle(cornerRadius: 12).fill(model.width == w ? Theme.highlight.opacity(0.5) : .white))
                        }
                        .accessibilityLabel(w < 10 ? "Dünn" : w < 20 ? "Mittel" : "Dick")
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var stickerPanel: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(StickerCatalog.sizes.indices, id: \.self) { i in
                    Button { model.selectStickerSize(i) } label: {
                        Image(systemName: "star.fill")
                            .font(.system(size: ([14, 20, 28] as [CGFloat])[i]))
                            .foregroundStyle(Theme.darkGreen)
                            .frame(width: 38, height: 48)
                            .background(RoundedRectangle(cornerRadius: 12).fill(model.stickerSizeIndex == i ? Theme.highlight.opacity(0.5) : .white))
                    }
                    .accessibilityLabel(["Klein", "Mittel", "Gross"][i])
                }
            }
            LazyVGrid(columns: grid, spacing: 6) {
                ForEach(StickerCatalog.all, id: \.self) { s in
                    Button { model.selectSticker(s) } label: {
                        StickerView(sticker: s, size: 44)
                            .frame(width: 56, height: 56)
                            .background(RoundedRectangle(cornerRadius: 14).fill(model.selectedSticker == s ? Theme.highlight.opacity(0.5) : .white))
                    }
                    .accessibilityLabel("Sticker")
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: Rechte Leiste: Werkzeuge

    private func toolButton(_ t: AtelierModel.DrawTool, _ icon: String, _ label: String) -> some View {
        CircleIconButton(systemName: icon, label: label,
                         tint: model.tool == t ? .white : Theme.darkGreen,
                         background: model.tool == t ? Theme.darkGreen : .white,
                         size: 56) {
            model.selectTool(t)
        }
    }

    private var sideActions: some View {
        VStack(spacing: 10) {
            toolButton(.pen, "pencil.tip", "Malen")
            toolButton(.fill, "drop.fill", "Füllen")
            toolButton(.sticker, "star.fill", "Sticker")
            toolButton(.eraser, "eraser.fill", "Radierer")
            CircleIconButton(systemName: "arrow.uturn.backward", label: "Rückgängig", size: 56) {
                model.undo()
            }
            .opacity(model.canUndo ? 1 : 0.4)
            Menu {
                ForEach(CanvasBackground.allCases, id: \.self) { bg in
                    Button("\(bg.icon) \(bg.title)") { model.setBackground(bg) }
                }
            } label: {
                Text(model.background.icon)
                    .font(.system(size: 26))
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(.white).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
            }
            .accessibilityLabel("Hintergrund wählen")
            Spacer(minLength: 4)
            Button {
                model.finishDrawing()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill").font(.system(size: 30))
                    Text("Fertig").font(Theme.rounded(19, .bold))
                }
                .foregroundStyle(.white)
                .frame(width: 92, height: 86)
                .background(RoundedRectangle(cornerRadius: 24).fill(Theme.success))
            }
            .buttonStyle(PressableStyle())
        }
        .frame(width: 96)
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
    enum DrawTool { case pen, fill, sticker, eraser }
    struct Snapshot {
        var ops: [PaintOp]
        var stickers: [PlacedSticker]
    }
    /// Das Bild als Liste von Malaktionen (Koordinaten in der Referenzbreite `doc.width`)
    var doc = PaintDoc(width: 800)
    /// Fertig gerendertes Bild aller Aktionen in Zeichenflächengrösse
    var layer: UIImage?
    /// Strich, der gerade entsteht
    var liveOp: PaintOp?
    var background: CanvasBackground = .leer
    var ink: InkChoice = .plain(.blue)
    var width: CGFloat = 14
    var tool: DrawTool = .pen
    var stickers: [PlacedSticker] = []
    var selectedSticker = StickerCatalog.all[0]
    var stickerSizeIndex = 1
    var artworkID: UUID?
    @ObservationIgnored private var draggingSticker: UUID?
    @ObservationIgnored private var undoStack: [Snapshot] = []
    @ObservationIgnored private var canvasWidth: Double = 0
    var canUndo = false

    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var currentPath: AtelierPath? {
        guard let id = pathIDs[safe: pathIndex] else { return nil }
        return AtelierPaths.all.first { $0.id == id }
    }

    /// Faktor von Bildkoordinaten zur aktuellen Zeichenfläche
    var paintScale: CGFloat { CGFloat(canvasWidth > 0 ? canvasWidth / max(doc.width, 1) : 1) }
    var canvasSize: CGSize { CGSize(width: canvasWidth, height: canvasWidth * 3 / 4) }

    var spec: LevelCatalog.AtelierSpec { LevelCatalog.atelier(host.level) }

    var traceStyle: TraceStyle {
        TraceStyle(trackWidth: spec.width, showCenterLine: true, showArrows: spec.showArrows, trackOpacity: host.level <= 2 ? 1.2 : 1)
    }

    private var tolerance: Double { spec.tolerance }

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
            return RoundSummary(text: "Drei Wege nachgefahren (Niveau \(self.host.level)).", practiced: ["Wege Niveau \(self.host.level)"])
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
                canvasWidth = saved.canvasWidth ?? 0
                doc = PaintDoc.decode(saved.drawing, fallbackWidth: canvasWidth)
                stickers = saved.stickers ?? []
                rerender()
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
            pathIDs = AtelierPaths.paths(for: spec.pathLevel).shuffled().prefix(host.tasksPerRound).map(\.id)
            pathIndex = 0
            loadPath(keeping: nil)
        case .free:
            doc = PaintDoc(width: canvasWidth > 0 ? canvasWidth : 800)
            layer = nil
            liveOp = nil
            stickers = []
            artworkID = nil
            undoStack = []
            canUndo = false
            save()
            host.setInstruction("Male, was du möchtest. Tippe auf «Fertig», wenn dein Bild fertig ist.")
        }
    }

    func leave() {
        demoTask?.cancel()
        if mode == .free && !isBlank && !host.roundComplete {
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
        state.drawing = mode == .free ? doc.encoded() : nil
        state.background = background
        state.canvasWidth = canvasWidth
        state.stickers = mode == .free ? stickers : nil
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
        if doc.ops.isEmpty { doc.width = newWidth }
        if abs(canvasWidth - newWidth) > 0.5 || layer == nil {
            // Nach einer Drehung einfach neu zeichnen; die Koordinaten skalieren mit.
            canvasWidth = newWidth
            rerender()
        }
    }

    var isBlank: Bool { doc.ops.isEmpty && stickers.isEmpty }

    private func pushUndo() {
        undoStack.append(Snapshot(ops: doc.ops, stickers: stickers))
        if undoStack.count > 40 { undoStack.removeFirst() }
        canUndo = true
    }

    /// Ganzes Bild neu rendern (nach Laden, Drehen, Rückgängig).
    private func rerender() {
        guard canvasWidth > 0 else { return }
        layer = doc.ops.isEmpty ? nil : PaintRenderer.render(doc.ops, base: nil, size: canvasSize, scale: paintScale)
    }

    /// Eine fertige Aktion übernehmen: nur sie wird auf das bestehende Bild gezeichnet.
    private func commit(_ op: PaintOp) {
        pushUndo()
        doc.ops.append(op)
        layer = PaintRenderer.render([op], base: layer, size: canvasSize, scale: paintScale) ?? layer
        save()
    }

    // MARK: Malen mit dem Finger

    func paintDrag(_ p: CGPoint) {
        guard tool == .pen || tool == .eraser, canvasWidth > 0 else { return }
        let s = paintScale
        let q = CGPoint(x: p.x / s, y: p.y / s)
        if liveOp == nil {
            let (r, g, b, gl) = PaintOp.ink(ink)
            liveOp = PaintOp(kind: tool == .eraser ? .erase : .line, r: r, g: g, b: b,
                             glitter: tool == .eraser ? nil : gl,
                             width: Double((tool == .eraser ? max(width, 24) : width) / s),
                             pts: [Double(q.x), Double(q.y)], seed: UInt64.random(in: 1...UInt64.max))
            return
        }
        guard var op = liveOp else { return }
        let n = op.pts.count
        let last = CGPoint(x: op.pts[n - 2], y: op.pts[n - 1])
        guard hypot(q.x - last.x, q.y - last.y) >= 1.2 / s else { return }
        op.pts += [Double(q.x), Double(q.y)]
        liveOp = op
    }

    func paintEnd() {
        guard let op = liveOp else { return }
        liveOp = nil
        commit(op)
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        host.audio.effect(.tap)
        doc.ops = prev.ops
        stickers = prev.stickers
        canUndo = !undoStack.isEmpty
        rerender()
        save()
    }

    func selectInk(_ i: InkChoice) {
        host.audio.effect(.tap)
        ink = i
        if tool == .eraser || tool == .sticker { tool = .pen }
    }

    func selectWidth(_ w: CGFloat) {
        host.audio.effect(.tap)
        width = w
        if tool != .pen { tool = .pen }
    }

    func selectTool(_ t: DrawTool) {
        host.audio.effect(.tap)
        tool = t
        switch t {
        case .fill: host.showBunny("Tippe in eine Fläche, dann wird sie ausgemalt.", seconds: 3)
        case .sticker: host.showBunny("Wähle einen Sticker und tippe auf dein Bild.", seconds: 3)
        default: break
        }
    }

    // MARK: Füllen und Sticker

    func tapCanvas(at p: CGPoint, size: CGSize) {
        switch tool {
        case .fill: fill(at: p, size: size)
        case .sticker: placeSticker(at: p, size: size)
        default: break
        }
    }

    private func fill(at p: CGPoint, size: CGSize) {
        let runs = FloodFill.runs(image: layer, size: size, at: p)
        guard !runs.isEmpty else { return }
        let s = Double(paintScale)
        var flat: [Double] = []
        flat.reserveCapacity(runs.count * 3)
        for r in runs { flat += [Double(r.y) / s, Double(r.x0) / s, Double(r.x1) / s] }
        let (r, g, b, gl) = PaintOp.ink(ink)
        commit(PaintOp(kind: .fill, r: r, g: g, b: b, glitter: gl, runs: flat, step: 3 / s, seed: UInt64.random(in: 1...UInt64.max)))
        host.audio.effect(.snap)
    }

    func selectSticker(_ s: String) {
        host.audio.effect(.tap)
        selectedSticker = s
    }

    func selectStickerSize(_ i: Int) {
        host.audio.effect(.tap)
        stickerSizeIndex = i
    }

    private func placeSticker(at p: CGPoint, size: CGSize) {
        guard size.width > 0, size.height > 0, stickers.count < 80 else { return }
        pushUndo()
        stickers.append(PlacedSticker(sticker: selectedSticker, x: Double(p.x / size.width), y: Double(p.y / size.height),
                                      size: StickerCatalog.sizes[stickerSizeIndex]))
        host.audio.effect(.snap)
        save()
    }

    func dragSticker(_ id: UUID, to p: CGPoint) {
        guard tool == .sticker, let idx = stickers.firstIndex(where: { $0.id == id }) else { return }
        if draggingSticker != id {
            pushUndo()
            draggingSticker = id
        }
        stickers[idx].x = min(max(Double(p.x), 0), 1)
        stickers[idx].y = min(max(Double(p.y), 0), 1)
    }

    func endStickerDrag() {
        guard draggingSticker != nil else { return }
        draggingSticker = nil
        save()
    }

    func removeSticker(_ id: UUID) {
        guard stickers.contains(where: { $0.id == id }) else { return }
        pushUndo()
        stickers.removeAll { $0.id == id }
        host.audio.effect(.tap)
        save()
    }

    func setBackground(_ bg: CanvasBackground) {
        host.audio.effect(.tap)
        background = bg
        save()
    }

    func finishDrawing() {
        guard !isBlank else {
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
        doc = PaintDoc.decode(art.drawing, fallbackWidth: art.canvasWidth ?? canvasWidth)
        stickers = art.stickers ?? []
        rerender()
        save()
        host.setInstruction("Male weiter an deinem Bild.")
    }

    /// Speichert bearbeitbare Striche und eine Vorschau. Leere Bilder erzeugen keinen Eintrag.
    private func storeArtwork() {
        guard !isBlank else { return }
        let id = artworkID ?? UUID()
        artworkID = id
        let thumb = makeThumbnail()
        let existing = host.app.gallery.first { $0.id == id }
        let art = Artwork(
            id: id,
            created: existing?.created ?? Date(),
            modified: Date(),
            background: background.rawValue,
            drawing: doc.encoded(),
            thumbnail: thumb,
            canvasWidth: canvasWidth,
            stickers: stickers
        )
        host.app.saveArtwork(art)
    }

    private func makeThumbnail() -> Data {
        let w = canvasWidth > 0 ? canvasWidth : 800
        let h = w * 3 / 4
        let size = CGSize(width: w, height: h)
        let picture = layer ?? PaintRenderer.render(doc.ops, base: nil, size: size, scale: CGFloat(w / max(doc.width, 1)))
        let view = ZStack(alignment: .topLeading) {
            CanvasBackgroundView(background: background)
            if let picture { Image(uiImage: picture).resizable() }
            StickerLayer(stickers: stickers, size: size)
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
            if doc.ops.isEmpty {
                // Vorführbild: Kreis mit Goldglitzer gefüllt, Regenbogenglitzer-Welle, zwei Sticker
                let w = canvasWidth > 0 ? CGFloat(canvasWidth) : 800
                let h = w * 3 / 4
                let s = paintScale
                let c = CGPoint(x: w * 0.3, y: h * 0.45), r = h * 0.25
                let circle = (0...60).flatMap { i -> [Double] in
                    let a = Double(i) / 60 * 2 * .pi
                    return [Double((c.x + r * CGFloat(cos(a))) / s), Double((c.y + r * CGFloat(sin(a))) / s)]
                }
                let wave = (0..<40).flatMap { i -> [Double] in
                    let t = Double(i) / 39
                    return [Double((w * 0.55 + w * 0.38 * CGFloat(t)) / s), Double((h * 0.75 + 40 * CGFloat(sin(t * 8))) / s)]
                }
                let (br, bg, bb, _) = PaintOp.ink(.plain(.black))
                commit(PaintOp(kind: .line, r: br, g: bg, b: bb, width: Double(10 / s), pts: circle, seed: 3))
                ink = .glitter(.gold)
                fill(at: c, size: CGSize(width: w, height: h))
                let gl = Glitter.regenbogen
                commit(PaintOp(kind: .line, r: gl.rgb.0, g: gl.rgb.1, b: gl.rgb.2, glitter: gl, width: Double(30 / s), pts: wave, seed: 7))
                stickers.append(PlacedSticker(sticker: "garten_schmetterling", x: 0.72, y: 0.3, size: 0.18))
                stickers.append(PlacedSticker(sticker: "🦄", x: 0.88, y: 0.12, size: 0.12))
                save()
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
            host.showBunny("Wähle eine Farbe und male mit dem Finger. Mit dem Tropfen malst du ganze Flächen aus, mit dem Stern klebst du Sticker. Hier gibt es kein Richtig oder Falsch.")
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
