import SwiftUI

/// «Mein Garten»: Dekorationen platzieren, verschieben und zurücklegen.
struct GardenView: View {
    @Environment(AppModel.self) private var app
    @State private var selectedStock: String?
    @State private var selectedPlaced: UUID?
    @State private var dragging: (id: UUID, offset: CGSize)?
    @State private var stockDrag: (item: String, location: CGPoint)?

    var body: some View {
        VStack(spacing: 12) {
            header
            if let reward = app.data.garden.pendingRewards.first {
                rewardBanner(reward)
            }
            GeometryReader { geo in
                gardenArea(size: geo.size)
            }
            .padding(.horizontal, 24)
            inventory
        }
        .padding(.vertical, 16)
        .coordinateSpace(name: "gardenRoot")
        .background(Theme.cream.ignoresSafeArea())
        .onAppear {
            app.audio.say("Das ist dein Garten. Tippe auf etwas unten und dann in den Garten.")
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            CircleIconButton(systemName: "house.fill", label: "Zu deinen Spielen") {
                app.audio.effect(.tap)
                app.goHome()
            }
            Text("🌻 Mein Garten")
                .font(Theme.rounded(32, .heavy))
                .foregroundStyle(Theme.darkGreen)
            Spacer()
            if let id = selectedPlaced {
                Button {
                    removePlaced(id)
                } label: {
                    Label("Zurück in den Vorrat", systemImage: "tray.and.arrow.down.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.apricot, foreground: Theme.darkGreen))
            }
            CircleIconButton(systemName: "arrow.uturn.backward", label: "Rückgängig") {
                undo()
            }
            .opacity(app.data.garden.undoStack.isEmpty ? 0.4 : 1)
            .disabled(app.data.garden.undoStack.isEmpty)
        }
        .padding(.horizontal, 24)
    }

    private func rewardBanner(_ reward: PendingReward) -> some View {
        HStack(spacing: 16) {
            Text("🎁").font(.system(size: 40))
            Text("Ein Geschenk aus \(reward.game.title):")
                .font(Theme.rounded(20, .semibold))
                .foregroundStyle(Theme.darkGreen)
            ForEach(reward.options, id: \.self) { item in
                Button {
                    app.audio.effect(.snap)
                    app.claimReward(reward, item: item)
                    selectedStock = item
                } label: {
                    Text(item)
                        .font(.system(size: 44))
                        .frame(width: 72, height: 72)
                        .background(RoundedRectangle(cornerRadius: 18).fill(.white))
                }
                .buttonStyle(PressableStyle())
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 24).fill(Theme.lightYellow))
        .padding(.horizontal, 24)
    }

    private func gardenArea(size: CGSize) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(LinearGradient(colors: [Theme.sky, Theme.meadow, Theme.softGreen], startPoint: .top, endPoint: .bottom))
            // Weg und Teich als ruhige Grundgestaltung
            Ellipse()
                .fill(Theme.lightBlue)
                .frame(width: size.width * 0.22, height: size.height * 0.16)
                .position(x: size.width * 0.82, y: size.height * 0.78)
            Capsule()
                .fill(Theme.creamDark)
                .frame(width: size.width * 0.12, height: size.height * 0.5)
                .rotationEffect(.degrees(20))
                .position(x: size.width * 0.3, y: size.height * 0.75)

            ForEach(app.data.garden.placed) { deco in
                let isDragging = dragging?.id == deco.id
                Text(deco.item)
                    .font(.system(size: 64))
                    .padding(6)
                    .background(
                        Circle().stroke(Theme.highlight, lineWidth: selectedPlaced == deco.id ? 5 : 0)
                    )
                    .scaleEffect(isDragging ? 1.15 : 1)
                    .position(x: deco.x * size.width, y: deco.y * size.height)
                    .offset(isDragging ? dragging!.offset : .zero)
                    .gesture(
                        DragGesture(minimumDistance: 6)
                            .onChanged { v in dragging = (deco.id, v.translation) }
                            .onEnded { v in
                                let nx = clamp(deco.x + v.translation.width / size.width)
                                let ny = clamp(deco.y + v.translation.height / size.height)
                                move(deco, x: nx, y: ny)
                                dragging = nil
                            }
                    )
                    .onTapGesture {
                        app.audio.effect(.tap)
                        selectedStock = nil
                        selectedPlaced = selectedPlaced == deco.id ? nil : deco.id
                    }
            }

            if let stockDrag {
                Text(stockDrag.item)
                    .font(.system(size: 64))
                    .position(x: stockDrag.location.x - gardenFrame.minX, y: stockDrag.location.y - gardenFrame.minY)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(coordinateSpace: .local) { location in
            guard let item = selectedStock else {
                selectedPlaced = nil
                return
            }
            place(item, x: clamp(location.x / size.width), y: clamp(location.y / size.height))
        }
        .overlay(alignment: .top) {
            if app.data.garden.placed.isEmpty {
                Text("Wähle unten etwas aus und tippe dann in den Garten.")
                    .font(Theme.rounded(22, .semibold))
                    .foregroundStyle(Theme.darkGreen)
                    .padding(.top, 24)
            }
        }
        .background(
            GeometryReader { g in
                Color.clear.preference(key: GardenFrameKey.self, value: g.frame(in: .named("gardenRoot")))
            }
        )
        .onPreferenceChange(GardenFrameKey.self) { gardenFrame = $0 }
    }

    @State private var gardenFrame: CGRect = .zero

    private var inventory: some View {
        let counts = stockCounts
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(counts, id: \.item) { entry in
                    Text(entry.item)
                        .font(.system(size: 50))
                        .frame(width: 84, height: 84)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(selectedStock == entry.item ? Theme.highlight.opacity(0.5) : .white)
                        )
                        .overlay(alignment: .topTrailing) {
                            if entry.count > 1 {
                                Text("\(entry.count)")
                                    .font(Theme.rounded(15, .heavy))
                                    .foregroundStyle(.white)
                                    .padding(6)
                                    .background(Circle().fill(Theme.darkGreen))
                            }
                        }
                        .onTapGesture {
                            app.audio.effect(.tap)
                            selectedPlaced = nil
                            selectedStock = selectedStock == entry.item ? nil : entry.item
                        }
                        .gesture(
                            // Kurz halten, dann ziehen – so bleibt die Leiste wischbar.
                            LongPressGesture(minimumDuration: 0.2)
                                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .named("gardenRoot")))
                                .onChanged { value in
                                    if case .second(true, let drag?) = value {
                                        stockDrag = (entry.item, drag.location)
                                    }
                                }
                                .onEnded { value in
                                    stockDrag = nil
                                    guard case .second(true, let drag?) = value else { return }
                                    let loc = drag.location
                                    if gardenFrame.width > 0, gardenFrame.contains(loc) {
                                        place(
                                            entry.item,
                                            x: clamp((loc.x - gardenFrame.minX) / gardenFrame.width),
                                            y: clamp((loc.y - gardenFrame.minY) / gardenFrame.height)
                                        )
                                    }
                                }
                        )
                        .accessibilityLabel("Gartenteil \(entry.item)")
                }
                if counts.isEmpty {
                    Text("Alles ist im Garten!")
                        .font(Theme.rounded(20, .semibold))
                        .foregroundStyle(Theme.darkGreen)
                        .frame(height: 84)
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(height: 100)
    }

    private struct StockEntry: Hashable {
        var item: String
        var count: Int
    }

    private var stockCounts: [StockEntry] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        for item in app.data.garden.inventory {
            if counts[item] == nil { order.append(item) }
            counts[item, default: 0] += 1
        }
        return order.map { StockEntry(item: $0, count: counts[$0] ?? 1) }
    }

    private func clamp(_ v: Double) -> Double { min(0.95, max(0.05, v)) }

    private func place(_ item: String, x: Double, y: Double) {
        guard let idx = app.data.garden.inventory.firstIndex(of: item) else { return }
        app.audio.effect(.snap)
        let deco = PlacedDecoration(item: item, x: x, y: y)
        app.update { d in
            d.garden.inventory.remove(at: idx)
            d.garden.placed.append(deco)
            d.garden.undoStack.append(.placed(deco.id))
            if d.garden.undoStack.count > 30 { d.garden.undoStack.removeFirst() }
        }
        if !app.data.garden.inventory.contains(item) { selectedStock = nil }
    }

    private func move(_ deco: PlacedDecoration, x: Double, y: Double) {
        app.update { d in
            guard let i = d.garden.placed.firstIndex(where: { $0.id == deco.id }) else { return }
            d.garden.undoStack.append(.moved(deco.id, deco.x, deco.y))
            d.garden.placed[i].x = x
            d.garden.placed[i].y = y
        }
    }

    private func removePlaced(_ id: UUID) {
        app.audio.effect(.tap)
        app.update { d in
            guard let i = d.garden.placed.firstIndex(where: { $0.id == id }) else { return }
            let deco = d.garden.placed.remove(at: i)
            d.garden.inventory.append(deco.item)
            d.garden.undoStack.append(.removed(deco))
        }
        selectedPlaced = nil
    }

    private func undo() {
        app.audio.effect(.tap)
        app.update { d in
            guard let last = d.garden.undoStack.popLast() else { return }
            switch last {
            case .placed(let id):
                if let i = d.garden.placed.firstIndex(where: { $0.id == id }) {
                    let deco = d.garden.placed.remove(at: i)
                    d.garden.inventory.append(deco.item)
                }
            case .moved(let id, let x, let y):
                if let i = d.garden.placed.firstIndex(where: { $0.id == id }) {
                    d.garden.placed[i].x = x
                    d.garden.placed[i].y = y
                }
            case .removed(let deco):
                if let i = d.garden.inventory.firstIndex(of: deco.item) {
                    d.garden.inventory.remove(at: i)
                    d.garden.placed.append(deco)
                }
            }
        }
        selectedPlaced = nil
    }
}

private struct GardenFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}
