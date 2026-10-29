import SwiftUI

/// Grosse, gut treffbare Hauptaktion (mindestens 72 Punkte hoch).
struct BigButtonStyle: ButtonStyle {
    var color: Color = Theme.darkGreen
    var foreground: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(26))
            .foregroundStyle(foreground)
            .padding(.horizontal, 32)
            .frame(minHeight: Theme.mainActionHeight)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(color)
                    .shadow(color: .black.opacity(configuration.isPressed ? 0.05 : 0.15), radius: 6, y: 3)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Runder Symbolknopf mit mindestens 64 × 64 Punkten Trefferfläche.
struct CircleIconButton: View {
    let systemName: String
    var label: String
    var tint: Color = Theme.darkGreen
    var background: Color = .white
    var size: CGFloat = Theme.controlSize
    var highlighted = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: size, height: size)
                .background(Circle().fill(background).shadow(color: .black.opacity(0.12), radius: 4, y: 2))
                .overlay(
                    Circle()
                        .stroke(Theme.highlight, lineWidth: highlighted ? 6 : 0)
                        .scaleEffect(highlighted ? 1.12 : 1)
                )
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(label)
    }
}

struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// Der Hase als Begleiter mit Sprechblase.
struct BunnyView: View {
    var message: String?
    var size: CGFloat = 64

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Pic("hase_begleiter", "🐰", size: size)
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
        // Nur Erscheinen und Verschwinden animieren, damit sich Texte nicht überlagern.
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: message == nil)
    }
}

/// Fortschrittspunkte einer Runde.
struct TaskDots: View {
    let done: Int
    let total: Int
    var tint: Color = Theme.darkGreen

    var body: some View {
        HStack(spacing: 12) {
            ForEach(0..<total, id: \.self) { i in
                Circle()
                    .fill(i < done ? tint : Color.white)
                    .overlay(Circle().stroke(tint.opacity(0.6), lineWidth: 3))
                    .frame(width: 22, height: 22)
                    .scaleEffect(i < done ? 1.1 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: done)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) von \(total) Aufgaben")
    }
}

/// Grosse Antwortkarte mit Zahl oder Bild.
struct AnswerCard<Content: View>: View {
    var state: AnswerState = .normal
    var minSize: CGFloat = 110
    let action: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        Button(action: action) {
            content()
                .frame(minWidth: minSize, minHeight: minSize)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(state.fill)
                        .shadow(color: .black.opacity(0.14), radius: 6, y: 3)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(state.border, lineWidth: state == .normal ? 0 : 6)
                )
        }
        .buttonStyle(PressableStyle())
    }
}

enum AnswerState: Equatable {
    case normal, correct, tried, hinted

    var fill: Color {
        switch self {
        case .normal: return .white
        case .correct: return Theme.softGreen
        case .tried: return Theme.creamDark
        case .hinted: return .white
        }
    }

    var border: Color {
        switch self {
        case .normal: return .clear
        case .correct: return Theme.success
        case .tried: return Theme.gentleRed.opacity(0.6)
        case .hinted: return Theme.highlight
        }
    }
}

/// Weiche Spielfläche, auf der die Aufgabe liegt.
struct PlayfieldBackground: View {
    var color: Color = .white

    var body: some View {
        RoundedRectangle(cornerRadius: 36, style: .continuous)
            .fill(color)
            .shadow(color: .black.opacity(0.08), radius: 10, y: 4)
    }
}

/// Pulsierende Hervorhebung für Hilfen.
struct PulseHighlight: ViewModifier {
    var active: Bool
    @State private var pulse = false

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Theme.highlight, lineWidth: active ? 7 : 0)
                    .scaleEffect(active && pulse ? 1.06 : 1)
                    .opacity(active ? 1 : 0)
            )
            .onAppear { startIfNeeded() }
            .onChange(of: active) { _, _ in startIfNeeded() }
    }

    private func startIfNeeded() {
        guard active else { pulse = false; return }
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) { pulse = true }
    }
}

extension View {
    func pulseHighlight(_ active: Bool) -> some View {
        modifier(PulseHighlight(active: active))
    }

    /// Kurzes Wackeln für eine unpassende Auswahl (ohne Strafe).
    func gentleShake(_ trigger: Int) -> some View {
        modifier(ShakeEffect(animatableData: CGFloat(trigger)))
    }
}

struct ShakeEffect: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let offset = sin(animatableData * .pi * 4) * 8
        return ProjectionTransform(CGAffineTransform(translationX: offset, y: 0))
    }
}

/// Emoji in fester Grösse (für Motive in Spielen).
struct EmojiView: View {
    let emoji: String
    var size: CGFloat

    var body: some View {
        Text(emoji)
            .font(.system(size: size))
            .minimumScaleFactor(0.5)
            .accessibilityHidden(true)
    }
}

/// Zeigt eine mitgelieferte Illustration (PNG im Ordner `EllieInsel/Images/`), sonst das Emoji.
struct Pic: View {
    let asset: String
    let emoji: String
    var size: CGFloat

    init(_ asset: String, _ emoji: String, size: CGFloat) {
        self.asset = asset
        self.emoji = emoji
        self.size = size
    }

    var body: some View {
        if !asset.isEmpty, let image = UIImage(named: asset) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: size * 1.2, height: size * 1.2)
                .accessibilityHidden(true)
        } else {
            Text(emoji)
                .font(.system(size: size))
                .accessibilityHidden(true)
        }
    }
}
