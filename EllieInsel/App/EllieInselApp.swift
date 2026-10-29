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
                GardenView()
                    .transition(.opacity)
            case .gallery:
                GalleryView()
                    .transition(.opacity)
            case .parents:
                ParentAreaView()
                    .transition(.opacity)
            }
        }
        .onAppear { DemoMode.applyOrientation() }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
    }
}
