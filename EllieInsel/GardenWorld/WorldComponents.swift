import SwiftUI

/// Bilder nur einmal laden (auch fehlende merken).
@MainActor
enum ImageCache {
    private static var cache: [String: UIImage] = [:]
    private static var missing: Set<String> = []

    static func image(_ name: String) -> UIImage? {
        if let i = cache[name] { return i }
        if missing.contains(name) || name.isEmpty { return nil }
        if let i = UIImage(named: name) {
            cache[name] = i
            return i
        }
        missing.insert(name)
        return nil
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
    func feet(_ p: CGPoint, size: CGFloat, in s: CGSize) -> some View {
        position(x: p.x * s.width, y: p.y * s.height - size * 0.42)
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

    var body: some View {
        GeometryReader { geo in
            let s = geo.size
            ZStack {
                if let img = ImageCache.image(area.scene(evening: evening)) {
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
    let size: CGFloat

    var body: some View {
        ZStack {
            if let base = ImageCache.image(kind.displayAsset) {
                Image(uiImage: base).resizable().scaledToFit()
                if let m = ImageCache.image(kind.maskBody) {
                    Image(uiImage: m).resizable().scaledToFit().colorMultiply(bodyColor.color).blendMode(.multiply)
                    if pattern != .keins, let p = ImageCache.image(pattern.asset) {
                        Image(uiImage: p).resizable(resizingMode: .tile)
                            .mask(Image(uiImage: m).resizable().scaledToFit())
                            .opacity(0.85)
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
            if let decoration {
                WorldPic(decoration.asset, decoration.emoji, size: size * 0.22)
                    .offset(x: size * 0.22, y: size * 0.1)
            }
        }
        .frame(width: size, height: size)
    }
}

struct BuiltObjectImage: View {
    let obj: BuiltObject
    let size: CGFloat
    var body: some View {
        BuiltObjectView(kind: obj.kind, roof: obj.roof, bodyColor: obj.body, pattern: obj.pattern, decoration: obj.decoration, size: size)
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
