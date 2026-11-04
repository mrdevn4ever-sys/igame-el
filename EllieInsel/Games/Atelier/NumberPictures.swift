import SwiftUI

// MARK: - Bilder

/// Eine Fläche im Zahlenbild. Koordinaten relativ zur Zeichenfläche (0…1, Seitenverhältnis 4:3).
struct NumberRegion {
    /// Farbgruppe im Bild (gleiche Gruppe = gleiche Zahl und Farbe)
    let group: Int
    /// Wo die Zahl steht
    let label: CGPoint
    let path: Path
}

/// Linien und Punkte, die nicht ausgemalt werden (Faden, Auge, Fühler).
struct NumberDecor {
    let path: Path
    let fill: Bool
    let width: CGFloat
}

struct NumberPicture: Identifiable {
    let id: String
    let title: String
    /// Farbe je Gruppe
    let colors: [Palette]
    let regions: [NumberRegion]
    var decor: [NumberDecor] = []

    var groupCount: Int { colors.count }
}

/// Bausteine in Einheitskoordinaten. Kreise berücksichtigen das Seitenverhältnis, damit sie rund bleiben.
private enum NPGeo {
    static let aspect: CGFloat = 4.0 / 3.0

    static func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
        Path(CGRect(x: x, y: y, width: w, height: h))
    }

    static func ellipse(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        Path(ellipseIn: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))
    }

    /// Kreis mit Radius in Breiten-Einheiten
    static func circle(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        ellipse(cx, cy, r, r * aspect)
    }

    static func poly(_ pts: [(CGFloat, CGFloat)]) -> Path {
        var p = Path()
        guard let f = pts.first else { return p }
        p.move(to: CGPoint(x: f.0, y: f.1))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
        p.closeSubpath()
        return p
    }

    /// Obere Hälfte einer Ellipse (Pilzhut)
    static func dome(_ cx: CGFloat, _ cy: CGFloat, _ rx: CGFloat, _ ry: CGFloat) -> Path {
        poly((0...24).map { i in
            let t = CGFloat.pi + CGFloat(i) / 24 * CGFloat.pi
            return (cx + rx * cos(t), cy + ry * sin(t))
        })
    }

    static func star(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) -> Path {
        poly((0..<10).map { i in
            let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 5
            let rr = i % 2 == 0 ? r : r * 0.48
            return (cx + rr * cos(a), cy + rr * sin(a) * aspect)
        })
    }

    static func line(_ pts: [(CGFloat, CGFloat)]) -> Path {
        var p = Path()
        guard let f = pts.first else { return p }
        p.move(to: CGPoint(x: f.0, y: f.1))
        for q in pts.dropFirst() { p.addLine(to: CGPoint(x: q.0, y: q.1)) }
        return p
    }

    static func region(_ g: Int, _ lx: CGFloat, _ ly: CGFloat, _ path: Path) -> NumberRegion {
        NumberRegion(group: g, label: CGPoint(x: lx, y: ly), path: path)
    }
}

enum NumberPictures {
    /// Einfache Bilder mit drei Farben (für den Anfang)
    static let simple: [String] = ["ballon", "pilz", "apfel"]

    static let all: [NumberPicture] = [ballon, pilz, apfel, haus, fisch, blume, rakete, schmetterling]

    static func picture(_ id: String) -> NumberPicture? { all.first { $0.id == id } }

    static let ballon = NumberPicture(
        id: "ballon", title: "Ballone",
        colors: [.blue, .red, .green],
        regions: [
            NPGeo.region(0, 0.12, 0.14, NPGeo.rect(0, 0, 1, 0.78)),
            NPGeo.region(2, 0.12, 0.89, NPGeo.rect(0, 0.78, 1, 0.22)),
            NPGeo.region(1, 0.5, 0.36, NPGeo.circle(0.5, 0.36, 0.15)),
            NPGeo.region(1, 0.24, 0.44, NPGeo.circle(0.24, 0.44, 0.08)),
            NPGeo.region(1, 0.78, 0.3, NPGeo.circle(0.78, 0.3, 0.09))
        ],
        decor: [
            NumberDecor(path: NPGeo.line([(0.5, 0.56), (0.48, 0.68), (0.5, 0.82)]), fill: false, width: 3),
            NumberDecor(path: NPGeo.line([(0.24, 0.547), (0.26, 0.66), (0.25, 0.8)]), fill: false, width: 3),
            NumberDecor(path: NPGeo.line([(0.78, 0.42), (0.76, 0.6), (0.77, 0.8)]), fill: false, width: 3)
        ]
    )

    static let pilz = NumberPicture(
        id: "pilz", title: "Pilze",
        colors: [.green, .red, .yellow],
        regions: [
            NPGeo.region(0, 0.1, 0.13, NPGeo.rect(0, 0, 1, 1)),
            NPGeo.region(2, 0.5, 0.72, NPGeo.rect(0.41, 0.5, 0.18, 0.36)),
            NPGeo.region(1, 0.5, 0.36, NPGeo.dome(0.5, 0.52, 0.28, 0.32)),
            NPGeo.region(2, 0.8, 0.79, NPGeo.rect(0.76, 0.67, 0.08, 0.2)),
            NPGeo.region(1, 0.8, 0.6, NPGeo.dome(0.8, 0.68, 0.12, 0.15))
        ]
    )

    static let apfel = NumberPicture(
        id: "apfel", title: "Apfel",
        colors: [.yellow, .red, .green],
        regions: [
            NPGeo.region(0, 0.1, 0.13, NPGeo.rect(0, 0, 1, 1)),
            NPGeo.region(1, 0.5, 0.58, NPGeo.circle(0.5, 0.58, 0.24)),
            NPGeo.region(2, 0.63, 0.2, NPGeo.ellipse(0.63, 0.2, 0.1, 0.065)),
            NPGeo.region(1, 0.84, 0.8, NPGeo.circle(0.84, 0.8, 0.08))
        ],
        decor: [NumberDecor(path: NPGeo.line([(0.5, 0.27), (0.51, 0.16)]), fill: false, width: 7)]
    )

    static let haus = NumberPicture(
        id: "haus", title: "Haus",
        colors: [.blue, .green, .yellow, .red, .brown],
        regions: [
            NPGeo.region(0, 0.1, 0.12, NPGeo.rect(0, 0, 1, 0.76)),
            NPGeo.region(1, 0.1, 0.88, NPGeo.rect(0, 0.76, 1, 0.24)),
            NPGeo.region(2, 0.85, 0.17, NPGeo.circle(0.85, 0.17, 0.07)),
            NPGeo.region(2, 0.37, 0.52, NPGeo.rect(0.3, 0.42, 0.4, 0.37)),
            NPGeo.region(3, 0.5, 0.34, NPGeo.poly([(0.25, 0.43), (0.5, 0.17), (0.75, 0.43)])),
            NPGeo.region(4, 0.51, 0.69, NPGeo.rect(0.45, 0.58, 0.12, 0.21)),
            NPGeo.region(0, 0.64, 0.555, NPGeo.rect(0.6, 0.5, 0.08, 0.11))
        ]
    )

    static let fisch = NumberPicture(
        id: "fisch", title: "Fisch",
        colors: [.blue, .orange, .yellow, .green],
        regions: [
            NPGeo.region(0, 0.1, 0.12, NPGeo.rect(0, 0, 1, 0.8)),
            NPGeo.region(2, 0.5, 0.9, NPGeo.rect(0, 0.8, 1, 0.2)),
            NPGeo.region(3, 0.135, 0.72, NPGeo.poly([(0.09, 0.82), (0.07, 0.52), (0.17, 0.6), (0.19, 0.82)])),
            NPGeo.region(3, 0.87, 0.71, NPGeo.poly([(0.82, 0.82), (0.85, 0.48), (0.93, 0.58), (0.92, 0.82)])),
            NPGeo.region(1, 0.47, 0.235, NPGeo.poly([(0.33, 0.34), (0.48, 0.15), (0.59, 0.34)])),
            NPGeo.region(1, 0.73, 0.45, NPGeo.poly([(0.6, 0.45), (0.79, 0.29), (0.79, 0.61)])),
            NPGeo.region(1, 0.45, 0.47, NPGeo.ellipse(0.44, 0.45, 0.2, 0.17))
        ],
        decor: [
            NumberDecor(path: NPGeo.circle(0.32, 0.42, 0.018), fill: true, width: 0),
            NumberDecor(path: NPGeo.circle(0.2, 0.3, 0.02), fill: false, width: 3),
            NumberDecor(path: NPGeo.circle(0.17, 0.18, 0.014), fill: false, width: 3)
        ]
    )

    static let blume = NumberPicture(
        id: "blume", title: "Blume",
        colors: [.blue, .pink, .yellow, .green, .brown],
        regions: [
            NPGeo.region(0, 0.1, 0.12, NPGeo.rect(0, 0, 1, 0.82)),
            NPGeo.region(4, 0.1, 0.91, NPGeo.rect(0, 0.82, 1, 0.18)),
            NPGeo.region(3, 0.39, 0.66, NPGeo.ellipse(0.39, 0.66, 0.09, 0.05)),
            NPGeo.region(3, 0.61, 0.6, NPGeo.ellipse(0.61, 0.6, 0.09, 0.05))
        ] + (0..<6).map { i -> NumberRegion in
            let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 3
            let cx = 0.5 + 0.128 * cos(a), cy = 0.33 + 0.128 * sin(a) * NPGeo.aspect
            return NPGeo.region(1, cx, cy, NPGeo.circle(cx, cy, 0.062))
        } + [
            NPGeo.region(2, 0.5, 0.33, NPGeo.circle(0.5, 0.33, 0.064))
        ],
        decor: [NumberDecor(path: NPGeo.line([(0.5, 0.58), (0.5, 0.83)]), fill: false, width: 9)]
    )

    static let rakete = NumberPicture(
        id: "rakete", title: "Rakete",
        colors: [.purple, .red, .blue, .orange, .yellow],
        regions: [
            NPGeo.region(0, 0.1, 0.12, NPGeo.rect(0, 0, 1, 1)),
            NPGeo.region(4, 0.2, 0.32, NPGeo.star(0.2, 0.32, 0.07)),
            NPGeo.region(4, 0.82, 0.2, NPGeo.star(0.82, 0.2, 0.06)),
            NPGeo.region(4, 0.78, 0.7, NPGeo.star(0.78, 0.7, 0.07)),
            NPGeo.region(3, 0.5, 0.84, NPGeo.poly([(0.43, 0.78), (0.57, 0.78), (0.5, 0.96)])),
            NPGeo.region(1, 0.385, 0.73, NPGeo.poly([(0.42, 0.58), (0.42, 0.78), (0.33, 0.78)])),
            NPGeo.region(1, 0.615, 0.73, NPGeo.poly([(0.58, 0.58), (0.58, 0.78), (0.67, 0.78)])),
            NPGeo.region(1, 0.5, 0.65, NPGeo.poly([(0.42, 0.78), (0.42, 0.35), (0.5, 0.14), (0.58, 0.35), (0.58, 0.78)])),
            NPGeo.region(2, 0.5, 0.43, NPGeo.circle(0.5, 0.43, 0.045))
        ]
    )

    static let schmetterling = NumberPicture(
        id: "schmetterling", title: "Schmetterling",
        colors: [.blue, .purple, .brown, .yellow],
        regions: [
            NPGeo.region(0, 0.08, 0.12, NPGeo.rect(0, 0, 1, 1)),
            NPGeo.region(1, 0.29, 0.3, NPGeo.ellipse(0.35, 0.37, 0.15, 0.18)),
            NPGeo.region(1, 0.71, 0.3, NPGeo.ellipse(0.65, 0.37, 0.15, 0.18)),
            NPGeo.region(1, 0.37, 0.69, NPGeo.ellipse(0.4, 0.65, 0.1, 0.12)),
            NPGeo.region(1, 0.63, 0.69, NPGeo.ellipse(0.6, 0.65, 0.1, 0.12)),
            NPGeo.region(3, 0.37, 0.44, NPGeo.circle(0.37, 0.44, 0.042)),
            NPGeo.region(3, 0.63, 0.44, NPGeo.circle(0.63, 0.44, 0.042)),
            NPGeo.region(2, 0.5, 0.5, NPGeo.ellipse(0.5, 0.5, 0.037, 0.25))
        ],
        decor: [
            NumberDecor(path: NPGeo.line([(0.49, 0.27), (0.44, 0.12)]), fill: false, width: 4),
            NumberDecor(path: NPGeo.line([(0.51, 0.27), (0.56, 0.12)]), fill: false, width: 4)
        ]
    )
}

// MARK: - Schwierigkeit

/// Stufen für Malen nach Zahlen. Richtet sich nach dem Niveau im Zählgarten.
enum NumberTier: Int, Codable {
    /// Punkte in den Flächen, Zahlen 1–3
    case punkte = 1
    /// Ziffern bis 5, Farbtöpfe mit Punkten
    case ziffern = 2
    /// Ziffern bis 9
    case gross = 3
    /// Plusaufgaben in den Flächen
    case rechnen = 4

    static func forCountingLevel(_ l: Int) -> NumberTier {
        switch l {
        case ...1: return .punkte
        case 2: return .ziffern
        case 3, 4: return .gross
        default: return .rechnen
        }
    }

    var maxNumber: Int {
        switch self {
        case .punkte: return 3
        case .ziffern: return 5
        case .gross, .rechnen: return 9
        }
    }

    var pictures: [String] {
        self == .punkte ? NumberPictures.simple : NumberPictures.all.map(\.id)
    }

    var potsShowDots: Bool { self == .punkte || self == .ziffern }
}

/// Gespeicherter Stand von «Malen nach Zahlen».
struct NumberPaintState: Codable, Equatable {
    var tier: NumberTier
    var pictureIDs: [String]
    var index: Int
    /// Zahl je Farbgruppe des aktuellen Bildes
    var numbers: [Int]
    /// Plusaufgaben je Fläche (nur Stufe «rechnen»): erster Summand
    var addends: [Int]
    var filled: Set<Int>
}

// MARK: - Spiellogik

@MainActor
@Observable
final class NumberPaintModel {
    @ObservationIgnored let host: GameHost
    private(set) var state: NumberPaintState
    var selectedGroup: Int?
    /// Hervorgehobene Gruppe (Hilfe)
    var hintGroup: Int?
    /// Zuletzt falsch angetippte Fläche (kurzes Wackeln)
    var shakeRegion: Int?
    @ObservationIgnored private var solved = false

    init(host: GameHost, restored: NumberPaintState?) {
        self.host = host
        if let restored, restored.pictureIDs.indices.contains(restored.index), NumberPictures.picture(restored.pictureIDs[restored.index]) != nil {
            state = restored
        } else {
            let tier = NumberTier.forCountingLevel(host.app.data.level(for: .counting))
            // Abwechslung: Bilder, die am längsten nicht dran waren, zuerst
            let ids = Array(Variety.freshFirst(tier.pictures, recent: host.app.recent(.atelier), key: { "bild:" + $0 }).prefix(host.tasksPerRound))
            host.app.remember(.atelier, ids.map { "bild:" + $0 })
            state = NumberPaintState(tier: tier, pictureIDs: ids, index: 0, numbers: [], addends: [], filled: [])
            prepare()
        }
        solved = isComplete
    }

    var picture: NumberPicture { NumberPictures.picture(state.pictureIDs[state.index]) ?? NumberPictures.ballon }
    var tier: NumberTier { state.tier }
    var isComplete: Bool { state.filled.count >= picture.regions.count }

    /// Zahlen verteilen und (Stufe «rechnen») Plusaufgaben je Fläche wählen.
    private func prepare() {
        let pic = picture
        let pool = Array(1...max(state.tier.maxNumber, pic.groupCount))
        // Beim Rechnen nur Ergebnisse ab 2, damit es eine echte Plusaufgabe gibt.
        let usable = state.tier == .rechnen ? pool.filter { $0 >= 2 } : pool
        state.numbers = Array(usable.shuffled().prefix(pic.groupCount))
        state.addends = pic.regions.map { r in
            let n = state.numbers[r.group]
            return n >= 2 ? Int.random(in: 1...(n - 1)) : 0
        }
        state.filled = []
        selectedGroup = nil
        hintGroup = nil
        solved = false
    }

    func number(ofGroup g: Int) -> Int { state.numbers[safe: g] ?? 0 }

    /// Beschriftung einer Fläche: Punkte, Ziffer oder Plusaufgabe.
    func label(forRegion i: Int) -> String {
        let r = picture.regions[i]
        let n = number(ofGroup: r.group)
        switch state.tier {
        case .punkte: return String(repeating: "•", count: n)
        case .ziffern, .gross: return "\(n)"
        case .rechnen:
            let a = state.addends[safe: i] ?? 0
            return a > 0 ? "\(a)+\(n - a)" : "\(n)"
        }
    }

    /// Farbtöpfe sortiert nach Zahl.
    var pots: [Int] {
        picture.colors.indices.sorted { number(ofGroup: $0) < number(ofGroup: $1) }
    }

    func groupDone(_ g: Int) -> Bool {
        picture.regions.indices.allSatisfy { picture.regions[$0].group != g || state.filled.contains($0) }
    }

    func instruction() {
        host.setInstruction(state.tier == .punkte
            ? "Zähle die Punkte. Wähle die Farbe mit dieser Zahl und tippe auf die Fläche."
            : "Wähle eine Farbe und tippe auf die Flächen mit dieser Zahl.")
    }

    func selectPot(_ g: Int) {
        guard !solved else { return }
        host.audio.effect(.tap)
        selectedGroup = g
        host.audio.say(NumberWords.word(number(ofGroup: g)))
    }

    /// Fläche unter dem Finger (oberste zuerst).
    func region(at p: CGPoint, size: CGSize) -> Int? {
        guard size.width > 0, size.height > 0 else { return nil }
        let u = CGPoint(x: p.x / size.width, y: p.y / size.height)
        return picture.regions.indices.reversed().first { picture.regions[$0].path.contains(u) }
    }

    func tap(at p: CGPoint, size: CGSize) {
        guard !solved, let i = region(at: p, size: size), !state.filled.contains(i) else { return }
        let g = picture.regions[i].group
        guard let sel = selectedGroup else {
            host.showBunny("Das ist die \(NumberWords.word(number(ofGroup: g))). Wähle unten die Farbe mit dieser Zahl.")
            return
        }
        if sel == g {
            fill(i)
        } else {
            shakeRegion = i
            host.wrong("Das ist die \(NumberWords.word(number(ofGroup: g))).")
            Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 450_000_000)
                self?.shakeRegion = nil
            }
        }
    }

    private func fill(_ i: Int) {
        withAnimation(.easeOut(duration: 0.25)) { _ = state.filled.insert(i) }
        host.audio.effect(.snap)
        if hintGroup != nil, groupDone(hintGroup!) { hintGroup = nil }
        persist()
        if isComplete { complete() }
    }

    private func complete() {
        guard !solved else { return }
        solved = true
        selectedGroup = nil
        persist()
        host.taskSolved("Super!")
    }

    func nextPicture() {
        state.index = min(state.index + 1, state.pictureIDs.count - 1)
        prepare()
        persist()
        instruction()
    }

    /// Nach dem Wiederherstellen: eine fertige Fläche wartet ggf. noch auf «Weiter».
    func resumeCompleted() {
        if isComplete && !solved { complete() }
    }

    @ObservationIgnored var onChange: (() -> Void)?
    private func persist() { onChange?() }

    // MARK: Hilfe

    private var firstOpenGroup: Int? {
        if let s = selectedGroup, !groupDone(s) { return s }
        return picture.regions.indices.first { !state.filled.contains($0) }.map { picture.regions[$0].group }
    }

    func help(_ level: Int) {
        guard !solved else { return }
        switch level {
        case 1:
            host.showBunny("Schau auf die Zahl in der Fläche. Der Farbtopf mit derselben Zahl passt.")
        case 2:
            guard let g = firstOpenGroup else { return }
            selectedGroup = g
            hintGroup = g
            host.showBunny("Schau, hier passt diese Farbe.")
        default:
            guard let g = firstOpenGroup else { return }
            selectedGroup = g
            host.showBunny("Wir malen diese Flächen gemeinsam aus.")
            for i in picture.regions.indices where picture.regions[i].group == g && !state.filled.contains(i) {
                fill(i)
            }
        }
    }

    /// Automatischer Durchlauf: nächste offene Fläche richtig ausmalen.
    func debugSolve() {
        guard !solved, let i = picture.regions.indices.first(where: { !state.filled.contains($0) }) else { return }
        selectedGroup = picture.regions[i].group
        fill(i)
    }
}

// MARK: - Ansicht

struct NumberPaintView: View {
    @Bindable var model: NumberPaintModel

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let w = min(geo.size.width, geo.size.height * 4 / 3)
                let h = w * 3 / 4
                let size = CGSize(width: w, height: h)
                ZStack(alignment: .topLeading) {
                    Canvas { ctx, sz in draw(ctx, size: sz) }
                        .frame(width: w, height: h)
                    ForEach(model.picture.regions.indices, id: \.self) { i in
                        if !model.state.filled.contains(i) {
                            regionLabel(i, width: w)
                                .position(x: model.picture.regions[i].label.x * w, y: model.picture.regions[i].label.y * h)
                                .offset(x: model.shakeRegion == i ? 6 : 0)
                                .animation(model.shakeRegion == i ? .easeInOut(duration: 0.07).repeatCount(5, autoreverses: true) : .default,
                                           value: model.shakeRegion)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .frame(width: w, height: h)
                .contentShape(Rectangle())
                .onTapGesture(coordinateSpace: .local) { p in model.tap(at: p, size: size) }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: .black.opacity(0.12), radius: 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Zahlenbild \(model.picture.title)")
            }
            pots
        }
    }

    private func draw(_ ctx: GraphicsContext, size: CGSize) {
        let t = CGAffineTransform(scaleX: size.width, y: size.height)
        let pic = model.picture
        for (i, r) in pic.regions.enumerated() {
            let path = r.path.applying(t)
            let filled = model.state.filled.contains(i)
            let color: Color = filled ? pic.colors[r.group].color : .white
            ctx.fill(path, with: .color(color))
            if !filled, model.hintGroup == r.group {
                ctx.fill(path, with: .color(Theme.highlight.opacity(0.35)))
            }
        }
        for r in pic.regions {
            ctx.stroke(r.path.applying(t), with: .color(Color(white: 0.25)), style: StrokeStyle(lineWidth: 3, lineJoin: .round))
        }
        for d in pic.decor {
            let path = d.path.applying(t)
            if d.fill {
                ctx.fill(path, with: .color(Color(white: 0.2)))
            } else {
                ctx.stroke(path, with: .color(Color(white: 0.25)), style: StrokeStyle(lineWidth: d.width, lineCap: .round))
            }
        }
    }

    @ViewBuilder
    private func regionLabel(_ i: Int, width: CGFloat) -> some View {
        let text = model.label(forRegion: i)
        let base = max(min(width / 22, 40), 22)
        if model.tier == .punkte {
            // Punkte zum Zählen: grosse, deutliche Kreise
            let n = model.number(ofGroup: model.picture.regions[i].group)
            HStack(spacing: base * 0.22) {
                ForEach(0..<n, id: \.self) { _ in
                    Circle().fill(Theme.darkGreen).frame(width: base * 0.5, height: base * 0.5)
                }
            }
            .padding(.horizontal, 8).padding(.vertical, 5)
            .background(Capsule().fill(.white.opacity(0.75)))
            .fixedSize()
        } else {
        Text(text)
            .font(Theme.rounded(model.tier == .punkte ? base * 1.1 : (model.tier == .rechnen ? base * 0.8 : base), .heavy))
            .foregroundStyle(Theme.darkGreen)
            .padding(.horizontal, 6)
            .background(Capsule().fill(.white.opacity(0.75)))
            .fixedSize()
        }
    }

    private var pots: some View {
        HStack(spacing: 14) {
            ForEach(model.pots, id: \.self) { g in
                let n = model.number(ofGroup: g)
                let done = model.groupDone(g)
                Button { model.selectPot(g) } label: {
                    VStack(spacing: 2) {
                        Text("\(n)")
                            .font(Theme.rounded(34, .heavy))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.35), radius: 1)
                        if model.tier.potsShowDots {
                            Text(String(repeating: "•", count: n))
                                .font(.system(size: n > 4 ? 14 : 18, weight: .black))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                    }
                    .frame(width: 84, height: 84)
                    .background(Circle().fill(model.picture.colors[g].color))
                    .overlay(Circle().stroke(Theme.darkGreen, lineWidth: model.selectedGroup == g ? 6 : 0).padding(-4))
                    .overlay(alignment: .topTrailing) {
                        if done {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 26))
                                .foregroundStyle(Theme.success, .white)
                        }
                    }
                    .opacity(done ? 0.55 : 1)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Farbe \(model.picture.colors[g].name), Zahl \(n)")
            }
        }
        .frame(height: 100)
    }
}
