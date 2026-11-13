import SwiftUI

/// Die bespielbare Szene eines Ortes.
struct SceneLayer: View {
    @Bindable var model: GardenWorldModel
    let size: CGSize
    @Binding var selectedDeco: String?
    @Binding var selectedChime: ChimeKind?
    @Environment(AppModel.self) private var app

    private var s: CGSize { size }
    private var W: CGFloat { size.width }

    private var ext: (min: Double, max: Double) { WorldPanorama.extent(model.area) }
    private var totalWidth: CGFloat { s.width * CGFloat(ext.max - ext.min) }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: ext.max - ext.min > 1) {
            ZStack(alignment: .topLeading) {
                SceneBackground(area: model.area, evening: model.w.evening, extent: ext)
                    .frame(width: totalWidth, height: s.height)
                    .contentShape(Rectangle())
                    .onTapGesture(coordinateSpace: .local) { p in backgroundTap(p) }

                // Inhalt im Grundbild: x 0…1 ist der bisherige Bildschirm, links negativ, rechts > 1
                ZStack(alignment: .topLeading) {
                    switch model.area {
                    case .haus: homeContent
                    case .bach: streamContent
                    case .lichtung: EmptyView()
                    case .baumhaus: treehouseContent
                    case .wunder: wonderContent
                    }

                    if model.area == .haus { decorations }
                    builtObjects
                    placementSpots
                    hotspots
                    // Figuren vor allem, was weiter hinten steht (Bodenlinie oberhalb 0.75)
                    ActorsLayer(model: model, size: s)
                        .zIndex(0.75)
                    if model.area == .bach { boatLayer.zIndex(0.9) }
                    flyerLayer.zIndex(30)
                }
                .frame(width: s.width, height: s.height, alignment: .topLeading)
                .coordinateSpace(name: "scene")
                .offset(x: CGFloat(-ext.min) * s.width)

                WeatherLayer(raining: (model.rainUntil ?? .distantPast) > Date(),
                             rainbow: (model.rainbowUntil ?? .distantPast) > Date() && (model.rainUntil ?? .distantPast) < Date(),
                             evening: model.w.evening)
                    .frame(width: totalWidth, height: s.height)
            }
            .frame(width: totalWidth, height: s.height)
        }
        .scrollDisabled(ext.max - ext.min <= 1)
        .defaultScrollAnchor(DemoMode.flag("-panoleft") ? .leading : DemoMode.flag("-panoright") ? .trailing : (ext.min < 0 ? .center : .leading))
        .frame(width: s.width, height: s.height)
        .overlay(alignment: .topLeading) { speechBubble }
        .overlay(alignment: .topTrailing) {
            if model.building {
                Text("Umbauen").font(Theme.rounded(18, .heavy)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 6)
                    .background(Capsule().fill(Theme.darkGreen))
                    .padding(14)
            }
        }
        .overlay(alignment: .bottom) {
            if ext.max - ext.min > 1 {
                Label("Wischen", systemImage: "hand.draw.fill")
                    .font(Theme.rounded(14, .heavy)).foregroundStyle(.white)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(Theme.darkGreen.opacity(0.55)))
                    .padding(.bottom, 10)
                    .allowsHitTesting(false)
            }
        }
    }

    /// Tippen auf den Hintergrund (ganzes Panorama) in Grundbild-Koordinaten.
    private func norm(_ p: CGPoint) -> CGPoint { CGPoint(x: p.x / s.width + CGFloat(ext.min), y: p.y / s.height) }

    private func backgroundTap(_ p: CGPoint) {
        if model.building, let item = selectedDeco, model.area == .haus {
            model.placeDecoration(item, at: norm(p))
            if !app.data.garden.inventory.contains(item) { selectedDeco = nil }
        }
    }

    // MARK: Sprechblase

    /// Sprechblase von Hermes, auf ein Viertel skaliert, damit die Ränder beim Dehnen erhalten bleiben.
    /// Gedehnt wirkt die gemalte Sprechblase blass; die weisse Blase bleibt besser lesbar.
    private var bubbleImage: UIImage? { nil }

    @ViewBuilder
    private var speechBubble: some View {
        if let text = model.dinoText {
            HStack(alignment: .top, spacing: 8) {
                WorldPic("gw_dino_stehen", "🦕", size: 44)
                Text(text)
                    .font(Theme.rounded(20, .semibold))
                    .foregroundStyle(Theme.darkGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, bubbleImage == nil ? 14 : 40)
            .padding(.trailing, bubbleImage == nil ? 14 : 34)
            .padding(.top, bubbleImage == nil ? 10 : 24)
            .padding(.bottom, bubbleImage == nil ? 10 : 40)
            .frame(maxWidth: s.width * 0.66, alignment: .leading)
            .background {
                if let img = bubbleImage {
                    Image(uiImage: img)
                        .resizable(capInsets: EdgeInsets(top: 30, leading: 75, bottom: 40, trailing: 35), resizingMode: .stretch)
                        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                } else {
                    RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.95)).shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                }
            }
            .padding(14)
            .onTapGesture { model.dinoText = nil }
            .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .topLeading)))
        }
    }

    // MARK: Hausgarten

    private var homeContent: some View {
        ZStack(alignment: .topLeading) {
            // Haustür: führt in die Wohnstube (Küche, Spielregal, Staffelei, Bett).
            sceneButton(WorldLayout.houseDoor, label: "Ins Haus") {
                guard !model.building else { return }
                model.moveDino(to: WorldLayout.houseDoorStep, seconds: 1)
                model.enterHouse()
            }
            if !model.w.houseVisited && !model.building {
                DoorHint(size: W * 0.07)
                    .at(CGPoint(x: WorldLayout.houseDoorStep.x, y: WorldLayout.houseDoorStep.y - 0.14), in: s)
                    .allowsHitTesting(false)
            }

            if WorldLayout.garden3, WorldPanorama.isActive(.haus) {
                // Busch an der Naht zwischen Hausgarten und Spielwiese: das gemalte Bild hat dort
                // einen halben Busch (Bildrand des ursprünglichen Gartens).
                WorldPic("gw_busch_1", "", size: W * 0.06)
                    .feet(WorldLayout.seamHedgeBush, size: W * 0.06, in: s, shadow: false)
                    .allowsHitTesting(false)
                WorldPic("gw_busch_2", "", size: W * 0.11)
                    .feet(WorldLayout.seamBush, size: W * 0.11, in: s)
                    .allowsHitTesting(false)
                    .zIndex(WorldLayout.seamBush.y)
            }
            if WorldLayout.garden3 {
                // Schuppen = Werkstatt, Gartentor = Inselkarte
                sceneButton(WorldLayout.shed, label: "Werkstatt im Schuppen") {
                    guard !model.building else { return }
                    model.openWorkshop()
                }
                sceneButton(WorldLayout.gate, label: "Inselkarte") {
                    guard !model.building else { return }
                    app.audio.effect(.tap)
                    model.overlay = .map
                }
            } else if model.w.workshopOpen {
                // Werkbank (alter Garten)
                Button { model.openWorkshop() } label: {
                    WorldPic("gw_werkbank", "🛠️", size: W * 0.11)
                }
                .buttonStyle(PressableStyle())
                .feet(WorldLayout.workbench, size: W * 0.11, in: s)
            }

            // Picknickdecke (einziger Eingang zum Picknick)
            picnicView(model.w.picnic, at: WorldLayout.blanket) {
                if model.w.picnic != nil || model.w.pantry.values.contains(where: { $0 > 0 }) {
                    model.overlay = .picnic
                } else {
                    model.say("Für ein Picknick brauchst du zuerst etwas aus der Küche.")
                }
            }

            ForEach(0..<WorldPanorama.bedCount, id: \.self) { i in
                let bs = i == 3 ? WorldLayout.treeSize : WorldLayout.bedSize
                BedView(model: model, index: i, size: W * bs)
                    .feet(WorldLayout.beds[i], size: W * bs, in: s)
                    .zIndex(WorldLayout.beds[i].y)
            }

            WorldPic(model.w.basket.isEmpty ? "gw_korb_leer" : "gw_korb_voll", "🧺", size: W * 0.07)
                .feet(WorldLayout.basket, size: W * 0.07, in: s)
                .allowsHitTesting(false)
        }
    }

    /// Unsichtbare Tippfläche über einem gemalten Teil der Szene (Haustür, Schuppen, Gartentor).
    private func sceneButton(_ r: CGRect, label: String, action: @escaping () -> Void) -> some View {
        Color.clear
            .frame(width: r.width * s.width, height: r.height * s.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .position(x: r.midX * s.width, y: r.midY * s.height)
    }

    @ViewBuilder
    private func picnicView(_ picnic: PicnicState?, at p: CGPoint, tap: @escaping () -> Void) -> some View {
        let blankets = ["gw_picknickdecke_rot", "gw_picknickdecke_blau", "gw_picknickdecke_blumen"]
        let size = W * 0.22
        ZStack {
            if let img = ImageCache.image(blankets[min(picnic?.blanket ?? 0, 2)]) {
                Image(uiImage: img).resizable().scaledToFit().frame(width: size, height: size * 0.6)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill([Theme.gentleRed, Palette.blue.color, Theme.lightYellow][min(picnic?.blanket ?? 0, 2)].opacity(0.85))
                    .frame(width: size, height: size * 0.36)
                    .rotation3DEffect(.degrees(55), axis: (x: 1, y: 0, z: 0))
            }
            if let picnic {
                HStack(spacing: -6) {
                    ForEach(0..<picnic.plates, id: \.self) { _ in WorldPic("gw_teller", "🍽️", size: size * 0.16) }
                }
                .offset(y: size * 0.1)
                HStack(spacing: 2) {
                    ForEach(picnic.dishes.indices, id: \.self) { i in
                        WorldPic(picnic.dishes[i].asset, picnic.dishes[i].emoji, size: size * 0.22)
                    }
                }
                .offset(y: -size * 0.05)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: tap)
        .at(p, in: s)
    }

    // MARK: Bach

    private var cellW: CGFloat { W * WorldLayout.gridCell }
    private var cellH: CGFloat { s.height * WorldLayout.cellHeight }

    private var streamContent: some View {
        ZStack(alignment: .topLeading) {
            // Zulauf vom Wasserfall, Rinne zum Beet und Auslauf in den Teich: durchgehend gezeichnet,
            // damit das Wasser sichtbar ankommt (vorher endete der Einlauf mitten auf der Wiese).
            ChannelRun(points: WorldLayout.sourceRun, wet: true, width: min(cellW, cellH))
                .frame(width: s.width, height: s.height)
            ChannelRun(points: WorldLayout.bedRun, wet: model.lastWaterResult.bed, width: min(cellW, cellH))
                .frame(width: s.width, height: s.height)
            ChannelRun(points: WorldLayout.pondRun, wet: model.lastWaterResult.pond, width: min(cellW, cellH))
                .frame(width: s.width, height: s.height)
            StreamBedView(model: model, size: cellW * 1.25)
                .at(WorldLayout.streamBed, in: s)

            ForEach(0..<WorldLayout.gridRows, id: \.self) { r in
                ForEach(0..<WorldLayout.gridCols, id: \.self) { c in
                    cellView(c, r)
                        .frame(width: cellW, height: cellH)
                        .at(WorldLayout.cellCenter(col: c, row: r), in: s)
                }
            }

            if model.boat == nil, !model.w.tiles.isEmpty, !model.lastWaterResult.pond, let g = model.lastWaterResult.gap,
               model.tileAt(g.col, g.row) == nil {
                HotspotView(asset: "gw_luecke_hinweis", emoji: "❓", size: cellW * 0.7)
                    .frame(width: cellW, height: cellH)
                    .allowsHitTesting(false)
                    .at(WorldLayout.cellCenter(col: g.col, row: g.row), in: s)
            }
        }
    }

    @ViewBuilder
    private func cellView(_ c: Int, _ r: Int) -> some View {
        let wet = model.lastWaterResult.wet.contains(WaterFlow.key(c, r))
        ZStack {
            if ImageCache.image(WorldArea.bach.scene(evening: false)) != nil && !WorldPanorama.isActive(.bach) {
                // Die Erdfelder sind im Hintergrund gemalt
                Color.clear
            } else if ImageCache.image("gw_bauplatz_erde") != nil {
                WorldPic("gw_bauplatz_erde", "", size: min(cellW, cellH) * 0.98)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                    .foregroundStyle(.white.opacity(0.7))
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.55, green: 0.42, blue: 0.3).opacity(0.18)))
                    .padding(3)
            }
            if let t = model.tileAt(c, r) {
                // Rinne bis an die Kachelkante gezeichnet, damit sie nahtlos an die Nachbarn anschliesst.
                ChannelTileView(openings: t.openings, wet: wet && t.open)
                    .frame(width: cellW, height: cellH)
                if t.piece == .wasserrad || t.piece == .schleuse {
                    TileView(tile: t, wet: wet, size: min(cellW, cellH) * 0.8)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.cellTapped(c, r) }
        .onLongPressGesture(minimumDuration: 0.5) { model.removeTile(c, r) }
        .accessibilityLabel("Feld \(c + 1) in Reihe \(r + 1)")
    }

    private var boatLayer: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: model.boat == nil)) { tl in
            if let b = model.boat, b.path.count > 1 {
                let t = min(tl.date.timeIntervalSince(b.start) / b.secondsPerStep, Double(b.path.count - 1))
                let i = min(Int(t), b.path.count - 2)
                let f = t - Double(i)
                let p = CGPoint(x: b.path[i].x + (b.path[i + 1].x - b.path[i].x) * f, y: b.path[i].y + (b.path[i + 1].y - b.path[i].y) * f)
                let angle = atan2(b.path[i + 1].y * s.height - b.path[i].y * s.height, b.path[i + 1].x * s.width - b.path[i].x * s.width)
                WorldPic(b.kind.asset, b.kind.emoji, size: cellW * 0.7)
                    .rotationEffect(.radians(angle))
                    .at(p, in: s)
            } else {
                Color.clear
            }
        }
        .frame(width: s.width, height: s.height)
        .allowsHitTesting(false)
    }

    // MARK: Baumhaus

    private var treehouseContent: some View {
        ZStack(alignment: .topLeading) {
            if model.w.treehouseStage > 0 {
                WorldPic("gw_baumhaus_stufe_\(model.w.treehouseStage)", ["🪵", "🧱", "🛖", "🏠"][min(model.w.treehouseStage, 4) - 1], size: W * 0.42)
                    .at(WorldLayout.platform, in: s)
                    .onTapGesture { model.say(model.w.treehouseStage >= 4 ? "Dein Baumhaus! Ganz oben sieht man die ganze Insel." : "Das Baumhaus wächst.") }
            }
            if model.w.treehouseStage >= 4 {
                WorldPic("gw_korbaufzug_seil", "🪢", size: W * 0.08)
                    .feet(WorldLayout.lift, size: W * 0.08, in: s, shadow: false)
                if let p = model.w.treeHousePicnic {
                    HStack(spacing: 2) {
                        ForEach(p.dishes.indices, id: \.self) { i in WorldPic(p.dishes[i].asset, p.dishes[i].emoji, size: W * 0.05) }
                        WorldPic("gw_dino_essen", "🦕", size: W * 0.07)
                    }
                    .at(CGPoint(x: WorldLayout.platform.x, y: WorldLayout.platform.y + 0.04), in: s)
                }
            }
        }
    }

    // MARK: Wunderlichtung

    private var wonderContent: some View {
        ZStack(alignment: .topLeading) {
            ForEach(0..<4, id: \.self) { i in
                chimeSlot(i)
                    .feet(WorldLayout.chimeSlots[i], size: W * 0.11, in: s)
            }
            ForEach(0..<3, id: \.self) { i in
                fantasySlot(i)
                    .feet(WorldLayout.fantasySlots[i], size: W * 0.14, in: s)
            }
            Button {
                app.audio.sfx("gw_sfx_zauber", fallback: .tap)
                model.overlay = .light
            } label: {
                WorldPic("gw_licht_prisma", "🔮", size: W * 0.09)
            }
            .buttonStyle(PressableStyle())
            .feet(WorldLayout.crystal, size: W * 0.09, in: s)
            Button { model.startRain() } label: {
                WorldPic("gw_wetterwolke", "🌦️", size: W * 0.08)
            }
            .buttonStyle(PressableStyle())
            .at(WorldLayout.cloud, in: s)
        }
    }

    private func chimeSlot(_ i: Int) -> some View {
        let kind = model.w.chimes[i]
        let glowing = (model.chimeGlow[i] ?? .distantPast).timeIntervalSinceNow > -0.45
        return ZStack {
            if ImageCache.image("gw_klang_sockel") != nil {
                WorldPic("gw_klang_sockel", "", size: W * 0.1).offset(y: W * 0.035)
            } else {
                Ellipse().fill(.white.opacity(0.35)).frame(width: W * 0.09, height: W * 0.03).offset(y: W * 0.04)
            }
            if let kind {
                WorldPic(glowing ? kind.glowAsset : kind.asset, kind.emoji, size: W * 0.11)
                    .scaleEffect(glowing ? 1.15 : 1)
                    .shadow(color: glowing ? .white : .clear, radius: 12)
                    .animation(.spring(response: 0.2), value: glowing)
            } else {
                Image(systemName: "plus.circle.fill").font(.system(size: W * 0.035)).foregroundStyle(.white.opacity(0.85))
            }
            Text("\(i + 1)").font(Theme.rounded(14, .heavy)).foregroundStyle(.white)
                .padding(4).background(Circle().fill(Theme.darkGreen.opacity(0.7))).offset(x: -W * 0.04, y: W * 0.04)
        }
        .frame(width: W * 0.11, height: W * 0.11)
        .contentShape(Rectangle())
        .onTapGesture {
            if let k = selectedChime {
                model.setChime(i, k)
            } else if kind != nil {
                model.chimeTapped(i)
            } else {
                model.say("Wähle unten ein Klangding und tippe dann auf den Platz.")
            }
        }
        .onLongPressGesture { model.setChime(i, nil) }
    }

    private func fantasySlot(_ i: Int) -> some View {
        let flower = model.w.fantasy.first { $0.slot == i }
        return ZStack {
            WorldPic("gw_fantasie_beet", "", size: W * 0.13).offset(y: W * 0.04)
            if let f = flower {
                FantasyFlowerView(flower: f, size: W * 0.14, pulse: model.fantasyPulse[f.id])
            } else if ImageCache.image("gw_fantasie_beet") != nil {
                Image(systemName: "sparkles").font(.system(size: W * 0.03)).foregroundStyle(.white).offset(y: -W * 0.02)
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "sparkles").font(.system(size: W * 0.035)).foregroundStyle(.white)
                    Text("Fantasieblume").font(Theme.rounded(12, .heavy)).foregroundStyle(.white)
                }
                .padding(8).background(Circle().fill(.white.opacity(0.25)))
            }
        }
        .frame(width: W * 0.14, height: W * 0.14)
        .contentShape(Rectangle())
        .onTapGesture {
            if let f = flower { model.fantasyTapped(f) } else { model.overlay = .fantasy(i) }
        }
        .onLongPressGesture { model.overlay = .fantasy(i) }
    }

    // MARK: Gebautes, Schmuck, Abenteuer

    private var builtObjects: some View {
        ForEach(model.w.built.filter { $0.area == model.area }) { obj in
            // Hängendes (Wimpelkette) staffelt nicht mit der Tiefe.
            let depth: CGFloat = obj.kind == .wimpelkette ? 1 : WorldLayout.depthScale(model.area, y: obj.y)
            let size = W * CGFloat(obj.kind.sceneSize) * depth
            BuiltObjectImage(obj: obj, size: size)
                .overlay(alignment: .topTrailing) {
                    if model.building && !obj.kind.unique {
                        Button { model.storeBuilt(obj.id) } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 26)).foregroundStyle(Theme.gentleRed)
                                .background(Circle().fill(.white))
                        }
                    }
                }
                .background(GroundShadow(width: size * 0.7).offset(y: size * 0.42))
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: .named("scene"))
                        .onChanged { v in
                            guard model.building, !obj.kind.unique else { return }
                            model.moveBuilt(obj.id, to: CGPoint(x: v.location.x / s.width, y: (v.location.y + size * 0.42) / s.height))
                        },
                    including: model.building ? .all : .subviews
                )
                .onTapGesture { builtTapped(obj) }
                .feet(CGPoint(x: obj.x, y: obj.y), size: size, in: s, shadow: false)
                .zIndex(obj.y)
        }
    }

    private func builtTapped(_ obj: BuiltObject) {
        guard !model.building else { return }
        switch obj.kind {
        case .futterstelle: model.fillFeeder(obj.id)
        case .windspiel: app.audio.tone(1318.5); model.say("Klingeling! Das Windspiel klingt im Wind.")
        case .bank: model.moveDino(to: CGPoint(x: obj.x - 0.07, y: obj.y), pose: "sitzen", seconds: 6); model.say("Printatops macht eine kleine Pause auf der Bank.")
        case .vogelhaus: model.say(model.w.has(.vogel) ? "Hier wohnt das Rotkehlchen." : "Ein Vogelhaus in deinen Farben. Noch wohnt niemand darin.")
        case .igelhaus: model.say(model.w.has(.igel) ? "Pssst, der Igel ruht sich in seinem Haus aus." : "Ein gemütliches Igelhaus.")
        case .bruecke: model.moveDino(to: CGPoint(x: obj.x + 0.06, y: obj.y)); model.say("Printatops läuft über deine Brücke.")
        case .tunnel: model.say("Durch den Weidentunnel kann man hindurchkriechen.")
        case .insektenhotel: model.say("Im Insektenhotel wohnen Wildbienen.")
        case .segelboot: model.say("Dein Segelboot schaukelt im Teich.")
        default: model.say("Das hast du selbst gebaut!")
        }
    }

    private var decorations: some View {
        ForEach(app.data.garden.placed) { deco in
            let size = W * 0.07 * CGFloat(GardenCatalog.scale(deco.item)) * WorldLayout.depthScale(.haus, y: deco.y)
            Pic(GardenCatalog.asset(deco.item), deco.item, size: size / 1.2)
                .frame(width: size, height: size)
                .overlay(alignment: .topTrailing) {
                    if model.building {
                        Button { model.storeDecoration(deco.id) } label: {
                            Image(systemName: "xmark.circle.fill").font(.system(size: 22)).foregroundStyle(Theme.gentleRed)
                                .background(Circle().fill(.white))
                        }
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 4, coordinateSpace: .named("scene"))
                        .onChanged { v in
                            guard model.building else { return }
                            model.moveDecoration(deco.id, to: CGPoint(x: v.location.x / s.width, y: (v.location.y + size * 0.42) / s.height))
                        },
                    including: model.building ? .all : .subviews
                )
                .onTapGesture {
                    if !model.building { app.audio.effect(.tap) }
                }
                .feet(CGPoint(x: deco.x, y: deco.y), size: size, in: s)
                .zIndex(deco.y)
        }
    }

    private var placementSpots: some View {
        ForEach(placementPoints.indices, id: \.self) { i in
            let p = placementPoints[i]
            HotspotView(asset: "gw_werkbank_umriss", emoji: "⭐️", size: W * 0.07)
                .onTapGesture { model.placeAt(p) }
                .feet(p, size: W * 0.07, in: s, shadow: false)
                .zIndex(10)
        }
    }

    private var placementPoints: [CGPoint] {
        guard let p = model.placing, p.area == model.area else { return [] }
        return model.freeSpots(model.area)
    }

    private var hotspots: some View {
        let steps = model.activeSteps().filter { $0.step.area == model.area }
        return ForEach(steps.indices, id: \.self) { i in
            let entry = steps[i]
            let size = W * 0.1
            let isBuild: Bool = {
                if case .build = entry.step.kind { return true }
                return false
            }()
            let progress: (Int, Int)? = {
                if case .count(let n) = entry.step.kind { return (model.countProgress[entry.adventure.id] ?? 0, n) }
                return nil
            }()
            HotspotView(asset: entry.step.asset, emoji: entry.step.emoji, size: size, dashed: isBuild, progress: progress)
                .onTapGesture {
                    if entry.step.kind == .evening && !model.w.evening {
                        model.toggleEvening()
                    } else {
                        model.hotspotTapped(entry)
                    }
                }
                .at(CGPoint(x: entry.step.x, y: entry.step.y - 0.05), in: s)
                .zIndex(20)
        }
    }

    private var flyerLayer: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: model.flyers.isEmpty)) { tl in
            ZStack(alignment: .topLeading) {
                ForEach(model.flyers) { f in
                    let t = min(tl.date.timeIntervalSince(f.start) / 0.9, 1)
                    let target = f.to ?? WorldLayout.basket
                    let x = f.from.x + (target.x - f.from.x) * t
                    let y = f.from.y + (target.y - 0.04 - f.from.y) * t - 0.15 * sin(.pi * t)
                    WorldPic(f.asset, f.emoji, size: W * 0.05 * (1 - 0.3 * t))
                        .opacity(t >= 1 ? 0 : 1)
                        .at(CGPoint(x: x, y: y), in: s)
                }
            }
            .frame(width: s.width, height: s.height)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Beet

struct BedView: View {
    let model: GardenWorldModel
    let index: Int
    let size: CGFloat

    var body: some View {
        let bed = model.w.beds[index]
        let isTree = index == 3
        let flat = WorldLayout.flatBeds
        let plantSize = isTree ? size : size * (flat ? 1.0 : 0.85)
        // Hochbeet: Pflanze steht oben in der Kiste. Flacher Pflanzhügel: Pflanze steht mitten auf der Erde.
        let offsetY = isTree ? 0 : (flat ? -0.15 * size : -0.4 * size + 0.08 * plantSize)
        let centerDY = size / 2 + offsetY - plantSize / 2
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: !animating(bed))) { tl in
            let now = tl.date
            ZStack(alignment: .bottom) {
                if isTree {
                    if bed.plant == nil {
                        if ImageCache.image("gw_baumplatz") != nil {
                            WorldPic("gw_baumplatz", "", size: size * 0.55)
                        } else {
                            Ellipse().fill(Color(red: 0.45, green: 0.32, blue: 0.22).opacity(0.6))
                                .frame(width: size * 0.4, height: size * 0.1).padding(.bottom, size * 0.06)
                            Text("Baumplatz").font(Theme.rounded(13, .heavy)).foregroundStyle(.white)
                                .padding(.horizontal, 8).background(Capsule().fill(Theme.darkGreen.opacity(0.7)))
                                .padding(.bottom, size * 0.2)
                        }
                    }
                } else {
                    WorldPic(bedAsset(bed, now: now), "🟫", size: size)
                }
                if let plant = bed.plant, bed.stage >= 1 {
                    let grew = (model.growAnim[index] ?? .distantPast).timeIntervalSince(now) > -0.7
                    WorldPic(plant.asset(stage: bed.stage), plant.emoji(stage: bed.stage), size: plantSize)
                        .scaleEffect(grew ? 1.08 : 1, anchor: .bottom)
                        .rotationEffect(.degrees(shakeAngle(now: now, isTree: isTree)), anchor: .bottom)
                        .offset(y: offsetY)
                        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: grew)
                        .id("\(plant.rawValue)\(bed.stage)")
                        .transition(.scale(scale: 0.3, anchor: .bottom).combined(with: .opacity))
                } else if bed.plant != nil {
                    Text("•  •  •").font(.system(size: size * 0.08, weight: .heavy)).foregroundStyle(Color(red: 0.4, green: 0.28, blue: 0.18))
                        .offset(y: offsetY - size * 0.02)
                }
                if let w = model.waterAnim[index], now.timeIntervalSince(w) < 1.6 {
                    WateringEffect(start: w, now: now, size: size)
                        .offset(y: -size * 0.45)
                }
            }
            .frame(width: size, height: size)
            .overlay { harvestPieces(bed, plantSize: plantSize, centerDY: centerDY) }
            .overlay(alignment: .top) { statusBadge(bed, now: now).offset(y: -size * (isTree ? 0.05 : 0.3)) }
            .overlay(alignment: .bottom) { fallenFruit(bed) }
        }
        .contentShape(Rectangle())
        .onTapGesture { model.bedTapped(index) }
        .simultaneousGesture(
            DragGesture(minimumDistance: 20).onEnded { v in
                if v.translation.height < -20, bed.isRipe, bed.plant?.style == .pull { model.collect(index, piece: nil) }
                if abs(v.translation.width) > 20, bed.isRipe, bed.plant?.style == .shake { model.harvestTap(index) }
            }
        )
        .accessibilityLabel(bed.plant.map { "Beet mit \($0.name)" } ?? "Freies Beet")
    }

    private func animating(_ bed: BedState) -> Bool {
        let now = Date()
        return bed.growingSince != nil
            || (model.waterAnim[index] ?? .distantPast).timeIntervalSince(now) > -1.7
            || (model.growAnim[index] ?? .distantPast).timeIntervalSince(now) > -1
            || (model.shakeAnim ?? .distantPast).timeIntervalSince(now) > -1.2
            || bed.isRipe
    }

    private func shakeAngle(now: Date, isTree: Bool) -> Double {
        guard isTree, let s = model.shakeAnim else { return 0 }
        let t = now.timeIntervalSince(s)
        guard t < 1 else { return 0 }
        return sin(t * 30) * 4 * (1 - t)
    }

    private func bedAsset(_ bed: BedState, now: Date) -> String {
        // Im neuen Garten flache Pflanzhügel (gw_erde_*), sonst die Hochbeete.
        let base = WorldLayout.flatBeds ? "gw_erde_" : "gw_beet_"
        if let wet = bed.wetUntil, wet > now { return base + "nass" }
        if bed.plant == nil { return base + "leer" }
        if bed.stage == 0 { return base + (bed.needsWater ? "gesaet" : "nass") }
        if bed.needsWater && bed.stage < 4 { return base + "trocken" }
        return base + "leer"
    }

    @ViewBuilder
    private func statusBadge(_ bed: BedState, now: Date) -> some View {
        if bed.plant != nil {
            if bed.isRipe && bed.plant?.style != .shake {
                Image(systemName: "star.fill").font(.system(size: size * 0.12)).foregroundStyle(Theme.highlight)
                    .shadow(color: .white, radius: 4)
                    .scaleEffect(1 + 0.12 * sin(now.timeIntervalSinceReferenceDate * 4))
            } else if bed.needsWater && bed.stage < 4 {
                Image(systemName: "drop.fill").font(.system(size: size * 0.12)).foregroundStyle(Palette.blue.color)
                    .padding(6).background(Circle().fill(.white.opacity(0.9)))
            } else if let since = bed.growingSince {
                let f = min(now.timeIntervalSince(since) / model.stageSeconds, 1)
                Circle().trim(from: 0, to: f).stroke(Theme.success, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .background(Circle().fill(.white.opacity(0.85)))
            }
        }
    }

    /// Einzeln pflückbare Früchte bei reifen Pflanzen mit mehreren Stücken.
    @ViewBuilder
    private func harvestPieces(_ bed: BedState, plantSize: CGFloat, centerDY: CGFloat) -> some View {
        if let plant = bed.plant, bed.isRipe, plant.style == .pick, plant.yield > 1 {
            let spots: [(Double, Double)] = [(-0.24, -0.1), (0.22, -0.16), (-0.02, -0.3), (0.28, 0.06), (-0.3, 0.08), (0.04, 0.0)]
            ZStack {
                ForEach(0..<min(bed.remaining, spots.count), id: \.self) { i in
                    Button {
                        model.collect(index, piece: nil)
                    } label: {
                        WorldPic(plant.harvest.asset, plant.harvest.emoji, size: plantSize * 0.24)
                            .background(Circle().fill(.white.opacity(0.35)).blur(radius: 3))
                    }
                    .buttonStyle(PressableStyle())
                    .offset(x: spots[i].0 * plantSize, y: centerDY + spots[i].1 * plantSize)
                }
            }
        }
    }

    @ViewBuilder
    private func fallenFruit(_ bed: BedState) -> some View {
        if index == 3, bed.isRipe, !bed.fallen.isEmpty {
            ZStack {
                ForEach(bed.fallen.indices, id: \.self) { i in
                    Button { model.collect(index, piece: i) } label: {
                        WorldPic(HarvestItem.apfel.asset, "🍎", size: size * 0.14)
                    }
                    .buttonStyle(PressableStyle())
                    .offset(x: (bed.fallen[i] - 0.5) * size * 0.9, y: size * 0.04)
                }
            }
            .frame(width: size, height: size * 0.2)
        }
    }
}

struct WateringEffect: View {
    let start: Date
    let now: Date
    let size: CGFloat

    var body: some View {
        let t = now.timeIntervalSince(start)
        ZStack {
            WorldPic("gw_giesskanne_giessen", "🚿", size: size * 0.45)
                .rotationEffect(.degrees(-15))
                .offset(x: -size * 0.25, y: -size * 0.1)
            ForEach(0..<8, id: \.self) { i in
                let phase = (t * 1.6 + Double(i) / 8).truncatingRemainder(dividingBy: 1)
                Circle().fill(Palette.blue.color.opacity(0.75))
                    .frame(width: size * 0.035, height: size * 0.05)
                    .offset(x: -size * 0.05 + Double(i % 4) * size * 0.06, y: phase * size * 0.4)
                    .opacity(1 - phase)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Leuchtender Hinweis über der Haustür, bis das Kind zum ersten Mal im Haus war.
struct DoorHint: View {
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Image(systemName: "arrowshape.down.fill")
                .font(.system(size: size * 0.6, weight: .heavy))
                .foregroundStyle(Theme.highlight)
                .shadow(color: .white, radius: 6)
                .shadow(color: .black.opacity(0.25), radius: 3, y: 2)
                .offset(y: CGFloat(sin(t * 4)) * size * 0.18)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Beet am Bach.
struct StreamBedView: View {
    let model: GardenWorldModel
    let size: CGFloat

    var body: some View {
        let bed = model.w.streamBed
        ZStack(alignment: .bottom) {
            WorldPic(model.lastWaterResult.bed ? "gw_beet_nass" : "gw_beet_leer", "🟫", size: size)
            if let p = bed.plant, bed.stage >= 1 {
                WorldPic(p.asset(stage: bed.stage), p.emoji(stage: bed.stage), size: size * 0.8)
                    .offset(y: -size * 0.3)
            }
            if bed.isRipe {
                Image(systemName: "star.fill").foregroundStyle(Theme.highlight).offset(y: -size * 0.9)
            } else if bed.plant != nil && bed.needsWater {
                Image(systemName: "drop.fill").foregroundStyle(Palette.blue.color).offset(y: -size * 0.9)
            }
        }
        .frame(width: size, height: size)
        .contentShape(Rectangle())
        .onTapGesture {
            if bed.plant == nil {
                model.overlay = .seeds(99)
            } else if bed.isRipe {
                model.collect(99, piece: nil)
            } else {
                model.say(model.lastWaterResult.bed ? "Das Wasser giesst dieses Beet. Es wächst!" : "Dieses Beet wird gegossen, wenn dein Wasserweg hierher fliesst. Es liegt oben rechts.")
            }
        }
    }
}

/// Eine Rinne am Bach.
struct TileView: View {
    let tile: WaterTile
    let wet: Bool
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 8, paused: !wet)) { tl in
            let frame = Int(tl.date.timeIntervalSinceReferenceDate * 6) % 3 + 1
            ZStack {
                if tile.piece == .wasserrad {
                    WorldPic("gw_wasserrad_\(wet ? (Int(tl.date.timeIntervalSinceReferenceDate * 5) % 4 + 1) : 1)", "⚙️", size: size)
                } else if tile.piece == .schleuse {
                    WorldPic(tile.open ? "gw_schleuse_offen" : "gw_schleuse_zu", tile.open ? "🟦" : "🚪", size: size)
                } else if ImageCache.image(tile.piece.asset) != nil {
                    WorldPic(tile.piece.asset, "", size: size)
                } else {
                    ChannelShape(openings: tile.piece.baseOpenings)
                        .stroke(Color(red: 0.55, green: 0.38, blue: 0.22), style: StrokeStyle(lineWidth: size * 0.32, lineCap: .butt, lineJoin: .round))
                        .frame(width: size, height: size)
                }
                if wet {
                    if tile.piece == .gerade, ImageCache.image("gw_wasser_gerade_h_1") != nil {
                        WorldPic("gw_wasser_gerade_h_\(frame)", "", size: size)
                    } else if tile.piece == .kurve, ImageCache.image("gw_wasser_kurve_1") != nil {
                        WorldPic("gw_wasser_kurve_\(frame)", "", size: size)
                    } else {
                        ChannelShape(openings: tile.piece.baseOpenings)
                            .stroke(Palette.blue.color.opacity(0.75), style: StrokeStyle(lineWidth: size * 0.18, lineCap: .butt, lineJoin: .round,
                                                                                        dash: [size * 0.12, size * 0.06], dashPhase: -Double(frame) * size * 0.06))
                            .frame(width: size, height: size)
                    }
                }
            }
            // Bilder zeigen Drehung 0; Drehung gegen den Uhrzeigersinn
            .rotationEffect(.degrees(-90 * Double(tile.rotation)))
        }
        .animation(.spring(response: 0.3), value: tile.rotation)
    }
}

/// Gezeichnete Rinne: Linien von der Mitte zu den Öffnungen.
struct ChannelShape: Shape {
    let openings: [Int]
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        for o in openings {
            p.move(to: c)
            switch o {
            case 0: p.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            case 1: p.addLine(to: CGPoint(x: r.midX, y: r.minY))
            case 2: p.addLine(to: CGPoint(x: r.minX, y: r.midY))
            default: p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            }
        }
        return p
    }
}

/// Fantasieblume aus Form, Farbe, Stiel und Reaktion.
struct FantasyFlowerView: View {
    let flower: FantasyFlower
    let size: CGFloat
    var pulse: Date?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: (pulse ?? .distantPast).timeIntervalSinceNow < -2.5)) { tl in
            let t = pulse.map { tl.date.timeIntervalSince($0) } ?? 99
            let active = t < 2.5
            ZStack(alignment: .bottom) {
                WorldPic("gw_fantasie_\(flower.stem.rawValue)", "🌿", size: size * 0.8)
                ZStack {
                    if let img = ImageCache.image("gw_fantasie_bluete_\(flower.shape.rawValue)") {
                        Image(uiImage: img).resizable().scaledToFit().colorMultiply(flower.color.color)
                    } else {
                        Text(flower.shape.emoji).font(.system(size: size * 0.4))
                            .padding(size * 0.05)
                            .background(Circle().fill(flower.color.color.opacity(0.85)))
                    }
                }
                .frame(width: size * 0.55, height: size * 0.55)
                .scaleEffect(active && flower.reaction == .aufgehen ? 1 + 0.3 * sin(min(t, 1) * .pi) : 1)
                .rotationEffect(.degrees(active && flower.reaction == .klingeln ? sin(t * 25) * 12 * (1 - t / 2.5) : 0))
                .offset(y: -size * 0.45)
                if active && flower.reaction == .lichtpunkte {
                    ForEach(0..<8, id: \.self) { i in
                        Circle().fill(Color(red: 1, green: 0.95, blue: 0.6))
                            .frame(width: 8, height: 8)
                            .offset(x: sin(Double(i) * 1.7 + t * 2) * size * 0.3, y: -size * 0.5 - t * size * 0.3 - Double(i) * 6)
                            .opacity(1 - t / 2.5)
                    }
                }
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - Figuren

struct ActorsLayer: View {
    let model: GardenWorldModel
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15)) { tl in
            let now = tl.date
            ZStack(alignment: .topLeading) {
                ForEach(model.actors) { a in
                    actorView(a, now: now)
                }
            }
            .frame(width: size.width, height: size.height)
        }
    }

    private func pose(_ a: WorldActor, now: Date) -> (String, String) {
        let moving = a.moving(at: now)
        if let r = a.resident {
            let p: String
            if moving {
                p = r.movePoses[Int(now.timeIntervalSinceReferenceDate * 5) % r.movePoses.count]
            } else if let ap = a.actionPose, a.actionUntil > now {
                p = ap
            } else {
                p = r.idlePose
            }
            return (r.asset(p), r.emoji)
        }
        let p: String
        if moving {
            p = "laufen_\(Int(now.timeIntervalSinceReferenceDate * 7) % 4 + 1)"
        } else if let ap = a.actionPose, a.actionUntil > now {
            p = ap
        } else {
            p = "stehen"
        }
        return ("gw_dino_\(p)", "🦕")
    }

    private func actorView(_ a: WorldActor, now: Date) -> some View {
        let pos = a.position(at: now)
        let flies = a.resident?.flies ?? false
        // Printatops etwas kleiner als bisher; am Boden wird nach Tiefe gestaffelt, Flieger nicht.
        let depth: CGFloat = flies ? 1 : WorldLayout.depthScale(model.area, y: Double(pos.y))
        let sz = size.width * CGFloat(a.resident?.size ?? 0.105) * depth
        let (asset, emoji) = pose(a, now: now)
        let bob = flies ? sin(now.timeIntervalSinceReferenceDate * 4 + Double(a.id.count)) * sz * 0.08 : 0
        let hop = (a.resident == .hase || a.resident == .frosch) && a.moving(at: now)
            ? -abs(sin(now.timeIntervalSinceReferenceDate * 8)) * sz * 0.25 : 0
        // Bilder schauen nach rechts; Emojis meist nach links
        let hasImage = ImageCache.image(asset) != nil
        let flip = hasImage ? a.facingLeft : !a.facingLeft
        return WorldPic(asset, emoji, size: sz)
            .scaleEffect(x: flip ? -1 : 1, y: 1)
            .background(alignment: .bottom) { if !flies { GroundShadow(width: sz * 0.6).offset(y: -sz * 0.06) } }
            .offset(y: bob + hop)
            .contentShape(Rectangle())
            .onTapGesture {
                if let r = a.resident { model.residentTapped(r) } else { model.dinoTapped() }
            }
            .feet(pos, size: sz, in: size, shadow: false)
            .zIndex(pos.y + 0.001)
            .accessibilityLabel(a.resident?.name ?? "Printatops")
    }
}

/// Gezeichnete Holzrinne entlang eines Linienzugs in Szenenanteilen (Zulauf, Auslauf in den Teich).
struct ChannelRun: View {
    let points: [CGPoint]
    let wet: Bool
    let width: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !wet)) { tl in
            Canvas { ctx, size in
                guard points.count > 1 else { return }
                var path = Path()
                path.move(to: CGPoint(x: points[0].x * size.width, y: points[0].y * size.height))
                for q in points.dropFirst() {
                    path.addLine(to: CGPoint(x: q.x * size.width, y: q.y * size.height))
                }
                let w = width
                let inner = wet ? Color(red: 0.16, green: 0.45, blue: 0.78) : Color(red: 0.55, green: 0.40, blue: 0.26)
                var layers: [(Color, CGFloat)] = [(Color(red: 0.45, green: 0.30, blue: 0.17), 0.5),
                                                  (Color(red: 0.72, green: 0.52, blue: 0.32), 0.4),
                                                  (inner, 0.28)]
                if wet { layers.append((Color(red: 0.36, green: 0.68, blue: 0.95), 0.21)) }
                for layer in layers {
                    ctx.stroke(path, with: .color(layer.0), style: StrokeStyle(lineWidth: w * layer.1, lineCap: .butt, lineJoin: .round))
                }
                if wet {
                    let phase = -tl.date.timeIntervalSinceReferenceDate * Double(w) * 0.5
                    ctx.stroke(path, with: .color(.white.opacity(0.5)),
                               style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round, dash: [w * 0.015, w * 0.37], dashPhase: phase))
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Gezeichnete Holzrinne bis genau an die Kachelkante: Nachbarteile gehen lückenlos ineinander über.
/// Kurven sind echte Bögen; nasse Rinnen zeigen fliessendes Wasser.
struct ChannelTileView: View {
    let openings: [Int]
    let wet: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 15, paused: !wet)) { tl in
            Canvas { ctx, size in
                let rect = CGRect(origin: .zero, size: size)
                let path = Self.path(openings, in: rect)
                let w = min(size.width, size.height)
                ctx.stroke(path, with: .color(Color(red: 0.45, green: 0.30, blue: 0.17)),
                           style: StrokeStyle(lineWidth: w * 0.5, lineCap: .butt, lineJoin: .round))
                ctx.stroke(path, with: .color(Color(red: 0.72, green: 0.52, blue: 0.32)),
                           style: StrokeStyle(lineWidth: w * 0.4, lineCap: .butt, lineJoin: .round))
                if wet {
                    // Dunkler Wasserrand, heller Wasserlauf, darauf wandernde Lichtpunkte
                    // (keine Mittelstriche: die sahen aus wie eine Strasse).
                    ctx.stroke(path, with: .color(Color(red: 0.16, green: 0.45, blue: 0.78)),
                               style: StrokeStyle(lineWidth: w * 0.28, lineCap: .butt, lineJoin: .round))
                    ctx.stroke(path, with: .color(Color(red: 0.36, green: 0.68, blue: 0.95)),
                               style: StrokeStyle(lineWidth: w * 0.21, lineCap: .butt, lineJoin: .round))
                    let phase = -tl.date.timeIntervalSinceReferenceDate * Double(w) * 0.5
                    ctx.stroke(path, with: .color(.white.opacity(0.5)),
                               style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round, dash: [w * 0.015, w * 0.37], dashPhase: phase))
                } else {
                    ctx.stroke(path, with: .color(Color(red: 0.55, green: 0.40, blue: 0.26)),
                               style: StrokeStyle(lineWidth: w * 0.28, lineCap: .butt, lineJoin: .round))
                }
                if openings.count > 2 {
                    // Mitte von Verzweigung und Kreuz ausfüllen
                    let c = CGPoint(x: rect.midX, y: rect.midY)
                    let r = w * 0.14
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2)),
                             with: .color(wet ? Color(red: 0.30, green: 0.62, blue: 0.92) : Color(red: 0.55, green: 0.40, blue: 0.26)))
                }
            }
        }
        .allowsHitTesting(false)
    }

    /// 0 = rechts, 1 = oben, 2 = links, 3 = unten
    static func edge(_ o: Int, _ r: CGRect) -> CGPoint {
        switch o {
        case 0: return CGPoint(x: r.maxX, y: r.midY)
        case 1: return CGPoint(x: r.midX, y: r.minY)
        case 2: return CGPoint(x: r.minX, y: r.midY)
        default: return CGPoint(x: r.midX, y: r.maxY)
        }
    }

    static func path(_ openings: [Int], in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let o = Array(Set(openings)).sorted()
        if o.count == 2, (o[1] - o[0]) % 2 == 1 {
            // Kurve: Bogen von Kante zu Kante
            p.move(to: edge(o[0], r))
            p.addQuadCurve(to: edge(o[1], r), control: c)
        } else if o.count == 2 {
            p.move(to: edge(o[0], r))
            p.addLine(to: edge(o[1], r))
        } else {
            for e in o {
                p.move(to: c)
                p.addLine(to: edge(e, r))
            }
        }
        return p
    }
}
