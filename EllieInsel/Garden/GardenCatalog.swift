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

    /// Drei Auswahlmöglichkeiten, deterministisch aus der Runden-ID, damit ein erneutes Öffnen dieselbe Auswahl zeigt.
    static func rewardOptions(roundID: String, owned: [String]) -> [String] {
        var rng = SeededGenerator(seed: UInt64(truncatingIfNeeded: roundID.stableHash))
        let fresh = rewardItems.filter { !owned.contains($0) }
        var pool = fresh.count >= 3 ? fresh : rewardItems
        pool.shuffle(using: &rng)
        return Array(pool.prefix(3))
    }
}
