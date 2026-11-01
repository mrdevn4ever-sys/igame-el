import SwiftUI
import PencilKit

/// Eine Malaktion: Strich, Radieren oder Füllen. Koordinaten in Punkten der Referenzbreite des Bildes.
struct PaintOp: Codable, Equatable {
    enum Kind: String, Codable { case line, erase, fill }

    var kind: Kind
    var r: Double = 0
    var g: Double = 0
    var b: Double = 0
    var glitter: Glitter?
    var width: Double = 14
    /// Punkte als x, y, x, y …
    var pts: [Double] = []
    /// Füllstreifen als y, x0, x1, …
    var runs: [Double] = []
    var step: Double = 3
    var seed: UInt64 = 1

    var color: Color { Color(red: r, green: g, blue: b) }

    var points: [CGPoint] {
        stride(from: 0, to: pts.count - 1, by: 2).map { CGPoint(x: pts[$0], y: pts[$0 + 1]) }
    }

    static func ink(_ choice: InkChoice) -> (Double, Double, Double, Glitter?) {
        switch choice {
        case .glitter(let gl):
            return (gl.rgb.0, gl.rgb.1, gl.rgb.2, gl)
        case .plain(let p):
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            p.uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
            return (Double(r), Double(g), Double(b), nil)
        }
    }
}

/// Ganzes Bild. Wird als JSON in `Artwork.drawing` gespeichert.
struct PaintDoc: Codable, Equatable {
    var format = "ellie-paint-1"
    /// Breite der Zeichenfläche, in der die Koordinaten gelten
    var width: Double
    var ops: [PaintOp] = []

    func encoded() -> Data { (try? JSONEncoder().encode(self)) ?? Data() }

    /// Liest das neue Format; ältere PencilKit-Bilder werden in Striche umgewandelt.
    static func decode(_ data: Data?, fallbackWidth: Double) -> PaintDoc {
        let w = fallbackWidth > 0 ? fallbackWidth : 800
        guard let data, !data.isEmpty else { return PaintDoc(width: w) }
        if let doc = try? JSONDecoder().decode(PaintDoc.self, from: data), doc.format.hasPrefix("ellie-paint") {
            return doc
        }
        guard let old = try? PKDrawing(data: data) else { return PaintDoc(width: w) }
        var doc = PaintDoc(width: w)
        for stroke in old.strokes {
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            stroke.ink.color.getRed(&r, green: &g, blue: &b, alpha: &a)
            var pts: [Double] = []
            var widthSum: CGFloat = 0
            var n: CGFloat = 0
            for p in stroke.path.interpolatedPoints(by: .distance(3)) {
                let q = p.location.applying(stroke.transform)
                pts += [Double(q.x), Double(q.y)]
                widthSum += p.size.width
                n += 1
            }
            guard !pts.isEmpty else { continue }
            doc.ops.append(PaintOp(kind: .line, r: Double(r), g: Double(g), b: Double(b), glitter: Glitter.match(stroke.ink.color),
                                   width: Double(max(widthSum / max(n, 1), 2)), pts: pts, seed: UInt64(doc.ops.count + 1)))
        }
        return doc
    }
}

/// Zeichnet Malaktionen – identisch beim Malen und im fertigen Bild.
enum PaintRenderer {
    static let rainbowBand: CGFloat = 45

    static func draw(_ op: PaintOp, in ctx: GraphicsContext, scale: CGFloat) {
        switch op.kind {
        case .line: drawLine(op, in: ctx, scale: scale)
        case .erase:
            var c = ctx
            c.blendMode = .clear
            c.stroke(smoothPath(op.points, scale: scale), with: .color(.black),
                     style: StrokeStyle(lineWidth: CGFloat(op.width) * scale, lineCap: .round, lineJoin: .round))
            if op.points.count == 1, let p = op.points.first {
                let d = CGFloat(op.width) * scale
                c.fill(Path(ellipseIn: CGRect(x: p.x * scale - d / 2, y: p.y * scale - d / 2, width: d, height: d)), with: .color(.black))
            }
        case .fill: drawFill(op, in: ctx, scale: scale)
        }
    }

    // MARK: Striche

    static func smoothPath(_ pts: [CGPoint], scale: CGFloat) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        let s = pts.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
        path.move(to: CGPoint(x: first.x * scale, y: first.y * scale))
        if s.count == 1 {
            path.addLine(to: CGPoint(x: s[0].x + 0.1, y: s[0].y))
            return path
        }
        for i in 1..<s.count {
            let mid = CGPoint(x: (s[i - 1].x + s[i].x) / 2, y: (s[i - 1].y + s[i].y) / 2)
            path.addQuadCurve(to: mid, control: s[i - 1])
        }
        path.addLine(to: s[s.count - 1])
        return path
    }

    private static func drawLine(_ op: PaintOp, in ctx: GraphicsContext, scale: CGFloat) {
        let pts = op.points
        guard !pts.isEmpty else { return }
        let style = StrokeStyle(lineWidth: CGFloat(op.width) * scale, lineCap: .round, lineJoin: .round)
        if op.glitter == .regenbogen {
            // Farbabschnitte entlang des Strichs
            var segment: [CGPoint] = [pts[0]]
            var length: CGFloat = 0
            var band = 0
            for i in 1..<max(pts.count, 1) {
                segment.append(pts[i])
                length += hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y)
                if length >= rainbowBand {
                    ctx.stroke(smoothPath(segment, scale: scale), with: .color(Color(uiColor: Glitter.rainbowColor(band))), style: style)
                    band += 1
                    length = 0
                    segment = [pts[i]]
                }
            }
            ctx.stroke(smoothPath(segment, scale: scale), with: .color(Color(uiColor: Glitter.rainbowColor(band))), style: style)
        } else {
            ctx.stroke(smoothPath(pts, scale: scale), with: .color(op.color), style: style)
        }
        if let gl = op.glitter { lineSparkles(op, glitter: gl, pts: pts, in: ctx, scale: scale) }
    }

    /// Funken in festen Abständen entlang des Strichs. Gleicher Zufall pro Strich: beim Malen und danach identisch.
    private static func lineSparkles(_ op: PaintOp, glitter: Glitter, pts: [CGPoint], in ctx: GraphicsContext, scale: CGFloat) {
        var rng = SeededGenerator(seed: op.seed == 0 ? 1 : op.seed)
        let colors = glitter.sparkleColors
        let spacing: CGFloat = 5
        let width = CGFloat(op.width)
        let expected = Double(spacing * width / 38)
        func emit(_ p: CGPoint) {
            let extra = Double.random(in: 0..<1, using: &rng)
            let n = Int(expected) + (extra < expected - Double(Int(expected)) ? 1 : 0)
            for _ in 0..<n {
                let dx = CGFloat.random(in: -0.42...0.42, using: &rng) * width
                let dy = CGFloat.random(in: -0.42...0.42, using: &rng) * width
                let rad = CGFloat.random(in: 0.9...2.3, using: &rng)
                let alpha = Double.random(in: 0.45...1, using: &rng)
                let c = colors[Int.random(in: 0..<colors.count, using: &rng)]
                let star = Int.random(in: 0..<9, using: &rng) == 0
                sparkle(at: CGPoint(x: (p.x + dx) * scale, y: (p.y + dy) * scale), radius: rad, color: c, alpha: alpha, star: star, in: ctx)
            }
        }
        emit(pts[0])
        var carry: CGFloat = spacing
        for i in 1..<max(pts.count, 1) {
            let a = pts[i - 1], b = pts[i]
            let len = hypot(b.x - a.x, b.y - a.y)
            guard len > 0 else { continue }
            var d = carry
            while d <= len {
                let t = d / len
                emit(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
                d += spacing
            }
            carry = d - len
        }
    }

    static func sparkle(at p: CGPoint, radius: CGFloat, color: Color, alpha: Double, star: Bool, in ctx: GraphicsContext) {
        ctx.fill(Path(ellipseIn: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2)),
                 with: .color(color.opacity(alpha)))
        if star {
            let l = radius * 3.2
            var cross = Path()
            cross.move(to: CGPoint(x: p.x - l, y: p.y))
            cross.addLine(to: CGPoint(x: p.x + l, y: p.y))
            cross.move(to: CGPoint(x: p.x, y: p.y - l))
            cross.addLine(to: CGPoint(x: p.x, y: p.y + l))
            ctx.stroke(cross, with: .color(.white.opacity(alpha)), lineWidth: 1.2)
        }
    }

    // MARK: Füllen

    private static func drawFill(_ op: PaintOp, in ctx: GraphicsContext, scale: CGFloat) {
        let count = op.runs.count / 3
        guard count > 0 else { return }
        let step = CGFloat(op.step)
        var minY = CGFloat.greatestFiniteMagnitude, maxY: CGFloat = 0
        for i in 0..<count {
            minY = min(minY, CGFloat(op.runs[i * 3]))
            maxY = max(maxY, CGFloat(op.runs[i * 3]))
        }
        let rainbow = op.glitter == .regenbogen
        let bandHeight = max((maxY - minY) / 6, 1)
        var paths = Array(repeating: Path(), count: rainbow ? 6 : 1)
        for i in 0..<count {
            let y = CGFloat(op.runs[i * 3]), x0 = CGFloat(op.runs[i * 3 + 1]), x1 = CGFloat(op.runs[i * 3 + 2])
            let rect = CGRect(x: (x0 - 0.8) * scale, y: (y - step / 2 - 0.6) * scale, width: (x1 - x0 + 1.6) * scale, height: (step + 1.2) * scale)
            let idx = rainbow ? min(Int((y - minY) / bandHeight), 5) : 0
            paths[idx].addRect(rect)
        }
        for (i, p) in paths.enumerated() {
            ctx.fill(p, with: .color(rainbow ? Color(uiColor: Glitter.rainbowColor(i)) : op.color))
        }
        guard let gl = op.glitter else { return }
        var rng = SeededGenerator(seed: op.seed == 0 ? 1 : op.seed)
        let colors = gl.sparkleColors
        let probability = Double(step * 7 / 60)
        for i in 0..<count {
            let y = CGFloat(op.runs[i * 3]), x0 = CGFloat(op.runs[i * 3 + 1]), x1 = CGFloat(op.runs[i * 3 + 2])
            var x = x0
            while x <= x1 {
                if Double.random(in: 0..<1, using: &rng) < probability {
                    let dy = CGFloat.random(in: -0.5...0.5, using: &rng) * step
                    let rad = CGFloat.random(in: 0.9...2.2, using: &rng)
                    let alpha = Double.random(in: 0.45...1, using: &rng)
                    let c = colors[Int.random(in: 0..<colors.count, using: &rng)]
                    let star = Int.random(in: 0..<10, using: &rng) == 0
                    sparkle(at: CGPoint(x: x * scale, y: (y + dy) * scale), radius: rad, color: c, alpha: alpha, star: star, in: ctx)
                }
                x += 7
            }
        }
    }

    // MARK: Bild

    /// Rendert Aktionen (optional auf einem bestehenden Bild) zu einem Bild in Zeichenflächengrösse.
    @MainActor
    static func render(_ ops: [PaintOp], base: UIImage?, size: CGSize, scale: CGFloat, pixelScale: CGFloat = 2) -> UIImage? {
        guard size.width > 1, size.height > 1 else { return nil }
        let view = Canvas { ctx, sz in
            if let base { ctx.draw(Image(uiImage: base), in: CGRect(origin: .zero, size: sz)) }
            for op in ops { draw(op, in: ctx, scale: scale) }
        }
        .frame(width: size.width, height: size.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = pixelScale
        renderer.isOpaque = false
        return renderer.uiImage
    }
}

/// Zeichenfläche: gespeichertes Bild plus der Strich, der gerade entsteht.
struct PaintCanvas: View {
    let layer: UIImage?
    let live: PaintOp?
    let scale: CGFloat

    var body: some View {
        Canvas { ctx, size in
            if let layer { ctx.draw(Image(uiImage: layer), in: CGRect(origin: .zero, size: size)) }
            if let live { PaintRenderer.draw(live, in: ctx, scale: scale) }
        }
    }
}
