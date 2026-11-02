import Foundation

/// Ein Schritt eines kleinen Abenteuers. Er erscheint als leuchtende Stelle in der Szene.
struct AdventureStep {
    enum Kind: Equatable {
        /// Stelle antippen
        case tap
        /// Mehrmals antippen und dabei zählen
        case count(Int)
        /// Etwas in der Werkstatt bauen (wird an dieser Stelle aufgestellt)
        case build(BuildKind)
        /// Ein Gericht aus der Küche mitbringen (nil = irgendein Essen)
        case dish(DishKind?)
        /// Ein Erntestück aus dem Korb geben
        case item(HarvestItem)
        /// Ein Boot bis in den Teich fahren lassen
        case boatToPond
        /// Auf Abendstimmung wechseln
        case evening
    }

    var area: WorldArea
    var x: Double
    var y: Double
    var kind: Kind = .tap
    /// Bild und Ersatz-Emoji der Stelle
    var asset: String
    var emoji: String
    var say: String
    var onComplete: ((inout WorldData) -> Void)?
}

struct Adventure: Identifiable {
    var id: String
    var title: String
    var available: (WorldData) -> Bool
    var steps: [AdventureStep]
    var finishText: String
    var finish: (inout WorldData) -> Void
}

enum AdventureCatalog {
    static func memory(_ kind: MemoryKind, _ detail: String, _ extra: [String] = []) -> WorldMemory {
        WorldMemory(kind: kind, detail: detail, extra: extra)
    }

    static let all: [Adventure] = [
        Adventure(
            id: "schmetterling", title: "Der Schmetterling",
            available: { w in
                !w.isUnlocked(.bach) && w.beds.contains { ($0.plant?.isFlower ?? false) && $0.stage >= 3 }
            },
            steps: [
                AdventureStep(area: .haus, x: 0.42, y: 0.42, asset: "gw_tier_schmetterling_sitzen", emoji: "🦋",
                              say: "Ein Schmetterling sitzt auf deiner Blume. Tippe ihn an."),
                AdventureStep(area: .haus, x: 0.94, y: 0.58, asset: "gw_busch_2", emoji: "🌳",
                              say: "Er fliegt zum Busch. Was ist dahinter?")
            ],
            finishText: "Hinter dem Busch ist ein Weg! Er führt zum Bach.",
            finish: { w in
                if !w.unlocked.contains(.bach) { w.unlocked.append(.bach) }
                if !w.visitors.contains(.schmetterling) { w.visitors.append(.schmetterling) }
                w.memories.append(AdventureCatalog.memory(.ort, WorldArea.bach.rawValue))
            }
        ),
        Adventure(
            id: "vogelhaus", title: "Ein Zuhause für den Vogel",
            available: { w in w.workshopOpen && !w.has(.vogel) },
            steps: [
                AdventureStep(area: .haus, x: 0.47, y: 0.44, kind: .build(.vogelhaus), asset: "gw_bau_vogelhaus_fertig", emoji: "🏠",
                              say: "Hier wäre ein schöner Platz für ein Vogelhaus. Bau es in der Werkstatt."),
                AdventureStep(area: .haus, x: 0.47, y: 0.3, asset: "gw_tier_vogel_fliegen_1", emoji: "🐦",
                              say: "Schau, da kommt jemand angeflogen! Tippe ihn an.")
            ],
            finishText: "Ein Rotkehlchen wohnt jetzt in deinem Vogelhaus. Es hat dir eine Feder mitgebracht.",
            finish: { w in
                if !w.residents.contains(.vogel) { w.residents.append(.vogel) }
                w.finds[FindItem.feder.rawValue, default: 0] += 1
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.vogel.rawValue))
            }
        ),
        Adventure(
            id: "hase", title: "Der hungrige Hase",
            available: { w in w.harvestedOnce.contains(HarvestItem.karotte.rawValue) && !w.has(.hase) },
            steps: [
                AdventureStep(area: .haus, x: 0.08, y: 0.5, asset: "gw_busch_2", emoji: "🌿",
                              say: "Da raschelt etwas im Busch. Tippe auf den Busch."),
                AdventureStep(area: .haus, x: 0.18, y: 0.66, kind: .item(.karotte), asset: "gw_tier_hase_verstecken", emoji: "🐇",
                              say: "Ein Hase! Er schnuppert. Hast du eine Karotte für ihn?")
            ],
            finishText: "Der Hase knabbert die Karotte. Jetzt besucht er deinen Garten.",
            finish: { w in
                if !w.residents.contains(.hase) { w.residents.append(.hase) }
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.hase.rawValue))
            }
        ),
        Adventure(
            id: "schnecke", title: "Ganz langsam",
            available: { w in w.harvestedOnce.contains(HarvestItem.salat.rawValue) && !w.has(.schnecke) },
            steps: [
                AdventureStep(area: .haus, x: 0.36, y: 0.92, asset: "gw_tier_schnecke_kriechen_1", emoji: "🐌",
                              say: "Wer kriecht denn da so langsam? Tippe ihn an.")
            ],
            finishText: "Eine Schnecke! Sie trägt ihr Haus auf dem Rücken.",
            finish: { w in
                if !w.residents.contains(.schnecke) { w.residents.append(.schnecke) }
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.schnecke.rawValue))
            }
        ),
        Adventure(
            id: "boot", title: "Das Blattboot",
            available: { w in w.isUnlocked(.bach) && !w.pondReached },
            steps: [
                AdventureStep(area: .bach, x: 0.13, y: 0.3, asset: "gw_boot_blatt", emoji: "🍃",
                              say: "An der Quelle wartet ein Blattboot. Tippe es an."),
                AdventureStep(area: .bach, x: 0.86, y: 0.86, kind: .boatToPond, asset: "gw_ziel_teich", emoji: "🏝️",
                              say: "Bau einen Wasserweg von der Quelle bis zum Teich. Dann lass das Boot fahren.")
            ],
            finishText: "Das Boot ist im Teich angekommen! An der Anlegestelle liegt eine Muschel.",
            finish: { w in
                w.finds[FindItem.muschel.rawValue, default: 0] += 1
                w.memories.append(AdventureCatalog.memory(.boot, BoatKind.blatt.rawValue))
            }
        ),
        Adventure(
            id: "frosch", title: "Auf dem Seerosenblatt",
            available: { w in w.pondReached && !w.has(.frosch) },
            steps: [
                AdventureStep(area: .bach, x: 0.78, y: 0.74, asset: "gw_seerose", emoji: "🪷",
                              say: "Auf dem Seerosenblatt sitzt jemand. Tippe ihn an.")
            ],
            finishText: "Ein Frosch! Er wohnt jetzt am Teich.",
            finish: { w in
                if !w.residents.contains(.frosch) { w.residents.append(.frosch) }
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.frosch.rawValue))
            }
        ),
        Adventure(
            id: "bruecke", title: "Die Brücke",
            available: { w in w.isUnlocked(.bach) && !w.isUnlocked(.lichtung) },
            steps: [
                AdventureStep(area: .bach, x: 0.5, y: 0.17, asset: "gw_szene_hausgarten_gesperrt_weg", emoji: "🪵",
                              say: "Hier fehlt eine Brücke. Tippe darauf.",
                              onComplete: { w in if !w.kits.contains(.bruecke) { w.kits.append(.bruecke) } }),
                AdventureStep(area: .bach, x: 0.5, y: 0.17, kind: .build(.bruecke), asset: "gw_bau_bruecke_fertig", emoji: "🌉",
                              say: "In der Werkstatt liegen die Teile für eine Brücke. Bau sie zusammen."),
                AdventureStep(area: .bach, x: 0.5, y: 0.1, asset: "gw_dino_zeigen", emoji: "🦕",
                              say: "Die Brücke ist fertig! Printatops geht als Erster hinüber. Komm mit!")
            ],
            finishText: "Auf der anderen Seite liegt die Tierlichtung!",
            finish: { w in
                if !w.unlocked.contains(.lichtung) { w.unlocked.append(.lichtung) }
                w.memories.append(AdventureCatalog.memory(.ort, WorldArea.lichtung.rawValue))
            }
        ),
        Adventure(
            id: "nachbar", title: "Der neue Nachbar",
            available: { w in w.isUnlocked(.lichtung) && !w.has(.igel) },
            steps: [
                AdventureStep(area: .lichtung, x: 0.22, y: 0.88, asset: "gw_spur_igel", emoji: "🐾",
                              say: "Hier sind kleine Spuren. Tippe darauf."),
                AdventureStep(area: .lichtung, x: 0.38, y: 0.78, asset: "gw_spur_igel", emoji: "🐾",
                              say: "Noch mehr Spuren. Wohin führen sie?"),
                AdventureStep(area: .lichtung, x: 0.54, y: 0.7, asset: "gw_spur_igel", emoji: "🐾",
                              say: "Die Spuren führen in diese Ecke."),
                AdventureStep(area: .lichtung, x: 0.7, y: 0.64, asset: "gw_busch_2", emoji: "🌿",
                              say: "Hier sucht jemand ein Zuhause. Tippe auf den Busch.",
                              onComplete: { w in if !w.kits.contains(.igelhaus) { w.kits.append(.igelhaus) } }),
                AdventureStep(area: .lichtung, x: 0.7, y: 0.66, kind: .build(.igelhaus), asset: "gw_bau_igelhaus_fertig", emoji: "🛖",
                              say: "Bau in der Werkstatt ein Igelhaus. Es kommt genau hierher."),
                AdventureStep(area: .lichtung, x: 0.7, y: 0.6, kind: .count(3), asset: "gw_bau_igelhaus_laub", emoji: "🍂",
                              say: "Lege drei Blätter zum Igelhaus. Tippe dreimal.")
            ],
            finishText: "Ein Igel schaut aus dem Haus. Er wohnt jetzt auf der Lichtung!",
            finish: { w in
                if !w.residents.contains(.igel) { w.residents.append(.igel) }
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.igel.rawValue))
            }
        ),
        Adventure(
            id: "eichhoernchen", title: "Das Eichhörnchen",
            available: { w in w.isUnlocked(.lichtung) && !w.isUnlocked(.baumhaus) },
            steps: [
                AdventureStep(area: .lichtung, x: 0.14, y: 0.52, asset: "gw_tier_eichhoernchen_sitzen", emoji: "🐿️",
                              say: "Im hohlen Baumstamm sitzt jemand. Tippe ihn an."),
                AdventureStep(area: .lichtung, x: 0.46, y: 0.36, asset: "gw_tier_eichhoernchen_springen", emoji: "🐿️",
                              say: "Das Eichhörnchen hüpft weiter. Folge ihm!"),
                AdventureStep(area: .lichtung, x: 0.84, y: 0.3, asset: "gw_tier_eichhoernchen_tragen", emoji: "🐿️",
                              say: "Es zeigt dir etwas hinter den Bäumen.")
            ],
            finishText: "Dort steht ein riesiger Baum. Da kann man ein Baumhaus bauen! Das Eichhörnchen schenkt dir eine Eichel.",
            finish: { w in
                if !w.residents.contains(.eichhoernchen) { w.residents.append(.eichhoernchen) }
                if !w.unlocked.contains(.baumhaus) { w.unlocked.append(.baumhaus) }
                w.finds[FindItem.eichel.rawValue, default: 0] += 1
                w.memories.append(AdventureCatalog.memory(.ort, WorldArea.baumhaus.rawValue))
            }
        ),
        Adventure(
            id: "reh", title: "Am Waldrand",
            available: { w in w.isBuilt(.tunnel) && !w.has(.reh) },
            steps: [
                AdventureStep(area: .lichtung, x: 0.86, y: 0.42, asset: "gw_tier_reh_stehen", emoji: "🦌",
                              say: "Am Waldrand steht jemand ganz still. Tippe vorsichtig.")
            ],
            finishText: "Ein Reh! Es kommt jetzt öfter auf die Lichtung.",
            finish: { w in
                if !w.residents.contains(.reh) { w.residents.append(.reh) }
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.reh.rawValue))
            }
        ),
        Adventure(
            id: "baumhausbau", title: "Das Baumhaus",
            available: { w in w.isUnlocked(.baumhaus) && w.treehouseStage < 4 },
            steps: [
                AdventureStep(area: .baumhaus, x: 0.22, y: 0.86, asset: "gw_bau_bruecke_bretter", emoji: "🪵",
                              say: "Hier liegen Bretter. Tippe darauf, dann bauen wir den Boden.",
                              onComplete: { w in w.treehouseStage = max(w.treehouseStage, 1) }),
                AdventureStep(area: .baumhaus, x: 0.42, y: 0.9, asset: "gw_bau_igelhaus_waende", emoji: "🧱",
                              say: "Jetzt kommen die Wände.",
                              onComplete: { w in w.treehouseStage = max(w.treehouseStage, 2) }),
                AdventureStep(area: .baumhaus, x: 0.62, y: 0.9, asset: "gw_bau_vogelhaus_dach", emoji: "🔺",
                              say: "Fehlt noch das Dach.",
                              onComplete: { w in w.treehouseStage = max(w.treehouseStage, 3) }),
                AdventureStep(area: .baumhaus, x: 0.82, y: 0.84, asset: "gw_wimpelkette", emoji: "🎏",
                              say: "Zum Schluss Fenster und Wimpel!",
                              onComplete: { w in w.treehouseStage = 4 })
            ],
            finishText: "Das Baumhaus ist fertig!",
            finish: { w in w.memories.append(AdventureCatalog.memory(.baumhaus, "4")) }
        ),
        Adventure(
            id: "eule", title: "Wer ist wach?",
            available: { w in w.treehouseStage >= 2 && !w.has(.eule) },
            steps: [
                AdventureStep(area: .baumhaus, x: 0.5, y: 0.2, kind: .evening, asset: "gw_ui_mond", emoji: "🌙",
                              say: "Am Abend wird im Baum jemand wach. Tippe oben auf den Mond."),
                AdventureStep(area: .baumhaus, x: 0.76, y: 0.3, asset: "gw_tier_eule_sitzen", emoji: "🦉",
                              say: "Zwei grosse Augen schauen dich an. Tippe darauf.")
            ],
            finishText: "Eine Eule! Sie wohnt jetzt im Baum beim Baumhaus.",
            finish: { w in
                if !w.residents.contains(.eule) { w.residents.append(.eule) }
                w.memories.append(AdventureCatalog.memory(.bewohner, Resident.eule.rawValue))
            }
        ),
        Adventure(
            id: "baumhauspicknick", title: "Picknick im Baumhaus",
            available: { w in w.treehouseStage >= 4 && w.treeHousePicnic == nil },
            steps: [
                AdventureStep(area: .baumhaus, x: 0.32, y: 0.82, kind: .dish(nil), asset: "gw_dino_nachdenken", emoji: "🦕",
                              say: "Printatops möchte ein Picknick oben im Baumhaus. Mach in der Küche etwas Feines und bring es her."),
                AdventureStep(area: .baumhaus, x: 0.62, y: 0.68, kind: .count(3), asset: "gw_korbaufzug_korb", emoji: "🧺",
                              say: "Zieh den Korb nach oben. Tippe dreimal auf das Seil."),
                AdventureStep(area: .baumhaus, x: 0.55, y: 0.36, asset: "gw_picknickdecke_rot", emoji: "🧺",
                              say: "Oben angekommen! Tippe, um den Tisch zu decken.")
            ],
            finishText: "Picknick im Baumhaus! Printatops winkt dir von oben.",
            finish: { w in
                if let dish = DishKind.allCases.first(where: { $0.isFood && (w.pantry[$0.rawValue] ?? 0) > 0 }) {
                    w.pantry[dish.rawValue, default: 1] -= 1
                    w.treeHousePicnic = PicnicState(area: .baumhaus, blanket: 0, dishes: [dish], plates: 2)
                    w.memories.append(AdventureCatalog.memory(.picknick, WorldArea.baumhaus.rawValue, [dish.rawValue]))
                } else {
                    w.treeHousePicnic = PicnicState(area: .baumhaus, blanket: 0, dishes: [], plates: 2)
                }
            }
        ),
        Adventure(
            id: "lichter", title: "Die leuchtende Spur",
            available: { w in w.isUnlocked(.baumhaus) && !w.isUnlocked(.wunder) },
            steps: [
                AdventureStep(area: .baumhaus, x: 0.5, y: 0.22, kind: .evening, asset: "gw_ui_mond", emoji: "🌙",
                              say: "Am Abend leuchten im Garten kleine Lichter. Tippe oben auf den Mond."),
                AdventureStep(area: .haus, x: 0.3, y: 0.36, asset: "gw_lichtpunkt", emoji: "✨",
                              say: "Ein Licht im Hausgarten! Tippe darauf."),
                AdventureStep(area: .bach, x: 0.6, y: 0.38, asset: "gw_lichtpunkt", emoji: "✨",
                              say: "Das nächste Licht leuchtet am Bach."),
                AdventureStep(area: .lichtung, x: 0.5, y: 0.44, asset: "gw_lichtpunkt", emoji: "✨",
                              say: "Noch ein Licht auf der Tierlichtung."),
                AdventureStep(area: .baumhaus, x: 0.5, y: 0.55, asset: "gw_lichtpunkt", emoji: "✨",
                              say: "Das letzte Licht ist beim Baumhaus.")
            ],
            finishText: "Die Lichter zeigen einen geheimen Weg zur Wunderlichtung!",
            finish: { w in
                if !w.unlocked.contains(.wunder) { w.unlocked.append(.wunder) }
                if !w.chimeKinds.contains(.muschelhorn) { w.chimeKinds.append(.muschelhorn) }
                w.memories.append(AdventureCatalog.memory(.ort, WorldArea.wunder.rawValue))
            }
        ),
        Adventure(
            id: "fest", title: "Das Gartenfest",
            available: { w in w.isUnlocked(.wunder) && !w.festDone },
            steps: [
                AdventureStep(area: .haus, x: 0.72, y: 0.5, kind: .dish(nil), asset: "gw_kueche_kuchen_fertig", emoji: "🥧",
                              say: "Wir feiern ein Gartenfest! Bereite in der Küche etwas Feines zu und bring es her."),
                AdventureStep(area: .haus, x: 0.64, y: 0.46, kind: .dish(.blumenstrauss), asset: "gw_kueche_vase_strauss", emoji: "💐",
                              say: "Für den Festtisch brauchen wir einen Blumenstrauss aus der Küche."),
                AdventureStep(area: .haus, x: 0.72, y: 0.34, kind: .build(.wimpelkette), asset: "gw_wimpelkette", emoji: "🎏",
                              say: "Jetzt fehlt noch eine Wimpelkette. Bau sie in der Werkstatt."),
                AdventureStep(area: .haus, x: 0.8, y: 0.56, asset: "gw_fest_girlande", emoji: "🎉",
                              say: "Alles ist bereit. Tippe hier, dann beginnt das Fest!")
            ],
            finishText: "Das Gartenfest beginnt! Alle deine Freunde sind gekommen.",
            finish: { w in
                w.festDone = true
                w.memories.append(AdventureCatalog.memory(.fest, "", w.residents.map(\.rawValue)))
            }
        )
    ]

    static func adventure(_ id: String) -> Adventure? { all.first { $0.id == id } }
}
