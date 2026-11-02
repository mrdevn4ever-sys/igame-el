import SwiftUI

// MARK: - Orte

enum WorldArea: String, Codable, CaseIterable, Identifiable {
    case haus, bach, lichtung, baumhaus, wunder

    var id: String { rawValue }

    var title: String {
        switch self {
        case .haus: return "Hausgarten"
        case .bach: return "Bach und Teich"
        case .lichtung: return "Tierlichtung"
        case .baumhaus: return "Baumhaus"
        case .wunder: return "Wunderlichtung"
        }
    }

    var emoji: String {
        switch self {
        case .haus: return "🏡"
        case .bach: return "🌊"
        case .lichtung: return "🦔"
        case .baumhaus: return "🌳"
        case .wunder: return "✨"
        }
    }

    /// Hintergrundbild (Tag/Abend).
    func scene(evening: Bool) -> String {
        let base: String
        switch self {
        case .haus: base = "gw_szene_hausgarten"
        case .bach: base = "gw_szene_bach_teich"
        case .lichtung: base = "gw_szene_tierlichtung"
        case .baumhaus: base = "gw_szene_baumhaus"
        case .wunder: base = "gw_szene_wunderlichtung"
        }
        if self == .haus { return base + (evening ? "_abend" : "_tag") }
        return evening ? base + "_abend" : base
    }

    /// Breites Panoramabild (mehrere Bildschirme), falls vorhanden.
    func panorama(evening: Bool) -> String {
        switch self {
        case .haus: return evening ? "gw_szene_hausgarten_panorama_abend" : "gw_szene_hausgarten_panorama_tag"
        case .bach: return evening ? "gw_szene_bach_teich_panorama_abend" : "gw_szene_bach_teich_panorama"
        case .lichtung: return evening ? "gw_szene_tierlichtung_panorama_abend" : "gw_szene_tierlichtung_panorama"
        default: return ""
        }
    }

    /// Ausdehnung im Panorama (Grundbild = 0…1): Hausgarten links und rechts je ein Bildschirm, Bach und Lichtung rechts einer.
    var panoramaExtent: (Double, Double) {
        switch self {
        case .haus: return (-1, 2)
        case .bach, .lichtung: return (0, 2)
        default: return (0, 1)
        }
    }

    /// Ersatzfarben, solange die Szenenbilder fehlen.
    var fallbackColors: [Color] {
        switch self {
        case .haus: return [Theme.sky, Theme.meadow, Theme.softGreen]
        case .bach: return [Theme.sky, Theme.lightBlue, Theme.softGreen]
        case .lichtung: return [Color(red: 0.85, green: 0.93, blue: 0.85), Color(red: 0.62, green: 0.80, blue: 0.55)]
        case .baumhaus: return [Theme.sky, Color(red: 0.75, green: 0.88, blue: 0.65)]
        case .wunder: return [Color(red: 0.80, green: 0.75, blue: 0.97), Color(red: 0.60, green: 0.88, blue: 0.86)]
        }
    }

    /// Position auf der Inselkarte (0…1).
    var mapPoint: CGPoint {
        switch self {
        case .haus: return CGPoint(x: 0.5, y: 0.62)
        case .bach: return CGPoint(x: 0.8, y: 0.6)
        case .lichtung: return CGPoint(x: 0.2, y: 0.3)
        case .baumhaus: return CGPoint(x: 0.78, y: 0.24)
        case .wunder: return CGPoint(x: 0.5, y: 0.14)
        }
    }
}

// MARK: - Pflanzen

enum HarvestStyle {
    /// Einzelne Früchte/Blüten antippen
    case pick
    /// Am Grün ziehen (Antippen geht auch)
    case pull
    /// Grosses, schweres Erntegut
    case heavy
    /// Ast schütteln, Früchte fallen herunter
    case shake
    /// Kerne aus dem Blütenkopf lösen
    case seeds
}

enum PlantKind: String, Codable, CaseIterable, Identifiable {
    case erdbeere, karotte, sonnenblume, apfelbaum, erbse, kuerbis, tomate, salat, radieschen, heidelbeere, tulpe, rose, lavendel, mohn

    var id: String { rawValue }

    var name: String {
        switch self {
        case .erdbeere: return "Erdbeeren"
        case .karotte: return "Karotten"
        case .sonnenblume: return "Sonnenblume"
        case .apfelbaum: return "Apfelbaum"
        case .erbse: return "Erbsen"
        case .kuerbis: return "Kürbis"
        case .tomate: return "Tomaten"
        case .salat: return "Salat"
        case .radieschen: return "Radieschen"
        case .heidelbeere: return "Heidelbeeren"
        case .tulpe: return "Tulpe"
        case .rose: return "Rose"
        case .lavendel: return "Lavendel"
        case .mohn: return "Mohnblume"
        }
    }

    var emoji: String {
        switch self {
        case .erdbeere: return "🍓"
        case .karotte: return "🥕"
        case .sonnenblume: return "🌻"
        case .apfelbaum: return "🍎"
        case .erbse: return "🫛"
        case .kuerbis: return "🎃"
        case .tomate: return "🍅"
        case .salat: return "🥬"
        case .radieschen: return "🌱"
        case .heidelbeere: return "🫐"
        case .tulpe: return "🌷"
        case .rose: return "🌹"
        case .lavendel: return "🪻"
        case .mohn: return "🌺"
        }
    }

    /// Satz, wenn die Pflanze reif ist oder blüht.
    var ripeText: String {
        switch self {
        case .erdbeere: return "Die Erdbeeren sind reif. Jetzt kannst du ernten!"
        case .karotte: return "Die Karotten sind gross. Zieh sie aus der Erde!"
        case .sonnenblume: return "Deine Sonnenblume ist voller Kerne!"
        case .apfelbaum: return "Am Apfelbaum hängen reife Äpfel!"
        case .erbse: return "Die Erbsenschoten sind dick und rund. Jetzt kannst du ernten!"
        case .kuerbis: return "Der Kürbis ist gross und orange. Jetzt kannst du ihn ernten!"
        case .tomate: return "Die Tomaten sind rot und reif!"
        case .salat: return "Der Salat ist gross und knackig!"
        case .radieschen: return "Die Radieschen sind reif. Zieh sie aus der Erde!"
        case .heidelbeere: return "Die Heidelbeeren sind blau und reif!"
        case .tulpe: return "Deine Tulpe blüht! Schau, wie schön."
        case .rose: return "Deine Rosen blühen! Schau, wie schön."
        case .lavendel: return "Dein Lavendel blüht und duftet!"
        case .mohn: return "Deine Mohnblume blüht! Schau, wie schön."
        }
    }

    var isTree: Bool { self == .apfelbaum }
    var isFlower: Bool { [.sonnenblume, .tulpe, .rose, .lavendel, .mohn].contains(self) }

    /// Mehrjährig: nach der Ernte wächst die Pflanze wieder nach.
    var regrows: Bool { [.erdbeere, .apfelbaum, .tomate, .heidelbeere, .rose, .lavendel].contains(self) }

    var style: HarvestStyle {
        switch self {
        case .karotte, .radieschen: return .pull
        case .kuerbis, .salat: return .heavy
        case .apfelbaum: return .shake
        case .sonnenblume: return .seeds
        default: return .pick
        }
    }

    /// Anzahl Erntestücke einer reifen Pflanze.
    var yield: Int {
        switch self {
        case .erdbeere, .erbse: return 5
        case .apfelbaum: return 7
        case .tomate: return 6
        case .rose: return 4
        case .sonnenblume: return 5
        case .heidelbeere: return 3
        default: return 1
        }
    }

    var harvest: HarvestItem {
        switch self {
        case .erdbeere: return .erdbeere
        case .karotte: return .karotte
        case .sonnenblume: return .kerne
        case .apfelbaum: return .apfel
        case .erbse: return .erbsenschote
        case .kuerbis: return .kuerbis
        case .tomate: return .tomate
        case .salat: return .salat
        case .radieschen: return .radieschen
        case .heidelbeere: return .heidelbeeren
        case .tulpe: return .tulpe
        case .rose: return .rose
        case .lavendel: return .lavendel
        case .mohn: return .mohn
        }
    }

    func asset(stage: Int) -> String {
        let labels = ["keimling", "jungpflanze", "bluete", "reif"]
        let s = min(max(stage, 1), 4)
        return "gw_pflanze_\(rawValue)_\(s)_\(labels[s - 1])"
    }

    var seedAsset: String { "gw_saat_\(rawValue)" }

    /// Ersatz-Emoji pro Stufe (solange Bilder fehlen).
    func emoji(stage: Int) -> String {
        switch stage {
        case ...1: return "🌱"
        case 2: return isTree ? "🌳" : "🌿"
        case 3: return isFlower ? emoji : (isTree ? "🌸" : "🌿")
        default: return isTree ? "🌳" : emoji
        }
    }

    static let starter: [PlantKind] = [.erdbeere, .karotte, .sonnenblume]
}

enum HarvestItem: String, Codable, CaseIterable, Identifiable {
    case erdbeere, karotte, kerne, apfel, erbsenschote, kuerbis, tomate, salat, radieschen, heidelbeeren
    case tulpe, rose, lavendel, mohn, blatt

    var id: String { rawValue }

    var name: String {
        switch self {
        case .erdbeere: return "Erdbeere"
        case .karotte: return "Karotte"
        case .kerne: return "Sonnenblumenkerne"
        case .apfel: return "Apfel"
        case .erbsenschote: return "Erbsenschote"
        case .kuerbis: return "Kürbis"
        case .tomate: return "Tomate"
        case .salat: return "Salat"
        case .radieschen: return "Radieschen"
        case .heidelbeeren: return "Heidelbeeren"
        case .tulpe: return "Tulpe"
        case .rose: return "Rose"
        case .lavendel: return "Lavendel"
        case .mohn: return "Mohnblume"
        case .blatt: return "Blatt"
        }
    }

    var emoji: String {
        switch self {
        case .erdbeere: return "🍓"
        case .karotte: return "🥕"
        case .kerne: return "🌻"
        case .apfel: return "🍎"
        case .erbsenschote: return "🫛"
        case .kuerbis: return "🎃"
        case .tomate: return "🍅"
        case .salat: return "🥬"
        case .radieschen: return "🌱"
        case .heidelbeeren: return "🫐"
        case .tulpe: return "🌷"
        case .rose: return "🌹"
        case .lavendel: return "🪻"
        case .mohn: return "🌺"
        case .blatt: return "🍂"
        }
    }

    var asset: String {
        switch self {
        case .kerne: return "gw_ernte_sonnenblumenkerne"
        case .erbsenschote: return "gw_ernte_erbsenschote_zu"
        case .blatt: return "gw_fund_blatt_gold"
        default: return "gw_ernte_\(rawValue)"
        }
    }

    /// Satz bei der allerersten Ernte.
    var firstText: String {
        switch self {
        case .erdbeere: return "Deine erste Erdbeere! Sie kommt in den Korb."
        case .karotte: return "Deine erste Karotte! Sie kommt in den Korb."
        case .kerne: return "Deine ersten Sonnenblumenkerne! Sie kommen in den Korb."
        case .apfel: return "Dein erster Apfel! Er kommt in den Korb."
        case .erbsenschote: return "Deine erste Erbsenschote! Sie kommt in den Korb."
        case .kuerbis: return "Dein erster Kürbis! Er kommt in den Korb."
        case .tomate: return "Deine erste Tomate! Sie kommt in den Korb."
        case .salat: return "Dein erster Salat! Er kommt in den Korb."
        case .radieschen: return "Dein erstes Radieschen! Es kommt in den Korb."
        case .heidelbeeren: return "Deine ersten Heidelbeeren! Sie kommen in den Korb."
        case .tulpe: return "Deine erste Tulpe! Sie kommt in den Korb."
        case .rose: return "Deine erste Rose! Sie kommt in den Korb."
        case .lavendel: return "Dein erster Lavendel! Er kommt in den Korb."
        case .mohn: return "Deine erste Mohnblume! Sie kommt in den Korb."
        case .blatt: return "Ein schönes Blatt! Es kommt in den Korb."
        }
    }

    var isFruit: Bool { [.erdbeere, .apfel, .heidelbeeren].contains(self) }
    var isFlower: Bool { [.tulpe, .rose, .lavendel, .mohn].contains(self) }
}

/// Ein Beet (oder der Baumplatz).
struct BedState: Codable, Equatable {
    var plant: PlantKind?
    /// 0 = gesät, 1…4 = Wachstumsstufen (4 = reif)
    var stage: Int = 0
    var needsWater = true
    /// Beginn des laufenden Wachstumsschritts (nach dem Giessen)
    var growingSince: Date?
    /// Noch nicht geerntete Stücke der reifen Pflanze
    var remaining: Int = 0
    /// Bei Bäumen: bereits heruntergefallene Früchte (Positionen 0…1 unter dem Baum)
    var fallen: [Double] = []
    /// Kurz feucht nach dem Giessen (nur Anzeige)
    var wetUntil: Date?

    var isEmpty: Bool { plant == nil }
    var isRipe: Bool { plant != nil && stage >= 4 }
}

// MARK: - Bauen

enum BuildKind: String, Codable, CaseIterable, Identifiable {
    case vogelhaus, igelhaus, bank, futterstelle, insektenhotel, blumentopf, bruecke, tunnel, windspiel, segelboot, wimpelkette, laterne

    var id: String { rawValue }

    var name: String {
        switch self {
        case .vogelhaus: return "Vogelhaus"
        case .igelhaus: return "Igelhaus"
        case .bank: return "Gartenbank"
        case .futterstelle: return "Futterstelle"
        case .insektenhotel: return "Insektenhotel"
        case .blumentopf: return "Blumentopf"
        case .bruecke: return "Brücke"
        case .tunnel: return "Weidentunnel"
        case .windspiel: return "Windspiel"
        case .segelboot: return "Segelboot"
        case .wimpelkette: return "Wimpelkette"
        case .laterne: return "Laterne"
        }
    }

    var emoji: String {
        switch self {
        case .vogelhaus: return "🏠"
        case .igelhaus: return "🛖"
        case .bank: return "🪑"
        case .futterstelle: return "🥣"
        case .insektenhotel: return "🐝"
        case .blumentopf: return "🪴"
        case .bruecke: return "🌉"
        case .tunnel: return "⛺️"
        case .windspiel: return "🎐"
        case .segelboot: return "⛵️"
        case .wimpelkette: return "🎏"
        case .laterne: return "🏮"
        }
    }

    /// «ein Vogelhaus», «eine Gartenbank», «einen Weidentunnel»
    var accusativeName: String {
        switch self {
        case .vogelhaus: return "ein Vogelhaus"
        case .igelhaus: return "ein Igelhaus"
        case .bank: return "eine Gartenbank"
        case .futterstelle: return "eine Futterstelle"
        case .insektenhotel: return "ein Insektenhotel"
        case .blumentopf: return "einen Blumentopf"
        case .bruecke: return "eine Brücke"
        case .tunnel: return "einen Weidentunnel"
        case .windspiel: return "ein Windspiel"
        case .segelboot: return "ein Segelboot"
        case .wimpelkette: return "eine Wimpelkette"
        case .laterne: return "eine Laterne"
        }
    }

    /// «das Vogelhaus», «die Gartenbank», «der Weidentunnel»
    var definiteName: String {
        switch self {
        case .vogelhaus: return "das Vogelhaus"
        case .igelhaus: return "das Igelhaus"
        case .bank: return "die Gartenbank"
        case .futterstelle: return "die Futterstelle"
        case .insektenhotel: return "das Insektenhotel"
        case .blumentopf: return "der Blumentopf"
        case .bruecke: return "die Brücke"
        case .tunnel: return "der Weidentunnel"
        case .windspiel: return "das Windspiel"
        case .segelboot: return "das Segelboot"
        case .wimpelkette: return "die Wimpelkette"
        case .laterne: return "die Laterne"
        }
    }

    /// Bauteile in der Werkstatt (Bildname-Endung und Ersatz-Emoji).
    var parts: [BuildPart] {
        switch self {
        case .vogelhaus: return [BuildPart(key: "boden", emoji: "🟫"), BuildPart(key: "wand_vorne", emoji: "🚪"), BuildPart(key: "wand_hinten", emoji: "🟫"), BuildPart(key: "dach", emoji: "🔺"), BuildPart(key: "pfahl", emoji: "🪵")]
        case .igelhaus: return [BuildPart(key: "boden", emoji: "🟫"), BuildPart(key: "waende", emoji: "🧱"), BuildPart(key: "dach", emoji: "🔺"), BuildPart(key: "laub", emoji: "🍂")]
        case .bank: return [BuildPart(key: "sitz", emoji: "🟫"), BuildPart(key: "lehne", emoji: "🪵"), BuildPart(key: "beine", emoji: "🦵")]
        case .futterstelle: return [BuildPart(key: "schale", emoji: "🥣"), BuildPart(key: "dach", emoji: "🔺"), BuildPart(key: "stange", emoji: "🪵")]
        case .insektenhotel: return [BuildPart(key: "rahmen", emoji: "🔲"), BuildPart(key: "fuellung", emoji: "🎋")]
        case .blumentopf: return [BuildPart(key: "topf", emoji: "🪴"), BuildPart(key: "rand", emoji: "⭕️")]
        case .bruecke: return [BuildPart(key: "pfosten", emoji: "🪵"), BuildPart(key: "bretter", emoji: "🟫"), BuildPart(key: "gelaender", emoji: "🪜")]
        case .tunnel: return [BuildPart(key: "boegen", emoji: "🌿"), BuildPart(key: "blaetter", emoji: "🍃")]
        case .windspiel: return [BuildPart(key: "stab", emoji: "🪵"), BuildPart(key: "glocken", emoji: "🔔")]
        case .segelboot: return [BuildPart(key: "rumpf", emoji: "🛶"), BuildPart(key: "mast", emoji: "🪵"), BuildPart(key: "segel", emoji: "⛵️")]
        case .wimpelkette: return [BuildPart(key: "schnur", emoji: "〰️"), BuildPart(key: "wimpel", emoji: "🚩")]
        case .laterne: return [BuildPart(key: "gestell", emoji: "🔲"), BuildPart(key: "papier", emoji: "🏮")]
        }
    }

    /// Wo es aufgestellt werden kann.
    var areas: [WorldArea] {
        switch self {
        case .vogelhaus, .bank, .futterstelle, .insektenhotel, .blumentopf, .windspiel: return [.haus, .lichtung, .baumhaus]
        case .igelhaus, .tunnel: return [.lichtung]
        case .bruecke: return [.bach]
        case .segelboot: return [.bach]
        case .wimpelkette, .laterne: return [.baumhaus, .haus]
        }
    }

    /// Darf nur einmal gebaut werden.
    var unique: Bool { [.bruecke, .igelhaus, .segelboot].contains(self) }

    var asset: String { "gw_bau_\(rawValue)_fertig" }
    var maskRoof: String { "gw_bau_\(rawValue)_maske_dach" }
    var maskBody: String { "gw_bau_\(rawValue)_maske_korpus" }
    func partAsset(_ key: String) -> String { "gw_bau_\(rawValue)_\(key)" }

    /// Feste Bildnamen, wo die Liste andere Namen nutzt.
    var displayAsset: String {
        switch self {
        case .segelboot: return "gw_boot_segel"
        case .wimpelkette: return "gw_wimpelkette"
        case .laterne: return "gw_laterne_papier"
        default: return asset
        }
    }

    /// Grösse relativ zur Szenenbreite.
    var sceneSize: Double {
        switch self {
        case .bruecke: return 0.26
        case .tunnel: return 0.2
        case .bank: return 0.14
        case .wimpelkette: return 0.24
        case .blumentopf, .laterne: return 0.08
        default: return 0.11
        }
    }
}

struct BuildPart: Hashable {
    var key: String
    var emoji: String
}

struct BuiltObject: Codable, Equatable, Identifiable {
    var id = UUID()
    var kind: BuildKind
    var area: WorldArea
    var x: Double
    var y: Double
    var roof: WorldColor = .rot
    var body: WorldColor = .natur
    var pattern: WorldPattern = .keins
    var decoration: FindItem?
    var created = Date()
}

enum WorldColor: String, Codable, CaseIterable, Identifiable {
    case natur, rot, orange, gelb, gruen, tuerkis, blau, lila, rosa, weiss, braun

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .natur: return Color(red: 0.93, green: 0.82, blue: 0.64)
        case .rot: return Color(red: 0.89, green: 0.30, blue: 0.27)
        case .orange: return Color(red: 0.98, green: 0.60, blue: 0.20)
        case .gelb: return Color(red: 0.99, green: 0.84, blue: 0.22)
        case .gruen: return Color(red: 0.36, green: 0.70, blue: 0.36)
        case .tuerkis: return Color(red: 0.20, green: 0.74, blue: 0.74)
        case .blau: return Color(red: 0.28, green: 0.52, blue: 0.88)
        case .lila: return Color(red: 0.60, green: 0.42, blue: 0.84)
        case .rosa: return Color(red: 0.96, green: 0.58, blue: 0.75)
        case .weiss: return Color(red: 0.98, green: 0.98, blue: 0.96)
        case .braun: return Color(red: 0.60, green: 0.42, blue: 0.27)
        }
    }

    var name: String {
        switch self {
        case .natur: return "Holz"
        case .rot: return "Rot"
        case .orange: return "Orange"
        case .gelb: return "Gelb"
        case .gruen: return "Grün"
        case .tuerkis: return "Türkis"
        case .blau: return "Blau"
        case .lila: return "Lila"
        case .rosa: return "Rosa"
        case .weiss: return "Weiss"
        case .braun: return "Braun"
        }
    }
}

enum WorldPattern: String, Codable, CaseIterable, Identifiable {
    case keins, punkte, streifen, herzen, sterne, blumen

    var id: String { rawValue }
    var asset: String { "gw_muster_overlay_\(rawValue)" }

    var symbol: String {
        switch self {
        case .keins: return "–"
        case .punkte: return "•"
        case .streifen: return "▤"
        case .herzen: return "♥"
        case .sterne: return "★"
        case .blumen: return "✿"
        }
    }

    var name: String {
        switch self {
        case .keins: return "ohne Muster"
        case .punkte: return "Punkte"
        case .streifen: return "Streifen"
        case .herzen: return "Herzen"
        case .sterne: return "Sterne"
        case .blumen: return "Blümchen"
        }
    }
}

// MARK: - Fundstücke

enum FindItem: String, Codable, CaseIterable, Identifiable {
    case feder, muschel, stein, eichel, schneckenhaus, goldblatt, tannzapfen, flaschenpost

    var id: String { rawValue }

    var name: String {
        switch self {
        case .feder: return "eine bunte Feder"
        case .muschel: return "eine Muschel"
        case .stein: return "einen Glücksstein"
        case .eichel: return "eine Eichel"
        case .schneckenhaus: return "ein leeres Schneckenhaus"
        case .goldblatt: return "ein goldenes Blatt"
        case .tannzapfen: return "einen Tannzapfen"
        case .flaschenpost: return "eine Flaschenpost"
        }
    }

    var emoji: String {
        switch self {
        case .feder: return "🪶"
        case .muschel: return "🐚"
        case .stein: return "🪨"
        case .eichel: return "🌰"
        case .schneckenhaus: return "🐌"
        case .goldblatt: return "🍁"
        case .tannzapfen: return "🌲"
        case .flaschenpost: return "🍾"
        }
    }

    var asset: String {
        switch self {
        case .goldblatt: return "gw_fund_blatt_gold"
        default: return "gw_fund_\(rawValue)"
        }
    }
}

// MARK: - Bewohner

enum Resident: String, Codable, CaseIterable, Identifiable {
    case schmetterling, vogel, hase, igel, eichhoernchen, ente, frosch, fisch, eule, reh, schnecke

    var id: String { rawValue }

    var name: String {
        switch self {
        case .schmetterling: return "Schmetterling"
        case .vogel: return "Rotkehlchen"
        case .hase: return "Hase"
        case .igel: return "Igel"
        case .eichhoernchen: return "Eichhörnchen"
        case .ente: return "Ente"
        case .frosch: return "Frosch"
        case .fisch: return "Fisch"
        case .eule: return "Eule"
        case .reh: return "Reh"
        case .schnecke: return "Schnecke"
        }
    }

    var article: String {
        switch self {
        case .schmetterling, .vogel, .hase, .igel, .frosch, .fisch: return "der"
        case .eichhoernchen, .reh: return "das"
        case .ente, .eule, .schnecke: return "die"
        }
    }

    var emoji: String {
        switch self {
        case .schmetterling: return "🦋"
        case .vogel: return "🐦"
        case .hase: return "🐇"
        case .igel: return "🦔"
        case .eichhoernchen: return "🐿️"
        case .ente: return "🦆"
        case .frosch: return "🐸"
        case .fisch: return "🐟"
        case .eule: return "🦉"
        case .reh: return "🦌"
        case .schnecke: return "🐌"
        }
    }

    var home: WorldArea {
        switch self {
        case .schmetterling, .vogel, .hase, .schnecke: return .haus
        case .ente, .frosch, .fisch: return .bach
        case .igel, .eichhoernchen, .reh: return .lichtung
        case .eule: return .baumhaus
        }
    }

    /// Posen: Ruhe, Bewegung (2 Bilder), besondere Handlung.
    var idlePose: String {
        switch self {
        case .schmetterling: return "sitzen"
        case .vogel: return "stehen"
        case .hase: return "sitzen"
        case .igel: return "schnuppern"
        case .eichhoernchen: return "sitzen"
        case .ente: return "schwimmen"
        case .frosch: return "sitzen"
        case .fisch: return "schwimmen_1"
        case .eule: return "sitzen"
        case .reh: return "stehen"
        case .schnecke: return "kriechen_1"
        }
    }

    var movePoses: [String] {
        switch self {
        case .schmetterling: return ["fliegen_1", "fliegen_2"]
        case .vogel: return ["fliegen_1", "fliegen_2"]
        case .hase: return ["huepfen_1", "huepfen_2"]
        case .igel: return ["laufen_1", "laufen_2"]
        case .eichhoernchen: return ["springen", "sitzen"]
        case .ente: return ["schwimmen", "schwimmen"]
        case .frosch: return ["springen", "sitzen"]
        case .fisch: return ["schwimmen_1", "schwimmen_2"]
        case .eule: return ["fliegen", "fliegen"]
        case .reh: return ["stehen", "grasen"]
        case .schnecke: return ["kriechen_1", "kriechen_2"]
        }
    }

    var actionPose: String {
        switch self {
        case .schmetterling: return "sitzen"
        case .vogel: return "singen"
        case .hase: return "schnuppern"
        case .igel: return "eingerollt"
        case .eichhoernchen: return "tragen"
        case .ente: return "tauchen"
        case .frosch: return "quaken"
        case .fisch: return "schwimmen_2"
        case .eule: return "schlafen"
        case .reh: return "grasen"
        case .schnecke: return "kriechen_2"
        }
    }

    func asset(_ pose: String) -> String { "gw_tier_\(rawValue)_\(pose)" }

    /// Geschwindigkeit in Szenenbreiten pro Sekunde.
    var speed: Double {
        switch self {
        case .schnecke: return 0.01
        case .igel: return 0.03
        case .ente, .fisch: return 0.035
        case .reh, .frosch: return 0.05
        case .hase, .eichhoernchen: return 0.07
        case .schmetterling, .vogel, .eule: return 0.09
        }
    }

    var size: Double {
        switch self {
        case .schmetterling, .schnecke, .fisch: return 0.05
        case .vogel, .frosch: return 0.06
        case .igel, .ente, .eichhoernchen: return 0.075
        case .hase, .eule: return 0.085
        case .reh: return 0.13
        }
    }

    var flies: Bool { [.schmetterling, .vogel, .eule].contains(self) }
    var nocturnal: Bool { self == .eule }
    var diurnal: Bool { [.schmetterling].contains(self) }

    /// Tierlaut-Datei aus dem Tierstimmen-Spiel (falls vorhanden).
    var soundFile: String? {
        switch self {
        case .ente: return "tier_ente_1"
        case .frosch: return "tier_frosch_1"
        case .eule: return "tier_eule_1"
        case .vogel: return "gw_sfx_vogel"
        default: return nil
        }
    }

    var imitation: String {
        switch self {
        case .ente: return "Quak quak!"
        case .frosch: return "Quaak!"
        case .eule: return "Huu huu!"
        case .vogel: return "Tirili!"
        default: return ""
        }
    }

    /// Kurze, sachlich richtige Sätze für Florian.
    var facts: [String] {
        switch self {
        case .schmetterling: return ["Der Schmetterling trinkt Nektar aus den Blüten.", "Schau, wie bunt seine Flügel sind."]
        case .vogel: return ["Das Rotkehlchen singt sein Lied.", "Das Rotkehlchen hat eine orange Brust."]
        case .hase: return ["Der Hase hat lange Ohren. Damit hört er sehr gut.", "Der Hase hoppelt schnell davon."]
        case .igel: return ["Der Igel frisst gerne Käfer und Schnecken.", "Wenn er erschrickt, rollt sich der Igel zu einer Kugel."]
        case .eichhoernchen: return ["Das Eichhörnchen versteckt Nüsse für den Winter.", "Mit seinem buschigen Schwanz hält es das Gleichgewicht."]
        case .ente: return ["Die Ente schwimmt mit ihren Schwimmfüssen.", "Die Ente taucht mit dem Kopf unter Wasser."]
        case .frosch: return ["Der Frosch quakt am Teich.", "Der Frosch kann weit springen."]
        case .fisch: return ["Der Fisch atmet unter Wasser.", "Der Fisch schwimmt im Teich herum."]
        case .eule: return ["Die Eule ist in der Nacht wach.", "Die Eule kann ihren Kopf weit drehen."]
        case .reh: return ["Das Reh frisst Gras und Blätter.", "Das Reh ist scheu und leise."]
        case .schnecke: return ["Die Schnecke trägt ihr Haus auf dem Rücken.", "Die Schnecke kriecht ganz langsam."]
        }
    }

    /// Gebaute Dinge, die dieses Tier gerne besucht.
    var likes: [BuildKind] {
        switch self {
        case .vogel: return [.vogelhaus, .futterstelle, .windspiel, .bank]
        case .hase: return [.tunnel, .bank, .blumentopf]
        case .igel: return [.igelhaus]
        case .eichhoernchen: return [.bank, .bruecke, .windspiel]
        case .schmetterling: return [.insektenhotel, .blumentopf]
        case .ente: return [.segelboot]
        case .eule: return [.laterne, .wimpelkette]
        case .reh: return [.tunnel]
        case .frosch, .fisch, .schnecke: return []
        }
    }
}

// MARK: - Wasserbau

enum WaterPiece: String, Codable, CaseIterable, Identifiable {
    case gerade, kurve, verzweigung, kreuz, schleuse, wasserrad

    var id: String { rawValue }

    var name: String {
        switch self {
        case .gerade: return "Gerade Rinne"
        case .kurve: return "Kurve"
        case .verzweigung: return "Verzweigung"
        case .kreuz: return "Kreuzung"
        case .schleuse: return "Schleuse"
        case .wasserrad: return "Wasserrad"
        }
    }

    var asset: String {
        switch self {
        case .gerade: return "gw_rinne_gerade_h"
        case .kurve: return "gw_rinne_kurve_ro"
        case .verzweigung: return "gw_rinne_t"
        case .kreuz: return "gw_rinne_kreuz"
        case .schleuse: return "gw_schleuse_zu"
        case .wasserrad: return "gw_wasserrad_1"
        }
    }

    /// Öffnungen bei Drehung 0 (0 = rechts, 1 = oben, 2 = links, 3 = unten).
    var baseOpenings: [Int] {
        switch self {
        case .gerade, .schleuse, .wasserrad: return [0, 2]
        case .kurve: return [0, 1]
        case .verzweigung: return [0, 2, 3]
        case .kreuz: return [0, 1, 2, 3]
        }
    }

    var rotations: Int {
        switch self {
        case .gerade, .schleuse, .wasserrad: return 2
        case .kreuz: return 1
        default: return 4
        }
    }

    static let starter: [WaterPiece] = [.gerade, .kurve]
}

struct WaterTile: Codable, Equatable, Identifiable {
    var id = UUID()
    var col: Int
    var row: Int
    var piece: WaterPiece
    /// Vierteldrehungen gegen den Uhrzeigersinn
    var rotation: Int = 0
    var open = true

    var openings: [Int] { piece.baseOpenings.map { ($0 + rotation) % 4 } }
}

enum BoatKind: String, Codable, CaseIterable, Identifiable {
    case blatt, rinde, fracht

    var id: String { rawValue }
    var name: String {
        switch self {
        case .blatt: return "Blattboot"
        case .rinde: return "Rindenboot"
        case .fracht: return "Frachtboot"
        }
    }
    var asset: String { "gw_boot_\(rawValue)" }
    var emoji: String { self == .fracht ? "🛶" : "🍃" }
}

// MARK: - Küche

enum DishKind: String, Codable, CaseIterable, Identifiable {
    case erdbeerschale, obstschale, karottensticks, salatteller, kuerbissuppe, apfelsaft, kuchen, erbsen, blumenstrauss, kuerbislaterne, eigenerTeller

    var id: String { rawValue }

    var name: String {
        switch self {
        case .erdbeerschale: return "Erdbeerschale"
        case .obstschale: return "Obstschale"
        case .karottensticks: return "Karottensticks"
        case .salatteller: return "Salatteller"
        case .kuerbissuppe: return "Kürbissuppe"
        case .apfelsaft: return "Apfelsaft"
        case .kuchen: return "Obstkuchen"
        case .erbsen: return "Erbsenschale"
        case .blumenstrauss: return "Blumenstrauss"
        case .kuerbislaterne: return "Kürbislaterne"
        case .eigenerTeller: return "Mein eigener Teller"
        }
    }

    var emoji: String {
        switch self {
        case .erdbeerschale: return "🍓"
        case .obstschale: return "🍎"
        case .karottensticks: return "🥕"
        case .salatteller: return "🥗"
        case .kuerbissuppe: return "🥣"
        case .apfelsaft: return "🧃"
        case .kuchen: return "🥧"
        case .erbsen: return "🫛"
        case .blumenstrauss: return "💐"
        case .kuerbislaterne: return "🎃"
        case .eigenerTeller: return "🍽️"
        }
    }

    var asset: String {
        switch self {
        case .erdbeerschale: return "gw_schale_erdbeeren"
        case .obstschale: return "gw_schale_obst"
        case .karottensticks: return "gw_schale_karotten"
        case .salatteller: return "gw_kueche_obstteller"
        case .kuerbissuppe: return "gw_kueche_suppenteller"
        case .apfelsaft: return "gw_kueche_glas_saft"
        case .kuchen: return "gw_kueche_kuchen_fertig"
        case .erbsen: return "gw_schale_leer"
        case .blumenstrauss: return "gw_kueche_vase_strauss"
        case .kuerbislaterne: return "gw_kueche_laterne_kuerbis"
        case .eigenerTeller: return "gw_teller"
        }
    }

    /// Zutaten. «Obst» und «Blumen» erlauben jede passende Sorte.
    var ingredients: [Ingredient] {
        switch self {
        case .erdbeerschale: return Array(repeating: .item(.erdbeere), count: 3)
        case .obstschale: return Array(repeating: .anyFruit, count: 3)
        case .karottensticks: return Array(repeating: .item(.karotte), count: 2)
        case .salatteller: return [.item(.salat), .item(.radieschen), .item(.radieschen), .item(.tomate)]
        case .kuerbissuppe: return [.item(.kuerbis), .item(.karotte)]
        case .apfelsaft: return Array(repeating: .item(.apfel), count: 3)
        case .kuchen: return [.item(.apfel), .item(.apfel), .item(.erdbeere), .item(.erdbeere), .item(.erdbeere)]
        case .erbsen: return [.item(.erbsenschote), .item(.erbsenschote)]
        case .blumenstrauss: return Array(repeating: .anyFlower, count: 3)
        case .kuerbislaterne: return [.item(.kuerbis)]
        case .eigenerTeller: return []
        }
    }

    /// Arbeitsschritt nach dem Hinlegen.
    var finishing: KitchenStep {
        switch self {
        case .erdbeerschale, .obstschale: return .wash
        case .karottensticks, .salatteller: return .cut
        case .kuerbissuppe: return .stir
        case .apfelsaft: return .pour
        case .kuchen: return .bake
        case .erbsen: return .shell
        case .blumenstrauss: return .arrange
        case .kuerbislaterne: return .carve
        case .eigenerTeller: return .none
        }
    }

    var isFood: Bool { ![.blumenstrauss, .kuerbislaterne].contains(self) }
}

enum Ingredient: Equatable {
    case item(HarvestItem)
    case anyFruit
    case anyFlower

    func accepts(_ h: HarvestItem) -> Bool {
        switch self {
        case .item(let i): return i == h
        case .anyFruit: return h.isFruit
        case .anyFlower: return h.isFlower
        }
    }

    var emoji: String {
        switch self {
        case .item(let i): return i.emoji
        case .anyFruit: return "🍎"
        case .anyFlower: return "🌷"
        }
    }

    var label: String {
        switch self {
        case .item(let i): return i.name
        case .anyFruit: return "Obst"
        case .anyFlower: return "Blume"
        }
    }
}

enum KitchenStep {
    case wash, cut, stir, pour, bake, shell, arrange, carve, none

    var instruction: String {
        switch self {
        case .wash: return "Jetzt waschen wir alles. Tippe auf die Wasserschüssel."
        case .cut: return "Jetzt schneiden wir. Tippe dreimal auf das Brett."
        case .stir: return "Rühre im Topf. Tippe dreimal auf den Löffel."
        case .pour: return "Giesse den Saft ins Glas."
        case .bake: return "Jetzt kommt der Kuchen in den Ofen. Tippe auf den Ofen."
        case .shell: return "Öffne die Schoten und hole die Erbsen heraus."
        case .arrange: return "Stell die Blumen in die Vase."
        case .carve: return "Welches Gesicht bekommt deine Laterne?"
        case .none: return ""
        }
    }

    var taps: Int {
        switch self {
        case .cut, .stir: return 3
        case .none: return 0
        default: return 1
        }
    }
}

// MARK: - Picknick

struct PicnicState: Codable, Equatable {
    var area: WorldArea = .haus
    var blanket: Int = 0
    var dishes: [DishKind] = []
    var plates: Int = 0
    var date = Date()
}

// MARK: - Wunderlichtung

enum ChimeKind: String, Codable, CaseIterable, Identifiable {
    case glockenblume, pilztrommel, kristall, muschelhorn, tropfenharfe

    var id: String { rawValue }
    var name: String {
        switch self {
        case .glockenblume: return "Glockenblume"
        case .pilztrommel: return "Pilztrommel"
        case .kristall: return "Kristall"
        case .muschelhorn: return "Muschelhorn"
        case .tropfenharfe: return "Tropfenharfe"
        }
    }
    var emoji: String {
        switch self {
        case .glockenblume: return "🔔"
        case .pilztrommel: return "🍄"
        case .kristall: return "💎"
        case .muschelhorn: return "🐚"
        case .tropfenharfe: return "💧"
        }
    }
    var frequency: Double {
        switch self {
        case .glockenblume: return 523.25
        case .pilztrommel: return 587.33
        case .kristall: return 659.25
        case .muschelhorn: return 783.99
        case .tropfenharfe: return 880.0
        }
    }
    var sound: String {
        switch self {
        case .glockenblume: return "gw_sfx_klang_c"
        case .pilztrommel: return "gw_sfx_klang_d"
        case .kristall: return "gw_sfx_klang_e"
        case .muschelhorn: return "gw_sfx_klang_g"
        case .tropfenharfe: return "gw_sfx_klang_a"
        }
    }
    var asset: String { "gw_klang_\(rawValue)" }
    var glowAsset: String { "gw_klang_\(rawValue)_leuchten" }
}

enum FantasyShape: String, Codable, CaseIterable { case glocke, stern, herz, schirm, spirale
    var emoji: String {
        switch self {
        case .glocke: return "🔔"
        case .stern: return "⭐️"
        case .herz: return "💗"
        case .schirm: return "☂️"
        case .spirale: return "🌀"
        }
    }
}
enum FantasyStem: String, Codable, CaseIterable { case gerade = "stiel_gerade", geschwungen = "stiel_geschwungen", spirale = "stiel_spirale" }
enum FantasyReaction: String, Codable, CaseIterable {
    case klingeln, aufgehen, lichtpunkte
    var name: String {
        switch self {
        case .klingeln: return "klingelt"
        case .aufgehen: return "geht auf wie ein Schirm"
        case .lichtpunkte: return "lässt Lichter aufsteigen"
        }
    }
    var symbol: String {
        switch self {
        case .klingeln: return "bell.fill"
        case .aufgehen: return "umbrella.fill"
        case .lichtpunkte: return "sparkles"
        }
    }
}

struct FantasyFlower: Codable, Equatable, Identifiable {
    var id = UUID()
    var slot: Int
    var shape: FantasyShape
    var color: WorldColor
    var stem: FantasyStem
    var reaction: FantasyReaction
}

// MARK: - Erinnerungen

enum MemoryKind: String, Codable {
    case ersteErnte, picknick, gebaut, bewohner, boot, ort, fest, melodie, fantasieblume, baumhaus, gericht
}

struct WorldMemory: Codable, Equatable, Identifiable {
    var id = UUID()
    var date = Date()
    var kind: MemoryKind
    /// z. B. Pflanzenart, Tier, Ort oder die ID eines Bauwerks
    var detail: String = ""
    var extra: [String] = []
}

// MARK: - Gesamter Zustand

struct WorldData: Codable, Equatable {
    var beds: [BedState] = Array(repeating: BedState(), count: 7)
    /// Beet am Bach, das über den Wasserlauf bewässert wird
    var streamBed = BedState()
    var basket: [String: Int] = [:]
    var seeds: [PlantKind] = PlantKind.starter
    var harvestedOnce: [String] = []

    var unlocked: [WorldArea] = [.haus]
    var workshopOpen = false
    var kits: [BuildKind] = []
    var built: [BuiltObject] = []
    var finds: [String: Int] = [:]

    var residents: [Resident] = []
    var visitors: [Resident] = []

    var tiles: [WaterTile] = []
    var pieces: [WaterPiece] = WaterPiece.starter
    var boats: [BoatKind] = [.blatt]
    var boatTrips = 0
    var pondReached = false

    var pantry: [String: Int] = [:]
    var cooked: [String] = []
    var picnic: PicnicState?
    var treeHousePicnic: PicnicState?
    var lanternFace: Int = 0

    var adventures: [String: Int] = [:]
    var adventuresDone: [String] = []

    var treehouseStage = 0
    var chimes: [ChimeKind?] = [nil, nil, nil, nil]
    var chimeKinds: [ChimeKind] = [.glockenblume, .pilztrommel, .kristall]
    var fantasy: [FantasyFlower] = []
    var lightLevel = 0

    var memories: [WorldMemory] = []
    var evening = false
    var lastArea: WorldArea = .haus
    var introDone = false
    var festDone = false

    init() {}

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = WorldData()
        beds = (try? c.decode([BedState].self, forKey: .beds)) ?? d.beds
        if beds.count < 7 { beds += Array(repeating: BedState(), count: 7 - beds.count) }
        streamBed = (try? c.decode(BedState.self, forKey: .streamBed)) ?? d.streamBed
        basket = (try? c.decode([String: Int].self, forKey: .basket)) ?? d.basket
        seeds = (try? c.decode([PlantKind].self, forKey: .seeds)) ?? d.seeds
        harvestedOnce = (try? c.decode([String].self, forKey: .harvestedOnce)) ?? d.harvestedOnce
        unlocked = (try? c.decode([WorldArea].self, forKey: .unlocked)) ?? d.unlocked
        workshopOpen = (try? c.decode(Bool.self, forKey: .workshopOpen)) ?? d.workshopOpen
        kits = (try? c.decode([BuildKind].self, forKey: .kits)) ?? d.kits
        built = (try? c.decode([BuiltObject].self, forKey: .built)) ?? d.built
        finds = (try? c.decode([String: Int].self, forKey: .finds)) ?? d.finds
        residents = (try? c.decode([Resident].self, forKey: .residents)) ?? d.residents
        visitors = (try? c.decode([Resident].self, forKey: .visitors)) ?? d.visitors
        tiles = (try? c.decode([WaterTile].self, forKey: .tiles)) ?? d.tiles
        pieces = (try? c.decode([WaterPiece].self, forKey: .pieces)) ?? d.pieces
        boats = (try? c.decode([BoatKind].self, forKey: .boats)) ?? d.boats
        boatTrips = (try? c.decode(Int.self, forKey: .boatTrips)) ?? d.boatTrips
        pondReached = (try? c.decode(Bool.self, forKey: .pondReached)) ?? d.pondReached
        pantry = (try? c.decode([String: Int].self, forKey: .pantry)) ?? d.pantry
        cooked = (try? c.decode([String].self, forKey: .cooked)) ?? d.cooked
        picnic = try? c.decode(PicnicState.self, forKey: .picnic)
        treeHousePicnic = try? c.decode(PicnicState.self, forKey: .treeHousePicnic)
        lanternFace = (try? c.decode(Int.self, forKey: .lanternFace)) ?? d.lanternFace
        adventures = (try? c.decode([String: Int].self, forKey: .adventures)) ?? d.adventures
        adventuresDone = (try? c.decode([String].self, forKey: .adventuresDone)) ?? d.adventuresDone
        treehouseStage = (try? c.decode(Int.self, forKey: .treehouseStage)) ?? d.treehouseStage
        chimes = (try? c.decode([ChimeKind?].self, forKey: .chimes)) ?? d.chimes
        if chimes.count < 4 { chimes += Array(repeating: nil, count: 4 - chimes.count) }
        chimeKinds = (try? c.decode([ChimeKind].self, forKey: .chimeKinds)) ?? d.chimeKinds
        fantasy = (try? c.decode([FantasyFlower].self, forKey: .fantasy)) ?? d.fantasy
        lightLevel = (try? c.decode(Int.self, forKey: .lightLevel)) ?? d.lightLevel
        memories = (try? c.decode([WorldMemory].self, forKey: .memories)) ?? d.memories
        evening = (try? c.decode(Bool.self, forKey: .evening)) ?? d.evening
        lastArea = (try? c.decode(WorldArea.self, forKey: .lastArea)) ?? d.lastArea
        introDone = (try? c.decode(Bool.self, forKey: .introDone)) ?? d.introDone
        festDone = (try? c.decode(Bool.self, forKey: .festDone)) ?? d.festDone
    }

    func count(_ item: HarvestItem) -> Int { basket[item.rawValue] ?? 0 }
    func count(_ dish: DishKind) -> Int { pantry[dish.rawValue] ?? 0 }
    func has(_ r: Resident) -> Bool { residents.contains(r) }
    func isUnlocked(_ a: WorldArea) -> Bool { unlocked.contains(a) }
    func isBuilt(_ k: BuildKind) -> Bool { built.contains { $0.kind == k } }
    var totalFinds: Int { finds.values.reduce(0, +) }
}
