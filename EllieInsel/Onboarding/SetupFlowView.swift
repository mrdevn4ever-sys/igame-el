import SwiftUI

/// Gemeinsame Einrichtung mit einem Elternteil (sechs Schritte, setzt beim offenen Schritt fort).
struct SetupFlowView: View {
    @Environment(AppModel.self) private var app

    private let stepCount = 6

    var body: some View {
        let step = min(app.data.setupStep, stepCount - 1)
        VStack(spacing: 0) {
            HStack {
                if step > 0 {
                    Button {
                        app.update { $0.setupStep = max(0, step - 1) }
                    } label: {
                        Label("Zurück", systemImage: "chevron.left")
                            .font(Theme.rounded(20, .semibold))
                            .frame(minHeight: 56)
                    }
                    .foregroundStyle(Theme.darkGreen)
                }
                Spacer()
                HStack(spacing: 10) {
                    ForEach(0..<stepCount, id: \.self) { i in
                        Capsule()
                            .fill(i <= step ? Theme.darkGreen : Theme.darkGreen.opacity(0.2))
                            .frame(width: i == step ? 34 : 14, height: 14)
                    }
                }
                Spacer()
                Color.clear.frame(width: 100, height: 1)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)

            ScrollView {
                VStack(spacing: 28) {
                    switch step {
                    case 0: WelcomeStep(next: advance)
                    case 1: ProfileStep(next: advance)
                    case 2: SoundStep(next: advance)
                    case 3: LevelStep(next: advance)
                    case 4: ParentCodeStep(next: advance)
                    default: HandoverStep()
                    }
                }
                .frame(maxWidth: 760)
                .padding(40)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Theme.cream.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: step)
    }

    private func advance() {
        app.audio.effect(.tap)
        app.update { $0.setupStep = min($0.setupStep + 1, stepCount - 1) }
    }
}

private struct StepTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(Theme.rounded(38, .heavy))
                .foregroundStyle(Theme.darkGreen)
                .multilineTextAlignment(.center)
            if let subtitle {
                Text(subtitle)
                    .font(Theme.rounded(21, .medium))
                    .foregroundStyle(Theme.darkGreen.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
}

private struct WelcomeStep: View {
    let next: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Pic("hase_begleiter", "🐰", size: 150)
            StepTitle(
                title: "Ellies Entdeckerinsel",
                subtitle: "Eine ruhige Spielwelt mit Tieren, Pflanzen, Zahlen und Formen. Wir richten sie zuerst gemeinsam ein – das dauert etwa drei Minuten."
            )
            Button("Gemeinsam einrichten", action: next)
                .buttonStyle(BigButtonStyle())
        }
    }
}

private struct ProfileStep: View {
    @Environment(AppModel.self) private var app
    let next: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            StepTitle(title: "Wer spielt?", subtitle: "Der Rufname ist freiwillig. Das Tier ist nur zur Gestaltung und verändert keine Aufgaben.")
            TextField("Rufname", text: app.binding(\.profile.name))
                .font(Theme.rounded(30))
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .padding()
                .frame(maxWidth: 420)
                .background(RoundedRectangle(cornerRadius: 20).fill(.white))
            AvatarPicker(selection: app.binding(\.profile.avatar))
            Button("Weiter", action: next)
                .buttonStyle(BigButtonStyle())
        }
    }
}

struct AvatarPicker: View {
    @Binding var selection: Avatar

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(120), spacing: 18), count: 3), spacing: 18) {
            ForEach(Avatar.allCases) { a in
                Button {
                    selection = a
                } label: {
                    VStack(spacing: 4) {
                        Pic(a.asset, a.emoji, size: 60)
                        Text(a.name).font(Theme.rounded(17, .semibold)).foregroundStyle(Theme.darkGreen)
                    }
                    .frame(width: 120, height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(selection == a ? Theme.softGreen : .white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Theme.darkGreen, lineWidth: selection == a ? 4 : 0)
                    )
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(a.name)
                .accessibilityAddTraits(selection == a ? .isSelected : [])
            }
        }
    }
}

private struct SoundStep: View {
    @Environment(AppModel.self) private var app
    let next: () -> Void

    var body: some View {
        VStack(spacing: 26) {
            StepTitle(title: "Sprache und Ton", subtitle: "Der Hase spricht Hochdeutsch. Hören Sie sich die Stimme an.")
            Button {
                app.audio.say("Hallo! Schön, dass du da bist. Gemeinsam entdecken wir deine Insel.")
            } label: {
                Label("Hörprobe abspielen", systemImage: "play.circle.fill")
            }
            .buttonStyle(BigButtonStyle(color: Theme.success))
            SoundSettingsForm()
                .frame(maxWidth: 560)
            Button("Weiter", action: next)
                .buttonStyle(BigButtonStyle())
        }
    }
}

/// Wiederverwendbare Ton-Einstellungen (Einrichtung und Elternbereich).
struct SoundSettingsForm: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 14) {
            ToggleRow(title: "Erzählerstimme", systemImage: "person.wave.2.fill", isOn: app.binding(\.sound.voiceOn))
            SliderRow(title: "Lautstärke Stimme", value: app.binding(\.sound.voiceVolume))
            SliderRow(title: "Sprechtempo", value: app.binding(\.sound.speechRate), range: 0.6...1.1)
            ToggleRow(title: "Tiergeräusche", systemImage: "pawprint.fill", isOn: app.binding(\.sound.animalOn))
            ToggleRow(title: "Rückmeldungen", systemImage: "bell.fill", isOn: app.binding(\.sound.effectsOn))
            SliderRow(title: "Lautstärke Rückmeldungen", value: app.binding(\.sound.effectsVolume))
            ToggleRow(title: "Musik", systemImage: "music.note", isOn: app.binding(\.sound.musicOn))
            SliderRow(title: "Lautstärke Musik", value: app.binding(\.sound.musicVolume))
        }
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 24).fill(.white))
    }
}

struct ToggleRow: View {
    let title: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            Label(title, systemImage: systemImage)
                .font(Theme.rounded(21, .semibold))
                .foregroundStyle(Theme.darkGreen)
        }
        .tint(Theme.success)
        .frame(minHeight: 48)
    }
}

struct SliderRow: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...1

    var body: some View {
        HStack {
            Text(title)
                .font(Theme.rounded(17, .medium))
                .foregroundStyle(Theme.darkGreen.opacity(0.8))
                .frame(width: 220, alignment: .leading)
            Slider(value: $value, in: range)
                .tint(Theme.success)
        }
    }
}

private struct LevelStep: View {
    @Environment(AppModel.self) private var app
    let next: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            StepTitle(title: "Startniveau", subtitle: "Jedes Spiel hat drei Stufen. Wir beginnen überall mit «Entdecken». Im Elternbereich lässt sich die Stufe je Spiel ändern.")
            ForEach(Difficulty.allCases) { d in
                HStack(spacing: 18) {
                    Text(d.symbol).font(.system(size: 48))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(d.title).font(Theme.rounded(26)).foregroundStyle(Theme.darkGreen)
                        Text(d.explanation).font(Theme.rounded(18, .medium)).foregroundStyle(Theme.darkGreen.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(18)
                .background(RoundedRectangle(cornerRadius: 22).fill(d == .entdecken ? Theme.softGreen : .white))
            }
            Button("Weiter", action: next)
                .buttonStyle(BigButtonStyle())
        }
    }
}

private struct ParentCodeStep: View {
    @Environment(AppModel.self) private var app
    let next: () -> Void
    @State private var firstEntry: String?
    @State private var error: String?

    var body: some View {
        VStack(spacing: 22) {
            StepTitle(
                title: "Elternzugang",
                subtitle: "Legen Sie einen sechsstelligen Elterncode fest. Er schützt Einstellungen und Datensicherung. Falls Sie ihn vergessen, hilft eine Rechenaufgabe für Erwachsene beim Zurücksetzen."
            )
            if !app.data.parentCodeHash.isEmpty && firstEntry == nil {
                Text("✅ Ein Elterncode ist bereits festgelegt.")
                    .font(Theme.rounded(21, .semibold))
                    .foregroundStyle(Theme.success)
                HStack(spacing: 16) {
                    Button("Code neu festlegen") {
                        app.update { $0.parentCodeHash = "" }
                    }
                    .buttonStyle(BigButtonStyle(color: .white, foreground: Theme.darkGreen))
                    Button("Weiter", action: next)
                        .buttonStyle(BigButtonStyle())
                }
            } else {
                CodePadView(
                    title: firstEntry == nil ? "Code eingeben" : "Code wiederholen",
                    errorMessage: error
                ) { code in
                    if let first = firstEntry {
                        if first == code {
                            app.update { $0.parentCodeHash = CodeHasher.hash(code) }
                            firstEntry = nil
                            error = nil
                            next()
                        } else {
                            firstEntry = nil
                            error = "Die Codes stimmen nicht überein. Bitte nochmals."
                        }
                    } else {
                        firstEntry = code
                        error = nil
                    }
                }
            }
        }
    }
}

private struct HandoverStep: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 28) {
            HStack(spacing: 24) {
                Pic(app.data.profile.avatar.asset, app.data.profile.avatar.emoji, size: 110)
                Pic("hase_begleiter", "🐰", size: 120)
            }
            StepTitle(
                title: "Jetzt darf \(app.data.profile.name.isEmpty ? "das Kind" : app.data.profile.name) ausprobieren",
                subtitle: "Der Hase zeigt in einer kleinen Einführung, wie man tippt, zuordnet und zurückfindet."
            )
            Button("Los geht's") {
                app.audio.effect(.success)
                app.update { $0.setupComplete = true }
                withAnimation { app.screen = app.data.tutorialDone ? .hub : .tutorial }
            }
            .buttonStyle(BigButtonStyle(color: Theme.success))
        }
    }
}
