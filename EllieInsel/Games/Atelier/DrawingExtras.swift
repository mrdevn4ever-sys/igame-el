import SwiftUI
import PencilKit

// MARK: - Farben

/// Glitzerfarben: ein eigener Grundton für den Strich, darüber funkelnde Pünktchen.
/// Die Grundtöne sind bewusst eigene Werte, damit Glitzerstriche in der Zeichnung erkennbar bleiben.
enum Glitter: String, CaseIterable, Codable {
    // Reihenfolge wie in der Leiste: Regenbogenfarben, dann Rosa/Pink, dann Metallisches
    case rot, orange, gelb, gruen, tuerkis, blau, lila, rosa, pink, gold, silber, rosegold, perlmutt, regenbogen

    var name: String {
        switch self {
        case .gold: return "Goldglitzer"
        case .orange: return "Orangeglitzer"
        case .gelb: return "Gelbglitzer"
        case .silber: return "Silberglitzer"
        case .rosa: return "Rosaglitzer"
        case .pink: return "Pinkglitzer"
        case .rosegold: return "Rosegoldglitzer"
        case .rot: return "Rotglitzer"
        case .lila: return "Lilaglitzer"
        case .blau: return "Blauglitzer"
        case .tuerkis: return "Türkisglitzer"
        case .gruen: return "Grünglitzer"
        case .regenbogen: return "Regenbogenglitzer"
        case .perlmutt: return "Perlmuttglitzer"
        }
    }

    var rgb: (Double, Double, Double) {
        switch self {
        case .gold: return (0.851, 0.647, 0.129)
        case .orange: return (0.973, 0.494, 0.071)
        case .gelb: return (0.988, 0.886, 0.098)
        case .silber: return (0.702, 0.722, 0.769)
        case .rosa: return (0.957, 0.612, 0.788)
        case .pink: return (0.871, 0.161, 0.553)
        case .rosegold: return (0.827, 0.537, 0.494)
        case .rot: return (0.776, 0.067, 0.188)
        case .lila: return (0.541, 0.290, 0.871)
        case .blau: return (0.176, 0.369, 0.894)
        case .tuerkis: return (0.098, 0.737, 0.757)
        case .gruen: return (0.176, 0.659, 0.333)
        case .regenbogen: return (0.886, 0.812, 0.965)
        case .perlmutt: return (0.937, 0.918, 0.961)
        }
    }

    var uiColor: UIColor { UIColor(red: rgb.0, green: rgb.1, blue: rgb.2, alpha: 1) }
    var color: Color { Color(red: rgb.0, green: rgb.1, blue: rgb.2) }

    private var light: Color {
        Color(red: rgb.0 + (1 - rgb.0) * 0.65, green: rgb.1 + (1 - rgb.1) * 0.65, blue: rgb.2 + (1 - rgb.2) * 0.65)
    }

    /// Farben der Funken.
    var sparkleColors: [Color] {
        switch self {
        case .regenbogen:
            return [Palette.red, .orange, .yellow, .green, .blue, .purple].map(\.color) + [.white]
        case .perlmutt:
            return [.white, Color(red: 1, green: 0.8, blue: 0.9), Color(red: 0.8, green: 0.9, blue: 1), Color(red: 0.85, green: 1, blue: 0.9)]
        case .gold:
            return [.white, Color(red: 1, green: 0.93, blue: 0.6), light]
        default:
            return [.white, .white, light]
        }
    }

    /// Erkennt einen Glitzerstrich an seiner Farbe.
    static func match(_ c: UIColor) -> Glitter? {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard c.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        return allCases.first {
            abs(Double(r) - $0.rgb.0) < 0.012 && abs(Double(g) - $0.rgb.1) < 0.012 && abs(Double(b) - $0.rgb.2) < 0.012
        }
    }
}

/// Gewählte Farbe beim freien Malen.
enum InkChoice: Equatable {
    case plain(Palette)
    case glitter(Glitter)

    var uiColor: UIColor {
        switch self {
        case .plain(let p): return p.uiColor
        case .glitter(let g): return g.uiColor
        }
    }

    var name: String {
        switch self {
        case .plain(let p): return p.name
        case .glitter(let g): return g.name
        }
    }
}

/// Farbtupfer in der Werkzeugleiste. Der Auswahlring liegt innerhalb des Feldes und wird nie abgeschnitten.
struct InkSwatch: View {
    let ink: InkChoice
    let selected: Bool

    var body: some View {
        ZStack {
            switch ink {
            case .plain(let p):
                Circle().fill(p.color).frame(width: 42, height: 42)
            case .glitter(let g):
                Group {
                    if g == .regenbogen {
                        Circle().fill(AngularGradient(colors: [Palette.red, .orange, .yellow, .green, .blue, .purple, .red].map(\.color), center: .center))
                    } else {
                        Circle().fill(RadialGradient(colors: [g.color.opacity(0.75), g.color], center: .topLeading, startRadius: 2, endRadius: 40))
                    }
                }
                .frame(width: 42, height: 42)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 1)
                )
            }
            Circle()
                .stroke(Theme.darkGreen, lineWidth: selected ? 4 : 0)
                .frame(width: 52, height: 52)
        }
        .frame(width: 56, height: 56)
        .contentShape(Rectangle())
    }
}

// MARK: - Füllen

enum FloodFill {
    struct Run {
        var y: CGFloat
        var x0: CGFloat
        var x1: CGFloat
    }

    /// Bestimmt die zusammenhängende Fläche am Punkt (begrenzt durch gemalte Linien und den Rand)
    /// und liefert sie als waagrechte Streifen.
    static func runs(drawing: PKDrawing, size: CGSize, at point: CGPoint, step: Int = 3) -> [Run] {
        let w = Int(size.width.rounded()), h = Int(size.height.rounded())
        let px = Int(point.x), py = Int(point.y)
        guard w > 10, h > 10, px >= 0, py >= 0, px < w, py < h else { return [] }

        var image = UIImage()
        UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
            image = drawing.image(from: CGRect(x: 0, y: 0, width: CGFloat(w), height: CGFloat(h)), scale: 1)
        }
        var buf = [UInt8](repeating: 0, count: w * h * 4)
        if let cg = image.cgImage {
            buf.withUnsafeMutableBytes { raw in
                guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
                ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            }
        }

        let seed = (py * w + px) * 4
        let seedEmpty = buf[seed + 3] < 100
        let r0 = Int(buf[seed]), g0 = Int(buf[seed + 1]), b0 = Int(buf[seed + 2])

        func inside(_ i: Int) -> Bool {
            let a = buf[i * 4 + 3]
            if seedEmpty { return a < 100 }
            guard a >= 100 else { return false }
            let d = abs(Int(buf[i * 4]) - r0) + abs(Int(buf[i * 4 + 1]) - g0) + abs(Int(buf[i * 4 + 2]) - b0)
            return d < 70
        }

        // Zeilenweises Füllen
        var mask = [Bool](repeating: false, count: w * h)
        var stack = [py * w + px]
        while let i = stack.popLast() {
            if mask[i] || !inside(i) { continue }
            let y = i / w
            var x0 = i % w, x1 = x0
            while x0 > 0, !mask[y * w + x0 - 1], inside(y * w + x0 - 1) { x0 -= 1 }
            while x1 < w - 1, !mask[y * w + x1 + 1], inside(y * w + x1 + 1) { x1 += 1 }
            for x in x0...x1 {
                mask[y * w + x] = true
                if y > 0 {
                    let j = (y - 1) * w + x
                    if !mask[j] && inside(j) { stack.append(j) }
                }
                if y < h - 1 {
                    let j = (y + 1) * w + x
                    if !mask[j] && inside(j) { stack.append(j) }
                }
            }
        }

        // Streifen: pro Band von `step` Zeilen alle Stellen, die irgendwo im Band zur Fläche gehören
        var runs: [Run] = []
        var y = 0
        while y < h {
            let band = y..<min(y + step, h)
            var x = 0
            while x < w {
                if band.contains(where: { mask[$0 * w + x] }) {
                    let start = x
                    while x + 1 < w, band.contains(where: { mask[$0 * w + x + 1] }) { x += 1 }
                    runs.append(Run(y: CGFloat(band.lowerBound) + CGFloat(band.count) / 2, x0: CGFloat(start), x1: CGFloat(x) + 1))
                }
                x += 1
            }
            y += step
        }
        return runs
    }

    /// Streifen als gleichmässig breite Striche (liegen über der Zeichnung und bleiben bearbeitbar).
    static func strokes(_ runs: [Run], color: UIColor, step: Int = 3) -> [PKStroke] {
        let width = CGFloat(step) + 1.6
        let ink = PKInk(.monoline, color: color)
        return runs.map { r in
            let x0 = r.x0 - 1, x1 = r.x1 + 1
            let n = max(2, Int((x1 - x0) / 30) + 2)
            let points = (0..<n).map { k -> PKStrokePoint in
                let t = CGFloat(k) / CGFloat(n - 1)
                return PKStrokePoint(location: CGPoint(x: x0 + (x1 - x0) * t, y: r.y), timeOffset: TimeInterval(t) * 0.1,
                                     size: CGSize(width: width, height: width), opacity: 1, force: 1, azimuth: 0, altitude: .pi / 2)
            }
            return PKStroke(ink: ink, path: PKStrokePath(controlPoints: points, creationDate: Date()))
        }
    }
}

// MARK: - Glitzer

struct Sparkle {
    var p: CGPoint
    var r: CGFloat
    var phase: Double
    var color: Color
    var star: Bool
}

enum GlitterField {
    /// Funken entlang aller Glitzerstriche (gleich bleibend, damit nichts springt).
    static func sparkles(for drawing: PKDrawing, limit: Int = 4000) -> [Sparkle] {
        var out: [Sparkle] = []
        var rng = SeededGenerator(seed: 4711)
        for stroke in drawing.strokes {
            guard let g = Glitter.match(stroke.ink.color) else { continue }
            let colors = g.sparkleColors
            for pt in stroke.path.interpolatedPoints(by: .distance(6)) {
                let width = max(pt.size.width, 3)
                let expected = 6 * width / 45
                var n = Int(expected)
                if Double.random(in: 0..<1, using: &rng) < expected - Double(n) { n += 1 }
                guard n > 0 else { continue }
                let center = pt.location.applying(stroke.transform)
                for _ in 0..<n {
                    let dx = CGFloat.random(in: -0.45...0.45, using: &rng) * width
                    let dy = CGFloat.random(in: -0.45...0.45, using: &rng) * width
                    out.append(Sparkle(
                        p: CGPoint(x: center.x + dx, y: center.y + dy),
                        r: CGFloat.random(in: 1.0...2.6, using: &rng),
                        phase: Double.random(in: 0..<(2 * .pi), using: &rng),
                        color: colors.randomElement(using: &rng) ?? .white,
                        star: Int.random(in: 0..<9, using: &rng) == 0
                    ))
                    if out.count >= limit { return out }
                }
            }
        }
        return out
    }
}

/// Zeichnet die Funken für einen Zeitpunkt.
struct GlitterCanvas: View {
    let sparkles: [Sparkle]
    let time: Double

    var body: some View {
        Canvas { ctx, _ in
            for s in sparkles {
                let o = 0.3 + 0.7 * (0.5 + 0.5 * sin(time * 3.2 + s.phase))
                ctx.fill(Path(ellipseIn: CGRect(x: s.p.x - s.r, y: s.p.y - s.r, width: s.r * 2, height: s.r * 2)),
                         with: .color(s.color.opacity(o)))
                if s.star && o > 0.8 {
                    let l = s.r * 3.2
                    var cross = Path()
                    cross.move(to: CGPoint(x: s.p.x - l, y: s.p.y))
                    cross.addLine(to: CGPoint(x: s.p.x + l, y: s.p.y))
                    cross.move(to: CGPoint(x: s.p.x, y: s.p.y - l))
                    cross.addLine(to: CGPoint(x: s.p.x, y: s.p.y + l))
                    ctx.stroke(cross, with: .color(.white.opacity(o)), lineWidth: 1.2)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

/// Funkelnde Ebene über der Zeichenfläche.
struct GlitterOverlay: View {
    let sparkles: [Sparkle]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12, paused: sparkles.isEmpty)) { context in
            GlitterCanvas(sparkles: sparkles, time: context.date.timeIntervalSinceReferenceDate)
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Sticker

struct PlacedSticker: Codable, Equatable, Identifiable {
    var id = UUID()
    /// Bildname (z. B. garten_stern) oder Emoji
    var sticker: String
    /// Mittelpunkt relativ zur Zeichenfläche (0…1)
    var x: Double
    var y: Double
    /// Grösse relativ zur Breite der Zeichenfläche
    var size: Double
}

enum StickerCatalog {
    static let images = [
        "garten_stern", "garten_regenbogen", "garten_schmetterling", "garten_marienkaefer", "garten_ballon", "garten_drachen",
        "garten_rose", "garten_tulpe", "garten_sonnenblume", "garten_hibiskus", "garten_gaensebluemchen", "memory_kirschbluete",
        "garten_erdbeere", "garten_kirschen", "garten_apfel", "garten_hase", "garten_katze", "garten_hund", "garten_igel",
        "garten_fuchs", "garten_eule", "garten_ente", "garten_schwan", "garten_frosch", "garten_schnecke", "garten_biene",
        "garten_eichhoernchen", "garten_reh", "garten_schaf", "memory_pferd", "memory_baer", "memory_otter", "memory_fisch",
        "memory_seestern", "memory_muschel", "memory_libelle", "memory_seerose", "garten_haus", "garten_palme", "garten_baum",
        "garten_tanne", "garten_pilz", "garten_vogel", "garten_nest"
    ]
    static let emojis = ["⭐️", "🌟", "❤️", "💖", "🌈", "🦄", "👑", "🎀", "🌸", "🦋", "☀️", "🌙", "🍭", "🧁", "🎈", "🍦", "💎", "🎁"]
    static let all = images + emojis
    /// Grössen relativ zur Bildbreite: klein, mittel, gross
    static let sizes: [Double] = [0.09, 0.14, 0.22]
}

struct StickerView: View {
    let sticker: String
    let size: CGFloat

    var body: some View {
        Group {
            if let image = UIImage(named: sticker) {
                Image(uiImage: image).resizable().scaledToFit()
            } else {
                Text(sticker).font(.system(size: size * 0.78)).fixedSize()
            }
        }
        .frame(width: size, height: size)
    }
}

/// Unbewegliche Stickerebene (für Vorschaubilder).
struct StickerLayer: View {
    let stickers: [PlacedSticker]
    let size: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
            ForEach(stickers) { s in
                StickerView(sticker: s.sticker, size: s.size * size.width)
                    .position(x: s.x * size.width, y: s.y * size.height)
            }
        }
        .frame(width: size.width, height: size.height)
    }
}
