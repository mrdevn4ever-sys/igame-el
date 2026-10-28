import SwiftUI

/// Eingabe eines sechsstelligen Elterncodes.
struct CodePadView: View {
    let title: String
    var subtitle: String?
    var errorMessage: String?
    let onComplete: (String) -> Void

    @State private var digits: String = ""
    @State private var shake = 0

    var body: some View {
        VStack(spacing: 18) {
            Text(title)
                .font(Theme.rounded(26))
                .foregroundStyle(Theme.darkGreen)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(17, .medium))
                    .foregroundStyle(Theme.darkGreen.opacity(0.75))
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: 14) {
                ForEach(0..<6, id: \.self) { i in
                    Circle()
                        .fill(i < digits.count ? Theme.darkGreen : Color.white)
                        .overlay(Circle().stroke(Theme.darkGreen, lineWidth: 2))
                        .frame(width: 22, height: 22)
                }
            }
            .gentleShake(shake)
            if let errorMessage {
                Text(errorMessage)
                    .font(Theme.rounded(17, .semibold))
                    .foregroundStyle(Theme.gentleRed)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(84), spacing: 14), count: 3), spacing: 14) {
                ForEach(1...9, id: \.self) { n in key("\(n)") }
                Color.clear.frame(width: 84, height: 72)
                key("0")
                Button {
                    if !digits.isEmpty { digits.removeLast() }
                } label: {
                    Image(systemName: "delete.left")
                        .font(.system(size: 26, weight: .semibold))
                        .frame(width: 84, height: 72)
                        .foregroundStyle(Theme.darkGreen)
                }
                .accessibilityLabel("Löschen")
            }
        }
        .onChange(of: errorMessage) { _, newValue in
            if newValue != nil {
                withAnimation(.default) { shake += 1 }
            }
        }
    }

    private func key(_ d: String) -> some View {
        Button {
            guard digits.count < 6 else { return }
            digits.append(d)
            if digits.count == 6 {
                let code = digits
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 150_000_000)
                    digits = ""
                    onComplete(code)
                }
            }
        } label: {
            Text(d)
                .font(Theme.rounded(32))
                .foregroundStyle(Theme.darkGreen)
                .frame(width: 84, height: 72)
                .background(RoundedRectangle(cornerRadius: 18).fill(.white).shadow(color: .black.opacity(0.1), radius: 3, y: 2))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Rechenaufgabe für Erwachsene als Wiederherstellungsweg, falls der Code vergessen wurde.
struct AdultChallenge {
    let a: Int
    let b: Int
    let c: Int

    static func make() -> AdultChallenge {
        AdultChallenge(a: Int.random(in: 6...9), b: Int.random(in: 6...9), c: Int.random(in: 11...29))
    }

    var question: String { "\(a) × \(b) + \(c) = ?" }
    var answer: Int { a * b + c }
}
