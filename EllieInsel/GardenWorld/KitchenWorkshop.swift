import SwiftUI

// MARK: - Gartenküche

struct KitchenView: View {
    let model: GardenWorldModel

    private enum Phase { case choose, place, finish, done }

    @State private var dish: DishKind?
    @State private var slots: [HarvestItem?] = []
    @State private var phase: Phase = .choose
    @State private var taps = 0
    @State private var podsOpen = 0
    @State private var peas = 0

    var body: some View {
        WorldPanel(title: "Gartenküche", background: "gw_szene_kueche_innen", close: { model.overlay = nil }) {
            HStack(alignment: .top, spacing: 20) {
                Group {
                    switch phase {
                    case .choose: recipeGrid
                    case .place: placeArea
                    case .finish: finishArea
                    case .done: doneArea
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 30).fill(.white.opacity(0.88)))
                basketColumn
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .onAppear {
            model.say(model.w.basket.isEmpty ? "Dein Korb ist noch leer. Ernte zuerst etwas im Garten." : "Was möchtest du zubereiten? Tippe auf ein Rezept.")
        }
    }

    // MARK: Rezepte

    private func available(_ h: HarvestItem) -> Int {
        model.w.count(h) - slots.filter { $0 == h }.count
    }

    private func canMake(_ d: DishKind) -> Bool {
        if d == .eigenerTeller { return !model.w.basket.isEmpty }
        var counts = model.w.basket
        for ing in d.ingredients {
            guard let h = HarvestItem.allCases.first(where: { ing.accepts($0) && (counts[$0.rawValue] ?? 0) > 0 }) else { return false }
            counts[h.rawValue, default: 0] -= 1
        }
        return true
    }

    private var recipeGrid: some View {
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(190), spacing: 16), count: 3), spacing: 16) {
                ForEach(DishKind.allCases) { d in
                    let ok = canMake(d)
                    Button { choose(d, ok: ok) } label: {
                        VStack(spacing: 6) {
                            WorldPic(d.asset, d.emoji, size: 90)
                            Text(d.name).font(Theme.rounded(18, .heavy)).foregroundStyle(Theme.darkGreen)
                            HStack(spacing: 2) {
                                if d == .eigenerTeller {
                                    Text("Alles, was du magst").font(Theme.rounded(13, .medium)).foregroundStyle(Theme.darkGreen.opacity(0.7))
                                } else {
                                    ForEach(d.ingredients.indices, id: \.self) { i in
                                        Text(d.ingredients[i].emoji).font(.system(size: 20))
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .frame(width: 190, height: 180)
                        .background(RoundedRectangle(cornerRadius: 22).fill(ok ? Theme.lightYellow : Theme.creamDark))
                        .opacity(ok ? 1 : 0.55)
                        .overlay(alignment: .topTrailing) {
                            if model.w.cooked.contains(d.rawValue) {
                                Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success).font(.system(size: 24)).padding(8)
                            }
                        }
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(18)
        }
    }

    private func choose(_ d: DishKind, ok: Bool) {
        guard ok else {
            let need = d.ingredients.map(\.label)
            let unique = need.reduce(into: [String]()) { if !$0.contains($1) { $0.append($1) } }
            model.say("Dafür brauchst du: \(unique.joined(separator: ", ")). Ernte es zuerst im Garten.")
            return
        }
        model.app.audio.effect(.tap)
        dish = d
        slots = d == .eigenerTeller ? [] : Array(repeating: nil, count: d.ingredients.count)
        taps = 0
        podsOpen = 0
        peas = 0
        phase = .place
        model.say(d == .eigenerTeller ? "Leg auf den Teller, was du magst. Dann tippe auf Fertig." : "Leg die Zutaten auf die Plätze. Tippe dazu rechts im Korb.")
    }

    // MARK: Hinlegen

    private var placeArea: some View {
        VStack(spacing: 18) {
            if let d = dish {
                Text(d.name).font(Theme.rounded(28, .heavy)).foregroundStyle(Theme.darkGreen)
                ZStack {
                    WorldPic(d == .blumenstrauss ? "gw_kueche_vase" : (d == .kuerbissuppe ? "gw_kueche_topf" : "gw_kueche_schneidebrett"), "🪵", size: 300)
                        .opacity(0.9)
                    if d == .eigenerTeller {
                        WorldPic("gw_teller", "🍽️", size: 260)
                        let placed = slots.compactMap { $0 }
                        ForEach(placed.indices, id: \.self) { i in
                            let a = Double(i) / Double(max(placed.count, 1)) * 2 * .pi
                            WorldPic(placed[i].asset, placed[i].emoji, size: 64)
                                .offset(x: cos(a) * 70, y: sin(a) * 50)
                        }
                    } else {
                        HStack(spacing: 14) {
                            ForEach(slots.indices, id: \.self) { i in
                                ZStack {
                                    Circle().stroke(style: StrokeStyle(lineWidth: 3, dash: [8, 6])).foregroundStyle(Theme.darkGreen.opacity(0.5))
                                        .background(Circle().fill(.white.opacity(0.6)))
                                    if let h = slots[i] {
                                        WorldPic(h.asset, h.emoji, size: 70).transition(.scale)
                                    } else if !model.w.cooked.contains(d.rawValue) {
                                        Text(d.ingredients[i].emoji).font(.system(size: 36)).opacity(0.3)
                                    }
                                }
                                .frame(width: 86, height: 86)
                            }
                        }
                    }
                }
                .frame(height: 320)
                if d == .eigenerTeller {
                    Button {
                        guard !slots.isEmpty else { return }
                        phase = .done
                        finish()
                    } label: { Label("Fertig", systemImage: "checkmark.circle.fill") }
                        .buttonStyle(BigButtonStyle(color: Theme.success))
                        .opacity(slots.isEmpty ? 0.5 : 1)
                }
                Button("Anderes Rezept") { phase = .choose; slots = []; dish = nil }
                    .font(Theme.rounded(18, .semibold)).foregroundStyle(Theme.darkGreen)
            }
        }
        .padding(20)
    }

    private func put(_ h: HarvestItem) {
        guard phase == .place, let d = dish, available(h) > 0 else { return }
        if d == .eigenerTeller {
            guard slots.count < 6 else { model.say("Der Teller ist voll."); return }
            withAnimation(.spring(response: 0.35)) { slots.append(h) }
            model.app.audio.sfx("gw_sfx_korb", fallback: .snap)
            return
        }
        guard let i = slots.indices.first(where: { slots[$0] == nil && d.ingredients[$0].accepts(h) }) else {
            model.app.audio.effect(.gentle)
            model.say("Das brauchen wir für dieses Rezept nicht.")
            return
        }
        withAnimation(.spring(response: 0.35)) { slots[i] = h }
        model.app.audio.sfx("gw_sfx_korb", fallback: .snap)
        let filled = slots.compactMap { $0 }.count
        model.app.audio.say(NumberWords.word(filled))
        if filled == slots.count {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                phase = d.finishing == .none ? .done : .finish
                if phase == .done { finish() } else { model.say(d.finishing.instruction) }
            }
        }
    }

    // MARK: Zubereiten

    private var finishArea: some View {
        VStack(spacing: 20) {
            if let d = dish {
                Text(d.finishing.instruction).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.darkGreen)
                    .multilineTextAlignment(.center).frame(maxWidth: 600)
                switch d.finishing {
                case .shell: shellArea
                case .carve: carveArea
                default:
                    Button {
                        taps += 1
                        model.app.audio.sfx(sound(d.finishing), fallback: .tap)
                        if d.finishing.taps > 1 { model.app.audio.say(NumberWords.word(taps)) }
                        if taps >= d.finishing.taps {
                            phase = .done
                            finish()
                        }
                    } label: {
                        WorldPic(tool(d.finishing), toolEmoji(d.finishing), size: 220)
                            .rotationEffect(.degrees(Double(taps) * 18))
                            .padding(20)
                            .background(Circle().fill(Theme.lightYellow))
                    }
                    .buttonStyle(PressableStyle())
                    .animation(.spring(response: 0.3), value: taps)
                }
            }
        }
        .padding(20)
    }

    private var shellArea: some View {
        VStack(spacing: 16) {
            HStack(spacing: 30) {
                ForEach(0..<2, id: \.self) { i in
                    Button {
                        guard podsOpen == i else { return }
                        podsOpen += 1
                        model.app.audio.sfx("gw_sfx_ploppen", fallback: .snap)
                        if podsOpen == 2 { model.say("Jetzt zählen wir die Erbsen. Tippe jede Erbse an.") }
                    } label: {
                        WorldPic(i < podsOpen ? "gw_ernte_erbsenschote_offen" : "gw_ernte_erbsenschote_zu", "🫛", size: 140)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            if podsOpen == 2 {
                HStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { i in
                        Button {
                            guard i == peas else { return }
                            peas += 1
                            model.app.audio.say(NumberWords.word(peas))
                            if peas == 10 { phase = .done; finish() }
                        } label: {
                            WorldPic("gw_ernte_erbse", "🟢", size: 44).opacity(i < peas ? 0.25 : 1)
                        }
                    }
                }
            }
        }
    }

    private var carveArea: some View {
        HStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { i in
                Button {
                    model.edit { $0.lanternFace = i }
                    model.app.audio.sfx("gw_sfx_zauber", fallback: .success)
                    phase = .done
                    finish()
                } label: {
                    VStack {
                        Text("🎃").font(.system(size: 90))
                        Text(["😊", "😮", "😴"][i]).font(.system(size: 50))
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 22).fill(Theme.lightYellow))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }

    private func tool(_ s: KitchenStep) -> String {
        switch s {
        case .wash: return "gw_kueche_schuessel_wasser"
        case .cut: return "gw_kueche_schneidebrett"
        case .stir: return "gw_kueche_kochloeffel"
        case .pour: return "gw_kueche_saftkrug"
        case .bake: return "gw_kueche_kuchenboden"
        case .arrange: return "gw_kueche_vase"
        default: return ""
        }
    }

    private func toolEmoji(_ s: KitchenStep) -> String {
        switch s {
        case .wash: return "💧"
        case .cut: return "🔪"
        case .stir: return "🥄"
        case .pour: return "🫗"
        case .bake: return "🔥"
        case .arrange: return "🏺"
        default: return "⭐️"
        }
    }

    private func sound(_ s: KitchenStep) -> String {
        switch s {
        case .wash, .pour: return "gw_sfx_platschen"
        case .stir: return "gw_sfx_umruehren"
        case .cut: return "gw_sfx_hammer"
        default: return "gw_sfx_teller"
        }
    }

    private func finish() {
        guard let d = dish else { return }
        model.cook(d, used: slots.compactMap { $0 })
        model.say("Fertig! \(d.name). Du kannst damit ein Picknick machen oder es jemandem bringen.")
    }

    private var doneArea: some View {
        VStack(spacing: 20) {
            if let d = dish {
                WorldPic(d.asset, d.emoji, size: 260)
                Text(d.name).font(Theme.rounded(32, .heavy)).foregroundStyle(Theme.darkGreen)
                HStack(spacing: 16) {
                    Button { phase = .choose; dish = nil; slots = [] } label: { Label("Noch etwas kochen", systemImage: "fork.knife") }
                        .buttonStyle(BigButtonStyle(color: Theme.lightYellow, foreground: Theme.darkGreen))
                    Button { model.overlay = nil } label: { Label("Zurück in den Garten", systemImage: "leaf.fill") }
                        .buttonStyle(BigButtonStyle(color: Theme.success))
                }
            }
        }
        .padding(20)
    }

    // MARK: Korb

    private var basketColumn: some View {
        VStack(spacing: 10) {
            Text("Korb").font(Theme.rounded(22, .heavy)).foregroundStyle(Theme.darkGreen)
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(HarvestItem.allCases.filter { model.w.count($0) > 0 }) { h in
                        Button { put(h) } label: {
                            HStack {
                                WorldPic(h.asset, h.emoji, size: 54)
                                Text("\(available(h))").font(Theme.rounded(22, .heavy)).foregroundStyle(Theme.darkGreen)
                            }
                            .frame(width: 140, height: 70)
                            .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                            .opacity(available(h) > 0 ? 1 : 0.4)
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityLabel(h.name)
                    }
                    if model.w.basket.isEmpty {
                        Text("Leer").font(Theme.rounded(18, .medium)).foregroundStyle(Theme.darkGreen)
                    }
                }
            }
        }
        .padding(14)
        .frame(width: 180)
        .background(RoundedRectangle(cornerRadius: 26).fill(Theme.lightYellow.opacity(0.92)))
    }
}

// MARK: - Werkstatt

struct WorkshopView: View {
    let model: GardenWorldModel
    let start: BuildKind?

    private enum Phase { case choose, assemble, paint }

    @State private var kind: BuildKind?
    @State private var placed: [String] = []
    @State private var phase: Phase = .choose
    @State private var roof: WorldColor = .rot
    @State private var bodyColor: WorldColor = .natur
    @State private var pattern: WorldPattern = .keins
    @State private var deco: FindItem?

    var body: some View {
        WorldPanel(title: "Werkstatt", background: "gw_szene_werkstatt_innen", close: { model.overlay = nil }) {
            Group {
                switch phase {
                case .choose: kitGrid
                case .assemble: assembleArea
                case .paint: paintArea
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RoundedRectangle(cornerRadius: 30).fill(.white.opacity(0.88)))
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .onAppear {
            if let k = start {
                begin(k)
            } else {
                model.say("Was möchtest du bauen?")
            }
        }
    }

    private func builtCount(_ k: BuildKind) -> Int { model.w.built.filter { $0.kind == k }.count }

    private var kitGrid: some View {
        ScrollView {
            if model.w.kits.isEmpty {
                Text("Noch keine Bausätze. Du bekommst sie als Geschenk nach den Lernspielen.")
                    .font(Theme.rounded(20, .medium)).foregroundStyle(Theme.darkGreen).padding(30)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(180), spacing: 16), count: 4), spacing: 16) {
                ForEach(model.w.kits) { k in
                    let done = k.unique && builtCount(k) > 0
                    Button {
                        if done { model.say("\(k.name) hast du schon gebaut.") } else { begin(k) }
                    } label: {
                        WorldCard(asset: k.displayAsset, emoji: k.emoji, title: k.name,
                                  subtitle: builtCount(k) > 0 ? "Schon \(builtCount(k))× gebaut" : "\(k.parts.count) Teile",
                                  disabled: done, size: 170)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(18)
        }
    }

    private func begin(_ k: BuildKind) {
        model.app.audio.sfx("gw_sfx_hammer", fallback: .tap)
        kind = k
        placed = []
        roof = .rot
        bodyColor = .natur
        pattern = .keins
        deco = nil
        phase = .assemble
        if DemoMode.flag("-teile") { placed = k.parts.prefix(3).map(\.key) }
        model.say("Wir bauen \(k.accusativeName). Tippe auf die Teile, dann kommen sie an ihren Platz.")
    }

    private var assembleArea: some View {
        VStack(spacing: 18) {
            if let k = kind {
                Text(k.name).font(Theme.rounded(28, .heavy)).foregroundStyle(Theme.darkGreen)
                let all = placed.count == k.parts.count
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(LinearGradient(colors: [Color(red: 0.99, green: 0.95, blue: 0.86), Color(red: 0.93, green: 0.84, blue: 0.68)],
                                             startPoint: .top, endPoint: .bottom))
                        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color(red: 0.80, green: 0.64, blue: 0.44), lineWidth: 3))
                    if all {
                        BuiltObjectView(kind: k, roof: .natur, bodyColor: .natur, size: 300)
                            .transition(.scale.combined(with: .opacity))
                    } else if k.partsStack {
                        // Bauplan: blasses fertiges Objekt, die Teile rasten an ihrer Stelle ein.
                        ZStack {
                            if let ghost = ImageCache.image(k.displayAsset) {
                                Image(uiImage: ghost).resizable().scaledToFit()
                                    .colorMultiply(Color(red: 0.55, green: 0.42, blue: 0.30))
                                    .opacity(0.16)
                            }
                            ForEach(placed.sorted { BuildKind.layerRank($0) < BuildKind.layerRank($1) }, id: \.self) { key in
                                if let img = ImageCache.image(k.partAsset(key)) {
                                    Image(uiImage: img).resizable().scaledToFit()
                                        .transition(.asymmetric(insertion: .offset(y: 60).combined(with: .opacity), removal: .opacity))
                                }
                            }
                        }
                        .frame(width: 300, height: 300)
                    } else {
                        HStack(spacing: 16) {
                            ForEach(k.parts, id: \.key) { part in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 18)
                                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [9, 7]))
                                        .foregroundStyle(Color(red: 0.80, green: 0.64, blue: 0.44))
                                    if placed.contains(part.key) {
                                        PartPic(asset: k.partAsset(part.key), emoji: part.emoji, size: 110).transition(.scale)
                                    } else if builtCount(k) == 0 {
                                        PartPic(asset: k.partAsset(part.key), emoji: part.emoji, size: 100).opacity(0.25)
                                    }
                                }
                                .frame(width: 130, height: 130)
                            }
                        }
                    }
                }
                .frame(height: 320)
                .padding(.horizontal, 30)
                if all {
                    Button { phase = .paint; model.say("Jetzt bemalen wir es. Such dir Farben aus.") } label: {
                        Label("Bemalen", systemImage: "paintbrush.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: Theme.success))
                } else {
                    Text("Teile").font(Theme.rounded(18, .bold)).foregroundStyle(Theme.darkGreen)
                    HStack(spacing: 14) {
                        ForEach(k.parts.filter { !placed.contains($0.key) }, id: \.key) { part in
                            Button {
                                withAnimation(.spring(response: 0.4)) { placed.append(part.key) }
                                model.app.audio.sfx("gw_sfx_einrasten", fallback: .snap)
                                if placed.count == k.parts.count {
                                    model.app.audio.sfx("gw_sfx_hammer", fallback: .success)
                                    model.say("Zusammengebaut! Toll gemacht.")
                                }
                            } label: {
                                PartPic(asset: k.partAsset(part.key), emoji: part.emoji, size: 100)
                                    .frame(width: 124, height: 124)
                                    .background(RoundedRectangle(cornerRadius: 20).fill(Theme.lightYellow))
                            }
                            .buttonStyle(PressableStyle())
                        }
                    }
                }
            }
        }
        .padding(20)
    }

    private var paintArea: some View {
        HStack(spacing: 30) {
            if let k = kind {
                VStack {
                    BuiltObjectView(kind: k, roof: roof, bodyColor: bodyColor, pattern: pattern, decoration: deco, size: 320)
                        .animation(.easeInOut(duration: 0.2), value: roof)
                    Button {
                        if let d = deco { model.edit { $0.finds[d.rawValue, default: 1] -= 1; if ($0.finds[d.rawValue] ?? 0) <= 0 { $0.finds[d.rawValue] = nil } } }
                        model.finishBuild(BuiltObject(kind: k, area: model.area, x: 0.5, y: 0.8, roof: roof, body: bodyColor, pattern: pattern, decoration: deco))
                    } label: {
                        Label("Aufstellen", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(BigButtonStyle(color: Theme.success))
                }
                VStack(alignment: .leading, spacing: 16) {
                    colorRow("Dach", selection: $roof)
                    colorRow("Wände", selection: $bodyColor)
                    HStack(spacing: 8) {
                        Text("Muster").font(Theme.rounded(18, .bold)).frame(width: 90, alignment: .leading)
                        ForEach(WorldPattern.allCases) { p in
                            Button { pattern = p; model.app.audio.sfx("gw_sfx_pinsel", fallback: .tap) } label: {
                                Text(p.symbol).font(.system(size: 26, weight: .bold))
                                    .frame(width: 50, height: 50)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(pattern == p ? Theme.highlight.opacity(0.6) : .white))
                            }
                            .accessibilityLabel(p.name)
                        }
                    }
                    let finds = FindItem.allCases.filter { (model.w.finds[$0.rawValue] ?? 0) > 0 }
                    if !finds.isEmpty {
                        HStack(spacing: 8) {
                            Text("Verzierung").font(Theme.rounded(18, .bold)).frame(width: 90, alignment: .leading)
                            ForEach(finds) { f in
                                Button { deco = deco == f ? nil : f; model.app.audio.effect(.tap) } label: {
                                    WorldPic(f.asset, f.emoji, size: 40)
                                        .frame(width: 50, height: 50)
                                        .background(RoundedRectangle(cornerRadius: 12).fill(deco == f ? Theme.highlight.opacity(0.6) : .white))
                                }
                            }
                        }
                    }
                }
                .foregroundStyle(Theme.darkGreen)
            }
        }
        .padding(20)
    }

    private func colorRow(_ title: String, selection: Binding<WorldColor>) -> some View {
        HStack(spacing: 6) {
            Text(title).font(Theme.rounded(18, .bold)).frame(width: 90, alignment: .leading)
            ForEach(WorldColor.allCases) { c in
                Button {
                    selection.wrappedValue = c
                    model.app.audio.sfx("gw_sfx_pinsel", fallback: .tap)
                } label: {
                    Circle().fill(c.color).frame(width: 40, height: 40)
                        .overlay(Circle().stroke(Theme.darkGreen, lineWidth: selection.wrappedValue == c ? 4 : 1).padding(-3))
                        .frame(width: 48, height: 48)
                }
                .accessibilityLabel(c.name)
            }
        }
    }
}

/// Bauteil ohne durchsichtigen Rand, damit es in der Ablage gross genug ist.
private struct PartPic: View {
    let asset: String
    let emoji: String
    let size: CGFloat

    var body: some View {
        Group {
            if let img = ImageCache.trimmed(asset) {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                Text(emoji).font(.system(size: size * 0.62))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
