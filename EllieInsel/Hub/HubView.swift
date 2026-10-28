import SwiftUI

struct HubView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        @Bindable var app = app
        GeometryReader { geo in
            let landscape = geo.size.width > geo.size.height
            VStack(spacing: 14) {
                header
                titleRow
                TabView(selection: $app.hubPage) {
                    ForEach(0..<2, id: \.self) { page in
                        HubPage(page: page, landscape: landscape)
                            .tag(page)
                            .padding(.horizontal, 28)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                footer
            }
            .padding(.vertical, 18)
        }
        .background(
            LinearGradient(colors: [Theme.cream, Theme.cream, Theme.meadow.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .sheet(isPresented: $app.showParentGate) {
            ParentGateView()
                .environment(app)
        }
        .overlay {
            if app.breakHintVisible {
                BreakHintView()
            }
        }
        .onAppear { app.checkBreakReminder() }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Pic(app.data.profile.avatar.asset, app.data.profile.avatar.emoji, size: 46)
                .frame(width: 72, height: 72)
                .background(Circle().fill(.white))
            Text(app.data.profile.name.isEmpty ? "Hallo!" : app.data.profile.name)
                .font(Theme.rounded(30))
                .foregroundStyle(Theme.darkGreen)
            Spacer()
            CircleIconButton(
                systemName: app.data.sound.masterMuted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: app.data.sound.masterMuted ? "Ton einschalten" : "Ton ausschalten"
            ) {
                app.update { $0.sound.masterMuted.toggle() }
                if !app.data.sound.masterMuted { app.audio.say("Der Ton ist an.") }
            }
            CircleIconButton(systemName: "lock.fill", label: "Elternbereich", tint: Theme.darkGreen.opacity(0.6), size: 56) {
                app.showParentGate = true
            }
        }
        .padding(.horizontal, 28)
    }

    private var titleRow: some View {
        HStack(spacing: 18) {
            Text("Was möchtest du spielen?")
                .font(Theme.rounded(32, .heavy))
                .foregroundStyle(Theme.darkGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .onTapGesture { app.audio.say("Was möchtest du spielen?") }
            Spacer()
            if let game = app.continueGame {
                Button {
                    app.audio.effect(.tap)
                    app.open(game)
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "play.fill")
                        Text("Weiterspielen")
                        Text(game.emoji)
                    }
                    .font(Theme.rounded(22))
                }
                .buttonStyle(BigButtonStyle(color: game.tint, foreground: Theme.darkGreen))
                .accessibilityLabel("Weiterspielen: \(game.title)")
            }
        }
        .padding(.horizontal, 28)
    }

    private var footer: some View {
        HStack(spacing: 18) {
            Button {
                app.audio.effect(.tap)
                app.screen = .garden
            } label: {
                HStack(spacing: 10) {
                    Text("🌻")
                    Text("Mein Garten")
                    if !app.data.garden.pendingRewards.isEmpty {
                        Text("🎁")
                    }
                }
                .font(Theme.rounded(24))
            }
            .buttonStyle(BigButtonStyle(color: Theme.softGreen, foreground: Theme.darkGreen))

            Spacer()

            HStack(spacing: 12) {
                ForEach(0..<2, id: \.self) { p in
                    Circle()
                        .fill(p == app.hubPage ? Theme.darkGreen : Theme.darkGreen.opacity(0.25))
                        .frame(width: 18, height: 18)
                }
            }
            .accessibilityLabel("Seite \(app.hubPage + 1) von 2")

            Spacer()

            Button {
                app.audio.effect(.tap)
                withAnimation(.easeInOut) { app.hubPage = app.hubPage == 0 ? 1 : 0 }
            } label: {
                if app.hubPage == 0 {
                    Label("Mehr Spiele", systemImage: "arrow.right.circle.fill")
                        .labelStyle(TrailingIconLabelStyle())
                } else {
                    Label("Zurück", systemImage: "arrow.left.circle.fill")
                }
            }
            .buttonStyle(BigButtonStyle())
        }
        .padding(.horizontal, 28)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.title
            configuration.icon
        }
    }
}

private struct HubPage: View {
    @Environment(AppModel.self) private var app
    let page: Int
    let landscape: Bool

    var body: some View {
        let games = Array(GameID.allCases[(page * 6)..<(page * 6 + 6)])
        let columns = landscape ? 3 : 2
        let rows = landscape ? 2 : 3
        GeometryReader { geo in
            let spacing: CGFloat = 22
            let w = (geo.size.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
            let h = (geo.size.height - spacing * CGFloat(rows - 1)) / CGFloat(rows)
            VStack(spacing: spacing) {
                ForEach(0..<rows, id: \.self) { r in
                    HStack(spacing: spacing) {
                        ForEach(0..<columns, id: \.self) { c in
                            let idx = r * columns + c
                            if let game = games[safe: idx], app.data.isVisible(game) {
                                GameTile(game: game)
                                    .frame(width: w, height: h)
                            } else {
                                Color.clear.frame(width: w, height: h)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }
}

private struct GameTile: View {
    @Environment(AppModel.self) private var app
    let game: GameID

    var body: some View {
        Button {
            app.audio.effect(.tap)
            app.open(game)
        } label: {
            VStack(spacing: 8) {
                Spacer(minLength: 0)
                ZStack(alignment: .bottomTrailing) {
                    Pic("spiel_\(game.rawValue)", game.emoji, size: 76)
                    Text(game.tileDecoration)
                        .font(Theme.rounded(26, .heavy))
                        .foregroundStyle(Theme.darkGreen)
                        .padding(.horizontal, 8)
                        .background(Capsule().fill(.white.opacity(0.85)))
                        .offset(x: 30, y: 6)
                }
                Spacer(minLength: 0)
                Text(game.title)
                    .font(Theme.tileFont)
                    .foregroundStyle(Theme.darkGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(game.tint)
                    .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
            )
            .overlay(alignment: .topTrailing) {
                if app.data.saves[game.rawValue] != nil {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.darkGreen.opacity(0.6))
                        .padding(16)
                        .accessibilityLabel("Angefangen")
                }
            }
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(game.title)
    }
}

private struct BreakHintView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("🐰💤").font(.system(size: 90))
                Text("Zeit für eine kleine Pause?")
                    .font(Theme.rounded(32, .heavy))
                    .foregroundStyle(Theme.darkGreen)
                Text("Du hast schon schön gespielt.")
                    .font(Theme.rounded(22, .medium))
                    .foregroundStyle(Theme.darkGreen)
                Button("Okay") { app.dismissBreakHint() }
                    .buttonStyle(BigButtonStyle())
            }
            .padding(44)
            .background(RoundedRectangle(cornerRadius: 40).fill(Theme.cream))
            .onAppear { app.audio.say("Zeit für eine kleine Pause? Du hast schon schön gespielt.") }
        }
    }
}
