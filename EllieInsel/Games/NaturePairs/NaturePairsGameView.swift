import SwiftUI

struct NatureItem: Codable, Equatable, Hashable {
    var emoji: String
    var name: String
}

struct NatureQuestion: Codable, Equatable {
    var relation: String // food, habitat, plantPart
    var subject: NatureItem
    var question: String
    var valid: [NatureItem]
    var wrong: [NatureItem]
    var explanation: String
}

enum NatureCatalog {
    private static func i(_ e: String, _ n: String) -> NatureItem { NatureItem(emoji: e, name: n) }

    // Häufig verwendete Antwortbilder
    private static let fisch = i("🐟", "Fisch"), stein = i("🪨", "Stein"), knochen = i("🦴", "Knochen")
    private static let heu = i("🌾", "Heu"), gras = i("🌿", "Gras"), karotte = i("🥕", "Karotte")
    private static let nuss = i("🌰", "Nüsse"), wasser = i("🌊", "Wasser"), eis = i("🧊", "Eis")
    private static let wueste = i("🏜️", "Wüste"), baum = i("🌳", "Baum"), apfel = i("🍎", "Apfel")
    private static let blatt = i("🍃", "Blatt"), banane = i("🍌", "Banane")

    /// 18 redaktionell geprüfte Grundfragen aus drei Themenbereichen.
    /// Jede angebotene Antwort ist entweder sicher passend (`valid`) oder sicher unpassend (`wrong`).
    static let questions: [NatureQuestion] = [
        // Nahrung
        NatureQuestion(relation: "food", subject: i("🐿️", "Eichhörnchen"), question: "Was frisst das Eichhörnchen?",
                       valid: [nuss, i("🌻", "Sonnenblumenkerne")], wrong: [fisch, stein, knochen],
                       explanation: "Eichhörnchen fressen gerne Nüsse und Samen."),
        NatureQuestion(relation: "food", subject: i("🐇", "Hase"), question: "Was frisst der Hase?",
                       valid: [karotte, gras, i("🥬", "Salat")], wrong: [fisch, knochen, stein],
                       explanation: "Hasen fressen Pflanzen wie Gras, Salat und Karotten."),
        NatureQuestion(relation: "food", subject: i("🐄", "Kuh"), question: "Was frisst die Kuh?",
                       valid: [gras, heu], wrong: [fisch, knochen, stein],
                       explanation: "Kühe fressen Gras und im Winter Heu."),
        NatureQuestion(relation: "food", subject: i("🐝", "Biene"), question: "Wo holt die Biene ihr Futter?",
                       valid: [i("🌼", "Blüte"), i("🌸", "Kirschblüte")], wrong: [fisch, knochen, stein],
                       explanation: "Bienen holen Nektar und Pollen aus Blüten."),
        NatureQuestion(relation: "food", subject: i("🦔", "Igel"), question: "Was frisst der Igel?",
                       valid: [i("🪱", "Wurm"), i("🪲", "Käfer")], wrong: [heu, stein, i("🧊", "Eis")],
                       explanation: "Igel fressen Würmer, Käfer und Schnecken."),
        NatureQuestion(relation: "food", subject: i("🐸", "Frosch"), question: "Was frisst der Frosch?",
                       valid: [i("🪰", "Fliege"), i("🦟", "Mücke")], wrong: [karotte, heu, nuss],
                       explanation: "Frösche fangen Fliegen und Mücken mit ihrer Zunge."),
        // Lebensraum
        NatureQuestion(relation: "habitat", subject: fisch, question: "Wo lebt der Fisch?",
                       valid: [wasser, i("🏞️", "See")], wrong: [wueste, baum, eis],
                       explanation: "Fische leben im Wasser."),
        NatureQuestion(relation: "habitat", subject: i("🐿️", "Eichhörnchen"), question: "Wo lebt das Eichhörnchen?",
                       valid: [baum, i("🌲", "Wald")], wrong: [wasser, wueste, eis],
                       explanation: "Eichhörnchen wohnen in Bäumen im Wald oder im Park."),
        NatureQuestion(relation: "habitat", subject: i("🐪", "Kamel"), question: "Wo lebt das Kamel?",
                       valid: [wueste], wrong: [wasser, eis, i("🌲", "Wald")],
                       explanation: "Kamele leben in der Wüste. Sie kommen lange ohne Wasser aus."),
        NatureQuestion(relation: "habitat", subject: i("🐧", "Pinguin"), question: "Wo lebt der Pinguin?",
                       valid: [eis, i("🌊", "Meer")], wrong: [wueste, baum, i("🌲", "Wald")],
                       explanation: "Pinguine leben am Meer, viele dort, wo es Eis gibt."),
        NatureQuestion(relation: "habitat", subject: i("🐄", "Kuh"), question: "Wo lebt die Kuh?",
                       valid: [i("🏡", "Bauernhof"), i("🌄", "Weide")], wrong: [wasser, eis, wueste],
                       explanation: "Kühe leben auf dem Bauernhof und auf der Weide."),
        NatureQuestion(relation: "habitat", subject: i("🐸", "Frosch"), question: "Wo lebt der Frosch?",
                       valid: [i("🪷", "Teich"), i("🏞️", "See")], wrong: [wueste, eis, stein],
                       explanation: "Frösche leben an Teichen und Seen."),
        // Pflanzenteile
        NatureQuestion(relation: "plantPart", subject: i("🌳", "Apfelbaum"), question: "Was wächst am Apfelbaum?",
                       valid: [apfel, blatt, i("🌸", "Blüte")], wrong: [karotte, banane, i("🍄", "Pilz")],
                       explanation: "Am Apfelbaum wachsen Blätter, Blüten und Äpfel."),
        NatureQuestion(relation: "plantPart", subject: i("🌳", "Kastanienbaum"), question: "Was wächst am Kastanienbaum?",
                       valid: [i("🌰", "Kastanie"), blatt], wrong: [apfel, karotte, i("🍓", "Erdbeere")],
                       explanation: "Am Kastanienbaum wachsen Kastanien in stacheligen Hüllen."),
        NatureQuestion(relation: "plantPart", subject: i("🌱", "Erdbeerpflanze"), question: "Was wächst an der Erdbeerpflanze?",
                       valid: [i("🍓", "Erdbeere"), i("🌼", "Blüte")], wrong: [apfel, banane, i("🌰", "Kastanie")],
                       explanation: "Aus den Blüten der Erdbeerpflanze werden Erdbeeren."),
        NatureQuestion(relation: "plantPart", subject: i("🍃", "Weinrebe"), question: "Was wächst an der Weinrebe?",
                       valid: [i("🍇", "Trauben"), blatt], wrong: [apfel, karotte, i("🌰", "Kastanie")],
                       explanation: "An der Weinrebe wachsen Trauben."),
        NatureQuestion(relation: "plantPart", subject: i("🌸", "Kirschbaum"), question: "Was wächst am Kirschbaum?",
                       valid: [i("🍒", "Kirschen"), blatt], wrong: [banane, karotte, i("🍐", "Birne")],
                       explanation: "Im Frühling blüht der Kirschbaum, im Sommer trägt er Kirschen."),
        NatureQuestion(relation: "plantPart", subject: i("🌴", "Bananenstaude"), question: "Was wächst an der Bananenstaude?",
                       valid: [banane, blatt], wrong: [apfel, i("🌰", "Kastanie"), karotte],
                       explanation: "Bananen wachsen in grossen Büscheln an der Bananenstaude.")
    ]

    /// Auswahlvariante einer Frage für eine Stufe (18 × 3 = 54 Varianten).
    static func variant(of q: NatureQuestion, difficulty: Difficulty, seed: UInt64) -> NatureTask {
        var rng = SeededGenerator(seed: seed)
        var options: [NatureItem]
        var multi = false
        switch difficulty {
        case .entdecken:
            options = [q.valid[0], q.wrong.shuffled(using: &rng)[0]]
        case .ueben:
            options = [q.valid.shuffled(using: &rng)[0]] + Array(q.wrong.shuffled(using: &rng).prefix(2))
        case .knobeln:
            if q.valid.count >= 2 {
                options = Array(q.valid.shuffled(using: &rng).prefix(2)) + Array(q.wrong.shuffled(using: &rng).prefix(2))
                multi = true
            } else {
                options = [q.valid[0]] + Array(q.wrong.shuffled(using: &rng).prefix(3))
            }
        }
        options.shuffle(using: &rng)
        return NatureTask(question: q, options: options, multipleValid: multi)
    }
}

struct NatureTask: Codable, Equatable {
    var question: NatureQuestion
    var options: [NatureItem]
    var multipleValid: Bool

    func isValid(_ item: NatureItem) -> Bool { question.valid.contains(item) }
}

struct NaturePairsState: Codable {
    var tasks: [NatureTask]
    var index: Int
    var tried: [String]
    var chosen: String?
}

/// Spiel 10: Naturpaare.
struct NaturePairsGameView: View {
    let host: GameHost
    @State private var model: NaturePairsModel

    init(host: GameHost) {
        self.host = host
        _model = State(initialValue: NaturePairsModel(host: host))
    }

    var body: some View {
        VStack(spacing: 24) {
            if let task = model.task {
                HStack(spacing: 30) {
                    VStack(spacing: 8) {
                        Text(task.question.subject.emoji)
                            .font(.system(size: 130))
                        Text(task.question.subject.name)
                            .font(Theme.rounded(28, .bold))
                            .foregroundStyle(Theme.darkGreen)
                        Text(relationLabel(task.question.relation))
                            .font(Theme.rounded(18, .semibold))
                            .foregroundStyle(Theme.darkGreen.opacity(0.75))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.softGreen))
                    }
                    .padding(30)
                    .background(RoundedRectangle(cornerRadius: 34).fill(.white))

                    if let chosen = model.chosenItem {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundStyle(Theme.success)
                        VStack(spacing: 8) {
                            Text(chosen.emoji).font(.system(size: 110))
                            Text(chosen.name).font(Theme.rounded(24, .bold)).foregroundStyle(Theme.darkGreen)
                        }
                        .padding(30)
                        .background(RoundedRectangle(cornerRadius: 34).fill(Theme.softGreen))
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PlayfieldBackground(color: Theme.meadow.opacity(0.6)))

                if model.solved {
                    Text(task.question.explanation)
                        .font(Theme.rounded(22, .medium))
                        .foregroundStyle(Theme.darkGreen)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)
                }

                HStack(spacing: 24) {
                    ForEach(task.options, id: \.self) { item in
                        AnswerCard(state: model.state(for: item), minSize: 140) {
                            model.choose(item)
                        } content: {
                            VStack(spacing: 4) {
                                Text(item.emoji).font(.system(size: 70))
                                Text(item.name)
                                    .font(Theme.rounded(17, .semibold))
                                    .foregroundStyle(Theme.darkGreen)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                            }
                            .frame(width: 140)
                        }
                        .pulseHighlight(model.highlightValid && task.isValid(item))
                        .accessibilityLabel(item.name)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .animation(.spring(), value: model.solved)
        .onAppear { model.start() }
    }

    private func relationLabel(_ r: String) -> String {
        switch r {
        case "food": return "🍽️ Nahrung"
        case "habitat": return "🏠 Lebensraum"
        default: return "🌱 Pflanzenteil"
        }
    }
}

@MainActor
@Observable
final class NaturePairsModel {
    @ObservationIgnored let host: GameHost
    var tasks: [NatureTask] = []
    var index = 0
    var tried: [String] = []
    var chosen: String?
    var solved = false
    var highlightValid = false
    @ObservationIgnored private var started = false

    init(host: GameHost) { self.host = host }

    var task: NatureTask? { tasks[safe: index] }
    var chosenItem: NatureItem? {
        guard let chosen, let task else { return nil }
        return task.options.first { $0.name == chosen }
    }

    func start() {
        guard !started else { return }
        started = true
        host.helpHandler = { [weak self] l in self?.help(l) }
        host.nextTaskHandler = { [weak self] in self?.advance() }
        host.summaryProvider = { [weak self] in
            guard let self else { return RoundSummary(text: "Naturpaare gefunden.") }
            let subjects = self.tasks.map(\.question.subject.name)
            return RoundSummary(text: "Vier Naturpaare gefunden: \(subjects.joined(separator: ", ")).",
                                practiced: self.tasks.map { $0.question.question })
        }
        if let saved = host.takeRestoredPayload(NaturePairsState.self), !saved.tasks.isEmpty {
            tasks = saved.tasks
            index = min(saved.index, tasks.count - 1)
            tried = saved.tried
            if host.tasksDone >= host.tasksPerRound { host.resumeIfNeeded(); return }
            if host.awaitingNext { host.next(); return }
            instruct()
        } else {
            let allowed = host.options.natureRelations
            var pool = NatureCatalog.questions.filter { allowed.contains($0.relation) }
            if pool.isEmpty { pool = NatureCatalog.questions }
            // Eine Runde verwendet eine klar bezeichnete Beziehung, wenn genügend Fragen vorhanden sind.
            let relation = Set(pool.map(\.relation)).randomElement()!
            var picked = pool.filter { $0.relation == relation }.shuffled()
            if picked.count < host.tasksPerRound {
                picked += pool.filter { $0.relation != relation }.shuffled()
            }
            tasks = picked.prefix(host.tasksPerRound).map {
                NatureCatalog.variant(of: $0, difficulty: host.difficulty, seed: UInt64.random(in: 1...UInt64.max))
            }
            index = 0
            present()
        }
    }

    private func present() {
        tried = []
        chosen = nil
        solved = false
        highlightValid = false
        save()
        instruct()
    }

    private func instruct() {
        guard let task else { return }
        if task.multipleValid {
            host.setInstruction("\(task.question.question) Finde etwas, das dazu passt.")
        } else {
            host.setInstruction(task.question.question)
        }
    }

    private func advance() {
        index = min(index + 1, tasks.count - 1)
        present()
    }

    private func save() {
        host.persist(NaturePairsState(tasks: tasks, index: index, tried: tried, chosen: chosen))
    }

    func state(for item: NatureItem) -> AnswerState {
        if solved && chosen == item.name { return .correct }
        if tried.contains(item.name) { return .tried }
        return .normal
    }

    /// Jede sachlich passende Antwort wird angenommen.
    func choose(_ item: NatureItem) {
        guard let task, !solved else { return }
        if task.isValid(item) {
            solved = true
            withAnimation(.spring()) { chosen = item.name }
            host.taskSolved("Ja, das passt! \(task.question.explanation)")
        } else {
            if !tried.contains(item.name) { tried.append(item.name) }
            save()
            host.wrong("\(item.name) passt hier nicht. Schauen wir es gemeinsam an.")
        }
    }

    private func help(_ level: Int) {
        guard let task else { return }
        switch level {
        case 1:
            let label: String
            switch task.question.relation {
            case "food": label = "Denk daran, was dieses Tier gerne isst."
            case "habitat": label = "Denk daran, wo dieses Tier wohnt."
            default: label = "Denk daran, was an dieser Pflanze wächst."
            }
            host.showBunny(label)
        case 2:
            if let wrong = task.options.first(where: { !task.isValid($0) && !tried.contains($0.name) }) {
                tried.append(wrong.name)
                save()
                host.showBunny("\(wrong.name) passt sicher nicht.")
            }
        default:
            highlightValid = true
            host.showBunny("Diese Bilder passen. \(task.question.explanation)")
        }
    }
}
