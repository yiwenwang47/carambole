//
//  SituationCardView.swift
//  carambole
//
//  One *En situation* (Book 2) card: the cue, the chat, the drill zone and its
//  footer. The session (`SituationSessionView`) lays cards side by side in Book
//  1's carousel, so each card draws only from its own `SituationCardState`. The
//  session keeps that state, which lets a finished card be shown again exactly
//  as it ended, and lets the card in play be rebuilt after it leaves the screen.
//
//  Binding UI rules (docs/archive/plans/2026-10-11-book-2-pilot-v2-handoff.md):
//  - The card never scrolls as a whole. Only the chat scrolls; when space is
//    short the chat gives up room, and excess word tiles scroll inside a tray
//    tall enough for two rows.
//  - English only on tap, in a tooltip right above the word (spoken forms show
//    `* `). New words are underlined. A tap anywhere else closes the tooltip.
//  - Learner bubbles use the palette's `tileOn`; server bubbles are white with
//    an ink outline. No strike-through, no colour flash in Corriger.
//  - Motion timings match the pilot; don't speed them up.
//  - French text is visible from the start; audio is replay only (auto-speak,
//    when the learner turns it on, reads the follow-up line).
//

import SwiftUI

/// Everything that draws one card. Choice indices are AUTHORED indices; only
/// the display order is shuffled, so grading never depends on screen position.
struct SituationCardState {
    enum Slot: Equatable { case hidden, building, preview(String), done(String, ok: Bool) }
    enum FixPhase { case find, choose }

    var step = 0
    var finished = false
    /// Outcome of each solved drill (worst wins).
    var drillOutcomes: [SituationOutcome] = []
    var tries = 0
    var drillMisses = 0
    var drillFailed = false
    var selected: Int?
    var wrongChoices: Set<Int> = []
    var rightChoice: Int?
    var placed: [Int] = []
    var bankOrder: [Int] = []
    /// Répondre answers already refused this drill (`SituationRetry`):
    /// Vérifier stays off until the placed tiles differ from all of them.
    var rejectedReplies: [[String]] = []
    var note = ""
    var slot: Slot = .hidden
    var gapText: String?
    var gapSettled = false
    var fixPhase: FixPhase = .find
    var errorFixed = false
    var showFollow = false
    /// True while a solved drill settles, before the next one slides in.
    var locked = false
    /// "Trop facile" armed on this card (shared gate, `TooEasy.swift`): the
    /// session resolves it when the card is finished.
    var pendingTooEasy = false

    /// No miss on this card so far (solved drills all first try, none in the
    /// drill in play) — the only state in which "Trop facile" can still remove.
    var clean: Bool {
        drillMisses == 0 && !drillFailed && drillOutcomes.allSatisfy { $0 == .good }
    }

    /// A fresh card at its first drill.
    init(item: SituationItem, salt: Int) {
        startDrill(item: item, salt: salt)
    }

    func drill(of item: SituationItem) -> SituationDrill? {
        finished ? nil : item.drills[step]
    }

    /// Clears the per-drill state and sets up drill `step`.
    mutating func startDrill(item: SituationItem, salt: Int) {
        tries = 0; drillMisses = 0; drillFailed = false
        selected = nil; wrongChoices = []; rightChoice = nil
        placed = []; rejectedReplies = []; note = ""; fixPhase = .find
        guard let drill = drill(of: item) else { return }
        if drill.type == .reply || drill.type == .pick { slot = .building }
        if drill.type == .reply {
            bankOrder = SituationShuffle.bankOrder(
                bank: drill.bank ?? [], accepted: drill.accepted ?? [],
                seed: SituationShuffle.seed("\(item.id)#\(step)#bank#\(salt)"))
        }
    }

    #if DEBUG
    /// Simulator flags: `step` jumps to drill n (earlier drills show solved);
    /// `stage` "fill" previews a filled answer, "done" the finished state.
    mutating func applyLaunch(step n: Int?, stage: String?, item: SituationItem, salt: Int) {
        if let n, item.drills.indices.contains(n) {
            slot = .hidden
            for d in item.drills.prefix(n) { showSolved(d) }
            step = n
            startDrill(item: item, salt: salt)
            if item.drills[n].type != .reply && item.drills[n].type != .pick,
               item.drills.prefix(n).allSatisfy({ $0.type != .reply && $0.type != .pick }) { slot = .hidden }
        }
        switch stage {
        case "fill":
            guard let drill = drill(of: item) else { break }
            let bank = drill.bank ?? []
            switch drill.type {
            case .reply:
                var used: [Int] = []
                for tile in drill.accepted?.first ?? [] {
                    if let i = bank.indices.first(where: { bank[$0] == tile && !used.contains($0) }) { used.append(i) }
                }
                placed = used
            case .pick, .complete:
                if let c = drill.correct, let choices = drill.choices {
                    let wrong = (c + 1) % choices.count
                    selected = wrong
                    if drill.type == .pick { slot = .preview(choices[wrong]) } else { gapText = choices[wrong] }
                }
            case .fix: fixPhase = .choose; selected = 0
            case .comprehend, .word:
                wrongChoices = [((drill.correct ?? 0) + 1) % max(1, drill.choices?.count ?? 1)]
                note = drill.miss ?? ""; tries = 1; drillMisses = 1
            }
        case "done":
            for d in item.drills { showSolved(d) }
            finished = true; showFollow = true
        default: break
        }
    }

    private mutating func showSolved(_ d: SituationDrill) {
        if d.type == .reply { slot = .done(d.model ?? "", ok: true) }
        if d.type == .pick, let right = d.correctChoice { slot = .done(right, ok: true) }
        if d.type == .complete { gapText = d.correctChoice; gapSettled = true }
        if d.type == .fix { errorFixed = true }
    }
    #endif
}

/// One wrong attempt, kept for the card's done block and the closing summary.
struct SituationMistake: Identifiable {
    let id = UUID()
    let cardIndex: Int
    let elementTitle: String
    /// Drill name as shown ("Corriger", or a standalone label).
    let title: String
    let given: String
    let expected: String
    let why: String?
}

struct SituationCardView: View {
    let item: SituationItem
    /// Changes each time the item comes back, so its choices reshuffle.
    let salt: Int
    /// Label above the cue when the item has no place.
    let fallbackPlace: String
    let words: [String: SituationWord]
    let wordMatcher: SituationText.Matcher
    /// Prepended to the item's audio keys (the Test book's clips are `pilot2_…`).
    let audioPrefix: String
    /// The session's first card shows the "tap a word" hint.
    let isFirst: Bool
    let isLast: Bool
    /// Behind the card in play: finished, shown as it ended, read-only.
    let reviewing: Bool
    /// The centred card. Off-screen cards close their tip and never speak.
    let active: Bool
    /// Footer label while reviewing ("Suivant", or "Reprendre" next to the card in play).
    let forwardLabel: String
    /// This card's wrong attempts.
    let mistakes: [SituationMistake]
    let autoSpeak: Bool
    @Binding var state: SituationCardState
    /// A wrong attempt: drill type, drill title, given, expected, why.
    let onMistake: (SituationDrill.Kind, String, String, String, String?) -> Void
    /// The last drill is solved; the card's rating.
    let onFinished: (SituationOutcome) -> Void
    /// Footer on the finished card in play: next dialogue, or the summary.
    let onNext: () -> Void
    /// Footer while reviewing.
    let onForward: () -> Void
    #if DEBUG
    var launch = SituationLaunch()
    #endif

    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    private var theme: AppTheme { AppPalette(stored: paletteID).theme }

    @State private var flashedWord: String?
    @State private var slotSwapInstant = false
    /// Natural height of the reply tiles; taller banks scroll in a two-row tray.
    @State private var trayContentHeight: CGFloat = 0
    /// Card fit (the card never scrolls): reserve two reply rows and let the
    /// dialogue scroll when its bubbles exceed the remaining space.
    @State private var fit = SituationCardFit()
    // Tap-to-show English.
    @State private var tip: Tip?
    @State private var tipToken = 0
    @State private var tipPinned = false
    /// Measured width of the shown tip bubble, so it can be kept on screen.
    @State private var tipWidth: CGFloat = 0
    @State private var lastWordTap = Date.distantPast

    /// One curve for every drill-to-drill change.
    private static let motion = Animation.smooth(duration: 0.5)
    private static let tileSpring = Animation.spring(response: 0.32, dampingFraction: 0.82)
    /// Rise-and-fade for content that replaces content.
    private static let swap = AnyTransition.asymmetric(
        insertion: .opacity.combined(with: .offset(y: 14))
            .animation(.smooth(duration: 0.45).delay(0.16)),
        removal: .opacity.animation(.easeOut(duration: 0.16)))

    private struct Tip: Equatable { let id: String; let french: String; let english: String }

    private var drill: SituationDrill? { state.drill(of: item) }
    private var newWordKeys: Set<String> { Set(item.newWords.map(SituationText.norm)) }

    var body: some View {
        VStack(spacing: 0) {
            cueBlock
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.header = $0 }
            // The chat takes what is left and scrolls inside itself. With a word
            // tray below, the chat keeps room for its bubbles when possible;
            // excess choices scroll inside the tray.
            chat
                .frame(minHeight: fit.chatFloor(trayShown: drill?.type == .reply))
            Rectangle().fill(AppColor.hairline).frame(height: 1).padding(.top, 10)
            ZStack(alignment: .topLeading) {
                zone
                    .id("\(state.step)-\(state.finished)")
                    .transition(Self.swap)
            }
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
        .background(AppColor.paper)
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
        .onChange(of: active) { _, isActive in if !isActive { tip = nil } }
        #if DEBUG
        .onAppear(perform: pinLaunchTip)
        // The Test book has no intro, so its first card can appear before the
        // session reads the launch flags.
        .onChange(of: launch.tip) { _, _ in pinLaunchTip() }
        .task(id: active && launch.autoplay != nil) { await autoplay() }
        #endif
    }

    private var cueBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(reviewing ? "Révision · " + (item.place ?? fallbackPlace) : (item.place ?? fallbackPlace))
                .uppercaseLabel()
            Text(item.cue).font(.display(size: 21, wght: 400)).foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 16)
        // Place and situation read as one heading, so the rotor can jump to it.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
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
                                                 audioKey: audioPrefix + item.turnAudioKey(i),
                                                 audioLocked: i == item.gapTurnIndex && !state.gapSettled)
                                }
                            }
                            if state.slot != .hidden {
                                slotBubble.transition(Self.swap)
                            }
                            if state.showFollow, let followUp = item.followUp {
                                serverBubble(id: "f", name: item.followUpSpeaker, text: followUp,
                                             audioKey: audioPrefix + item.followUpAudioKey)
                                    .transition(Self.swap)
                            }
                        }
                        // The bubbles' own height (the spacer above would grow with
                        // the chat and feed back into the fit), plus the top
                        // padding, the end marker and its spacing.
                        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.chatContent = $0 + 19 }
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
                .onChange(of: state.slot) { _, _ in scrollToEnd(reader) }
                .onChange(of: state.placed) { _, _ in scrollToEnd(reader) }
                .onChange(of: state.gapText) { _, _ in scrollToEnd(reader) }
                .onChange(of: state.step) { _, _ in scrollToEnd(reader) }
                .onChange(of: geo.size.height) { _, _ in scrollToEnd(reader) }
                .onChange(of: state.showFollow) { _, _ in scrollToEnd(reader) }
                .onAppear { scrollToEnd(reader) }
                // When the chat is taller than its space (small screens), the
                // oldest line fades out under the cue instead of being cut mid-line.
                .mask {
                    VStack(spacing: 0) {
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                            .frame(height: fit.chatContent > geo.size.height ? 28 : 0)
                        Rectangle()
                    }
                }
            }
        }
    }

    private func scrollToEnd(_ reader: ScrollViewProxy) {
        DispatchQueue.main.async { withAnimation(.easeOut(duration: 0.25)) { reader.scrollTo("end", anchor: .bottom) } }
    }

    private func speakerLabel(_ text: String) -> some View {
        Text(text).font(.label(size: 10.5)).tracking(1.2).foregroundColor(AppColor.g2).padding(.horizontal, 6)
    }

    /// `audioLocked`: the clip voices the gap's answer, so it stays off until the gap is settled.
    private func serverBubble(id: String, name: String?, text: String, audioKey: String,
                              audioLocked: Bool = false) -> some View {
        let hasAudio = Speaker.bundledAudioURL(key: audioKey) != nil && !audioLocked
        return HStack {
            VStack(alignment: .leading, spacing: 3) {
                if let name { speakerLabel(name.uppercased()).accessibilityLabel(name) }
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
                switch state.slot {
                case .building:
                    Group {
                        if state.placed.isEmpty {
                            Text("votre réponse").font(.display(size: 15, wght: 400)).foregroundColor(AppColor.g2)
                                .padding(.horizontal, 10).frame(minWidth: 130, minHeight: 34)
                                .accessibilityLabel("Votre réponse, vide")
                        } else {
                            FlowLayout(spacing: 6, lineSpacing: 6) {
                                ForEach(state.placed, id: \.self) { bankIndex in
                                    Button {
                                        guard !state.locked else { return }
                                        withAnimation(Self.tileSpring) { state.placed.removeAll { $0 == bankIndex } }
                                    } label: {
                                        MagnetTile(text: bank[bankIndex], style: .placed)
                                    }
                                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(bank[bankIndex])
                                    .accessibilityHint("Retire ce mot de votre réponse")
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
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
            .frame(maxWidth: .infinity, alignment: .trailing)
            .transaction { $0.disablesAnimations = slotSwapInstant }
        }
    }

    private var bank: [String] { drill?.bank ?? [] }
    private var placedTiles: [String] { state.placed.map { bank[$0] } }
    private var canCheckReply: Bool { SituationRetry.canCheck(placedTiles, rejected: state.rejectedReplies) }

    // MARK: - Words

    private func lineText(id: String, text: String, turnIndex: Int?) -> some View {
        let fixLine = turnIndex != nil && turnIndex == item.errorTurnIndex
        let segments = wordMatcher.segments(text,
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
            let marked = isError && state.fixPhase == .choose && drill?.type == .fix && !state.errorFixed
            let shown = isError && state.errorFixed ? matchCase(mark?.fix ?? seg.display, like: seg.display) : seg.display
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
        if fixLine && drill?.type == .fix && state.fixPhase == .find && !state.locked {
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
        let filled = state.gapText != nil
        let settled = state.gapSettled
        return Text(state.gapText ?? " ")
            .font(.display(size: 19, wght: 400))
            .foregroundColor(AppColor.ink)
            .padding(.horizontal, settled ? 0 : 8)
            .frame(minWidth: settled ? 0 : 70)
            .background(RoundedRectangle(cornerRadius: 8)
                .fill(filled && !settled ? Color(hex: theme.tileOn) : .clear))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(settled ? .clear : (filled ? AppColor.ink : AppColor.g2),
                              style: StrokeStyle(lineWidth: 1.5, dash: filled ? [] : [4, 3])))
            .accessibilityLabel(state.gapText.map { settled ? $0 : "Blanc : \($0)" } ?? "Blanc")
    }

    private func matchCase(_ word: String, like original: String) -> String {
        guard let first = original.first, first.isUppercase else { return word }
        return word.prefix(1).uppercased() + word.dropFirst()
    }

    private func tapWord(_ seg: SituationText.Segment, wordID: String, fixLine: Bool, isError: Bool) {
        if fixLine && drill?.type == .fix && state.fixPhase == .find {
            withAnimation(Self.motion) { tapFix(isError: isError, wordID: wordID, word: seg.display) }
            return
        }
        guard let key = seg.key, let word = words[key] else { return }
        lastWordTap = Date()
        withAnimation(.easeOut(duration: 0.15)) {
            tip = Tip(id: wordID, french: seg.display, english: word.tipText)
        }
        announce(word.en)
        tipPinned = false
        tipToken += 1
    }

    private func tipBubble(_ tip: Tip, word: CGRect, width: CGFloat) -> some View {
        // A long gloss wraps onto more lines instead of running off the card.
        let maxWidth = min(260, width - 20)
        let estimate = min(maxWidth, CGFloat(max(tip.french.count, tip.english.count)) * 8.4 + 28)
        let bubble = tipWidth > 0 ? min(tipWidth, maxWidth) : estimate
        let centerX = min(max(word.midX, bubble / 2 + 10), width - bubble / 2 - 10)
        return VStack(spacing: 0) {
            VStack(spacing: 1) {
                Text(tip.french).font(.label(size: 12, wght: 500)).opacity(0.65)
                let parts = Self.tipParts(tip.english)
                Text(parts.meaning).font(.display(size: 15, wght: 500))
                if let note = parts.note {
                    Text(note).font(.label(size: 12, wght: 500)).opacity(0.65)
                        .padding(.top, 2)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundColor(AppColor.white)
            .padding(.horizontal, 12).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 12).fill(AppColor.ink))
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { tipWidth = $0 }
            SituationTipArrow().fill(AppColor.ink).frame(width: 14, height: 7)
                .offset(x: word.midX - centerX)
        }
        .frame(width: maxWidth)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: width, height: max(0, word.minY - 4), alignment: .bottom)
        .offset(x: centerX - width / 2)
        .transition(.opacity)
    }

    /// Splits "meaning (note)" into the meaning and the note without its
    /// brackets, so a long gloss reads as a short meaning plus a small note.
    /// Only the last bracket group splits off, and only after a space:
    /// "cancel(s) (je, il)" gives "cancel(s)" + "je, il"; "close(s), shut(s)"
    /// and a gloss that is all one bracket group stay whole.
    static func tipParts(_ english: String) -> (meaning: String, note: String?) {
        guard english.hasSuffix(")") else { return (english, nil) }
        let chars = Array(english)
        var depth = 0
        var open = chars.count - 1
        while open >= 0 {
            if chars[open] == ")" { depth += 1 }
            if chars[open] == "(" { depth -= 1; if depth == 0 { break } }
            open -= 1
        }
        guard open > 0, chars[open - 1] == " " else { return (english, nil) }
        let meaning = String(chars[..<(open - 1)])
        let note = String(chars[(open + 1)..<(chars.count - 1)])
        return (meaning, note)
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
                        Text("\(state.step + 1)/\(item.drills.count)").uppercaseLabel()
                            .accessibilityLabel("Exercice \(state.step + 1) sur \(item.drills.count)")
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                Text(promptText(drill))
                    .font(.display(size: 21, wght: 350))
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                drillBody(drill)
                Text(state.note.isEmpty && isFirst && state.step == 0 && state.tries == 0 && drill.type != .fix
                     ? "Touchez un mot pour voir l'anglais." : state.note)
                    .font(.display(size: 14, wght: 400))
                    .foregroundColor(AppColor.graphite)
                    .frame(minHeight: 20, alignment: .topLeading)
                    .fixedSize(horizontal: false, vertical: true)
                    .onChange(of: state.note) { _, new in announce(new) }
            } else {
                doneBlock
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func promptText(_ drill: SituationDrill) -> String {
        if drill.type == .fix, state.fixPhase == .choose, let mark = item.errorMark {
            return "What should « \(mark.word) » be?"
        }
        if drill.type == .fix, state.fixPhase == .find {
            return "Tap the wrong word in your line."
        }
        return drill.prompt
    }

    /// Display order for the current drill's choices (authored indices).
    private func displayOrder(count: Int, tag: String) -> [Int] {
        SituationShuffle.order(count: count,
                               seed: SituationShuffle.seed("\(item.id)#\(state.step)#\(tag)#\(salt)"))
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
            if state.fixPhase == .choose, let mark = item.errorMark {
                choiceGrid(mark.choices, order: displayOrder(count: mark.choices.count, tag: "fix"),
                           columns: 3, stacked: false) { c in
                    withAnimation(Self.motion) { if !state.locked { state.selected = c } }
                }
            }
        case .reply:
            replyTray
        }
    }

    /// Keep up to two rows of choices visible. More tiles scroll within the tray,
    /// while the card and its footer stay fixed.
    private var replyTray: some View {
        ScrollView(.vertical, showsIndicators: false) {
            FlowLayout(spacing: 8, lineSpacing: 8) {
                ForEach(state.bankOrder, id: \.self) { i in
                    let used = state.placed.contains(i)
                    Button {
                        guard !state.locked else { return }
                        withAnimation(Self.tileSpring) { state.placed.append(i) }
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
        .frame(height: min(SituationCardFit.trayVisibleHeight, max(96, trayContentHeight)))
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { fit.tray = $0 }
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Color(hex: theme.tint)))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func choiceGrid(_ choices: [String], order: [Int], columns: Int, stacked: Bool,
                            action: @escaping (Int) -> Void) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, columns)), spacing: 8) {
            ForEach(order.filter { choices.indices.contains($0) }, id: \.self) { i in
                let isRight = state.rightChoice == i
                let isWrong = state.wrongChoices.contains(i)
                let isSel = state.selected == i
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
                .disabled(isWrong || state.rightChoice != nil)
                .accessibilityValue(isRight ? "Bonne réponse" : (isWrong ? "Mauvaise réponse" : ""))
                .accessibilityAddTraits(isSel ? .isSelected : [])
            }
        }
    }

    private var doneBlock: some View {
        let outcome = SituationOutcome.dialogue(state.drillOutcomes)
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
                    guard active, !reviewing else { return }
                    announce(outcome == .again ? "Pas trouvé." : outcome == .hard ? "Réussi avec un essai de plus."
                             : "Du premier coup.")
                }
            if !mistakes.isEmpty {
                Text("Vos erreurs").uppercaseLabel()
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(mistakes) {
                        SituationMistakeRow(title: $0.title, given: $0.given, expected: $0.expected,
                                            why: $0.why, compact: true)
                    }
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
        let word = words[SituationText.norm(fr)]
        let hasAudio = word?.audio.flatMap(Speaker.bundledAudioURL(key:)) != nil
        return Button {
            if let key = word?.audio { Speaker.shared.playBundled(key: key) }
        } label: {
            (Text(fr).foregroundColor(AppColor.ink)
             + Text(" · \(word?.tipText ?? "")").foregroundColor(AppColor.graphite))
                .font(.display(size: 14, wght: 400))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppColor.hairline))
        }
        .buttonStyle(.plain)
        .disabled(!hasAudio)
        .accessibilityLabel("\(fr), \(word?.en ?? "")")
    }

    // MARK: - Footer

    private var footer: some View {
        let (label, enabled): (String, Bool) = {
            if reviewing { return (forwardLabel, true) }
            guard let drill else { return (isLast ? "Terminer" : "Suivant", true) }
            switch drill.type {
            case .comprehend, .word: return ("Choisissez une réponse", false)
            case .fix where state.fixPhase == .find: return ("Touchez le mot", false)
            case .reply: return ("Vérifier", canCheckReply)
            default: return ("Vérifier", state.selected != nil)
            }
        }()
        return VStack(spacing: Spacing.sm) {
            // "Trop facile" — every book has it (shared: `TooEasy.swift`).
            if SituationTooEasy.showsControl(finished: state.finished, reviewing: reviewing, locked: state.locked,
                                             pending: state.pendingTooEasy, clean: state.clean) {
                TooEasyControl(pending: $state.pendingTooEasy,
                               canCancel: SituationTooEasy.canCancel(clean: state.clean))
            }
            Button {
                if reviewing { onForward() } else if drill == nil { onNext() } else { withAnimation(Self.motion) { check() } }
            } label: {
                Text(label).contentTransition(.identity)
            }
            .buttonStyle(DrillButtonStyle())
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.4)
            .accessibilityHint(footerHint(enabled: enabled))
        }
    }

    /// Why the footer button is off, for VoiceOver.
    private func footerHint(enabled: Bool) -> String {
        guard !enabled, let drill else { return "" }
        switch drill.type {
        case .reply:
            return state.placed.isEmpty ? "Placez des mots d'abord." : "Changez votre réponse avant de vérifier."
        case .pick, .complete: return "Choisissez une réponse d'abord."
        case .fix: return state.fixPhase == .find ? "Touchez le mot faux dans votre ligne." : "Choisissez la correction."
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
        onMistake(drill.type, item.standalone ?? drill.type.title, given, expected, why)
    }

    private func startDrill() {
        flashedWord = nil
        trayContentHeight = 0
        state.startDrill(item: item, salt: salt)
    }

    /// One drill done: keep its outcome (the dialogue takes the worst). A
    /// Corriger whose wrong word was never found counts as not solved, even if
    /// its fix was then picked right.
    private func closeDrill(solved: Bool) {
        state.drillOutcomes.append(.drill(misses: state.drillMisses, solved: solved && !state.drillFailed))
    }

    private func miss() {
        state.drillMisses += 1
        state.tries += 1
    }

    /// Comprendre / Mot: a tap answers at once; two misses show the answer.
    private func instant(_ choice: Int) {
        guard !state.locked, let drill, let choices = drill.choices, let right = drill.correctChoice,
              choices.indices.contains(choice) else { return }
        if drill.isCorrect(choice: choices[choice]) {
            state.rightChoice = choice
            closeDrill(solved: true)
            advanceSoon(0.7)
            return
        }
        miss()
        state.wrongChoices.insert(choice)
        log(choices[choice], expected: right, why: drill.miss ?? drill.why(for: choice))
        if state.tries >= 2 {
            state.note = "Answer: \(right)."
            state.rightChoice = drill.correct
            closeDrill(solved: false)
            advanceSoon(1.7)
        } else {
            state.note = drill.miss ?? drill.why(for: choice) ?? "Pas encore. Touchez un mot pour voir l'anglais."
        }
    }

    private func select(_ choice: Int) {
        guard !state.locked, let drill, let choices = drill.choices, choices.indices.contains(choice) else { return }
        state.selected = choice
        if drill.type == .pick { state.slot = .preview(choices[choice]) } else { state.gapText = choices[choice] }
    }

    private func check() {
        guard !state.locked, let drill else { return }
        switch drill.type {
        case .reply:
            // An answer already refused (unchanged since the miss) never spends a try.
            guard canCheckReply else { return }
            let tiles = placedTiles
            if drill.accepts(tiles) {
                state.tries += 1
                closeDrill(solved: true)
                fillSlot(tiles.joined(separator: " "), ok: true); advanceSoon(0.75)
            } else {
                miss()
                let keep = drill.correctPrefixCount(tiles)
                log(tiles.joined(separator: " "), expected: drill.model ?? "",
                    why: keep > 0 ? "The start « \(tiles.prefix(keep).joined(separator: " ")) » was right." : nil)
                if state.tries < 2 {
                    state.placed = Array(state.placed.prefix(keep))
                    state.rejectedReplies += SituationRetry.rejected(after: tiles, keep: keep)
                    state.note = "Pas encore : « \(tiles.joined(separator: " ")) »"
                        + (keep > 0 ? ". The start is kept; fix the rest." : ". Try again.")
                } else {
                    closeDrill(solved: false)
                    fillSlot(drill.model ?? "", ok: false); advanceSoon(1.1)
                }
            }
        case .pick, .complete:
            guard let selected = state.selected, let choices = drill.choices, let right = drill.correctChoice,
                  choices.indices.contains(selected) else { return }
            if drill.isCorrect(choice: choices[selected]) {
                state.tries += 1
                closeDrill(solved: true)
                settle(drill, text: right, ok: true)
            } else if state.tries < 1 {
                miss()
                state.wrongChoices.insert(selected)
                log(choices[selected], expected: right, why: drill.why(for: selected))
                state.note = drill.why(for: selected) ?? "Pas encore."
                state.selected = nil
                if drill.type == .pick { state.slot = .building } else { state.gapText = nil }
            } else {
                miss()
                log(choices[selected], expected: right, why: drill.why(for: selected))
                closeDrill(solved: false)
                settle(drill, text: right, ok: false)
            }
        case .fix:
            guard let selected = state.selected, let mark = item.errorMark,
                  mark.choices.indices.contains(selected) else { return }
            let picked = mark.choices[selected]
            if picked == mark.fix {
                state.tries += 1
                closeDrill(solved: true)
                state.errorFixed = true; advanceSoon(0.75)
            } else {
                miss()
                log("\(mark.word) → \(picked)", expected: "\(mark.word) → \(mark.fix)", why: mark.why)
                if state.tries >= 2 || state.drillFailed {
                    closeDrill(solved: false)
                    state.errorFixed = true; advanceSoon(1.1)
                } else {
                    state.wrongChoices.insert(selected); state.selected = nil
                    state.note = mark.why ?? "Pas encore."
                }
            }
        case .comprehend, .word:
            break
        }
    }

    /// Tiles/preview → final text in place, so old and new never overlap.
    private func fillSlot(_ text: String, ok: Bool) {
        slotSwapInstant = true
        state.slot = .done(text, ok: ok)
        DispatchQueue.main.async { slotSwapInstant = false }
    }

    private func settle(_ drill: SituationDrill, text: String, ok: Bool) {
        if drill.type == .pick {
            fillSlot(text, ok: ok)
        } else {
            state.gapText = text; state.gapSettled = true
        }
        advanceSoon(ok ? 0.75 : 1.1)
    }

    /// Corriger, first step: find the wrong word. Two wrong taps reveal it.
    private func tapFix(isError: Bool, wordID: String, word: String) {
        guard !state.locked, let drill else { return }
        if isError {
            state.fixPhase = .choose; state.tries = 0; state.note = ""
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
        if state.tries >= 2 {
            // Not found: show it. The fix step still runs, but the drill is lost.
            state.drillFailed = true
            state.fixPhase = .choose; state.tries = 0
            state.note = "It was « \(item.errorMark?.word ?? "") »."
        } else {
            state.note = drill.miss ?? "That word is fine."
        }
    }

    /// Let the solved state sit for a beat, then move on in one animated step.
    /// Input is ignored meanwhile. The state lives in the session, so this
    /// still lands if the card is swiped away meanwhile.
    private func advanceSoon(_ delay: Double) {
        state.locked = true
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(Self.motion) { advance() }
        }
    }

    private func advance() {
        state.locked = false
        if state.step + 1 < item.drills.count {
            state.step += 1
            startDrill()
        } else {
            state.finished = true
            state.note = ""
            onFinished(SituationOutcome.dialogue(state.drillOutcomes))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                guard state.finished, !state.showFollow else { return }
                withAnimation(Self.motion) { state.showFollow = true }
                if autoSpeak, active, let followUp = item.followUp, !followUp.isEmpty {
                    Speaker.shared.playBundled(key: audioPrefix + item.followUpAudioKey)
                }
            }
        }
    }

    // MARK: - Simulator flags (DEBUG)

    #if DEBUG
    func launching(_ launch: SituationLaunch) -> SituationCardView {
        var card = self
        card.launch = launch
        return card
    }

    private func pinLaunchTip() {
        guard let key = launch.tip, let word = words[key] else { return }
        for (i, turn) in item.turns.enumerated() {
            if let seg = wordMatcher.segments(turn.text).first(where: { $0.key == key }) {
                tip = Tip(id: "t\(i)-\(seg.index)", french: seg.display, english: word.tipText)
                tipPinned = true
                return
            }
        }
    }

    /// CB_*_AUTOPLAY: the card in play answers itself, one action at a time,
    /// then moves on with `onNext`.
    private func autoplay() async {
        guard active, !reviewing, let mode = launch.autoplay else { return }
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        while !Task.isCancelled {
            if !state.locked {
                if let drill {
                    withAnimation(Self.motion) { autoStep(drill, wrongFirst: mode == "wrong") }
                } else if state.showFollow || item.followUp == nil {
                    onNext()
                    return
                }
            }
            try? await Task.sleep(nanoseconds: 1_100_000_000)
        }
    }

    private func autoStep(_ drill: SituationDrill, wrongFirst: Bool) {
        if wrongFirst && state.drillMisses == 0 && state.tries == 0 && state.wrongChoices.isEmpty
            && state.fixPhase == .find {
            autoWrong(drill)
            return
        }
        switch drill.type {
        case .comprehend, .word:
            if let c = drill.correct { instant(c) }
        case .reply:
            // The last accepted reply (often the alternative), unless the
            // tiles kept after a miss already start another one.
            let kept = placedTiles
            let replies = drill.accepted ?? []
            let target = replies.reversed().first { Array($0.prefix(kept.count)) == kept } ?? replies.last ?? []
            if state.placed.count < target.count {
                let tile = target[state.placed.count]
                if let i = bank.indices.first(where: { bank[$0] == tile && !state.placed.contains($0) }) {
                    withAnimation(Self.tileSpring) { state.placed.append(i) }
                }
            } else { check() }
        case .pick, .complete:
            if state.selected == nil, let c = drill.correct { select(c) } else { check() }
        case .fix:
            if state.fixPhase == .find { tapFix(isError: true, wordID: "", word: item.errorMark?.word ?? "") }
            else if state.selected == nil, let mark = item.errorMark { state.selected = mark.choices.firstIndex(of: mark.fix) }
            else { check() }
        }
    }

    /// One wrong attempt per drill (CB_*_AUTOPLAY=wrong).
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
            state.placed = used; check()
        case .fix:
            let line = item.errorTurnIndex.map { item.turns[$0].text } ?? ""
            let first = SituationText.tokens(line).first {
                SituationText.norm($0) != SituationText.norm(item.errorMark?.word ?? "")
            } ?? ""
            tapFix(isError: false, wordID: "auto", word: first)
        }
    }
    #endif
}

#if DEBUG
/// Simulator launch flags a card applies to itself (the session decides which
/// card gets them).
struct SituationLaunch {
    /// Gloss key whose English opens pinned on the card.
    var tip: String?
    /// "1" plays every drill right; "wrong" misses each drill once first.
    var autoplay: String?
}
#endif

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
/// keeps room for its bubbles when possible and reserves two visible rows for
/// the word tray; additional choices scroll inside the tray.
/// Every input is a measured height in points. The tray's own height is
/// subtracted from the drill zone, so the result never feeds back into itself.
struct SituationCardFit: Equatable {
    static let trayVisibleHeight: CGFloat = 116
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
        return max(Self.chatMin, min(chatContent, shared - Self.trayVisibleHeight))
    }
}
