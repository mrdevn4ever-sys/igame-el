import SwiftUI

struct MemoryMotif: Codable, Equatable, Hashable {
    var emoji: String
    var name: String
}

enum MemoryCatalog {
    static let groups: [(title: String, motifs: [MemoryMotif])] = [
        ("Waldtiere", [
            MemoryMotif(emoji: "🦊", name: "Fuchs"), MemoryMotif(emoji: "🦌", name: "Reh"),
            MemoryMotif(emoji: "🦔", name: "Igel"), MemoryMotif(emoji: "🐿️", name: "Eichhörnchen"),
            MemoryMotif(emoji: "🦉", name: "Eule"), MemoryMotif(emoji: "🐗", name: "Wildschwein"),
            MemoryMotif(emoji: "🐻", name: "Bär"), MemoryMotif(emoji: "🐺", name: "Wolf")
        ]),
        ("Wiesentiere", [
            MemoryMotif(emoji: "🐞", name: "Marienkäfer"), MemoryMotif(emoji: "🦋", name: "Schmetterling"),
            MemoryMotif(emoji: "🐝", name: "Biene"), MemoryMotif(emoji: "🐌", name: "Schnecke"),
            MemoryMotif(emoji: "🐛", name: "Raupe"), MemoryMotif(emoji: "🐇", name: "Hase"),
            MemoryMotif(emoji: "🐸", name: "Frosch"), MemoryMotif(emoji: "🦗", name: "Grashüpfer")
        ]),
        ("Naturmotive", [
            MemoryMotif(emoji: "🌻", name: "Sonnenblume"), MemoryMotif(emoji: "🌷", name: "Tulpe"),
            MemoryMotif(emoji: "🍄", name: "Pilz"), MemoryMotif(emoji: "🌲", name: "Tanne"),
            MemoryMotif(emoji: "🍁", name: "Ahornblatt"), MemoryMotif(emoji: "🌰", name: "Kastanie"),
            MemoryMotif(emoji: "🌈", name: "Regenbogen"), MemoryMotif(emoji: "🌸", name: "Kirschblüte")
        ])
    ]
}

struct MemoryCard: Codable, Identifiable, Equatable {
    var id: Int
    var motif: MemoryMotif
    var faceUp = false
    var matched = false
}

struct MemoryState: Codable {
    var cards: [MemoryCard]
    var group: String
    var moves: Int
}

/// Spiel 3: Tier- und Natur-Memory.
struct MemoryGameView: View {
    let host: GameHost
    @State private var model: MemoryModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: MemoryModel(host: host))
    }

    var body: some View {
        GeometryReader { geo in
            let cols = model.columns
            let rows = Int(ceil(Double(model.cards.count) / Double(cols)))
            let spacing: CGFloat = 18
            let w = (geo.size.width - spacing * CGFloat(cols - 1)) / CGFloat(cols)
            let h = (geo.size.height - spacing * CGFloat(max(rows - 1, 0))) / CGFloat(max(rows, 1))
            let side = min(w, h, 220)
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<cols, id: \.self) { c in
                            let idx = r * cols + c
                            if let card = model.cards[safe: idx] {
                                MemoryCardView(card: card, hinted: model.hinted == card.id, size: side)
                                    .onTapGesture { model.tap(card.id) }
                                    .accessibilityLabel(card.faceUp || card.matched ? card.motif.name : "Verdeckte Karte")
                                    .accessibilityAddTraits(.isButton)
                            } else {
                                Color.clear.frame(width: side, height: side)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(.vertical, 6)
        .onAppear { model.start() }
        .onDisappear { model.stop() }
    }
}

struct MemoryCardView: View {
    let card: MemoryCard
    var hinted: Bool
    let size: CGFloat

    var body: some View {
        let shown = card.faceUp || card.matched
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                .fill(shown ? Color.white : Theme.lightBlue)
                .shadow(color: .black.opacity(0.14), radius: 5, y: 3)
            if shown {
                Pic("memory_" + card.motif.name.voiceSlug, card.motif.emoji, size: size * 0.55)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                Text("🍃")
                    .font(.system(size: size * 0.32))
                    .opacity(0.5)
            }
            if card.matched {
                RoundedRectangle(cornerRadius: size * 0.16, style: .continuous)
                    .stroke(Theme.success, lineWidth: 6)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: size * 0.18))
                    .foregroundStyle(Theme.success)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(8)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(width: size, height: size)
        .rotation3DEffect(.degrees(shown ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .pulseHighlight(hinted)
        .animation(.easeInOut(duration: 0.35), value: shown)
    }
}

@MainActor
@Observable
final class MemoryModel {
    @ObservationIgnored let host: GameHost
    var cards: [MemoryCard] = []
    var group = ""
    var moves = 0
    var hinted: Int?
    /// Läuft gerade ein Vergleich? Dann werden weitere Tipps ignoriert.
    @ObservationIgnored private var comparing = false
    @ObservationIgnored private var started = false
    @ObservationIgnored private var flipTask: Task<Void, Never>?

    init(host: GameHost) { self.host = host }

    var pairs: Int {
        switch host.difficulty {
        case .entdecken: return 3
        case .ueben: return 6
        case .knobeln: return 8
        }
    }

    var columns: Int {
        switch cards.count {
        case ...6: return 3
        case ...12: return 4
        default: return 4
        }
    }

    private var revealSeconds: Double { host.options.calmMemory ? 2.8 : 1.3 }

    func start() {
        guard !started else { return }
        started = true
        host.debugSolveHandler = { [weak self] in self?.debugSolve() }
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Memory gelöst.") }
            return RoundSummary(
                text: "Memory mit \(NumberWords.word(self.pairs)) Paaren (\(self.group)) gelöst.",
                practiced: ["\(self.group) mit \(self.pairs) Paaren"]
            )
        }
        if let saved = host.takeRestoredPayload(MemoryState.self), !saved.cards.isEmpty {
            cards = saved.cards
            group = saved.group
            moves = saved.moves
            if cards.allSatisfy(\.matched) { host.resumeIfNeeded(); return }
            let open = cards.filter { $0.faceUp && !$0.matched }
            if open.count >= 2 { scheduleFlipBack() }
            host.setInstruction("Tippe zwei Karten an. Findest du zwei gleiche?")
        } else {
            newBoard()
        }
    }

    func stop() { flipTask?.cancel() }

    private func newBoard() {
        let g = MemoryCatalog.groups.randomElement()!
        group = g.title
        let motifs = Array(g.motifs.shuffled().prefix(pairs))
        var list: [MemoryCard] = []
        for (i, m) in (motifs + motifs).enumerated() {
            list.append(MemoryCard(id: i, motif: m))
        }
        cards = list.shuffled()
        moves = 0
        save()
        host.setInstruction("Tippe zwei Karten an. Findest du zwei gleiche Tiere?")
    }

    private func save() {
        host.persist(MemoryState(cards: cards, group: group, moves: moves))
    }

    func tap(_ id: Int) {
        guard !comparing, let idx = cards.firstIndex(where: { $0.id == id }) else { return }
        guard !cards[idx].faceUp, !cards[idx].matched else { return }
        hinted = nil
        host.audio.effect(.flip)
        cards[idx].faceUp = true
        let open = cards.indices.filter { cards[$0].faceUp && !cards[$0].matched }
        if open.count == 1 {
            host.audio.say(cards[idx].motif.name)
            save()
            return
        }
        guard open.count == 2 else { return }
        moves += 1
        let a = open[0], b = open[1]
        if cards[a].motif == cards[b].motif {
            cards[a].matched = true
            cards[b].matched = true
            cards[a].faceUp = false
            cards[b].faceUp = false
            host.resetHelp()
            save()
            if cards.allSatisfy(\.matched) {
                host.taskSolved("Du hast alle Paare gefunden.", needsNext: false)
            } else {
                host.audio.effect(.success)
                host.audio.say("Zwei gleiche: \(cards[a].motif.name)!")
            }
        } else {
            save()
            host.audio.say(cards[idx].motif.name)
            scheduleFlipBack()
        }
    }

    private func scheduleFlipBack() {
        comparing = true
        flipTask?.cancel()
        flipTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.revealSeconds * 1_000_000_000))
            guard !Task.isCancelled else { self.comparing = false; return }
            for i in self.cards.indices where self.cards[i].faceUp && !self.cards[i].matched {
                self.cards[i].faceUp = false
            }
            self.comparing = false
            self.save()
        }
    }

    // MARK: Hilfe

    // MARK: Automatischer Durchlauf (Simulator)

    func debugSolve() {
        help(3)
    }

    private func help(_ level: Int) {
        guard !comparing else { return }
        let open = cards.filter { $0.faceUp && !$0.matched }
        // Partnerkarte zu einer offenen Karte, sonst zu einer beliebigen verbleibenden.
        let reference = open.first ?? cards.first { !$0.matched }
        guard let ref = reference, let partner = cards.first(where: { $0.motif == ref.motif && $0.id != ref.id }) else { return }
        switch level {
        case 1:
            if open.isEmpty {
                host.showBunny("Dreh eine Karte um und merk dir das Tier.")
            } else {
                host.showBunny("Wo hast du schon \(ref.motif.name) gesehen?")
            }
        case 2:
            hinted = partner.id
            host.showBunny(open.isEmpty ? "Versuch es mit dieser Karte." : "Schau mal hier.")
        default:
            host.showBunny("Wir finden das Paar gemeinsam.")
            if open.isEmpty {
                tap(ref.id)
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 700_000_000)
                    self?.tap(partner.id)
                }
            } else {
                tap(partner.id)
            }
        }
    }
}
