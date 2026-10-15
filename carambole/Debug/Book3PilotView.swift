#if DEBUG
import SwiftUI

/// Review-only Book 3 session. It does not write progress or use the production
/// Book 2 dialogue schema. The source is the only scrolling part of a card.
struct Book3PilotView: View {
    let onFinish: () -> Void

    @State private var index = 0
    @State private var selected: String?
    @State private var typed = ""
    @State private var checked = false
    @State private var correct = false
    @FocusState private var typingFocused: Bool

    private let cards = Self.loadCards()

    var body: some View {
        Group {
            if cards.isEmpty {
                VStack(spacing: Spacing.md) {
                    Text("Le pilote Book 3 n'a pas pu être chargé.").font(.appPrompt)
                    Button("Fermer", action: onFinish).buttonStyle(PrimaryButtonStyle())
                }
                .padding(Spacing.screenH)
            } else {
                cardView(cards[index])
            }
        }
        .background(AppColor.paper.ignoresSafeArea())
        .onAppear {
            let env = ProcessInfo.processInfo.environment
            if let requested = Int(env["CB_BOOK3_CARD"] ?? ""), cards.indices.contains(requested - 1) {
                index = requested - 1
            }
            if let card = cards.indices.contains(index) ? cards[index] : nil,
               let state = env["CB_BOOK3_CHECK"] {
                correct = state == "correct"
                checked = true
                selected = correct ? card.response.answer : card.response.choices?.first { $0 != card.response.answer }
                typed = correct ? card.response.answer : "Je ne sais pas"
            }
        }
    }

    private func cardView(_ card: Book3PilotCard) -> some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Button(action: onFinish) {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppColor.ink)
                            .frame(width: 42, height: 42)
                    }
                    .accessibilityLabel("Fermer le pilote")
                    Spacer()
                    Text(String(format: "%02d / %02d", index + 1, cards.count))
                        .font(.appBody)
                        .foregroundColor(AppColor.g2)
                }

                HStack(spacing: 8) {
                    Text("NUANCES · 01").foregroundColor(AppColor.g2)
                    Text("/").foregroundColor(AppColor.g2)
                    Text(card.format.title).foregroundColor(AppColor.ink)
                }
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .textCase(.uppercase)

                Text("Ce qui s'est passé")
                    .font(.display(size: 31, wght: 300))
                    .foregroundColor(AppColor.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(card.source.enumerated()), id: \.offset) { _, line in
                            sourceLine(line, dialogue: card.format == .dialogue)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                }
                .frame(height: sourceHeight(for: card, available: geo.size.height))
                .background(Color(hex: AppPalette.current.theme.tint))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                Text(card.task)
                    .font(.display(size: 24, wght: 350))
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)

                responseView(card)

                Spacer(minLength: 0)

                if checked {
                    VStack(alignment: .leading, spacing: 5) {
                        Text(correct ? "Juste" : "À revoir")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.ink)
                        if !correct {
                            Text(card.response.answer)
                                .font(.appBody)
                                .foregroundColor(AppColor.ink)
                        }
                        Text(card.feedback)
                            .font(.appBody)
                            .foregroundColor(AppColor.g2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color(hex: AppPalette.current.theme.quietFill).opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button(action: checked ? advance : { check(card) }) {
                    Text(checked ? (index + 1 == cards.count ? "Terminer" : "Suivant") : "Vérifier")
                        .font(.appBody)
                        .foregroundColor(AppColor.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Capsule().fill(Color(hex: AppPalette.current.theme.buttonFill)))
                }
                .buttonStyle(.plain)
                .disabled(!checked && !hasResponse(card))
                .opacity(!checked && !hasResponse(card) ? 0.45 : 1)
            }
            .padding(.horizontal, Spacing.screenH)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }

    private func sourceLine(_ line: Book3PilotCard.SourceLine, dialogue: Bool) -> some View {
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
        .padding(dialogue ? 12 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(dialogue ? AppColor.paper : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func responseView(_ card: Book3PilotCard) -> some View {
        switch card.response.kind {
        case .choices:
            VStack(spacing: 8) {
                ForEach(displayChoices(card), id: \.self) { choice in
                    Button { if !checked { selected = choice } } label: {
                        HStack(spacing: 10) {
                            Text(choice)
                                .font(.appBody)
                                .foregroundColor(AppColor.ink)
                                .multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                            if selected == choice {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColor.ink)
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                        .background(selected == choice ? Color(hex: AppPalette.current.theme.tileOn) : AppColor.paper)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.hairline, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
        case .typed:
            TextField("Écris ta réponse", text: $typed)
                .font(.appBody)
                .foregroundColor(AppColor.ink)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($typingFocused)
                .submitLabel(.done)
                .onSubmit { if hasResponse(card) && !checked { check(card) } }
                .padding(14)
                .background(AppColor.paper)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColor.hairline, lineWidth: 1))
        }
    }

    private func hasResponse(_ card: Book3PilotCard) -> Bool {
        switch card.response.kind {
        case .choices: return selected != nil
        case .typed: return !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    private func displayChoices(_ card: Book3PilotCard) -> [String] {
        let choices = card.response.choices ?? []
        let order = SituationShuffle.order(count: choices.count, seed: SituationShuffle.seed(card.id))
        return order.map { choices[$0] }
    }

    private func sourceHeight(for card: Book3PilotCard, available: CGFloat) -> CGFloat {
        switch card.format {
        case .dialogue: return min(220, max(175, available * 0.27))
        case .microtext: return min(175, max(145, available * 0.21))
        case .rewrite, .word: return min(145, max(115, available * 0.17))
        }
    }

    private func check(_ card: Book3PilotCard) {
        typingFocused = false
        correct = card.accepts(card.response.kind == .typed ? typed : (selected ?? ""))
        checked = true
    }

    private func advance() {
        guard index + 1 < cards.count else { onFinish(); return }
        index += 1
        selected = nil
        typed = ""
        checked = false
        correct = false
    }

    private static func loadCards() -> [Book3PilotCard] {
        guard let url = Bundle.main.url(forResource: "testbook_book3", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let cards = try? JSONDecoder().decode([Book3PilotCard].self, from: data),
              cards.count == 8, cards.allSatisfy({ $0.validationErrors.isEmpty }) else { return [] }
        return cards
    }
}
#endif
