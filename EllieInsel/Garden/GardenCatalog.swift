import Foundation

enum GardenCatalog {
    /// Die zwölf Dekorationen, die von Anfang an zur Verfügung stehen.
    static let starterItems: [String] = ["g2_tulpen", "g2_gaensebluemchen", "g2_farn", "g2_tanne", "g2_steinhaufen", "g2_pilzgruppe",
                                         "g2_blumenkuebel", "g2_zaun", "g2_baumstumpf", "g2_lavendelbusch", "g2_rosenbusch", "g2_windrad"]

    /// Weitere Dekorationen, die nach abgeschlossenen Runden gewählt werden können.
    static let rewardItems: [String] = [
        "g2_gartenzwerg", "g2_vogeltraenke", "g2_gartenlaterne", "g2_schubkarre", "g2_giesskanne_blumen", "g2_schaukel",
        "g2_sandkasten", "g2_vogelscheuche", "g2_bienenkorb", "g2_regenfass", "g2_wegweiser", "g2_obstbaum_klein"
    ]

    /// Gartenschmuck im alten Bilderbuchstil (Emoji als Schlüssel). Wird nicht mehr verschenkt,
    /// bleibt aber in bestehenden Gärten erhalten.
    static let legacyItems: [String] = [
        "🌷", "🌻", "🌼", "🌳", "🌲", "🪨", "🍄", "🌿", "🐞", "🦋", "🏡", "🌾",
        "🐇", "🦔", "🐿️", "🐦", "🦆", "🐸", "🐌", "🐝", "🦉", "🦊", "🦌", "🐢",
        "🌵", "🌴", "🍓", "🍒", "🍐", "🍎", "🥕", "🎃", "🌈", "⛲️", "🪺", "🛖",
        "🍀", "🌺", "🌹", "🪻", "⭐️", "🎈", "🪁", "🐑", "🐓", "🐈", "🐕", "🦢"
    ]

    static var allItems: [String] { starterItems + rewardItems }

    /// Bildnamen der Dekorationen (`garten_<name>.png`); fehlt das Bild, erscheint das Emoji.
    static let names: [String: String] = [
        "🌷": "tulpe", "🌻": "sonnenblume", "🌼": "gaensebluemchen", "🌳": "baum", "🌲": "tanne", "🪨": "stein",
        "🍄": "pilz", "🌿": "kraeuter", "🐞": "marienkaefer", "🦋": "schmetterling", "🏡": "haus", "🌾": "aehren",
        "🐇": "hase", "🦔": "igel", "🐿️": "eichhoernchen", "🐦": "vogel", "🦆": "ente", "🐸": "frosch",
        "🐌": "schnecke", "🐝": "biene", "🦉": "eule", "🦊": "fuchs", "🦌": "reh", "🐢": "schildkroete",
        "🌵": "kaktus", "🌴": "palme", "🍓": "erdbeere", "🍒": "kirschen", "🍐": "birne", "🍎": "apfel",
        "🥕": "karotte", "🎃": "kuerbis", "🌈": "regenbogen", "⛲️": "brunnen", "🪺": "nest", "🛖": "huette",
        "🍀": "kleeblatt", "🌺": "hibiskus", "🌹": "rose", "🪻": "lavendel", "⭐️": "stern", "🎈": "ballon",
        "🪁": "drachen", "🐑": "schaf", "🐓": "hahn", "🐈": "katze", "🐕": "hund", "🦢": "schwan"
    ]

    /// Grösse im Garten relativ zur Standardgrösse, damit Tiere und Pflanzen zueinander passen
    /// (Hermes-Prüfung Garten 2: kleine Tiere waren zu gross, Sonnenblume zu klein).
    static func scale(_ item: String) -> Double {
        if item.hasPrefix("g2_") {
            switch String(item.dropFirst(3)) {
            case "tanne", "obstbaum_klein", "schaukel", "vogelscheuche": return 1.9
            case "sandkasten", "schubkarre", "regenfass", "zaun", "wegweiser", "vogeltraenke", "bienenkorb": return 1.4
            case "gaensebluemchen", "tulpen", "farn", "pilzgruppe": return 0.9
            default: return 1.15
            }
        }
        switch names[item] {
        case "marienkaefer", "biene", "schnecke": return 0.5
        case "igel", "frosch", "vogel": return 0.7
        case "gaensebluemchen": return 0.7
        case "sonnenblume": return 1.3
        default: return 1
        }
    }

    static func asset(_ item: String) -> String {
        // Neuer Schmuck: Schlüssel «g2_<name>» → Bild garten2_<name>
        if item.hasPrefix("g2_") { return "garten2_" + String(item.dropFirst(3)) }
        return names[item].map { "garten_" + $0 } ?? ""
    }

    /// Drei Auswahlmöglichkeiten, deterministisch aus der Runden-ID, damit ein erneutes Öffnen dieselbe Auswahl zeigt.
    static func rewardOptions(roundID: String, owned: [String]) -> [String] {
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: roundID.stableHash))
        let fresh = rewardItems.filter { !owned.contains($0) }
        var pool = fresh.count >= 3 ? fresh : rewardItems
        pool.shuffle(using: &rng)
        return Array(pool.prefix(3))
    }
}
