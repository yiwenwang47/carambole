import SwiftUI

/// One visible-source Nuances card at a time. Progress is saved when a card is
/// resolved, so closing the session does not discard an answer.
struct NuanceSessionView: View {
    struct Entry: Equatable {
        let element: GrammarElement
        let card: NuanceCard
        let presentationCount: Int
    }

    let title: String
    let ruleNote: String
    let mode: SessionMode
    let module: CourseModule?
    let canStart: Bool
    let onFinish: () -> Void

    @State private var queue: [Entry]
    @State private var showingIntro: Bool
    @State private var cursor = 0
    @State private var selected: String?
    @State private var typed = ""
    @State private var priorMisses = 0
    @State private var reviewingParaphrase = false
    @State private var result: NuanceAttemptPolicy.Outcome?
    @State private var pendingTooEasy = false
    @State private var tooEasyUndoElementID: String?
    @State private var tooEasyUndoToken = 0
    @FocusState private var typingFocused: Bool

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    init(book: Book, title: String, ruleNote: String, elements: [GrammarElement], mode: SessionMode,
         module: CourseModule? = nil, canStart: Bool = true, onFinish: @escaping () -> Void) {
        self.title = title
        self.ruleNote = ruleNote
        self.mode = mode
        self.module = module
        self.canStart = canStart
        self.onFinish = onFinish
        #if DEBUG
        let forcedCard = Self.debugCard(in: book)
        _queue = State(initialValue: forcedCard.map { [$0] }
            ?? Self.buildQueue(elements: elements, mode: mode))
        _showingIntro = State(initialValue: forcedCard == nil && mode == .learn && module != nil)
        if forcedCard != nil {
            switch ProcessInfo.processInfo.environment["CB_NUANCE_PREVIEW"] {
            case "wrong": _result = State(initialValue: .again)
            case "tooEasy": _pendingTooEasy = State(initialValue: true)
            default: break
            }
        }
        #else
        _queue = State(initialValue: Self.buildQueue(elements: elements, mode: mode))
        _showingIntro = State(initialValue: mode == .learn && module != nil)
        #endif
    }

    #if DEBUG
    /// Opens one authored card in Test book without requiring earlier modules'
    /// progress. Set CB_NUANCE_CARD to its card ID, then enter any Nuances session.
    private static func debugCard(in book: Book) -> Entry? {
        guard let id = ProcessInfo.processInfo.environment["CB_NUANCE_CARD"] else { return nil }
        for element in book.allElements {
            if let card = element.nuanceCards.first(where: { $0.id == id }) {
                return Entry(element: element, card: card, presentationCount: 0)
            }
        }
        return nil
    }
    #endif

    private static func buildQueue(elements: [GrammarElement], mode: SessionMode) -> [Entry] {
        let chosen: [GrammarElement]
        switch mode {
        case .learn:
            chosen = elements.first(where: { !$0.nuanceCards.isEmpty }).map { [$0] } ?? []
        case .review:
            chosen = elements.filter { !$0.nuanceCards.isEmpty }
        }
        return chosen.flatMap { element in
            let history = DataManager.shared.fetchNuanceCardHistory(elementID: element.id)
            let cards = NuanceCardSelector.select(from: element.nuanceCards, history: history,
                                                   limit: mode == .learn ? 3 : 1,
                                                   mode: mode == .learn ? .learn : .review)
            return cards.map { Entry(element: element, card: $0,
                                     presentationCount: history[$0.id]?.times ?? 0) }
        }
    }

    var body: some View {
        Group {
            if showingIntro { intro }
            else if queue.indices.contains(cursor) { cardView(queue[cursor]) }
            else { completion }
        }
        .background(AppColor.paper.ignoresSafeArea())
        .tooEasyUndo(elementID: $tooEasyUndoElementID, token: tooEasyUndoToken)
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack { closeButton; Spacer() }
            Text(module.map { "Leçon · module \($0.sortOrder)" } ?? "Leçon")
                .uppercaseLabel(AppColor.g2)
            Text(title)
                .font(.display(size: 40, wght: 250))
                .foregroundColor(AppColor.ink)
            Text(ruleNote)
                .font(.appBody)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            if let first = queue.first {
                Text(first.element.ruleNote)
                    .font(.appBody)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(!canStart ? "Verrouillé" : (queue.isEmpty ? "Aucun exercice" : "Commencer")) {
                showingIntro = false
            }
            .buttonStyle(DrillButtonStyle())
            .disabled(!canStart || queue.isEmpty)
        }
        .padding(Spacing.screenH)
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer()
            Text(title).uppercaseLabel(AppColor.g2)
            Text(queue.isEmpty ? (mode == .review ? "Rien à réviser" : "Rien à apprendre") : "Terminé")
                .font(.display(size: 40, wght: 250))
                .foregroundColor(AppColor.ink)
            Spacer()
            Button("Terminer", action: onFinish).buttonStyle(DrillButtonStyle())
        }
        .padding(Spacing.screenH)
    }

    private var closeButton: some View {
        Button(action: onFinish) {
            Image(systemName: "xmark")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(AppColor.ink)
                .frame(width: 42, height: 42)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quitter")
    }

    private func cardView(_ entry: Entry) -> some View {
        let card = entry.card
        return GeometryReader { geo in
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    closeButton
                    Spacer()
                    Text(String(format: "%02d / %02d", cursor + 1, queue.count))
                        .font(.appBody)
                        .foregroundColor(AppColor.g2)
                }
                Text(entry.element.label)
                    .font(.display(size: 30, wght: 300))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(card.format.title.uppercased())
                    .uppercaseLabel(AppColor.g2)

                ScrollView {
                    VStack(alignment: .leading, spacing: card.format == .dialogue ? 18 : 12) {
                        ForEach(Array(card.source.enumerated()), id: \.offset) { _, line in
                            sourceLine(line)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .frame(height: result == nil ? sourceHeight(card, available: geo.size.height) : 115)
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(hex: theme.tint)))

                Text(card.task)
                    .font(.display(size: 24, wght: 350))
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                responseView(card, presentationCount: entry.presentationCount)
                Spacer(minLength: 0)

                if reviewingParaphrase {
                    paraphraseReview(card)
                } else if let result {
                    feedback(card, result: result)
                } else if priorMisses > 0 {
                    Text("Essaie encore.").font(.appBody).foregroundColor(AppColor.g2)
                }

                if result == nil && !reviewingParaphrase &&
                    NuanceAttemptPolicy.canArmTooEasy(priorMisses: priorMisses) {
                    TooEasyControl(pending: $pendingTooEasy)
                }

                if !reviewingParaphrase {
                    Button(result == nil ? "Vérifier" : (cursor + 1 == queue.count ? "Terminer" : "Suivant")) {
                        if result == nil { submit(card) } else { advance() }
                    }
                    .buttonStyle(DrillButtonStyle())
                    .disabled(result == nil && !hasResponse(card))
                    .opacity(result == nil && !hasResponse(card) ? 0.45 : 1)
                }
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func sourceLine(_ line: NuanceCard.SourceLine) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let speaker = line.speaker {
                Text(speaker.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.7)
                    .foregroundColor(AppColor.g2)
            }
            Text(line.text)
                .font(.appBody)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func responseView(_ card: NuanceCard, presentationCount: Int) -> some View {
        switch card.response.kind {
        case .choices:
            VStack(spacing: 8) {
                ForEach(displayChoices(card, presentationCount: presentationCount), id: \.self) { choice in
                    Button {
                        if result == nil { selected = choice }
                    } label: {
                        HStack(spacing: 10) {
                            Text(choice)
                                .font(.appBody)
                                .foregroundColor(AppColor.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            if selected == choice {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(AppColor.ink)
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(selected == choice ? Color(hex: theme.tileOn) : AppColor.paper)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.hairline, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(result != nil)
                }
            }
        case .typed:
            TextField("Écris ta réponse", text: $typed)
                .font(.appBody)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($typingFocused)
                .submitLabel(.done)
                .onSubmit { if hasResponse(card) && result == nil && !reviewingParaphrase { submit(card) } }
                .padding(14)
                .background(AppColor.paper)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.hairline, lineWidth: 1))
                .disabled(result != nil || reviewingParaphrase)
        }
    }

    private func paraphraseReview(_ card: NuanceCard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Réponse proposée").uppercaseLabel(AppColor.g2)
            Text(card.response.answer).font(.appBody).foregroundColor(AppColor.ink)
            Text("Ta réponse exprime-t-elle bien la même idée ?")
                .font(.appBody).foregroundColor(AppColor.graphite)
            Button("Oui, formulation équivalente") { finish(.hard) }
                .buttonStyle(DrillButtonStyle())
            if priorMisses < 2 {
                Button("Réessayer") {
                    reviewingParaphrase = false
                    typed = ""
                }
                .buttonStyle(.plain)
            }
            Button("Non, réponse différente") { finish(.again) }
                .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func feedback(_ card: NuanceCard, result: NuanceAttemptPolicy.Outcome) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(result == .good ? "Juste" : result == .hard ? "Bien repris" : "À revoir")
                .font(.system(size: 13, weight: .semibold))
            if result == .again {
                Text(card.response.answer)
                    .font(.appBody)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(card.feedback)
                .font(.appBody)
                .foregroundColor(AppColor.g2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundColor(AppColor.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: theme.quietFill).opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func sourceHeight(_ card: NuanceCard, available: CGFloat) -> CGFloat {
        switch card.format {
        case .dialogue: return min(190, max(170, available * 0.22))
        case .microtext: return min(175, max(145, available * 0.21))
        case .rewrite, .word: return min(145, max(115, available * 0.17))
        }
    }

    private func displayChoices(_ card: NuanceCard, presentationCount: Int) -> [String] {
        let choices = card.response.choices ?? []
        let key = NuanceAttemptPolicy.presentationKey(cardID: card.id, times: presentationCount)
        let order = SituationShuffle.order(count: choices.count, seed: SituationShuffle.seed(key))
        return order.map { choices[$0] }
    }

    private func hasResponse(_ card: NuanceCard) -> Bool {
        switch card.response.kind {
        case .choices: return selected != nil
        case .typed: return !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func submit(_ card: NuanceCard) {
        typingFocused = false
        let answer = card.response.kind == .typed ? typed : (selected ?? "")
        if card.accepts(answer) {
            finish(NuanceAttemptPolicy.exactOutcome(priorMisses: priorMisses))
            return
        }
        priorMisses += 1
        if pendingTooEasy {
            finish(.again)
            return
        }
        switch NuanceAttemptPolicy.mismatch(priorMisses: priorMisses - 1,
                                            typed: card.response.kind == .typed) {
        case .retry:
            selected = nil
        case .reviewParaphrase:
            reviewingParaphrase = true
        case .again:
            finish(.again)
        }
    }

    private func finish(_ outcome: NuanceAttemptPolicy.Outcome) {
        guard result == nil, queue.indices.contains(cursor) else { return }
        typingFocused = false
        reviewingParaphrase = false
        result = outcome
        let entry = queue[cursor]
        let element = entry.element
        let card = entry.card
        let now = Date()
        let gate: (ReviewStatus) -> Bool = { status in
            NuanceMastery.gateMet(correctCardIDs: status.masteredExampleIDs,
                                  cards: element.nuanceCards)
        }
        if pendingTooEasy {
            let removed = outcome == .good
            TooEasyGate.resolve(elementID: element.id, exampleID: card.id, removed: removed,
                                now: now, graduationGate: gate)
            if removed {
                DataManager.shared.logNuanceCard(cardID: card.id, elementID: element.id,
                                                  rating: 3, at: now)
                tooEasyUndoElementID = element.id
                tooEasyUndoToken += 1
            } else {
                DataManager.shared.clearNuanceCardHistory(elementID: element.id)
            }
            // Keep answered cards in place so `cursor` and its feedback remain
            // stable; only skip later cards from this group.
            queue = Array(queue.prefix(cursor + 1)) +
                queue.dropFirst(cursor + 1).filter { $0.element.id != element.id }
        } else {
            let rating: FSRS.Rating = outcome == .good ? .good : (outcome == .hard ? .hard : .again)
            ElementGrader.grade(elementID: element.id, exampleID: card.id, rating: rating,
                                now: now, graduationGate: gate)
            DataManager.shared.logNuanceCard(cardID: card.id, elementID: element.id,
                                              rating: outcome == .good ? 3 : (outcome == .hard ? 2 : 1),
                                              at: now)
        }
        pendingTooEasy = false
    }

    private func advance() {
        guard result != nil else { return }
        cursor += 1
        selected = nil
        typed = ""
        priorMisses = 0
        reviewingParaphrase = false
        result = nil
        pendingTooEasy = false
    }
}
