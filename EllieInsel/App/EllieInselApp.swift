import SwiftUI

@main
struct EllieInselApp: App {
    @State private var app = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .preferredColorScheme(.light)
                .tint(Theme.darkGreen)
        }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                app.audio.stopAll()
                app.saveNow()
            case .inactive:
                app.audio.stopVoice()
            case .active:
                break
            @unknown default:
                break
            }
        }
    }
}

struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            switch app.screen {
            case .setup:
                SetupFlowView()
                    .transition(.opacity)
            case .tutorial:
                TutorialView()
                    .transition(.opacity)
            case .hub:
                HubView()
                    .transition(.opacity)
            case .game(let game):
                GameScreen(game: game)
                    .id(game)
                    .transition(.opacity)
            case .garden:
                GardenWorldView()
                    .transition(.opacity)
            case .gallery:
                GalleryView()
                    .transition(.opacity)
            case .parents:
                ParentAreaView()
                    .transition(.opacity)
            }
        }
        .demoSurface()
        .onAppear { DemoMode.applyOrientation() }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}

private extension View {
    /// Simulator: «-flaeche 1133x744» zeigt die App in der Grösse eines kleineren iPads (für Layout-Prüfungen).
    @ViewBuilder
    func demoSurface() -> some View {
        if let raw = DemoMode.value("-flaeche"), let x = raw.firstIndex(of: "x"),
           let w = Double(raw[..<x]), let h = Double(raw[raw.index(after: x)...]) {
            ZStack {
                Color.black.ignoresSafeArea()
                self.frame(width: w, height: h).clipped()
            }
        } else {
            self
        }
    }
}
