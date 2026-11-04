import SwiftUI

/// Bilder nur einmal laden (auch fehlende merken).
@MainActor
enum ImageCache {
    private static var cache: [String: UIImage] = [:]
    private static var missing: Set<String> = []

    static func image(_ name: String) -> UIImage? {
        if let i = cache[name] { return i }
        if missing.contains(name) || name.isEmpty { return nil }
        if let i = UIImage.app(name) {
            cache[name] = i
            return i
        }
        missing.insert(name)
        return nil
    }

    private static var trimmedCache: [String: UIImage] = [:]

    /// Bild ohne durchsichtigen Rand (für Teile, die im vollen Bauplan-Rahmen liegen).
    static func trimmed(_ name: String) -> UIImage? {
        if let i = trimmedCache[name] { return i }
        guard let img = image(name), let cg = img.cgImage else { return nil }
        let w = cg.width, h = cg.height
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = data.withUnsafeMutableBytes { buf in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return img }
        var minX = w, minY = h, maxX = -1, maxY = -1
        for y in 0..<h {
            let row = y * w
            for x in 0..<w where data[(row + x) * 4 + 3] > 8 {
                if x < minX { minX = x }
                if x > maxX { maxX = x }
                if y < minY { minY = y }
                if y > maxY { maxY = y }
            }
        }
        guard maxX >= minX, maxY >= minY else { return img }
        let pad = max(4, (maxX - minX) / 20)
        let rect = CGRect(x: max(0, minX - pad), y: max(0, minY - pad),
                          width: min(w, maxX + pad + 1) - max(0, minX - pad), height: min(h, maxY + pad + 1) - max(0, minY - pad))
        guard let cut = cg.cropping(to: rect) else { return img }
        let out = UIImage(cgImage: cut, scale: img.scale, orientation: img.imageOrientation)
        trimmedCache[name] = out
        return out
    }
}

/// Bild aus der Gartenwelt, sonst Emoji. Quadratischer Rahmen.
struct WorldPic: View {
    let asset: String
    let emoji: String
    let size: CGFloat

    init(_ asset: String, _ emoji: String, size: CGFloat) {
        self.asset = asset
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        Group {
            if let img = ImageCache.image(asset) {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                Text(emoji).font(.system(size: size * 0.62))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

extension View {
    /// Setzt ein quadratisches Bild so, dass seine Bodenlinie (92 % Höhe) auf dem Punkt steht.
    /// Setzt ein Ding mit den Füssen auf den Punkt und gibt ihm einen weichen Bodenschatten,
    /// damit es im Gras steht statt zu schweben.
    func feet(_ p: CGPoint, size: CGFloat, in s: CGSize, shadow: Bool = true) -> some View {
        self
            .background(alignment: .bottom) {
                if shadow {
                    Ellipse()
                        .fill(Color.black.opacity(0.16))
                        .frame(width: size * 0.62, height: size * 0.12)
                        .blur(radius: size * 0.025)
                        .offset(y: size * 0.03)
                        .allowsHitTesting(false)
                }
            }
            .position(x: p.x * s.width, y: p.y * s.height - size * 0.42)
    }

    func at(_ p: CGPoint, in s: CGSize) -> some View {
        position(x: p.x * s.width, y: p.y * s.height)
    }
}

/// Printatops als Helfer in der ganzen App (ersetzt das Häschen).
struct DinoHelperView: View {
    var message: String?
    var size: CGFloat = 64
    var pose = "stehen"

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            WorldPic("gw_dino_\(pose)", "🦕", size: size)
            if let message {
                Text(message)
                    .font(Theme.rounded(22, .semibold))
                    .foregroundStyle(Theme.darkGreen)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
                    )
                    .transition(.scale(scale: 0.8, anchor: .bottomLeading).combined(with: .opacity))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: message == nil)
    }
}

/// Weicher Bodenschatten unter Dingen in der Szene.
struct GroundShadow: View {
    let width: CGFloat
    var body: some View {
        Ellipse()
            .fill(.black.opacity(0.13))
            .frame(width: width, height: width * 0.2)
            .blur(radius: 2)
            .allowsHitTesting(false)
    }
}

/// Hintergrund eines Ortes (Bild oder gezeichneter Ersatz).
struct SceneBackground: View {
    let area: WorldArea
    let evening: Bool
    var extent: (min: Double, max: Double) = (0, 1)

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            ZStack {
                if extent.max - extent.min > 1 {
                    panorama(s)
                } else if let img = ImageCache.image(area.scene(evening: evening)) {
                    Image(uiImage: img).resizable().scaledToFill().frame(width: s.width, height: s.height).clipped()
                } else if evening, let img = ImageCache.image(area.scene(evening: false)) {
                    Image(uiImage: img).resizable().scaledToFill().frame(width: s.width, height: s.height).clipped()
                    Color(red: 0.08, green: 0.12, blue: 0.35).opacity(0.45).blendMode(.multiply)
                } else {
                    fallback(s)
                    if evening { Color(red: 0.08, green: 0.12, blue: 0.35).opacity(0.45).blendMode(.multiply) }
                }
            }
        }
    }

    /// Panorama: eigenes Bild; im Simulator-Test ein Ersatz aus dem Grundbild (Seiten gespiegelt).
    @ViewBuilder
    private func panorama(_ s: CGSize) -> some View {
        if let img = ImageCache.image(area.panorama(evening: evening)) ?? ImageCache.image(area.panorama(evening: false)) {
            Image(uiImage: img).resizable().scaledToFill().frame(width: s.width, height: s.height).clipped()
            if ImageCache.image(area.panorama(evening: evening)) == nil && evening {
                Color(red: 0.08, green: 0.12, blue: 0.35).opacity(0.45).blendMode(.multiply)
            }
        } else if let base = ImageCache.image(area.scene(evening: evening)) ?? ImageCache.image(area.scene(evening: false)) {
            let unit = s.width / CGFloat(extent.max - extent.min)
            HStack(spacing: 0) {
                ForEach(Int(extent.min)..<Int(extent.max), id: \.self) { i in
                    Image(uiImage: base).resizable().scaledToFill().frame(width: unit, height: s.height).clipped()
                        .scaleEffect(x: i == 0 ? 1 : -1, y: 1)
                }
            }
        } else {
            fallback(s)
        }
    }

    @ViewBuilder
    private func fallback(_ s: CGSize) -> some View {
        ZStack {
            LinearGradient(colors: area.fallbackColors, startPoint: .top, endPoint: .bottom)
            switch area {
            case .haus:
                RoundedRectangle(cornerRadius: 24).fill(Color(red: 0.86, green: 0.72, blue: 0.55))
                    .frame(width: s.width * 0.2, height: s.height * 0.18).position(x: s.width * 0.86, y: s.height * 0.3)
                Text("🏡").font(.system(size: s.width * 0.12)).position(x: s.width * 0.88, y: s.height * 0.22)
                Capsule().fill(Theme.creamDark).frame(width: s.width * 0.08, height: s.height * 0.5)
                    .rotationEffect(.degrees(-25)).position(x: s.width * 0.72, y: s.height * 0.8)
                Text("🌳").font(.system(size: s.width * 0.08)).position(x: s.width * 0.04, y: s.height * 0.3)
            case .bach:
                Ellipse().fill(Theme.lightBlue).frame(width: s.width * 0.22, height: s.height * 0.22).position(x: s.width * 0.88, y: s.height * 0.86)
                Capsule().fill(Theme.lightBlue).frame(width: s.width * 0.9, height: s.height * 0.05).position(x: s.width * 0.5, y: s.height * 0.17)
            case .lichtung:
                ForEach(0..<6, id: \.self) { i in
                    Text("🌲").font(.system(size: s.width * 0.08)).position(x: s.width * (0.05 + 0.18 * Double(i)), y: s.height * 0.2)
                }
                Text("🪵").font(.system(size: s.width * 0.07)).position(x: s.width * 0.14, y: s.height * 0.5)
            case .baumhaus:
                Text("🌳").font(.system(size: s.width * 0.4)).position(x: s.width * 0.55, y: s.height * 0.4)
            case .wunder:
                ForEach(0..<14, id: \.self) { i in
                    Text(["✨", "🍄", "💎", "🌟"][i % 4]).font(.system(size: s.width * 0.035))
                        .position(x: s.width * (0.05 + 0.067 * Double(i)), y: s.height * (0.15 + 0.25 * Double(i % 3)))
                        .opacity(0.6)
                }
            }
        }
    }
}

/// Gebautes Objekt mit Bemalung (Grundbild + eingefärbte Masken + Muster).
struct BuiltObjectView: View {
    let kind: BuildKind
    var roof: WorldColor = .rot
    var bodyColor: WorldColor = .natur
    var pattern: WorldPattern = .keins
    var decoration: FindItem?
    var glitter: BuildGlitter?
    let size: CGFloat

    var body: some View {
        ZStack {
            if let base = ImageCache.image(kind.displayAsset) {
                Image(uiImage: base).resizable().scaledToFit()
                if let m = ImageCache.image(kind.maskBody) {
                    Image(uiImage: m).resizable().scaledToFit().colorMultiply(bodyColor.color).blendMode(.multiply)
                    if pattern != .keins {
                        // Gezeichnet statt Kachelbild: Grösse passt sich dem Bauwerk an.
                        DrawnPattern(pattern: pattern, size: size)
                            .mask(Image(uiImage: m).resizable().scaledToFit())
                    }
                }
                if let m = ImageCache.image(kind.maskRoof) {
                    Image(uiImage: m).resizable().scaledToFit().colorMultiply(roof.color).blendMode(.multiply)
                }
            } else {
                // Ersatz: Farbfelder mit Symbol
                VStack(spacing: 0) {
                    Triangle().fill(roof.color).frame(width: size * 0.7, height: size * 0.22)
                    RoundedRectangle(cornerRadius: size * 0.08)
                        .fill(bodyColor.color)
                        .frame(width: size * 0.6, height: size * 0.42)
                        .overlay(Text(pattern == .keins ? kind.emoji : pattern.symbol).font(.system(size: size * 0.2)).foregroundStyle(.white))
                }
                .frame(width: size, height: size, alignment: .bottom)
                .padding(.bottom, size * 0.08)
            }
            if let glitter, let base = ImageCache.image(kind.displayAsset) {
                BuildSparkles(glitter: glitter, size: size)
                    .mask(Image(uiImage: base).resizable().scaledToFit())
                    .allowsHitTesting(false)
            }
            if let decoration {
                WorldPic(decoration.asset, decoration.emoji, size: size * 0.22)
                    .offset(x: size * 0.22, y: size * 0.1)
            }
        }
        .frame(width: size, height: size)
    }
}

/// Funkelnde Pünktchen für Glitzer-Bauwerke (feste Positionen, sanftes Blinken).
struct BuildSparkles: View {
    let glitter: BuildGlitter
    let size: CGFloat

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12)) { tl in
            Canvas { ctx, sz in
                let t = tl.date.timeIntervalSinceReferenceDate
                let colors = glitter.sparkleColors
                for i in 0..<70 {
                    // Pseudo-zufällig, aber bei jedem Zeichnen gleich
                    let x = Double((i * 7919) % 1000) / 1000 * sz.width
                    let y = Double((i * 104_729) % 1000) / 1000 * sz.height
                    let o = 0.25 + 0.75 * (0.5 + 0.5 * sin(t * 3 + Double(i) * 1.7))
                    let r = (i % 4 == 0 ? 2.6 : 1.5) * Double(size) / 200
                    ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                             with: .color(colors[i % colors.count].opacity(o)))
                    if i % 6 == 0 && o > 0.85 {
                        var cross = Path()
                        cross.move(to: CGPoint(x: x - r * 3, y: y)); cross.addLine(to: CGPoint(x: x + r * 3, y: y))
                        cross.move(to: CGPoint(x: x, y: y - r * 3)); cross.addLine(to: CGPoint(x: x, y: y + r * 3))
                        ctx.stroke(cross, with: .color(.white.opacity(o)), lineWidth: 1)
                    }
                }
            }
        }
    }
}

/// Muster auf Bauwerken, passend zur Grösse gezeichnet (etwa neun Motive über die Breite),
/// versetzt angeordnet und halb durchscheinend, damit sie zur Farbe darunter passen.
struct DrawnPattern: View {
    let pattern: WorldPattern
    let size: CGFloat

    var body: some View {
        Canvas { ctx, sz in
            let step = max(size / 9, 5)
            let ink = Color.white.opacity(0.62)
            switch pattern {
            case .keins:
                break
            case .regenbogen:
                let bands = Glitter.rainbowBands
                let h = step * 0.9
                var y: CGFloat = 0, i = 0
                while y < sz.height {
                    let c = bands[i % bands.count]
                    ctx.fill(Path(CGRect(x: 0, y: y, width: sz.width, height: h)),
                             with: .color(Color(red: c.0, green: c.1, blue: c.2).opacity(0.7)))
                    y += h; i += 1
                }
            case .streifen:
                var p = Path()
                var x = -sz.height
                while x < sz.width {
                    p.move(to: CGPoint(x: x, y: sz.height)); p.addLine(to: CGPoint(x: x + sz.height, y: 0))
                    x += step
                }
                ctx.stroke(p, with: .color(ink), lineWidth: step * 0.3)
            case .karos:
                var y: CGFloat = 0, row = 0
                while y < sz.height {
                    var x: CGFloat = row % 2 == 0 ? 0 : step
                    while x < sz.width {
                        ctx.fill(Path(CGRect(x: x, y: y, width: step, height: step)), with: .color(Color.white.opacity(0.4)))
                        x += step * 2
                    }
                    y += step; row += 1
                }
            default:
                let symbol: String
                switch pattern {
                case .herzen: symbol = "heart.fill"
                case .sterne: symbol = "star.fill"
                case .blumen: symbol = "camera.macro"
                default: symbol = "circle.fill"
                }
                var motif = ctx.resolve(Image(systemName: symbol))
                motif.shading = .color(.white)
                let d = step * (pattern == .punkte ? 0.45 : 0.6)
                var y = step / 2, row = 0
                while y < sz.height + step {
                    var x = row % 2 == 0 ? step / 2 : step
                    while x < sz.width + step {
                        var c = ctx
                        c.opacity = 0.62
                        c.draw(motif, in: CGRect(x: x - d / 2, y: y - d / 2, width: d, height: d))
                        x += step
                    }
                    y += step * 0.9; row += 1
                }
            }
        }
        .foregroundStyle(.white)
    }
}

struct BuiltObjectImage: View {
    let obj: BuiltObject
    let size: CGFloat
    var body: some View {
        BuiltObjectView(kind: obj.kind, roof: obj.roof, bodyColor: obj.body, pattern: obj.pattern, decoration: obj.decoration, glitter: obj.glitter, size: size)
    }
}

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Leuchtende Stelle eines Abenteuers.
struct HotspotView: View {
    let asset: String
    let emoji: String
    let size: CGFloat
    var dashed = false
    var progress: (Int, Int)?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 20)) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            let pulse = 0.5 + 0.5 * sin(t * 3)
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.highlight.opacity(0.65), Theme.highlight.opacity(0)], center: .center, startRadius: 2, endRadius: size * 0.7))
                    .frame(width: size * (1.3 + 0.15 * pulse), height: size * (1.3 + 0.15 * pulse))
                if dashed {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .stroke(style: StrokeStyle(lineWidth: 4, dash: [10, 8]))
                        .foregroundStyle(.white)
                        .frame(width: size, height: size)
                    WorldPic(asset, emoji, size: size * 0.8).opacity(0.45)
                    Image(systemName: "hammer.fill").font(.system(size: size * 0.25)).foregroundStyle(Theme.darkGreen)
                        .padding(8).background(Circle().fill(.white)).offset(x: size * 0.4, y: -size * 0.4)
                } else {
                    WorldPic(asset, emoji, size: size)
                        .offset(y: -4 * pulse)
                }
                if let prog = progress {
                    HStack(spacing: 6) {
                        ForEach(0..<prog.1, id: \.self) { i in
                            Circle().fill(i < prog.0 ? Theme.success : .white).frame(width: 14, height: 14)
                                .overlay(Circle().stroke(Theme.darkGreen, lineWidth: 2))
                        }
                    }
                    .offset(y: size * 0.65)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

/// Regen, Glühwürmchen und Regenbogen.
struct WeatherLayer: View {
    let raining: Bool
    let rainbow: Bool
    let evening: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !(raining || evening))) { tl in
            let t = tl.date.timeIntervalSinceReferenceDate
            Canvas { ctx, s in
                if raining {
                    for i in 0..<90 {
                        let x = (Double(i * 73 % 100) / 100) * s.width
                        let speed = 500 + Double(i % 7) * 40
                        let y = (t * speed + Double(i * 37)).truncatingRemainder(dividingBy: s.height + 40) - 20
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: y))
                        p.addLine(to: CGPoint(x: x - 3, y: y + 14))
                        ctx.stroke(p, with: .color(.white.opacity(0.7)), lineWidth: 2)
                    }
                }
                if evening {
                    for i in 0..<22 {
                        let bx = Double(i * 47 % 100) / 100 * s.width
                        let by = (0.35 + Double(i * 29 % 50) / 100) * s.height
                        let x = bx + sin(t * 0.7 + Double(i)) * 18
                        let y = by + cos(t * 0.9 + Double(i) * 1.7) * 12
                        let o = 0.4 + 0.6 * (0.5 + 0.5 * sin(t * 2 + Double(i)))
                        ctx.fill(Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8)), with: .color(Color(red: 1, green: 0.95, blue: 0.5).opacity(o)))
                    }
                }
            }
        }
        .overlay {
            if rainbow {
                GeometryReader { g in
                    ZStack {
                        ForEach(0..<6, id: \.self) { i in
                            Circle()
                                .trim(from: 0.5, to: 1)
                                .stroke([Palette.red, .orange, .yellow, .green, .blue, .purple][i].color.opacity(0.45), lineWidth: 14)
                                .frame(width: g.size.width * 0.8 - CGFloat(i) * 28, height: g.size.width * 0.8 - CGFloat(i) * 28)
                        }
                    }
                    .position(x: g.size.width * 0.5, y: g.size.height * 0.75)
                }
                .transition(.opacity)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Runder Knopf in der Gartenleiste (Bild oder SF-Symbol).
struct WorldRoundButton: View {
    var asset: String = ""
    var symbol: String
    var label: String
    var active = false
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if let img = ImageCache.image(asset) {
                    Image(uiImage: img).resizable().scaledToFit().padding(6)
                } else {
                    Image(systemName: symbol).font(.system(size: 26, weight: .bold))
                        .foregroundStyle(active ? .white : Theme.darkGreen)
                }
            }
            .frame(width: 60, height: 60)
            .background(Circle().fill(active ? Theme.darkGreen : .white).shadow(color: .black.opacity(0.15), radius: 4, y: 2))
            .overlay(alignment: .topTrailing) {
                if badge > 0 {
                    Text("\(badge)").font(Theme.rounded(14, .heavy)).foregroundStyle(.white)
                        .padding(5).background(Circle().fill(Theme.gentleRed)).offset(x: 6, y: -6)
                }
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }
}

/// Grosse Karte für Auswahl (Samen, Gerichte, Bausätze …).
struct WorldCard: View {
    let asset: String
    let emoji: String
    let title: String
    var subtitle: String = ""
    var selected = false
    var disabled = false
    var size: CGFloat = 120

    var body: some View {
        VStack(spacing: 6) {
            WorldPic(asset, emoji, size: size * 0.62)
            Text(title).font(Theme.rounded(17, .bold)).foregroundStyle(Theme.darkGreen)
                .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.7)
            if !subtitle.isEmpty {
                Text(subtitle).font(Theme.rounded(13, .medium)).foregroundStyle(Theme.darkGreen.opacity(0.7))
                    .lineLimit(2).multilineTextAlignment(.center).minimumScaleFactor(0.7)
            }
        }
        .padding(10)
        .frame(width: size, height: size * 1.3)
        .background(RoundedRectangle(cornerRadius: 22).fill(selected ? Theme.lightYellow : .white).shadow(color: .black.opacity(0.1), radius: 5, y: 2))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(Theme.highlight, lineWidth: selected ? 5 : 0))
        .opacity(disabled ? 0.45 : 1)
    }
}

/// Weisse Tafel für Überlagerungen (Küche, Werkstatt …).
struct WorldPanel<Content: View>: View {
    let title: String
    var background: String = ""
    let close: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack {
            if let img = ImageCache.image(background) {
                Image(uiImage: img).resizable().scaledToFill().ignoresSafeArea().opacity(0.95)
            } else {
                Theme.cream.ignoresSafeArea()
            }
            VStack(spacing: 12) {
                HStack {
                    CircleIconButton(systemName: "xmark", label: "Zurück in den Garten") { close() }
                    Text(title).font(Theme.rounded(32, .heavy)).foregroundStyle(Theme.darkGreen)
                        .padding(.horizontal, 16).padding(.vertical, 6)
                        .background(Capsule().fill(.white.opacity(0.85)))
                    Spacer()
                }
                .padding(.horizontal, 24)
                content()
            }
            .padding(.vertical, 16)
        }
    }
}
