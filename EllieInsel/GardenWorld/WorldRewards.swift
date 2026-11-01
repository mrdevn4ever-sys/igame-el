import Foundation

/// Gartengeschenk nach einer Lernrunde. Wird als Text gespeichert («saat:erdbeere», «bau:bank» …);
/// ältere Geschenke sind einfache Emojis und werden zu Dekorationen.
enum WorldReward: Equatable {
    case seed(PlantKind)
    case kit(BuildKind)
    case piece(WaterPiece)
    case boat(BoatKind)
    case chime(ChimeKind)
    case deco(String)

    init(_ raw: String) {
        let parts = raw.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { self = .deco(raw); return }
        switch parts[0] {
        case "saat": self = PlantKind(rawValue: parts[1]).map { .seed($0) } ?? .deco("🌷")
        case "bau": self = BuildKind(rawValue: parts[1]).map { .kit($0) } ?? .deco("🌷")
        case "wasser": self = WaterPiece(rawValue: parts[1]).map { .piece($0) } ?? .deco("🌷")
        case "boot": self = BoatKind(rawValue: parts[1]).map { .boat($0) } ?? .deco("🌷")
        case "klang": self = ChimeKind(rawValue: parts[1]).map { .chime($0) } ?? .deco("🌷")
        default: self = .deco(parts[1])
        }
    }

    var raw: String {
        switch self {
        case .seed(let p): return "saat:\(p.rawValue)"
        case .kit(let b): return "bau:\(b.rawValue)"
        case .piece(let w): return "wasser:\(w.rawValue)"
        case .boat(let b): return "boot:\(b.rawValue)"
        case .chime(let c): return "klang:\(c.rawValue)"
        case .deco(let e): return e
        }
    }

    var title: String {
        switch self {
        case .seed(let p): return "\(p.name)-Samen"
        case .kit(let b): return "Bausatz \(b.name)"
        case .piece(let w): return w.name
        case .boat(let b): return b.name
        case .chime(let c): return c.name
        case .deco(let e): return GardenCatalog.names[e].map { $0.capitalizedFirst } ?? "Gartenschmuck"
        }
    }

    /// Kurze Vorschau, was man damit machen kann.
    var preview: String {
        switch self {
        case .seed(let p): return p.isFlower ? "Wächst zu einer Blume" : "Wächst, dann kannst du ernten"
        case .kit: return "Zusammenbauen und bemalen"
        case .piece: return "Für deinen Wasserweg am Bach"
        case .boat: return "Fährt auf deinem Bach"
        case .chime: return "Klingt auf der Wunderlichtung"
        case .deco: return "Für deinen Garten"
        }
    }

    var asset: String {
        switch self {
        case .seed(let p): return p.seedAsset
        case .kit(let b): return b.displayAsset
        case .piece(let w): return w.asset
        case .boat(let b): return b.asset
        case .chime(let c): return c.asset
        case .deco(let e): return GardenCatalog.asset(e)
        }
    }

    var emoji: String {
        switch self {
        case .seed(let p): return p.emoji
        case .kit(let b): return b.emoji
        case .piece: return "〰️"
        case .boat(let b): return b.emoji
        case .chime(let c): return c.emoji
        case .deco(let e): return e
        }
    }

    var speech: String {
        switch self {
        case .seed(let p): return "\(p.name)-Samen. Die kannst du im Garten pflanzen."
        case .kit(let b): return "Ein Bausatz für \(b.accusativeName). Den baust du in der Werkstatt."
        case .piece(let w): return "\(w.name) für deinen Bach."
        case .boat(let b): return "Ein \(b.name) für deinen Bach."
        case .chime(let c): return "Ein Klangding: \(c.name)."
        case .deco: return "Das kommt in deinen Garten."
        }
    }

    /// Bringt das Geschenk in die Welt. Freigeschaltetes bleibt dauerhaft nutzbar.
    func apply(to d: inout AppData) {
        switch self {
        case .seed(let p): if !d.world.seeds.contains(p) { d.world.seeds.append(p) }
        case .kit(let b): if !d.world.kits.contains(b) { d.world.kits.append(b) }
        case .piece(let w): if !d.world.pieces.contains(w) { d.world.pieces.append(w) }
        case .boat(let b): if !d.world.boats.contains(b) { d.world.boats.append(b) }
        case .chime(let c): if !d.world.chimeKinds.contains(c) { d.world.chimeKinds.append(c) }
        case .deco(let e): d.garden.inventory.append(e)
        }
    }

    /// Drei passende Möglichkeiten: nur Dinge, die Ellie gerade auch benutzen kann.
    static func options(roundID: String, data: AppData) -> [String] {
        let w = data.world
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: roundID.stableHash))
        var useful: [WorldReward] = []
        useful += PlantKind.allCases.filter { !w.seeds.contains($0) }.map { .seed($0) }
        if w.workshopOpen {
            var kits: [BuildKind] = [.bank, .futterstelle, .insektenhotel, .blumentopf, .windspiel, .vogelhaus]
            if w.isUnlocked(.lichtung) { kits.append(.tunnel) }
            if w.isUnlocked(.baumhaus) { kits += [.wimpelkette, .laterne] }
            if w.isUnlocked(.bach) { kits.append(.segelboot) }
            useful += kits.filter { !w.kits.contains($0) }.map { .kit($0) }
        }
        if w.isUnlocked(.bach) {
            useful += WaterPiece.allCases.filter { !w.pieces.contains($0) }.map { .piece($0) }
            useful += BoatKind.allCases.filter { !w.boats.contains($0) }.map { .boat($0) }
        }
        if w.isUnlocked(.wunder) {
            useful += ChimeKind.allCases.filter { !w.chimeKinds.contains($0) }.map { .chime($0) }
        }
        let owned = data.garden.inventory + data.garden.placed.map(\.item)
        var decos = GardenCatalog.rewardItems.filter { !owned.contains($0) }.map { WorldReward.deco($0) }
        if decos.isEmpty { decos = GardenCatalog.rewardItems.map { WorldReward.deco($0) } }

        useful.shuffle(using: &rng)
        decos.shuffle(using: &rng)
        // Möglichst verschiedene Arten anbieten
        var picked: [WorldReward] = []
        var kinds: Set<String> = []
        for r in useful where picked.count < 3 {
            let k = String(r.raw.split(separator: ":").first ?? "")
            if !kinds.contains(k) {
                picked.append(r)
                kinds.insert(k)
            }
        }
        for r in useful where picked.count < 3 && !picked.contains(r) { picked.append(r) }
        for r in decos where picked.count < 3 { picked.append(r) }
        return picked.map(\.raw)
    }
}
