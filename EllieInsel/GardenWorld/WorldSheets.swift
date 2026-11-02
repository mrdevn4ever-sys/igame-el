import SwiftUI

/// Abgedunkelter Hintergrund mit Karte in der Mitte.
struct WorldDialog<Content: View>: View {
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea().onTapGesture(perform: close)
            VStack(spacing: 18) { content() }
                .padding(28)
                .background(RoundedRectangle(cornerRadius: 36, style: .continuous).fill(Theme.cream).shadow(color: .black.opacity(0.25), radius: 20, y: 6))
                .overlay(alignment: .topTrailing) {
                    Button(action: close) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 34)).foregroundStyle(Theme.darkGreen.opacity(0.55))
                    }
                    .padding(14)
                    .accessibilityLabel("Schliessen")
                }
                .padding(30)
        }
        .transition(.opacity)
    }
}

// MARK: - Samen

struct SeedPickerView: View {
    let model: GardenWorldModel
    let bed: Int

    var body: some View {
        let seeds = bed == 99 ? model.w.seeds.filter { !$0.isTree } : model.availableSeeds(for: bed)
        WorldDialog(close: { model.overlay = nil }) {
            Text(bed == 3 ? "Ein Baum für den Baumplatz" : "Welchen Samen pflanzt du?")
                .font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            if seeds.isEmpty {
                Text(bed == 3 ? "Apfelbaum-Samen bekommst du als Geschenk nach einem Lernspiel." : "Noch keine Samen.")
                    .font(Theme.rounded(20, .medium)).foregroundStyle(Theme.darkGreen)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(seeds) { p in
                        Button {
                            model.plant(p, in: bed)
                        } label: {
                            WorldCard(asset: p.seedAsset, emoji: p.emoji, title: p.name, subtitle: harvestHint(p), size: 140)
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
                .padding(6)
            }
            .frame(maxWidth: 760)
        }
        .onAppear {
            if seeds.count > 0 { model.say("Such dir einen Samen aus.") }
        }
    }

    private func harvestHint(_ p: PlantKind) -> String {
        switch p.style {
        case .pick: return p.isFlower ? "Blüten pflücken" : "Einzeln pflücken"
        case .pull: return "Aus der Erde ziehen"
        case .heavy: return "Gross und schwer"
        case .shake: return "Baum schütteln"
        case .seeds: return "Kerne für Vögel"
        }
    }
}

// MARK: - Sonnenblume

struct SunflowerView: View {
    let model: GardenWorldModel
    let bed: Int

    var body: some View {
        let remaining = model.w.beds[bed].remaining
        WorldDialog(close: { model.overlay = nil }) {
            Text("Löse die Kerne heraus").font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            ZStack {
                WorldPic("gw_ernte_sonnenblumenkopf", "🌻", size: 340)
                ForEach(0..<remaining, id: \.self) { i in
                    let a = Double(i) / 5 * 2 * .pi
                    Button { model.sunflowerSeed(bed) } label: {
                        WorldPic("gw_ernte_sonnenblumenkerne", "🌰", size: 64)
                            .background(Circle().fill(Theme.highlight.opacity(0.35)))
                    }
                    .buttonStyle(PressableStyle())
                    .offset(x: cos(a) * 80, y: sin(a) * 80)
                }
            }
            .frame(width: 360, height: 360)
            Text("Die Kerne kannst du in die Futterstelle für die Vögel legen.")
                .font(Theme.rounded(18, .medium)).foregroundStyle(Theme.darkGreen)
        }
    }
}

// MARK: - Picknick

struct PicnicSheet: View {
    let model: GardenWorldModel
    @State private var chosen: [DishKind] = []
    @State private var blanket = 0
    @State private var plates = 0

    var body: some View {
        let dishes = DishKind.allCases.filter { model.w.count($0) > 0 }
        let guests = model.guests(in: .haus)
        WorldDialog(close: { model.overlay = nil }) {
            Text("Picknick vorbereiten").font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            HStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text("1. Was bringst du mit?").font(Theme.rounded(19, .bold)).foregroundStyle(Theme.darkGreen)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(110), spacing: 10), count: 3), spacing: 10) {
                        ForEach(dishes) { d in
                            let n = chosen.filter { $0 == d }.count
                            Button {
                                model.app.audio.effect(.tap)
                                if n < model.w.count(d) && chosen.count < 3 { chosen.append(d) } else { chosen.removeAll { $0 == d } }
                            } label: {
                                WorldCard(asset: d.asset, emoji: d.emoji, title: d.name, subtitle: "\(model.w.count(d))×", selected: n > 0, size: 110)
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
                VStack(spacing: 14) {
                    Text("2. Welche Decke?").font(Theme.rounded(19, .bold)).foregroundStyle(Theme.darkGreen)
                    HStack(spacing: 10) {
                        ForEach(0..<3, id: \.self) { i in
                            Button { blanket = i; model.app.audio.effect(.tap) } label: {
                                WorldPic(["gw_picknickdecke_rot", "gw_picknickdecke_blau", "gw_picknickdecke_blumen"][i], ["🟥", "🟦", "🟨"][i], size: 70)
                                    .padding(4)
                                    .background(RoundedRectangle(cornerRadius: 14).stroke(Theme.highlight, lineWidth: blanket == i ? 4 : 0))
                            }
                        }
                    }
                    Text("3. Stell für jeden Gast einen Teller hin.").font(Theme.rounded(19, .bold)).foregroundStyle(Theme.darkGreen)
                    HStack(spacing: 6) {
                        WorldPic("gw_dino_sitzen", "🦕", size: 50)
                        ForEach(model.presentResidents(.haus).filter { ![.fisch, .schmetterling, .schnecke].contains($0) }.prefix(guests - 1), id: \.self) { r in
                            WorldPic(r.asset(r.idlePose), r.emoji, size: 44)
                        }
                    }
                    HStack(spacing: 8) {
                        ForEach(0..<guests, id: \.self) { i in
                            ZStack {
                                Circle().stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 4])).foregroundStyle(Theme.darkGreen.opacity(0.5))
                                if i < plates { WorldPic("gw_teller", "🍽️", size: 46) }
                            }
                            .frame(width: 56, height: 56)
                        }
                    }
                    Button {
                        guard plates < guests else { return }
                        plates += 1
                        model.app.audio.sfx("gw_sfx_teller", fallback: .snap)
                        model.app.audio.say(NumberWords.word(plates))
                    } label: {
                        Label("Teller hinstellen", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: Theme.lightYellow, foreground: Theme.darkGreen))
                }
            }
            Button {
                model.startPicnic(dishes: chosen, blanket: blanket, plates: plates)
            } label: {
                Label("Picknick beginnen", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(BigButtonStyle(color: Theme.success))
            .disabled(chosen.isEmpty || plates < guests)
            .opacity(chosen.isEmpty || plates < guests ? 0.5 : 1)
        }
        .onAppear {
            model.say("Such aus, was du mitbringst. Dann stell für jeden Gast einen Teller hin. Es \(guests == 1 ? "kommt ein Gast" : "kommen \(NumberWords.word(guests)) Gäste").")
        }
    }
}

// MARK: - Karte

struct IslandMapView: View {
    let model: GardenWorldModel

    var body: some View {
        WorldDialog(close: { model.overlay = nil }) {
            Text("Die Entdeckerinsel").font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            GeometryReader { geo in
                let s = geo.size
                ZStack {
                    if let img = ImageCache.image("gw_szene_inselkarte") {
                        Image(uiImage: img).resizable().scaledToFill().frame(width: s.width, height: s.height).clipped()
                    } else {
                        RoundedRectangle(cornerRadius: 26).fill(Theme.lightBlue)
                        Ellipse().fill(Theme.softGreen).frame(width: s.width * 0.86, height: s.height * 0.86)
                    }
                    // Wege zwischen den Orten
                    Path { p in
                        let pts = [WorldArea.haus, .bach, .lichtung, .baumhaus, .wunder].map { CGPoint(x: $0.mapPoint.x * s.width, y: $0.mapPoint.y * s.height) }
                        p.move(to: pts[0]); p.addLine(to: pts[1])
                        p.move(to: pts[1]); p.addLine(to: pts[2])
                        p.move(to: pts[2]); p.addLine(to: pts[3])
                        p.move(to: pts[3]); p.addLine(to: pts[4])
                    }
                    .stroke(Theme.creamDark, style: StrokeStyle(lineWidth: 8, lineCap: .round, dash: [14, 10]))
                    ForEach(WorldArea.allCases) { a in
                        let open = model.w.isUnlocked(a)
                        Button {
                            model.go(a)
                        } label: {
                            VStack(spacing: 4) {
                                ZStack {
                                    Circle().fill(.white).frame(width: 96, height: 96)
                                        .overlay(Circle().stroke(model.area == a ? Theme.highlight : .clear, lineWidth: 6))
                                    if open {
                                        WorldPic("gw_karte_ort_\(a.rawValue)", a.emoji, size: 88)
                                    } else {
                                        WorldPic("gw_karte_nebel", "☁️", size: 90)
                                        Image(systemName: "questionmark").font(.system(size: 30, weight: .heavy)).foregroundStyle(Theme.darkGreen.opacity(0.6))
                                    }
                                }
                                Text(open ? a.title : "Noch nicht entdeckt").font(Theme.rounded(16, .heavy)).foregroundStyle(Theme.darkGreen)
                                    .padding(.horizontal, 10).padding(.vertical, 3).background(Capsule().fill(.white.opacity(0.9)))
                            }
                        }
                        .buttonStyle(PressableStyle())
                        .position(x: a.mapPoint.x * s.width, y: a.mapPoint.y * s.height)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 26))
            }
            .frame(width: 760, height: 520)
        }
        .onAppear { model.say("Tippe auf einen Ort, dann gehen wir dorthin.") }
    }
}

// MARK: - Erinnerungsbuch

struct MemoryBookView: View {
    let model: GardenWorldModel
    @State private var page = 0

    var body: some View {
        let memories = Array(model.w.memories.reversed())
        let perPage = 6
        let pages = max(1, (memories.count + perPage - 1) / perPage)
        let slice = Array(memories.dropFirst(page * perPage).prefix(perPage))
        WorldDialog(close: { model.overlay = nil }) {
            Text("Mein Erinnerungsbuch").font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            if memories.isEmpty {
                Text("Noch leer. Pflanze, ernte, baue und entdecke – dann füllt sich das Buch.")
                    .font(Theme.rounded(20, .medium)).foregroundStyle(Theme.darkGreen).frame(width: 600)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(230), spacing: 18), count: 3), spacing: 18) {
                ForEach(slice) { m in
                    Button { model.say(text(m)) } label: { postcard(m) }
                        .buttonStyle(PressableStyle())
                }
            }
            if pages > 1 {
                HStack(spacing: 20) {
                    Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left.circle.fill").font(.system(size: 44)) }
                        .disabled(page == 0)
                    Text("Seite \(page + 1) von \(pages)").font(Theme.rounded(18, .bold))
                    Button { page = min(pages - 1, page + 1) } label: { Image(systemName: "chevron.right.circle.fill").font(.system(size: 44)) }
                        .disabled(page >= pages - 1)
                }
                .foregroundStyle(Theme.darkGreen)
            }
        }
        .onAppear { model.say(memories.isEmpty ? "Hier sammeln wir deine schönsten Momente." : "Tippe auf ein Bild, dann erzähle ich dir davon.") }
    }

    private func postcard(_ m: WorldMemory) -> some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 16).fill(LinearGradient(colors: [Theme.sky, Theme.meadow], startPoint: .top, endPoint: .bottom))
                picture(m)
            }
            .frame(width: 206, height: 140)
            Text(title(m)).font(Theme.rounded(15, .bold)).foregroundStyle(Theme.darkGreen).lineLimit(2).multilineTextAlignment(.center)
            Text(m.date.formatted(date: .abbreviated, time: .omitted)).font(Theme.rounded(12, .medium)).foregroundStyle(Theme.darkGreen.opacity(0.6))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 20).fill(.white).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
        .rotationEffect(.degrees(Double(abs(m.id.hashValue % 5)) - 2))
    }

    @ViewBuilder
    private func picture(_ m: WorldMemory) -> some View {
        switch m.kind {
        case .ersteErnte:
            let p = PlantKind(rawValue: m.detail) ?? .erdbeere
            HStack { WorldPic(p.asset(stage: 4), p.emoji, size: 90); WorldPic("gw_dino_jubeln", "🦕", size: 80) }
        case .picknick, .fest:
            ZStack {
                WorldPic("gw_picknickdecke_rot", "🧺", size: 150).offset(y: 20)
                HStack(spacing: 0) {
                    ForEach(m.extra.prefix(3), id: \.self) { raw in
                        if let d = DishKind(rawValue: raw) { WorldPic(d.asset, d.emoji, size: 48) }
                        else if let r = Resident(rawValue: raw) { WorldPic(r.asset(r.idlePose), r.emoji, size: 44) }
                    }
                    WorldPic(m.kind == .fest ? "gw_dino_jubeln" : "gw_dino_essen", "🦕", size: 70)
                }
            }
        case .gebaut:
            if let o = model.w.built.first(where: { $0.id.uuidString == m.detail }) {
                BuiltObjectImage(obj: o, size: 120)
            } else {
                Text("🔨").font(.system(size: 60))
            }
        case .bewohner:
            let r = Resident(rawValue: m.detail) ?? .vogel
            WorldPic(r.asset(r.actionPose), r.emoji, size: 110)
        case .boot:
            HStack { WorldPic("gw_boot_blatt", "🍃", size: 80); WorldPic("gw_ziel_teich", "🏝️", size: 90) }
        case .ort:
            let a = WorldArea(rawValue: m.detail) ?? .bach
            if let img = ImageCache.image(a.scene(evening: false)) {
                Image(uiImage: img).resizable().scaledToFill().frame(width: 206, height: 140).clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Text(a.emoji).font(.system(size: 70))
            }
        case .melodie:
            HStack(spacing: 4) {
                ForEach(m.extra.indices, id: \.self) { i in
                    if let c = ChimeKind(rawValue: m.extra[i]) { WorldPic(c.asset, c.emoji, size: 44) }
                }
            }
        case .fantasieblume:
            if let f = model.w.fantasy.first(where: { $0.id.uuidString == m.detail }) {
                FantasyFlowerView(flower: f, size: 120)
            } else {
                Text("🌸").font(.system(size: 70))
            }
        case .baumhaus:
            WorldPic("gw_baumhaus_stufe_4", "🏠", size: 130)
        case .gericht:
            let d = DishKind(rawValue: m.detail) ?? .obstschale
            WorldPic(d.asset, d.emoji, size: 110)
        }
    }

    private func title(_ m: WorldMemory) -> String {
        switch m.kind {
        case .ersteErnte: return "Erste Ernte: \(PlantKind(rawValue: m.detail)?.name ?? "")"
        case .picknick: return m.detail == "baumhaus" ? "Picknick im Baumhaus" : "Picknick im Garten"
        case .fest: return "Das grosse Gartenfest"
        case .gebaut: return "Selbst gebaut: \(model.w.built.first { $0.id.uuidString == m.detail }?.kind.name ?? "ein Bauwerk")"
        case .bewohner: return "Neuer Nachbar: \(Resident(rawValue: m.detail)?.name ?? "")"
        case .boot: return "Das Boot im Teich"
        case .ort: return "Entdeckt: \(WorldArea(rawValue: m.detail)?.title ?? "")"
        case .melodie: return "Meine Melodie"
        case .fantasieblume: return "Meine Fantasieblume"
        case .baumhaus: return "Das Baumhaus ist fertig"
        case .gericht: return "Gekocht: \(DishKind(rawValue: m.detail)?.name ?? "")"
        }
    }

    private func text(_ m: WorldMemory) -> String {
        switch m.kind {
        case .ersteErnte: return "Das war deine erste Ernte: \(PlantKind(rawValue: m.detail)?.name ?? "")."
        case .picknick: return "Weisst du noch? Das Picknick mit Printatops."
        case .fest: return "Das Gartenfest mit allen deinen Freunden."
        case .gebaut: return "Das hast du selbst gebaut und bemalt."
        case .bewohner: return "\(Resident(rawValue: m.detail).map { $0.article.capitalizedFirst + " " + $0.name } ?? "Ein Tier") ist bei dir eingezogen."
        case .boot: return "Dein Boot ist zum ersten Mal bis in den Teich gefahren."
        case .ort: return "Hier hast du \(WorldArea(rawValue: m.detail)?.title ?? "einen neuen Ort") entdeckt."
        case .melodie: return "Das ist deine eigene Melodie aus dem Klanggarten."
        case .fantasieblume: return "Deine erste Fantasieblume."
        case .baumhaus: return "Zusammen habt ihr das Baumhaus gebaut."
        case .gericht: return "Das hast du in der Küche zubereitet: \(DishKind(rawValue: m.detail)?.name ?? "")."
        }
    }
}

// MARK: - Lichtspiel

struct LightPuzzleView: View {
    let model: GardenWorldModel
    @State private var mirrors: [Int: Int] = [:]
    @State private var level = 0
    @State private var solved = false

    /// Rätsel: Quelle (Reihe links), Ziel, Spiegel mit Startstellung (0 = /, 1 = \).
    private struct Puzzle {
        var sourceRow: Int
        var target: (Int, Int)
        var mirrors: [(Int, Int, Int)]
    }

    private static let cols = 5, rows = 4
    private static let puzzles: [Puzzle] = [
        Puzzle(sourceRow: 1, target: (2, 3), mirrors: [(2, 1, 0)]),
        Puzzle(sourceRow: 2, target: (4, 0), mirrors: [(1, 2, 1), (1, 0, 1)]),
        Puzzle(sourceRow: 0, target: (0, 1), mirrors: [(3, 0, 0), (3, 3, 1), (0, 3, 0), (2, 2, 0)])
    ]

    private var puzzle: Puzzle { Self.puzzles[min(level, Self.puzzles.count - 1)] }

    var body: some View {
        WorldDialog(close: { model.overlay = nil }) {
            Text("Lichtspiel \(min(level, 2) + 1) von 3").font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            Text("Tippe auf die Spiegel, bis das Licht die Knospe trifft.").font(Theme.rounded(19, .medium)).foregroundStyle(Theme.darkGreen)
            let cell: CGFloat = 110
            let beam = trace()
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20).fill(Color(red: 0.2, green: 0.18, blue: 0.38))
                    .frame(width: cell * CGFloat(Self.cols) + cell, height: cell * CGFloat(Self.rows))
                // Lichtstrahl
                Path { p in
                    guard let first = beam.first else { return }
                    p.move(to: first)
                    for pt in beam.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(Color(red: 1, green: 0.95, blue: 0.55), style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round))
                .shadow(color: .yellow, radius: 8)
                // Quelle
                WorldPic("gw_licht_prisma", "🔦", size: cell * 0.7)
                    .position(x: cell * 0.5, y: cell * (CGFloat(puzzle.sourceRow) + 0.5))
                ForEach(0..<Self.rows, id: \.self) { r in
                    ForEach(0..<Self.cols, id: \.self) { c in
                        let x = cell * (CGFloat(c) + 1.5)
                        let y = cell * (CGFloat(r) + 0.5)
                        if c == puzzle.target.0 && r == puzzle.target.1 {
                            WorldPic(solved ? "gw_licht_ziel_offen" : "gw_licht_ziel_zu", solved ? "🌸" : "🌷", size: cell * 0.8)
                                .position(x: x, y: y)
                        } else if let m = mirrors[r * 10 + c] {
                            Button {
                                guard !solved else { return }
                                mirrors[r * 10 + c] = 1 - m
                                model.app.audio.sfx("gw_sfx_einrasten", fallback: .tap)
                                check()
                            } label: {
                                ZStack {
                                    Circle().fill(.white.opacity(0.15)).frame(width: cell * 0.8, height: cell * 0.8)
                                    Capsule().fill(LinearGradient(colors: [.white, Theme.lightBlue], startPoint: .top, endPoint: .bottom))
                                        .frame(width: cell * 0.12, height: cell * 0.75)
                                        .rotationEffect(.degrees(m == 0 ? 45 : -45))
                                }
                            }
                            .position(x: x, y: y)
                        } else {
                            Circle().fill(.white.opacity(0.08)).frame(width: 10, height: 10).position(x: x, y: y)
                        }
                    }
                }
            }
            .frame(width: cell * CGFloat(Self.cols) + cell, height: cell * CGFloat(Self.rows))
            if solved {
                Button {
                    if level < Self.puzzles.count - 1 { level += 1; load() } else { model.overlay = nil }
                } label: {
                    Label(level < Self.puzzles.count - 1 ? "Nächstes Rätsel" : "Fertig", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.success))
            }
        }
        .onAppear {
            level = min(model.w.lightLevel, Self.puzzles.count - 1)
            load()
        }
    }

    private func load() {
        solved = false
        mirrors = [:]
        for (c, r, m) in puzzle.mirrors { mirrors[r * 10 + c] = m }
    }

    /// Verlauf des Lichts in Punkten.
    private func trace() -> [CGPoint] {
        let cell: CGFloat = 110
        var pts: [CGPoint] = [CGPoint(x: cell * 0.5, y: cell * (CGFloat(puzzle.sourceRow) + 0.5))]
        var c = -1, r = puzzle.sourceRow
        var dx = 1, dy = 0
        for _ in 0..<40 {
            c += dx; r += dy
            let center = CGPoint(x: cell * (CGFloat(c) + 1.5), y: cell * (CGFloat(r) + 0.5))
            if c < 0 || r < 0 || c >= Self.cols || r >= Self.rows {
                pts.append(center)
                break
            }
            if c == puzzle.target.0 && r == puzzle.target.1 {
                pts.append(center)
                break
            }
            if let m = mirrors[r * 10 + c] {
                pts.append(center)
                // "/" : rechts→oben, oben→rechts, links→unten, unten→links ; "\" : rechts→unten, unten→rechts, links→oben, oben→links
                if m == 0 { (dx, dy) = (-dy, -dx) } else { (dx, dy) = (dy, dx) }
            }
        }
        return pts
    }

    private func hits() -> Bool {
        var c = -1, r = puzzle.sourceRow
        var dx = 1, dy = 0
        for _ in 0..<40 {
            c += dx; r += dy
            if c < 0 || r < 0 || c >= Self.cols || r >= Self.rows { return false }
            if c == puzzle.target.0 && r == puzzle.target.1 { return true }
            if let m = mirrors[r * 10 + c] {
                if m == 0 { (dx, dy) = (-dy, -dx) } else { (dx, dy) = (dy, dx) }
            }
        }
        return false
    }

    private func check() {
        if hits() {
            solved = true
            if level >= model.w.lightLevel { model.lightSolved() } else { model.app.audio.sfx("gw_sfx_zauber", fallback: .success) }
        }
    }
}

// MARK: - Fantasieblume

struct FantasyEditorView: View {
    let model: GardenWorldModel
    let slot: Int
    @State private var shape: FantasyShape = .stern
    @State private var color: WorldColor = .rosa
    @State private var stem: FantasyStem = .geschwungen
    @State private var reaction: FantasyReaction = .lichtpunkte
    @State private var preview = Date()

    var body: some View {
        WorldDialog(close: { model.overlay = nil }) {
            Text("Fantasieblume erfinden").font(Theme.rounded(30, .heavy)).foregroundStyle(Theme.darkGreen)
            HStack(spacing: 30) {
                FantasyFlowerView(flower: current, size: 240, pulse: preview)
                    .onTapGesture { preview = Date() }
                VStack(alignment: .leading, spacing: 14) {
                    picker("Blüte") {
                        ForEach(FantasyShape.allCases, id: \.self) { s in
                            choice(selected: shape == s) { Text(s.emoji).font(.system(size: 32)) } action: { shape = s }
                        }
                    }
                    picker("Farbe") {
                        ForEach(WorldColor.allCases.filter { $0 != .natur && $0 != .braun }) { c in
                            choice(selected: color == c) { Circle().fill(c.color).frame(width: 34, height: 34) } action: { color = c }
                        }
                    }
                    picker("Stiel") {
                        ForEach(FantasyStem.allCases, id: \.self) { s in
                            choice(selected: stem == s) { WorldPic("gw_fantasie_\(s.rawValue)", ["|", "～", "@"][FantasyStem.allCases.firstIndex(of: s) ?? 0], size: 38) } action: { stem = s }
                        }
                    }
                    picker("Zauber") {
                        ForEach(FantasyReaction.allCases, id: \.self) { r in
                            choice(selected: reaction == r) { Image(systemName: r.symbol).font(.system(size: 26)) } action: { reaction = r; preview = Date() }
                        }
                    }
                }
            }
            Button {
                model.plantFantasy(current)
            } label: {
                Label("Pflanzen", systemImage: "sparkles")
            }
            .buttonStyle(BigButtonStyle(color: Theme.success))
        }
        .onAppear {
            if let f = model.w.fantasy.first(where: { $0.slot == slot }) {
                shape = f.shape; color = f.color; stem = f.stem; reaction = f.reaction
            }
            model.say("Erfinde deine eigene Blume: Form, Farbe, Stiel und einen kleinen Zauber.")
        }
    }

    private var current: FantasyFlower {
        FantasyFlower(slot: slot, shape: shape, color: color, stem: stem, reaction: reaction)
    }

    private func picker<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        HStack(spacing: 8) {
            Text(title).font(Theme.rounded(18, .bold)).foregroundStyle(Theme.darkGreen).frame(width: 70, alignment: .leading)
            content()
        }
    }

    private func choice<C: View>(selected: Bool, @ViewBuilder _ label: () -> C, action: @escaping () -> Void) -> some View {
        Button {
            model.app.audio.effect(.tap)
            action()
        } label: {
            label()
                .frame(width: 48, height: 48)
                .background(RoundedRectangle(cornerRadius: 12).fill(selected ? Theme.highlight.opacity(0.55) : .white))
        }
        .buttonStyle(PressableStyle())
        .foregroundStyle(Theme.darkGreen)
    }
}

// MARK: - Fest und Abschlüsse

struct CelebrationView: View {
    let model: GardenWorldModel
    let text: String

    var body: some View {
        WorldDialog(close: { model.overlay = nil }) {
            TimelineView(.animation(minimumInterval: 1.0 / 24)) { tl in
                let t = tl.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(0..<24, id: \.self) { i in
                        Text(["🎉", "✨", "🌸", "🍓", "🎈", "⭐️"][i % 6])
                            .font(.system(size: 26))
                            .offset(x: sin(Double(i) * 2.3 + t) * 260, y: ((t * 60 + Double(i) * 37).truncatingRemainder(dividingBy: 320)) - 160)
                            .opacity(0.8)
                    }
                    HStack(spacing: 6) {
                        WorldPic("gw_dino_jubeln", "🦕", size: 130)
                        ForEach(model.w.residents.prefix(6), id: \.self) { r in
                            WorldPic(r.asset(r.actionPose), r.emoji, size: 70)
                                .offset(y: -abs(sin(t * 4 + Double(r.rawValue.count))) * 14)
                        }
                    }
                }
                .frame(width: 640, height: 260)
            }
            Text(text).font(Theme.rounded(26, .heavy)).foregroundStyle(Theme.darkGreen)
                .multilineTextAlignment(.center).frame(maxWidth: 600)
            Button { model.overlay = nil } label: { Label("Schön!", systemImage: "heart.fill") }
                .buttonStyle(BigButtonStyle(color: Theme.success))
        }
    }
}
