//
//  SituationSessionView.swift
//  carambole
//
//  *En situation* (Book 2) study session: short dialogues and standalone drills,
//  one locked chat card each (`SituationCardView`), 1–2 drills per card, six
//  drill types. Every finished item is graded with FSRS on its element
//  (`ElementGrader`), logged for Réviser selection (`situation_item_log`), and
//  every wrong attempt is saved (`situation_attempt_log`). The Test book pilot
//  (`Debug/SituationPilotView.swift`) runs this same session without saving.
//
//  Cards sit side by side in Book 1's carousel (`DrillSessionView`): the
//  finger drags the row, a finished card can be swiped back to and read, and
//  « Suivant » slides the next card in from the right. The top bar stays put.
//

import SwiftUI

struct SituationSessionView: View {
    let title: String
    let ruleNote: String
    let mode: SessionMode
    /// The module whose Leçon card opens a learn session (nil for Réviser).
    let module: CourseModule?
    let canStart: Bool
    let autoSpeak: Bool
    let onFinish: () -> Void
    private let bookID: String
    private let words: [String: SituationWord]
    /// Who the learner plays in every dialogue (Leçon intro only).
    private let persona: String?
    private let wordMatcher: SituationText.Matcher
    /// False for the Test book: nothing is graded or saved.
    private let recordsProgress: Bool
    /// Prepended to every dialogue audio key.
    private let audioPrefix: String
    /// Simulator flag prefix: `CB_SIT_` (production) or `CB_PILOT_` (Test book).
    private let flagPrefix: String

    init(book: Book, title: String, ruleNote: String, elements: [GrammarElement], mode: SessionMode,
         module: CourseModule? = nil, canStart: Bool = true, autoSpeak: Bool = false,
         onFinish: @escaping () -> Void) {
        self.title = title
        self.ruleNote = ruleNote
        self.mode = mode
        self.module = module
        self.canStart = canStart
        self.autoSpeak = autoSpeak
        self.onFinish = onFinish
        bookID = book.id
        words = book.words
        persona = book.persona
        wordMatcher = SituationText.Matcher(keys: Set(book.words.keys))
        recordsProgress = true
        audioPrefix = ""
        flagPrefix = "CB_SIT_"
        _cards = State(initialValue: Self.buildQueue(book: book, elements: elements, mode: mode))
        _showingIntro = State(initialValue: mode == .learn && module != nil)
    }

    #if DEBUG
    /// The Test book: a fixed queue, played without grading or saving.
    init(pilot cards: [Card], words: [String: SituationWord], audioPrefix: String,
         onFinish: @escaping () -> Void) {
        title = "En situation · essai"
        ruleNote = ""
        mode = .learn
        module = nil
        canStart = true
        autoSpeak = false
        self.onFinish = onFinish
        bookID = "testbook"
        self.words = words
        persona = nil
        wordMatcher = SituationText.Matcher(keys: Set(words.keys))
        recordsProgress = false
        self.audioPrefix = audioPrefix
        flagPrefix = "CB_PILOT_"
        _cards = State(initialValue: cards)
        _showingIntro = State(initialValue: false)
    }
    #endif

    /// One presentation: an item of an element. `salt` changes each time the
    /// item comes back, so its choices reshuffle between reviews.
    struct Card: Equatable {
        let element: GrammarElement
        let item: SituationItem
        let salt: Int
    }

    @State private var cards: [Card]
    @State private var showingIntro: Bool

    /// State of every card shown so far, by queue index. A card is added when
    /// it first slides in and kept, so going back shows it exactly as it ended.
    @State private var states: [Int: SituationCardState] = [:]
    /// The card on screen.
    @State private var cursor = 0
    /// The card in play (the furthest one reached). Cards before it are finished.
    @State private var frontier = 0
    /// The first card of the session (a simulator flag may start later).
    @State private var firstIndex = 0
    /// Live horizontal drag of the card row, in points. Each card sits at
    /// `(i - cursor) * width + dragOffset` (Book 1's carousel).
    @State private var dragOffset: CGFloat = 0
    /// The card just left with « Suivant ». It slides out keeping its live
    /// look instead of flipping to « Révision » (Book 1's `hideExplanationAt`);
    /// cleared when the learner heads back.
    @State private var leavingIndex: Int?
    /// Decided on a drag's first change, so vertical chat scrolls keep working.
    @State private var dragIsHorizontal: Bool?
    /// Every wrong attempt this session, in order (also saved to the database).
    @State private var mistakes: [SituationMistake] = []
    /// Outcome per finished card index, for the closing summary.
    @State private var results: [Int: SituationOutcome] = [:]
    @State private var showSummary = false
    /// Element just removed with "Trop facile", for the undo pill's « Annuler ».
    @State private var tooEasyUndoElementID: String?
    @State private var tooEasyUndoToken = 0
    #if DEBUG
    @State private var launch = SituationLaunch()
    @State private var launchStep: Int?
    @State private var launchStage: String?
    /// CB_*_BACK_AT=n: autoplay stops on card n and goes back one.
    @State private var backAt: Int?
    /// CB_*_TOO_EASY=1: the first card opens with "Trop facile" armed.
    @State private var launchTooEasy = false
    #endif

    /// Book 1's paging spring, for drags, chevrons and « Suivant ».
    private static let pageSpring = Animation.interactiveSpring(response: 0.32, dampingFraction: 0.86)

    var body: some View {
        Group {
            if showingIntro {
                intro.transition(.opacity)
            } else if cards.isEmpty {
                emptyState
            } else if showSummary {
                summary.transition(.opacity)
            } else {
                session
            }
        }
        .background(AppColor.paper.ignoresSafeArea())
        .tooEasyUndo(elementID: $tooEasyUndoElementID, token: tooEasyUndoToken)
        .onAppear {
            #if DEBUG
            applyLaunchFlags()
            #endif
            open(firstIndex)
        }
        .onDisappear { Speaker.shared.stop() }
        #if DEBUG
        .onChange(of: frontier) { _, n in
            guard n == backAt else { return }
            launch.autoplay = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { goBack() }
        }
        #endif
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

    /// Makes card `index` the one in play, with a fresh state.
    private func open(_ index: Int) {
        guard cards.indices.contains(index), states[index] == nil else { return }
        var state = SituationCardState(item: cards[index].item, salt: cards[index].salt)
        #if DEBUG
        if index == firstIndex {
            state.applyLaunch(step: launchStep, stage: launchStage, item: cards[index].item, salt: cards[index].salt)
            state.pendingTooEasy = launchTooEasy
        }
        #endif
        states[index] = state
        frontier = index
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
                            // Decorative: the label above already names the module.
                            .accessibilityHidden(true)
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
                .accessibilityAddTraits(.isHeader)
            Text(ruleNote)
                .font(.appBody)
                .lineSpacing(4)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
            if let persona {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vous").uppercaseLabel(AppColor.g2)
                    Text(persona)
                        .font(.appBody)
                        .foregroundColor(AppColor.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            if let module {
                Text(module.elements.map(\.label).joined(separator: " · "))
                    .font(.display(size: 14, wght: 400))
                    .foregroundColor(AppColor.g2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button(!canStart ? "Verrouillé" : (cards.isEmpty ? "Aucun exercice" : "Commencer")) {
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

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

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

    // MARK: - Carousel

    private var session: some View {
        VStack(spacing: 0) {
            topBar
            carousel
        }
    }

    /// Only the card on screen and its neighbours exist.
    private var visibleIndices: [Int] {
        let lo = max(firstIndex, cursor - 1)
        let hi = min(frontier, cursor + 1)
        return lo <= hi ? Array(lo...hi) : []
    }

    private var carousel: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack {
                ForEach(visibleIndices, id: \.self) { i in
                    card(at: i)
                        .frame(width: w, height: geo.size.height)
                        .offset(x: CGFloat(i - cursor) * w + dragOffset)
                        // Only the centred card takes touches; neighbours are parked
                        // off-screen and must not steal taps.
                        .allowsHitTesting(i == cursor)
                }
            }
            .frame(width: w, height: geo.size.height)
            .contentShape(Rectangle())
            .clipped()
            .simultaneousGesture(dragGesture(width: w))
        }
    }

    @ViewBuilder
    private func card(at i: Int) -> some View {
        let card = cards[i]
        let view = SituationCardView(
            item: card.item, salt: card.salt, words: words,
            wordMatcher: wordMatcher,
            audioPrefix: audioPrefix, isLast: i == cards.count - 1,
            reviewing: i < frontier && i != leavingIndex, active: i == cursor,
            forwardLabel: i + 1 == frontier ? "Reprendre" : "Suivant",
            mistakes: mistakes.filter { $0.cardIndex == i },
            autoSpeak: autoSpeak,
            state: Binding(get: { states[i] ?? SituationCardState(item: card.item, salt: card.salt) },
                           set: { states[i] = $0 }),
            onMistake: { type, drillTitle, given, expected, why in
                log(card: i, type: type, title: drillTitle, given: given, expected: expected, why: why)
            },
            onTooEasy: { resolveTooEasy(card: i, outcome: $0) },
            onFinished: { finish(card: i, outcome: $0) },
            onNext: nextDialogue,
            onForward: goForward)
        #if DEBUG
        view.launching(i == firstIndex ? launch : SituationLaunch(autoplay: launch.autoplay)).id(i)
        #else
        view.id(i)
        #endif
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
                Text("\(cursor + 1)/\(cards.count)")
                    .font(.label(size: 12)).foregroundColor(AppColor.g2).monospacedDigit()
                    .accessibilityLabel("Dialogue \(cursor + 1) sur \(cards.count)")
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
        let done = states[frontier]?.finished == true ? 1 : 0
        return CGFloat(frontier + done) / CGFloat(max(1, cards.count))
    }

    // MARK: - Paging (Book 1)

    private var canGoBack: Bool { cursor > firstIndex }
    private var canGoForward: Bool { cursor < frontier }
    /// The card in play is finished, so a forward swipe may bring the next one.
    private var liveCardFinished: Bool { states[frontier]?.finished == true }

    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                let dx = value.translation.width, dy = value.translation.height
                if dragIsHorizontal == nil { dragIsHorizontal = abs(dx) > abs(dy) }
                guard dragIsHorizontal == true else { return }
                if dx > 0 { leavingIndex = nil }
                dragOffset = resistedOffset(dx, width: width)
            }
            .onEnded { value in
                defer { dragIsHorizontal = nil }
                guard dragIsHorizontal == true else { return }
                endDrag(translation: value.translation.width,
                        predicted: value.predictedEndTranslation.width, width: width)
            }
    }

    /// Track the finger 1:1 toward an existing neighbour; rubber-band (damp +
    /// cap) toward an edge or the unfinished card in play.
    private func resistedOffset(_ raw: CGFloat, width: CGFloat) -> CGFloat {
        if raw > 0 ? canGoBack : canGoForward { return raw }
        let cap = width * 0.22
        return max(-cap, min(cap, raw * 0.32))
    }

    /// Commit past 28 % of the width or on a fast flick; else spring back.
    private func endDrag(translation: CGFloat, predicted: CGFloat, width: CGFloat) {
        let commit = abs(translation) > width * 0.28 || abs(predicted) > width * 0.55
        if commit {
            if translation > 0 {
                if canGoBack { navHaptic(); goBack(); return }
            } else if canGoForward {
                navHaptic(); goForward(); return
            } else if cursor == frontier && liveCardFinished {
                navHaptic(); nextDialogue(); return
            }
        }
        withAnimation(Self.pageSpring) { dragOffset = 0 }
    }

    private func navHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Slide the row so card `index` is centred (and clear any drag).
    private func animateCursor(to index: Int) {
        Speaker.shared.stop()
        withAnimation(Self.pageSpring) {
            dragOffset = 0
            cursor = index
        }
    }

    private func goBack() {
        guard canGoBack else { return }
        leavingIndex = nil
        animateCursor(to: cursor - 1)
    }

    private func goForward() {
        guard canGoForward else { return }
        animateCursor(to: cursor + 1)
    }

    /// « Suivant » on the finished card in play: the next card slides in from
    /// the right, or the last one opens the summary.
    private func nextDialogue() {
        guard cursor == frontier, liveCardFinished else { return }
        Speaker.shared.stop()
        if frontier == cards.count - 1 {
            withAnimation(.smooth(duration: 0.5)) { showSummary = true }
            return
        }
        leavingIndex = frontier
        open(frontier + 1)
        // One frame parked off-screen right, so the new card slides in rather
        // than appearing in place.
        DispatchQueue.main.async { animateCursor(to: frontier) }
    }

    /// The authored first pass is finite. Keep offering fresh (then oldest)
    /// items for elements still without a correct answer, one per pass.
    private func appendUnlearnedCards() {
        guard mode == .learn, recordsProgress else { return }
        #if DEBUG
        // Simulator item selection intentionally requests an exact fixed queue.
        if ProcessInfo.processInfo.environment["CB_SIT_ITEMS"] != nil { return }
        #endif
        var elements: [GrammarElement] = []
        var seen: Set<String> = []
        for card in cards where seen.insert(card.element.id).inserted {
            elements.append(card.element)
        }
        let pending = Set(SituationLearnQueue.pendingIDs(
            elements.map(\.id), introduced: DataManager.shared.fetchIntroducedElementIDs()))
        for element in elements where pending.contains(element.id) {
            let history = DataManager.shared.fetchSituationItemHistory(elementID: element.id)
            guard let item = SituationSelector.learnItems(element.items, history: history, size: 1).first else { continue }
            cards.append(Card(element: element, item: item, salt: history[item.id]?.times ?? 0))
        }
    }

    // MARK: - Grading

    private func log(card i: Int, type: SituationDrill.Kind, title drillTitle: String,
                     given: String, expected: String, why: String?) {
        let card = cards[i]
        mistakes.append(SituationMistake(cardIndex: i, elementTitle: card.element.label, title: drillTitle,
                                         given: given, expected: expected, why: why))
        guard recordsProgress else { return }
        DataManager.shared.logSituationAttempt(.init(
            bookID: bookID, elementID: card.element.id, dialogueID: card.item.id,
            drillType: type.rawValue, given: given, expected: expected, reason: why,
            createdAt: Date()))
    }

    /// Book 2's mastery gate for `element`, used by every grade of it.
    private func masteryGate(_ element: GrammarElement) -> (ReviewStatus) -> Bool {
        { status in SituationMastery.gateMet(correctItemIDs: status.masteredExampleIDs, items: element.items) }
    }

    /// The drill armed with "Trop facile" on card `i` closed: resolve the shared
    /// gate on that drill's outcome alone (same logic as Book 1). The card's
    /// later drills still play and grade normally; the element's later cards
    /// leave the queue.
    private func resolveTooEasy(card i: Int, outcome: SituationOutcome) {
        let card = cards[i]
        let kept = SituationTooEasy.keptAfter(index: i, elementIDs: cards.map(\.element.id))
        cards = kept.map { cards[$0] }
        guard recordsProgress else { return }
        let removed = SituationTooEasy.removes(outcome)
        TooEasyGate.resolve(elementID: card.element.id, exampleID: card.item.id, removed: removed,
                            graduationGate: masteryGate(card.element))
        if removed {
            tooEasyUndoElementID = card.element.id
            tooEasyUndoToken += 1
        }
    }

    /// Grade the finished item on its element and remember it for Réviser.
    /// The rating is the worst drill; reading and word taps never lower it.
    /// A drill that resolved "Trop facile" is left out (the gate graded it).
    private func finish(card i: Int, outcome: SituationOutcome) {
        results[i] = outcome
        let card = cards[i]
        let element = card.element
        guard recordsProgress else { return }
        let now = Date()
        if let graded = SituationTooEasy.gradedOutcome(states[i]?.drillOutcomes ?? [outcome],
                                                       armedAt: states[i]?.tooEasyDrill) {
            let rating: FSRS.Rating = graded == .good ? .good : (graded == .hard ? .hard : .again)
            ElementGrader.grade(elementID: element.id, exampleID: card.item.id, rating: rating, now: now,
                                graduationGate: masteryGate(element))
        }
        DataManager.shared.logSituationItem(itemID: card.item.id, elementID: element.id, rating: outcome, at: now)
        if mode == .learn && i == cards.count - 1 { appendUnlearnedCards() }
    }

    // MARK: - Summary

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
                                ForEach(mistakes.filter { $0.cardIndex == cardIndex }) {
                                    SituationMistakeRow(title: $0.title, given: $0.given, expected: $0.expected,
                                                        why: $0.why, compact: false)
                                }
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

    /// <prefix>INDEX=n opens card n; STEP=n jumps to drill n; STAGE=fill|done
    /// previews a filled answer or the finished state; TIP=<word key> pins that
    /// word's English open; AUTOPLAY=1|wrong plays through (wrong = one miss
    /// per drill first); BACK_AT=n stops autoplay on card n and goes back one;
    /// TOO_EASY=1 arms "Trop facile" on the first card.
    private func applyLaunchFlags() {
        let env = ProcessInfo.processInfo.environment
        func flag(_ name: String) -> String? { env[flagPrefix + name] }
        guard !cards.isEmpty, states.isEmpty else { return }
        if flag("SKIP_INTRO") == "1" || flag("AUTOPLAY") != nil { showingIntro = false }
        if let n = flag("INDEX").flatMap(Int.init), cards.indices.contains(n) {
            firstIndex = n; cursor = n; showingIntro = false
        }
        launchStep = flag("STEP").flatMap(Int.init)
        launchStage = flag("STAGE")
        launch = SituationLaunch(tip: flag("TIP"), autoplay: flag("AUTOPLAY"))
        backAt = flag("BACK_AT").flatMap(Int.init)
        launchTooEasy = flag("TOO_EASY") == "1"
    }
    #endif
}
