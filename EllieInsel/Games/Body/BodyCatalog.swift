import SwiftUI

/// Bildebenen der Kinderfigur. Alle Ebenen haben denselben Bildrahmen (3:4) und dieselbe Haltung,
/// damit sie genau übereinander liegen.
enum BodyLayer: String, Codable, CaseIterable, Identifiable {
    case aussen, organe, knochen, adern, muskeln

    var id: String { rawValue }
    var asset: String { "koerper_\(rawValue)" }

    var title: String {
        switch self {
        case .aussen: return "Aussen"
        case .organe: return "Organe"
        case .knochen: return "Knochen"
        case .adern: return "Adern"
        case .muskeln: return "Muskeln"
        }
    }

    var emoji: String {
        switch self {
        case .aussen: return "🧒"
        case .organe: return "🫀"
        case .knochen: return "🦴"
        case .adern: return "🩸"
        case .muskeln: return "💪"
        }
    }

    /// Ansage beim Wechsel der Zauberlupe.
    var lensText: String {
        switch self {
        case .aussen: return "Jetzt siehst du wieder die Haut."
        case .organe: return "Die Zauberlupe zeigt jetzt die Organe."
        case .knochen: return "Die Zauberlupe zeigt jetzt die Knochen."
        case .adern: return "Die Zauberlupe zeigt jetzt die Adern."
        case .muskeln: return "Die Zauberlupe zeigt jetzt die Muskeln."
        }
    }
}

/// Was ein Körperteil macht (Antwortbilder bei «Was macht …?»).
enum BodyFunction: String, Codable, CaseIterable {
    case pumpen, atmen, denken, verdauen, sehen, hoeren, riechen, schmecken, fuehlen, stuetzen, schuetzen, bewegen

    var label: String {
        switch self {
        case .pumpen: return "Blut pumpen"
        case .atmen: return "Atmen"
        case .denken: return "Denken"
        case .verdauen: return "Essen verdauen"
        case .sehen: return "Sehen"
        case .hoeren: return "Hören"
        case .riechen: return "Riechen"
        case .schmecken: return "Schmecken"
        case .fuehlen: return "Fühlen"
        case .stuetzen: return "Den Körper halten"
        case .schuetzen: return "Beschützen"
        case .bewegen: return "Bewegen"
        }
    }

    var emoji: String {
        switch self {
        case .pumpen: return "❤️"
        case .atmen: return "🌬️"
        case .denken: return "💭"
        case .verdauen: return "🍽️"
        case .sehen: return "🌈"
        case .hoeren: return "🎵"
        case .riechen: return "🌸"
        case .schmecken: return "🍦"
        case .fuehlen: return "🐱"
        case .stuetzen: return "🧍"
        case .schuetzen: return "🛡️"
        case .bewegen: return "🤸"
        }
    }

    var asset: String { "koerper_funktion_\(rawValue)" }
}

/// Ein Körperteil, das man zeigen, suchen oder erklären kann.
/// Koordinaten: Anteil am Bildrahmen der Figur (x nach rechts, y nach unten).
/// Wichtig: Die Figur schaut uns an. Ihr linker Arm ist auf unserer rechten Seite, das Herz liegt
/// darum etwas rechts der Mitte.
enum BodyPart: String, Codable, CaseIterable, Identifiable {
    // Aussen
    case kopf, bauch, hand, fuss, arm, bein, knie
    // Gesicht und Sinne
    case augen, ohren, nase, mund
    // Organe
    case gehirn, herz, lunge, magen, darm
    // Knochen
    case schaedel, rippen, wirbelsaeule, oberschenkel
    // Adern und Muskeln
    case adern, muskeln

    var id: String { rawValue }

    var name: String {
        switch self {
        case .kopf: return "Kopf"
        case .bauch: return "Bauch"
        case .hand: return "Hand"
        case .fuss: return "Fuss"
        case .arm: return "Arm"
        case .bein: return "Bein"
        case .knie: return "Knie"
        case .augen: return "Augen"
        case .ohren: return "Ohren"
        case .nase: return "Nase"
        case .mund: return "Mund"
        case .gehirn: return "Gehirn"
        case .herz: return "Herz"
        case .lunge: return "Lunge"
        case .magen: return "Magen"
        case .darm: return "Darm"
        case .schaedel: return "Schädel"
        case .rippen: return "Rippen"
        case .wirbelsaeule: return "Wirbelsäule"
        case .oberschenkel: return "Oberschenkelknochen"
        case .adern: return "Adern"
        case .muskeln: return "Muskeln"
        }
    }

    var emoji: String {
        switch self {
        case .kopf: return "🙂"
        case .bauch: return "🫃"
        case .hand: return "✋"
        case .fuss: return "🦶"
        case .arm: return "💪"
        case .bein: return "🦵"
        case .knie: return "🦵"
        case .augen: return "👀"
        case .ohren: return "👂"
        case .nase: return "👃"
        case .mund: return "👄"
        case .gehirn: return "🧠"
        case .herz: return "🫀"
        case .lunge: return "🫁"
        case .magen: return "🥣"
        case .darm: return "🌀"
        case .schaedel: return "💀"
        case .rippen: return "🦴"
        case .wirbelsaeule: return "🦴"
        case .oberschenkel: return "🦴"
        case .adern: return "🩸"
        case .muskeln: return "💪"
        }
    }

    var asset: String { "koerper_teil_\(rawValue)" }

    var layer: BodyLayer {
        switch self {
        case .kopf, .bauch, .hand, .fuss, .arm, .bein, .knie, .augen, .ohren, .nase, .mund: return .aussen
        case .gehirn, .herz, .lunge, .magen, .darm: return .organe
        case .schaedel, .rippen, .wirbelsaeule, .oberschenkel: return .knochen
        case .adern: return .adern
        case .muskeln: return .muskeln
        }
    }

    /// Trefferpunkte auf der Figur (paarige Teile haben zwei).
    var spots: [CGPoint] {
        switch self {
        case .kopf: return [CGPoint(x: 0.5, y: 0.14)]
        case .bauch: return [CGPoint(x: 0.5, y: 0.47)]
        case .hand: return [CGPoint(x: 0.18, y: 0.58), CGPoint(x: 0.82, y: 0.58)]
        case .fuss: return [CGPoint(x: 0.42, y: 0.95), CGPoint(x: 0.58, y: 0.95)]
        case .arm: return [CGPoint(x: 0.25, y: 0.43), CGPoint(x: 0.75, y: 0.43)]
        case .bein: return [CGPoint(x: 0.43, y: 0.8), CGPoint(x: 0.57, y: 0.8)]
        case .knie: return [CGPoint(x: 0.43, y: 0.73), CGPoint(x: 0.57, y: 0.73)]
        case .augen: return [CGPoint(x: 0.45, y: 0.14), CGPoint(x: 0.55, y: 0.14)]
        case .ohren: return [CGPoint(x: 0.37, y: 0.155), CGPoint(x: 0.63, y: 0.155)]
        case .nase: return [CGPoint(x: 0.5, y: 0.175)]
        case .mund: return [CGPoint(x: 0.5, y: 0.205)]
        case .gehirn: return [CGPoint(x: 0.5, y: 0.085)]
        case .herz: return [CGPoint(x: 0.535, y: 0.37)]
        case .lunge: return [CGPoint(x: 0.44, y: 0.36), CGPoint(x: 0.575, y: 0.35)]
        case .magen: return [CGPoint(x: 0.545, y: 0.45)]
        case .darm: return [CGPoint(x: 0.5, y: 0.53)]
        case .schaedel: return [CGPoint(x: 0.5, y: 0.12)]
        case .rippen: return [CGPoint(x: 0.44, y: 0.38), CGPoint(x: 0.56, y: 0.38)]
        case .wirbelsaeule: return [CGPoint(x: 0.5, y: 0.47), CGPoint(x: 0.5, y: 0.52)]
        case .oberschenkel: return [CGPoint(x: 0.44, y: 0.65), CGPoint(x: 0.56, y: 0.65)]
        case .adern: return [CGPoint(x: 0.25, y: 0.46), CGPoint(x: 0.75, y: 0.46), CGPoint(x: 0.44, y: 0.8), CGPoint(x: 0.56, y: 0.8)]
        case .muskeln: return [CGPoint(x: 0.26, y: 0.42), CGPoint(x: 0.74, y: 0.42), CGPoint(x: 0.43, y: 0.66), CGPoint(x: 0.57, y: 0.66)]
        }
    }

    /// Trefferradius als Anteil der Figurenhöhe.
    var radius: Double {
        switch self {
        case .kopf: return 0.1
        case .bauch: return 0.07
        case .augen, .nase, .mund: return 0.028
        case .ohren: return 0.03
        case .herz: return 0.04
        case .wirbelsaeule: return 0.05
        default: return 0.055
        }
    }

    /// «Wo ist …?» für Teile, die man von aussen sieht.
    var whereQuestion: String {
        switch self {
        case .kopf: return "Wo ist dein Kopf?"
        case .bauch: return "Wo ist dein Bauch?"
        case .hand: return "Wo ist deine Hand?"
        case .fuss: return "Wo ist dein Fuss?"
        case .arm: return "Wo ist dein Arm?"
        case .bein: return "Wo ist dein Bein?"
        case .knie: return "Wo ist dein Knie?"
        case .augen: return "Wo sind deine Augen?"
        case .ohren: return "Wo sind deine Ohren?"
        case .nase: return "Wo ist deine Nase?"
        case .mund: return "Wo ist dein Mund?"
        case .gehirn: return "Such dein Gehirn mit der Zauberlupe."
        case .herz: return "Such dein Herz mit der Zauberlupe."
        case .lunge: return "Such deine Lunge mit der Zauberlupe."
        case .magen: return "Such deinen Magen mit der Zauberlupe."
        case .darm: return "Such deinen Darm mit der Zauberlupe."
        case .schaedel: return "Such deinen Schädel mit der Zauberlupe."
        case .rippen: return "Such deine Rippen mit der Zauberlupe."
        case .wirbelsaeule: return "Such deine Wirbelsäule mit der Zauberlupe."
        case .oberschenkel: return "Such deinen Oberschenkelknochen mit der Zauberlupe."
        case .adern: return "Such deine Adern mit der Zauberlupe."
        case .muskeln: return "Such deine Muskeln mit der Zauberlupe."
        }
    }

    /// Wird gesagt, wenn das Kind auf dieses Teil tippt, aber ein anderes gesucht ist.
    var thisIs: String {
        switch self {
        case .kopf: return "Das ist dein Kopf."
        case .bauch: return "Das ist dein Bauch."
        case .hand: return "Das ist deine Hand."
        case .fuss: return "Das ist dein Fuss."
        case .arm: return "Das ist dein Arm."
        case .bein: return "Das ist dein Bein."
        case .knie: return "Das ist dein Knie."
        case .augen: return "Das sind deine Augen."
        case .ohren: return "Das sind deine Ohren."
        case .nase: return "Das ist deine Nase."
        case .mund: return "Das ist dein Mund."
        case .gehirn: return "Das ist dein Gehirn."
        case .herz: return "Das ist dein Herz."
        case .lunge: return "Das ist deine Lunge."
        case .magen: return "Das ist dein Magen."
        case .darm: return "Das ist dein Darm."
        case .schaedel: return "Das ist dein Schädel."
        case .rippen: return "Das sind deine Rippen."
        case .wirbelsaeule: return "Das ist deine Wirbelsäule."
        case .oberschenkel: return "Das ist dein Oberschenkelknochen."
        case .adern: return "Das sind deine Adern."
        case .muskeln: return "Das sind deine Muskeln."
        }
    }

    /// Kindgerechte, sachlich richtige Erklärung (wie es aussieht und was es macht).
    var explanation: String {
        switch self {
        case .kopf: return "Im Kopf sind dein Gehirn, deine Augen, deine Ohren, deine Nase und dein Mund."
        case .bauch: return "In deinem Bauch liegen der Magen und der Darm. Dort wird dein Essen verdaut."
        case .hand: return "Mit der Hand kannst du greifen, malen und winken. Jede Hand hat fünf Finger."
        case .fuss: return "Auf deinen Füssen stehst und gehst du. Jeder Fuss hat fünf Zehen."
        case .arm: return "Deine Arme können sich beugen und strecken. In der Mitte ist der Ellbogen."
        case .bein: return "Mit deinen Beinen gehst, rennst und hüpfst du."
        case .knie: return "Das Knie ist ein Gelenk. Damit kannst du dein Bein beugen."
        case .augen: return "Mit deinen Augen siehst du Farben, Formen und alles um dich herum."
        case .ohren: return "Mit deinen Ohren hörst du Stimmen, Musik und Geräusche."
        case .nase: return "Mit deiner Nase riechst du. Und du atmest durch die Nase."
        case .mund: return "Mit dem Mund isst und sprichst du. Mit der Zunge im Mund schmeckst du, ob etwas süss oder sauer ist."
        case .gehirn: return "Das Gehirn ist im Kopf. Damit denkst, lernst und träumst du. Es sagt deinem Körper, was er tun soll."
        case .herz: return "Dein Herz ist ein starker Muskel und etwa so gross wie deine Faust. Es pumpt das Blut durch deinen ganzen Körper."
        case .lunge: return "Du hast zwei Lungenflügel in der Brust. Wenn du einatmest, füllen sie sich mit Luft wie ein Ballon."
        case .magen: return "Der Magen ist wie ein kleiner Sack. Dort wird dein Essen zu einem weichen Brei geknetet."
        case .darm: return "Der Darm ist ein ganz langer Schlauch im Bauch. Dort holt dein Körper die guten Sachen aus dem Essen."
        case .schaedel: return "Der Schädel ist wie ein harter Helm. Er beschützt dein Gehirn."
        case .rippen: return "Die Rippen sind wie ein Käfig aus Knochen. Sie beschützen dein Herz und deine Lunge."
        case .wirbelsaeule: return "Die Wirbelsäule geht durch deinen Rücken. Sie hält dich aufrecht, und du kannst dich mit ihr bücken und drehen."
        case .oberschenkel: return "Der Oberschenkelknochen ist der längste Knochen in deinem Körper."
        case .adern: return "In den Adern fliesst dein Blut durch den ganzen Körper, bis in die Finger und Zehen. Auf Bildern malt man manche Adern blau, das Blut ist aber immer rot."
        case .muskeln: return "Mit deinen Muskeln bewegst du dich. Sie ziehen an den Knochen."
        }
    }

    var function: BodyFunction {
        switch self {
        case .herz, .adern: return .pumpen
        case .lunge, .nase: return .atmen
        case .gehirn, .kopf: return .denken
        case .magen, .darm, .bauch: return .verdauen
        case .augen: return .sehen
        case .ohren: return .hoeren
        case .mund: return .schmecken
        case .hand: return .fuehlen
        case .wirbelsaeule, .oberschenkel: return .stuetzen
        case .schaedel, .rippen: return .schuetzen
        case .muskeln, .arm, .bein, .knie, .fuss: return .bewegen
        }
    }

    /// «Was macht …?»-Frage, nur für Teile mit eindeutiger Aufgabe.
    var functionQuestion: String? {
        switch self {
        case .herz: return "Was macht dein Herz?"
        case .lunge: return "Was macht deine Lunge?"
        case .gehirn: return "Was macht dein Gehirn?"
        case .magen: return "Was macht dein Magen?"
        case .augen: return "Was machst du mit den Augen?"
        case .ohren: return "Was machst du mit den Ohren?"
        case .schaedel: return "Was macht dein Schädel?"
        case .rippen: return "Was machen deine Rippen?"
        case .wirbelsaeule: return "Was macht deine Wirbelsäule?"
        case .muskeln: return "Was machen deine Muskeln?"
        default: return nil
        }
    }

    /// Grösse des Teils, wenn es im Puzzle in die Figur gelegt wird (Anteil der Figurenhöhe).
    var puzzleSize: Double {
        switch self {
        case .gehirn: return 0.17
        case .lunge: return 0.24
        case .herz: return 0.07
        case .magen: return 0.1
        case .darm: return 0.13
        default: return 0.1
        }
    }

    /// Mittelpunkt im Puzzle.
    var center: CGPoint {
        let s = spots
        let x = s.map(\.x).reduce(0, +) / CGFloat(s.count)
        let y = s.map(\.y).reduce(0, +) / CGFloat(s.count)
        return CGPoint(x: x, y: y)
    }

    static let outer: [BodyPart] = [.kopf, .bauch, .hand, .fuss, .arm, .bein, .knie]
    static let face: [BodyPart] = [.augen, .ohren, .nase, .mund]
    static let organs: [BodyPart] = [.gehirn, .herz, .lunge, .magen, .darm]
    static let bones: [BodyPart] = [.schaedel, .rippen, .wirbelsaeule, .oberschenkel]

    /// Teile, die die Zauberlupe auf einer Ebene finden kann.
    static func on(_ layer: BodyLayer) -> [BodyPart] { allCases.filter { $0.layer == layer } }
}

/// Sinnesfrage: Womit …? Antwort ist ein Sinnesorgan.
struct SenseQuestion: Codable, Equatable {
    var object: String      // Bildname-Endung
    var emoji: String
    var question: String
    var answer: BodyPart
    var explanation: String
}

enum SenseCatalog {
    static let senses: [BodyPart] = [.augen, .ohren, .nase, .mund, .hand]

    static let questions: [SenseQuestion] = [
        SenseQuestion(object: "blume", emoji: "🌸", question: "Womit riechst du an der Blume?", answer: .nase,
                      explanation: "Mit der Nase riechst du, wie gut die Blume duftet."),
        SenseQuestion(object: "kuchen", emoji: "🎂", question: "Womit riechst du den frischen Kuchen?", answer: .nase,
                      explanation: "Die Nase riecht den feinen Duft schon von weitem."),
        SenseQuestion(object: "glocke", emoji: "🔔", question: "Womit hörst du die Glocke?", answer: .ohren,
                      explanation: "Mit den Ohren hörst du, wie die Glocke klingt."),
        SenseQuestion(object: "vogel", emoji: "🐦", question: "Womit hörst du den Vogel singen?", answer: .ohren,
                      explanation: "Deine Ohren hören das Lied des Vogels."),
        SenseQuestion(object: "zitrone", emoji: "🍋", question: "Womit schmeckst du die saure Zitrone?", answer: .mund,
                      explanation: "Mit der Zunge im Mund schmeckst du, dass die Zitrone sauer ist."),
        SenseQuestion(object: "eis", emoji: "🍦", question: "Womit schmeckst du das süsse Eis?", answer: .mund,
                      explanation: "Deine Zunge schmeckt, dass das Eis süss ist."),
        SenseQuestion(object: "regenbogen", emoji: "🌈", question: "Womit siehst du den Regenbogen?", answer: .augen,
                      explanation: "Mit den Augen siehst du die Farben des Regenbogens."),
        SenseQuestion(object: "sterne", emoji: "⭐️", question: "Womit siehst du die Sterne?", answer: .augen,
                      explanation: "Deine Augen sehen die Sterne am Himmel."),
        SenseQuestion(object: "katze", emoji: "🐱", question: "Womit fühlst du das weiche Fell?", answer: .hand,
                      explanation: "Mit der Haut an deinen Händen fühlst du, wie weich das Fell ist."),
        SenseQuestion(object: "wasser", emoji: "💧", question: "Womit spürst du, ob das Wasser warm ist?", answer: .hand,
                      explanation: "Deine Haut spürt, ob etwas warm oder kalt ist.")
    ]
}

/// Herzschlag: In welcher Lage schlägt das Herz schnell oder langsam?
struct HeartScene: Codable, Equatable {
    var image: String
    var emoji: String
    var question: String
    var fast: Bool
    var explanation: String
}

enum HeartCatalog {
    static let scenes: [HeartScene] = [
        HeartScene(image: "koerper_dino_rennen", emoji: "🏃", question: "Printatops ist ganz schnell gerannt. Welches Herz schlägt jetzt?",
                   fast: true, explanation: "Beim Rennen braucht dein Körper mehr Blut. Darum schlägt das Herz schneller."),
        HeartScene(image: "koerper_dino_huepfen", emoji: "🤸", question: "Printatops hüpft und tanzt. Welches Herz schlägt jetzt?",
                   fast: true, explanation: "Wenn du dich viel bewegst, pumpt dein Herz schneller."),
        HeartScene(image: "koerper_dino_schlafen", emoji: "😴", question: "Printatops schläft tief und fest. Welches Herz schlägt jetzt?",
                   fast: false, explanation: "Beim Schlafen ruht dein Körper aus. Darum schlägt das Herz langsam."),
        HeartScene(image: "koerper_dino_ausruhen", emoji: "📖", question: "Printatops liegt ganz ruhig da. Welches Herz schlägt jetzt?",
                   fast: false, explanation: "Wenn du ruhig bist, schlägt dein Herz langsam und gleichmässig.")
    ]
}

/// Weg des Essens: Mund, Magen, Darm.
enum FoodPath {
    static let order: [BodyPart] = [.mund, .magen, .darm]
    static let start = "Wohin wandert dein Essen? Tippe zuerst auf den Ort, wo das Essen hineinkommt."
    static let steps = [
        "Ja, zuerst kaust du das Essen im Mund. Wohin rutscht es dann?",
        "Genau, durch die Speiseröhre rutscht das Essen in den Magen. Und danach?",
        "Super, zum Schluss geht es in den langen Darm."
    ]
    static let hints = [
        "Das Essen kommt zuerst in den Mund.",
        "Nach dem Mund kommt der Magen.",
        "Nach dem Magen kommt der Darm."
    ]
}
