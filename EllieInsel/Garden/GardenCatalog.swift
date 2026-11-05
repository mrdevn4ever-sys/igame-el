import Foundation

enum GardenCatalog {
    /// Die zwölf Dekorationen, die von Anfang an zur Verfügung stehen.
    static let starterItems: [String] = ["🌷", "🌻", "🌼", "🌳", "🌲", "🪨", "🍄", "🌿", "🐞", "🦋", "🏡", "🌾"]

    /// Weitere Dekorationen, die nach abgeschlossenen Runden gewählt werden können.
    static let rewardItems: [String] = [
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
        switch names[item] {
        case "marienkaefer", "biene", "schnecke": return 0.5
        case "igel", "frosch", "vogel": return 0.7
        case "gaensebluemchen": return 0.7
        case "sonnenblume": return 1.3
        default: return 1
        }
    }

    static func asset(_ item: String) -> String {
        names[item].map { "garten_" + $0 } ?? ""
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
