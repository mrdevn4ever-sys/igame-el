import SwiftUI
import Observation

/// Figur in einer Szene (Bewohner oder Printatops). Bewegung wird zwischen zwei Punkten interpoliert.
struct WorldActor: Identifiable, Equatable {
    var id: String
    var resident: Resident?
    var from: CGPoint
    var to: CGPoint
    var start: Date
    var duration: Double
    /// Bis wann eine besondere Pose gezeigt wird
    var actionUntil: Date = .distantPast
    var actionPose: String?
    var restUntil: Date = .distantPast

    func position(at t: Date) -> CGPoint {
        guard duration > 0 else { return to }
        let f = min(max(t.timeIntervalSince(start) / duration, 0), 1)
        let e = f * f * (3 - 2 * f)
        return CGPoint(x: from.x + (to.x - from.x) * e, y: from.y + (to.y - from.y) * e)
    }

    func moving(at t: Date) -> Bool { t.timeIntervalSince(start) < duration }
    var facingLeft: Bool { to.x < from.x }
}

/// Fliegt ein Erntestück in den Korb.
struct Flyer: Identifiable {
    var id = UUID()
    var asset: String
    var emoji: String
    var from: CGPoint
    var start = Date()
}

/// Laufende Bootsfahrt am Bach.
struct BoatRun {
    var kind: BoatKind
    var path: [CGPoint]
    var start = Date()
    var secondsPerStep = 0.9
    var success: Bool
    var gap: (col: Int, row: Int)?
    var total: Double { Double(max(path.count - 1, 1)) * secondsPerStep }
}

/// Ergebnis der Wassersimulation.
struct WaterFlow {
    var wet: Set<Int> = []
    var pond = false
    var bed = false
    var wheels = false
    var gap: (col: Int, row: Int)?
    static func key(_ c: Int, _ r: Int) -> Int { r * 10 + c }
}

enum WorldOverlay: Equatable {
    case map, book, kitchen, workshop(BuildKind?), seeds(Int), sunflower(Int), picnic, light, fantasy(Int), celebration(String)
    /// Die Wohnstube im Haus
    case house
}

@MainActor
@Observable
final class GardenWorldModel {
    @ObservationIgnored let app: AppModel

    var area: WorldArea
    var building = false
    var overlay: WorldOverlay?
    /// Gebautes Objekt, das noch einen Platz braucht
    var placing: BuiltObject?
    var dinoText: String?
    var flyers: [Flyer] = []
    var actors: [WorldActor] = []
    var boat: BoatRun?
    var countProgress: [String: Int] = [:]
    var waterAnim: [Int: Date] = [:]
    var growAnim: [Int: Date] = [:]
    var shakeAnim: Date?
    var rainUntil: Date?
    var rainbowUntil: Date?
    var chimeGlow: [Int: Date] = [:]
    var fantasyPulse: [UUID: Date] = [:]
    var melodyPlaying = false
    var selectedPiece: WaterPiece?
    /// Schaufel am Bach: Antippen nimmt eine Rinne wieder weg.
    var removingTiles = false
    /// Im Selbsttest: die Ergebnis-Notiz bleibt in der Sprechblase stehen.
    @ObservationIgnored private var noteShown = false
    /// Küche oder Erinnerungsbuch wurden aus dem Haus geöffnet: Schliessen führt zurück in die Wohnstube.
    var fromHouse = false
    var lastWaterResult = WaterFlow()

    @ObservationIgnored private var loop: Task<Void, Never>?
    @ObservationIgnored private var dinoTask: Task<Void, Never>?
    @ObservationIgnored private var factIndex: [Resident: Int] = [:]
    @ObservationIgnored private var squirrelTaps = 0

    /// Wartezeit im Simulator-Durchlauf.
    static var growSeconds: Double { stageSeconds(firstHarvestDone: true) }

    /// Dauer einer Wachstumsstufe. Bis zur allerersten Ernte wächst alles sehr schnell, damit das Kind
    /// den ganzen Kreislauf (säen, giessen, ernten) in der ersten Sitzung erlebt. Danach dauert eine Stufe
    /// wenige Minuten; jede abgeschlossene Lernrunde lässt zusätzlich alles eine Stufe wachsen.
    static func stageSeconds(firstHarvestDone: Bool) -> Double {
        if DemoMode.isActive { return 1.5 }
        return firstHarvestDone ? 180 : 20
    }

    var stageSeconds: Double { Self.stageSeconds(firstHarvestDone: !w.harvestedOnce.isEmpty) }

    /// Stufe, bei der eine Pflanze noch einmal Durst bekommt (einmal nachgiessen bis zur Ernte).
    static let thirstStage = 2

    init(app: AppModel) {
        self.app = app
        area = app.data.world.lastArea
        if let raw = DemoMode.value("-area"), let a = WorldArea(rawValue: raw) { area = a }
        if !app.data.world.isUnlocked(area) && !DemoMode.isActive { area = .haus }
        lastWaterResult = computeFlow()
    }

    var w: WorldData { app.data.world }
    func edit(_ f: (inout WorldData) -> Void) { app.update { f(&$0.world) } }
    var audio: AudioManager { app.audio }

    // MARK: - Ablauf

    /// Erster Start im neuen Garten: Gebautes und Gartenschmuck stehen noch an Plätzen des alten Gartens,
    /// wo jetzt Haus, Schuppen oder Gemüsebeet sind. Einmalig auf die freie Wiese umstellen.
    private func moveIntoNewGarden() {
        guard WorldLayout.garden3 else { return }
        let wide = WorldPanorama.isActive(.haus)
        let target = wide ? 2 : 1
        guard w.gardenLayout < target else { return }
        var spots = WorldLayout.spots(.haus)
        // Mit Spielwiese: alles auf die Wiese rechts, die Plätze am Haus bleiben frei.
        if wide { spots.removeAll { $0.x < 1 } }
        app.update { d in
            var extra = 0
            for i in d.world.built.indices where d.world.built[i].area == .haus {
                if spots.isEmpty {
                    // Mehr Bauten als Stellplätze: der Rest kommt in eine Reihe ganz vorne.
                    d.world.built[i].x = (wide ? 1.1 : 0.22) + 0.14 * Double(extra % 5)
                    d.world.built[i].y = 0.995
                    extra += 1
                } else {
                    let p = spots.removeFirst()
                    d.world.built[i].x = Double(p.x)
                    d.world.built[i].y = Double(p.y)
                }
            }
            // Gartenschmuck zwischen den Stellplätzen der Bauten
            let xs: [Double] = wide ? [1.05, 1.23, 1.41, 1.59, 1.77, 1.93] : [0.27, 0.5, 0.7, 0.9, 0.06, 0.33, 0.55, 0.74, 0.21]
            let ys: [Double] = wide ? [0.86, 0.7, 0.99] : [0.945, 0.995]
            for i in d.garden.placed.indices {
                d.garden.placed[i].x = xs[i % xs.count]
                d.garden.placed[i].y = ys[(i / xs.count) % ys.count]
            }
            d.world.gardenLayout = target
        }
    }

    /// `quiet`: ohne Begrüssung (Rückkehr aus einem Spiel direkt in die Wohnstube).
    func start(quiet: Bool = false) {
        moveIntoNewGarden()
        if quiet {
            // nichts ansagen
        } else if !w.introDone {
            edit { $0.introDone = true }
            say("Hallo, ich bin Printatops! Das ist dein Garten. Tippe auf ein Beet, dann pflanzen wir etwas zusammen.")
        } else if let r = app.data.garden.pendingRewards.first {
            say("Ein Geschenk aus \(r.game.title) wartet auf dich.")
        } else {
            say(contextHint())
        }
        // Gelegentlich ein kurzer Regen, wenn Pflanzen Durst haben
        if !DemoMode.isActive, w.beds.contains(where: { $0.plant != nil && $0.needsWater && $0.stage < 4 }), Int.random(in: 0..<8) == 0 {
            startRain()
        }
        resetActors()
        loop?.cancel()
        loop = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                self?.tick()
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }

    func stop() {
        loop?.cancel()
        dinoTask?.cancel()
        edit { $0.lastArea = area }
    }

    // MARK: - Haus

    /// Durch die Haustür in die Wohnstube.
    func enterHouse() {
        audio.sfx("gw_sfx_tuer", fallback: .flip)
        let first = !w.houseVisited
        if first { edit { $0.houseVisited = true } }
        building = false
        withAnimation(.easeInOut(duration: 0.3)) { overlay = .house }
        say(first ? "Willkommen zu Hause! Im Regal warten deine Spiele." : "Willkommen zu Hause!")
    }

    /// Zurück in den Garten.
    func leaveHouse() {
        audio.sfx("gw_sfx_tuer", fallback: .flip)
        fromHouse = false
        withAnimation(.easeInOut(duration: 0.3)) { overlay = nil }
    }

    /// Aus der Wohnstube in die Küche oder zum Erinnerungsbuch.
    func openFromHouse(_ o: WorldOverlay) {
        fromHouse = true
        withAnimation(.easeInOut(duration: 0.25)) { overlay = o }
    }

    /// Schliesst Küche oder Buch: zurück dorthin, wo sie geöffnet wurden.
    func closeOverlay() {
        withAnimation(.easeInOut(duration: 0.25)) { overlay = fromHouse ? .house : nil }
        fromHouse = false
    }

    /// Schlafen gehen oder aufstehen (Bett in der Wohnstube).
    func bedTime() {
        audio.sfx("gw_sfx_zauber", fallback: .flip)
        edit { $0.evening.toggle() }
        say(w.evening ? "Gute Nacht! Printatops kuschelt sich ins Bett." : "Guten Morgen! Die Sonne scheint.")
        resetActors()
    }

    func go(_ a: WorldArea) {
        guard w.isUnlocked(a) else {
            say("Diesen Ort hast du noch nicht entdeckt.")
            return
        }
        audio.sfx("gw_sfx_bruecke", fallback: .flip)
        withAnimation(.easeInOut(duration: 0.35)) {
            area = a
            overlay = nil
        }
        building = false
        removingTiles = false
        selectedPiece = nil
        resetActors()
        say(arrivalText(a))
    }

    private func arrivalText(_ a: WorldArea) -> String {
        switch a {
        case .haus: return "Wir sind im Hausgarten."
        case .bach: return w.tiles.isEmpty ? "Am Bach kannst du Wasserwege bauen. Wähle unten eine Rinne und tippe auf ein Feld." : "Wir sind am Bach."
        case .lichtung: return "Willkommen auf der Tierlichtung."
        case .baumhaus: return w.treehouseStage < 4 ? "Hier bauen wir ein Baumhaus!" : "Wir sind beim Baumhaus."
        case .wunder: return "Die Wunderlichtung! Hier ist alles ein bisschen zauberhaft."
        }
    }

    func say(_ text: String) {
        // Eine bleibende Notiz (Selbsttest) wird nicht von späteren Ansagen überschrieben.
        guard !text.isEmpty, !noteShown else { return }
        audio.say(text)
        withAnimation(.spring(response: 0.3)) { dinoText = text }
        dinoTask?.cancel()
        let seconds = max(4.0, Double(text.count) / 13)
        dinoTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withAnimation { self?.dinoText = nil }
        }
    }

    /// Bleibende Notiz in der Sprechblase ohne Ansage (für den Selbsttest im Simulator, damit das
    /// Ergebnis auf dem Screenshot steht).
    func showNote(_ text: String) {
        dinoTask?.cancel()
        noteShown = true
        dinoText = text
    }

    /// Printatops antippen: wiederholt, was gerade sinnvoll ist.
    func dinoTapped() {
        audio.sfx("gw_sfx_entdeckt", fallback: .tap)
        if let step = activeSteps().first(where: { $0.step.area == area }) {
            say(step.step.say)
        } else {
            say(contextHint())
        }
        nudgeDino()
    }

    func contextHint() -> String {
        switch area {
        case .haus:
            let beds = w.beds.prefix(WorldPanorama.bedCount)
            if beds.contains(where: { $0.isRipe }) { return "Etwas ist reif! Tippe darauf und ernte es." }
            if beds.contains(where: { $0.plant != nil && $0.needsWater && $0.stage < 4 }) { return "Deine Pflanzen haben Durst. Tippe auf das Beet zum Giessen." }
            if beds.contains(where: { $0.isEmpty }) { return "Tippe auf ein freies Beet und such dir einen Samen aus." }
            if w.basket.values.reduce(0, +) > 2 { return "Dein Korb ist voll. In der Küche kannst du etwas zubereiten." }
            if !w.pantry.isEmpty && w.picnic == nil { return "Tippe auf die Picknickdecke und mach ein Picknick." }
            return "Schau, was in deinem Garten wächst."
        case .bach:
            if lastWaterResult.pond { return "Das Wasser fliesst bis zum Teich! Tippe auf das Boot an der Quelle." }
            if let g = lastWaterResult.gap { return "Hier fehlt noch ein Stück: Reihe \(g.row + 1), Feld \(g.col + 1)." }
            return "Baue mit den Rinnen einen Weg von der Quelle zum Teich."
        case .lichtung: return "Schau dich um. Vielleicht findest du Spuren."
        case .baumhaus: return w.treehouseStage < 4 ? "Tippe auf die Bauteile, dann wächst das Baumhaus." : "Im Baumhaus kann man wunderbar picknicken."
        case .wunder: return "Stell Klangdinge auf und tippe auf Abspielen. Oder pflanze eine Fantasieblume."
        }
    }

    // MARK: - Takt

    func tick() {
        let now = Date()
        var changed = false
        var newlyRipe: [PlantKind] = []
        var data = w
        let raining = (rainUntil ?? .distantPast) > now
        let stageTime = stageSeconds
        func grow(_ bed: inout BedState, index: Int) {
            guard bed.plant != nil else { return }
            if raining, bed.needsWater, bed.stage < 4 {
                bed.needsWater = false
                bed.growingSince = now
                changed = true
            }
            guard var since = bed.growingSince else { return }
            // Auch mehrere Stufen auf einmal, wenn die App länger zu war.
            var advanced = false
            while bed.stage < 4, now.timeIntervalSince(since) >= stageTime {
                bed.stage += 1
                since = since.addingTimeInterval(stageTime)
                advanced = true
                if bed.stage == Self.thirstStage && !raining { break }
            }
            guard advanced else { return }
            if bed.stage >= 4 {
                bed.stage = 4
                bed.needsWater = false
                bed.growingSince = nil
                bed.remaining = bed.plant?.yield ?? 1
                bed.fallen = []
                if let p = bed.plant { newlyRipe.append(p) }
            } else if bed.stage == Self.thirstStage && !raining {
                bed.needsWater = true
                bed.growingSince = nil
            } else {
                bed.growingSince = since
            }
            growAnim[index] = now
            changed = true
        }
        for i in data.beds.indices { grow(&data.beds[i], index: i) }
        // Bachbeet: wird vom Wasserlauf gegossen
        if lastWaterResult.bed, data.streamBed.plant != nil, data.streamBed.needsWater, data.streamBed.stage < 4 {
            data.streamBed.needsWater = false
            data.streamBed.growingSince = now
            changed = true
        }
        grow(&data.streamBed, index: 99)

        // Ankunft von Bewohnern ohne eigenes Abenteuer
        if data.isUnlocked(.bach) && !data.residents.contains(.fisch) { data.residents.append(.fisch); changed = true }
        if data.pondReached && !data.residents.contains(.ente) {
            data.residents.append(.ente)
            data.memories.append(WorldMemory(kind: .bewohner, detail: Resident.ente.rawValue))
            changed = true
            if area == .bach { say("Eine Ente ist im Teich gelandet!") }
        }
        let blooming = data.beds.contains { ($0.plant?.isFlower ?? false) && $0.stage >= 3 }
        if blooming && !data.visitors.contains(.schmetterling) { data.visitors.append(.schmetterling); changed = true }

        if changed {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                app.update { $0.world = data }
            }
            if let p = newlyRipe.first, area == .haus || area == .bach {
                audio.sfx("gw_sfx_wachsen", fallback: .success)
                say(p.ripeText)
            }
            if area == .haus || area == .bach { resetActorsIfNeeded() }
        }

        // Bedingungen in Abenteuern
        for entry in activeSteps() {
            switch entry.step.kind {
            case .evening where w.evening: completeStep(entry.adventure)
            case .boatToPond where w.pondReached: completeStep(entry.adventure)
            case .build(let k) where w.built.contains(where: { $0.kind == k && $0.area == entry.step.area }): completeStep(entry.adventure)
            default: break
            }
        }

        updateActors(now: now)
        if let b = boat, now.timeIntervalSince(b.start) > b.total + 0.6 { finishBoat() }
        flyers.removeAll { now.timeIntervalSince($0.start) > 1.2 }
    }

    // MARK: - Pflanzen

    func bedTapped(_ index: Int) {
        guard !building, index < w.beds.count else { return }
        let bed = w.beds[index]
        moveDino(to: WorldLayout.beds[index])
        if bed.isEmpty {
            overlay = .seeds(index)
            audio.sfx("gw_sfx_rascheln", fallback: .tap)
            say(index == 3 ? "Hier ist Platz für einen Baum." : "Such dir einen Samen aus.")
        } else if bed.isRipe {
            harvestTap(index)
        } else if bed.needsWater {
            water(index)
        } else {
            say("Es wächst gerade.")
        }
    }

    func availableSeeds(for index: Int) -> [PlantKind] {
        if index == 3 { return w.seeds.contains(.apfelbaum) ? [.apfelbaum] : [] }
        return w.seeds.filter { !$0.isTree }
    }

    func plant(_ kind: PlantKind, in index: Int) {
        overlay = nil
        audio.sfx("gw_sfx_pflanzen", fallback: .snap)
        edit { d in
            if index == 99 {
                d.streamBed = BedState(plant: kind, stage: 0, needsWater: true)
            } else {
                d.beds[index] = BedState(plant: kind, stage: 0, needsWater: true)
            }
        }
        growAnim[index] = Date()
        say(index == 99 ? "Gepflanzt! Wenn dein Wasserweg hierher fliesst, wird das Beet gegossen." : "Der Samen ist in der Erde. Jetzt kannst du giessen.")
    }

    func water(_ index: Int) {
        let now = Date()
        audio.sfx("gw_sfx_giessen", fallback: .flip)
        waterAnim[index] = now
        edit { d in
            guard d.beds[index].needsWater, d.beds[index].stage < 4 else { return }
            d.beds[index].needsWater = false
            d.beds[index].growingSince = now
            d.beds[index].wetUntil = now.addingTimeInterval(3)
        }
        if w.beds[index].stage == 0 { say("Gut gegossen! Schau, gleich wächst etwas.") }
    }

    func waterAll() {
        let now = Date()
        edit { d in
            for i in d.beds.indices where d.beds[i].plant != nil && d.beds[i].needsWater && d.beds[i].stage < 4 {
                d.beds[i].needsWater = false
                d.beds[i].growingSince = now
                d.beds[i].wetUntil = now.addingTimeInterval(4)
            }
        }
    }

    /// Ernte je nach Pflanze: pflücken, ziehen, schwer, schütteln, Kerne.
    func harvestTap(_ index: Int) {
        guard let plant = w.beds[index].plant, w.beds[index].isRipe else { return }
        switch plant.style {
        case .seeds:
            overlay = .sunflower(index)
            say("Tippe auf die Kerne im Blütenkopf.")
        case .shake:
            if w.beds[index].fallen.isEmpty {
                shakeAnim = Date()
                audio.sfx("gw_sfx_rascheln", fallback: .bump)
                let n = w.beds[index].remaining
                edit { d in d.beds[index].fallen = (0..<n).map { i in 0.12 + 0.76 * Double(i) / Double(max(n - 1, 1)) } }
                say("Die Äpfel fallen herunter! Sammle sie ein.")
            }
        default:
            collect(index, piece: nil)
        }
    }

    /// Ein Stück ernten und in den Korb fliegen lassen.
    func collect(_ index: Int, piece: Int?, at point: CGPoint? = nil) {
        guard let plant = (index == 99 ? w.streamBed.plant : w.beds[index].plant) else { return }
        let item = plant.harvest
        var bed = index == 99 ? w.streamBed : w.beds[index]
        guard bed.remaining > 0 else { return }
        bed.remaining -= 1
        if let piece, piece < bed.fallen.count { bed.fallen.remove(at: piece) }
        let first = !w.harvestedOnce.contains(item.rawValue)
        let base = index == 99 ? WorldLayout.streamBed : WorldLayout.beds[min(index, WorldLayout.beds.count - 1)]
        flyers.append(Flyer(asset: item.asset, emoji: item.emoji, from: point ?? CGPoint(x: base.x, y: base.y - 0.1)))
        switch plant.style {
        case .pull: audio.sfx("gw_sfx_ziehen", fallback: .snap)
        case .heavy: audio.sfx("gw_sfx_schwer", fallback: .bump)
        default: audio.sfx("gw_sfx_ploppen", fallback: .tap)
        }
        let done = bed.remaining == 0
        if done {
            if plant.regrows {
                bed.stage = 2
                bed.needsWater = true
                bed.fallen = []
            } else {
                bed = BedState()
            }
        }
        edit { d in
            if index == 99 { d.streamBed = bed } else { d.beds[index] = bed }
            d.basket[item.rawValue, default: 0] += 1
            if first {
                d.harvestedOnce.append(item.rawValue)
                d.memories.append(WorldMemory(kind: .ersteErnte, detail: plant.rawValue))
            }
        }
        if first {
            say(item.firstText + " In der Küche kannst du daraus etwas machen.")
        } else if done {
            say(plant.regrows ? "Alles geerntet! Die Pflanze wächst wieder nach, wenn du sie giesst." : "Alles geerntet! Das Beet ist wieder frei.")
        } else if plant.yield > 1 {
            audio.say(NumberWords.word(plant.yield - bed.remaining))
        }
    }

    func sunflowerSeed(_ index: Int) {
        collect(index, piece: nil, at: CGPoint(x: 0.5, y: 0.5))
        if w.beds[index].isEmpty { overlay = nil }
    }

    // MARK: - Küche und Picknick

    func cook(_ dish: DishKind, used: [HarvestItem]) {
        let first = !w.cooked.contains(dish.rawValue)
        edit { d in
            for h in used { d.basket[h.rawValue, default: 1] -= 1; if (d.basket[h.rawValue] ?? 0) <= 0 { d.basket[h.rawValue] = nil } }
            d.pantry[dish.rawValue, default: 0] += 1
            if first {
                d.cooked.append(dish.rawValue)
                d.memories.append(WorldMemory(kind: .gericht, detail: dish.rawValue))
            }
        }
        audio.sfx("gw_sfx_teller", fallback: .success)
    }

    func guests(in a: WorldArea) -> Int {
        1 + min(3, presentResidents(a).filter { ![.fisch, .schmetterling, .schnecke].contains($0) }.count)
    }

    func startPicnic(dishes: [DishKind], blanket: Int, plates: Int) {
        let firstPicnic = w.memories.contains { $0.kind == .picknick } == false
        edit { d in
            for dish in dishes {
                d.pantry[dish.rawValue, default: 1] -= 1
                if (d.pantry[dish.rawValue] ?? 0) <= 0 { d.pantry[dish.rawValue] = nil }
            }
            d.picnic = PicnicState(area: .haus, blanket: blanket, dishes: dishes, plates: plates)
            d.memories.append(WorldMemory(kind: .picknick, detail: WorldArea.haus.rawValue, extra: dishes.map(\.rawValue)))
            if !d.workshopOpen {
                d.workshopOpen = true
                if !d.kits.contains(.vogelhaus) { d.kits.append(.vogelhaus) }
            }
        }
        overlay = nil
        audio.sfx("gw_sfx_essen", fallback: .munch)
        moveDino(to: CGPoint(x: WorldLayout.blanket.x + 0.05, y: WorldLayout.blanket.y), pose: "essen", seconds: 6)
        // Gäste kommen zur Decke
        for i in actors.indices where actors[i].resident != nil && !(actors[i].resident?.flies ?? false) {
            let target = CGPoint(x: WorldLayout.blanket.x - 0.06 - Double(i) * 0.04, y: WorldLayout.blanket.y + 0.04)
            actors[i].from = actors[i].position(at: Date())
            actors[i].to = target
            actors[i].start = Date()
            actors[i].duration = 2.5
            actors[i].restUntil = Date().addingTimeInterval(10)
        }
        if firstPicnic {
            say(WorldLayout.garden3 ? "Mmh, lecker! Danke für das Picknick. Im Schuppen ist die Werkstatt."
                : "Mmh, lecker! Danke für das Picknick. Schau mal, hinten im Garten steht jetzt eine Werkbank. Dort kannst du bauen.")
        } else {
            say("Picknick! Printatops lässt es sich schmecken.")
        }
    }

    // MARK: - Werkstatt und Bauen

    func openWorkshop(_ kind: BuildKind? = nil) {
        guard w.workshopOpen || kind != nil else {
            say(WorldLayout.garden3 ? "Der Schuppen ist noch zu. Mach zuerst ein Picknick." : "Die Werkbank ist noch zugedeckt. Mach zuerst ein Picknick.")
            return
        }
        audio.sfx("gw_sfx_hammer", fallback: .tap)
        overlay = .workshop(kind)
    }

    /// Fertig gebaut und bemalt: aufstellen.
    func finishBuild(_ obj: BuiltObject) {
        overlay = nil
        // Ein Abenteuer wartet genau auf dieses Bauwerk: an seiner Stelle aufstellen.
        if let entry = activeSteps().first(where: {
            if case .build(let k) = $0.step.kind { return k == obj.kind }
            return false
        }) {
            var o = obj
            o.area = entry.step.area
            o.x = entry.step.x
            o.y = entry.step.y
            place(o)
            if area != o.area { go(o.area) }
            return
        }
        let target = obj.kind.areas.contains(area) ? area : (obj.kind.areas.first { w.isUnlocked($0) } ?? .haus)
        if area != target { go(target) }
        var o = obj
        o.area = target
        if obj.kind == .segelboot {
            o.x = WorldLayout.dock.x
            o.y = WorldLayout.dock.y
            place(o)
            return
        }
        placing = o
        say("Wo soll \(obj.kind.definiteName) stehen? Tippe auf einen leuchtenden Platz.")
    }

    func freeSpots(_ a: WorldArea) -> [CGPoint] {
        WorldLayout.spots(a).filter { p in
            !w.built.contains { $0.area == a && abs($0.x - p.x) < 0.04 && abs($0.y - p.y) < 0.04 }
        }
    }

    func placeAt(_ p: CGPoint) {
        guard var o = placing else { return }
        o.x = p.x
        o.y = p.y
        placing = nil
        place(o)
    }

    private func place(_ o: BuiltObject) {
        edit { d in
            d.built.append(o)
            d.memories.append(WorldMemory(kind: .gebaut, detail: o.id.uuidString))
        }
        audio.sfx("gw_sfx_einrasten", fallback: .success)
        say(reactionText(for: o.kind))
        resetActors()
        // Ein Bewohner schaut sich das Neue an
        if let i = actors.firstIndex(where: { $0.resident?.likes.contains(o.kind) ?? false }) {
            actors[i].from = actors[i].position(at: Date())
            actors[i].to = CGPoint(x: o.x + 0.04, y: o.y - (actors[i].resident?.flies == true ? 0.12 : 0))
            actors[i].start = Date()
            actors[i].duration = 2.5
            actors[i].restUntil = Date().addingTimeInterval(6)
        }
    }

    private func reactionText(for k: BuildKind) -> String {
        switch k {
        case .vogelhaus: return "Dein Vogelhaus steht! Mal sehen, wer es entdeckt."
        case .bank: return "Eine Bank! Da setzt sich bestimmt bald jemand hin."
        case .futterstelle: return "Die Futterstelle ist bereit. Mit Sonnenblumenkernen kommen die Vögel."
        case .insektenhotel: return "Im Insektenhotel finden Bienen und Käfer ein Zuhause."
        case .bruecke: return "Die Brücke ist fertig!"
        case .igelhaus: return "Das Igelhaus steht. Jetzt braucht es noch Blätter."
        case .tunnel: return "Ein Tunnel aus Weiden! Wer wohl hindurchläuft?"
        case .windspiel: return "Hör mal, wie das Windspiel klingt."
        case .segelboot: return "Dein Segelboot liegt im Teich."
        default: return "Wunderschön! Das hast du selbst gemacht."
        }
    }

    func fillFeeder(_ id: UUID) {
        guard w.count(.kerne) > 0 else {
            say("Für die Futterstelle brauchst du Sonnenblumenkerne. Pflanze eine Sonnenblume.")
            return
        }
        edit { d in
            d.basket[HarvestItem.kerne.rawValue, default: 1] -= 1
            if (d.basket[HarvestItem.kerne.rawValue] ?? 0) <= 0 { d.basket[HarvestItem.kerne.rawValue] = nil }
        }
        audio.sfx("gw_sfx_korb", fallback: .snap)
        if let o = w.built.first(where: { $0.id == id }), let i = actors.firstIndex(where: { $0.resident == .vogel }) {
            actors[i].from = actors[i].position(at: Date())
            actors[i].to = CGPoint(x: o.x, y: o.y - 0.14)
            actors[i].start = Date()
            actors[i].duration = 2
            actors[i].restUntil = Date().addingTimeInterval(8)
            actors[i].actionPose = "picken"
            actors[i].actionUntil = Date().addingTimeInterval(8)
            say("Das Rotkehlchen pickt die Kerne. Danke!")
        } else {
            say("Die Kerne liegen bereit. Bald kommt ein Vogel.")
        }
    }

    func moveBuilt(_ id: UUID, to p: CGPoint) {
        edit { d in
            guard let i = d.built.firstIndex(where: { $0.id == id }) else { return }
            let ext = WorldPanorama.extent(d.built[i].area)
            d.built[i].x = min(max(Double(p.x), ext.min + 0.04), ext.max - 0.04)
            d.built[i].y = min(max(p.y, 0.2), 0.97)
        }
    }

    // MARK: - Bewohner

    func presentResidents(_ a: WorldArea) -> [Resident] {
        var list = (w.residents + w.visitors).filter { $0.home == a }
        if w.evening { list.removeAll { $0.diurnal } } else { list.removeAll { $0.nocturnal } }
        var seen: Set<Resident> = []
        return list.filter { seen.insert($0).inserted }
    }

    func resetActors() {
        let now = Date()
        var list: [WorldActor] = []
        let dinoHome: CGPoint = area == .haus ? WorldLayout.dinoHome : CGPoint(x: 0.5, y: 0.86)
        list.append(WorldActor(id: "dino", resident: nil, from: dinoHome, to: dinoHome, start: now, duration: 0,
                               restUntil: now.addingTimeInterval(4)))
        for (i, r) in presentResidents(area).enumerated() {
            let p = randomPoint(for: r, seed: i)
            list.append(WorldActor(id: r.rawValue, resident: r, from: p, to: p, start: now, duration: 0,
                                   restUntil: now.addingTimeInterval(Double(i) + 1)))
        }
        actors = list
    }

    private func resetActorsIfNeeded() {
        let ids = Set(actors.compactMap { $0.resident })
        if ids != Set(presentResidents(area)) { resetActors() }
    }

    private func randomPoint(for r: Resident?, seed: Int = 0) -> CGPoint {
        var rect = WorldLayout.walkArea(area, resident: r)
        // Am Bach auch oben links auf der Wiese beim Wasserfall laufen (links vom Wasserbaukasten).
        if area == .bach, !WorldPanorama.isActive(.bach), r == nil || !(r!.flies || r == .ente || r == .fisch || r == .frosch),
           Bool.random() {
            rect = WorldLayout.bachUpperMeadow
        }
        return CGPoint(x: rect.minX + Double.random(in: 0...1) * rect.width, y: rect.minY + Double.random(in: 0...1) * rect.height)
    }

    private func updateActors(now: Date) {
        for i in actors.indices {
            let a = actors[i]
            guard !a.moving(at: now), now > a.restUntil else { continue }
            let here = a.position(at: now)
            var target = randomPoint(for: a.resident)
            var pose: String?
            if a.id == "dino" {
                // Printatops besucht Bank, Brücke oder Picknick
                if let bench = w.built.first(where: { $0.area == area && $0.kind == .bank }), Int.random(in: 0..<3) == 0 {
                    target = CGPoint(x: bench.x, y: bench.y + 0.01)
                    pose = "sitzen"
                } else if area == .bach, w.isBuilt(.bruecke), Int.random(in: 0..<3) == 0 {
                    target = CGPoint(x: WorldLayout.bridge.x + 0.08, y: WorldLayout.bridge.y)
                } else if area == .haus, w.picnic != nil, Int.random(in: 0..<3) == 0 {
                    target = CGPoint(x: WorldLayout.blanket.x + 0.05, y: WorldLayout.blanket.y)
                    pose = "sitzen"
                }
            } else if let r = a.resident {
                let liked = w.built.filter { $0.area == area && r.likes.contains($0.kind) }
                if let o = liked.randomElement(), Int.random(in: 0..<2) == 0 {
                    target = CGPoint(x: o.x + Double.random(in: -0.03...0.03), y: r.flies ? o.y - 0.13 : o.y + 0.01)
                    pose = r.actionPose
                } else if r == .schmetterling, let bi = w.beds.indices.prefix(WorldPanorama.bedCount).first(where: { (w.beds[$0].plant?.isFlower ?? false) && w.beds[$0].stage >= 3 }) {
                    let b = WorldLayout.beds[bi]
                    target = CGPoint(x: b.x, y: b.y - 0.16)
                    pose = "sitzen"
                }
            }
            let dist = hypot(target.x - here.x, target.y - here.y)
            let speed = a.resident?.speed ?? 0.06
            actors[i].from = here
            actors[i].to = target
            actors[i].start = now
            actors[i].duration = max(0.8, dist / speed)
            actors[i].restUntil = now.addingTimeInterval(actors[i].duration + Double.random(in: 2...6))
            if let pose {
                actors[i].actionPose = pose
                actors[i].actionUntil = actors[i].restUntil
            } else {
                actors[i].actionPose = nil
            }
        }
    }

    func moveDino(to p: CGPoint, pose: String? = nil, seconds: Double = 3) {
        guard let i = actors.firstIndex(where: { $0.id == "dino" }) else { return }
        let now = Date()
        let here = actors[i].position(at: now)
        let target = CGPoint(x: p.x + 0.07, y: min(p.y + 0.04, 0.96))
        actors[i].from = here
        actors[i].to = target
        actors[i].start = now
        actors[i].duration = max(0.6, hypot(target.x - here.x, target.y - here.y) / 0.2)
        actors[i].restUntil = now.addingTimeInterval(actors[i].duration + seconds)
        actors[i].actionPose = pose
        actors[i].actionUntil = pose == nil ? .distantPast : actors[i].restUntil
    }

    private func nudgeDino() {
        guard let i = actors.firstIndex(where: { $0.id == "dino" }) else { return }
        actors[i].actionPose = "winken"
        actors[i].actionUntil = Date().addingTimeInterval(2)
    }

    func residentTapped(_ r: Resident) {
        let n = factIndex[r, default: 0]
        factIndex[r] = n + 1
        if let i = actors.firstIndex(where: { $0.resident == r }) {
            actors[i].actionPose = r.actionPose
            actors[i].actionUntil = Date().addingTimeInterval(2.5)
            actors[i].restUntil = max(actors[i].restUntil, Date().addingTimeInterval(2.5))
        }
        if let file = r.soundFile {
            Task { await audio.playAnimal(file: file, imitation: r.imitation, pitch: 1.2) }
        }
        // Das Eichhörnchen bringt ab und zu ein Fundstück
        if r == .eichhoernchen {
            squirrelTaps += 1
            if squirrelTaps % 3 == 0 {
                let f = [FindItem.eichel, .tannzapfen, .goldblatt, .stein].randomElement() ?? .eichel
                edit { $0.finds[f.rawValue, default: 0] += 1 }
                say("Das Eichhörnchen bringt dir \(f.name). Das kannst du in der Werkstatt verwenden.")
                return
            }
        }
        if r == .hase, w.count(.karotte) > 0, n % 2 == 1 {
            edit { d in
                d.basket[HarvestItem.karotte.rawValue, default: 1] -= 1
                if (d.basket[HarvestItem.karotte.rawValue] ?? 0) <= 0 { d.basket[HarvestItem.karotte.rawValue] = nil }
            }
            audio.sfx("gw_sfx_essen", fallback: .munch)
            say("Der Hase knabbert eine Karotte aus deinem Korb.")
            return
        }
        say(r.facts[n % r.facts.count])
    }

    // MARK: - Abenteuer

    struct ActiveStep {
        var adventure: Adventure
        var step: AdventureStep
        var index: Int
    }

    func activeSteps() -> [ActiveStep] {
        let data = w
        return AdventureCatalog.all.compactMap { adv in
            guard !data.adventuresDone.contains(adv.id) else { return nil }
            let idx = data.adventures[adv.id] ?? 0
            guard idx < adv.steps.count else { return nil }
            // Ein noch nicht begonnenes Abenteuer erscheint nur, wenn es passt.
            if idx == 0 && !adv.available(data) { return nil }
            // Im neuen Garten liegen die Stellen des Hausgartens woanders.
            var step = adv.steps[idx]
            let p = WorldLayout.stepPoint(adventure: adv.id, index: idx, area: step.area, fallback: CGPoint(x: step.x, y: step.y))
            step.x = Double(p.x)
            step.y = Double(p.y)
            return ActiveStep(adventure: adv, step: step, index: idx)
        }
    }

    func hotspotTapped(_ entry: ActiveStep) {
        let step = entry.step
        audio.sfx("gw_sfx_entdeckt", fallback: .tap)
        switch step.kind {
        case .tap:
            completeStep(entry.adventure)
        case .count(let n):
            let c = countProgress[entry.adventure.id, default: 0] + 1
            countProgress[entry.adventure.id] = c
            audio.say(NumberWords.word(c))
            audio.sfx("gw_sfx_korb", fallback: .snap)
            if c >= n {
                countProgress[entry.adventure.id] = 0
                completeStep(entry.adventure)
            }
        case .build(let k):
            if !w.kits.contains(k) { edit { $0.kits.append(k) } }
            if !w.workshopOpen { edit { $0.workshopOpen = true } }
            say(step.say)
            openWorkshop(k)
        case .dish(let d):
            let available: DishKind? = d.flatMap { w.count($0) > 0 ? $0 : nil }
                ?? (d == nil ? DishKind.allCases.first { $0.isFood && w.count($0) > 0 } : nil)
            if let dish = available {
                edit { data in
                    data.pantry[dish.rawValue, default: 1] -= 1
                    if (data.pantry[dish.rawValue] ?? 0) <= 0 { data.pantry[dish.rawValue] = nil }
                }
                audio.sfx("gw_sfx_teller", fallback: .snap)
                completeStep(entry.adventure)
            } else {
                say(step.say)
            }
        case .item(let h):
            if w.count(h) > 0 {
                edit { d in
                    d.basket[h.rawValue, default: 1] -= 1
                    if (d.basket[h.rawValue] ?? 0) <= 0 { d.basket[h.rawValue] = nil }
                }
                audio.sfx("gw_sfx_essen", fallback: .munch)
                completeStep(entry.adventure)
            } else {
                say("Du brauchst zuerst \(h == .karotte ? "eine Karotte" : h.name). Pflanze sie im Beet und ernte sie.")
            }
        case .boatToPond:
            say(step.say)
        case .evening:
            say(step.say)
        }
    }

    func completeStep(_ adv: Adventure) {
        let idx = w.adventures[adv.id] ?? 0
        guard idx < adv.steps.count else { return }
        let step = adv.steps[idx]
        edit { d in
            step.onComplete?(&d)
            d.adventures[adv.id] = idx + 1
            if idx + 1 >= adv.steps.count {
                adv.finish(&d)
                if !d.adventuresDone.contains(adv.id) { d.adventuresDone.append(adv.id) }
            }
        }
        if idx + 1 >= adv.steps.count {
            audio.sfx("gw_sfx_entdeckt", fallback: .complete)
            say(adv.finishText)
            if adv.id == "fest" {
                overlay = .celebration(adv.finishText)
                playMelody()
            } else {
                overlay = .celebration(adv.finishText)
            }
            resetActors()
        } else {
            let next = adv.steps[idx + 1]
            if next.area == area || next.kind == .evening {
                say(next.say)
            } else {
                say("Weiter geht es: \(next.area.title). Schau auf der Karte.")
            }
        }
    }

    // MARK: - Abend und Wetter

    func toggleEvening() {
        audio.sfx("gw_sfx_zauber", fallback: .flip)
        edit { $0.evening.toggle() }
        say(w.evening ? "Guten Abend, Garten. Hörst du die Grillen?" : "Guten Morgen! Die Sonne scheint.")
        resetActors()
    }

    func startRain() {
        rainUntil = Date().addingTimeInterval(7)
        rainbowUntil = Date().addingTimeInterval(16)
        waterAll()
        say("Es regnet! Der Regen giesst alle Pflanzen.")
    }

    // MARK: - Wasserbau

    func tileAt(_ c: Int, _ r: Int) -> WaterTile? { w.tiles.first { $0.col == c && $0.row == r } }

    func cellTapped(_ c: Int, _ r: Int) {
        if removingTiles {
            if tileAt(c, r) != nil { removeTile(c, r) }
            return
        }
        if let t = tileAt(c, r) {
            if t.piece == .schleuse && selectedPiece == nil {
                edit { d in if let i = d.tiles.firstIndex(where: { $0.id == t.id }) { d.tiles[i].open.toggle() } }
                audio.sfx("gw_sfx_schleuse", fallback: .snap)
            } else if t.piece.rotations > 1 {
                edit { d in if let i = d.tiles.firstIndex(where: { $0.id == t.id }) { d.tiles[i].rotation = (d.tiles[i].rotation + 1) % 4 } }
                audio.sfx("gw_sfx_einrasten", fallback: .tap)
            }
        } else if let p = selectedPiece {
            edit { $0.tiles.append(WaterTile(col: c, row: r, piece: p)) }
            audio.sfx("gw_sfx_einrasten", fallback: .snap)
        } else {
            say("Wähle unten zuerst eine Rinne aus.")
            return
        }
        refreshWater()
    }

    func removeTile(_ c: Int, _ r: Int) {
        edit { d in d.tiles.removeAll { $0.col == c && $0.row == r } }
        audio.sfx("gw_sfx_platschen", fallback: .flip)
        refreshWater()
    }

    func refreshWater() {
        let before = lastWaterResult
        lastWaterResult = computeFlow()
        if lastWaterResult.pond && !before.pond { say("Das Wasser fliesst bis in den Teich!"); audio.sfx("gw_sfx_wasser_fliessen", fallback: .success) }
        if lastWaterResult.bed && !before.bed { say("Das Wasser fliesst zum Beet. Jetzt wird es von selbst gegossen.") }
        if lastWaterResult.wheels && !before.wheels { say("Das Wasserrad dreht sich!"); audio.sfx("gw_sfx_wasserrad", fallback: .flip) }
    }

    private static let dirs = [(1, 0), (0, -1), (-1, 0), (0, 1)]

    func computeFlow() -> WaterFlow {
        var flow = WaterFlow()
        var queue: [(Int, Int, Int)] = [(0, 0, 2)]
        var visited: Set<Int> = []
        while !queue.isEmpty {
            let (c, r, entry) = queue.removeFirst()
            let key = WaterFlow.key(c, r) * 4 + entry
            if visited.contains(key) { continue }
            visited.insert(key)
            guard let t = tileAt(c, r) else {
                if flow.gap == nil { flow.gap = (c, r) }
                continue
            }
            guard t.openings.contains(entry) else { continue }
            flow.wet.insert(WaterFlow.key(c, r))
            if t.piece == .wasserrad { flow.wheels = true }
            if t.piece == .schleuse && !t.open { continue }
            for o in t.openings where o != entry {
                let nc = c + Self.dirs[o].0, nr = r + Self.dirs[o].1
                if nc >= WorldLayout.gridCols && o == 0 {
                    if r == WorldLayout.gridRows - 1 { flow.pond = true }
                    if r == 0 { flow.bed = true }
                    continue
                }
                guard nc >= 0, nr >= 0, nc < WorldLayout.gridCols, nr < WorldLayout.gridRows else { continue }
                queue.append((nc, nr, (o + 2) % 4))
            }
        }
        return flow
    }

    /// Weg des Boots: folgt dem Wasser, an Verzweigungen abwechselnd.
    func launchBoat(_ kind: BoatKind) {
        guard boat == nil else { return }
        var path: [CGPoint] = [WorldLayout.source]
        var c = 0, r = 0, entry = 2
        var success = false
        var gap: (col: Int, row: Int)?
        var steps = 0
        let turn = w.boatTrips
        while steps < 40 {
            steps += 1
            guard let t = tileAt(c, r), t.openings.contains(entry) else { gap = (c, r); break }
            if t.piece == .schleuse && !t.open { gap = (c, r); break }
            path.append(WorldLayout.cellCenter(col: c, row: r))
            let exits = t.openings.filter { $0 != entry }
            guard !exits.isEmpty else { break }
            let straight = (entry + 2) % 4
            let o: Int
            if exits.contains(straight) && t.piece != .verzweigung { o = straight } else { o = exits[turn % exits.count] }
            let nc = c + Self.dirs[o].0, nr = r + Self.dirs[o].1
            if nc >= WorldLayout.gridCols && o == 0 && r == WorldLayout.gridRows - 1 {
                path.append(WorldLayout.pond)
                success = true
                break
            }
            if nc < 0 || nr < 0 || nc >= WorldLayout.gridCols || nr >= WorldLayout.gridRows { break }
            c = nc; r = nr; entry = (o + 2) % 4
        }
        audio.sfx("gw_sfx_platschen", fallback: .flip)
        boat = BoatRun(kind: kind, path: path, success: success, gap: gap)
        edit { $0.boatTrips += 1 }
    }

    private func finishBoat() {
        guard let b = boat else { return }
        boat = nil
        if b.success {
            let first = !w.pondReached
            edit { d in
                d.pondReached = true
                if !first, Int.random(in: 0..<3) == 0 {
                    let f = [FindItem.muschel, .stein, .schneckenhaus, .flaschenpost].randomElement() ?? .muschel
                    d.finds[f.rawValue, default: 0] += 1
                }
            }
            audio.sfx("gw_sfx_platschen", fallback: .success)
            if !first { say("Das \(b.kind.name) ist im Teich angekommen!") }
            if let i = actors.firstIndex(where: { $0.resident == .ente }) {
                actors[i].from = actors[i].position(at: Date())
                actors[i].to = CGPoint(x: WorldLayout.pond.x - 0.04, y: WorldLayout.pond.y + 0.05)
                actors[i].start = Date()
                actors[i].duration = 2
                actors[i].restUntil = Date().addingTimeInterval(5)
            }
        } else if let g = b.gap {
            let t = tileAt(g.col, g.row)
            if t?.piece == .schleuse {
                say("Die Schleuse ist zu. Tippe darauf, dann geht sie auf.")
            } else if t != nil {
                say("Hier passt die Rinne nicht. Tippe darauf, dann dreht sie sich.")
            } else {
                say("Das Boot steckt fest. Hier fehlt noch ein Stück.")
            }
            lastWaterResult.gap = g
        } else {
            say("Das Boot ist ans Ufer gestossen. Versuch einen anderen Weg.")
        }
    }

    // MARK: - Wunderlichtung

    func setChime(_ slot: Int, _ kind: ChimeKind?) {
        edit { d in d.chimes[slot] = kind }
        if let kind {
            audio.tone(kind.frequency, file: kind.sound)
            chimeGlow[slot] = Date()
        }
    }

    func chimeTapped(_ slot: Int) {
        guard let k = w.chimes[slot] else { return }
        audio.tone(k.frequency, file: k.sound)
        chimeGlow[slot] = Date()
    }

    func playMelody() {
        let notes = w.chimes.enumerated().compactMap { i, k in k.map { (i, $0) } }
        guard !notes.isEmpty, !melodyPlaying else {
            if notes.isEmpty { say("Stell zuerst Klangdinge auf die Plätze.") }
            return
        }
        melodyPlaying = true
        let first = !w.memories.contains { $0.kind == .melodie }
        Task { @MainActor [weak self] in
            guard let self else { return }
            for _ in 0..<2 {
                for (i, k) in notes {
                    if self.area == .wunder { self.moveDino(to: WorldLayout.chimeSlots[i], seconds: 0.3) }
                    self.audio.tone(k.frequency, file: k.sound)
                    self.chimeGlow[i] = Date()
                    try? await Task.sleep(nanoseconds: 520_000_000)
                }
            }
            self.melodyPlaying = false
            if first {
                self.edit { $0.memories.append(WorldMemory(kind: .melodie, extra: notes.map { $0.1.rawValue })) }
                self.say("Das ist deine eigene Melodie!")
            }
        }
    }

    func plantFantasy(_ f: FantasyFlower) {
        let first = w.fantasy.isEmpty
        edit { d in
            d.fantasy.removeAll { $0.slot == f.slot }
            d.fantasy.append(f)
            if first { d.memories.append(WorldMemory(kind: .fantasieblume, detail: f.id.uuidString)) }
        }
        overlay = nil
        audio.sfx("gw_sfx_zauber", fallback: .success)
        fantasyPulse[f.id] = Date()
        say("Deine Fantasieblume \(f.reaction.name)!")
    }

    func fantasyTapped(_ f: FantasyFlower) {
        fantasyPulse[f.id] = Date()
        switch f.reaction {
        case .klingeln: audio.tone(1046.5)
        case .aufgehen: audio.sfx("gw_sfx_zauber", fallback: .flip)
        case .lichtpunkte: audio.sfx("gw_sfx_zauber", fallback: .success)
        }
    }

    func lightSolved() {
        let level = w.lightLevel
        edit { d in
            d.lightLevel = level + 1
            if level + 1 == 3, !d.chimeKinds.contains(.tropfenharfe) { d.chimeKinds.append(.tropfenharfe) }
        }
        audio.sfx("gw_sfx_zauber", fallback: .complete)
        say(level + 1 == 3 ? "Alle Knospen leuchten! Du bekommst eine Tropfenharfe für den Klanggarten." : "Die Knospe öffnet sich! Probier das nächste Lichträtsel.")
    }

    // MARK: - Umbauen (Dekorationen)

    func placeDecoration(_ item: String, at p: CGPoint) {
        guard let idx = app.data.garden.inventory.firstIndex(of: item) else { return }
        audio.sfx("gw_sfx_einrasten", fallback: .snap)
        app.update { d in
            d.garden.inventory.remove(at: idx)
            d.garden.placed.append(PlacedDecoration(item: item, x: p.x, y: p.y))
        }
    }

    func moveDecoration(_ id: UUID, to p: CGPoint) {
        app.update { d in
            guard let i = d.garden.placed.firstIndex(where: { $0.id == id }) else { return }
            let ext = WorldPanorama.extent(.haus)
            d.garden.placed[i].x = min(max(Double(p.x), ext.min + 0.03), ext.max - 0.03)
            d.garden.placed[i].y = min(max(p.y, 0.15), 0.97)
        }
    }

    func storeDecoration(_ id: UUID) {
        app.update { d in
            guard let i = d.garden.placed.firstIndex(where: { $0.id == id }) else { return }
            d.garden.inventory.append(d.garden.placed[i].item)
            d.garden.placed.remove(at: i)
        }
        audio.sfx("gw_sfx_korb", fallback: .tap)
    }

    func storeBuilt(_ id: UUID) {
        edit { d in d.built.removeAll { $0.id == id } }
        audio.sfx("gw_sfx_korb", fallback: .tap)
        say("Weggeräumt. In der Werkstatt kannst du es neu bauen.")
    }

    func claim(_ reward: PendingReward, _ option: String) {
        app.claimReward(reward, item: option)
        audio.sfx("gw_sfx_entdeckt", fallback: .success)
        say(WorldReward(option).speech)
    }
}

// MARK: - Automatischer Durchlauf (nur Simulator-Test)

extension GardenWorldModel {
    /// Spielt den ganzen Kreislauf einmal durch: pflanzen, giessen, ernten, kochen, Picknick,
    /// bauen, Wasserweg, Boot, Klanggarten, Erinnerungsbuch.
    func runDemoPlay() {
        Task { @MainActor [weak self] in
            func wait(_ s: Double) async { try? await Task.sleep(nanoseconds: UInt64(s * 1_000_000_000)) }
            guard let self else { return }
            await wait(2)
            self.bedTapped(0)
            await wait(1)
            self.plant(.erdbeere, in: 0)
            self.plant(.karotte, in: 1)
            self.plant(.sonnenblume, in: 2)
            for _ in 0..<6 {
                for i in 0..<3 where self.w.beds[i].needsWater && self.w.beds[i].stage < 4 { self.water(i) }
                await wait(Self.growSeconds + 0.7)
            }
            var guardCount = 0
            while self.w.beds[0].remaining > 0 && guardCount < 10 { self.collect(0, piece: nil); guardCount += 1; await wait(0.3) }
            self.collect(1, piece: nil)
            self.overlay = .sunflower(2)
            await wait(1)
            guardCount = 0
            while self.w.beds[2].remaining > 0 && guardCount < 10 { self.sunflowerSeed(2); guardCount += 1; await wait(0.2) }
            self.overlay = .kitchen
            await wait(2)
            self.cook(.erdbeerschale, used: [.erdbeere, .erdbeere, .erdbeere])
            self.overlay = nil
            self.startPicnic(dishes: [.erdbeerschale], blanket: 1, plates: self.guests(in: .haus))
            await wait(3)
            self.openWorkshop(.vogelhaus)
            await wait(2)
            self.finishBuild(BuiltObject(kind: .vogelhaus, area: .haus, x: 0.5, y: 0.8, roof: .gelb, body: .blau, pattern: .sterne))
            await wait(1)
            if self.placing != nil, let p = self.freeSpots(.haus).first { self.placeAt(p) }
            await wait(2)
            for _ in 0..<4 {
                for e in self.activeSteps() where e.step.area == self.area { self.hotspotTapped(e) }
                await wait(1)
            }
            self.edit { d in
                for a in WorldArea.allCases where !d.unlocked.contains(a) { d.unlocked.append(a) }
                d.tiles = [WaterTile(col: 0, row: 0, piece: .kurve, rotation: 2),
                           WaterTile(col: 0, row: 1, piece: .gerade, rotation: 1),
                           WaterTile(col: 0, row: 2, piece: .gerade, rotation: 1),
                           WaterTile(col: 0, row: 3, piece: .kurve, rotation: 0)]
                    + (1..<6).map { WaterTile(col: $0, row: 3, piece: .gerade) }
            }
            self.go(.bach)
            self.refreshWater()
            await wait(1.5)
            self.launchBoat(.blatt)
            await wait(9)
            self.go(.lichtung)
            await wait(2)
            for _ in 0..<3 {
                for e in self.activeSteps() where e.step.area == self.area { self.hotspotTapped(e) }
                await wait(1)
            }
            self.go(.wunder)
            await wait(1)
            self.setChime(0, .glockenblume)
            self.setChime(1, .kristall)
            self.setChime(2, .pilztrommel)
            self.playMelody()
            await wait(4)
            self.plantFantasy(FantasyFlower(slot: 1, shape: .herz, color: .lila, stem: .spirale, reaction: .lichtpunkte))
            await wait(2)
            self.toggleEvening()
            await wait(2)
            self.go(.haus)
            await wait(2)
            self.overlay = .book
        }
    }
}
