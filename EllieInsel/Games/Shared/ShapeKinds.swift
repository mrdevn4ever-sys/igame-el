import SwiftUI

enum ShapeKind: String, Codable, CaseIterable {
    case circle, square, triangle, rectangle, oval, star

    var name: String {
        switch self {
        case .circle: return "Kreis"
        case .square: return "Quadrat"
        case .triangle: return "Dreieck"
        case .rectangle: return "Rechteck"
        case .oval: return "Oval"
        case .star: return "Stern"
        }
    }

    var article: String {
        switch self {
        case .circle, .star: return "der"
        case .square, .triangle, .rectangle, .oval: return "das"
        }
    }

    /// Seitenverhältnis Breite/Höhe.
    var aspect: CGFloat {
        switch self {
        case .rectangle, .oval: return 1.6
        default: return 1
        }
    }

    var path: AnyShape {
        switch self {
        case .circle: return AnyShape(Circle())
        case .square: return AnyShape(RoundedRectangle(cornerRadius: 6))
        case .triangle: return AnyShape(TriangleShape())
        case .rectangle: return AnyShape(RoundedRectangle(cornerRadius: 6))
        case .oval: return AnyShape(Ellipse())
        case .star: return AnyShape(StarShape())
        }
    }
}

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct StarShape: Shape {
    var points = 5

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.45
        var p = Path()
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? outer : inner
            let a = Double(i) * .pi / Double(points) - .pi / 2
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r * 1.05)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// Eine Form in Farbe oder als Aussparung.
struct ShapeTile: View {
    let kind: ShapeKind
    var size: CGFloat
    var color: Color?
    var outlineOnly = false

    var body: some View {
        let w = kind.aspect >= 1 ? size : size * kind.aspect
        let h = kind.aspect >= 1 ? size / kind.aspect : size
        ZStack {
            if outlineOnly {
                kind.path
                    .fill(Color.black.opacity(0.08))
                kind.path
                    .stroke(Theme.darkGreen.opacity(0.55), style: StrokeStyle(lineWidth: 4, dash: [10, 7]))
            } else {
                kind.path
                    .fill(color ?? Theme.success)
                kind.path
                    .stroke(Color.black.opacity(0.18), lineWidth: 3)
            }
        }
        .frame(width: w, height: h)
    }
}
