import SwiftUI

struct SortCategory: Codable, Equatable {
    var color: Palette?
    var shape: ShapeKind?
    /// 0 = klein, 1 = mittel, 2 = gross
    var sizeLevel: Int?
}

struct SortItem: Codable, Equatable {
    var category: Int
    var shape: ShapeKind?
    var emoji: String?
    var color: Palette
    var scale: Double
    var pos: NPoint
}

struct SortTask: Codable, Equatable {
    enum Feature: String, Codable { case color, shape, size }
    var feature: Feature
    var categories: [SortCategory]
    var items: [SortItem]
    var sizeNoun: String?
    var sizeEmoji: String?
}

enum SortFactory {
    static let sizeObjects: [(emoji: String, plural: String)] = [("🍂", "Blätter"), ("🍎", "Äpfel"), ("🍄", "Pilze"), ("🌰", "Kastanien")]

    static func scatter(_ n: Int, rng: inout SeededGenerator) -> [NPoint] {
        let cols = n <= 6 ? 3 : 4
        let rows = Int(ceil(Double(n) / Double(cols)))
        var cells = Array(0..<(cols * rows)).shuffled(using: &rng)
        return (0..<n).map { _ in
            let c = cells.removeFirst()
            return NPoint((Double(c % cols) + 0.5) / Double(cols) + Double.random(in: -0.04...0.04, using: &rng),
                          (Double(c / cols) + 0.5) / Double(rows) + Double.random(in: -0.05...0.05, using: &rng))
        }
    }

    /// 24 Aufgaben: je acht für Farbe, Form und Grösse (pro Stufe angepasst).
    static func catalog(difficulty: Difficulty) -> [SortTask] {
        var rng = SeededGenerator(seed: 700 + UInt64(Difficulty.allCases.firstIndex(of: difficulty)!))
        var tasks: [SortTask] = []
        for feature in [SortTask.Feature.color, .shape, .size] {
            for v in 0..<8 {
                tasks.append(make(feature: feature, variant: v, difficulty: difficulty, rng: &rng))
            }
        }
        return tasks
    }

    static func make(feature: SortTask.Feature, variant: Int, difficulty: Difficulty, rng: inout SeededGenerator) -> SortTask {
        let basketCount: Int
        let itemCount: Int
        switch difficulty {
        case .entdecken:
            basketCount = 2
            itemCount = variant % 2 == 0 ? 4 : 6
        case .ueben:
            basketCount = 3
            itemCount = 6
        case .knobeln:
            basketCount = variant % 2 == 0 ? 2 : 3
            itemCount = 8
        }
        var categories: [SortCategory] = []
        var items: [SortItem] = []
        let positions = scatter(itemCount, rng: &rng)
        // Gleichmässige Verteilung auf die Körbe
        var cats = (0..<itemCount).map { $0 % basketCount }
        cats.shuffle(using: &rng)

        switch feature {
        case .color:
            let pool: [Palette] = difficulty == .knobeln
                ? [.red, .orange, .yellow, .pink, .purple].shuffled(using: &rng)
                : [.red, .blue, .yellow, .green].shuffled(using: &rng)
            categories = pool.prefix(basketCount).map { SortCategory(color: $0) }
            let shapes: [ShapeKind] = [.circle, .square, .triangle, .star]
            for (i, c) in cats.enumerated() {
                items.append(SortItem(category: c, shape: shapes.randomElement(using: &rng)!, emoji: nil,
                                      color: categories[c].color!, scale: 1, pos: positions[i]))
            }
            return SortTask(feature: .color, categories: categories, items: items)
        case .shape:
            let pool: [ShapeKind] = difficulty == .knobeln
                ? [.circle, .oval, .square, .rectangle].shuffled(using: &rng)
                : [.circle, .square, .triangle, .star].shuffled(using: &rng)
            categories = pool.prefix(basketCount).map { SortCategory(shape: $0) }
            let colors: [Palette] = [.red, .blue, .yellow, .green, .purple, .orange]
            for (i, c) in cats.enumerated() {
                items.append(SortItem(category: c, shape: categories[c].shape!, emoji: nil,
                                      color: colors.randomElement(using: &rng)!, scale: 1, pos: positions[i]))
            }
            return SortTask(feature: .shape, categories: categories, items: items)
        case .size:
            let object = sizeObjects[variant % sizeObjects.count]
            let levels: [Int] = basketCount == 3 ? [0, 1, 2] : [0, 2]
            categories = levels.map { SortCategory(sizeLevel: $0) }
            for (i, c) in cats.enumerated() {
                let level = categories[c].sizeLevel!
                let scale: Double = level == 0 ? 0.55 : level == 1 ? 0.8 : 1.15
                items.append(SortItem(category: c, shape: nil, emoji: object.emoji, color: .green, scale: scale, pos: positions[i]))
            }
            return SortTask(feature: .size, categories: categories, items: items, sizeNoun: object.plural, sizeEmoji: object.emoji)
        }
    }
}

struct SortingState: Codable {
    var tasks: [SortTask]
    var index: Int
    var placed: [Int: Int]
}

/// Spiel 7: Sortiergarten.
struct SortingGameView: View {
    let host: GameHost
    @State private var model: SortingModel
    @State private var dragging: Int?
    @State private var dragLocation: CGPoint = .zero

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: SortingModel(host: host))
    }

    var body: some View {
        GeometryReader { geo in
            if let task = model.task {
                let itemArea = CGRect(x: 20, y: 10, width: geo.size.width - 40, height: geo.size.height * 0.56)
                let basketY = geo.size.height * 0.8
                let basketW = min(geo.size.width / CGFloat(task.categories.count) - 30, 300)
                let baseSize = min(itemArea.height / 3.2, 110)
                ZStack {
                    RoundedRectangle(cornerRadius: 36).fill(Theme.meadow)

                    ForEach(task.categories.indices, id: \.self) { c in
                        basket(task: task, category: c, width: basketW, itemSize: baseSize * 0.5)
                            .position(basketCenter(c, count: task.categories.count, width: geo.size.width, y: basketY))
                            .onTapGesture { model.tapBasket(c) }
                    }

                    ForEach(task.items.indices, id: \.self) { i in
                        if model.placed[i] == nil {
                            let item = task.items[i]
                            let home = CGPoint(x: itemArea.minX + item.pos.x * itemArea.width, y: itemArea.minY + item.pos.y * itemArea.height)
                            SortItemView(item: item, size: baseSize)
                                .padding(6)
                                .background(RoundedRectangle(cornerRadius: 18).stroke(Theme.highlight, lineWidth: model.selected == i ? 5 : 0))
                                .pulseHighlight(model.hintItem == i)
                                .scaleEffect(dragging == i ? 1.1 : 1)
                                .position(dragging == i ? dragLocation : home)
                                .zIndex(dragging == i ? 10 : 1)
                                .gesture(
                                    DragGesture(minimumDistance: 4, coordinateSpace: .named("sorting"))
                                        .onChanged { v in
                                            dragging = i
                                            dragLocation = v.location
                                        }
                                        .onEnded { v in
                                            let target = task.categories.indices.first { c in
                                                basketCenter(c, count: task.categories.count, width: geo.size.width, y: basketY)
                                                    .distance(to: v.location) < basketW * 0.6 + 30
                                            }
                                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                                dragging = nil
                                                if let target { model.drop(item: i, in: target) }
                                            }
                                        }
                                )
                                .simultaneousGesture(TapGesture().onEnded { model.select(i) })
                        }
                    }
                }
                .coordinateSpace(name: "sorting")
            }
        }
        .onAppear { model.start() }
    }

    private func basketCenter(_ c: Int, count: Int, width: CGFloat, y: CGFloat) -> CGPoint {
        let step = width / CGFloat(count)
        return CGPoint(x: step * (CGFloat(c) + 0.5), y: y)
    }

    private func basket(task: SortTask, category c: Int, width: CGFloat, itemSize: CGFloat) -> some View {
        let cat = task.categories[c]
        let inside = task.items.indices.filter { model.placed[$0] == c }
        return VStack(spacing: 6) {
            // Merkmal deutlich sichtbar über dem Korb
            Group {
                if let color = cat.color {
                    HStack(spacing: 8) {
                        Circle().fill(color.color).frame(width: 44, height: 44)
                        Text(color.name).font(Theme.rounded(20, .bold))
                    }
                } else if let shape = cat.shape {
                    HStack(spacing: 8) {
                        ShapeTile(kind: shape, size: 50, outlineOnly: true)
                        Text(shape.name).font(Theme.rounded(20, .bold))
                    }
                } else if let level = cat.sizeLevel {
                    HStack(spacing: 8) {
                        Text(task.sizeEmoji ?? "🍂")
                            .font(.system(size: level == 0 ? 24 : level == 1 ? 36 : 52))
                        Text(level == 0 ? "klein" : level == 1 ? "mittel" : "gross").font(Theme.rounded(20, .bold))
                    }
                }
            }
            .foregroundStyle(Theme.darkGreen)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(.white))

            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(Theme.creamDark)
                    .overlay(RoundedRectangle(cornerRadius: 28).stroke(Theme.highlight, lineWidth: model.selected != nil ? 4 : 0))
                HStack(spacing: -10) {
                    ForEach(inside, id: \.self) { i in
                        SortItemView(item: task.items[i], size: itemSize)
                    }
                }
                Text("🧺").font(.system(size: 34)).opacity(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(8)
            }
            .frame(width: width, height: 110)
            .pulseHighlight(model.hintBasket == c)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

struct SortItemView: View {
    let item: SortItem
    let size: CGFloat

    var body: some View {
        Group {
            if let emoji = item.emoji {
                Text(emoji).font(.system(size: size * item.scale))
            } else if let shape = item.shape {
                ShapeTile(kind: shape, size: size * 0.8 * item.scale, color: item.color.color)
            }
        }
        .frame(width: size, height: size)
    }
}

@MainActor
@Observable
final class SortingModel {
    @ObservationIgnored let host: GameHost
    var tasks: [SortTask] = []
    var index = 0
    var placed: [Int: Int] = [:]
    var selected: Int?
    var hintItem: Int?
    var hintBasket: Int?
    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var task: SortTask? { tasks[safe: index] }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Sortiert.") }
            let names = Set(self.tasks.map { self.featureName($0.feature) }).sorted()
            return RoundSummary(text: "Vier Sortieraufgaben nach \(names.joined(separator: ", ")) gelöst.", practiced: names.map { "nach \($0) sortiert" })
        }
        if let saved = host.takeRestoredPayload(SortingState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            placed = saved.placed
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            explain()
        } else {
            let allowed = host.options.sortingFeatures
            let pool = SortFactory.catalog(difficulty: host.difficulty).filter { allowed.contains($0.feature.rawValue) }
            tasks = Array((pool.isEmpty ? SortFactory.catalog(difficulty: host.difficulty) : pool).shuffled().prefix(host.tasksPerRound))
            index = 0
            present()
        }
    }

    func featureName(_ f: SortTask.Feature) -> String {
        switch f {
        case .color: return "Farbe"
        case .shape: return "Form"
        case .size: return "Grösse"
        }
    }

    private func present() {
        placed = [:]
        selected = nil
        hintItem = nil
        hintBasket = nil
        save()
        explain()
    }

    /// Jede Aufgabe verwendet nur ein Merkmal; ein Wechsel wird neu erklärt.
    private func explain() {
        guard let task else { return }
        switch task.feature {
        case .color:
            host.setInstruction("Sortiere nach Farbe. Leg jedes Ding in den Korb mit der gleichen Farbe.")
        case .shape:
            host.setInstruction("Sortiere nach Form. Leg jede Form in den Korb mit der gleichen Form.")
        case .size:
            let noun = task.sizeNoun ?? "Dinge"
            if task.categories.count == 3 {
                host.setInstruction("Sortiere nach Grösse: kleine, mittlere und grosse \(noun).")
            } else {
                host.setInstruction("Leg die grossen \(noun) zum grossen Bild und die kleinen zum kleinen.")
            }
        }
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    private func save() {
        host.persist(SortingState(tasks: tasks, index: index, placed: placed))
    }

    func select(_ i: Int) {
        guard placed[i] == nil else { return }
        host.audio.effect(.tap)
        selected = selected == i ? nil : i
    }

    func tapBasket(_ c: Int) {
        guard let i = selected else { return }
        drop(item: i, in: c)
    }

    func drop(item i: Int, in c: Int) {
        guard let task, placed[i] == nil else { return }
        selected = nil
        if task.items[i].category == c {
            placed[i] = c
            hintItem = nil
            hintBasket = nil
            host.audio.effect(.snap)
            save()
            if placed.count == task.items.count {
                host.taskSolved("Alles ist sortiert.")
            }
        } else {
            switch task.feature {
            case .color: host.wrong("Schau genau auf die Farbe.")
            case .shape: host.wrong("Schau genau auf die Form.")
            case .size: host.wrong("Ist es gross oder klein?")
            }
        }
    }

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        guard let task, let next = task.items.indices.first(where: { placed[$0] == nil }) else { return }
        drop(item: next, in: task.items[next].category)
    }

    private func help(_ level: Int) {
        guard let task, let next = task.items.indices.first(where: { placed[$0] == nil }) else { return }
        let target = task.items[next].category
        switch level {
        case 1:
            hintItem = next
            host.showBunny("Wohin passt dieses?")
        case 2:
            hintItem = next
            hintBasket = target
            host.showBunny("Es gehört in diesen Korb.")
        default:
            host.showBunny("Wir legen es gemeinsam hinein.")
            withAnimation(.spring()) { drop(item: next, in: target) }
        }
    }
}
