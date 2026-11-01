import SwiftUI
import UniformTypeIdentifiers

/// Elternbereich: Übersicht, Profil, Ton, Spiele, Pausen, Datensicherung.
struct ParentAreaView: View {
    @Environment(AppModel.self) private var app
    @State private var section: ParentSection? = ParentSection(rawValue: DemoMode.value("-section") ?? "") ?? .overview

    enum ParentSection: String, CaseIterable, Identifiable {
        case overview, profile, sound, games, pause, backup, more
        var id: String { rawValue }

        var title: String {
            switch self {
            case .overview: return "Übersicht"
            case .profile: return "Profil"
            case .sound: return "Ton"
            case .games: return "Spiele"
            case .pause: return "Pausenhinweis"
            case .backup: return "Datensicherung"
            case .more: return "Weiteres"
            }
        }

        var icon: String {
            switch self {
            case .overview: return "chart.bar.doc.horizontal"
            case .profile: return "person.crop.circle"
            case .sound: return "speaker.wave.2"
            case .games: return "square.grid.3x2"
            case .pause: return "moon.zzz"
            case .backup: return "externaldrive"
            case .more: return "ellipsis.circle"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            List(ParentSection.allCases, selection: $section) { s in
                Label(s.title, systemImage: s.icon)
                    .font(Theme.rounded(19, .semibold))
                    .tag(s)
            }
            .navigationTitle("Elternbereich")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        app.saveNow()
                        app.goHome()
                    } label: {
                        Label("Zurück zur Insel", systemImage: "house.fill")
                    }
                }
            }
        } detail: {
            NavigationStack {
                Group {
                    switch section ?? .overview {
                    case .overview: OverviewSection()
                    case .profile: ProfileSection()
                    case .sound: SoundSection()
                    case .games: GamesSection()
                    case .pause: PauseSection()
                    case .backup: BackupSection()
                    case .more: MoreSection()
                    }
                }
                .navigationTitle((section ?? .overview).title)
            }
        }
        .tint(Theme.darkGreen)
    }
}

// MARK: - Übersicht

private struct OverviewSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            Section("Abgeschlossene Runden") {
                let played = GameID.allCases.filter { (app.data.roundsCompleted[$0.rawValue] ?? 0) > 0 }
                if played.isEmpty {
                    Text("Noch keine Runde abgeschlossen.")
                        .foregroundStyle(.secondary)
                }
                ForEach(played) { g in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("\(g.emoji) \(g.title)")
                                .font(.headline)
                            Spacer()
                            Text("\(app.data.roundsCompleted[g.rawValue] ?? 0) Runden")
                                .foregroundStyle(.secondary)
                        }
                        if let items = app.data.practicedItems[g.rawValue], !items.isEmpty {
                            Text("Geübt: " + items.prefix(30).joined(separator: ", "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            Section("Letzte Aktivitäten") {
                if app.data.activities.isEmpty {
                    Text("Hier erscheinen konkrete Aktivitäten, zum Beispiel «Zahlen 1 bis 5 nachgezeichnet».")
                        .foregroundStyle(.secondary)
                }
                ForEach(app.data.activities.prefix(100)) { entry in
                    HStack(alignment: .top, spacing: 14) {
                        Text(entry.game.emoji).font(.title)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(entry.text).font(.body.weight(.semibold))
                            HStack(spacing: 8) {
                                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                                if let d = entry.difficulty { Text("· \(d.title)") }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            Text(entry.stats.summary)
                                .font(.caption)
                                .foregroundStyle(Theme.darkGreen)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
}

// MARK: - Profil

private struct ProfileSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Form {
            Section("Rufname") {
                TextField("Rufname (optional)", text: app.binding(\.profile.name))
                    .font(.title3)
            }
            Section("Tier") {
                AvatarPicker(selection: app.binding(\.profile.avatar))
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Ton

private struct SoundSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ToggleRow(title: "Alles stumm", systemImage: "speaker.slash.fill", isOn: app.binding(\.sound.masterMuted))
                    .padding(22)
                    .background(RoundedRectangle(cornerRadius: 24).fill(.white))
                SoundSettingsForm()
                Button {
                    app.audio.say("Hallo! Schön, dass du da bist. Gemeinsam entdecken wir deine Insel.")
                } label: {
                    Label("Hörprobe", systemImage: "play.circle.fill")
                }
                .buttonStyle(BigButtonStyle(color: Theme.success))
                Text("Ist eine vorproduzierte Sprachaufnahme in der App enthalten, wird sie verwendet. Sonst spricht die beste installierte deutsche Systemstimme. Bessere Stimmen lassen sich unter Einstellungen › Bedienungshilfen › Gesprochene Inhalte › Stimmen › Deutsch laden.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(30)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.cream)
    }
}

// MARK: - Spiele

private struct GamesSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Form {
            Section {
                Text("Jedes Spiel hat einen Apfelbaum: ein Apfel pro Niveau. Mit «Automatisch» passt sich das Niveau nach jeder Runde an – nach oben, wenn fast alles sicher und zügig gelingt, nach unten, wenn es zu schwer wird. Eine Änderung gilt immer erst ab der nächsten Runde.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(GameID.allCases) { game in
                Section {
                    Toggle("Im Hub anzeigen", isOn: Binding(
                        get: { app.data.isVisible(game) },
                        set: { visible in
                            app.update {
                                if visible { $0.hiddenGames.remove(game.rawValue) } else { $0.hiddenGames.insert(game.rawValue) }
                            }
                        }
                    ))
                    LevelControls(game: game)
                    gameOptions(game)
                } header: {
                    Text("\(game.emoji) \(game.title)")
                        .font(.headline)
                }
            }
        }
    }

    @ViewBuilder
    private func gameOptions(_ game: GameID) -> some View {
        switch game {
        case .appleMath:
            SetToggle(title: "Addition", key: "plus", keyPath: \.options.mathOperations)
            SetToggle(title: "Subtraktion", key: "minus", keyPath: \.options.mathOperations)
        case .memory:
            Toggle("Ruhiges Betrachten (Karten bleiben länger offen)", isOn: app.binding(\.options.calmMemory))
        case .snake:
            Toggle("Steuern durch Wischen erlauben", isOn: app.binding(\.options.snakeSwipe))
        case .counting:
            SetToggle(title: "Modus «Wie viele?»", key: "howMany", keyPath: \.options.countingModes)
            SetToggle(title: "Modus «Gib mir …»", key: "giveMe", keyPath: \.options.countingModes)
        case .sorting:
            SetToggle(title: "Nach Farbe", key: "color", keyPath: \.options.sortingFeatures)
            SetToggle(title: "Nach Form", key: "shape", keyPath: \.options.sortingFeatures)
            SetToggle(title: "Nach Grösse", key: "size", keyPath: \.options.sortingFeatures)
        case .naturePairs:
            SetToggle(title: "Nahrung", key: "food", keyPath: \.options.natureRelations)
            SetToggle(title: "Lebensraum", key: "habitat", keyPath: \.options.natureRelations)
            SetToggle(title: "Pflanzenteile", key: "plantPart", keyPath: \.options.natureRelations)
        case .atelier:
            SetToggle(title: "Wege nachfahren", key: "paths", keyPath: \.options.atelierModes)
            SetToggle(title: "Freies Malen", key: "free", keyPath: \.options.atelierModes)
        case .animalSounds:
            Toggle("Bildermodus ohne Ton anbieten", isOn: app.binding(\.options.animalPictureModeAllowed))
        default:
            EmptyView()
        }
    }
}

/// Niveau eines Spiels: Baum, Beschreibung, Automatik, manuelle Wahl und letzte Ergebnisse.
private struct LevelControls: View {
    @Environment(AppModel.self) private var app
    let game: GameID

    var body: some View {
        let level = app.data.level(for: game)
        let maxLevel = LevelCatalog.maxLevel(game)
        let skill = app.data.skill(for: game)
        HStack(spacing: 16) {
            AppleTreeView(level: level, maxLevel: maxLevel)
                .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 4) {
                Text("Niveau \(level) von \(maxLevel)")
                    .font(.headline)
                Text(LevelCatalog.describe(game, level: level))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                resultDots(skill: skill, level: level)
            }
            Spacer()
            Stepper("Niveau", value: Binding(
                get: { level },
                set: { app.setLevel($0, for: game) }
            ), in: 1...maxLevel)
            .labelsHidden()
        }
        Toggle("Automatisch anpassen", isOn: Binding(
            get: { app.data.isAdaptive(game) },
            set: { on in
                app.update {
                    if on { $0.adaptiveOff.remove(game.rawValue) } else { $0.adaptiveOff.insert(game.rawValue) }
                }
            }
        ))
    }

    /// Letzte Aufgaben auf diesem Niveau: grün = sicher, gelb = gut, orange = schwer.
    @ViewBuilder
    private func resultDots(skill: SkillState, level: Int) -> some View {
        let reference = LevelEngine.referenceSeconds(skill, level: level, fallback: LevelCatalog.targetSeconds(game, level: level))
        let recent = skill.results.filter { $0.level == level }.suffix(10)
        if !recent.isEmpty {
            HStack(spacing: 4) {
                ForEach(Array(recent.enumerated()), id: \.offset) { _, r in
                    let rating = LevelEngine.rate(r, reference: reference)
                    Circle()
                        .fill(rating == .strong ? Color.green : rating == .good ? Color.yellow : Color.orange)
                        .frame(width: 10, height: 10)
                }
            }
            .accessibilityLabel("Letzte Ergebnisse")
        }
    }
}

/// Schalter für ein Element einer Menge; mindestens ein Element bleibt immer aktiv.
private struct SetToggle: View {
    @Environment(AppModel.self) private var app
    let title: String
    let key: String
    let keyPath: WritableKeyPath<AppData, Set<String>>

    var body: some View {
        Toggle(title, isOn: Binding(
            get: { app.data[keyPath: keyPath].contains(key) },
            set: { on in
                app.update { d in
                    if on {
                        d[keyPath: keyPath].insert(key)
                    } else if d[keyPath: keyPath].count > 1 {
                        d[keyPath: keyPath].remove(key)
                    }
                }
            }
        ))
    }
}

// MARK: - Pausen

private struct PauseSection: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        Form {
            Section {
                Picker("Pausenhinweis", selection: app.binding(\.breakReminderMinutes)) {
                    Text("Aus").tag(0)
                    Text("Nach 15 Minuten").tag(15)
                    Text("Nach 20 Minuten").tag(20)
                    Text("Nach 30 Minuten").tag(30)
                    Text("Nach 45 Minuten").tag(45)
                }
                .pickerStyle(.inline)
            } footer: {
                Text("Der Hase schlägt im Hub freundlich eine Pause vor. Ein laufendes Spiel wird nicht unterbrochen.")
            }
        }
    }
}

// MARK: - Datensicherung

private struct BackupSection: View {
    @Environment(AppModel.self) private var app
    @State private var exporting = false
    @State private var importing = false
    @State private var exportDoc: BackupDocument?
    @State private var pendingImport: BackupFile?
    @State private var message: String?

    var body: some View {
        Form {
            Section {
                Button {
                    app.saveNow()
                    exportDoc = BackupDocument(backup: app.makeBackup())
                    exporting = true
                } label: {
                    Label("Sicherung exportieren", systemImage: "square.and.arrow.up")
                }
                Button {
                    importing = true
                } label: {
                    Label("Sicherung importieren", systemImage: "square.and.arrow.down")
                }
            } footer: {
                Text("Die Sicherung enthält Fortschritt, Einstellungen, Garten und alle gespeicherten Zeichnungen in einer Datei.")
            }

            if let pendingImport {
                Section("Diese Sicherung importieren?") {
                    Text("Erstellt: \(pendingImport.created.formatted(date: .long, time: .shortened))")
                    Text("Ersetzt würden:")
                        .font(.headline)
                    comparisonRow("Profil", now: "\(app.data.profile.avatar.emoji) \(app.data.profile.name)", new: "\(pendingImport.app.profile.avatar.emoji) \(pendingImport.app.profile.name)")
                    comparisonRow("Aktivitäten", now: "\(app.data.activities.count)", new: "\(pendingImport.app.activities.count)")
                    comparisonRow("Gartenteile", now: "\(app.data.garden.placed.count + app.data.garden.inventory.count)", new: "\(pendingImport.app.garden.placed.count + pendingImport.app.garden.inventory.count)")
                    comparisonRow("Zeichnungen", now: "\(app.gallery.count)", new: "\(pendingImport.gallery.count)")
                    comparisonRow("Angefangene Spiele", now: "\(app.data.saves.count)", new: "\(pendingImport.app.saves.count)")
                    Button(role: .destructive) {
                        app.restore(from: pendingImport)
                        self.pendingImport = nil
                        message = "Die Sicherung wurde importiert."
                    } label: {
                        Label("Ja, bestehende Daten ersetzen", systemImage: "arrow.triangle.2.circlepath")
                    }
                    Button("Abbrechen") { self.pendingImport = nil }
                }
            }

            if let message {
                Section { Text(message).foregroundStyle(Theme.darkGreen) }
            }
        }
        .fileExporter(
            isPresented: $exporting,
            document: exportDoc,
            contentType: .json,
            defaultFilename: "Entdeckerinsel-Sicherung-\(Date().formatted(.iso8601.year().month().day()))"
        ) { result in
            switch result {
            case .success: message = "Die Sicherung wurde gespeichert."
            case .failure(let error): message = "Export fehlgeschlagen: \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                do {
                    let raw = try Data(contentsOf: url)
                    let backup = try Persistence.decoder.decode(BackupFile.self, from: raw)
                    guard backup.format == "ellies-entdeckerinsel-backup" else {
                        message = "Diese Datei ist keine Sicherung der Entdeckerinsel."
                        return
                    }
                    pendingImport = backup
                    message = nil
                } catch {
                    message = "Die Datei konnte nicht gelesen werden."
                }
            case .failure(let error):
                message = "Import fehlgeschlagen: \(error.localizedDescription)"
            }
        }
    }

    private func comparisonRow(_ title: String, now: String, new: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text("jetzt: \(now)").foregroundStyle(.secondary)
            Image(systemName: "arrow.right")
            Text(new).bold()
        }
    }
}

// MARK: - Weiteres

private struct MoreSection: View {
    @Environment(AppModel.self) private var app
    @State private var confirmReset = false
    @State private var confirmSaves = false
    @State private var changingCode = false

    var body: some View {
        Form {
            Section("Einführung") {
                Button("Kinder-Einführung erneut starten") {
                    app.update { $0.tutorialDone = false }
                    app.screen = .tutorial
                }
            }
            Section("Elterncode") {
                Button("Elterncode ändern") { changingCode = true }
            }
            Section("Spielstände") {
                Button("Alle angefangenen Spiele beenden", role: .destructive) { confirmSaves = true }
            }
            Section {
                Button("Alles zurücksetzen", role: .destructive) { confirmReset = true }
            } footer: {
                Text("Löscht Profil, Fortschritt, Garten und Zeichnungen auf diesem iPad. Erstellen Sie vorher eine Sicherung.")
            }
            Section("Über") {
                Text("Ellies Entdeckerinsel 1.0 – alle Spiele und Stimmen funktionieren offline. Es werden keine Daten übertragen.")
                    .font(.footnote)
            }
        }
        .confirmationDialog("Wirklich alles zurücksetzen?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Alles löschen", role: .destructive) { app.resetEverything() }
        }
        .confirmationDialog("Alle angefangenen Spiele beenden?", isPresented: $confirmSaves, titleVisibility: .visible) {
            Button("Beenden", role: .destructive) { app.update { $0.saves = [:] } }
        }
        .sheet(isPresented: $changingCode) {
            ChangeCodeSheet()
                .environment(app)
        }
    }
}

private struct ChangeCodeSheet: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var first: String?
    @State private var error: String?

    var body: some View {
        VStack(spacing: 20) {
            CodePadView(title: first == nil ? "Neuen Code eingeben" : "Neuen Code wiederholen", errorMessage: error) { code in
                if let f = first {
                    if f == code {
                        app.update { $0.parentCodeHash = CodeHasher.hash(code) }
                        dismiss()
                    } else {
                        first = nil
                        error = "Die Codes stimmen nicht überein."
                    }
                } else {
                    first = code
                    error = nil
                }
            }
            Button("Abbrechen") { dismiss() }
                .frame(minHeight: 48)
        }
        .padding(30)
        .foregroundStyle(Theme.darkGreen)
    }
}
