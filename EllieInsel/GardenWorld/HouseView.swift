import SwiftUI

/// Feste Plätze in der Wohnstube (Anteile der Szene, wie assets/skizzen/haus_innen_layout.png).
enum HouseLayout {
    static let gardenDoor = CGRect(x: 0.02, y: 0.18, width: 0.12, height: 0.54)
    static let kitchenDoor = CGRect(x: 0.84, y: 0.14, width: 0.14, height: 0.58)
    static let easel = CGRect(x: 0.66, y: 0.28, width: 0.14, height: 0.46)
    static let bed = CGRect(x: 0.04, y: 0.72, width: 0.24, height: 0.22)
    static let table = CGRect(x: 0.44, y: 0.70, width: 0.16, height: 0.14)
    static let shelf = CGRect(x: 0.24, y: 0.08, width: 0.38, height: 0.52)
    static let dino = CGPoint(x: 0.7, y: 0.95)

    static let shelfColumns = 5
    static let shelfRows = 3

    /// Fach im Spielregal (5 × 3, zeilenweise von oben links).
    static func shelfCell(_ index: Int) -> CGRect {
        let col = index % shelfColumns
        let row = index / shelfColumns
        return CGRect(x: 0.255 + Double(col) * 0.071, y: 0.14 + Double(row) * 0.15, width: 0.062, height: 0.135)
    }
}

/// Die Wohnstube im Haus: Spielregal mit allen Lernspielen, Staffelei, Küchentür, Kuschelbett,
/// Erinnerungsbuch und die Tür zurück in den Garten.
struct HouseView: View {
    @Bindable var model: GardenWorldModel
    @Environment(AppModel.self) private var app
    /// Gerade gewähltes Spiel (wird angesagt und öffnet sich gleich).
    @State private var chosen: GameID?

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            GeometryReader { geo in
                let w = min(geo.size.width, geo.size.height * 4 / 3)
                let s = CGSize(width: w, height: w * 3 / 4)
                room(s)
                    .frame(width: s.width, height: s.height)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
                    .overlay(alignment: .topLeading) { speechBubble(maxWidth: s.width * 0.6) }
                    .overlay(alignment: .topTrailing) {
                        CircleIconButton(systemName: "square.grid.2x2.fill", label: "Alle Spiele", size: 52) {
                            app.audio.effect(.tap)
                            app.goHub()
                        }
                        .padding(12)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(12)
        }
        .transition(.opacity)
    }

    // MARK: Raum

    private func room(_ s: CGSize) -> some View {
        let evening = model.w.evening
        return ZStack(alignment: .topLeading) {
            background(evening: evening)
                .frame(width: s.width, height: s.height)

            // Tür in den Garten
            hotspot(HouseLayout.gardenDoor, in: s, label: "Zurück in den Garten") {
                model.leaveHouse()
            }
            // Durchgang zur Küche
            hotspot(HouseLayout.kitchenDoor, in: s, label: "Küche") {
                app.audio.sfx("gw_sfx_teller", fallback: .tap)
                model.openFromHouse(.kitchen)
            }
            // Staffelei: malen
            hotspot(HouseLayout.easel, in: s, label: "Malen an der Staffelei") {
                if app.data.isVisible(.atelier) {
                    launch(.atelier)
                } else {
                    model.say("An der Staffelei kannst du malen.")
                }
            }
            // Kuschelbett: Abend und Morgen
            hotspot(HouseLayout.bed, in: s, label: evening ? "Aufstehen" : "Schlafen gehen") {
                model.bedTime()
            }

            // Erinnerungsbuch auf dem Tischchen
            Button {
                app.audio.effect(.tap)
                model.openFromHouse(.book)
            } label: {
                WorldPic("gw_buch_einband", "📖", size: s.width * 0.085)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel("Erinnerungsbuch")
            .position(x: HouseLayout.table.midX * s.width, y: (HouseLayout.table.minY + 0.035) * s.height)

            shelf(s)

            // Printatops: am Abend im Bett, sonst auf dem Teppich
            if evening {
                WorldPic("gw_dino_schlafen", "😴", size: s.width * 0.15)
                    .position(x: HouseLayout.bed.midX * s.width, y: (HouseLayout.bed.minY + 0.04) * s.height)
                    .allowsHitTesting(false)
            } else {
                Button {
                    app.audio.sfx("gw_sfx_entdeckt", fallback: .tap)
                    model.say("Im Regal warten deine Spiele. Such dir ein Spiel aus.")
                } label: {
                    WorldPic("gw_dino_winken", "🦕", size: s.width * 0.17)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel("Printatops fragen")
                .feet(HouseLayout.dino, size: s.width * 0.17, in: s)
            }
        }
        .frame(width: s.width, height: s.height, alignment: .topLeading)
    }

    private func background(evening: Bool) -> some View {
        let painted = ImageCache.image(evening ? "gw_szene_haus_innen_abend" : "gw_szene_haus_innen") ?? ImageCache.image("gw_szene_haus_innen")
        // Abendbild fehlt (oder es gibt nur den Platzhalter): Tagbild abdunkeln.
        let dim = evening && ImageCache.image("gw_szene_haus_innen_abend") == nil
        return ZStack {
            if let img = painted {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                HousePlaceholder()
            }
            if dim {
                Color(red: 0.08, green: 0.12, blue: 0.35).opacity(0.4).blendMode(.multiply)
            }
        }
    }

    /// Unsichtbare Tippfläche über einem gemalten Teil der Stube.
    private func hotspot(_ r: CGRect, in s: CGSize, label: String, action: @escaping () -> Void) -> some View {
        Color.clear
            .frame(width: r.width * s.width, height: r.height * s.height)
            .contentShape(Rectangle())
            .onTapGesture(perform: action)
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .position(x: r.midX * s.width, y: r.midY * s.height)
    }

    // MARK: Spielregal

    private func shelf(_ s: CGSize) -> some View {
        let games = Array(app.visibleGames.prefix(HouseLayout.shelfColumns * HouseLayout.shelfRows))
        return ForEach(games.indices, id: \.self) { i in
            let game = games[i]
            let cell = HouseLayout.shelfCell(i)
            let side = min(cell.width * s.width, cell.height * s.height) * 0.94
            Button {
                launch(game)
            } label: {
                Pic("spiel_\(game.rawValue)", game.emoji, size: side * 0.9)
                    .frame(width: side, height: side)
                    .background(RoundedRectangle(cornerRadius: side * 0.18).fill(game.tint.opacity(0.9)))
                    .overlay(RoundedRectangle(cornerRadius: side * 0.18).stroke(Theme.highlight, lineWidth: chosen == game ? 5 : 0))
                    .scaleEffect(chosen == game ? 1.25 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: chosen)
            }
            .buttonStyle(PressableStyle())
            .accessibilityLabel(game.title)
            .position(x: cell.midX * s.width, y: cell.midY * s.height)
            .zIndex(chosen == game ? 2 : 1)
        }
    }

    /// Spiel ansagen und nach einem Moment öffnen (das Kind hört, was es gewählt hat).
    private func launch(_ game: GameID) {
        guard chosen == nil else { return }
        chosen = game
        app.audio.effect(.tap)
        app.audio.say(game.title)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_100_000_000)
            // Nur öffnen, wenn das Kind noch in der Stube ist.
            guard model.overlay == .house else {
                chosen = nil
                return
            }
            app.openFromHouse(game)
        }
    }

    // MARK: Sprechblase

    @ViewBuilder
    private func speechBubble(maxWidth: CGFloat) -> some View {
        if let text = model.dinoText {
            HStack(alignment: .top, spacing: 8) {
                WorldPic("gw_dino_stehen", "🦕", size: 44)
                Text(text)
                    .font(Theme.rounded(20, .semibold))
                    .foregroundStyle(Theme.darkGreen)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20).fill(.white.opacity(0.95)).shadow(color: .black.opacity(0.15), radius: 6, y: 2))
            .padding(14)
            .onTapGesture { model.dinoText = nil }
            .transition(.opacity)
        }
    }
}

/// Gezeichneter Platzhalter für die Wohnstube, bis das gemalte Bild geliefert ist.
struct HousePlaceholder: View {
    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            func rect(_ r: CGRect) -> CGRect {
                CGRect(x: r.minX * w, y: r.minY * h, width: r.width * w, height: r.height * h)
            }
            let wood = Color(red: 0.80, green: 0.62, blue: 0.40)
            let darkWood = Color(red: 0.55, green: 0.38, blue: 0.22)
            // Wand und Boden
            ctx.fill(Path(CGRect(x: 0, y: 0, width: w, height: h * 0.64)), with: .color(Color(red: 0.99, green: 0.93, blue: 0.80)))
            ctx.fill(Path(CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38)), with: .color(Color(red: 0.86, green: 0.68, blue: 0.46)))
            // Teppich
            ctx.fill(Path(ellipseIn: CGRect(x: w * 0.34, y: h * 0.84, width: w * 0.48, height: h * 0.14)), with: .color(Color(red: 0.90, green: 0.55, blue: 0.50)))
            // Gartentür mit Blick ins Grüne
            ctx.fill(Path(roundedRect: rect(HouseLayout.gardenDoor), cornerRadius: w * 0.02), with: .color(darkWood))
            ctx.fill(Path(roundedRect: rect(HouseLayout.gardenDoor.insetBy(dx: 0.012, dy: 0.016)), cornerRadius: w * 0.015), with: .color(Color(red: 0.62, green: 0.82, blue: 0.45)))
            ctx.fill(Path(rect(CGRect(x: HouseLayout.gardenDoor.minX + 0.012, y: HouseLayout.gardenDoor.minY + 0.016, width: HouseLayout.gardenDoor.width - 0.024, height: 0.2))),
                     with: .color(Theme.sky))
            // Spielregal mit Fächern
            ctx.fill(Path(roundedRect: rect(HouseLayout.shelf), cornerRadius: w * 0.012), with: .color(darkWood))
            for i in 0..<(HouseLayout.shelfColumns * HouseLayout.shelfRows) {
                ctx.fill(Path(roundedRect: rect(HouseLayout.shelfCell(i)), cornerRadius: w * 0.006), with: .color(wood))
            }
            // Staffelei mit leerer Leinwand
            let e = HouseLayout.easel
            ctx.fill(Path(rect(CGRect(x: e.midX - 0.006, y: e.minY, width: 0.012, height: e.height))), with: .color(darkWood))
            ctx.fill(Path(roundedRect: rect(CGRect(x: e.minX + 0.01, y: e.minY + 0.04, width: e.width - 0.02, height: 0.24)), cornerRadius: w * 0.006), with: .color(.white))
            // Durchgang zur Küche
            ctx.fill(Path(roundedRect: rect(HouseLayout.kitchenDoor), cornerRadius: w * 0.05), with: .color(darkWood))
            ctx.fill(Path(roundedRect: rect(HouseLayout.kitchenDoor.insetBy(dx: 0.012, dy: 0.016)), cornerRadius: w * 0.04), with: .color(Color(red: 0.66, green: 0.80, blue: 0.56)))
            // Kuschelbett mit Kissen
            ctx.fill(Path(roundedRect: rect(HouseLayout.bed), cornerRadius: w * 0.025), with: .color(Theme.lightBlue))
            ctx.fill(Path(roundedRect: rect(CGRect(x: HouseLayout.bed.minX + 0.015, y: HouseLayout.bed.minY + 0.02, width: 0.07, height: 0.07)), cornerRadius: w * 0.015), with: .color(.white))
            // Tischchen
            ctx.fill(Path(roundedRect: rect(HouseLayout.table), cornerRadius: w * 0.012), with: .color(wood))
        }
        .accessibilityHidden(true)
    }
}
