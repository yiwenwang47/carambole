#if DEBUG
import SwiftUI

/// Test book probe for Book 2 (design rework, 2026-10-11): short café dialogues
/// on one locked chat card, 1–2 drills each, six drill types. Server lines are
/// outlined bubbles, the learner's are filled with the palette's placed-magnet
/// colour. Any word shows its English above it on tap — never by default. State
/// is in memory only; nothing is scheduled. Reference mock:
/// https://claude.ai/artifact/WisTx5oe1Jq5ZW3h6SL6gN
struct SituationPilotView: View {
    let onFinish: () -> Void

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    private let content = Self.load()

    @State private var index = 0
    @State private var step = 0
    @State private var finished = false
    @State private var misses = 0
    @State private var failed = false
    // Per-drill state.
    @State private var tries = 0
    @State private var selected: Int?
    @State private var wrongChoices: Set<Int> = []
    @State private var rightChoice: Int?
    @State private var placed: [Int] = []
    @State private var bankOrder: [Int] = []
    /// Répondre answers already refused this drill: Vérifier stays off until
    /// the placed tiles change (`SituationRetry`).
    @State private var rejectedReplies: [[String]] = []
    @State private var note = ""
    @State private var slot: Slot = .hidden
    @State private var gapText: String?
    @State private var gapSettled = false
    @State private var fixPhase: FixPhase = .find
    @State private var flashedWord: String?
    @State private var errorFixed = false
    @State private var showFollow = false
    /// True while a solved drill settles, before the next one slides in.
    @State private var locked = false
    /// Every wrong attempt this session, in order. Shown after each dialogue
    /// and on the closing summary; the real book saves these (action plan).
    @State private var mistakes: [Mistake] = []
    /// Ratings per finished dialogue, for the closing summary.
    @State private var results: [String: Rating] = [:]
    @State private var showSummary = false
    /// Dialogue change: old content fades out, then the new one rises in.
    @State private var contentOpacity: Double = 1
    @State private var contentOffset: CGFloat = 0
    /// Natural height of the reply tiles, so the tray can shrink and scroll.
    @State private var trayContentHeight: CGFloat = 0
    /// Card fit (shared with the production card): the dialogue keeps its
    /// height and the reply tray gives up space instead.
    @State private var fit = SituationCardFit()
    /// The reply bubble swaps tiles → text in place, without a crossfade.
    @State private var slotSwapInstant = false
    // Tap-to-show English.
    @State private var tip: Tip?
    @State private var tipToken = 0
    /// Simulator flag: keep the launch-flag tip open for a screenshot.
    @State private var tipPinned = false
    /// When a word was last tapped, so the card-wide tap that closes the tip
    /// can tell a tap on a word from a tap anywhere else.
    @State private var lastWordTap = Date.distantPast
    // Going back, as in the production card: finished dialogues kept as they
    // ended; `live` holds the one in play while an earlier one is shown.
    @State private var finishedCards: [Int: CardState] = [:]
    @State private var live: CardState?

    /// One curve for every drill-to-drill and dialogue-to-dialogue change.
    private static let motion = Animation.smooth(duration: 0.5)
    private static let tileSpring = Animation.spring(response: 0.32, dampingFraction: 0.82)
    /// Rise-and-fade for content that replaces content.
    private static let swap = AnyTransition.asymmetric(
        insertion: .opacity.combined(with: .offset(y: 14))
            .animation(.smooth(duration: 0.45).delay(0.16)),
        removal: .opacity.animation(.easeOut(duration: 0.16)))

    private enum Rating { case good, hard, again }

    private struct Mistake: Identifiable {
        let id = UUID()
        let dialogueID: String
        let element: String
        /// Drill name as shown ("Corriger", or a standalone label).
        let title: String
        /// What the learner gave, as shown.
        let given: String
        /// The right answer.
        let expected: String
        /// English reason, when the content has one.
        let why: String?
    }

    private var dialogueMistakes: [Mistake] { mistakes.filter { $0.dialogueID == dialogue.id } }

    private func log(_ given: String, expected: String, why: String?) {
        guard let drill else { return }
        mistakes.append(Mistake(dialogueID: dialogue.id, element: dialogue.element,
                                title: dialogue.standalone ?? drill.type.title,
                                given: given, expected: expected, why: why))
    }

    private enum Slot: Equatable { case hidden, building, preview(String), done(String, ok: Bool) }

    private struct CardState {
        var index = 0, step = 0, finished = false
        var misses = 0, failed = false, tries = 0
        var selected: Int?, rightChoice: Int?
        var wrongChoices: Set<Int> = []
        var placed: [Int] = [], bankOrder: [Int] = []
        var rejectedReplies: [[String]] = []
        var note = ""
        var slot: Slot = .hidden
        var gapText: String?
        var gapSettled = false, errorFixed = false, showFollow = false
        var fixPhase: FixPhase = .find
    }
    private enum FixPhase { case find, choose }
    private struct Tip: Equatable { let id: String; let french: String; let english: String }

    private var dialogues: [PilotDialogue] { content?.dialogues ?? [] }
    private var glossary: [String: String] { content?.glossary ?? [:] }
    private var dialogue: PilotDialogue { dialogues[index] }
    private var drill: PilotDrill? { finished ? nil : dialogue.drills[step] }

    var body: some View {
        Group {
            if dialogues.isEmpty {
                VStack(spacing: Spacing.md) {
                    Text("Le pilote n'a pas pu être chargé.").font(.appPrompt)
                    Button("Fermer", action: onFinish).buttonStyle(PrimaryButtonStyle())
                }
                .padding(Spacing.screenH)
            } else if showSummary {
                summary.transition(.opacity)
            } else {
                card
            }
        }
        .background(AppColor.paper.ignoresSafeArea())
        .onAppear(perform: applyLaunchFlags)
    }

    // MARK: - Card

    private var card: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                topBar
                cueBlock
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.header = $0 }
            // With a word tray below, the chat keeps room for all its bubbles
            // and the tray shrinks (its tiles scroll) instead; the card itself
            // never scrolls, and the cue never covers a speaker label.
            chat
                .frame(minHeight: fit.chatFloor(trayShown: drill?.type == .reply))
                .opacity(contentOpacity)
                .offset(y: contentOffset)
            Rectangle().fill(AppColor.hairline).frame(height: 1).padding(.top, 10)
            ZStack(alignment: .topLeading) {
                zone
                    .id("\(index)-\(step)-\(finished)")
                    .transition(Self.swap)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
            .padding(.horizontal, 18)
            .padding(.top, 22)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.zone = $0 }
            .layoutPriority(1)
            Spacer(minLength: 0).frame(maxHeight: 4)
            footer
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.footer = $0 }
                .layoutPriority(2)
        }
        .frame(minHeight: 0, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.card = $0 }
        .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
            let dx = value.translation.width, dy = value.translation.height
            guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }
            if dx > 0 { goBack() } else if canGoForward { goForward() }
        })
        .overlayPreferenceValue(TipAnchorKey.self) { anchors in
            GeometryReader { proxy in
                if let tip, let anchor = anchors[tip.id] {
                    tipBubble(tip, word: proxy[anchor], width: proxy.size.width)
                }
            }
            .allowsHitTesting(false)
        }
        // Any tap off a word closes the tip at once. Runs alongside the word's own
        // tap, in either order; a fresh word tap within the same touch keeps it.
        .simultaneousGesture(TapGesture().onEnded {
            guard tip != nil else { return }
            DispatchQueue.main.async {
                if Date().timeIntervalSince(lastWordTap) > 0.15 {
                    withAnimation(.easeOut(duration: 0.15)) { tip = nil }
                }
            }
        })
        .task(id: tipToken) {
            guard tip != nil, !tipPinned else { return }
            try? await Task.sleep(nanoseconds: 2_600_000_000)
            if !Task.isCancelled { withAnimation(.easeOut(duration: 0.15)) { tip = nil } }
        }
    }

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: onFinish) {
                Image(systemName: "xmark").font(.system(size: 17, weight: .medium)).foregroundColor(AppColor.ink)
                    .frame(width: 32, height: 32)
            }
            .accessibilityLabel("Fermer le pilote")
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.hairline)
                    Capsule().fill(AppColor.ink)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
            HStack(spacing: 0) {
                navChevron("‹", label: "Dialogue précédent", enabled: canGoBack, action: goBack)
                Text("\(index + 1)/\(dialogues.count)")
                    .font(.label(size: 12)).foregroundColor(AppColor.g2).monospacedDigit()
                navChevron("›", label: "Dialogue suivant", enabled: canGoForward, action: goForward)
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 8)
    }

    private func navChevron(_ glyph: String, label: String, enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.display(size: 20, wght: 300))
                .foregroundColor(AppColor.ink)
                .frame(width: 24, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(enabled ? 1 : 0)
        .disabled(!enabled)
        .accessibilityLabel(label)
        .accessibilityHidden(!enabled)
    }

    private var progress: CGFloat {
        CGFloat(index + (finished ? 1 : 0)) / CGFloat(max(1, dialogues.count))
    }

    private var cueBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(live == nil ? (dialogue.place ?? "Au café")
                 : "Révision · " + (dialogue.place ?? "Au café")).uppercaseLabel()
            ZStack(alignment: .leading) {
                Text(dialogue.cue).font(.display(size: 21, wght: 400)).foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(contentOpacity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 16)
    }

    // MARK: - Chat

    private var chat: some View {
        GeometryReader { geo in
            ScrollViewReader { reader in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        Spacer(minLength: 0)
                        VStack(spacing: 10) {
                            ForEach(Array(dialogue.turns.enumerated()), id: \.offset) { i, turn in
                                if turn.isLearner {
                                    learnerBubble(turnIndex: i, turn: turn)
                                } else {
                                    serverBubble(id: "t\(i)", name: turn.speakerLabel, text: turn.text,
                                                 audioKey: "pilot2_\(dialogue.id)_t\(i)",
                                                 locked: turn.text.contains("___") && !gapSettled)
                                }
                            }
                            if slot != .hidden {
                                slotBubble.transition(Self.swap)
                            }
                            if showFollow, let followUp = dialogue.followUp {
                                serverBubble(id: "f", name: dialogue.followUpSpeaker, text: followUp,
                                             audioKey: "pilot2_\(dialogue.id)_f")
                                    .transition(Self.swap)
                            }
                        }
                        // The bubbles' own height (the spacer above would grow with
                        // the chat and feed back into the fit), plus the top
                        // padding, the end marker and its spacing.
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.chatContent = $0 + 19 }
                        .id(index)
                        .transition(.identity)
                        Color.clear.frame(height: 1).id("end")
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .frame(minHeight: geo.size.height, alignment: .bottom)
                }
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
                .onScrollPhaseChange { _, phase in if phase == .interacting { tip = nil } }
                .onChange(of: slot) { _, _ in scrollToEnd(reader) }
                // Keep the learner's answer in view as it grows (tiles placed, gap
                // filled) and when the drill zone below grows and shrinks the chat.
                .onChange(of: placed) { _, _ in scrollToEnd(reader) }
                .onChange(of: gapText) { _, _ in scrollToEnd(reader) }
                .onChange(of: step) { _, _ in scrollToEnd(reader) }
                .onChange(of: geo.size.height) { _, _ in scrollToEnd(reader) }
                .onChange(of: showFollow) { _, _ in scrollToEnd(reader) }
                .onChange(of: index) { _, _ in scrollToEnd(reader) }
                .onAppear { scrollToEnd(reader) }
            }
        }
    }

    private func scrollToEnd(_ reader: ScrollViewProxy) {
        DispatchQueue.main.async { withAnimation(.easeOut(duration: 0.25)) { reader.scrollTo("end", anchor: .bottom) } }
    }

    private func speakerLabel(_ text: String) -> some View {
        Text(text).font(.label(size: 10.5)).tracking(1.2).foregroundColor(AppColor.g2).padding(.horizontal, 6)
    }

    /// `locked`: the clip voices the gap's answer, so it stays off until the gap is settled.
    private func serverBubble(id: String, name: String?, text: String, audioKey: String,
                              locked: Bool = false) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                if let name { speakerLabel(name.uppercased()) }
                HStack(alignment: .top, spacing: 10) {
                    Button { Speaker.shared.speak(text, key: audioKey) } label: {
                        Image(systemName: "play.fill").font(.system(size: 10)).foregroundColor(AppColor.ink)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(hex: theme.quietFill)))
                    }
                    .disabled(locked)
                    .opacity(locked ? 0.35 : 1)
                    .accessibilityLabel(name.map { "Écouter \($0)" } ?? "Écouter")
                    lineText(id: id, text: text, turnIndex: nil)
                        .padding(.top, 2)
                }
                .padding(.vertical, 11).padding(.horizontal, 13)
                .background(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, bottomLeading: 6,
                                                                      bottomTrailing: 20, topTrailing: 20))
                    .fill(AppColor.white))
                .overlay(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, bottomLeading: 6,
                                                                   bottomTrailing: 20, topTrailing: 20))
                    .strokeBorder(AppColor.ink, lineWidth: 1.5))
            }
            Spacer(minLength: 40)
        }
    }

    private func learnerShape() -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(cornerRadii: .init(topLeading: 20, bottomLeading: 20, bottomTrailing: 6, topTrailing: 20))
    }

    private func learnerBubble(turnIndex: Int, turn: PilotDialogue.Turn) -> some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 3) {
                speakerLabel(turn.isSource ? "VOUS · AVANT" : "VOUS")
                lineText(id: "t\(turnIndex)", text: turn.text, turnIndex: turnIndex)
                    .padding(.vertical, 11).padding(.horizontal, 15)
                    // The line to rewrite sits grey, so the new reply reads as the answer.
                    .background(learnerShape().fill(turn.isSource ? AppColor.hairline : Color(hex: theme.tileOn)))
            }
        }
    }

    private var slotBubble: some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 3) {
                speakerLabel("VOUS")
                switch slot {
                case .building:
                    Group {
                        if placed.isEmpty {
                            Text("votre réponse").font(.display(size: 15, wght: 400)).foregroundColor(AppColor.g2)
                                .padding(.horizontal, 10).frame(minWidth: 130, minHeight: 34)
                        } else {
                            FlowLayout(spacing: 6, lineSpacing: 6) {
                                ForEach(placed, id: \.self) { bankIndex in
                                    Button { guard !locked else { return }; withAnimation(Self.tileSpring) { placed.removeAll { $0 == bankIndex } } } label: {
                                        MagnetTile(text: bank[bankIndex], style: .placed)
                                    }
                                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                                    .buttonStyle(.plain)
                                    .accessibilityLabel("Retirer \(bank[bankIndex])")
                                }
                            }
                        }
                    }
                    .padding(8)
                    .background(learnerShape().fill(AppColor.white))
                    .overlay(learnerShape().strokeBorder(AppColor.g3, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                    .transition(.identity)
                case .preview(let text):
                    Text(text).font(.display(size: 18, wght: 400)).foregroundColor(AppColor.ink)
                        .padding(.vertical, 11).padding(.horizontal, 15)
                        .background(learnerShape().fill(AppColor.white))
                        .overlay(learnerShape().strokeBorder(AppColor.g3, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                        .transition(.identity)
                case .done(let text, let ok):
                    lineText(id: "s", text: text, turnIndex: nil)
                        .padding(.vertical, 11).padding(.horizontal, 15)
                        .background(learnerShape().fill(ok ? Color(hex: theme.tileOn) : AppColor.hairline))
                        .transition(.identity)
                case .hidden:
                    EmptyView()
                }
            }
            .transaction { $0.disablesAnimations = slotSwapInstant }
        }
    }

    private var bank: [String] { drill?.bank ?? [] }
    private var canCheckReply: Bool {
        SituationRetry.canCheck(placed.map { bank[$0] }, rejected: rejectedReplies)
    }

    // MARK: - Words

    private func lineText(id: String, text: String, turnIndex: Int?) -> some View {
        let fixLine = turnIndex != nil && turnIndex == dialogue.errorTurnIndex
        let segments = PilotText.segments(text, glossary: glossary,
                                          keepApart: fixLine ? dialogue.errorTurnIndex.flatMap { dialogue.turns[$0].error?.word } : nil)
        return FlowLayout(spacing: 5, lineSpacing: 4) {
            ForEach(segments, id: \.index) { seg in
                segmentView(seg, lineID: id, fixLine: fixLine)
            }
        }
    }

    @ViewBuilder
    private func segmentView(_ seg: PilotText.Segment, lineID: String, fixLine: Bool) -> some View {
        let font = Font.display(size: 19, wght: 400)
        if seg.kind == .gap {
            HStack(spacing: 0) {
                gapView
                Text(seg.trailing).font(font).foregroundColor(AppColor.ink)
            }
        } else {
            let wordID = "\(lineID)-\(seg.index)"
            let mark = fixLine ? dialogue.turns[dialogue.errorTurnIndex!].error : nil
            let isError = mark.map { PilotText.norm(seg.display) == PilotText.norm($0.word) } ?? false
            let struck = isError && fixPhase == .choose && drill?.type == .fix && !errorFixed
            let shown = isError && errorFixed ? matchCase(mark!.fix, like: seg.display) : seg.display
            let isNew = seg.key.map { dialogue.newWords.contains($0) } ?? false
            // Word + its trailing punctuation as one Text, so no gap opens
            // before a comma or full stop.
            (Text(shown).underline(isNew && !fixLine, color: AppColor.g2) + Text(seg.trailing))
                .font(font)
                .foregroundColor(AppColor.ink)
                // The word being corrected gets a white fill on the learner bubble
                // (no strike, no extra colour) and loses it once fixed.
                .background(RoundedRectangle(cornerRadius: 5)
                    .fill(struck ? AppColor.white : highlight(wordID: wordID, key: seg.key)).padding(-3))
                // A wrong tap shakes the word instead of flashing a colour.
                .modifier(Shake(amount: flashedWord == wordID ? 1 : 0))
                .anchorPreference(key: TipAnchorKey.self, value: .bounds) { [wordID: $0] }
                .contentShape(Rectangle())
                .onTapGesture { tapWord(seg, wordID: wordID, fixLine: fixLine, isError: isError) }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(seg.key == nil ? "" : "Affiche l'anglais")
        }
    }

    private func highlight(wordID: String, key: String?) -> Color {
        if tip?.id == wordID { return Color.white.opacity(0.9) }
        if drill?.type == .word, let key, key == drill?.target { return Color(hex: theme.tint) }
        return .clear
    }

    private var gapView: some View {
        let filled = gapText != nil
        return Text(gapText ?? " ")
            .font(.display(size: 19, wght: 400))
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, gapSettled ? 0 : 8)
            .frame(minWidth: gapSettled ? 0 : 70)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(filled && !gapSettled ? Color(hex: theme.tileOn) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(gapSettled ? .clear : (filled ? AppColor.ink : AppColor.g2),
                              style: StrokeStyle(lineWidth: 1.5, dash: filled ? [] : [4, 3])))
    }

    private func matchCase(_ word: String, like original: String) -> String {
        guard let first = original.first, first.isUppercase else { return word }
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    private func tapWord(_ seg: PilotText.Segment, wordID: String, fixLine: Bool, isError: Bool) {
        if fixLine && drill?.type == .fix && fixPhase == .find {
            withAnimation(Self.motion) { tapFix(isError: isError, wordID: wordID, word: seg.display) }
            return
        }
        guard let key = seg.key, let english = glossary[key] else { return }
        lastWordTap = Date()
        withAnimation(.easeOut(duration: 0.15)) {
            tip = Tip(id: wordID, french: seg.display, english: english)
        }
        tipPinned = false
        tipToken += 1
    }

    private func tipBubble(_ tip: Tip, word: CGRect, width: CGFloat) -> some View {
        let estimate = min(240, CGFloat(max(tip.french.count, tip.english.count)) * 8.4 + 28)
        let centerX = min(max(word.midX, estimate / 2 + 10), width - estimate / 2 - 10)
        return VStack(spacing: 0) {
            VStack(spacing: 1) {
                Text(tip.french).font(.label(size: 12, wght: 500)).opacity(0.65)
                Text(tip.english).font(.display(size: 15, wght: 500))
            }
            .multilineTextAlignment(.center)
            .foregroundColor(AppColor.white)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.ink))
            TipArrow().fill(AppColor.ink).frame(width: 14, height: 7)
                .offset(x: word.midX - centerX)
        }
        .fixedSize()
        .frame(width: width, height: max(0, word.minY - 4), alignment: .bottom)
        .offset(x: centerX - width / 2)
        .transition(.opacity)
    }

    // MARK: - Drill zone

    @ViewBuilder
    private var zone: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let drill {
                HStack {
                    Text(dialogue.standalone ?? drill.type.title).uppercaseLabel()
                    Spacer()
                    if dialogue.isStandalone {
                        Text("Phrase seule").uppercaseLabel()
                    } else if dialogue.drills.count > 1 {
                        Text("\(step + 1)/\(dialogue.drills.count)").uppercaseLabel()
                    }
                }
                Text(promptText(drill))
                    .font(.display(size: 21, wght: 350))
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                drillBody(drill)
                Text(note.isEmpty && index == 0 && step == 0 && tries == 0 && drill.type != .fix
                     ? "Touchez un mot pour voir l'anglais." : note)
                    .font(.display(size: 14, wght: 400))
                    .foregroundColor(AppColor.graphite)
                    .frame(minHeight: 20, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                doneBlock
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func promptText(_ drill: PilotDrill) -> String {
        if drill.type == .fix, fixPhase == .choose, let mark = errorMark {
            return "What should « \(mark.word) » be?"
        }
        return drill.prompt
    }

    private var errorMark: PilotDialogue.Turn.ErrorMark? {
        dialogue.errorTurnIndex.flatMap { dialogue.turns[$0].error }
    }

    @ViewBuilder
    private func drillBody(_ drill: PilotDrill) -> some View {
        switch drill.type {
        case .comprehend, .word:
            choiceGrid(drill.choices ?? [], columns: (drill.choices?.count ?? 2), stacked: false) { c in withAnimation(Self.motion) { instant(c) } }
        case .pick:
            choiceGrid(drill.choices ?? [], columns: 1, stacked: true) { c in withAnimation(Self.motion) { select(c) } }
        case .complete:
            choiceGrid(drill.choices ?? [], columns: 3, stacked: false) { c in withAnimation(Self.motion) { select(c) } }
        case .fix:
            if fixPhase == .choose, let mark = errorMark {
                choiceGrid(mark.choices, columns: 3, stacked: false) { c in withAnimation(Self.motion) { if !locked { selected = c } } }
            }
        case .reply:
            // The tray asks for its full height; when the dialogue above needs
            // the room, it shrinks and its tiles scroll inside it, clipped to
            // its rounded edge. The card itself never scrolls.
            ScrollView(.vertical, showsIndicators: false) {
                FlowLayout(spacing: 8, lineSpacing: 8) {
                    ForEach(bankOrder, id: \.self) { i in
                        let used = placed.contains(i)
                        Button { guard !locked else { return }; withAnimation(Self.tileSpring) { placed.append(i) } } label: { MagnetTile(text: bank[i]) }
                            .buttonStyle(.plain)
                            .opacity(used ? 0.25 : 1)
                            .disabled(used)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, minHeight: 96)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { trayContentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(minHeight: SituationCardFit.trayMin, maxHeight: max(96, trayContentHeight))
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.tray = $0 }
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: theme.tint)))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    private func choiceGrid(_ choices: [String], columns: Int, stacked: Bool,
                            action: @escaping (Int) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, columns)), spacing: 8) {
            ForEach(choices.indices, id: \.self) { i in
                let isRight = rightChoice == i
                let isWrong = wrongChoices.contains(i)
                let isSel = selected == i
                Button { action(i) } label: {
                    Text(choices[i])
                        .font(.display(size: stacked ? 17 : 16, wght: 400))
                        .foregroundColor(AppColor.ink)
                        .multilineTextAlignment(stacked ? .leading : .center)
                        .frame(maxWidth: .infinity, minHeight: 24, alignment: stacked ? .leading : .center)
                        .padding(.vertical, 13).padding(.horizontal, stacked ? 14 : 8)
                        .background(RoundedRectangle(cornerRadius: 16)
                            .fill(isRight ? Color(hex: theme.tileOn) : AppColor.white))
                        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(
                            isWrong ? Color(hex: theme.fragile) : (isRight || isSel ? AppColor.ink : AppColor.hairline),
                            style: StrokeStyle(lineWidth: 1.5, dash: isWrong ? [4, 3] : [])))
                }
                .buttonStyle(.plain)
                .disabled(isWrong || rightChoice != nil)
            }
        }
    }

    private var doneBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fini").uppercaseLabel()
                Spacer()
                Text(dialogue.standalone ?? dialogue.drills.map(\.type.title).joined(separator: " + ")).uppercaseLabel()
            }
            Text(failed ? "Pas trouvé. On le reverra bientôt."
                 : misses > 0 ? "Réussi avec un essai de plus." : "Du premier coup.")
                .font(.display(size: 21, wght: 350)).foregroundColor(AppColor.ink)
            if !dialogueMistakes.isEmpty {
                Text("Vos erreurs").uppercaseLabel()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(dialogueMistakes) { mistakeRow($0, compact: true) }
                }
            }
            if !dialogue.newWords.isEmpty {
                Text("Nouveaux mots").uppercaseLabel()
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(dialogue.newWords, id: \.self) { word in
                        (Text(word).foregroundColor(AppColor.ink)
                         + Text(" · \(glossary[word] ?? "")").foregroundColor(AppColor.graphite))
                            .font(.display(size: 14, wght: 400))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 10).fill(AppColor.hairline))
                    }
                }
            }
        }
    }

    private func mistakeRow(_ m: Mistake, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(m.title.uppercased() + "  ").font(.label(size: 11)).foregroundColor(AppColor.g2)
             + Text("Vous : " + m.given).font(.display(size: 14, wght: 400)).foregroundColor(AppColor.graphite)
             + Text("  →  " + m.expected).font(.display(size: 14, wght: 500)).foregroundColor(AppColor.ink))
            if !compact, let why = m.why, !why.isEmpty {
                Text(why).font(.display(size: 13, wght: 400)).foregroundColor(AppColor.graphite)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Closing screen: one line per dialogue, then every wrong attempt with
    /// its reason. This screen may scroll; it is not a drill card.
    private var summary: some View {
        let counts = (good: results.values.filter { $0 == .good }.count,
                      hard: results.values.filter { $0 == .hard }.count,
                      again: results.values.filter { $0 == .again }.count)
        return VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Séance terminée").font(.display(size: 30, wght: 300)).foregroundColor(AppColor.ink)
                    Text("\(counts.good) du premier coup · \(counts.hard) avec un essai de plus · \(counts.again) à revoir")
                        .font(.display(size: 15, wght: 400)).foregroundColor(AppColor.graphite)
                    if mistakes.isEmpty {
                        Text("Aucune erreur.").font(.display(size: 19, wght: 350)).foregroundColor(AppColor.ink)
                    } else {
                        Text("Vos erreurs · \(mistakes.count)").uppercaseLabel()
                        ForEach(dialogues.filter { d in mistakes.contains { $0.dialogueID == d.id } }) { d in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(d.element).font(.display(size: 17, wght: 500)).foregroundColor(AppColor.ink)
                                ForEach(mistakes.filter { $0.dialogueID == d.id }) { mistakeRow($0, compact: false) }
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(AppColor.hairline, lineWidth: 1))
                        }
                    }
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 40)
                .padding(.bottom, 20)
            }
            Button("Fermer", action: onFinish)
                .buttonStyle(DrillButtonStyle())
                .padding(.horizontal, 18).padding(.bottom, 8)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        let (label, enabled): (String, Bool) = {
            if let live { return (index + 1 == live.index ? "Reprendre" : "Suivant", true) }
            guard let drill else {
                return (index == dialogues.count - 1 ? "Terminer" : "Suivant", true)
            }
            switch drill.type {
            case .comprehend, .word: return ("Choisissez une réponse", false)
            case .fix where fixPhase == .find: return ("Touchez le mot", false)
            case .reply: return ("Vérifier", canCheckReply)
            default: return ("Vérifier", selected != nil)
            }
        }()
        return Button {
            if live != nil { goForward() } else if drill == nil { nextDialogue() } else { withAnimation(Self.motion) { check() } }
        } label: {
            Text(label).contentTransition(.identity)
        }
        .buttonStyle(DrillButtonStyle())
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    // MARK: - Logic

    private func startDrill() {
        tries = 0; selected = nil; wrongChoices = []; rightChoice = nil
        placed = []; rejectedReplies = []; note = ""; fixPhase = .find; flashedWord = nil
        trayContentHeight = 0
        guard let drill else { return }
        if drill.type == .reply || drill.type == .pick { slot = .building }
        if drill.type == .reply { bankOrder = Array((drill.bank ?? []).indices).shuffled() }
    }

    private func instant(_ choice: Int) {
        guard !locked, let drill, let correct = drill.correct else { return }
        if choice == correct {
            rightChoice = choice
            advanceSoon(0.7)
            return
        }
        misses += 1; tries += 1
        wrongChoices.insert(choice)
        log(drill.choices?[choice] ?? "", expected: drill.choices?[correct] ?? "", why: drill.miss)
        if tries >= 2 {
            failed = true
            note = "Answer: \(drill.choices?[correct] ?? "")."
            rightChoice = correct
            advanceSoon(1.7)
        } else {
            note = drill.miss ?? "Pas encore. Touchez un mot pour voir l'anglais."
        }
    }

    private func select(_ choice: Int) {
        guard !locked, let drill, let choices = drill.choices else { return }
        selected = choice
        if drill.type == .pick { slot = .preview(choices[choice]) } else { gapText = choices[choice] }
    }

    private func check() {
        guard !locked, let drill else { return }
        switch drill.type {
        case .reply:
            // An answer already refused (unchanged since the miss) never spends a try.
            guard canCheckReply else { return }
            let tiles = placed.map { bank[$0] }
            tries += 1
            if drill.accepts(tiles) {
                fillSlot(tiles.joined(separator: " "), ok: true); advanceSoon(0.75)
            } else {
                misses += 1
                let keep = drill.correctPrefixCount(tiles)
                log(tiles.joined(separator: " "), expected: drill.model ?? "",
                    why: keep > 0 ? "The start « \(tiles.prefix(keep).joined(separator: " ")) » was right." : nil)
                if tries < 2 {
                    placed = Array(placed.prefix(keep))
                    rejectedReplies += SituationRetry.rejected(after: tiles, keep: keep)
                    note = "Pas encore : « \(tiles.joined(separator: " ")) »"
                        + (keep > 0 ? ". The start is kept; fix the rest." : ". Try again.")
                } else {
                    failed = true
                    fillSlot(drill.model ?? "", ok: false); advanceSoon(1.1)
                }
            }
        case .pick, .complete:
            guard let selected, let correct = drill.correct, let choices = drill.choices else { return }
            tries += 1
            if selected == correct {
                settle(drill, text: choices[correct], ok: true)
            } else if tries < 2 {
                misses += 1; wrongChoices.insert(selected)
                log(choices[selected], expected: choices[correct], why: drill.why?[selected])
                note = drill.why?[selected] ?? "Pas encore."
                self.selected = nil
                if drill.type == .pick { slot = .building } else { gapText = nil }
            } else {
                misses += 1; failed = true
                log(choices[selected], expected: choices[correct], why: drill.why?[selected])
                settle(drill, text: choices[correct], ok: false)
            }
        case .fix:
            guard let selected, let mark = errorMark else { return }
            tries += 1
            if mark.choices[selected] != mark.fix {
                log("\(mark.word) → \(mark.choices[selected])", expected: "\(mark.word) → \(mark.fix)",
                    why: mark.why)
            }
            if mark.choices[selected] == mark.fix || tries >= 2 {
                if mark.choices[selected] != mark.fix { misses += 1; failed = true }
                errorFixed = true; advanceSoon(0.75)
            } else {
                misses += 1; wrongChoices.insert(selected); self.selected = nil
                note = mark.why ?? "Pas encore."
            }
        case .comprehend, .word:
            break
        }
    }

    /// Tiles/preview → final text in place, so old and new never overlap.
    private func fillSlot(_ text: String, ok: Bool) {
        slotSwapInstant = true
        slot = .done(text, ok: ok)
        DispatchQueue.main.async { slotSwapInstant = false }
    }

    private func settle(_ drill: PilotDrill, text: String, ok: Bool) {
        if drill.type == .pick {
            fillSlot(text, ok: ok)
        } else {
            gapText = text; gapSettled = true
        }
        advanceSoon(ok ? 0.75 : 1.1)
    }

    private func tapFix(isError: Bool, wordID: String, word: String) {
        guard !locked, let drill else { return }
        if isError {
            fixPhase = .choose; tries = 0; note = ""
            return
        }
        misses += 1; tries += 1
        if let mark = errorMark {
            log("« \(word) »", expected: "wrong word: « \(mark.word) »", why: "« \(word) » was fine.")
        }
        withAnimation(.linear(duration: 0.35)) { flashedWord = wordID }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { if flashedWord == wordID { flashedWord = nil } }
        }
        if tries >= 2 {
            failed = true
            fixPhase = .choose; tries = 0
            note = "It was « \(errorMark?.word ?? "") »."
        } else {
            note = drill.miss ?? "That word is fine."
        }
    }

    /// Let the solved state (green bubble, filled gap, right choice) sit for a
    /// beat, then move on in one animated step. Input is ignored meanwhile.
    private func advanceSoon(_ delay: Double) {
        locked = true
        let current = index
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard current == index else { return }
            withAnimation(Self.motion) { advance() }
        }
    }

    private func advance() {
        locked = false
        if step + 1 < dialogue.drills.count {
            step += 1
            startDrill()
        } else {
            finished = true
            note = ""
            results[dialogue.id] = failed ? .again : (misses > 0 ? .hard : .good)
            let current = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard current == index, finished else { return }
                withAnimation(Self.motion) { showFollow = true }
            }
        }
    }

    /// The finished card is complete once its follow-up shows (if it has one).
    private var settled: Bool { showFollow || dialogue.followUp == nil }

    private func nextDialogue() {
        if index == dialogues.count - 1 {
            withAnimation(Self.motion) { showSummary = true }
            return
        }
        guard !locked else { return }
        locked = true
        var kept = captureCard()
        kept.showFollow = true
        finishedCards[index] = kept
        withAnimation(.easeIn(duration: 0.24)) { contentOpacity = 0; contentOffset = -8 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) {
                index += 1
                resetDialogue()
                contentOffset = 18
            }
            withAnimation(Self.motion) { contentOpacity = 1; contentOffset = 0 }
        }
    }

    private func resetDialogue() {
        step = 0; finished = false; misses = 0; failed = false; locked = false
        slot = .hidden; gapText = nil; gapSettled = false; errorFixed = false
        showFollow = false; tip = nil
        startDrill()
    }

    // MARK: - Going back

    private var canGoBack: Bool { !locked && finishedCards[index - 1] != nil }
    private var canGoForward: Bool { live != nil }

    private func captureCard() -> CardState {
        CardState(index: index, step: step, finished: finished, misses: misses, failed: failed, tries: tries,
                  selected: selected, rightChoice: rightChoice, wrongChoices: wrongChoices,
                  placed: placed, bankOrder: bankOrder, rejectedReplies: rejectedReplies, note: note,
                  slot: slot, gapText: gapText, gapSettled: gapSettled, errorFixed: errorFixed,
                  showFollow: showFollow, fixPhase: fixPhase)
    }

    private func restoreCard(_ c: CardState) {
        index = c.index; step = c.step; finished = c.finished; misses = c.misses; failed = c.failed
        tries = c.tries; selected = c.selected; rightChoice = c.rightChoice; wrongChoices = c.wrongChoices
        placed = c.placed; bankOrder = c.bankOrder; rejectedReplies = c.rejectedReplies; note = c.note
        slot = c.slot; gapText = c.gapText; gapSettled = c.gapSettled; errorFixed = c.errorFixed
        showFollow = c.showFollow || c.finished
        fixPhase = c.fixPhase
    }

    private func swapCard(_ change: @escaping () -> Void) {
        Speaker.shared.stop()
        tip = nil
        withAnimation(.easeIn(duration: 0.18)) { contentOpacity = 0 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { change() }
            withAnimation(Self.motion) { contentOpacity = 1 }
        }
    }

    private func goBack() {
        guard canGoBack, let earlier = finishedCards[index - 1] else { return }
        let current = live == nil ? captureCard() : nil
        swapCard {
            if let current { live = current }
            restoreCard(earlier)
        }
    }

    private func goForward() {
        guard let liveCard = live else { return }
        let next = index + 1
        swapCard {
            if next < liveCard.index, let later = finishedCards[next] {
                restoreCard(later)
            } else {
                restoreCard(liveCard)
                live = nil
            }
        }
    }

    // MARK: - Launch flags (simulator checks)

    /// CB_PILOT_INDEX=n opens dialogue n; CB_PILOT_STEP=n jumps to drill n;
    /// CB_PILOT_STAGE=fill|done previews a filled answer or the finished state;
    /// CB_PILOT_TIP=<gloss key> opens the English above that word.
    /// CB_PILOT_AUTOPLAY=1 answers every drill correctly, one action every
    /// ~1.1 s, so transitions can be recorded on the simulator.
    private func autoStep(wrongFirst: Bool) -> Bool {
        guard !locked, !showSummary else { return !showSummary }
        guard let drill else {
            guard settled else { return true }
            nextDialogue(); return true
        }
        if wrongFirst && misses == 0 && tries == 0 && wrongChoices.isEmpty {
            withAnimation(Self.motion) { autoWrong(drill) }
            return true
        }
        withAnimation(Self.motion) {
            switch drill.type {
            case .comprehend, .word:
                if let c = drill.correct { instant(c) }
            case .reply:
                let target = drill.accepted?.first ?? []
                if placed.count < target.count {
                    let tile = target[placed.count]
                    if let i = bank.indices.first(where: { bank[$0] == tile && !placed.contains($0) }) {
                        withAnimation(Self.tileSpring) { placed.append(i) }
                    }
                } else { check() }
            case .pick, .complete:
                if selected == nil, let c = drill.correct { select(c) } else { check() }
            case .fix:
                if fixPhase == .find { tapFix(isError: true, wordID: "", word: errorMark?.word ?? "") }
                else if selected == nil, let mark = errorMark { selected = mark.choices.firstIndex(of: mark.fix) }
                else { check() }
            }
        }
        return true
    }

    /// One wrong attempt per drill (CB_PILOT_AUTOPLAY=wrong).
    private func autoWrong(_ drill: PilotDrill) {
        let wrongIndex = ((drill.correct ?? 0) + 1) % max(1, drill.choices?.count ?? 1)
        switch drill.type {
        case .comprehend, .word: instant(wrongIndex)
        case .pick, .complete: select(wrongIndex); check()
        case .reply:
            let target = drill.accepted?.first ?? []
            var used: [Int] = []
            for tile in target.dropLast() {
                if let i = bank.indices.first(where: { bank[$0] == tile && !used.contains($0) }) { used.append(i) }
            }
            if let odd = bank.indices.first(where: { !used.contains($0) && !target.contains(bank[$0]) }) { used.append(odd) }
            placed = used; check()
        case .fix:
            let line = dialogue.errorTurnIndex.map { dialogue.turns[$0].text } ?? ""
            let first = PilotText.tokens(line).first ?? ""
            tapFix(isError: false, wordID: "auto", word: first)
        }
    }

    private func applyLaunchFlags() {
        let env = ProcessInfo.processInfo.environment
        if let mode = env["CB_PILOT_AUTOPLAY"] {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                // CB_PILOT_BACK_AT=n: stop on dialogue n and go back one (checks the review view).
                let backAt = env["CB_PILOT_BACK_AT"].flatMap(Int.init)
                while autoStep(wrongFirst: mode == "wrong") {
                    try? await Task.sleep(nanoseconds: 1_100_000_000)
                    if let backAt, index == backAt, !locked { goBack(); break }
                }
            }
        }
        if let n = env["CB_PILOT_INDEX"].flatMap(Int.init), dialogues.indices.contains(n) { index = n }
        resetDialogue()
        if let n = env["CB_PILOT_STEP"].flatMap(Int.init), dialogue.drills.indices.contains(n) {
            step = n; startDrill()
        }
        switch env["CB_PILOT_STAGE"] {
        case "fill":
            guard let drill else { break }
            switch drill.type {
            case .reply:
                let first = drill.accepted?.first ?? []
                var used: [Int] = []
                for tile in first {
                    if let i = bank.indices.first(where: { bank[$0] == tile && !used.contains($0) }) { used.append(i) }
                }
                placed = used
            case .pick, .complete: if let c = drill.correct { select((c + 1) % (drill.choices?.count ?? 1)) }
            case .fix: fixPhase = .choose; selected = 0
            case .comprehend, .word: wrongChoices = [1]; note = drill.miss ?? ""; misses = 1; tries = 1
            }
        case "done":
            for d in dialogue.drills {
                if d.type == .reply { slot = .done(d.model ?? "", ok: true) }
                if d.type == .pick, let c = d.correct { slot = .done(d.choices?[c] ?? "", ok: true) }
                if d.type == .complete, let c = d.correct { gapText = d.choices?[c]; gapSettled = true }
                if d.type == .fix { errorFixed = true }
            }
            finished = true; showFollow = true
        default: break
        }
        if let key = env["CB_PILOT_TIP"] {
            for (i, turn) in dialogue.turns.enumerated() {
                if let seg = PilotText.segments(turn.text, glossary: glossary).first(where: { $0.key == key }) {
                    tip = Tip(id: "t\(i)-\(seg.index)", french: seg.display, english: glossary[key] ?? "")
                    tipPinned = true
                    break
                }
            }
        }
    }

    private static func load() -> PilotContent? {
        guard let url = Bundle.main.url(forResource: "testbook_situation", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let content = try? JSONDecoder().decode(PilotContent.self, from: data)
        else { return nil }
        let errors = content.validationErrors
        if !errors.isEmpty {
            print("Situation pilot: \(errors.joined(separator: "; "))")
            return nil
        }
        return content
    }
}

/// Bounds of each tappable word, keyed by line + segment, so the English can
/// sit directly above the tapped word.
private struct TipAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct TipArrow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
/// Two quick side-to-side wiggles as `amount` animates 0 → 1.
private struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 4 * sin(amount * .pi * 4), y: 0))
    }
}
#endif
