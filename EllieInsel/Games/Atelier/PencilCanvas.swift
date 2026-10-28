import SwiftUI
import PencilKit

/// PencilKit-Zeichenfläche für Finger und Apple Pencil.
struct PencilCanvas: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var tool: PKTool
    var onStrokeFinished: (PKDrawing) -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.contentInsetAdjustmentBehavior = .never
        canvas.drawing = drawing
        canvas.tool = tool
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        context.coordinator.parent = self
        canvas.tool = tool
        if canvas.drawing != drawing {
            context.coordinator.applyingExternal = true
            canvas.drawing = drawing
            context.coordinator.applyingExternal = false
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: PencilCanvas
        var applyingExternal = false

        init(parent: PencilCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !applyingExternal else { return }
            let d = canvasView.drawing
            DispatchQueue.main.async {
                self.parent.drawing = d
            }
        }

        func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {
            let d = canvasView.drawing
            DispatchQueue.main.async {
                self.parent.onStrokeFinished(d)
            }
        }
    }
}

/// Die sechs Hintergründe für das freie Malen.
enum CanvasBackground: String, CaseIterable, Codable {
    case leer, wiese, himmel, meer, wald, strand

    var title: String {
        switch self {
        case .leer: return "Leer"
        case .wiese: return "Wiese"
        case .himmel: return "Himmel"
        case .meer: return "Meer"
        case .wald: return "Wald"
        case .strand: return "Strand"
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
                }
            }
        }
    }
}
