import SwiftUI

// MARK: - Aufgaben

enum BodyTaskKind: Codable, Equatable {
    case zeigen(BodyPart)
    case suchen(BodyPart)
    case entdecken([BodyLayer])
    case funktion(BodyPart, [BodyFunction])
    case sinn(SenseQuestion, [BodyPart])
    case herz(HeartScene, fastLeft: Bool)
    case weg
    case puzzle([BodyPart])
}

struct BodyState: Codable {
    var tasks: [BodyTaskKind]
    var index: Int
}

enum BodyTasks {
    /// Vier Aufgaben pro Runde, je nach Niveau.
    static func round(level: Int) -> [BodyTaskKind] {
        let organSearch: [BodyPart] = [.gehirn, .herz, .lunge, .magen]
        let withFunction = BodyPart.allCases.filter { $0.functionQuestion != nil }
        switch level {
        case ...1:
            return BodyPart.outer.shuffled().prefix(4).map { BodyTaskKind.zeigen($0) }
        case 2:
            let face = BodyPart.face.shuffled().prefix(2).map { BodyTaskKind.zeigen($0) }
            let senses = SenseCatalog.questions.shuffled().prefix(2).map { sense($0, options: 3) }
            return [face[0], senses[0], face[1], senses[1]]
        case 3:
            let parts = organSearch.shuffled()
            return [.entdecken([.organe]), .suchen(parts[0]), function(parts[2], options: 3), .suchen(parts[1])]
        case 4:
            return [.entdecken([.organe, .knochen, .adern, .muskeln]),
                    .suchen(BodyPart.bones.randomElement()!),
                    heart(),
                    function(withFunction.randomElement()!, options: 3)]
        case 5:
            return [function(withFunction.randomElement()!, options: 4), .weg, heart(),
                    sense(SenseCatalog.questions.randomElement()!, options: 5)]
        default:
            let search = (organSearch + BodyPart.bones).randomElement()!
            return [.puzzle([.gehirn, .lunge, .herz, .magen]), .weg, .suchen(search),
                    function(withFunction.randomElement()!, options: 4)]
        }
    }

    static func function(_ part: BodyPart, options: Int) -> BodyTaskKind {
        let others = BodyFunction.allCases.filter { $0 != part.function }.shuffled()
        return .funktion(part, ([part.function] + others.prefix(options - 1)).shuffled())
    }

    static func sense(_ q: SenseQuestion, options: Int) -> BodyTaskKind {
        let others = SenseCatalog.senses.filter { $0 != q.answer }.shuffled()
        return .sinn(q, ([q.answer] + others.prefix(options - 1)).shuffled())
    }

    static func heart() -> BodyTaskKind {
        .herz(HeartCatalog.scenes.randomElement()!, fastLeft: Bool.random())
    }
}

// MARK: - Spiel

/// Spiel 13: Mein Körper.
struct BodyGameView: View {
    let host: GameHost
    @State private var model: BodyModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: BodyModel(host: host))
    }

    var body: some View {
        Group {
            if let task = model.task {
                switch task {
                case .zeigen, .suchen, .entdecken, .weg:
                    HStack(spacing: 20) {
                        figureArea(task)
                        infoPanel(task)
                            .frame(width: 360)
                    }
                case .funktion(let part, let options):
                    functionView(part, options)
                case .sinn(let q, let options):
                    senseView(q, options)
                case .herz(let scene, let fastLeft):
                    heartView(scene, fastLeft: fastLeft)
                case .puzzle(let parts):
                    BodyPuzzleView(model: model, parts: parts)
                }
            }
        }
        .animation(.spring(response: 0.4), value: model.solved)
        .onAppear { model.start() }
    }

    // MARK: Figur

    private func figureArea(_ task: BodyTaskKind) -> some View {
        BodyFigureView(base: model.baseLayer,
                       reveal: model.revealLayer,
                       lensLayer: model.lensLayer,
                       lensPos: model.lensPos,
                       highlights: model.highlights,
                       food: model.foodPoint,
                       onTap: { model.tap($0) },
                       onLens: { model.moveLens($0) })
            .padding(10)
            .background(PlayfieldBackground(color: Theme.sky))
            .overlay(alignment: .bottomLeading) {
                if case .entdecken(let layers) = task, layers.count > 1 {
                    layerPicker(layers).padding(16)
                }
            }
    }

    private func layerPicker(_ layers: [BodyLayer]) -> some View {
        HStack(spacing: 10) {
            ForEach(layers) { l in
                Button { model.switchLens(l) } label: {
                    VStack(spacing: 2) {
                        Pic("koerper_knopf_\(l.rawValue)", l.emoji, size: 30)
                        Text(l.title).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.darkGreen)
                    }
                    .frame(width: 84, height: 72)
                    .background(RoundedRectangle(cornerRadius: 18).fill(model.lensLayer == l ? Theme.lightYellow : .white))
                    .overlay(RoundedRectangle(cornerRadius: 18).stroke(model.lensLayer == l ? Theme.highlight : .clear, lineWidth: 4))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    @ViewBuilder
    private func infoPanel(_ task: BodyTaskKind) -> some View {
        VStack(spacing: 14) {
            if let part = model.info {
                PartCard(part: part, animate: true)
                Text(part.explanation)
                    .font(Theme.rounded(20, .medium))
                    .foregroundStyle(Theme.darkGreen)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            } else {
                switch task {
                case .zeigen(let part), .suchen(let part):
                    PartCard(part: part, animate: false)
                    Text(part.layer == .aussen ? "Tippe auf die richtige Stelle." : "So sieht es aus. Fahr mit der Zauberlupe über den Körper.")
                        .font(Theme.rounded(19, .medium))
                        .foregroundStyle(Theme.darkGreen.opacity(0.8))
                        .multilineTextAlignment(.center)
                case .entdecken:
                    Pic("koerper_zauberlupe", "🔍", size: 110)
                    Text("Fahr mit der Zauberlupe über den Körper. Was findest du?")
                        .font(Theme.rounded(20, .medium))
                        .foregroundStyle(Theme.darkGreen)
                        .multilineTextAlignment(.center)
                case .weg:
                    HStack(spacing: 8) {
                        ForEach(Array(FoodPath.order.enumerated()), id: \.offset) { i, p in
                            if i > 0 { Image(systemName: "arrow.right").foregroundStyle(Theme.darkGreen.opacity(0.5)) }
                            VStack(spacing: 4) {
                                Pic(p.asset, p.emoji, size: 58)
                                    .opacity(i < model.foodStep ? 1 : 0.25)
                                Text(i < model.foodStep ? p.name : "?")
                                    .font(Theme.rounded(16, .bold)).foregroundStyle(Theme.darkGreen)
                            }
                        }
                    }
                    Pic("koerper_essen_apfel", "🍎", size: 70)
                default:
                    EmptyView()
                }
            }
            if case .entdecken = task, !model.found.isEmpty {
                FlowChips(parts: model.found)
            }
        }
        .padding(22)
        .frame(maxHeight: .infinity)
        .background(RoundedRectangle(cornerRadius: 34).fill(.white))
    }

    // MARK: Was macht …?

    private func functionView(_ part: BodyPart, _ options: [BodyFunction]) -> some View {
        VStack(spacing: 22) {
            HStack(spacing: 30) {
                PartCard(part: part, animate: true)
                if model.solved {
                    Text(part.explanation)
                        .font(Theme.rounded(22, .medium))
                        .foregroundStyle(Theme.darkGreen)
                        .frame(maxWidth: 440)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PlayfieldBackground(color: Theme.sky))

            HStack(spacing: 20) {
                ForEach(options, id: \.self) { f in
                    AnswerCard(state: model.state(for: f.rawValue, correct: f == part.function), minSize: 150) {
                        model.chooseFunction(f, part: part)
                    } content: {
                        VStack(spacing: 6) {
                            Pic(f.asset, f.emoji, size: 80)
                            Text(f.label)
                                .font(Theme.rounded(18, .bold))
                                .foregroundStyle(Theme.darkGreen)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: 160)
                    }
                    .pulseHighlight(model.highlightAnswer && f == part.function)
                }
            }
            .padding(.bottom, 6)
        }
    }

    // MARK: Sinne

    private func senseView(_ q: SenseQuestion, _ options: [BodyPart]) -> some View {
        VStack(spacing: 22) {
            HStack(spacing: 30) {
                Pic("koerper_sinn_\(q.object)", q.emoji, size: 170)
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 34).fill(.white))
                if model.solved {
                    Text(q.explanation)
                        .font(Theme.rounded(22, .medium))
                        .foregroundStyle(Theme.darkGreen)
                        .frame(maxWidth: 440)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PlayfieldBackground(color: Theme.meadow.opacity(0.6)))

            HStack(spacing: 20) {
                ForEach(options) { p in
                    AnswerCard(state: model.state(for: p.rawValue, correct: p == q.answer), minSize: 140) {
                        model.chooseSense(p, q: q)
                    } content: {
                        VStack(spacing: 6) {
                            Pic(p.asset, p.emoji, size: 74)
                            Text(p == .hand ? "Hand und Haut" : p.name)
                                .font(Theme.rounded(18, .bold))
                                .foregroundStyle(Theme.darkGreen)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .frame(width: 140)
                    }
                    .pulseHighlight(model.highlightAnswer && p == q.answer)
                }
            }
            .padding(.bottom, 6)
        }
    }

    // MARK: Herzschlag

    private func heartView(_ scene: HeartScene, fastLeft: Bool) -> some View {
        VStack(spacing: 22) {
            HStack(spacing: 30) {
                Pic(scene.image, scene.emoji, size: 200)
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 34).fill(.white))
                if model.solved {
                    Text(scene.explanation)
                        .font(Theme.rounded(22, .medium))
                        .foregroundStyle(Theme.darkGreen)
                        .frame(maxWidth: 440)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(PlayfieldBackground(color: Theme.apricot.opacity(0.45)))

            HStack(spacing: 40) {
                ForEach([fastLeft, !fastLeft], id: \.self) { fast in
                    AnswerCard(state: model.state(for: fast ? "schnell" : "langsam", correct: fast == scene.fast), minSize: 200) {
                        model.chooseHeart(fast: fast, scene: scene)
                    } content: {
                        VStack(spacing: 8) {
                            BeatingHeart(period: fast ? 0.42 : 1.35, size: 110)
                            Text(fast ? "Schnell" : "Langsam")
                                .font(Theme.rounded(22, .bold))
                                .foregroundStyle(Theme.darkGreen)
                        }
                        .frame(width: 220)
                    }
                    .pulseHighlight(model.highlightAnswer && fast == scene.fast)
                }
            }
            .padding(.bottom, 6)
        }
    }
}

// MARK: - Bausteine

/// Bild eines Körperteils; Herz schlägt, Lunge atmet, andere wippen leicht.
struct PartCard: View {
    let part: BodyPart
    let animate: Bool

    var body: some View {
        VStack(spacing: 8) {
            Group {
                if animate && part == .herz {
                    BeatingImage(asset: part.asset, emoji: part.emoji, period: 0.85, size: 170)
                } else if animate && part == .lunge {
                    BreathingImage(asset: part.asset, emoji: part.emoji, size: 170)
                } else {
                    Pic(part.asset, part.emoji, size: 150)
                        .frame(width: 180, height: 180)
                }
            }
            Text(part.name)
                .font(Theme.rounded(26, .heavy))
                .foregroundStyle(Theme.darkGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 30).fill(Theme.cream))
    }
}

/// Schlagendes Herz (Doppelschlag «bum-bum»).
struct BeatingHeart: View {
    let period: Double
    let size: CGFloat

    var body: some View {
        BeatingImage(asset: "koerper_teil_herz", emoji: "❤️", period: period, size: size)
    }
}

struct BeatingImage: View {
    let asset: String
    let emoji: String
    let period: Double
    let size: CGFloat

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
            Pic(asset, emoji, size: size * 0.85)
                .scaleEffect(1 + 0.12 * Self.beat(t))
                .frame(width: size, height: size)
        }
    }

    /// Zwei kurze Spitzen pro Takt.
    static func beat(_ t: Double) -> Double {
        func bump(_ c: Double, _ w: Double) -> Double { max(0, 1 - abs(t - c) / w) }
        return bump(0.08, 0.08) + 0.6 * bump(0.26, 0.07)
    }
}

struct BreathingImage: View {
    let asset: String
    let emoji: String
    let size: CGFloat

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSinceReferenceDate
            let s = 1 + 0.06 * sin(t * 2 * .pi / 3)
            Pic(asset, emoji, size: size * 0.85)
                .scaleEffect(x: s, y: 1 + (s - 1) * 1.4, anchor: .bottom)
                .frame(width: size, height: size)
        }
    }
}

/// Gefundene Teile als kleine Kärtchen.
struct FlowChips: View {
    let parts: [BodyPart]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(parts) { p in
                HStack(spacing: 4) {
                    Pic(p.asset, p.emoji, size: 24)
                    Text(p.name).font(Theme.rounded(14, .bold)).foregroundStyle(Theme.darkGreen)
                        .lineLimit(1).minimumScaleFactor(0.6)
                }
                .padding(.horizontal, 8).padding(.vertical, 6)
                .background(Capsule().fill(Theme.softGreen))
            }
        }
    }
}

/// Die Kinderfigur mit Ebenen und Zauberlupe.
struct BodyFigureView: View {
    let base: BodyLayer
    let reveal: BodyLayer?
    let lensLayer: BodyLayer?
    let lensPos: CGPoint
    let highlights: [BodyPart]
    let food: CGPoint?
    let onTap: (CGPoint) -> Void
    let onLens: (CGPoint) -> Void

    static let aspect: CGFloat = 0.75
    static let lensDiameter: CGFloat = 0.24   // Anteil der Figurenhöhe
    static let lensLift: CGFloat = 0.1         // Lupe sitzt etwas über dem Finger

    var body: some View {
        GeometryReader { geo in
            let h = min(geo.size.height, geo.size.width / Self.aspect)
            let w = h * Self.aspect
            let rect = CGRect(x: (geo.size.width - w) / 2, y: (geo.size.height - h) / 2, width: w, height: h)
            ZStack(alignment: .topLeading) {
                layerImage(base, rect)
                if let reveal {
                    layerImage(reveal, rect).transition(.opacity)
                }
                if let lensLayer {
                    let c = point(lensPos, rect)
                    let d = Self.lensDiameter * h
                    layerImage(lensLayer, rect)
                        .mask(alignment: .topLeading) {
                            Circle().frame(width: d, height: d).position(c)
                        }
                    LensRing(diameter: d).position(c).allowsHitTesting(false)
                }
                ForEach(highlights) { part in
                    ForEach(Array(part.spots.enumerated()), id: \.offset) { _, s in
                        PulseRing(diameter: part.radius * 2 * h)
                            .position(point(s, rect))
                            .allowsHitTesting(false)
                    }
                }
                if let food {
                    Pic("koerper_essen_bissen", "🟤", size: h * 0.035)
                        .position(point(food, rect))
                        .allowsHitTesting(false)
                        .animation(.easeInOut(duration: 0.9), value: food)
                }
            }
            .contentShape(Rectangle())
            .gesture(lensLayer == nil ? nil : DragGesture(minimumDistance: 0).onChanged { v in
                let p = CGPoint(x: v.location.x, y: v.location.y - Self.lensLift * h)
                onLens(normalize(p, rect))
            })
            .simultaneousGesture(lensLayer != nil ? nil : SpatialTapGesture().onEnded { v in
                onTap(normalize(v.location, rect))
            })
        }
    }

    @ViewBuilder
    private func layerImage(_ layer: BodyLayer, _ rect: CGRect) -> some View {
        Group {
            if let img = UIImage(named: layer.asset) {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                // Ersatz nur für Tests ohne Bilder
                ZStack {
                    RoundedRectangle(cornerRadius: 40).fill(layer == .aussen ? Theme.apricot : Theme.lilac.opacity(0.6))
                    Text(layer.emoji).font(.system(size: rect.width * 0.4))
                }
            }
        }
        .frame(width: rect.width, height: rect.height)
        .position(x: rect.midX, y: rect.midY)
    }

    private func point(_ p: CGPoint, _ rect: CGRect) -> CGPoint {
        CGPoint(x: rect.minX + p.x * rect.width, y: rect.minY + p.y * rect.height)
    }

    private func normalize(_ p: CGPoint, _ rect: CGRect) -> CGPoint {
        CGPoint(x: (p.x - rect.minX) / rect.width, y: (p.y - rect.minY) / rect.height)
    }
}

/// Goldener Lupenring mit Griff.
struct LensRing: View {
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Capsule()
                .fill(LinearGradient(colors: [Color(red: 0.62, green: 0.40, blue: 0.22), Color(red: 0.45, green: 0.27, blue: 0.14)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: diameter * 0.16, height: diameter * 0.55)
                .offset(y: diameter * 0.62)
                .rotationEffect(.degrees(-35))
            Circle()
                .stroke(LinearGradient(colors: [Color(red: 1, green: 0.88, blue: 0.45), Color(red: 0.86, green: 0.62, blue: 0.18)],
                                       startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: diameter * 0.075)
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
            Circle()
                .trim(from: 0.55, to: 0.7)
                .stroke(.white.opacity(0.7), style: StrokeStyle(lineWidth: diameter * 0.03, lineCap: .round))
                .frame(width: diameter * 0.78, height: diameter * 0.78)
        }
        .frame(width: diameter * 1.6, height: diameter * 1.6)
    }
}

struct PulseRing: View {
    let diameter: CGFloat
    @State private var on = false

    var body: some View {
        Circle()
            .stroke(Theme.highlight, lineWidth: 6)
            .frame(width: diameter, height: diameter)
            .scaleEffect(on ? 1.12 : 0.92)
            .opacity(on ? 1 : 0.6)
            .onAppear { withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { on = true } }
    }
}

// MARK: - Puzzle

/// Organe in die Figur legen.
struct BodyPuzzleView: View {
    let model: BodyModel
    let parts: [BodyPart]
    @State private var drag: [BodyPart: CGPoint] = [:]

    var body: some View {
        GeometryReader { geo in
            let trayW: CGFloat = 220
            let figW = geo.size.width - trayW - 20
            let h = min(geo.size.height, figW / BodyFigureView.aspect)
            let w = h * BodyFigureView.aspect
            let rect = CGRect(x: (figW - w) / 2, y: (geo.size.height - h) / 2, width: w, height: h)
            ZStack(alignment: .topLeading) {
                PlayfieldBackground(color: Theme.sky)
                    .frame(width: figW, height: geo.size.height)
                Group {
                    if let img = UIImage(named: "koerper_umriss") {
                        Image(uiImage: img).resizable().scaledToFit()
                    } else {
                        RoundedRectangle(cornerRadius: 40).fill(Theme.apricot.opacity(0.5))
                    }
                }
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)

                ForEach(parts) { p in
                    let target = CGPoint(x: rect.minX + p.center.x * rect.width, y: rect.minY + p.center.y * rect.height)
                    let size = p.puzzleSize * h
                    if !model.placed.contains(p) {
                        Circle()
                            .stroke(style: StrokeStyle(lineWidth: 3, dash: [8, 6]))
                            .foregroundStyle(model.highlightAnswer ? Theme.highlight : Theme.darkGreen.opacity(0.35))
                            .frame(width: size * 0.9, height: size * 0.9)
                            .position(target)
                    }
                }

                RoundedRectangle(cornerRadius: 30).fill(.white)
                    .frame(width: trayW, height: geo.size.height)
                    .position(x: geo.size.width - trayW / 2, y: geo.size.height / 2)

                ForEach(Array(parts.enumerated()), id: \.element) { i, p in
                    let target = CGPoint(x: rect.minX + p.center.x * rect.width, y: rect.minY + p.center.y * rect.height)
                    let slot = CGPoint(x: geo.size.width - trayW / 2,
                                       y: geo.size.height * (CGFloat(i) + 0.5) / CGFloat(parts.count))
                    let placed = model.placed.contains(p)
                    let size = placed ? p.puzzleSize * h : min(120, geo.size.height / CGFloat(parts.count) - 20)
                    Pic(p.asset, p.emoji, size: size / 1.2)
                        .frame(width: size, height: size)
                        .position(placed ? target : (drag[p] ?? slot))
                        .zIndex(drag[p] != nil ? 10 : 1)
                        .gesture(placed ? nil : DragGesture()
                            .onChanged { v in drag[p] = v.location }
                            .onEnded { v in
                                let dx = (v.location.x - target.x) / h, dy = (v.location.y - target.y) / h
                                if (dx * dx + dy * dy).squareRoot() < 0.09 {
                                    withAnimation(.spring(response: 0.35)) { model.place(p) }
                                } else {
                                    model.misplaced(p)
                                }
                                withAnimation(.spring(response: 0.35)) { drag[p] = nil }
                            }, including: .all)
                }
            }
            .coordinateSpace(name: "puzzle")
        }
    }
}

// MARK: - Modell

@MainActor
@Observable
final class BodyModel {
    @ObservationIgnored let host: GameHost
    var tasks: [BodyTaskKind] = []
    var index = 0

    var solved = false
    var tried: Set<String> = []
    var chosen: String?
    var highlightAnswer = false
    var highlights: [BodyPart] = []
    var info: BodyPart?
    var found: [BodyPart] = []
    var lensLayer: BodyLayer?
    var lensPos = CGPoint(x: 0.82, y: 0.86)
    var revealLayer: BodyLayer?
    var foodStep = 0
    var placed: [BodyPart] = []
    @ObservationIgnored private var lastLensPart: BodyPart?
    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var task: BodyTaskKind? { tasks[safe: index] }

    var baseLayer: BodyLayer {
        if case .weg = task { return .organe }
        return .aussen
    }

    var foodPoint: CGPoint? {
        guard case .weg = task, foodStep > 0 else { return nil }
        return FoodPath.order[foodStep - 1].center
    }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Den Körper entdeckt.") }
            let names = self.tasks.compactMap { self.subjectName($0) }
            return RoundSummary(text: "Körper entdeckt: \(names.joined(separator: ", ")).", practiced: names)
        }
        if DemoMode.flag("-koerpertest"), let demo = DemoMode.value("-koerperaufgabe") {
            tasks = Self.demoTasks(demo)
            index = 0
            present()
            return
        }
        if let saved = host.takeRestoredPayload(BodyState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            present()
        } else {
            tasks = BodyTasks.round(level: host.level)
            index = 0
            present()
        }
    }

    private func subjectName(_ t: BodyTaskKind) -> String? {
        switch t {
        case .zeigen(let p), .suchen(let p), .funktion(let p, _): return p.name
        case .entdecken: return "Zauberlupe"
        case .sinn(let q, _): return q.answer.name
        case .herz: return "Herzschlag"
        case .weg: return "Weg des Essens"
        case .puzzle: return "Organe einsetzen"
        }
    }

    private func present() {
        solved = false
        tried = []
        chosen = nil
        highlightAnswer = false
        highlights = []
        info = nil
        found = []
        revealLayer = nil
        foodStep = 0
        placed = []
        lastLensPart = nil
        lensPos = CGPoint(x: 0.82, y: 0.86)
        switch task {
        case .suchen(let p): lensLayer = p.layer
        case .entdecken(let layers): lensLayer = layers.first
        default: lensLayer = nil
        }
        host.persist(BodyState(tasks: tasks, index: index))
        instruct()
    }

    private func instruct() {
        guard let task else { return }
        switch task {
        case .zeigen(let p), .suchen(let p): host.setInstruction(p.whereQuestion)
        case .entdecken: host.setInstruction("Fahr mit der Zauberlupe über den Körper. Was findest du?")
        case .funktion(let p, _): host.setInstruction(p.functionQuestion ?? "Was macht das?")
        case .sinn(let q, _): host.setInstruction(q.question)
        case .herz(let s, _): host.setInstruction(s.question)
        case .weg: host.setInstruction(FoodPath.start)
        case .puzzle: host.setInstruction("Leg die Organe an ihren Platz im Körper.")
        }
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    func state(for key: String, correct: Bool) -> AnswerState {
        if solved && chosen == key { return .correct }
        if tried.contains(key) { return .tried }
        return .normal
    }

    // MARK: Figur antippen

    /// Bester Treffer: das gesuchte Teil zuerst, sonst das kleinste getroffene.
    private func hit(_ p: CGPoint, in parts: [BodyPart]) -> BodyPart? {
        parts.filter { distance(p, $0) <= $0.radius }.min { $0.radius < $1.radius }
    }

    private func distance(_ p: CGPoint, _ part: BodyPart) -> Double {
        part.spots.map { s in
            let dx = Double(p.x - s.x) * Double(BodyFigureView.aspect), dy = Double(p.y - s.y)
            return (dx * dx + dy * dy).squareRoot()
        }.min() ?? 1
    }

    func tap(_ p: CGPoint) {
        guard let task, !solved else { return }
        switch task {
        case .zeigen(let target):
            if distance(p, target) <= target.radius {
                solve(target, text: "\(target.thisIs) \(target.explanation)")
            } else if let other = hit(p, in: BodyPart.outer + BodyPart.face) {
                host.wrong("\(other.thisIs) \(target.whereQuestion)")
            } else {
                host.audio.effect(.tap)
            }
        case .weg:
            let expected = FoodPath.order[foodStep]
            if distance(p, expected) <= max(expected.radius, 0.05) {
                foodStep += 1
                host.audio.sfx("koerper_sfx_schlucken", fallback: .munch)
                if foodStep == FoodPath.order.count {
                    solved = true
                    highlights = FoodPath.order
                    host.taskSolved(FoodPath.steps[foodStep - 1])
                } else {
                    host.say(FoodPath.steps[foodStep - 1])
                }
            } else if hit(p, in: BodyPart.organs + [.mund]) != nil {
                host.wrong(FoodPath.hints[foodStep])
            }
        default:
            break
        }
    }

    // MARK: Zauberlupe

    func moveLens(_ p: CGPoint) {
        lensPos = CGPoint(x: min(max(p.x, 0), 1), y: min(max(p.y, 0), 1))
        guard let task, !solved, let layer = lensLayer else { return }
        let under = hit(lensPos, in: BodyPart.on(layer))
        switch task {
        case .suchen(let target):
            if distance(lensPos, target) <= target.radius {
                revealLayer = target.layer
                solve(target, text: "\(target.thisIs) \(target.explanation)")
            } else if let under, under != lastLensPart {
                lastLensPart = under
                host.say(under.thisIs)
            }
        case .entdecken:
            guard let under, under != lastLensPart else { return }
            lastLensPart = under
            info = under
            if !found.contains(under) {
                found.append(under)
                host.audio.sfx("koerper_sfx_zauber", fallback: .gentle)
            }
            if found.count >= requiredFinds {
                solved = true
                host.taskSolved("\(under.thisIs) \(under.explanation) Toll entdeckt!")
            } else {
                host.say("\(under.thisIs) \(under.explanation)")
            }
        default:
            break
        }
    }

    private var requiredFinds: Int {
        guard case .entdecken(let layers) = task else { return 0 }
        return min(3, layers.flatMap { BodyPart.on($0) }.count)
    }

    func switchLens(_ layer: BodyLayer) {
        host.audio.effect(.tap)
        lensLayer = layer
        lastLensPart = nil
        host.say(layer.lensText)
    }

    private func solve(_ part: BodyPart, text: String) {
        solved = true
        info = part
        highlights = [part]
        if part == .herz { host.audio.sfx("koerper_sfx_herzschlag", fallback: .gentle) }
        if part == .lunge { host.audio.sfx("koerper_sfx_atmen", fallback: .gentle) }
        host.taskSolved(text)
    }

    // MARK: Antwortkarten

    func chooseFunction(_ f: BodyFunction, part: BodyPart) {
        guard !solved else { return }
        if f == part.function {
            solved = true
            chosen = f.rawValue
            host.taskSolved("Ja, genau! \(part.explanation)")
        } else {
            tried.insert(f.rawValue)
            host.wrong("Das passt nicht ganz. Versuch es nochmals.")
        }
    }

    func chooseSense(_ p: BodyPart, q: SenseQuestion) {
        guard !solved else { return }
        if p == q.answer {
            solved = true
            chosen = p.rawValue
            host.taskSolved("Ja, genau! \(q.explanation)")
        } else {
            tried.insert(p.rawValue)
            host.wrong("Das passt nicht ganz. Versuch es nochmals.")
        }
    }

    func chooseHeart(fast: Bool, scene: HeartScene) {
        guard !solved else { return }
        let key = fast ? "schnell" : "langsam"
        host.audio.sfx(fast ? "koerper_sfx_herz_schnell" : "koerper_sfx_herz_langsam", fallback: .tap)
        if fast == scene.fast {
            solved = true
            chosen = key
            host.taskSolved("Ja, genau! \(scene.explanation)")
        } else {
            tried.insert(key)
            host.wrong("Hmm, schau nochmals, was Printatops gerade macht.")
        }
    }

    // MARK: Puzzle

    func place(_ p: BodyPart) {
        guard !placed.contains(p), case .puzzle(let parts) = task else { return }
        placed.append(p)
        host.audio.effect(.snap)
        if placed.count == parts.count {
            solved = true
            host.taskSolved("Super, alles ist an seinem Platz! Gehirn, Lunge, Herz und Magen arbeiten jetzt zusammen.")
        } else {
            host.say(p.thisIs)
        }
    }

    func misplaced(_ p: BodyPart) {
        host.wrong("Das gehört an einen anderen Platz. Versuch es nochmals.")
    }

    // MARK: Hilfe

    private func help(_ level: Int) {
        guard let task else { return }
        switch task {
        case .zeigen(let p), .suchen(let p):
            if level == 1 {
                host.showBunny(hintText(p))
            } else {
                highlights = [p]
                host.showBunny("Schau, hier ist es.")
            }
        case .entdecken:
            if let layer = lensLayer, let next = BodyPart.on(layer).first(where: { !found.contains($0) }) {
                highlights = [next]
                host.showBunny("Fahr mit der Lupe zum leuchtenden Kreis.")
            }
        case .weg:
            host.showBunny(FoodPath.hints[min(foodStep, FoodPath.hints.count - 1)])
            if level >= 2 { highlights = [FoodPath.order[min(foodStep, FoodPath.order.count - 1)]] }
        case .puzzle:
            highlightAnswer = true
            host.showBunny("Die gestrichelten Kreise zeigen die Plätze.")
        default:
            highlightAnswer = level >= 2
            host.showBunny(level >= 2 ? "Diese Karte leuchtet. Sie passt." : "Hör dir die Frage nochmals genau an.")
        }
    }

    private func hintText(_ p: BodyPart) -> String {
        switch p.layer {
        case .aussen: return p.spots.first!.y < 0.25 ? "Es ist im Gesicht oder am Kopf." : "Schau dir den Körper genau an."
        case .organe: return p.center.y < 0.25 ? "Es ist im Kopf." : (p.center.y < 0.42 ? "Es ist in der Brust." : "Es ist im Bauch.")
        default: return "Fahr langsam mit der Lupe über den Körper."
        }
    }

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        guard let task, !solved else { return }
        switch task {
        case .zeigen(let p): tap(p.spots[0])
        case .suchen(let p): moveLens(p.spots[0])
        case .entdecken(let layers):
            for p in layers.flatMap({ BodyPart.on($0) }) where !solved {
                lensLayer = p.layer
                moveLens(p.spots[0])
            }
        case .funktion(let p, _): chooseFunction(p.function, part: p)
        case .sinn(let q, _): chooseSense(q.answer, q: q)
        case .herz(let s, _): chooseHeart(fast: s.fast, scene: s)
        case .weg: for p in FoodPath.order where !solved { tap(p.spots[0]) }
        case .puzzle(let parts): for p in parts { place(p) }
        }
    }

    /// Feste Aufgaben für Simulator-Bilder.
    static func demoTasks(_ name: String) -> [BodyTaskKind] {
        let main: BodyTaskKind
        switch name {
        case "zeigen": main = .zeigen(.bauch)
        case "suchen": main = .suchen(.herz)
        case "entdecken": main = .entdecken([.organe, .knochen, .adern, .muskeln])
        case "funktion": main = BodyTasks.function(.lunge, options: 4)
        case "sinn": main = BodyTasks.sense(SenseCatalog.questions[0], options: 5)
        case "herz": main = .herz(HeartCatalog.scenes[0], fastLeft: true)
        case "weg": main = .weg
        default: main = .puzzle([.gehirn, .lunge, .herz, .magen])
        }
        return [main, .zeigen(.kopf), .zeigen(.hand), .zeigen(.fuss)]
    }
}
