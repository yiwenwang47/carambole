//
//  SituationSessionView.swift
//  carambole
//
//  *En situation* (Book 2) study session: short dialogues and standalone drills
//  on one locked chat card, 1–2 drills each, six drill types. Ported from the
//  approved Test book pilot (`Debug/SituationPilotView.swift`) into the real
//  study loop: every finished item is graded with FSRS on its element
//  (`ElementGrader`), logged for Réviser selection (`situation_item_log`), and
//  every wrong attempt is saved (`situation_attempt_log`).
//
//  Binding UI rules (docs/plans/2026-10-11-book-2-pilot-v2-handoff.md):
//  - The card never scrolls as a whole. Only the chat scrolls; when space is
//    short the chat gives up room first, then the word tray shrinks and its
//    tiles scroll inside it.
//  - English only on tap, in a tooltip right above the word (spoken forms show
//    `* `). New words are underlined. A tap anywhere else closes the tooltip.
//  - Learner bubbles use the palette's `tileOn`; server bubbles are white with
//    an ink outline. No strike-through, no colour flash in Corriger.
//  - Motion timings match the pilot; don't speed them up.
//  - French text is visible from the start; audio is replay only (auto-speak,
//    when the learner turns it on, reads the follow-up line).
//

import SwiftUI

struct SituationSessionView: View {
    let book: Book
    let title: String
    let ruleNote: String
    let mode: SessionMode
    /// The module whose Leçon card opens a learn session (nil for Réviser).
    let module: CourseModule?
    let canStart: Bool
    let autoSpeak: Bool
    let onFinish: () -> Void

    init(book: Book, title: String, ruleNote: String, elements: [GrammarElement], mode: SessionMode,
         module: CourseModule? = nil, canStart: Bool = true, autoSpeak: Bool = false,
         onFinish: @escaping () -> Void) {
        self.book = book
        self.title = title
        self.ruleNote = ruleNote
        self.mode = mode
        self.module = module
        self.canStart = canStart
        self.autoSpeak = autoSpeak
        self.onFinish = onFinish
        _cards = State(initialValue: Self.buildQueue(book: book, elements: elements, mode: mode))
        _showingIntro = State(initialValue: mode == .learn && module != nil)
    }

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    /// One presentation: an item of an element. `salt` changes each time the
    /// item comes back, so its choices reshuffle between reviews.
    struct Card: Equatable {
        let element: GrammarElement
        let item: SituationItem
        let salt: Int
    }

    @State private var cards: [Card]
    @State private var showingIntro: Bool

    @State private var index = 0
    @State private var step = 0
    @State private var finished = false
    /// Outcome of each solved drill of the current item (worst wins).
    @State private var drillOutcomes: [SituationOutcome] = []
    // Per-drill state. Choice indices are AUTHORED indices; only the display
    // order is shuffled, so grading never depends on screen position.
    @State private var tries = 0
    @State private var drillMisses = 0
    @State private var drillFailed = false
    @State private var selected: Int?
    @State private var wrongChoices: Set<Int> = []
    @State private var rightChoice: Int?
    @State private var placed: [Int] = []
    @State private var bankOrder: [Int] = []
    /// Répondre answers already refused this drill (`SituationRetry`):
    /// Vérifier stays off until the placed tiles differ from all of them.
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
    /// Every wrong attempt this session, in order (also saved to the database).
    @State private var mistakes: [Mistake] = []
    /// Outcome per finished card index, for the closing summary.
    @State private var results: [Int: SituationOutcome] = [:]
    @State private var showSummary = false
    @State private var contentOpacity: Double = 1
    @State private var contentOffset: CGFloat = 0
    @State private var slotSwapInstant = false
    /// Natural height of the reply tiles, so the tray can shrink below it and
    /// scroll when the card is short.
    @State private var trayContentHeight: CGFloat = 0
    /// Card fit (the card never scrolls): the dialogue keeps its full height and
    /// the reply tray gives up space instead. Measured heights, in points.
    @State private var fit = SituationCardFit()
    // Tap-to-show English.
    @State private var tip: Tip?
    @State private var tipToken = 0
    @State private var tipPinned = false
    @State private var lastWordTap = Date.distantPast
    // Going back (like Book 1): each finished card is kept as it ended, and an
    // earlier one can be looked at read-only. `live` holds the card in play
    // while one is being looked at; nil means the card in play is on screen.
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

    private struct Mistake: Identifiable {
        let id = UUID()
        let cardIndex: Int
        let elementTitle: String
        /// Drill name as shown ("Corriger", or a standalone label).
        let title: String
        let given: String
        let expected: String
        let why: String?
    }

    private enum Slot: Equatable { case hidden, building, preview(String), done(String, ok: Bool) }

    /// Everything that draws one card, so a finished card can be shown again
    /// and the card in play put back exactly as it was.
    private struct CardState {
        var index = 0, step = 0, finished = false
        var drillOutcomes: [SituationOutcome] = []
        var tries = 0, drillMisses = 0, drillFailed = false
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

    private var card: Card { cards[index] }
    private var item: SituationItem { card.item }
    private var drill: SituationDrill? { finished ? nil : item.drills[step] }
    private var wordKeys: Set<String> { Set(book.words.keys) }
    private var newWordKeys: Set<String> { Set(item.newWords.map(SituationText.norm)) }
    private var cardMistakes: [Mistake] { mistakes.filter { $0.cardIndex == index } }

    var body: some View {
        Group {
            if showingIntro {
                intro.transition(.opacity)
            } else if cards.isEmpty {
                emptyState
            } else if showSummary {
                summary.transition(.opacity)
            } else {
                cardView
            }
        }
        .background(AppColor.paper.ignoresSafeArea())
        .onAppear {
            if !showingIntro && !cards.isEmpty { resetDialogue() }
            #if DEBUG
            applyLaunchFlags()
            #endif
        }
        .onDisappear { Speaker.shared.stop() }
    }

    private func exit() {
        Speaker.shared.stop()
        onFinish()
    }

    // MARK: - Queue

    /// Learn: per element, its next unseen items in authored order (two
    /// dialogues and a standalone). Review: one item per element — a missed one
    /// first, else unseen, else the oldest, varying the drill type.
    static func buildQueue(book: Book, elements: [GrammarElement], mode: SessionMode) -> [Card] {
        #if DEBUG
        if let forced = debugQueue(book: book) { return forced }
        #endif
        var out: [Card] = []
        for element in elements where !element.items.isEmpty {
            let history = DataManager.shared.fetchSituationItemHistory(elementID: element.id)
            func card(_ item: SituationItem) -> Card {
                Card(element: element, item: item, salt: history[item.id]?.times ?? 0)
            }
            switch mode {
            case .learn:
                out += SituationSelector.learnItems(element.items, history: history).map(card)
            case .review:
                let last = history.max { $0.value.lastDone < $1.value.lastDone }?.key
                let lastKinds = element.items.first { $0.id == last }?.drillKinds ?? []
                if let item = SituationSelector.reviewItem(element.items, history: history, lastKinds: lastKinds) {
                    out.append(card(item))
                }
            }
        }
        return out
    }

    // MARK: - Intro (Leçon) and empty state

    private var intro: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack { closeButton.padding(.leading, -8); Spacer() }
                .padding(.top, 8)
                .padding(.bottom, -Spacing.md)
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(hex: theme.quietFill))
                .overlay(alignment: .bottomTrailing) {
                    if let n = module?.sortOrder {
                        Text("\(n)")
                            .font(.display(size: 190, wght: 200))
                            .tracking(-11)
                            .foregroundColor(AppColor.ink.opacity(0.9))
                            .lineLimit(1)
                            .fixedSize()
                            .offset(x: 6, y: 52)
                    }
                }
                .overlay(alignment: .topLeading) {
                    Text(module.map { "Leçon · module \($0.sortOrder)" } ?? "Leçon")
                        .uppercaseLabel(AppColor.ink)
                        .padding(18)
                }
                .frame(height: 190)
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .accessibilityElement(children: .combine)
                .padding(.top, Spacing.md)
            Text(title)
                .font(.display(size: 40, wght: 250))
                .tracking(-1.2)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(ruleNote)
                .font(.appBody)
                .lineSpacing(4)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            if let module {
                Text(module.elements.map(\.label).joined(separator: " · "))
                    .font(.display(size: 14, wght: 400))
                    .foregroundColor(AppColor.g2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(!canStart ? "Verrouillé" : (cards.isEmpty ? "Aucun exercice" : "Commencer")) {
                resetDialogue()
                withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) { showingIntro = false }
            }
            .buttonStyle(DrillButtonStyle())
            .disabled(!canStart || cards.isEmpty)
            .opacity(canStart && !cards.isEmpty ? 1 : 0.4)
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Spacer(minLength: Spacing.xl)
            SectionLabel(title)
            Text(mode == .review ? "Rien à réviser" : "Rien à apprendre")
                .font(.display(size: 40, wght: 250))
                .tracking(-1.2)
                .foregroundColor(AppColor.ink)
            Text(mode == .review
                 ? "Aucun dialogue à réviser pour le moment. Reviens plus tard."
                 : "Tu as parcouru tout le contenu disponible.")
                .font(.appBody)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Button("Terminer", action: exit).buttonStyle(DrillButtonStyle())
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.bottom, Spacing.sm)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var closeButton: some View {
        Button(action: exit) {
            Image(systemName: "xmark").font(.system(size: 17, weight: .medium)).foregroundColor(AppColor.ink)
                .frame(width: 32, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Quitter")
    }

    // MARK: - Card

    private var cardView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                topBar
                cueBlock
            }
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.header = $0 }
            // The chat takes what is left and scrolls inside itself. With a word
            // tray below, the chat keeps room for all its bubbles and the tray
            // shrinks (its tiles scroll) instead, so the cue never covers a
            // speaker label.
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
            footer
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.footer = $0 }
                .layoutPriority(2)
        }
        .frame(minHeight: 0, maxHeight: .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.card = $0 }
        // Swipe right for the previous dialogue, left to come back (Book 1's gesture).
        .simultaneousGesture(DragGesture(minimumDistance: 24).onEnded { value in
            let dx = value.translation.width, dy = value.translation.height
            guard abs(dx) > 60, abs(dx) > abs(dy) * 1.5 else { return }
            if dx > 0 { goBack() } else if canGoForward { goForward() }
        })
        .overlayPreferenceValue(SituationTipAnchorKey.self) { anchors in
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
            closeButton
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColor.hairline)
                    Capsule().fill(AppColor.ink)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 4)
            .accessibilityHidden(true)
            HStack(spacing: 0) {
                navChevron("‹", label: "Dialogue précédent", enabled: canGoBack, action: goBack)
                Text("\(index + 1)/\(cards.count)")
                    .font(.label(size: 12)).foregroundColor(AppColor.g2).monospacedDigit()
                    .accessibilityLabel("Dialogue \(index + 1) sur \(cards.count)")
                navChevron("›", label: "Dialogue suivant", enabled: canGoForward, action: goForward)
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 8)
    }

    /// Book 1's ‹ › chevrons; invisible when there is nowhere to go.
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
        CGFloat(index + (finished ? 1 : 0)) / CGFloat(max(1, cards.count))
    }

    private var cueBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(live == nil ? (item.place ?? card.element.label)
                 : "Révision · " + (item.place ?? card.element.label)).uppercaseLabel()
            Text(item.cue).font(.display(size: 21, wght: 400)).foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(contentOpacity)
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
                            ForEach(Array(item.turns.enumerated()), id: \.offset) { i, turn in
                                if turn.isLearner {
                                    learnerBubble(turnIndex: i, turn: turn)
                                } else {
                                    serverBubble(id: "t\(i)", name: turn.speakerLabel, text: turn.text,
                                                 audioKey: item.turnAudioKey(i),
                                                 locked: i == item.gapTurnIndex && !gapSettled)
                                }
                            }
                            if slot != .hidden {
                                slotBubble.transition(Self.swap)
                            }
                            if showFollow, let followUp = item.followUp {
                                serverBubble(id: "f", name: item.followUpSpeaker, text: followUp,
                                             audioKey: item.followUpAudioKey)
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
                // Café handoff fix 1: the answer bubble stays in view. Pin to the
                // bottom when the content grows, and scroll whenever a tile is
                // placed, a gap is filled or the drill step changes.
                .defaultScrollAnchor(.bottom, for: .sizeChanges)
                .onScrollPhaseChange { _, phase in if phase == .interacting { tip = nil } }
                .onChange(of: slot) { _, _ in scrollToEnd(reader) }
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
        let hasAudio = Speaker.bundledAudioURL(key: audioKey) != nil && !locked
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                if let name { speakerLabel(name.uppercased()) }
                HStack(alignment: .top, spacing: 10) {
                    // Replay only. A missing clip leaves the text and a dimmed button.
                    Button { Speaker.shared.playBundled(key: audioKey) } label: {
                        Image(systemName: "play.fill").font(.system(size: 10)).foregroundColor(AppColor.ink)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color(hex: theme.quietFill)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!hasAudio)
                    .opacity(hasAudio ? 1 : 0.35)
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

    private func learnerBubble(turnIndex: Int, turn: SituationItem.Turn) -> some View {
        HStack {
            Spacer(minLength: 40)
            VStack(alignment: .trailing, spacing: 3) {
                speakerLabel(turn.isSource ? "VOUS · AVANT" : "VOUS")
                    .accessibilityLabel(turn.isSource ? "Vous, avant" : "Vous")
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
                                .accessibilityLabel("Votre réponse, vide")
                        } else {
                            FlowLayout(spacing: 6, lineSpacing: 6) {
                                ForEach(placed, id: \.self) { bankIndex in
                                    Button {
                                        guard !locked else { return }
                                        withAnimation(Self.tileSpring) { placed.removeAll { $0 == bankIndex } }
                                    } label: {
                                        MagnetTile(text: bank[bankIndex], style: .placed)
                                    }
                                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(bank[bankIndex])
                                    .accessibilityHint("Retire ce mot de votre réponse")
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
                        .accessibilityLabel("Votre réponse : \(text)")
                        .padding(.vertical, 11).padding(.horizontal, 15)
                        .background(learnerShape().fill(AppColor.white))
                        .overlay(learnerShape().strokeBorder(AppColor.g3, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                        .transition(.identity)
                case .done(let text, let ok):
                    lineText(id: "s", text: text, turnIndex: nil)
                        .padding(.vertical, 11).padding(.horizontal, 15)
                        .background(learnerShape().fill(ok ? Color(hex: theme.tileOn) : AppColor.hairline))
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(ok ? "Votre réponse" : "La bonne réponse")
                        .transition(.identity)
                case .hidden:
                    EmptyView()
                }
            }
            .transaction { $0.disablesAnimations = slotSwapInstant }
        }
    }

    private var bank: [String] { drill?.bank ?? [] }
    private var placedTiles: [String] { placed.map { bank[$0] } }
    private var canCheckReply: Bool { SituationRetry.canCheck(placedTiles, rejected: rejectedReplies) }

    // MARK: - Words

    private func lineText(id: String, text: String, turnIndex: Int?) -> some View {
        let fixLine = turnIndex != nil && turnIndex == item.errorTurnIndex
        let segments = SituationText.segments(text, keys: wordKeys,
                                              keepApart: fixLine ? item.errorMark?.word : nil)
        return FlowLayout(spacing: 5, lineSpacing: 4) {
            ForEach(segments, id: \.index) { seg in
                segmentView(seg, lineID: id, fixLine: fixLine)
            }
        }
    }

    @ViewBuilder
    private func segmentView(_ seg: SituationText.Segment, lineID: String, fixLine: Bool) -> some View {
        let font = Font.display(size: 19, wght: 400)
        if seg.kind == .gap {
            HStack(spacing: 0) {
                gapView
                Text(seg.trailing).font(font).foregroundColor(AppColor.ink)
            }
        } else {
            let wordID = "\(lineID)-\(seg.index)"
            let mark = fixLine ? item.errorMark : nil
            let isError = mark.map { SituationText.norm(seg.display) == SituationText.norm($0.word) } ?? false
            let marked = isError && fixPhase == .choose && drill?.type == .fix && !errorFixed
            let shown = isError && errorFixed ? matchCase(mark?.fix ?? seg.display, like: seg.display) : seg.display
            let isNew = seg.key.map { newWordKeys.contains($0) } ?? false
            // Word + its trailing punctuation as one Text, so no gap opens
            // before a comma or full stop.
            (Text(shown).underline(isNew && !fixLine, color: AppColor.g2) + Text(seg.trailing))
                .font(font)
                .foregroundColor(AppColor.ink)
                // The word being corrected gets a white fill on the learner bubble
                // (no strike, no extra colour) and loses it once fixed.
                .background(RoundedRectangle(cornerRadius: 5)
                    .fill(marked ? AppColor.white : highlight(wordID: wordID, key: seg.key)).padding(-3))
                // A wrong tap shakes the word instead of flashing a colour.
                .modifier(SituationShake(amount: flashedWord == wordID ? 1 : 0))
                .anchorPreference(key: SituationTipAnchorKey.self, value: .bounds) { [wordID: $0] }
                .contentShape(Rectangle())
                .onTapGesture { tapWord(seg, wordID: wordID, fixLine: fixLine, isError: isError) }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(shown + seg.trailing.replacingOccurrences(of: "\u{00A0}", with: " "))
                .accessibilityValue(wordAccessibilityValue(marked: marked, isNew: isNew && !fixLine, key: seg.key))
                .accessibilityAddTraits(.isButton)
                .accessibilityHint(wordAccessibilityHint(fixLine: fixLine, key: seg.key))
        }
    }

    /// VoiceOver state of a tappable word: the Corriger word being fixed, a
    /// Mot target, a new word.
    private func wordAccessibilityValue(marked: Bool, isNew: Bool, key: String?) -> String {
        if marked { return "Mot à corriger" }
        if drill?.type == .word, let key, let target = drill?.target, key == SituationText.norm(target) {
            return "Mot de la question"
        }
        return isNew ? "Nouveau mot" : ""
    }

    private func wordAccessibilityHint(fixLine: Bool, key: String?) -> String {
        if fixLine && drill?.type == .fix && fixPhase == .find && !locked {
            return "Touchez ce mot s'il est faux"
        }
        return key == nil ? "" : "Affiche l'anglais"
    }

    private func highlight(wordID: String, key: String?) -> Color {
        if tip?.id == wordID { return Color.white.opacity(0.9) }
        if drill?.type == .word, let key, let target = drill?.target, key == SituationText.norm(target) {
            return Color(hex: theme.tint)
        }
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
            .accessibilityLabel(gapText.map { gapSettled ? $0 : "Blanc : \($0)" } ?? "Blanc")
    }

    private func matchCase(_ word: String, like original: String) -> String {
        guard let first = original.first, first.isUppercase else { return word }
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    private func tapWord(_ seg: SituationText.Segment, wordID: String, fixLine: Bool, isError: Bool) {
        if fixLine && drill?.type == .fix && fixPhase == .find {
            withAnimation(Self.motion) { tapFix(isError: isError, wordID: wordID, word: seg.display) }
            return
        }
        guard let key = seg.key, let word = book.words[key] else { return }
        lastWordTap = Date()
        withAnimation(.easeOut(duration: 0.15)) {
            tip = Tip(id: wordID, french: seg.display, english: word.tipText)
        }
        announce(word.en)
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
            SituationTipArrow().fill(AppColor.ink).frame(width: 14, height: 7)
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
                    Text(item.standalone ?? drill.type.title).uppercaseLabel()
                    Spacer()
                    if item.isStandalone {
                        Text("Phrase seule").uppercaseLabel()
                    } else if item.drills.count > 1 {
                        Text("\(step + 1)/\(item.drills.count)").uppercaseLabel()
                            .accessibilityLabel("Exercice \(step + 1) sur \(item.drills.count)")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
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
                    .onChange(of: note) { _, new in announce(new) }
            } else {
                doneBlock
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func promptText(_ drill: SituationDrill) -> String {
        if drill.type == .fix, fixPhase == .choose, let mark = item.errorMark {
            return "What should « \(mark.word) » be?"
        }
        if drill.type == .fix, fixPhase == .find {
            return "Tap the wrong word in your line."
        }
        return drill.prompt
    }

    /// Display order for the current drill's choices (authored indices).
    private func displayOrder(count: Int, tag: String) -> [Int] {
        SituationShuffle.order(count: count,
                               seed: SituationShuffle.seed("\(item.id)#\(step)#\(tag)#\(card.salt)"))
    }

    @ViewBuilder
    private func drillBody(_ drill: SituationDrill) -> some View {
        let choices = drill.choices ?? []
        switch drill.type {
        case .comprehend, .word:
            choiceGrid(choices, order: displayOrder(count: choices.count, tag: "c"),
                       columns: choices.count, stacked: false) { c in withAnimation(Self.motion) { instant(c) } }
        case .pick:
            choiceGrid(choices, order: displayOrder(count: choices.count, tag: "c"),
                       columns: 1, stacked: true) { c in withAnimation(Self.motion) { select(c) } }
        case .complete:
            choiceGrid(choices, order: displayOrder(count: choices.count, tag: "c"),
                       columns: 3, stacked: false) { c in withAnimation(Self.motion) { select(c) } }
        case .fix:
            if fixPhase == .choose, let mark = item.errorMark {
                choiceGrid(mark.choices, order: displayOrder(count: mark.choices.count, tag: "fix"),
                           columns: 3, stacked: false) { c in withAnimation(Self.motion) { if !locked { selected = c } } }
            }
        case .reply:
            replyTray
        }
    }

    /// Word tray. Café handoff fix 2 kept: the tray asks for its full height and
    /// the chat gives up space first. Only when the chat is at its minimum does
    /// the tray shrink, and then its tiles scroll inside the tray, clipped to
    /// its rounded edge — the card itself never scrolls.
    private var replyTray: some View {
        ScrollView(.vertical, showsIndicators: false) {
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(bankOrder, id: \.self) { i in
                    let used = placed.contains(i)
                    Button {
                        guard !locked else { return }
                        withAnimation(Self.tileSpring) { placed.append(i) }
                    } label: { MagnetTile(text: bank[i]) }
                        .buttonStyle(.plain)
                        .opacity(used ? 0.25 : 1)
                        .disabled(used)
                        .accessibilityLabel(bank[i])
                        .accessibilityValue(used ? "Déjà placé" : "")
                        .accessibilityHint(used ? "" : "Ajoute ce mot à votre réponse")
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { trayContentHeight = $0 }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(minHeight: SituationCardFit.trayMin, maxHeight: max(96, trayContentHeight))
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.tray = $0 }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: theme.tint)))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func choiceGrid(_ choices: [String], order: [Int], columns: Int, stacked: Bool,
                            action: @escaping (Int) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, columns)), spacing: 8) {
            ForEach(order.filter { choices.indices.contains($0) }, id: \.self) { i in
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
                .accessibilityValue(isRight ? "Bonne réponse" : (isWrong ? "Mauvaise réponse" : ""))
                .accessibilityAddTraits(isSel ? .isSelected : [])
            }
        }
    }

    private var doneBlock: some View {
        let outcome = SituationOutcome.dialogue(drillOutcomes)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Fini").uppercaseLabel()
                Spacer()
                Text(item.standalone ?? item.drills.map(\.type.title).joined(separator: " + ")).uppercaseLabel()
            }
            Text(outcome == .again ? "Pas trouvé. On le reverra bientôt."
                 : outcome == .hard ? "Réussi avec un essai de plus." : "Du premier coup.")
                .font(.display(size: 21, wght: 350)).foregroundColor(AppColor.ink)
                .onAppear {
                    announce(outcome == .again ? "Pas trouvé." : outcome == .hard ? "Réussi avec un essai de plus."
                             : "Du premier coup.")
                }
            if !cardMistakes.isEmpty {
                Text("Vos erreurs").uppercaseLabel()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(cardMistakes) { mistakeRow($0, compact: true) }
                }
            }
            if !item.newWords.isEmpty {
                Text("Nouveaux mots").uppercaseLabel()
                FlowLayout(spacing: 6, lineSpacing: 6) {
                    ForEach(item.newWords, id: \.self) { fr in
                        newWordChip(fr)
                    }
                }
            }
        }
    }

    /// A finished dialogue's new word with its English. Tap plays the word's
    /// own clip (`sitw_*`) when it is bundled.
    private func newWordChip(_ fr: String) -> some View {
        let word = book.words[SituationText.norm(fr)]
        let hasAudio = word?.audio.flatMap(Speaker.bundledAudioURL(key:)) != nil
        return Button {
            if let key = word?.audio { Speaker.shared.playBundled(key: key) }
        } label: {
            (Text(fr).foregroundColor(AppColor.ink)
             + Text(" · \(word?.tipText ?? "")").foregroundColor(AppColor.graphite))
                .font(.display(size: 14, wght: 400))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppColor.hairline))
        }
        .buttonStyle(.plain)
        .disabled(!hasAudio)
        .accessibilityLabel("\(fr), \(word?.en ?? "")")
    }

    private func mistakeRow(_ m: Mistake, compact: Bool) -> some View {
        SituationMistakeRow(title: m.title, given: m.given, expected: m.expected, why: m.why, compact: compact)
    }

    /// Closing screen: the session's ratings, then every wrong attempt with its
    /// reason. This screen may scroll; it is not a drill card.
    private var summary: some View {
        let values = Array(results.values)
        let counts = (good: values.filter { $0 == .good }.count,
                      hard: values.filter { $0 == .hard }.count,
                      again: values.filter { $0 == .again }.count)
        let cardsWithMistakes = Array(Set(mistakes.map(\.cardIndex))).sorted()
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
                        ForEach(cardsWithMistakes, id: \.self) { cardIndex in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(mistakes.first { $0.cardIndex == cardIndex }?.elementTitle ?? "")
                                    .font(.display(size: 17, wght: 500)).foregroundColor(AppColor.ink)
                                ForEach(mistakes.filter { $0.cardIndex == cardIndex }) { mistakeRow($0, compact: false) }
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
            Button("Fermer", action: exit)
                .buttonStyle(DrillButtonStyle())
                .padding(.horizontal, 18).padding(.bottom, 8)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        let (label, enabled): (String, Bool) = {
            if let live { return (index + 1 == live.index ? "Reprendre" : "Suivant", true) }
            guard let drill else {
                return (index == cards.count - 1 ? "Terminer" : "Suivant", true)
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
        .accessibilityHint(footerHint(enabled: enabled))
    }

    /// Why the footer button is off, for VoiceOver.
    private func footerHint(enabled: Bool) -> String {
        guard !enabled, let drill else { return "" }
        switch drill.type {
        case .reply:
            return placed.isEmpty ? "Placez des mots d'abord." : "Changez votre réponse avant de vérifier."
        case .pick, .complete: return "Choisissez une réponse d'abord."
        case .fix: return fixPhase == .find ? "Touchez le mot faux dans votre ligne." : "Choisissez la correction."
        case .comprehend, .word: return ""
        }
    }

    /// Reads feedback aloud when VoiceOver is on (wrong-answer notes, the
    /// rating, a word's English).
    private func announce(_ text: String) {
        guard UIAccessibility.isVoiceOverRunning, !text.isEmpty else { return }
        AccessibilityNotification.Announcement(text).post()
    }

    // MARK: - Logic

    private func log(_ given: String, expected: String, why: String?) {
        guard let drill else { return }
        let title = item.standalone ?? drill.type.title
        mistakes.append(Mistake(cardIndex: index, elementTitle: card.element.label, title: title,
                                given: given, expected: expected, why: why))
        DataManager.shared.logSituationAttempt(.init(
            bookID: book.id, elementID: card.element.id, dialogueID: item.id,
            drillType: drill.type.rawValue, given: given, expected: expected, reason: why,
            createdAt: Date()))
    }

    private func startDrill() {
        tries = 0; drillMisses = 0; drillFailed = false
        selected = nil; wrongChoices = []; rightChoice = nil
        placed = []; rejectedReplies = []; note = ""; fixPhase = .find; flashedWord = nil
        trayContentHeight = 0
        guard let drill else { return }
        if drill.type == .reply || drill.type == .pick { slot = .building }
        if drill.type == .reply {
            bankOrder = SituationShuffle.bankOrder(
                bank: drill.bank ?? [], accepted: drill.accepted ?? [],
                seed: SituationShuffle.seed("\(item.id)#\(step)#bank#\(card.salt)"))
        }
    }

    /// One drill done: keep its outcome (the dialogue takes the worst). A
    /// Corriger whose wrong word was never found counts as not solved, even if
    /// its fix was then picked right.
    private func closeDrill(solved: Bool) {
        drillOutcomes.append(.drill(misses: drillMisses, solved: solved && !drillFailed))
    }

    private func miss() {
        drillMisses += 1
        tries += 1
    }

    /// Comprendre / Mot: a tap answers at once; two misses show the answer.
    private func instant(_ choice: Int) {
        guard !locked, let drill, let choices = drill.choices, let right = drill.correctChoice,
              choices.indices.contains(choice) else { return }
        if drill.isCorrect(choice: choices[choice]) {
            rightChoice = choice
            closeDrill(solved: true)
            advanceSoon(0.7)
            return
        }
        miss()
        wrongChoices.insert(choice)
        log(choices[choice], expected: right, why: drill.miss ?? drill.why(for: choice))
        if tries >= 2 {
            note = "Answer: \(right)."
            rightChoice = drill.correct
            closeDrill(solved: false)
            advanceSoon(1.7)
        } else {
            note = drill.miss ?? drill.why(for: choice) ?? "Pas encore. Touchez un mot pour voir l'anglais."
        }
    }

    private func select(_ choice: Int) {
        guard !locked, let drill, let choices = drill.choices, choices.indices.contains(choice) else { return }
        selected = choice
        if drill.type == .pick { slot = .preview(choices[choice]) } else { gapText = choices[choice] }
    }

    private func check() {
        guard !locked, let drill else { return }
        switch drill.type {
        case .reply:
            // An answer already refused (unchanged since the miss) never spends a try.
            guard canCheckReply else { return }
            let tiles = placedTiles
            if drill.accepts(tiles) {
                tries += 1
                closeDrill(solved: true)
                fillSlot(tiles.joined(separator: " "), ok: true); advanceSoon(0.75)
            } else {
                miss()
                let keep = drill.correctPrefixCount(tiles)
                log(tiles.joined(separator: " "), expected: drill.model ?? "",
                    why: keep > 0 ? "The start « \(tiles.prefix(keep).joined(separator: " ")) » was right." : nil)
                if tries < 2 {
                    placed = Array(placed.prefix(keep))
                    rejectedReplies += SituationRetry.rejected(after: tiles, keep: keep)
                    note = "Pas encore : « \(tiles.joined(separator: " ")) »"
                        + (keep > 0 ? ". The start is kept; fix the rest." : ". Try again.")
                } else {
                    closeDrill(solved: false)
                    fillSlot(drill.model ?? "", ok: false); advanceSoon(1.1)
                }
            }
        case .pick, .complete:
            guard let selected, let choices = drill.choices, let right = drill.correctChoice,
                  choices.indices.contains(selected) else { return }
            if drill.isCorrect(choice: choices[selected]) {
                tries += 1
                closeDrill(solved: true)
                settle(drill, text: right, ok: true)
            } else if tries < 1 {
                miss()
                wrongChoices.insert(selected)
                log(choices[selected], expected: right, why: drill.why(for: selected))
                note = drill.why(for: selected) ?? "Pas encore."
                self.selected = nil
                if drill.type == .pick { slot = .building } else { gapText = nil }
            } else {
                miss()
                log(choices[selected], expected: right, why: drill.why(for: selected))
                closeDrill(solved: false)
                settle(drill, text: right, ok: false)
            }
        case .fix:
            guard let selected, let mark = item.errorMark, mark.choices.indices.contains(selected) else { return }
            let picked = mark.choices[selected]
            if picked == mark.fix {
                tries += 1
                closeDrill(solved: true)
                errorFixed = true; advanceSoon(0.75)
            } else {
                miss()
                log("\(mark.word) → \(picked)", expected: "\(mark.word) → \(mark.fix)", why: mark.why)
                if tries >= 2 || drillFailed {
                    closeDrill(solved: false)
                    errorFixed = true; advanceSoon(1.1)
                } else {
                    wrongChoices.insert(selected); self.selected = nil
                    note = mark.why ?? "Pas encore."
                }
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

    private func settle(_ drill: SituationDrill, text: String, ok: Bool) {
        if drill.type == .pick {
            fillSlot(text, ok: ok)
        } else {
            gapText = text; gapSettled = true
        }
        advanceSoon(ok ? 0.75 : 1.1)
    }

    /// Corriger, first step: find the wrong word. Two wrong taps reveal it.
    private func tapFix(isError: Bool, wordID: String, word: String) {
        guard !locked, let drill else { return }
        if isError {
            fixPhase = .choose; tries = 0; note = ""
            return
        }
        miss()
        if let mark = item.errorMark {
            log("« \(word) »", expected: "wrong word: « \(mark.word) »", why: "« \(word) » was fine.")
        }
        withAnimation(.linear(duration: 0.35)) { flashedWord = wordID }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var t = Transaction(); t.disablesAnimations = true
            withTransaction(t) { if flashedWord == wordID { flashedWord = nil } }
        }
        if tries >= 2 {
            // Not found: show it. The fix step still runs, but the drill is lost.
            drillFailed = true
            fixPhase = .choose; tries = 0
            note = "It was « \(item.errorMark?.word ?? "") »."
        } else {
            note = drill.miss ?? "That word is fine."
        }
    }

    /// Let the solved state sit for a beat, then move on in one animated step.
    /// Input is ignored meanwhile.
    private func advanceSoon(_ delay: Double) {
        locked = true
        let current = index
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard current == index, !showSummary else { return }
            withAnimation(Self.motion) { advance() }
        }
    }

    private func advance() {
        locked = false
        if step + 1 < item.drills.count {
            step += 1
            startDrill()
        } else {
            finished = true
            note = ""
            finishItem()
            let current = index
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard current == index, finished else { return }
                withAnimation(Self.motion) { showFollow = true }
                if autoSpeak, let followUp = item.followUp, !followUp.isEmpty {
                    Speaker.shared.playBundled(key: item.followUpAudioKey)
                }
            }
        }
    }

    /// Grade the finished item on its element and remember it for Réviser.
    /// The rating is the worst drill; reading and word taps never lower it.
    private func finishItem() {
        let outcome = SituationOutcome.dialogue(drillOutcomes)
        results[index] = outcome
        let rating: FSRS.Rating = outcome == .good ? .good : (outcome == .hard ? .hard : .again)
        let element = card.element
        let now = Date()
        ElementGrader.grade(elementID: element.id, exampleID: item.id, rating: rating, now: now) { status in
            SituationMastery.gateMet(correctItemIDs: status.masteredExampleIDs, items: element.items)
        }
        DataManager.shared.logSituationItem(itemID: item.id, elementID: element.id, rating: outcome, at: now)
    }

    /// The finished card is complete once its follow-up shows (if it has one).
    private var settled: Bool { showFollow || item.followUp == nil }

    private func nextDialogue() {
        Speaker.shared.stop()
        if index == cards.count - 1 {
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
        guard cards.indices.contains(index) else { return }
        step = 0; finished = false; drillOutcomes = []; locked = false
        slot = .hidden; gapText = nil; gapSettled = false; errorFixed = false
        showFollow = false; tip = nil
        startDrill()
    }

    // MARK: - Going back

    private var canGoBack: Bool { !locked && finishedCards[index - 1] != nil }
    private var canGoForward: Bool { live != nil }

    private func captureCard() -> CardState {
        CardState(index: index, step: step, finished: finished, drillOutcomes: drillOutcomes,
                  tries: tries, drillMisses: drillMisses, drillFailed: drillFailed,
                  selected: selected, rightChoice: rightChoice, wrongChoices: wrongChoices,
                  placed: placed, bankOrder: bankOrder, rejectedReplies: rejectedReplies, note: note,
                  slot: slot, gapText: gapText, gapSettled: gapSettled, errorFixed: errorFixed,
                  showFollow: showFollow, fixPhase: fixPhase)
    }

    private func restoreCard(_ c: CardState) {
        index = c.index; step = c.step; finished = c.finished; drillOutcomes = c.drillOutcomes
        tries = c.tries; drillMisses = c.drillMisses; drillFailed = c.drillFailed
        selected = c.selected; rightChoice = c.rightChoice; wrongChoices = c.wrongChoices
        placed = c.placed; bankOrder = c.bankOrder; rejectedReplies = c.rejectedReplies; note = c.note
        slot = c.slot; gapText = c.gapText; gapSettled = c.gapSettled; errorFixed = c.errorFixed
        // A follow-up that was due while away has shown by now.
        showFollow = c.showFollow || c.finished
        fixPhase = c.fixPhase
    }

    /// Fade out, swap the card without animation, fade back in (as between dialogues).
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

    // MARK: - Simulator flags (DEBUG)

    #if DEBUG
    /// CB_SIT_ITEMS=id,id,… serves exactly those items (any book module), in
    /// order, graded for real — for simulator checks of every drill type.
    private static func debugQueue(book: Book) -> [Card]? {
        guard let raw = ProcessInfo.processInfo.environment["CB_SIT_ITEMS"] else { return nil }
        let ids = raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        var out: [Card] = []
        for id in ids {
            for element in book.allElements {
                if let item = element.items.first(where: { $0.id == id }) {
                    out.append(Card(element: element, item: item, salt: 0))
                }
            }
        }
        return out.isEmpty ? nil : out
    }

    /// CB_SIT_INDEX=n opens card n; CB_SIT_STEP=n jumps to drill n;
    /// CB_SIT_STAGE=fill|done previews a filled answer or the finished state;
    /// CB_SIT_TIP=<word key> pins that word's English open;
    /// CB_SIT_AUTOPLAY=1|wrong plays through (wrong = one miss per drill first).
    private func applyLaunchFlags() {
        let env = ProcessInfo.processInfo.environment
        guard !cards.isEmpty else { return }
        if env["CB_SIT_SKIP_INTRO"] == "1" || env["CB_SIT_AUTOPLAY"] != nil { showingIntro = false }
        if let mode = env["CB_SIT_AUTOPLAY"] {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                while autoStep(wrongFirst: mode == "wrong") { try? await Task.sleep(nanoseconds: 1_100_000_000) }
            }
        }
        if let n = env["CB_SIT_INDEX"].flatMap(Int.init), cards.indices.contains(n) { index = n; showingIntro = false }
        resetDialogue()
        if let n = env["CB_SIT_STEP"].flatMap(Int.init), item.drills.indices.contains(n) {
            // Earlier drills show as solved.
            slot = .hidden
            for d in item.drills.prefix(n) {
                if d.type == .reply { slot = .done(d.model ?? "", ok: true) }
                if d.type == .pick, let right = d.correctChoice { slot = .done(right, ok: true) }
                if d.type == .complete { gapText = d.correctChoice; gapSettled = true }
                if d.type == .fix { errorFixed = true }
            }
            step = n; startDrill()
            if item.drills[n].type != .reply && item.drills[n].type != .pick,
               item.drills.prefix(n).allSatisfy({ $0.type != .reply && $0.type != .pick }) { slot = .hidden }
        }
        switch env["CB_SIT_STAGE"] {
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
            case .comprehend, .word:
                wrongChoices = [((drill.correct ?? 0) + 1) % max(1, drill.choices?.count ?? 1)]
                note = drill.miss ?? ""; tries = 1; drillMisses = 1
            }
        case "done":
            for d in item.drills {
                if d.type == .reply { slot = .done(d.model ?? "", ok: true) }
                if d.type == .pick, let right = d.correctChoice { slot = .done(right, ok: true) }
                if d.type == .complete { gapText = d.correctChoice; gapSettled = true }
                if d.type == .fix { errorFixed = true }
            }
            finished = true; showFollow = true
        default: break
        }
        if let key = env["CB_SIT_TIP"], let word = book.words[key] {
            for (i, turn) in item.turns.enumerated() {
                if let seg = SituationText.segments(turn.text, keys: wordKeys).first(where: { $0.key == key }) {
                    tip = Tip(id: "t\(i)-\(seg.index)", french: seg.display, english: word.tipText)
                    tipPinned = true
                    break
                }
            }
        }
    }

    private func autoStep(wrongFirst: Bool) -> Bool {
        guard !locked, !showSummary else { return !showSummary }
        guard let drill else {
            guard settled else { return true }
            nextDialogue(); return true
        }
        if wrongFirst && drillMisses == 0 && tries == 0 && wrongChoices.isEmpty && fixPhase == .find {
            withAnimation(Self.motion) { autoWrong(drill) }
            return true
        }
        withAnimation(Self.motion) {
            switch drill.type {
            case .comprehend, .word:
                if let c = drill.correct { instant(c) }
            case .reply:
                // The last accepted reply (often the alternative), unless the
                // tiles kept after a miss already start another one.
                let kept = placed.map { bank[$0] }
                let replies = drill.accepted ?? []
                let target = replies.reversed().first { Array($0.prefix(kept.count)) == kept } ?? replies.last ?? []
                if placed.count < target.count {
                    let tile = target[placed.count]
                    if let i = bank.indices.first(where: { bank[$0] == tile && !placed.contains($0) }) {
                        withAnimation(Self.tileSpring) { placed.append(i) }
                    }
                } else { check() }
            case .pick, .complete:
                if selected == nil, let c = drill.correct { select(c) } else { check() }
            case .fix:
                if fixPhase == .find { tapFix(isError: true, wordID: "", word: item.errorMark?.word ?? "") }
                else if selected == nil, let mark = item.errorMark { selected = mark.choices.firstIndex(of: mark.fix) }
                else { check() }
            }
        }
        return true
    }

    /// One wrong attempt per drill (CB_SIT_AUTOPLAY=wrong).
    private func autoWrong(_ drill: SituationDrill) {
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
            let line = item.errorTurnIndex.map { item.turns[$0].text } ?? ""
            let first = SituationText.tokens(line).first { SituationText.norm($0) != SituationText.norm(item.errorMark?.word ?? "") } ?? ""
            tapFix(isError: false, wordID: "auto", word: first)
        }
    }
    #endif
}

/// Bounds of each tappable word, keyed by line + segment, so the English can
/// sit directly above the tapped word.
private struct SituationTipAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue()) { $1 }
    }
}

private struct SituationTipArrow: Shape {
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
private struct SituationShake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 4 * sin(amount * .pi * 4), y: 0))
    }
}

/// Vertical fit for a dialogue card that never scrolls as a whole. The chat
/// keeps the height of all its bubbles while a word tray is on screen; the tray
/// takes the rest and scrolls its tiles inside itself (down to `trayMin`).
/// Every input is a measured height in points. The tray's own height is
/// subtracted from the drill zone, so the result never feeds back into itself.
struct SituationCardFit: Equatable {
    static let trayMin: CGFloat = 60
    static let chatMin: CGFloat = 64
    /// The hairline between chat and drill zone, with its top padding.
    static let divider: CGFloat = 11

    var card: CGFloat = 0
    var header: CGFloat = 0
    var chatContent: CGFloat = 0
    var zone: CGFloat = 0
    var tray: CGFloat = 0
    var footer: CGFloat = 0

    /// Height the chat and the tray share.
    var shared: CGFloat { card - header - Self.divider - (zone - tray) - footer }

    func chatFloor(trayShown: Bool) -> CGFloat {
        guard trayShown, card > 0, chatContent > 0 else { return Self.chatMin }
        return max(Self.chatMin, min(chatContent, shared - Self.trayMin))
    }
}
