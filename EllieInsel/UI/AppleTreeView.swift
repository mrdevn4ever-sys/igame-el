import SwiftUI

/// Wachsender Apfelbaum: zeigt das Niveau eines Spiels. Pro Niveau ein Apfel, Stamm und Krone wachsen mit.
struct AppleTreeView: View {
    let level: Int
    let maxLevel: Int
    var showGround = true

    var body: some View {
        Canvas { ctx, size in
            let w = size.width, h = size.height
            let g = Double(max(level - 1, 0)) / Double(max(maxLevel - 1, 1)) // 0 … 1

            // Boden
            if showGround {
                ctx.fill(Path(ellipseIn: CGRect(x: w * 0.12, y: h * 0.86, width: w * 0.76, height: h * 0.11)),
                         with: .color(Color(red: 0.55, green: 0.76, blue: 0.42)))
            }

            // Stamm
            let base = CGPoint(x: w * 0.5, y: h * 0.91)
            let trunkW = w * (0.06 + 0.07 * g)
            let trunkH = h * (0.24 + 0.14 * g)
            let top = CGPoint(x: base.x, y: base.y - trunkH)
            var trunk = Path()
            trunk.move(to: CGPoint(x: base.x - trunkW * 0.75, y: base.y))
            trunk.addQuadCurve(to: CGPoint(x: top.x - trunkW * 0.4, y: top.y), control: CGPoint(x: base.x - trunkW * 0.35, y: base.y - trunkH * 0.5))
            trunk.addLine(to: CGPoint(x: top.x + trunkW * 0.4, y: top.y))
            trunk.addQuadCurve(to: CGPoint(x: base.x + trunkW * 0.75, y: base.y), control: CGPoint(x: base.x + trunkW * 0.35, y: base.y - trunkH * 0.5))
            trunk.closeSubpath()
            let bark = Color(red: 0.55, green: 0.36, blue: 0.22)
            ctx.fill(trunk, with: .color(bark))

            // Krone
            let crownR = w * (0.17 + 0.2 * g)
            let center = CGPoint(x: w * 0.5, y: top.y - crownR * 0.45)

            // Äste: mehr und kräftiger mit jedem Niveau
            let branchCount = min(2 + level / 2, 7)
            for i in 0..<branchCount {
                let t = Double(i) / Double(max(branchCount - 1, 1))
                let angle = (-150 + 120 * t) * .pi / 180
                let len = crownR * (0.75 + 0.15 * sin(Double(i) * 1.7))
                var branch = Path()
                let start = CGPoint(x: top.x, y: top.y + trunkH * 0.12)
                branch.move(to: start)
                branch.addLine(to: CGPoint(x: start.x + cos(angle) * len, y: start.y + sin(angle) * len))
                ctx.stroke(branch, with: .color(bark), style: StrokeStyle(lineWidth: max(2, trunkW * 0.35), lineCap: .round))
            }

            // Laub aus mehreren runden Teilen
            let leaf = Color(red: 0.36, green: 0.66, blue: 0.33)
            let leafLight = Color(red: 0.49, green: 0.77, blue: 0.40)
            let lobes = 4 + level / 2
            for i in 0..<lobes {
                let a = Double(i) / Double(lobes) * 2 * .pi
                let r = crownR * 0.62
                let p = CGPoint(x: center.x + cos(a) * crownR * 0.55, y: center.y + sin(a) * crownR * 0.42)
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2)), with: .color(leaf))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: center.x - crownR * 0.8, y: center.y - crownR * 0.75,
                                            width: crownR * 1.6, height: crownR * 1.5)), with: .color(leafLight))

            // Äpfel: einer pro Niveau, gleichmässig in der Krone verteilt
            let appleR = max(w * 0.035, crownR * 0.13)
            for i in 0..<max(level, 0) {
                let angle = Double(i) * 137.508 * .pi / 180
                let dist = crownR * 0.72 * sqrt((Double(i) + 0.6) / Double(max(level, 1)))
                let p = CGPoint(x: center.x + cos(angle) * dist, y: center.y + sin(angle) * dist * 0.85)
                let apple = CGRect(x: p.x - appleR, y: p.y - appleR, width: appleR * 2, height: appleR * 2)
                ctx.fill(Path(ellipseIn: apple), with: .color(Color(red: 0.86, green: 0.18, blue: 0.16)))
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - appleR * 0.5, y: p.y - appleR * 0.6, width: appleR * 0.5, height: appleR * 0.4)),
                         with: .color(.white.opacity(0.55)))
                var stem = Path()
                stem.move(to: CGPoint(x: p.x, y: p.y - appleR * 0.9))
                stem.addLine(to: CGPoint(x: p.x + appleR * 0.2, y: p.y - appleR * 1.35))
                ctx.stroke(stem, with: .color(bark), lineWidth: max(1, appleR * 0.18))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Apfelbaum mit \(level) \(level == 1 ? "Apfel" : "Äpfeln")")
    }
}

/// Grosser Baum im Rundenabschluss: wächst sichtbar, wenn das Niveau gestiegen ist.
struct GrowingTreeView: View {
    let outcome: AppModel.LevelOutcome
    let maxLevel: Int
    @State private var shown: Int = 0
    @State private var pop = false

    var body: some View {
        AppleTreeView(level: shown, maxLevel: maxLevel)
            .scaleEffect(pop ? 1.08 : 1)
            .animation(.spring(response: 0.5, dampingFraction: 0.55), value: pop)
            .onAppear {
                shown = outcome.from
                guard outcome.to > outcome.from else {
                    shown = outcome.to
                    return
                }
                Task { @MainActor in
                    for l in (outcome.from + 1)...outcome.to {
                        try? await Task.sleep(nanoseconds: 900_000_000)
                        withAnimation(.easeInOut(duration: 0.4)) { shown = l }
                        pop = true
                        try? await Task.sleep(nanoseconds: 250_000_000)
                        pop = false
                    }
                }
            }
    }
}
