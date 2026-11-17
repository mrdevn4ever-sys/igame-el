import SwiftUI

// MARK: - Eis

/// Eissorten aus der Eismaschine.
enum IceKind: String, Codable, CaseIterable, Identifiable {
    case erdbeer, heidelbeer, apfel, karotten, sonnenblumen, schoko, regenbogen, einhorn, herz

    var id: String { rawValue }
    var asset: String { "gw_eis_\(rawValue)" }

    var emoji: String {
        switch self {
        case .regenbogen: return "🌈"
        case .einhorn: return "🦄"
        case .herz: return "💖"
        default: return "🍦"
        }
    }

    var name: String {
        switch self {
        case .erdbeer: return "Erdbeereis"
        case .heidelbeer: return "Heidelbeereis"
        case .apfel: return "Apfeleis"
        case .karotten: return "Karotteneis"
        case .sonnenblumen: return "Sonnenblumeneis"
        case .schoko: return "Schokoladeneis"
        case .regenbogen: return "Regenbogen-Eis"
        case .einhorn: return "Einhorn-Eis"
        case .herz: return "Herz-Eis"
        }
    }

    /// Welches Eis aus diesen Zutaten wird.
    static func recipe(_ input: [HarvestItem]) -> IceKind {
        let kinds = Set(input)
        if kinds == [.erdbeere, .heidelbeeren] { return .einhorn }
        if kinds.count >= 3 { return .regenbogen }
        if kinds == [.erdbeere] && input.count >= 2 { return .herz }
        if kinds.count == 1, let one = kinds.first {
            switch one {
            case .erdbeere: return .erdbeer
            case .heidelbeeren: return .heidelbeer
            case .apfel: return .apfel
            case .karotte: return .karotten
            case .kerne: return .sonnenblumen
            default: break
            }
        }
        // Alles andere: Überraschung
        return .schoko
    }

    /// Was in die Eismaschine passt (keine Blumen).
    static func accepts(_ h: HarvestItem) -> Bool { !h.isFlower && h != .blatt }
}

// MARK: - Verkleidung

/// Verkleidungen für Printatops. Die Bilder liegen deckungsgleich auf gw_dino_stehen.
enum Costume: String, Codable, CaseIterable, Identifiable {
    case krone, schleife, blumenkranz, feenfluegel, tutu, zauberstab, sonnenbrille, halskette

    var id: String { rawValue }
    var asset: String { "gw_kostuem_\(rawValue)" }

    var emoji: String {
        switch self {
        case .krone: return "👑"
        case .schleife: return "🎀"
        case .blumenkranz: return "🌸"
        case .feenfluegel: return "🧚"
        case .tutu: return "🩰"
        case .zauberstab: return "🪄"
        case .sonnenbrille: return "🕶️"
        case .halskette: return "📿"
        }
    }

    var name: String {
        switch self {
        case .krone: return "Krone"
        case .schleife: return "Schleife"
        case .blumenkranz: return "Blumenkranz"
        case .feenfluegel: return "Feenflügel"
        case .tutu: return "Tutu"
        case .zauberstab: return "Zauberstab"
        case .sonnenbrille: return "Herz-Brille"
        case .halskette: return "Perlenkette"
        }
    }

    /// Nur eines je Platz: Kopf, Gesicht, Hals, Rücken, Bauch, Hand.
    var slot: String {
        switch self {
        case .krone, .schleife, .blumenkranz: return "kopf"
        case .sonnenbrille: return "gesicht"
        case .halskette: return "hals"
        case .feenfluegel: return "ruecken"
        case .tutu: return "bauch"
        case .zauberstab: return "hand"
        }
    }

    static let starter: [Costume] = [.krone, .schleife, .tutu]
}

// MARK: - Eismaschine

extension GardenWorldModel {
    /// Wo die Eismaschine steht (nur im Hausgarten).
    var icePos: CGPoint { WorldLayout.iceMachine }

    /// Liegt der Punkt (Szenenanteile) auf der Eismaschine?
    func hitsIceMachine(_ p: CGPoint) -> Bool {
        guard area == .haus, ImageCache.image("gw_station_eismaschine") != nil else { return false }
        let m = icePos
        return abs(p.x - m.x) < 0.065 && p.y > m.y - 0.15 && p.y < m.y + 0.02
    }

    /// Eine Frucht fällt in die Eismaschine.
    func dropIntoMachine(_ item: HandItem) {
        guard case .harvest(let h) = item, IceKind.accepts(h), machineInput.count < 3, machineRunUntil == nil else {
            audio.effect(.bump)
            react("🙈", at: CGPoint(x: icePos.x, y: icePos.y - 0.16))
            if machineInput.count >= 3 { say("Die Eismaschine ist voll.") }
            return
        }
        edit { d in
            d.basket[h.rawValue, default: 1] -= 1
            if (d.basket[h.rawValue] ?? 0) <= 0 { d.basket[h.rawValue] = nil }
        }
        machineInput.append(h)
        machineLastDrop = Date()
        audio.sfx("gw_sfx_ploppen", fallback: .snap)
        if machineInput.count == 1 { say("Noch mehr Früchte? Oder warte, dann gibt es Eis.") }
    }

    /// Im Takt: nach einer kurzen Pause läuft die Maschine, danach kommt das Eis heraus.
    func tickIceMachine(now: Date) {
        if let until = machineRunUntil {
            guard now >= until else { return }
            machineRunUntil = nil
            let ice = IceKind.recipe(machineInput)
            machineInput = []
            let first = !w.iceFound.contains(ice.rawValue)
            edit { d in
                d.ice[ice.rawValue, default: 0] += 1
                if first { d.iceFound.append(ice.rawValue) }
            }
            iceBurst = (ice, now)
            audio.sfx("gw_sfx_entdeckt", fallback: .success)
            react(first ? "⭐️" : "✨", at: CGPoint(x: icePos.x, y: icePos.y - 0.17))
            say(first ? "Ein neues Eis! \(ice.name)!" : "\(ice.name)!")
            return
        }
        if !machineInput.isEmpty, now.timeIntervalSince(machineLastDrop) > 1.6 {
            machineRunUntil = now.addingTimeInterval(1.6)
            audio.sfx("gw_sfx_umruehren", fallback: .flip)
        }
    }

    func iceMachineTapped() {
        audio.effect(.tap)
        say(machineInput.isEmpty ? "Die Eismaschine! Zieh Früchte aus deinem Korb hinein." : "Gleich gibt es Eis.")
    }

    // MARK: Verkleiden

    /// Printatops eine Verkleidung anziehen (oder wieder ausziehen, wenn er sie schon trägt).
    func dress(_ c: Costume, actor i: Int) {
        let pos = actors[i].position(at: Date())
        if w.worn[c.slot] == c.rawValue {
            edit { $0.worn[c.slot] = nil }
            audio.sfx("gw_sfx_rascheln", fallback: .flip)
            say("Ausgezogen.")
        } else {
            edit { $0.worn[c.slot] = c.rawValue }
            audio.sfx("gw_sfx_zauber", fallback: .success)
            react("💖", at: CGPoint(x: pos.x, y: pos.y - 0.16))
            say(["Wie schön!", "Schau mal, wie hübsch!", "Das gefällt Printatops!"].randomElement() ?? "Wie schön!")
        }
        // Printatops bleibt kurz stehen und zeigt sich.
        actors[i].from = pos
        actors[i].to = pos
        actors[i].duration = 0
        actors[i].actionPose = nil
        actors[i].restUntil = Date().addingTimeInterval(5)
    }

    /// Getragene Verkleidungen, Flügel zuerst (hinter Printatops).
    var wornCostumes: [Costume] {
        Costume.allCases.filter { w.worn[$0.slot] == $0.rawValue }
    }
}

/// Die Eismaschine im Garten: wackelt beim Laufen, zeigt die eingefüllten Früchte und das fertige Eis.
struct IceMachineView: View {
    let model: GardenWorldModel
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20, paused: model.machineRunUntil == nil && model.iceBurst == nil)) { tl in
            let now = tl.date
            let running = model.machineRunUntil != nil
            let t = now.timeIntervalSinceReferenceDate
            ZStack(alignment: .bottom) {
                WorldPic(running && Int(t * 6) % 2 == 0 ? "gw_station_eismaschine_laeuft" : "gw_station_eismaschine", "🍦", size: size)
                    .scaleEffect(x: running ? 1 + 0.04 * sin(t * 30) : 1, y: running ? 1 - 0.04 * sin(t * 30) : 1, anchor: .bottom)
                // Eingefüllte Früchte schweben über der Schale
                HStack(spacing: -size * 0.04) {
                    ForEach(model.machineInput.indices, id: \.self) { i in
                        WorldPic(model.machineInput[i].asset, model.machineInput[i].emoji, size: size * 0.24)
                    }
                }
                .offset(y: -size * 0.86)
                // Fertiges Eis springt kurz heraus
                if let burst = model.iceBurst, now.timeIntervalSince(burst.at) < 1.6 {
                    let k = min(now.timeIntervalSince(burst.at) / 0.5, 1)
                    WorldPic(burst.kind.asset, burst.kind.emoji, size: size * 0.6)
                        .scaleEffect(0.3 + 0.9 * k)
                        .offset(x: size * 0.45 * k, y: -size * (0.2 + 0.4 * sin(.pi * min(k, 1))))
                }
            }
            .frame(width: size, height: size)
        }
    }
}
