import SwiftUI

/// Zugang zum Elternbereich mit dem sechsstelligen Code.
struct ParentGateView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var error: String?
    @State private var mode: Mode = .enter
    @State private var challenge = AdultChallenge.make()
    @State private var answer = ""
    @State private var newCode: String?

    enum Mode { case enter, recover, newCode }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                switch mode {
                case .enter:
                    if app.data.parentCodeHash.isEmpty {
                        Text("Es ist noch kein Elterncode festgelegt.")
                            .font(Theme.rounded(22, .semibold))
                        Button("Code festlegen") { mode = .newCode }
                            .buttonStyle(BigButtonStyle())
                    } else {
                        CodePadView(title: "Elterncode eingeben", errorMessage: error) { code in
                            if CodeHasher.hash(code) == app.data.parentCodeHash {
                                error = nil
                                dismiss()
                                app.audio.stopAll()
                                app.screen = .parents
                            } else {
                                error = "Dieser Code stimmt nicht."
                            }
                        }
                        Button("Code vergessen?") {
                            challenge = AdultChallenge.make()
                            answer = ""
                            mode = .recover
                        }
                        .font(Theme.rounded(18, .semibold))
                        .frame(minHeight: 48)
                    }
                case .recover:
                    Text("Für Erwachsene")
                        .font(Theme.rounded(26))
                    Text("Lösen Sie die Aufgabe, um einen neuen Code festzulegen.")
                        .font(Theme.rounded(18, .medium))
                        .multilineTextAlignment(.center)
                    Text(challenge.question)
                        .font(Theme.rounded(40, .heavy))
                    TextField("Ergebnis", text: $answer)
                        .keyboardType(.numberPad)
                        .font(Theme.rounded(30))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 220)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.creamDark))
                    if let error { Text(error).foregroundStyle(Theme.gentleRed) }
                    Button("Prüfen") {
                        if Int(answer.trimmingCharacters(in: .whitespaces)) == challenge.answer {
                            error = nil
                            mode = .newCode
                        } else {
                            error = "Das Ergebnis stimmt nicht."
                            challenge = AdultChallenge.make()
                            answer = ""
                        }
                    }
                    .buttonStyle(BigButtonStyle())
                case .newCode:
                    CodePadView(title: newCode == nil ? "Neuen Code eingeben" : "Neuen Code wiederholen", errorMessage: error) { code in
                        if let first = newCode {
                            if first == code {
                                app.update { $0.parentCodeHash = CodeHasher.hash(code) }
                                newCode = nil
                                error = nil
                                mode = .enter
                            } else {
                                newCode = nil
                                error = "Die Codes stimmen nicht überein."
                            }
                        } else {
                            newCode = code
                            error = nil
                        }
                    }
                }
            }
            .padding(30)
            .foregroundStyle(Theme.darkGreen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.cream)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schliessen") { dismiss() }
                }
            }
        }
    }
}
