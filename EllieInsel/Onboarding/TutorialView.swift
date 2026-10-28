import SwiftUI

/// Kleine Einführung für das Kind: Antippen, Zuordnen, Zurückfinden.
struct TutorialView: View {
    @Environment(AppModel.self) private var app
    @State private var stage = 0
    @State private var butterflyFlown = false
    @State private var appleSelected = false
    @State private var appleInBasket = false
    @State private var dragOffset: CGSize = .zero
    @State private var hint = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [Theme.sky, Theme.meadow], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                VStack {
                    HStack {
                        if stage == 2 {
                            CircleIconButton(systemName: "house.fill", label: "Zu deinen Spielen", highlighted: true) {
                                finish()
                            }
                            .scaleEffect(1.25)
                            .padding(.leading, 12)
                        }
                        Spacer()
                        Button("Später") { finish() }
                            .buttonStyle(BigButtonStyle(color: .white, foreground: Theme.darkGreen))
                    }
                    .padding(24)
                    Spacer()
                }

                switch stage {
                case 0: butterflyStage(geo.size)
                case 1: appleStage(geo.size)
                default: homeStage
                }

                VStack {
                    Spacer()
                    BunnyView(message: message, size: 80)
                        .padding(30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear { speak() }
        .onChange(of: stage) { _, _ in speak() }
    }

    private var message: String {
        switch stage {
        case 0: return "Tippe den Schmetterling an."
        case 1: return "Bring den Apfel zum Korb."
        default: return "Hier kommst du zu deinen Spielen."
        }
    }

    private func speak() {
        app.audio.say(message)
    }

    // MARK: Schritt 1 – Antippen

    private func butterflyStage(_ size: CGSize) -> some View {
        ZStack {
            Pic("einfuehrung_blume", "🌸", size: 220)
                .position(x: size.width / 2, y: size.height * 0.55)
            Pic("einfuehrung_schmetterling", "🦋", size: 130)
                .rotationEffect(.degrees(butterflyFlown ? 25 : 0))
                .position(
                    x: size.width / 2 + (butterflyFlown ? size.width * 0.3 : 0),
                    y: size.height * 0.42 - (butterflyFlown ? size.height * 0.25 : 0)
                )
                .onTapGesture {
                    guard !butterflyFlown else { return }
                    app.audio.effect(.success)
                    withAnimation(.easeInOut(duration: 1.0)) { butterflyFlown = true }
                    app.audio.say("Super, du hast getippt!")
                    advance(after: 2.0)
                }
                .accessibilityLabel("Schmetterling")
                .accessibilityAddTraits(.isButton)
        }
    }

    // MARK: Schritt 2 – Zuordnen

    private func appleStage(_ size: CGSize) -> some View {
        let applePos = CGPoint(x: size.width * 0.3, y: size.height * 0.55)
        let basketPos = CGPoint(x: size.width * 0.7, y: size.height * 0.55)
        return ZStack {
            Pic("korb", "🧺", size: 180)
                .padding(20)
                .background(Circle().fill(appleSelected ? Theme.highlight.opacity(0.35) : .clear))
                .position(basketPos)
                .onTapGesture {
                    if appleSelected { placeApple() }
                }
            if !appleInBasket {
                Pic("motiv_apfel", "🍎", size: 120)
                    .padding(10)
                    .background(Circle().stroke(Theme.highlight, lineWidth: appleSelected ? 6 : 0))
                    .position(applePos)
                    .offset(dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { v in dragOffset = v.translation }
                            .onEnded { v in
                                let end = CGPoint(x: applePos.x + v.translation.width, y: applePos.y + v.translation.height)
                                if end.distance(to: basketPos) < 170 {
                                    placeApple()
                                } else {
                                    withAnimation(.spring()) { dragOffset = .zero }
                                }
                            }
                    )
                    .simultaneousGesture(TapGesture().onEnded {
                        app.audio.effect(.tap)
                        appleSelected.toggle()
                        if appleSelected { app.audio.say("Jetzt tippe den Korb an.") }
                    })
            } else {
                Pic("motiv_apfel", "🍎", size: 80)
                    .position(x: basketPos.x, y: basketPos.y - 40)
            }
        }
    }

    private func placeApple() {
        guard !appleInBasket else { return }
        app.audio.effect(.snap)
        withAnimation(.spring()) {
            appleInBasket = true
            dragOffset = .zero
        }
        app.audio.say("Der Apfel ist im Korb.")
        advance(after: 2.0)
    }

    // MARK: Schritt 3 – Zurückfinden

    private var homeStage: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.up.left")
                .font(.system(size: 90, weight: .bold))
                .foregroundStyle(Theme.darkGreen)
            Text("Tippe auf das Haus.")
                .font(Theme.rounded(30))
                .foregroundStyle(Theme.darkGreen)
        }
    }

    private func advance(after seconds: Double) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            withAnimation { stage += 1 }
        }
    }

    private func finish() {
        app.audio.effect(.tap)
        app.update { $0.tutorialDone = true }
        app.goHome()
    }
}
