import SwiftUI

struct ShapeBoard: Codable, Equatable {
    var slots: [ShapeKind]
    /// Reihenfolge der beweglichen Formen unten (Indizes in `slots`).
    var pieceOrder: [Int]
    var colors: [Palette]
}

enum ShapeBoards {
    /// 36 Spielfelder, zwölf pro Stufe, reproduzierbar erzeugt.
    static func boards(for difficulty: Difficulty) -> [ShapeBoard] {
        var rng = SeededGenerator(seed: difficulty == .entdecken ? 11 : difficulty == .ueben ? 22 : 33)
        var result: [ShapeBoard] = []
        let palette: [Palette] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        while result.count < 12 {
            var kinds: [ShapeKind]
            switch difficulty {
            case .entdecken:
                // Deutlich unterschiedliche Formen
                let pool: [ShapeKind] = [.circle, .square, .triangle, .star]
                kinds = Array(pool.shuffled(using: &rng).prefix(result.count % 2 == 0 ? 2 : 3))
            case .ueben:
                let pool: [ShapeKind] = [.circle, .square, .triangle, .rectangle, .star, .oval]
                kinds = Array(pool.shuffled(using: &rng).prefix(result.count % 2 == 0 ? 3 : 4))
            case .knobeln:
                // Ähnlichere Konturen: Kreis/Oval und Quadrat/Rechteck gemeinsam
                var base: [ShapeKind] = [.circle, .oval, .square, .rectangle]
                let extra: [ShapeKind] = [.triangle, .star]
                if result.count % 2 == 1 { base.append(extra[result.count % 4 == 1 ? 0 : 1]) }
                kinds = base.shuffled(using: &rng)
            }
            let order = Array(kinds.indices).shuffled(using: &rng)
            let colors = Array(palette.shuffled(using: &rng).prefix(kinds.count))
            let board = ShapeBoard(slots: kinds, pieceOrder: order, colors: colors)
            if !result.contains(board) { result.append(board) }
        }
        return result
    }
}

struct ShapesState: Codable {
    var boards: [ShapeBoard]
    var index: Int
    var filled: [Int]
}

/// Spiel 6: Formenhaus.
struct ShapesGameView: View {
    let host: GameHost
    @State private var model: ShapesModel
    @State private var dragging: Int?
    @State private var dragLocation: CGPoint = .zero
    @State private var shakeToken = 0

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: ShapesModel(host: host))
    }

    var body: some View {
        GeometryReader { geo in
            if let board = model.board {
                let layout = ShapesLayout(size: geo.size, count: board.slots.count)
                ZStack {
                    houseBackground(layout)
                    // Aussparungen
                    ForEach(board.slots.indices, id: \.self) { i in
                        let filled = model.filled.contains(i)
                        let hover = isHover(slot: i, board: board, layout: layout)
                        ZStack {
                            if filled {
                                ShapeTile(kind: board.slots[i], size: layout.shapeSize, color: board.colors[i].color)
                            } else {
                                ShapeTile(kind: board.slots[i], size: layout.shapeSize, outlineOnly: true)
                            }
                        }
                        .frame(width: layout.shapeSize * 1.2, height: layout.shapeSize * 1.2)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(hover || (model.selected != nil && !filled) ? Theme.highlight.opacity(hover ? 0.45 : 0.15) : Color.white.opacity(0.6))
                        )
                        .pulseHighlight(model.hintSlot == i)
                        .position(layout.slot(i))
                        .onTapGesture { model.tapSlot(i) }
                        .accessibilityLabel(filled ? "\(board.slots[i].name) eingesetzt" : "Öffnung")
                    }
                    // Bewegliche Formen
                    ForEach(Array(board.pieceOrder.enumerated()), id: \.element) { pos, slotIndex in
                        if !model.filled.contains(slotIndex) {
                            let home = layout.piece(pos)
                            let isDragging = dragging == slotIndex
                            ShapeTile(kind: board.slots[slotIndex], size: layout.shapeSize, color: board.colors[slotIndex].color)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Theme.highlight, lineWidth: model.selected == slotIndex ? 6 : 0)
                                )
                                .pulseHighlight(model.hintPiece == slotIndex)
                                .scaleEffect(isDragging ? 1.1 : 1)
                                .position(isDragging ? dragLocation : home)
                                .gesture(
                                    DragGesture(minimumDistance: 4, coordinateSpace: .named("shapes"))
                                        .onChanged { v in
                                            dragging = slotIndex
                                            dragLocation = v.location
                                        }
                                        .onEnded { v in
                                            let target = layout.nearestSlot(to: v.location)
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                                dragging = nil
                                                if let target {
                                                    model.drop(piece: slotIndex, on: target)
                                                }
                                            }
                                        }
                                )
                                .simultaneousGesture(TapGesture().onEnded { model.select(slotIndex) })
                                .zIndex(isDragging ? 10 : 1)
                                .accessibilityLabel("\(board.slots[slotIndex].name), \(board.colors[slotIndex].name)")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .coordinateSpace(name: "shapes")
            }
        }
        .onAppear { model.start() }
    }

    private func isHover(slot: Int, board: ShapeBoard, layout: ShapesLayout) -> Bool {
        guard let d = dragging, !model.filled.contains(slot), board.slots[d] == board.slots[slot] else { return false }
        return layout.slot(slot).distance(to: dragLocation) < layout.snapRadius * 1.3
    }

    private func houseBackground(_ layout: ShapesLayout) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36)
                .fill(Theme.softGreen.opacity(0.45))
                .frame(width: layout.size.width, height: layout.size.height)
                .position(x: layout.size.width / 2, y: layout.size.height / 2)
            // Haus
            TriangleShape()
                .fill(Theme.gentleRed.opacity(0.55))
                .frame(width: layout.houseRect.width * 1.08, height: layout.size.height * 0.12)
                .position(x: layout.houseRect.midX, y: layout.houseRect.minY - layout.size.height * 0.06)
            RoundedRectangle(cornerRadius: 20)
                .fill(Theme.apricot.opacity(0.85))
                .frame(width: layout.houseRect.width, height: layout.houseRect.height)
                .position(x: layout.houseRect.midX, y: layout.houseRect.midY)
            // Wiese für die Formen
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.55))
                .frame(width: layout.size.width * 0.94, height: layout.size.height * 0.26)
                .position(x: layout.size.width / 2, y: layout.size.height * 0.84)
        }
    }
}

struct ShapesLayout {
    let size: CGSize
    let count: Int

    var houseRect: CGRect {
        CGRect(x: size.width * 0.08, y: size.height * 0.14, width: size.width * 0.84, height: size.height * 0.5)
    }

    var shapeSize: CGFloat {
        min(size.width / CGFloat(count + 1) * 0.75, size.height * 0.2, 170)
    }

    var snapRadius: CGFloat { shapeSize * 0.75 }

    func slot(_ i: Int) -> CGPoint {
        let r = houseRect
        let step = r.width / CGFloat(count)
        return CGPoint(x: r.minX + step * (CGFloat(i) + 0.5), y: r.midY)
    }

    func piece(_ pos: Int) -> CGPoint {
        let step = size.width * 0.94 / CGFloat(count)
        return CGPoint(x: size.width * 0.03 + step * (CGFloat(pos) + 0.5), y: size.height * 0.84)
    }

    func nearestSlot(to p: CGPoint) -> Int? {
        var best: (Int, CGFloat)?
        for i in 0..<count {
            let d = slot(i).distance(to: p)
            if d < snapRadius * 1.3, best == nil || d < best!.1 { best = (i, d) }
        }
        return best?.0
    }
}

@MainActor
@Observable
final class ShapesModel {
    @ObservationIgnored let host: GameHost
    var boards: [ShapeBoard] = []
    var index = 0
    var filled: [Int] = []
    var selected: Int?
    var hintSlot: Int?
    var hintPiece: Int?
    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var board: ShapeBoard? { boards[safe: index] }

    func start() {
        guard !started else { return }
        started = true
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Formen zugeordnet.") }
            let kinds = Set(self.boards.flatMap(\.slots)).map(\.name).sorted()
            return RoundSummary(text: "Vier Formenhäuser gefüllt: \(kinds.joined(separator: ", ")).", practiced: kinds)
        }
        if let saved = host.takeRestoredPayload(ShapesState.self), !saved.boards.isEmpty {
            boards = saved.boards
            index = min(saved.index, boards.count - 1)
            filled = saved.filled
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            host.setInstruction("Welche Form passt hier hinein?")
        } else {
            boards = Array(ShapeBoards.boards(for: host.difficulty).shuffled().prefix(host.tasksPerRound))
            index = 0
            present()
        }
    }

    private func present() {
        filled = []
        selected = nil
        hintSlot = nil
        hintPiece = nil
        save()
        host.setInstruction("Welche Form passt hier hinein? Zieh sie in die Öffnung.")
    }

    private func advance() {
        index = min(index + 1, boards.count - 1)
        present()
    }

    private func save() {
        host.persist(ShapesState(boards: boards, index: index, filled: filled))
    }

    func select(_ piece: Int) {
        guard let board, !filled.contains(piece) else { return }
        host.audio.effect(.tap)
        selected = selected == piece ? nil : piece
        if selected != nil {
            host.audio.say("\(board.slots[piece].article.capitalizedFirst) \(board.slots[piece].name). Wo passt \(board.slots[piece].article == "der" ? "er" : "es") hin?")
        }
    }

    func tapSlot(_ slot: Int) {
        guard let piece = selected else { return }
        drop(piece: piece, on: slot)
    }

    /// Die Zuordnung richtet sich nach der Form, nicht nach der Farbe.
    func drop(piece: Int, on slot: Int) {
        guard let board, !filled.contains(slot) else { return }
        selected = nil
        if board.slots[piece] == board.slots[slot] {
            filled.append(slot)
            hintSlot = nil
            hintPiece = nil
            host.audio.effect(.snap)
            save()
            if filled.count == board.slots.count {
                host.taskSolved("Alle Formen sind im Haus.")
            } else {
                host.audio.say("\(board.slots[piece].article.capitalizedFirst) \(board.slots[piece].name) passt.")
            }
        } else {
            host.wrong("Das ist ein \(board.slots[piece].name). Die Form passt hier nicht.")
        }
    }

    private func help(_ level: Int) {
        guard let board else { return }
        guard let next = board.pieceOrder.first(where: { !filled.contains($0) }) else { return }
        switch level {
        case 1:
            hintSlot = next
            host.showBunny("Schau dir die Ecken und Rundungen an.")
        case 2:
            hintPiece = next
            hintSlot = next
            host.showBunny("\(board.slots[next].article.capitalizedFirst) \(board.slots[next].name) gehört hierhin.")
        default:
            host.showBunny("Wir setzen \(board.slots[next].article == "der" ? "den" : "das") \(board.slots[next].name) gemeinsam ein.")
            withAnimation(.spring()) { drop(piece: next, on: next) }
        }
    }
}
