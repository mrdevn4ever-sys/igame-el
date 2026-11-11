import Foundation
import CoreGraphics

/// Selbsttest der Spiellogik für den Simulator-Lauf («-selbsttest»). Schlägt eine Prüfung fehl,
/// bricht die App ab und der Lauf erscheint im CI-Bericht als ABSTURZ.
@MainActor
enum SelfTest {
    static func run(_ model: GardenWorldModel) {
        guard DemoMode.flag("-selbsttest") else { return }
        learningGrowth()
        timedGrowth(model)
        waterFlow(model)
        rewards()
        saveRoundTrip()
        layout()
        model.say("Selbsttest bestanden.")
    }

    private static func check(_ ok: Bool, _ what: String) {
        precondition(ok, "Selbsttest fehlgeschlagen: \(what)")
    }

    /// Jede Lernrunde bringt alle Pflanzen eine Stufe weiter.
    private static func learningGrowth() {
        var w = WorldData()
        w.beds[0] = BedState(plant: .erdbeere, stage: 0, needsWater: true)
        check(w.hasGrowingPlants, "gesäte Pflanze zählt als wachsend")
        w.growByLearning()
        check(w.beds[0].stage == 1 && !w.beds[0].needsWater && w.beds[0].growingSince != nil, "Lernrunde: eine Stufe und gegossen")
        w.growByLearning()
        w.growByLearning()
        w.growByLearning()
        check(w.beds[0].isRipe && w.beds[0].remaining == PlantKind.erdbeere.yield && w.beds[0].growingSince == nil, "vier Lernrunden bis reif")
        check(!w.hasGrowingPlants, "reife Pflanze wächst nicht weiter")
        let before = w
        w.growByLearning()
        check(w == before, "reife Pflanze bleibt unverändert")
    }

    /// Wachstum über die Zeit: hält bei Stufe 2 an (Durst), nach dem Giessen bis reif.
    private static func timedGrowth(_ model: GardenWorldModel) {
        let i = 6
        let saved = model.w.beds[i]
        let longAgo = Date().addingTimeInterval(-model.stageSeconds * 10)
        model.edit { d in d.beds[i] = BedState(plant: .karotte, stage: 0, needsWater: false, growingSince: longAgo) }
        model.tick()
        let thirsty = model.w.beds[i]
        check(thirsty.stage == GardenWorldModel.thirstStage && thirsty.needsWater && thirsty.growingSince == nil,
              "Wachstum hält bei Stufe 2 an und hat Durst")
        model.edit { d in
            d.beds[i].needsWater = false
            d.beds[i].growingSince = longAgo
        }
        model.tick()
        let ripe = model.w.beds[i]
        check(ripe.isRipe && ripe.remaining == PlantKind.karotte.yield, "nach dem Nachgiessen bis reif")
        model.edit { d in d.beds[i] = saved }
    }

    /// Wasserweg von der Quelle bis zum Teich; eine fehlende Rinne wird als Lücke gefunden.
    private static func waterFlow(_ model: GardenWorldModel) {
        let saved = model.w.tiles
        var path = [WaterTile(col: 0, row: 0, piece: .kurve, rotation: 2),
                    WaterTile(col: 0, row: 1, piece: .gerade, rotation: 1),
                    WaterTile(col: 0, row: 2, piece: .gerade, rotation: 1),
                    WaterTile(col: 0, row: 3, piece: .kurve, rotation: 0)]
        for c in 1..<WorldLayout.gridCols { path.append(WaterTile(col: c, row: 3, piece: .gerade)) }
        model.edit { d in d.tiles = path }
        check(model.computeFlow().pond, "Wasserweg von der Quelle bis zum Teich")
        model.edit { d in d.tiles.removeAll { $0.col == 2 && $0.row == 3 } }
        let broken = model.computeFlow()
        check(!broken.pond && broken.gap?.col == 2 && broken.gap?.row == 3, "Lücke im Wasserweg wird gefunden")
        model.edit { d in d.tiles = saved }
        model.refreshWater()
    }

    private static func rewards() {
        let options = WorldReward.options(roundID: "selbsttest", data: AppData())
        check(options.count == 3 && Set(options).count == 3, "drei verschiedene Geschenke")
    }

    private static func saveRoundTrip() {
        var d = AppData()
        d.world.houseVisited = true
        d.world.beds[1] = BedState(plant: .tulpe, stage: 3, needsWater: false)
        let raw = try? Persistence.encoder.encode(d)
        let back = raw.flatMap { try? Persistence.decoder.decode(AppData.self, from: $0) }
        check(back?.world.houseVisited == true && back?.world.beds[1].plant == .tulpe, "Spielstand übersteht Speichern und Laden")
        check("Zähle die Punkte.".voiceSlug == "zaehle_die_punkte", "Dateiname einer Sprachaufnahme")
    }

    private static func layout() {
        check(WorldLayout.beds.count == 7 && WorldPanorama.bedCount <= WorldLayout.beds.count, "Beetplätze")
        for a in WorldArea.allCases where a != .wunder {
            check(!WorldLayout.spots(a).isEmpty, "Stellplätze in \(a.rawValue)")
        }
        let cells = (0..<(HouseLayout.shelfColumns * HouseLayout.shelfRows)).map { HouseLayout.shelfCell($0) }
        check(cells.allSatisfy { HouseLayout.shelf.contains($0) }, "Regalfächer liegen im Regal")
        check(GameID.available.count <= cells.count, "alle Spiele haben ein Regalfach")
    }
}
