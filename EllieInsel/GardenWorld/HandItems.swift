import SwiftUI

/// Ein Ding, das das Kind aus der Leiste in die Hand nimmt und durch den Garten trägt.
enum HandItem: Hashable {
    case harvest(HarvestItem)
    case dish(DishKind)
    case ice(IceKind)
    case costume(Costume)

    var asset: String {
        switch self {
        case .harvest(let h): return h.asset
        case .dish(let d): return d.asset
        case .ice(let i): return i.asset
        case .costume(let c): return c.asset
        }
    }

    var emoji: String {
        switch self {
        case .harvest(let h): return h.emoji
        case .dish(let d): return d.emoji
        case .ice(let i): return i.emoji
        case .costume(let c): return c.emoji
        }
    }

    var name: String {
        switch self {
        case .harvest(let h): return h.name
        case .dish(let d): return d.name
        case .ice(let i): return i.name
        case .costume(let c): return c.name
        }
    }
}

/// Kleines Zeichen, das über einer Figur aufsteigt (Herz, wenn es schmeckt …).
struct Reaction: Identifiable {
    var id = UUID()
    var symbol: String
    var at: CGPoint
    var start = Date()
}

extension GardenWorldModel {
    /// Was in der Leiste liegt: Ernte zuerst, dann Gekochtes (jeweils mit Anzahl).
    func handItems(limit: Int) -> [(item: HandItem, count: Int)] {
        var list: [(item: HandItem, count: Int)] = []
        if trayCostumes {
            return w.costumes.map { (.costume($0), 1) }
        }
        // Eis zuerst: das ist der Liebling
        for i in IceKind.allCases where (w.ice[i.rawValue] ?? 0) > 0 { list.append((.ice(i), w.ice[i.rawValue] ?? 0)) }
        for h in HarvestItem.allCases where w.count(h) > 0 { list.append((.harvest(h), w.count(h))) }
        for d in DishKind.allCases where w.count(d) > 0 { list.append((.dish(d), w.count(d))) }
        return Array(list.prefix(limit))
    }

    /// Finger bewegt sich mit einem Ding in der Hand (Ort im Koordinatenraum «garden»).
    func dragHand(_ item: HandItem, to loc: CGPoint) {
        if held != item {
            held = item
            audio.sfx("gw_sfx_ploppen", fallback: .tap)
        }
        heldAt = loc
        edgeScroll(loc)
    }

    /// Am Bildrand wischt der Garten von selbst weiter, damit man das Ding überallhin tragen kann.
    private func edgeScroll(_ loc: CGPoint) {
        let ext = WorldPanorama.extent(area)
        let span = ext.max - ext.min
        guard span > 1, sceneViewport.width > 0 else { return }
        let unit = sceneViewport.width * 0.25
        let current = Int(((sceneViewport.minX - sceneContentFrame.minX) / unit).rounded())
        let maxStep = Int(span * 4) - 4
        var target = current
        if loc.x > sceneViewport.maxX - 80 { target = min(current + 1, maxStep) }
        if loc.x < sceneViewport.minX + 80 { target = max(current - 1, 0) }
        guard target != current, Date().timeIntervalSince(lastEdgeScroll) > 0.45 else { return }
        lastEdgeScroll = Date()
        scrollTarget = target
        scrollTick += 1
    }

    /// Ort in Szenenanteilen (x 0…1 je Bildschirm), nil ausserhalb der Szene.
    func scenePoint(_ loc: CGPoint) -> CGPoint? {
        let ext = WorldPanorama.extent(area)
        let span = CGFloat(ext.max - ext.min)
        guard sceneContentFrame.width > 0, sceneContentFrame.height > 0, sceneViewport.contains(loc) else { return nil }
        let screen = sceneContentFrame.width / span
        return CGPoint(x: (loc.x - sceneContentFrame.minX) / screen + CGFloat(ext.min),
                       y: (loc.y - sceneContentFrame.minY) / sceneContentFrame.height)
    }

    /// Ding losgelassen: wer in der Nähe steht, bekommt es.
    func dropHand(_ item: HandItem, at loc: CGPoint) {
        held = nil
        guard let p = scenePoint(loc) else { return }
        if hitsIceMachine(p) {
            dropIntoMachine(item)
            return
        }
        let now = Date()
        var best: (index: Int, distance: Double)?
        for i in actors.indices {
            let a = actors[i]
            let pos = a.position(at: now)
            let size = a.resident?.size ?? 0.105
            // Mitte der Figur liegt über ihren Füssen
            let d = Double(hypot(pos.x - p.x, (pos.y - CGFloat(size) * 0.7 - p.y) * 0.75))
            if d < (best?.distance ?? 0.12) { best = (i, d) }
        }
        guard let hit = best else {
            audio.effect(.bump)
            return
        }
        give(item, toActor: hit.index)
    }

    /// Eine Figur bekommt ein Ding und reagiert darauf.
    private func give(_ item: HandItem, toActor i: Int) {
        let actor = actors[i]
        let pos = actor.position(at: Date())
        let above = CGPoint(x: pos.x, y: pos.y - CGFloat(actor.resident?.size ?? 0.105) * 1.3)

        if case .costume(let c) = item {
            if actor.resident == nil {
                dress(c, actor: i)
            } else {
                react("🙈", at: above)
                say("Die Verkleidung ist für Printatops.")
            }
            return
        }

        guard let r = actor.resident else {
            // Printatops probiert alles, was man essen kann.
            switch item {
            case .dish(let d) where !d.isFood:
                react("✨", at: above)
                actors[i].actionPose = "jubeln"
                actors[i].actionUntil = Date().addingTimeInterval(3)
                say("Schau, wie schön.")
            default:
                consume(item)
                react("❤️", at: above)
                actors[i].actionPose = "essen"
                actors[i].actionUntil = Date().addingTimeInterval(3)
                actors[i].restUntil = max(actors[i].restUntil, Date().addingTimeInterval(3))
                audio.sfx("gw_sfx_essen", fallback: .munch)
                say("Mjam!")
            }
            return
        }

        func enjoy() {
            actors[i].actionPose = r.actionPose
            actors[i].actionUntil = Date().addingTimeInterval(3)
            actors[i].restUntil = max(actors[i].restUntil, Date().addingTimeInterval(3))
        }

        switch item {
        case .harvest(let h) where r.foods.contains(h):
            consume(item)
            enjoy()
            react("❤️", at: above)
            audio.sfx("gw_sfx_essen", fallback: .munch)
            // Lieblingsfutter: einmal am Tag ein kleines Dankeschön
            if h == r.foods.first, let gift = r.thankYouFind,
               !Calendar.current.isDateInToday(w.fedGift[r.rawValue] ?? .distantPast) {
                edit { d in
                    d.finds[gift.rawValue, default: 0] += 1
                    d.fedGift[r.rawValue] = Date()
                }
                say("Das schmeckt! \(r.article.capitalizedFirst) \(r.name) bringt dir \(gift.name).")
            } else {
                say("Das schmeckt!")
            }
        case .ice where !r.foods.isEmpty:
            consume(item)
            enjoy()
            react("💖", at: above)
            audio.sfx("gw_sfx_essen", fallback: .munch)
            say("Eis! Mmh, lecker!")
        case .dish(let d) where d.isFood && !r.foods.isEmpty:
            consume(item)
            enjoy()
            react("💖", at: above)
            audio.sfx("gw_sfx_essen", fallback: .munch)
            say("Mmh, lecker!")
        case .dish(let d) where !d.isFood:
            enjoy()
            react("✨", at: above)
            say("Schau, wie schön.")
        default:
            // Mag das Tier nicht: es schüttelt sich, das Ding bleibt in der Leiste.
            react("🙈", at: above)
            if let file = r.soundFile {
                Task { await audio.playAnimal(file: file, imitation: r.imitation, pitch: 1.2) }
            } else {
                audio.effect(.bump)
            }
        }
    }

    private func consume(_ item: HandItem) {
        edit { d in
            switch item {
            case .harvest(let h):
                d.basket[h.rawValue, default: 1] -= 1
                if (d.basket[h.rawValue] ?? 0) <= 0 { d.basket[h.rawValue] = nil }
            case .dish(let dish):
                d.pantry[dish.rawValue, default: 1] -= 1
                if (d.pantry[dish.rawValue] ?? 0) <= 0 { d.pantry[dish.rawValue] = nil }
            case .ice(let i):
                d.ice[i.rawValue, default: 1] -= 1
                if (d.ice[i.rawValue] ?? 0) <= 0 { d.ice[i.rawValue] = nil }
            case .costume:
                break
            }
        }
    }

    func react(_ symbol: String, at p: CGPoint) {
        for k in 0..<3 {
            reactions.append(Reaction(symbol: symbol, at: CGPoint(x: p.x + CGFloat(k - 1) * 0.025, y: p.y),
                                      start: Date().addingTimeInterval(Double(k) * 0.15)))
        }
    }
}

/// Aufsteigende Herzchen und andere Zeichen über den Figuren.
struct ReactionLayer: View {
    let model: GardenWorldModel
    let size: CGSize

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: model.reactions.isEmpty)) { tl in
            ZStack(alignment: .topLeading) {
                ForEach(model.reactions) { r in
                    let t = tl.date.timeIntervalSince(r.start) / 1.3
                    if t >= 0, t < 1 {
                        Text(r.symbol)
                            .font(.system(size: size.width * 0.035))
                            .scaleEffect(0.6 + 0.6 * min(t * 3, 1))
                            .opacity(1 - max(0, t - 0.6) / 0.4)
                            .position(x: r.at.x * size.width, y: (r.at.y - CGFloat(0.09 * t)) * size.height)
                    }
                }
            }
            .frame(width: size.width, height: size.height)
        }
        .allowsHitTesting(false)
    }
}
