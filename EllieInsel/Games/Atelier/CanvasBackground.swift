import SwiftUI

/// Hintergründe für das freie Malen. Die ersten sechs gibt es immer, die übrigen sind Atelier-Schätze.
enum CanvasBackground: String, CaseIterable, Codable {
    case leer, wiese, himmel, meer, wald, strand
    case nacht, schnee, regenbogen

    /// Immer verfügbar, ohne Schatz.
    static let basic: [CanvasBackground] = [.leer, .wiese, .himmel, .meer, .wald, .strand]

    var title: String {
        switch self {
        case .leer: return "Leer"
        case .wiese: return "Wiese"
        case .himmel: return "Himmel"
        case .meer: return "Meer"
        case .wald: return "Wald"
        case .strand: return "Strand"
        case .nacht: return "Nachthimmel"
        case .schnee: return "Schnee"
        case .regenbogen: return "Regenbogen"
        }
    }

    var icon: String {
        switch self {
        case .leer: return "⬜️"
        case .wiese: return "🌼"
        case .himmel: return "☁️"
        case .meer: return "🌊"
        case .wald: return "🌲"
        case .strand: return "🏖️"
        case .nacht: return "🌙"
        case .schnee: return "⛄️"
        case .regenbogen: return "🌈"
        }
    }
}

struct CanvasBackgroundView: View {
    let background: CanvasBackground

    var body: some View {
        GeometryReader { geo in
            ZStack {
                switch background {
                case .leer:
                    Color.white
                case .wiese:
                    VStack(spacing: 0) {
                        Color(red: 0.86, green: 0.94, blue: 0.99)
                        Color(red: 0.72, green: 0.88, blue: 0.62).frame(height: geo.size.height * 0.35)
                    }
                case .himmel:
                    LinearGradient(colors: [Color(red: 0.70, green: 0.86, blue: 0.98), .white], startPoint: .top, endPoint: .bottom)
                    Text("☁️").font(.system(size: 90)).opacity(0.5).position(x: geo.size.width * 0.2, y: geo.size.height * 0.2)
                    Text("☁️").font(.system(size: 70)).opacity(0.5).position(x: geo.size.width * 0.75, y: geo.size.height * 0.3)
                case .meer:
                    VStack(spacing: 0) {
                        Color(red: 0.86, green: 0.94, blue: 0.99)
                        LinearGradient(colors: [Color(red: 0.55, green: 0.80, blue: 0.95), Color(red: 0.30, green: 0.58, blue: 0.85)], startPoint: .top, endPoint: .bottom)
                            .frame(height: geo.size.height * 0.5)
                    }
                case .wald:
                    VStack(spacing: 0) {
                        Color(red: 0.88, green: 0.95, blue: 0.90)
                        Color(red: 0.55, green: 0.75, blue: 0.52).frame(height: geo.size.height * 0.25)
                    }
                    Text("🌲").font(.system(size: 120)).opacity(0.35).position(x: geo.size.width * 0.1, y: geo.size.height * 0.68)
                    Text("🌲").font(.system(size: 100)).opacity(0.35).position(x: geo.size.width * 0.9, y: geo.size.height * 0.7)
                case .strand:
                    VStack(spacing: 0) {
                        Color(red: 0.86, green: 0.94, blue: 0.99)
                        Color(red: 0.55, green: 0.80, blue: 0.95).frame(height: geo.size.height * 0.2)
                        Color(red: 0.98, green: 0.90, blue: 0.70).frame(height: geo.size.height * 0.3)
                    }
                case .nacht:
                    LinearGradient(colors: [Color(red: 0.10, green: 0.13, blue: 0.35), Color(red: 0.27, green: 0.22, blue: 0.52)], startPoint: .top, endPoint: .bottom)
                    ForEach(0..<14, id: \.self) { i in
                        // Feste Sternpositionen, damit das Bild bei jedem Zeichnen gleich aussieht
                        let x = Double((i * 37 + 11) % 100) / 100
                        let y = Double((i * 53 + 7) % 60) / 100
                        Text(i % 3 == 0 ? "✨" : "⭐️")
                            .font(.system(size: CGFloat(14 + (i * 7) % 16)))
                            .opacity(0.8)
                            .position(x: geo.size.width * x, y: geo.size.height * y)
                    }
                    Text("🌙").font(.system(size: 80)).position(x: geo.size.width * 0.85, y: geo.size.height * 0.16)
                case .schnee:
                    VStack(spacing: 0) {
                        LinearGradient(colors: [Color(red: 0.80, green: 0.90, blue: 0.98), Color(red: 0.93, green: 0.96, blue: 1.0)], startPoint: .top, endPoint: .bottom)
                        Color.white.frame(height: geo.size.height * 0.3)
                    }
                    ForEach(0..<12, id: \.self) { i in
                        Text("❄️")
                            .font(.system(size: CGFloat(14 + (i * 5) % 14)))
                            .opacity(0.55)
                            .position(x: geo.size.width * Double((i * 41 + 5) % 100) / 100,
                                      y: geo.size.height * Double((i * 29 + 9) % 65) / 100)
                    }
                case .regenbogen:
                    Color(red: 0.97, green: 0.98, blue: 1.0)
                    ForEach(0..<6, id: \.self) { i in
                        let c = Glitter.rainbowBands[i]
                        Circle()
                            .stroke(Color(red: c.0, green: c.1, blue: c.2).opacity(0.35), lineWidth: geo.size.width * 0.035)
                            .frame(width: geo.size.width * (1.1 - Double(i) * 0.07), height: geo.size.width * (1.1 - Double(i) * 0.07))
                            .position(x: geo.size.width / 2, y: geo.size.height * 1.05)
                    }
                }
            }
        }
    }
}
