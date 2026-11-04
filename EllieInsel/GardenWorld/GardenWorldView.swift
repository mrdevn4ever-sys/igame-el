import SwiftUI

/// «Ellies lebendiger Garten»: die Gartenwelt mit fünf Orten.
struct GardenWorldView: View {
    @Environment(AppModel.self) private var app
    @State private var model: GardenWorldModel?

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if let model {
                GardenWorldContent(model: model)
            }
        }
        .onAppear {
            if model == nil {
                let m = GardenWorldModel(app: app)
                model = m
                m.start()
                if let o = DemoMode.value("-overlay") { m.openDemoOverlay(o) }
                if DemoMode.flag("-gardenplay") { m.runDemoPlay() }
            }
        }
        .onDisappear { model?.stop() }
    }
}

struct GardenWorldContent: View {
    @Bindable var model: GardenWorldModel
    @Environment(AppModel.self) private var app
    @State private var showBasket = false
    @State private var selectedDeco: String?
    @State private var selectedChime: ChimeKind?

    var body: some View {
        VStack(spacing: 8) {
            topBar
            if let reward = app.data.garden.pendingRewards.first {
                rewardBanner(reward)
            }
            GeometryReader { geo in
                let w = min(geo.size.width, geo.size.height * 4 / 3)
                let h = w * 3 / 4
                SceneLayer(model: model, size: CGSize(width: w, height: h), selectedDeco: $selectedDeco, selectedChime: $selectedChime)
                    .frame(width: w, height: h)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .id(model.area)
                    .transition(.opacity)
            }
            .padding(.horizontal, 16)
            bottomBar
        }
        .padding(.vertical, 10)
        .background(Theme.cream.ignoresSafeArea())
        .overlay { overlayView }
        .overlay(alignment: .bottomTrailing) {
            if showBasket { BasketPopover(model: model, close: { showBasket = false }).padding(.trailing, 24).padding(.bottom, 110) }
        }
        .onAppear { updateMusic() }
        .onChange(of: model.area) { _, _ in updateMusic() }
        .onChange(of: model.w.evening) { _, _ in updateMusic() }
        .onDisappear { app.audio.setMusicTrack(nil) }
    }

    /// Gartenmusik: Tag, Abend oder Wunderlichtung (nur wenn Musik eingeschaltet ist).
    private func updateMusic() {
        let track = model.area == .wunder ? "gw_musik_wunderlichtung"
            : (model.w.evening ? "gw_musik_garten_abend" : "gw_musik_garten_tag")
        app.audio.setMusicTrack(track)
    }

    // MARK: Obere Leiste

    private var topBar: some View {
        HStack(spacing: 12) {
            CircleIconButton(systemName: "house.fill", label: "Zu deinen Spielen") {
                app.audio.effect(.tap)
                app.goHome()
            }
            Button {
                app.audio.effect(.tap)
                model.overlay = .map
            } label: {
                HStack(spacing: 8) {
                    Text(model.area.emoji)
                    Text(model.area.title).lineLimit(1).minimumScaleFactor(0.6)
                    Image(systemName: "map.fill").font(.system(size: 18))
                }
                .font(Theme.rounded(24, .heavy))
                .foregroundStyle(Theme.darkGreen)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Capsule().fill(.white).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Inselkarte")
            Spacer(minLength: 8)
            WorldRoundButton(asset: model.w.evening ? "gw_ui_sonne" : "gw_ui_mond", symbol: model.w.evening ? "sun.max.fill" : "moon.stars.fill",
                             label: model.w.evening ? "Tag" : "Abend") { model.toggleEvening() }
            WorldRoundButton(asset: "gw_ui_umbauen", symbol: "hammer.fill", label: "Garten umbauen", active: model.building) {
                app.audio.effect(.tap)
                model.building.toggle()
                selectedDeco = nil
                model.say(model.building ? "Umbauen: Ziehe Dinge an einen neuen Platz. Unten findest du deinen Gartenschmuck." : "Fertig umgebaut.")
            }
            WorldRoundButton(asset: "gw_ui_erinnerungsbuch", symbol: "book.fill", label: "Erinnerungsbuch", badge: 0) {
                app.audio.effect(.tap)
                model.overlay = .book
            }
            Button { model.dinoTapped() } label: {
                WorldPic("gw_dino_winken", "🦕", size: 56)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Theme.lightYellow).shadow(color: .black.opacity(0.15), radius: 4, y: 2))
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Printatops fragen")
        }
        .padding(.horizontal, 20)
    }

    private func rewardBanner(_ reward: PendingReward) -> some View {
        // Schlank: Geschenk-Symbol und drei Bilder, ohne Textzeilen (das Kind wählt nach Bild).
        HStack(spacing: 10) {
            Text("🎁").font(.system(size: 30))
            ForEach(reward.options, id: \.self) { raw in
                let r = WorldReward(raw)
                Button { model.claim(reward, raw) } label: {
                    WorldPic(r.asset, r.emoji, size: 44)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(.white))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(r.title)
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(Theme.lightYellow))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
    }

    // MARK: Untere Leiste

    @ViewBuilder
    private var bottomBar: some View {
        HStack(spacing: 12) {
            if model.building {
                decoInventory
            } else {
                switch model.area {
                case .bach: waterPalette
                case .wunder: chimePalette
                default: gardenTools
                }
            }
        }
        .frame(height: 84)
        .padding(.horizontal, 20)
    }

    private var basketCount: Int { model.w.basket.values.reduce(0, +) }

    private var gardenTools: some View {
        HStack(spacing: 14) {
            toolChip(asset: "gw_korb_voll", emoji: "🧺", title: "Korb", badge: basketCount) {
                app.audio.effect(.tap)
                showBasket.toggle()
            }
            toolChip(asset: "gw_kueche_topf", emoji: "🍳", title: "Küche", badge: model.w.pantry.values.reduce(0, +)) {
                app.audio.sfx("gw_sfx_teller", fallback: .tap)
                model.overlay = .kitchen
            }
            toolChip(asset: "gw_werkbank_hammer", emoji: "🔨", title: "Werkstatt", badge: 0, dimmed: !model.w.workshopOpen) {
                model.openWorkshop()
            }
            Spacer()
        }
    }

    private func toolChip(asset: String, emoji: String, title: String, badge: Int, dimmed: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                WorldPic(asset, emoji, size: 48)
                Text(title).font(Theme.rounded(20, .bold)).foregroundStyle(Theme.darkGreen)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Capsule().fill(.white).shadow(color: .black.opacity(0.1), radius: 4, y: 2))
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text("\(badge)").font(Theme.rounded(14, .heavy)).foregroundStyle(.white)
                        .padding(6).background(Circle().fill(Theme.success)).offset(x: 4, y: -6)
                }
            }
            .opacity(dimmed ? 0.5 : 1)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(title)
    }

    private var waterPalette: some View {
        HStack(spacing: 10) {
            ForEach(model.w.pieces) { p in
                Button {
                    app.audio.effect(.tap)
                    model.selectedPiece = model.selectedPiece == p ? nil : p
                } label: {
                    Group {
                        if ImageCache.image(p.asset) != nil {
                            WorldPic(p.asset, "", size: 54)
                        } else {
                            ZStack {
                                ChannelShape(openings: p.baseOpenings)
                                    .stroke(Color(red: 0.55, green: 0.38, blue: 0.22), style: StrokeStyle(lineWidth: 12, lineCap: .butt, lineJoin: .round))
                                    .frame(width: 44, height: 44)
                                if p == .schleuse { Rectangle().fill(Theme.darkGreen).frame(width: 6, height: 26) }
                                if p == .wasserrad { Image(systemName: "gearshape.fill").font(.system(size: 22)).foregroundStyle(Theme.darkGreen) }
                            }
                        }
                    }
                    .frame(width: 66, height: 66)
                        .background(RoundedRectangle(cornerRadius: 16).fill(model.selectedPiece == p ? Theme.highlight.opacity(0.6) : .white))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(p.name)
            }
            Spacer()
            ForEach(model.w.boats) { b in
                Button {
                    model.launchBoat(b)
                } label: {
                    HStack(spacing: 6) {
                        WorldPic(b.asset, b.emoji, size: 44)
                        Image(systemName: "play.fill")
                    }
                    .font(Theme.rounded(20, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .background(Capsule().fill(Theme.success))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("\(b.name) fahren lassen")
                .opacity(model.boat == nil ? 1 : 0.5)
            }
        }
    }

    private var chimePalette: some View {
        HStack(spacing: 10) {
            ForEach(model.w.chimeKinds) { k in
                Button {
                    app.audio.tone(k.frequency, file: k.sound)
                    selectedChime = selectedChime == k ? nil : k
                } label: {
                    WorldPic(k.asset, k.emoji, size: 52)
                        .frame(width: 66, height: 66)
                        .background(RoundedRectangle(cornerRadius: 16).fill(selectedChime == k ? Theme.highlight.opacity(0.6) : .white))
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(k.name)
            }
            Spacer()
            Button { model.playMelody() } label: {
                Label("Abspielen", systemImage: "music.note")
                    .font(Theme.rounded(22, .bold)).foregroundStyle(.white)
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(Capsule().fill(Theme.success))
            }
            .buttonStyle(PressableStyle())
        }
    }

    private var decoInventory: some View {
        let items = stockCounts
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(items.indices, id: \.self) { idx in
                    let entry = items[idx]
                    Button {
                        app.audio.effect(.tap)
                        selectedDeco = selectedDeco == entry.0 ? nil : entry.0
                        if selectedDeco != nil { model.say("Tippe in den Garten, wo es hin soll.") }
                    } label: {
                        Pic(GardenCatalog.asset(entry.0), entry.0, size: 44)
                            .frame(width: 70, height: 70)
                            .background(RoundedRectangle(cornerRadius: 18).fill(selectedDeco == entry.0 ? Theme.highlight.opacity(0.6) : .white))
                            .overlay(alignment: .topTrailing) {
                                if entry.1 > 1 {
                                    Text("\(entry.1)").font(Theme.rounded(13, .heavy)).foregroundStyle(.white)
                                        .padding(5).background(Circle().fill(Theme.darkGreen))
                                }
                            }
                    }
                    .buttonStyle(PressableStyle())
                }
                if items.isEmpty {
                    Text("Aller Gartenschmuck steht schon im Garten.").font(Theme.rounded(18, .semibold)).foregroundStyle(Theme.darkGreen)
                }
            }
        }
    }

    private var stockCounts: [(String, Int)] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for item in app.data.garden.inventory {
            if counts[item] == nil { order.append(item) }
            counts[item, default: 0] += 1
        }
        return order.map { ($0, counts[$0] ?? 1) }
    }

    // MARK: Überlagerungen

    @ViewBuilder
    private var overlayView: some View {
        if let overlay = model.overlay {
            overlayContent(overlay)
        }
    }

    @ViewBuilder
    private func overlayContent(_ overlay: WorldOverlay) -> some View {
        switch overlay {
        case .map: IslandMapView(model: model)
        case .book: MemoryBookView(model: model)
        case .kitchen: KitchenView(model: model)
        case .workshop(let k): WorkshopView(model: model, start: k)
        case .seeds(let i): SeedPickerView(model: model, bed: i)
        case .sunflower(let i): SunflowerView(model: model, bed: i)
        case .picnic: PicnicSheet(model: model)
        case .light: LightPuzzleView(model: model)
        case .fantasy(let slot): FantasyEditorView(model: model, slot: slot)
        case .celebration(let text): CelebrationView(model: model, text: text)
        }
    }
}

extension GardenWorldModel {
    /// Für Screenshots im Simulator.
    func openDemoOverlay(_ name: String) {
        switch name {
        case "map": overlay = .map
        case "book": overlay = .book
        case "kitchen": overlay = .kitchen
        case "workshop": overlay = .workshop(.vogelhaus)
        case "seeds": overlay = .seeds(0)
        case "picnic": overlay = .picnic
        case "light": overlay = .light
        case "fantasy": overlay = .fantasy(0)
        case "fest": overlay = .celebration("Das Gartenfest beginnt! Alle deine Freunde sind gekommen.")
        default: break
        }
    }
}

/// Inhalt des Korbs.
struct BasketPopover: View {
    let model: GardenWorldModel
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Mein Korb").font(Theme.rounded(22, .heavy)).foregroundStyle(Theme.darkGreen)
                Spacer()
                Button(action: close) { Image(systemName: "xmark.circle.fill").font(.system(size: 28)).foregroundStyle(Theme.darkGreen.opacity(0.6)) }
            }
            let items = HarvestItem.allCases.filter { model.w.count($0) > 0 }
            let finds = FindItem.allCases.filter { (model.w.finds[$0.rawValue] ?? 0) > 0 }
            let dishes = DishKind.allCases.filter { model.w.count($0) > 0 }
            if items.isEmpty && finds.isEmpty && dishes.isEmpty {
                Text("Noch leer. Ernte etwas im Garten!").font(Theme.rounded(18, .medium)).foregroundStyle(Theme.darkGreen)
            }
            row(items.map { ($0.asset, $0.emoji, model.w.count($0)) })
            if !dishes.isEmpty {
                Text("Aus der Küche").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.darkGreen.opacity(0.7))
                row(dishes.map { ($0.asset, $0.emoji, model.w.count($0)) })
            }
            if !finds.isEmpty {
                Text("Fundstücke").font(Theme.rounded(16, .bold)).foregroundStyle(Theme.darkGreen.opacity(0.7))
                row(finds.map { ($0.asset, $0.emoji, model.w.finds[$0.rawValue] ?? 0) })
            }
        }
        .padding(18)
        .frame(width: 420)
        .background(RoundedRectangle(cornerRadius: 26).fill(.white).shadow(color: .black.opacity(0.2), radius: 12, y: 4))
    }

    private func row(_ entries: [(String, String, Int)]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(70), spacing: 8), count: 5), alignment: .leading, spacing: 8) {
            ForEach(entries.indices, id: \.self) { i in
                VStack(spacing: 0) {
                    WorldPic(entries[i].0, entries[i].1, size: 50)
                    Text("\(entries[i].2)").font(Theme.rounded(16, .heavy)).foregroundStyle(Theme.darkGreen)
                }
                .frame(width: 70, height: 76)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.cream))
            }
        }
    }
}
