import SwiftUI
import UIKit

/// Start-Argumente für automatische Screenshots und Durchläufe im Simulator (nur Debug-Builds).
///
/// Beispiele:
///   -demo -screen hub -page 1
///   -demo -screen game -game memory -difficulty ueben -autoplay
///   -demo -screen setup -step 2
enum DemoMode {
    static let arguments = ProcessInfo.processInfo.arguments

    static var isActive: Bool {
        #if DEBUG
        return arguments.contains("-demo")
        #else
        return false
        #endif
    }

    static func value(_ key: String) -> String? {
        guard isActive, let i = arguments.firstIndex(of: key), i + 1 < arguments.count else { return nil }
        return arguments[i + 1]
    }

    static func flag(_ key: String) -> Bool { isActive && arguments.contains(key) }

    static var autoplay: Bool { flag("-autoplay") }

    /// Vorbereiteter Zustand mit ein paar Inhalten für aussagekräftige Screenshots.
    static func makeData() -> AppData {
        var d = AppData()
        d.setupComplete = value("-screen") != "setup"
        d.setupStep = Int(value("-step") ?? "0") ?? 0
        d.tutorialDone = true
        d.parentCodeHash = CodeHasher.hash("123456")
        d.sound.masterMuted = true
        d.profile = Profile(name: "Ellie", avatar: .fuchs)
        if let raw = value("-difficulty"), let diff = Difficulty(rawValue: raw) {
            for g in GameID.allCases { d.difficulties[g.rawValue] = diff }
        }
        if let raw = value("-level"), let l = Int(raw) {
            for g in GameID.allCases {
                d.skills[g.rawValue] = SkillState(level: min(max(l, 1), LevelCatalog.maxLevel(g)))
            }
        }
        d.lastGame = GameID.memory.rawValue
        d.garden.placed = [
            PlacedDecoration(item: "🌷", x: 0.33, y: 0.74), PlacedDecoration(item: "🌻", x: 0.5, y: 0.52)
        ]
        d.garden.inventory = Array(d.garden.inventory.dropFirst(3))
        d.garden.pendingRewards = value("-world") == nil ? [PendingReward(id: "demo", game: .memory, options: ["saat:tomate", "bau:bank", "🦔"])] : []
        if let stage = value("-world") { d.world = demoWorld(stage) }
        let stats = HelpStats(instructionRepeats: 2, hints: 1, demonstrations: 0, solvedTogether: 0)
        d.activities = [
            ActivityEntry(date: Date(), game: .tracing, difficulty: .entdecken, text: "Zahlen 3, 1, 5, 2 nachgezeichnet.", stats: stats),
            ActivityEntry(date: Date().addingTimeInterval(-3600), game: .memory, difficulty: .ueben, text: "Memory mit sechs Paaren (Waldtiere) gelöst.", stats: HelpStats())
        ]
        d.roundsCompleted = [GameID.tracing.rawValue: 3, GameID.memory.rawValue: 2]
        // Erste Demo-Runde bringt ein Gartengeschenk (sonst erst jede dritte Runde).
        d.garden.learningRoundsSinceGift = GardenData.roundsPerGift - 1
        if let raw = value("-treasures"), let n = Int(raw) {
            d.atelierTreasures = Array(AtelierTreasures.all.prefix(max(0, n)).map(\.id))
        }
        if let raw = value("-zaehlniveau"), let l = Int(raw) {
            d.skills[GameID.counting.rawValue] = SkillState(level: l)
        }
        d.practicedItems = [GameID.tracing.rawValue: ["Ziffer 1", "Ziffer 2", "Ziffer 3"]]
        return d
    }

    /// Gartenwelt in verschiedenen Ständen: «start», «mitte», «voll».
    static func demoWorld(_ stage: String) -> WorldData {
        var w = WorldData()
        w.introDone = stage != "start"
        w.evening = flag("-abend")
        guard stage != "start" else { return w }
        let now = Date()
        w.beds[0] = BedState(plant: .erdbeere, stage: 4, needsWater: false, remaining: 5)
        w.beds[1] = BedState(plant: .karotte, stage: 2, needsWater: true)
        w.beds[2] = BedState(plant: .sonnenblume, stage: 3, needsWater: false, growingSince: now)
        w.basket = ["erdbeere": 4, "karotte": 2, "apfel": 3, "kerne": 2]
        w.harvestedOnce = ["erdbeere", "karotte"]
        w.pantry = ["erdbeerschale": 1, "obstschale": 1]
        w.cooked = ["erdbeerschale"]
        w.workshopOpen = true
        w.kits = [.vogelhaus, .bank, .futterstelle]
        w.picnic = PicnicState(area: .haus, blanket: 0, dishes: [.erdbeerschale], plates: 2)
        w.built = [BuiltObject(kind: .vogelhaus, area: .haus, x: 0.47, y: 0.44, roof: .gelb, body: .blau, pattern: .punkte),
                   BuiltObject(kind: .bank, area: .haus, x: 0.28, y: 0.86, roof: .rot, body: .rosa)]
        w.residents = [.vogel, .hase]
        w.visitors = [.schmetterling]
        w.unlocked = [.haus, .bach]
        w.seeds = PlantKind.starter + [.apfelbaum, .tomate, .tulpe]
        w.tiles = [WaterTile(col: 0, row: 0, piece: .gerade), WaterTile(col: 1, row: 0, piece: .kurve, rotation: 3),
                   WaterTile(col: 1, row: 1, piece: .gerade, rotation: 1), WaterTile(col: 1, row: 2, piece: .gerade, rotation: 1)]
        w.adventuresDone = ["schmetterling", "vogelhaus", "hase"]
        w.memories = [WorldMemory(kind: .ersteErnte, detail: "erdbeere"), WorldMemory(kind: .picknick, detail: "haus", extra: ["erdbeerschale"]),
                      WorldMemory(kind: .gebaut, detail: w.built[0].id.uuidString), WorldMemory(kind: .bewohner, detail: "vogel"),
                      WorldMemory(kind: .ort, detail: "bach")]
        guard stage == "voll" else { return w }
        w.beds[3] = BedState(plant: .apfelbaum, stage: 4, needsWater: false, remaining: 7)
        w.beds[4] = BedState(plant: .tomate, stage: 4, needsWater: false, remaining: 6)
        w.beds[5] = BedState(plant: .tulpe, stage: 3, needsWater: false, growingSince: now)
        w.beds[6] = BedState(plant: .kuerbis, stage: 4, needsWater: false, remaining: 1)
        w.built.append(BuiltObject(kind: .insektenhotel, area: .haus, x: 1.55, y: 0.5, roof: .rot, body: .natur))
        w.unlocked = WorldArea.allCases
        w.kits = BuildKind.allCases
        w.pieces = WaterPiece.allCases
        w.boats = BoatKind.allCases
        w.tiles = [WaterTile(col: 0, row: 0, piece: .gerade), WaterTile(col: 1, row: 0, piece: .schleuse),
                   WaterTile(col: 2, row: 0, piece: .verzweigung, rotation: 0),
                   WaterTile(col: 3, row: 0, piece: .gerade), WaterTile(col: 4, row: 0, piece: .wasserrad), WaterTile(col: 5, row: 0, piece: .gerade),
                   WaterTile(col: 2, row: 1, piece: .gerade, rotation: 1), WaterTile(col: 2, row: 2, piece: .gerade, rotation: 1),
                   WaterTile(col: 2, row: 3, piece: .kurve, rotation: 0), WaterTile(col: 3, row: 3, piece: .gerade),
                   WaterTile(col: 4, row: 3, piece: .gerade), WaterTile(col: 5, row: 3, piece: .gerade)]
        w.streamBed = BedState(plant: .tomate, stage: 3, needsWater: false, growingSince: now)
        w.pondReached = true
        w.residents = [.vogel, .hase, .schnecke, .ente, .frosch, .fisch, .igel, .eichhoernchen, .reh, .eule]
        w.built += [BuiltObject(kind: .bruecke, area: .bach, x: 0.16, y: 0.7, roof: .braun, body: .natur),
                    BuiltObject(kind: .igelhaus, area: .lichtung, x: 0.7, y: 0.66, roof: .orange, body: .natur),
                    BuiltObject(kind: .tunnel, area: .lichtung, x: 0.4, y: 0.92, roof: .gruen, body: .natur),
                    BuiltObject(kind: .futterstelle, area: .haus, x: 0.62, y: 0.44, roof: .rot, body: .gelb),
                    BuiltObject(kind: .wimpelkette, area: .baumhaus, x: 0.34, y: 0.92, roof: .rosa, body: .tuerkis)]
        w.treehouseStage = 4
        w.treeHousePicnic = PicnicState(area: .baumhaus, blanket: 1, dishes: [.kuchen], plates: 3)
        w.chimes = [.glockenblume, .kristall, .muschelhorn, .pilztrommel]
        w.chimeKinds = ChimeKind.allCases
        w.fantasy = [FantasyFlower(slot: 0, shape: .stern, color: .lila, stem: .spirale, reaction: .lichtpunkte),
                     FantasyFlower(slot: 1, shape: .herz, color: .rosa, stem: .geschwungen, reaction: .klingeln)]
        w.finds = ["feder": 1, "muschel": 2, "eichel": 1]
        w.adventuresDone += ["boot", "frosch", "bruecke", "nachbar", "eichhoernchen", "reh", "baumhausbau", "eule", "baumhauspicknick", "lichter", "schnecke"]
        w.memories += [WorldMemory(kind: .ort, detail: "lichtung"), WorldMemory(kind: .bewohner, detail: "igel"),
                       WorldMemory(kind: .baumhaus, detail: "4"), WorldMemory(kind: .melodie, extra: ["glockenblume", "kristall", "muschelhorn"])]
        return w
    }

    static var startScreen: Screen {
        switch value("-screen") ?? "hub" {
        case "setup": return .setup
        case "tutorial": return .tutorial
        case "game": return .game(GameID(rawValue: value("-game") ?? "") ?? .tracing)
        case "garden": return .garden
        case "gallery": return .gallery
        case "parents": return .parents
        default: return .hub
        }
    }

    /// Dreht das Fenster ins Querformat (Standardnutzung auf dem iPad).
    @MainActor
    static func applyOrientation() {
        guard isActive, !flag("-portrait") else { return }
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { _ in }
    }
}
