import SwiftUI
import UIKit

struct PuzzleScene: Codable, Equatable {
    var animal: String
    var name: String
    var habitat: String
    var decor: [String]
}

enum PuzzleCatalog {
    /// Zwölf Illustrationen aus Wald, Wiese, Wasser und Bauernhof.
    static let scenes: [PuzzleScene] = [
        PuzzleScene(animal: "🦊", name: "Fuchs", habitat: "Wald", decor: ["🌲", "🍄", "🌲"]),
        PuzzleScene(animal: "🦉", name: "Eule", habitat: "Wald", decor: ["🌙", "🌲", "⭐️"]),
        PuzzleScene(animal: "🐻", name: "Bär", habitat: "Wald", decor: ["🌲", "🍯", "🌳"]),
        PuzzleScene(animal: "🐇", name: "Hase", habitat: "Wiese", decor: ["🌼", "🥕", "🌷"]),
        PuzzleScene(animal: "🦋", name: "Schmetterling", habitat: "Wiese", decor: ["🌸", "☀️", "🌼"]),
        PuzzleScene(animal: "🐞", name: "Marienkäfer", habitat: "Wiese", decor: ["🍀", "🌻", "🌿"]),
        PuzzleScene(animal: "🐸", name: "Frosch", habitat: "Wasser", decor: ["🪷", "💧", "🌿"]),
        PuzzleScene(animal: "🦆", name: "Ente", habitat: "Wasser", decor: ["🌾", "💧", "☀️"]),
        PuzzleScene(animal: "🐟", name: "Fisch", habitat: "Wasser", decor: ["🫧", "🐚", "🌿"]),
        PuzzleScene(animal: "🐄", name: "Kuh", habitat: "Bauernhof", decor: ["🏡", "🌾", "☀️"]),
        PuzzleScene(animal: "🐖", name: "Schwein", habitat: "Bauernhof", decor: ["🌻", "🏡", "🌾"]),
        PuzzleScene(animal: "🐓", name: "Hahn", habitat: "Bauernhof", decor: ["☀️", "🌾", "🥚"])
    ]
}

/// Gemalte Szene, die für das Puzzle in ein Bild umgewandelt wird.
struct PuzzleSceneView: View {
    let scene: PuzzleScene

    var colors: [Color] {
        switch scene.habitat {
        case "Wald": return [Color(red: 0.75, green: 0.88, blue: 0.80), Color(red: 0.45, green: 0.68, blue: 0.48)]
        case "Wiese": return [Color(red: 0.80, green: 0.92, blue: 0.98), Color(red: 0.62, green: 0.84, blue: 0.48)]
        case "Wasser": return [Color(red: 0.78, green: 0.92, blue: 0.99), Color(red: 0.42, green: 0.70, blue: 0.90)]
        default: return [Color(red: 0.99, green: 0.93, blue: 0.80), Color(red: 0.80, green: 0.75, blue: 0.48)]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom)
            Ellipse()
                .fill(.white.opacity(0.35))
                .frame(width: 420, height: 120)
                .offset(y: 150)
            Text(scene.decor[0]).font(.system(size: 110)).offset(x: -200, y: -70)
            Text(scene.decor[1]).font(.system(size: 80)).offset(x: 210, y: -120)
            Text(scene.decor[2]).font(.system(size: 95)).offset(x: 205, y: 105)
            Text(scene.animal).font(.system(size: 230)).offset(y: 20)
        }
        .frame(width: 600, height: 400)
        .clipped()
    }
}

@MainActor
enum PuzzleImageCache {
    private static var cache: [String: UIImage] = [:]

    static func image(for scene: PuzzleScene) -> UIImage? {
        if let img = cache[scene.name] { return img }
        // Mitgelieferte Illustration (z. B. `puzzle_fuchs.png`, Seitenverhältnis 3:2) bevorzugen.
        if let provided = UIImage(named: "puzzle_" + scene.name.voiceSlug) {
            cache[scene.name] = provided
            return provided
        }
        let renderer = ImageRenderer(content: PuzzleSceneView(scene: scene))
        renderer.scale = 2
        guard let img = renderer.uiImage else { return nil }
        cache[scene.name] = img
        return img
    }

    static func tile(_ image: UIImage, index: Int, rows: Int, cols: Int) -> UIImage? {
        guard let cg = image.cgImage else { return nil }
        let w = CGFloat(cg.width) / CGFloat(cols)
        let h = CGFloat(cg.height) / CGFloat(rows)
        let r = index / cols, c = index % cols
        let rect = CGRect(x: CGFloat(c) * w, y: CGFloat(r) * h, width: w, height: h).integral
        guard let cut = cg.cropping(to: rect) else { return nil }
        return UIImage(cgImage: cut, scale: image.scale, orientation: .up)
    }
}

struct PuzzleState: Codable {
    var sceneIndex: Int
    var pieces: Int
    var placed: [Int]
    var trayOrder: [Int]
    var previewDone: Bool
}

/// Spiel 11: Tierpuzzle.
struct PuzzleGameView: View {
    let host: GameHost
    @State private var model: PuzzleModel
    @State private var dragging: Int?
    @State private var dragLocation: CGPoint = .zero

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: PuzzleModel(host: host))
    }

    var body: some View {
        GeometryReader { geo in
            let boardW = min(geo.size.width * 0.58, geo.size.height * 1.5 * 0.95)
            let boardH = boardW / 1.5
            let board = CGRect(x: 10, y: (geo.size.height - boardH) / 2, width: boardW, height: boardH)
            let tray = CGRect(x: board.maxX + 30, y: 10, width: geo.size.width - board.maxX - 40, height: geo.size.height - 20)
            let cellW = board.width / CGFloat(model.cols)
            let cellH = board.height / CGFloat(model.rows)

            ZStack(alignment: .topLeading) {
                // Zielfläche
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white)
                    .frame(width: board.width, height: board.height)
                    .offset(x: board.minX, y: board.minY)
                    .shadow(color: .black.opacity(0.1), radius: 8)

                if let img = model.image {
                    Image(uiImage: img)
                        .resizable()
                        .frame(width: board.width, height: board.height)
                        .opacity(model.showingPreview || model.complete ? 1 : (model.showTemplate ? 0.25 : 0))
                        .offset(x: board.minX, y: board.minY)
                        .animation(.easeInOut(duration: 0.6), value: model.showingPreview)
                }

                // Raster und platzierte Teile
                ForEach(0..<model.pieces, id: \.self) { i in
                    let r = i / model.cols, c = i % model.cols
                    let rect = CGRect(x: board.minX + CGFloat(c) * cellW, y: board.minY + CGFloat(r) * cellH, width: cellW, height: cellH)
                    ZStack {
                        if model.placed.contains(i), let tile = model.tiles[safe: i] {
                            Image(uiImage: tile).resizable()
                        } else if !model.showingPreview {
                            Rectangle()
                                .stroke(Theme.darkGreen.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                                .background(hoverCell(i, rect: rect) ? Theme.highlight.opacity(0.35) : Color.clear)
                        }
                    }
                    .frame(width: rect.width, height: rect.height)
                    .pulseHighlight(model.hintCell == i)
                    .offset(x: rect.minX, y: rect.minY)
                    .onTapGesture { model.tapCell(i) }
                }

                // Teile neben der Zielfläche
                if !model.showingPreview {
                    let trayCols = model.pieces <= 4 ? 2 : 3
                    let trayRows = Int(ceil(Double(model.pieces) / Double(trayCols)))
                    let slotW = tray.width / CGFloat(trayCols)
                    let slotH = tray.height / CGFloat(trayRows)
                    let scale = min(slotW * 0.85 / cellW, slotH * 0.85 / cellH, 1)
                    ForEach(Array(model.trayOrder.enumerated()), id: \.element) { pos, i in
                        if !model.placed.contains(i), let tile = model.tiles[safe: i] {
                            let home = CGPoint(x: tray.minX + slotW * (CGFloat(pos % trayCols) + 0.5),
                                               y: tray.minY + slotH * (CGFloat(pos / trayCols) + 0.5))
                            let isDragging = dragging == i
                            Image(uiImage: tile)
                                .resizable()
                                .frame(width: cellW, height: cellH)
                                .overlay(Rectangle().stroke(Theme.highlight, lineWidth: model.selected == i ? 6 : 1))
                                .shadow(color: .black.opacity(0.2), radius: isDragging ? 8 : 3)
                                .pulseHighlight(model.hintPiece == i)
                                .scaleEffect(isDragging ? 1 : scale)
                                .position(isDragging ? dragLocation : home)
                                .zIndex(isDragging ? 10 : 1)
                                .gesture(
                                    DragGesture(minimumDistance: 4, coordinateSpace: .named("puzzle"))
                                        .onChanged { v in
                                            dragging = i
                                            dragLocation = v.location
                                        }
                                        .onEnded { v in
                                            let target = cellIndex(at: v.location, board: board, cellW: cellW, cellH: cellH)
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                dragging = nil
                                                if let target { model.drop(piece: i, on: target) }
                                            }
                                        }
                                )
                                .simultaneousGesture(TapGesture().onEnded { model.select(i) })
                                .accessibilityLabel("Puzzleteil \(pos + 1)")
                        }
                    }
                }
            }
            .coordinateSpace(name: "puzzle")
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }

    private func hoverCell(_ i: Int, rect: CGRect) -> Bool {
        guard let d = dragging, d == i else { return false }
        return rect.insetBy(dx: -rect.width * 0.25, dy: -rect.height * 0.25).contains(dragLocation)
    }

    /// Grosszügige Einrasttoleranz: Zelle unter dem Finger (mit Rand).
    private func cellIndex(at p: CGPoint, board: CGRect, cellW: CGFloat, cellH: CGFloat) -> Int? {
        let expanded = board.insetBy(dx: -cellW * 0.3, dy: -cellH * 0.3)
        guard expanded.contains(p) else { return nil }
        let c = min(max(Int((p.x - board.minX) / cellW), 0), model.cols - 1)
        let r = min(max(Int((p.y - board.minY) / cellH), 0), model.rows - 1)
        return r * model.cols + c
    }
}

@MainActor
@Observable
final class PuzzleModel {
    @ObservationIgnored let host: GameHost
    var sceneIndex = 0
    var pieces = 4
    var placed: [Int] = []
    var trayOrder: [Int] = []
    var showingPreview = true
    var showTemplate = false
    var selected: Int?
    var hintCell: Int?
    var hintPiece: Int?
    var image: UIImage?
    var tiles: [UIImage] = []
    @ObservationIgnored private var started = false
    @ObservationIgnored private var previewTask: Task<Void, Never>?

    init(host: GameHost) { self.host = host }

    var rows: Int { pieces == 4 ? 2 : pieces == 6 ? 2 : 3 }
    var cols: Int { pieces == 4 ? 2 : 3 }
    var complete: Bool { placed.count == pieces }
    var scene: PuzzleScene { PuzzleCatalog.scenes[sceneIndex % PuzzleCatalog.scenes.count] }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Ein Puzzle zusammengesetzt.") }
            return RoundSummary(text: "Puzzle «\(self.scene.name)» mit \(NumberWords.word(self.pieces)) Teilen zusammengesetzt.",
                                practiced: ["Puzzle mit \(self.pieces) Teilen"])
        }
        if let saved = host.takeRestoredPayload(PuzzleState.self) {
            sceneIndex = saved.sceneIndex
            pieces = saved.pieces
            placed = saved.placed
            trayOrder = saved.trayOrder
            showingPreview = !saved.previewDone
            prepareImage()
            if complete { host.resumeIfNeeded(); return }
            if showingPreview { runPreview() } else { host.setInstruction("Setz das Bild wieder zusammen.") }
        } else {
            switch host.difficulty {
            case .entdecken: pieces = 4
            case .ueben: pieces = 6
            case .knobeln: pieces = 9
            }
            let done = host.app.data.roundsCompleted[GameID.puzzle.rawValue] ?? 0
            sceneIndex = (done + Int.random(in: 0..<3)) % PuzzleCatalog.scenes.count
            placed = []
            trayOrder = Array(0..<pieces).shuffled()
            showingPreview = true
            prepareImage()
            runPreview()
        }
    }

    func stop() { previewTask?.cancel() }

    private func prepareImage() {
        image = PuzzleImageCache.image(for: scene)
        if let image {
            tiles = (0..<pieces).compactMap { PuzzleImageCache.tile(image, index: $0, rows: rows, cols: cols) }
        }
    }

    /// Zunächst ist das ganze Bild zu sehen, danach liegen die Teile bereit.
    private func runPreview() {
        save()
        host.setInstruction("Schau dir das Bild genau an. Das ist \(article) \(scene.name).")
        previewTask?.cancel()
        previewTask = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.host.audio.waitUntilQuiet()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring()) { self.showingPreview = false }
            self.save()
            self.host.setInstruction("Jetzt setz das Bild zusammen. Zieh ein Teil an seinen Platz.")
        }
    }

    private var article: String {
        switch scene.name {
        case "Eule", "Ente", "Kuh": return "die"
        case "Schwein": return "das"
        default: return "der"
        }
    }

    private func save() {
        host.persist(PuzzleState(sceneIndex: sceneIndex, pieces: pieces, placed: placed, trayOrder: trayOrder, previewDone: !showingPreview))
    }

    func select(_ i: Int) {
        guard !placed.contains(i) else { return }
        host.audio.effect(.tap)
        selected = selected == i ? nil : i
    }

    func tapCell(_ cell: Int) {
        guard let piece = selected else { return }
        drop(piece: piece, on: cell)
    }

    func drop(piece: Int, on cell: Int) {
        guard !placed.contains(piece) else { return }
        selected = nil
        if piece == cell {
            placed.append(piece)
            hintCell = nil
            hintPiece = nil
            host.audio.effect(.snap)
            save()
            if complete {
                host.taskSolved("Das ganze Bild ist fertig: \(article) \(scene.name)!", needsNext: false)
            }
        } else {
            host.audio.effect(.gentle)
            host.showBunny("Dieses Teil gehört woanders hin.", speak: true, seconds: 2.5)
        }
    }

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        guard !showingPreview, let next = trayOrder.first(where: { !placed.contains($0) }) else { return }
        drop(piece: next, on: next)
    }

    private func help(_ level: Int) {
        guard let next = trayOrder.first(where: { !placed.contains($0) }) else { return }
        switch level {
        case 1:
            showTemplate = true
            host.showBunny("Ich zeige dir das Bild ganz hell im Hintergrund.")
        case 2:
            showTemplate = true
            hintPiece = next
            hintCell = next
            host.showBunny("Dieses Teil gehört hierhin.")
        default:
            host.showBunny("Wir legen ein Teil gemeinsam.")
            withAnimation(.spring()) { drop(piece: next, on: next) }
        }
    }
}
