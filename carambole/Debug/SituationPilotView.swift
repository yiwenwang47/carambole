#if DEBUG
import SwiftUI

/// A disposable Test book probe for the Book 2 difficulty level. It deliberately
/// keeps all state in memory and uses the app's existing palette, fonts, and
/// Speaker. The real book will use the normal element-level review path.
struct SituationPilotView: View {
    let onFinish: () -> Void

    private let scenarios = Self.load()
    @State private var index = 0
    @State private var phase: Phase = .listen
    @State private var selectedChoice: Int?
    @State private var listeningMisses = 0
    @State private var transcriptShown = false
    @State private var assisted = false
    @State private var chosenBankIndices: [Int] = []
    @State private var bankOrder: [Int] = []
    @State private var replyAttempts = 0
    @State private var replyCorrect = false

    private enum Phase {
        case listen, reply, feedback
    }

    private var item: PilotScenario { scenarios[index] }
    private var chosenChunks: [String] {
        chosenBankIndices.map { item.tokenBank[$0] }
    }

    var body: some View {
        Group {
            if scenarios.isEmpty {
                VStack(spacing: Spacing.md) {
                    Text("Le pilote n'a pas pu être chargé.").font(.appPrompt)
                    Button("Fermer", action: onFinish).buttonStyle(PrimaryButtonStyle())
                }
                .padding(Spacing.screenH)
            } else {
                pilotBody
            }
        }
        .background(AppColor.paper.ignoresSafeArea())
        .onAppear {
            resetBank()
            switch ProcessInfo.processInfo.environment["CB_PILOT_STAGE"] {
            case "reply": phase = .reply
            case "feedback": phase = .feedback; replyCorrect = true
            default: break
            }
        }
    }

    private var pilotBody: some View {
        GeometryReader { geo in
          VStack(spacing: 0) {
            HStack {
                Button("Fermer", action: onFinish)
                    .font(.appBody)
                    .foregroundColor(AppColor.ink)
                    .accessibilityLabel("Fermer le pilote")
                Spacer()
                Text("EN SITUATION · \(index + 1)/\(scenarios.count)")
                    .uppercaseLabel()
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("Au café, avant le train")
                        .font(.display(size: 29, wght: 300))
                        .foregroundColor(AppColor.ink)
                    Text(phase == .listen
                         ? item.context
                         : "Train in 10 min · takeaway · phone + card · no cash")
                        .font(.appBody)
                        .foregroundColor(AppColor.graphite)
                        .fixedSize(horizontal: false, vertical: true)

                    audioBlock

                    switch phase {
                    case .listen: listeningBlock
                    case .reply: replyBlock
                    case .feedback: feedbackBlock
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, Spacing.xl)
            }
            .scrollIndicators(.visible)

            footer
                .padding(.horizontal, Spacing.screenH)
                .padding(.vertical, Spacing.sm)
                .background(AppColor.paper)
          }
          .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private var audioBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("01 · ÉCOUTER").uppercaseLabel()
            Button {
                Speaker.shared.speak(item.turns.map(\.text).joined(separator: " … "),
                                     key: "pilot_" + item.id)
            } label: {
                HStack {
                    Text("▶  Écouter l'échange").font(.appBody)
                    Spacer()
                    Text("↺").font(.appBody)
                }
                .foregroundColor(AppColor.ink)
                .padding(Spacing.md)
                .background(RoundedRectangle(cornerRadius: 16).fill(AppColor.hairline))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Lance ou relance les deux voix en français")

            Button(transcriptShown ? "Masquer le texte" : "Afficher le texte") {
                transcriptShown.toggle()
                if transcriptShown && phase != .feedback { assisted = true }
            }
            .font(.appBody)
            .foregroundColor(AppColor.graphite)
            .accessibilityHint("Le texte peut aider à comprendre l'audio")

            if transcriptShown {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    ForEach(Array(item.turns.enumerated()), id: \.offset) { _, turn in
                        HStack(alignment: .top, spacing: 12) {
                            Text(turn.speaker).uppercaseLabel()
                                .frame(width: 74, alignment: .leading)
                            Text(turn.text).font(.appBody)
                                .foregroundColor(AppColor.ink)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(AppColor.hairline))
            }
        }
    }

    private var listeningBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("02 · COMPRENDRE").uppercaseLabel()
            Text(item.question)
                .font(.display(size: 23, wght: 350))
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(item.choices.indices, id: \.self) { choice in
                Button { selectedChoice = choice } label: {
                    HStack {
                        Text(item.choices[choice]).font(.appBody)
                        Spacer()
                        Text(selectedChoice == choice ? "●" : "○")
                    }
                    .foregroundColor(AppColor.ink)
                    .padding(Spacing.md)
                    .overlay(RoundedRectangle(cornerRadius: 15)
                        .stroke(selectedChoice == choice ? AppColor.ink : AppColor.hairline,
                                lineWidth: selectedChoice == choice ? 1.5 : 1))
                }
                .buttonStyle(.plain)
            }
            if listeningMisses > 0 {
                Text(listeningMisses == 1
                     ? "Pas encore. Réécoutez, puis choisissez une autre réponse."
                     : "Réponse : \(item.choices[item.correctChoice])")
                    .font(.appBody).foregroundColor(AppColor.graphite)
            }
        }
    }

    private var replyBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if listeningMisses >= 2 {
                Text("À l'écoute : \(item.choices[item.correctChoice])")
                    .font(.appBody)
                    .foregroundColor(AppColor.graphite)
            }
            Text("03 · RÉPONDRE").uppercaseLabel()
            Text(item.responsePrompt)
                .font(.display(size: 23, wght: 350))
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Composez une réponse qui règle la situation.")
                .font(.appBody).foregroundColor(AppColor.g2)

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(chosenChunks.isEmpty ? "Touchez les morceaux ci-dessous" : item.replyText(chosenChunks))
                    .font(.appBody)
                    .foregroundColor(chosenChunks.isEmpty ? AppColor.g2 : AppColor.ink)
                    .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
                    .padding(.horizontal, Spacing.md)
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(AppColor.ink))
                if !chosenBankIndices.isEmpty {
                    Button("Effacer la réponse") { chosenBankIndices = [] }
                        .font(.appBody).foregroundColor(AppColor.graphite)
                }
            }

            Text("MORCEAUX").uppercaseLabel()
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 8)], spacing: 8) {
                ForEach(bankOrder, id: \.self) { bankIndex in
                    let used = chosenBankIndices.contains(bankIndex)
                    Button {
                        if used {
                            chosenBankIndices.removeAll { $0 == bankIndex }
                        } else {
                            chosenBankIndices.append(bankIndex)
                        }
                    } label: {
                        Text(item.tokenBank[bankIndex])
                            .font(.appBody)
                            .foregroundColor(used ? AppColor.g3 : AppColor.ink)
                            .padding(.horizontal, 10)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .background(RoundedRectangle(cornerRadius: 12)
                                .fill(used ? AppColor.hairline : AppColor.paper))
                            .overlay(RoundedRectangle(cornerRadius: 12)
                                .stroke(used ? AppColor.hairline : AppColor.g3))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(item.tokenBank[bankIndex])
                    .accessibilityHint(used ? "Retirer de la réponse" : "Ajouter à la réponse")
                }
            }
            if replyAttempts > 0 {
                Text("Encore un essai. Vérifiez le sens de votre réponse.")
                    .font(.appBody).foregroundColor(AppColor.graphite)
            }
        }
    }

    private var feedbackBlock: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(replyCorrect ? "La situation est résolue" : "Une réponse utile")
                .font(.display(size: 25, wght: 350))
                .foregroundColor(AppColor.ink)
            Text("« \(item.modelReply) »")
                .font(.appPrompt)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button("▶  Écouter la réponse") {
                Speaker.shared.speak(item.modelReply, key: "pilot_" + item.id + "_model")
            }
            .font(.appBody).foregroundColor(AppColor.ink)
            Text(item.explanationEN)
                .font(.appBody).foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            Text("LA SUITE").uppercaseLabel()
            Text("« \(item.followUp) »")
                .font(.appBody).foregroundColor(AppColor.ink)
            Button("▶  Écouter la suite") {
                Speaker.shared.speak(item.followUp, key: "pilot_" + item.id + "_followup")
            }
            .font(.appBody).foregroundColor(AppColor.ink)
            if assisted || listeningMisses > 0 || replyAttempts > 1 {
                Text("Cet essai a utilisé une aide ou un deuxième essai.")
                    .font(.appBody).foregroundColor(AppColor.g2)
            }
        }
    }

    private var footer: some View {
        Button {
            switch phase {
            case .listen: checkListening()
            case .reply: checkReply()
            case .feedback: next()
            }
        } label: {
            Text(phase == .feedback
                 ? (index == scenarios.count - 1 ? "Terminer" : "Échange suivant")
                 : "Vérifier")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled((phase == .listen && selectedChoice == nil)
                  || (phase == .reply && chosenBankIndices.isEmpty))
        .opacity(((phase == .listen && selectedChoice == nil)
                  || (phase == .reply && chosenBankIndices.isEmpty)) ? 0.45 : 1)
    }

    private func checkListening() {
        guard let selectedChoice else { return }
        if selectedChoice == item.correctChoice {
            phase = .reply
        } else {
            listeningMisses += 1
            self.selectedChoice = nil
            if listeningMisses >= 2 { phase = .reply }
        }
    }

    private func checkReply() {
        replyAttempts += 1
        replyCorrect = item.accepts(chosenChunks)
        if replyCorrect || replyAttempts >= 2 {
            phase = .feedback
        } else {
            chosenBankIndices = []
        }
    }

    private func next() {
        if index == scenarios.count - 1 {
            onFinish()
            return
        }
        index += 1
        phase = .listen
        selectedChoice = nil
        listeningMisses = 0
        transcriptShown = false
        assisted = false
        chosenBankIndices = []
        replyAttempts = 0
        replyCorrect = false
        resetBank()
    }

    private func resetBank() {
        guard !scenarios.isEmpty else { return }
        bankOrder = Array(item.tokenBank.indices).shuffled()
    }

    private static func load() -> [PilotScenario] {
        guard let url = Bundle.main.url(forResource: "testbook_situation", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONDecoder().decode([PilotScenario].self, from: data)
        else { return [] }
        for item in items where !item.validationErrors.isEmpty {
            print("Situation pilot \(item.id): \(item.validationErrors.joined(separator: ", "))")
            return []
        }
        return items
    }
}
#endif
