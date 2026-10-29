import SwiftUI

struct GridPoint: Codable, Equatable, Hashable {
    var x: Int
    var y: Int
}

enum SnakeDirection: String, Codable {
    case up, down, left, right

    var delta: (Int, Int) {
        switch self {
        case .up: return (0, -1)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .right: return (1, 0)
        }
    }

    var opposite: SnakeDirection {
        switch self {
        case .up: return .down
        case .down: return .up
        case .left: return .right
        case .right: return .left
        }
    }
}

enum SnakeLayouts {
    static let size = 12

    /// Sechs geprüfte Hindernisanordnungen für «Knobeln» (lassen Start und Mitte frei).
    static let obstacles: [[GridPoint]] = [
        [GridPoint(x: 3, y: 3), GridPoint(x: 3, y: 4), GridPoint(x: 8, y: 7), GridPoint(x: 8, y: 8)],
        [GridPoint(x: 2, y: 9), GridPoint(x: 3, y: 9), GridPoint(x: 4, y: 9), GridPoint(x: 8, y: 2), GridPoint(x: 9, y: 2)],
        [GridPoint(x: 6, y: 2), GridPoint(x: 6, y: 3), GridPoint(x: 6, y: 9), GridPoint(x: 6, y: 10)],
        [GridPoint(x: 2, y: 2), GridPoint(x: 9, y: 2), GridPoint(x: 2, y: 9), GridPoint(x: 9, y: 9)],
        [GridPoint(x: 4, y: 2), GridPoint(x: 5, y: 2), GridPoint(x: 6, y: 2), GridPoint(x: 9, y: 8), GridPoint(x: 9, y: 9)],
        [GridPoint(x: 1, y: 6), GridPoint(x: 2, y: 6), GridPoint(x: 9, y: 4), GridPoint(x: 10, y: 4), GridPoint(x: 5, y: 10)]
    ]
}

struct SnakeState: Codable {
    var body: [GridPoint]
    var direction: SnakeDirection
    var fruit: GridPoint
    var fruitEmoji: String
    var obstacles: [GridPoint]
    var crashed: Bool
}

/// Spiel 4: Garten-Snake.
struct SnakeGameView: View {
    let host: GameHost
    @State private var model: SnakeModel
    @Environment(\.scenePhase) private var scenePhase

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: SnakeModel(host: host))
    }

    var body: some View {
        GeometryReader { geo in
            let boardSide = min(geo.size.height, geo.size.width * 0.62)
            HStack(spacing: 30) {
                board(side: boardSide)
                    .frame(width: boardSide, height: boardSide)
                controls
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear { model.start() }
        .onDisappear { model.pause() }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { model.pause() }
        }
    }

    private func board(side: CGFloat) -> some View {
        let n = SnakeLayouts.size
        let cell = side / CGFloat(n)
        return ZStack(alignment: .topLeading) {
            // Gartenraster
            Canvas { ctx, _ in
                for x in 0..<n {
                    for y in 0..<n where (x + y) % 2 == 0 {
                        ctx.fill(Path(CGRect(x: CGFloat(x) * cell, y: CGFloat(y) * cell, width: cell, height: cell)),
                                 with: .color(Theme.softGreen.opacity(0.35)))
                    }
                }
            }
            .background(Theme.meadow)

            if host.difficulty == .knobeln {
                Rectangle()
                    .stroke(Theme.darkGreen.opacity(0.7), lineWidth: 6)
            }

            ForEach(model.obstacles, id: \.self) { o in
                Text("🪨")
                    .font(.system(size: cell * 0.8))
                    .frame(width: cell, height: cell)
                    .offset(x: CGFloat(o.x) * cell, y: CGFloat(o.y) * cell)
            }

            Text(model.fruitEmoji)
                .font(.system(size: cell * 0.8))
                .frame(width: cell, height: cell)
                .offset(x: CGFloat(model.fruit.x) * cell, y: CGFloat(model.fruit.y) * cell)
                .pulseHighlight(model.highlightFruit)

            ForEach(Array(model.body.enumerated()), id: \.offset) { i, p in
                RoundedRectangle(cornerRadius: cell * 0.35)
                    .fill(i == 0 ? Theme.darkGreen : Theme.success.opacity(1 - Double(i) * 0.03))
                    .frame(width: cell * 0.9, height: cell * 0.9)
                    .overlay {
                        if i == 0 {
                            Text(model.crashed ? "😵" : "👀")
                                .font(.system(size: cell * 0.45))
                        }
                    }
                    .offset(x: CGFloat(p.x) * cell + cell * 0.05, y: CGFloat(p.y) * cell + cell * 0.05)
            }

            if !model.running {
                Color.black.opacity(0.18)
                VStack(spacing: 16) {
                    if model.crashed {
                        Text("Hoppla! Die Schlange ist angestossen.")
                            .font(Theme.rounded(24, .semibold))
                            .multilineTextAlignment(.center)
                        Button {
                            model.restartAfterCrash()
                        } label: {
                            Label("Nochmal los", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(BigButtonStyle(color: Theme.success))
                    } else {
                        Text(model.everStarted ? "Pause" : "Wähle eine Richtung.")
                            .font(Theme.rounded(26, .semibold))
                    }
                }
                .foregroundStyle(Theme.darkGreen)
                .padding(24)
                .background(RoundedRectangle(cornerRadius: 26).fill(Theme.cream))
                .frame(width: side, height: side)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 30)
                .onEnded { v in
                    guard host.options.snakeSwipe else { return }
                    let dx = v.translation.width, dy = v.translation.height
                    if abs(dx) > abs(dy) {
                        model.steer(dx > 0 ? .right : .left)
                    } else {
                        model.steer(dy > 0 ? .down : .up)
                    }
                }
        )
    }

    private var controls: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Früchte:")
                    .font(Theme.rounded(22, .semibold))
                ForEach(0..<host.tasksPerRound, id: \.self) { i in
                    Text(i < host.tasksDone ? "🍓" : "◯")
                        .font(.system(size: 30))
                        .opacity(i < host.tasksDone ? 1 : 0.4)
                }
            }
            .foregroundStyle(Theme.darkGreen)

            arrowButton(.up)
            HStack(spacing: 16) {
                arrowButton(.left)
                Button {
                    model.togglePause()
                } label: {
                    Image(systemName: model.running ? "pause.fill" : "play.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Theme.darkGreen)
                        .frame(width: 96, height: 96)
                        .background(Circle().fill(.white).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(model.running ? "Pause" : "Weiter")
                .disabled(model.crashed)
                arrowButton(.right)
            }
            arrowButton(.down)
        }
    }

    private func arrowButton(_ d: SnakeDirection) -> some View {
        let icon: String
        let label: String
        switch d {
        case .up: icon = "arrow.up"; label = "Nach oben"
        case .down: icon = "arrow.down"; label = "Nach unten"
        case .left: icon = "arrow.left"; label = "Nach links"
        case .right: icon = "arrow.right"; label = "Nach rechts"
        }
        return Button {
            model.steer(d)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 110, height: 110)
                .background(RoundedRectangle(cornerRadius: 28).fill(Theme.darkGreen))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Theme.highlight, lineWidth: model.suggested == d ? 7 : 0)
                )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }
}

@MainActor
@Observable
final class SnakeModel {
    @ObservationIgnored let host: GameHost
    var body: [GridPoint] = []
    var direction: SnakeDirection = .right
    var fruit = GridPoint(x: 8, y: 6)
    var fruitEmoji = "🍓"
    var obstacles: [GridPoint] = []
    var running = false
    var crashed = false
    var everStarted = false
    var suggested: SnakeDirection?
    var highlightFruit = false
    @ObservationIgnored private var queue: [SnakeDirection] = []
    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var started = false

    private let fruits = ["🍓", "🍎", "🍐", "🍒", "🫐", "🥕"]

    init(host: GameHost) { self.host = host }

    var stepSeconds: Double {
        switch host.difficulty {
        case .entdecken: return 0.65
        case .ueben: return 0.45
        case .knobeln: return 0.35
        }
    }

    var wraps: Bool { host.difficulty != .knobeln }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.summaryProvider = { [weak self] in
            let level = self?.host.difficulty.title ?? ""
            return RoundSummary(text: "Mit der Schlange fünf Früchte gesammelt (\(level)).", practiced: ["Richtungen planen"])
        }
        if let saved = host.takeRestoredPayload(SnakeState.self), !saved.body.isEmpty {
            body = saved.body
            direction = saved.direction
            fruit = saved.fruit
            fruitEmoji = saved.fruitEmoji
            obstacles = saved.obstacles
            crashed = saved.crashed
            everStarted = true
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            // Nach einer Unterbrechung wartet die Schlange auf einen bewussten Start.
            host.setInstruction("Tippe auf eine Richtung, dann geht es weiter.")
        } else {
            reset(keepingFruitCount: false)
            host.setInstruction("Sammle fünf Früchte. Tippe auf einen Pfeil.")
        }
    }

    private func reset(keepingFruitCount: Bool) {
        let mid = SnakeLayouts.size / 2
        body = [GridPoint(x: mid - 2, y: mid), GridPoint(x: mid - 3, y: mid), GridPoint(x: mid - 4, y: mid)]
        direction = .right
        if host.difficulty == .knobeln {
            obstacles = SnakeLayouts.obstacles.randomElement()!
        } else {
            obstacles = []
        }
        crashed = false
        running = false
        queue = []
        placeFruit()
        save()
    }

    private func save() {
        host.persist(SnakeState(body: body, direction: direction, fruit: fruit, fruitEmoji: fruitEmoji, obstacles: obstacles, crashed: crashed))
    }

    private func placeFruit() {
        let n = SnakeLayouts.size
        var free: [GridPoint] = []
        let head = body.first ?? GridPoint(x: 0, y: 0)
        for x in 0..<n {
            for y in 0..<n {
                let p = GridPoint(x: x, y: y)
                if body.contains(p) || obstacles.contains(p) { continue }
                // In «Knobeln» nicht direkt an den Rand legen.
                if !wraps && (x == 0 || y == 0 || x == n - 1 || y == n - 1) { continue }
                // Nicht zu nah am Kopf, aber auch nicht zu weit für Anfänger.
                let dist = abs(p.x - head.x) + abs(p.y - head.y)
                if dist < 3 { continue }
                if host.difficulty == .entdecken && dist > 8 { continue }
                free.append(p)
            }
        }
        fruit = free.randomElement() ?? GridPoint(x: 1, y: 1)
        fruitEmoji = fruits.randomElement()!
    }

    func steer(_ d: SnakeDirection) {
        guard !crashed else { return }
        host.audio.effect(.tap)
        suggested = nil
        // Kontrollierte Verarbeitung schneller Befehle: höchstens zwei vorgemerkt, keine Umkehr.
        let last = queue.last ?? direction
        if d == last || d == last.opposite && body.count > 1 {
            if !running { resume() }
            return
        }
        if queue.count < 2 { queue.append(d) }
        if !running { resume() }
    }

    func togglePause() {
        if running {
            pause()
        } else if !crashed {
            resume()
        }
    }

    func resume() {
        guard !running, !crashed else { return }
        running = true
        everStarted = true
        host.audio.stopVoice()
        loop?.cancel()
        loop = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled, self.running {
                try? await Task.sleep(nanoseconds: UInt64(self.stepSeconds * 1_000_000_000))
                guard !Task.isCancelled, self.running else { return }
                self.step()
            }
        }
    }

    func pause() {
        running = false
        loop?.cancel()
        loop = nil
        if started { save() }
    }

    private func step() {
        if let next = queue.first {
            queue.removeFirst()
            if next != direction.opposite || body.count <= 1 { direction = next }
        }
        let n = SnakeLayouts.size
        guard let head = body.first else { return }
        var nx = head.x + direction.delta.0
        var ny = head.y + direction.delta.1
        if wraps {
            nx = (nx + n) % n
            ny = (ny + n) % n
        } else if nx < 0 || ny < 0 || nx >= n || ny >= n {
            crash()
            return
        }
        let newHead = GridPoint(x: nx, y: ny)
        let eating = newHead == fruit
        let bodyToCheck = eating ? body : Array(body.dropLast())
        if bodyToCheck.contains(newHead) || obstacles.contains(newHead) {
            crash()
            return
        }
        body.insert(newHead, at: 0)
        if eating {
            host.audio.effect(.munch)
            highlightFruit = false
            host.resetHelp()
            placeFruit()
            host.taskSolved(host.tasksDone + 1 >= host.tasksPerRound ? "" : "Mjam! \(NumberWords.word(host.tasksDone + 1).capitalizedFirst).", needsNext: false)
            if host.tasksDone >= host.tasksPerRound {
                pause()
                return
            }
            save()
        } else {
            body.removeLast()
        }
    }

    private func crash() {
        running = false
        crashed = true
        loop?.cancel()
        host.audio.effect(.bump)
        host.showBunny("Hoppla! Tippe auf «Nochmal los». Deine Früchte bleiben.")
        save()
    }

    /// Sicherer Neustart: gesammelte Früchte bleiben erhalten.
    func restartAfterCrash() {
        host.audio.effect(.tap)
        reset(keepingFruitCount: true)
        host.setInstruction("Tippe auf einen Pfeil, dann geht es los.")
    }

    // MARK: Hilfe

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        if crashed { restartAfterCrash(); return }
        pause()
        guard let head = body.first else { return }
        let n = SnakeLayouts.size
        let target = GridPoint(x: (head.x + direction.delta.0 + n) % n, y: (head.y + direction.delta.1 + n) % n)
        if !obstacles.contains(target) && !body.contains(target) { fruit = target }
        step()
    }

    private func help(_ level: Int) {
        guard let head = body.first else { return }
        let dx = fruit.x - head.x
        let dy = fruit.y - head.y
        var best: SnakeDirection = abs(dx) >= abs(dy) ? (dx > 0 ? .right : .left) : (dy > 0 ? .down : .up)
        if best == direction.opposite {
            best = abs(dx) >= abs(dy) ? (dy >= 0 ? .down : .up) : (dx >= 0 ? .right : .left)
        }
        switch level {
        case 1:
            highlightFruit = true
            host.showBunny("Dort ist die Frucht. Wohin muss die Schlange?")
        case 2:
            highlightFruit = true
            suggested = best
            host.showBunny("Versuch diesen Pfeil.")
        default:
            highlightFruit = true
            suggested = best
            if running { pause() }
            host.showBunny("Ich mache langsamer. Tippe auf den leuchtenden Pfeil.")
        }
    }
}
