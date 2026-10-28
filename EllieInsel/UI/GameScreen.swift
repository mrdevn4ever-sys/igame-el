import SwiftUI

/// Gemeinsamer Rahmen für alle Spiele.
struct GameScreen: View {
    let game: GameID
    @Environment(AppModel.self) private var app
    @State private var host: GameHost?

    var body: some View {
        ZStack {
            Theme.cream.ignoresSafeArea()
            if let host {
                GameFrame(host: host)
            }
        }
        .onAppear {
            if host == nil {
                let h = GameHost(game: game, app: app)
                host = h
            }
        }
    }
}

private struct GameFrame: View {
    @Bindable var host: GameHost
    @Environment(AppModel.self) private var app
    @State private var confirmRestart = false

    var body: some View {
        ZStack {
            VStack(spacing: 10) {
                topBar
                instructionRow
                gameContent
                    .id(host.roundToken)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 20)
                bottomBar
            }
            .padding(.vertical, 12)

            if host.roundComplete {
                Color.black.opacity(0.25).ignoresSafeArea()
                RoundCompleteView(host: host)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: host.roundComplete)
        .confirmationDialog("Neue Runde beginnen?", isPresented: $confirmRestart, titleVisibility: .visible) {
            Button("Ja, neu beginnen", role: .destructive) { host.startNewRound() }
            Button("Weiterspielen", role: .cancel) {}
        } message: {
            Text("Die laufende Runde wird ersetzt.")
        }
    }

    private var topBar: some View {
        HStack(spacing: 16) {
            CircleIconButton(systemName: "house.fill", label: "Zu deinen Spielen") {
                app.audio.effect(.tap)
                app.goHome()
            }
            Text(host.game.emoji)
                .font(.system(size: 40))
            Text(host.game.title)
                .font(Theme.rounded(28))
                .foregroundStyle(Theme.darkGreen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if host.game != .atelier {
                Text("\(host.difficulty.symbol) \(host.difficulty.title)")
                    .font(Theme.rounded(16, .semibold))
                    .foregroundStyle(Theme.darkGreen.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(host.game.tint.opacity(0.6)))
            }
            Spacer()
            CircleIconButton(systemName: "arrow.counterclockwise", label: "Neu beginnen", size: 52) {
                confirmRestart = true
            }
            .opacity(0.8)
            CircleIconButton(systemName: "speaker.wave.2.fill", label: "Anweisung nochmals hören") {
                host.repeatInstruction()
            }
            CircleIconButton(systemName: "lightbulb.fill", label: "Hilfe", tint: .white, background: Theme.highlight) {
                host.requestHelp()
            }
        }
        .padding(.horizontal, 20)
    }

    private var instructionRow: some View {
        HStack(alignment: .center, spacing: 12) {
            BunnyView(message: host.bunnyMessage, size: 48)
            if host.bunnyMessage == nil {
                Text(host.instruction)
                    .font(Theme.instructionFont)
                    .foregroundStyle(Theme.darkGreen)
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                    .onTapGesture { host.repeatInstruction() }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .frame(minHeight: 64)
    }

    private var bottomBar: some View {
        HStack {
            if host.game.showsTaskDots {
                TaskDots(done: host.tasksDone, total: host.tasksPerRound)
            }
            Spacer()
            if let feedback = host.feedback, !host.roundComplete {
                Text(feedback)
                    .font(Theme.rounded(22, .semibold))
                    .foregroundStyle(Theme.success)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .transition(.opacity)
            }
            Spacer()
            if host.awaitingNext {
                Button {
                    app.audio.effect(.tap)
                    host.next()
                } label: {
                    Label("Weiter", systemImage: "arrow.right.circle.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.success))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 28)
        .frame(minHeight: Theme.mainActionHeight)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: host.awaitingNext)
    }

    @ViewBuilder
    private var gameContent: some View {
        switch host.game {
        case .tracing: TracingGameView(host: host)
        case .appleMath: AppleMathGameView(host: host)
        case .memory: MemoryGameView(host: host)
        case .snake: SnakeGameView(host: host)
        case .counting: CountingGameView(host: host)
        case .shapes: ShapesGameView(host: host)
        case .puzzle: PuzzleGameView(host: host)
        case .pattern: PatternGameView(host: host)
        case .animalSounds: AnimalSoundsGameView(host: host)
        case .naturePairs: NaturePairsGameView(host: host)
        case .sorting: SortingGameView(host: host)
        case .atelier: AtelierGameView(host: host)
        }
    }
}

/// Abschluss einer Runde mit freiwilliger Gartenbelohnung.
struct RoundCompleteView: View {
    let host: GameHost
    @Environment(AppModel.self) private var app
    @State private var chosen: String?

    var body: some View {
        VStack(spacing: 22) {
            Text("🎉")
                .font(.system(size: 72))
            Text("Geschafft!")
                .font(Theme.rounded(44, .heavy))
                .foregroundStyle(Theme.darkGreen)
            Text(host.completionText)
                .font(Theme.rounded(24, .medium))
                .foregroundStyle(Theme.darkGreen)
                .multilineTextAlignment(.center)

            if let reward = host.pendingReward {
                VStack(spacing: 12) {
                    Text("Such dir etwas für deinen Garten aus:")
                        .font(Theme.rounded(22, .semibold))
                        .foregroundStyle(Theme.darkGreen)
                    HStack(spacing: 18) {
                        ForEach(reward.options, id: \.self) { item in
                            Button {
                                app.audio.effect(.snap)
                                chosen = item
                                app.claimReward(reward, item: item)
                                app.audio.say("Das kommt in deinen Garten.")
                            } label: {
                                Text(item)
                                    .font(.system(size: 60))
                                    .frame(width: 104, height: 104)
                                    .background(RoundedRectangle(cornerRadius: 24).fill(Theme.meadow))
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityLabel("Gartenteil \(item)")
                        }
                    }
                    Text("Du kannst auch später im Garten wählen.")
                        .font(Theme.rounded(17, .medium))
                        .foregroundStyle(Theme.darkGreen.opacity(0.7))
                }
            } else if let chosen {
                HStack(spacing: 10) {
                    Text(chosen).font(.system(size: 50))
                    Text("wartet in deinem Garten.")
                        .font(Theme.rounded(22, .semibold))
                        .foregroundStyle(Theme.darkGreen)
                }
            }

            HStack(spacing: 20) {
                Button {
                    app.audio.effect(.tap)
                    host.startNewRound()
                } label: {
                    Label("Nochmals", systemImage: "arrow.clockwise")
                }
                .buttonStyle(BigButtonStyle(color: Theme.success))

                Button {
                    app.audio.effect(.tap)
                    app.goHome()
                } label: {
                    Label("Andere Spiele", systemImage: "square.grid.2x2.fill")
                }
                .buttonStyle(BigButtonStyle())
            }
            .padding(.top, 6)
        }
        .padding(40)
        .frame(maxWidth: 640)
        .background(
            RoundedRectangle(cornerRadius: 40, style: .continuous)
                .fill(Theme.cream)
                .shadow(color: .black.opacity(0.2), radius: 20, y: 8)
        )
        .padding(30)
    }
}
