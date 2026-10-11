//
//  ModuleDetailView.swift
//  carambole
//
//  The module page — motion.html 02 "Cinétique". The type moves and the grammar
//  is the motion: a looping `wght` wave rolls through the title, and below it a
//  ticker rolls through the module's example sentences (one per element, the
//  blank filled with the answer, answer in weight 500) like a split-flap board.
//  The rule label above the ticker names the element on show.
//
//  Below: the element list with its memory-strength bucket (maîtrisé · fragile ·
//  en cours · à venir). A GRADUATED element (maîtrisé or fragile) carries a swipe
//  action "Remettre en cours" → `BookViewModel.demoteElement`, the durable
//  un-graduate surface (the undo toast after "Trop facile" is the transient one).
//  A fixed `Apprendre` pill starts a learn session for this module; a locked
//  module shows a disabled `Verrouillé` pill.
//

import SwiftUI

struct ModuleDetailView: View {
    let module: CourseModule
    @ObservedObject var viewModel: BookViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The learn session presented full-screen (elements snapshotted at tap time).
    @State private var session: LearnSession?
    /// Ticker row on show. Runs 0…lines.count (the last value is the duplicated
    /// first row, snapped back to 0 without animation for a seamless loop).
    @State private var tickerIndex = 0

    private var elements: [GrammarElement] {
        module.elements.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var tickerLines: [TickerLine] {
        elements.compactMap(TickerLine.init(element:))
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    LoopWaveText(text: module.title)
                        .frame(height: Layout.titleRegion, alignment: .topLeading)
                        .padding(.top, 22)
                    ruleLabel
                    ticker
                        .padding(.top, 10)
                    elementList
                        .padding(.top, 30)
                    footnote
                }
                .padding(.horizontal, Layout.edge)
                .padding(.top, 10)
                .padding(.bottom, 24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { learnBar }
        // Re-read the live sets on appear (and after a demote elsewhere) so the
        // buckets, ring and lock state are current.
        .onAppear { viewModel.refresh() }
        .fullScreenCover(item: $session, onDismiss: { viewModel.refresh() }) { s in
            StudySessionView(viewModel: viewModel, title: module.title, ruleNote: module.ruleNote,
                             elements: s.elements, mode: .learn, moduleNumber: module.sortOrder) {
                session = nil
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack { dismiss() }
    }

    // MARK: Layout (motion.html 02, 360×760 px ≈ pt)

    private enum Layout {
        static let edge: CGFloat = 20
        /// `.title` top 112 → rule label top 306.
        static let titleRegion: CGFloat = 194
        static let rowHeight: CGFloat = 64
        static let tickerHeight: CGFloat = 128
        static let rollInterval: Double = 1.8
        static let roll = Animation.timingCurve(0.7, 0, 0.2, 1, duration: 0.9)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            Button { dismiss() } label: {
                Text("‹ Module \(module.sortOrder)")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Retour")

            Spacer()

            ProgressRing(progress: masteredFraction)
                .accessibilityElement()
                .accessibilityLabel("\(viewModel.masteredCount(in: module)) éléments maîtrisés sur \(module.elements.count)")
        }
    }

    private var masteredFraction: Double {
        guard !module.elements.isEmpty else { return 0 }
        return Double(viewModel.masteredCount(in: module)) / Double(module.elements.count)
    }

    // MARK: Rule label + ticker

    /// `.lab` above the ticker: the label of the element whose sentence is on show.
    private var ruleLabel: some View {
        let lines = tickerLines
        let text = lines.isEmpty ? "Exemples" : lines[tickerIndex % lines.count].elementLabel
        return Text(text)
            .uppercaseLabel()
            .lineLimit(1)
            .contentTransition(.opacity)
            // A quick swap, not the 0.9 s roll curve — two labels must not overlap long.
            .transaction { if $0.animation != nil { $0.animation = .easeOut(duration: 0.2) } }
            .accessibilityHidden(true)
    }

    private var ticker: some View {
        let lines = tickerLines
        // Two duplicated head rows let the column roll past the end seamlessly.
        let rows = lines + lines.prefix(2)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { k, line in
                line.text(dim: k != tickerIndex)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, minHeight: Layout.rowHeight,
                           maxHeight: Layout.rowHeight, alignment: .leading)
            }
        }
        .offset(y: -CGFloat(tickerIndex) * Layout.rowHeight)
        .frame(height: Layout.tickerHeight, alignment: .top)
        .clipped()
        .overlay(alignment: .top) { Rectangle().fill(AppColor.ink).frame(height: 1) }
        .overlay(alignment: .bottom) { Rectangle().fill(AppColor.g3).frame(height: 1) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(lines.isEmpty ? "" : lines[tickerIndex % lines.count].plain)
        .task(id: reduceMotion) { await runTicker(count: lines.count) }
    }

    /// Roll one row every 1.8 s (cubic-bezier(.7,0,.2,1) over .9 s). On reaching the
    /// duplicated head row, snap back to 0 after the roll lands (.95 s) — no motion
    /// visible because the rows are identical. Reduce motion: static first row.
    private func runTicker(count: Int) async {
        tickerIndex = 0
        guard !reduceMotion, count > 1 else { return }
        var wait = Layout.rollInterval
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            withAnimation(Layout.roll) { tickerIndex += 1 }
            wait = Layout.rollInterval
            if tickerIndex >= count {
                try? await Task.sleep(for: .seconds(0.95))
                guard !Task.isCancelled else { return }
                var tx = Transaction()
                tx.disablesAnimations = true
                withTransaction(tx) { tickerIndex = 0 }
                wait = Layout.rollInterval - 0.95
            }
        }
    }

    // MARK: Element list

    private var elementList: some View {
        ModuleElementRows(module: module, viewModel: viewModel)
    }

    private var footnote: some View {
        Text("Glisse un élément maîtrisé vers la gauche pour le remettre en cours.")
            .uppercaseLabel()
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 14)
    }

    // MARK: Apprendre

    private var learnBar: some View {
        let unlocked = viewModel.isUnlocked(module)
        return Button {
            session = LearnSession(elements: viewModel.moduleLearnElements(module))
        } label: {
            Text(unlocked ? "Apprendre" : "Verrouillé")
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(!unlocked)
        .opacity(unlocked ? 1 : 0.25)
        // Opaque base so the faded (locked) pill never shows the list through it.
        .background(Capsule(style: .continuous).fill(AppColor.paper))
        .accessibilityHint(unlocked ? "Commence une session pour ce module" : "Termine le module précédent")
        .padding(.horizontal, Layout.edge)
        .padding(.top, 18)
        .padding(.bottom, 8)
        .background(
            LinearGradient(stops: [.init(color: AppColor.paper.opacity(0), location: 0),
                                   .init(color: AppColor.paper, location: 0.3)],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
        )
    }
}

// MARK: - Learn session

private struct LearnSession: Identifiable {
    let id = UUID()
    let elements: [GrammarElement]
}

// MARK: - Ticker line (decision 5: the module's example sentences)

/// One element's example, rendered as final French: the blank filled with the answer
/// (answer pieces in weight 500), scaffolding stripped exactly as `spokenFrench` does.
struct TickerLine {
    let elementLabel: String
    /// Alternating light / answer pieces: even indices light, odd indices answer.
    let pieces: [String]

    var plain: String { pieces.joined() }

    /// Picks the element's shortest blanked example (falling back to a full build
    /// sentence) so most rows fit the 32pt line. nil when the element has no examples.
    init?(element: GrammarElement) {
        let scored: [(Int, [String])] = element.examples.map { ex in
            let p = Self.pieces(for: ex)
            let length = p.joined().count
            if Exercise.promptHasBlank(ex.prompt) { return (length, p) }
            // A build sentence reads fine but carries no emphasis; a short no-blank
            // answer (an MC pick like "le") is not a sentence at all.
            return (ex.answerTokens.count < 3 ? 1000 + length : 12 + length, p)
        }
        guard let best = scored.min(by: { $0.0 < $1.0 }) else { return nil }
        elementLabel = element.label
        pieces = best.1
    }

    static func pieces(for ex: Exercise) -> [String] {
        let answer = Exercise.spokenFrench(prompt: "", answer: Exercise.displayJoin(ex.answerTokens),
                                           hasBlank: false)
        guard Exercise.promptHasBlank(ex.prompt) else {
            return [capitalizedFirst(answer)]
        }
        // Run the same scaffolding strip as `spokenFrench`, with a marker standing in
        // for the answer, then split around it.
        let marker = "\u{E000}"
        let body = Exercise.spokenFrench(prompt: ex.prompt, answer: marker, hasBlank: true)
        let light = body.components(separatedBy: marker)
        var out: [String] = []
        for (i, part) in light.enumerated() {
            var part = part
            // An elided answer ("l'", "n'") hugs the next word.
            if i > 0, answer.hasSuffix("'") || answer.hasSuffix("\u{2019}") {
                part = String(part.drop { $0 == " " })
            }
            out.append(part)
            if i < light.count - 1 { out.append(answer) }
        }
        if let first = out.firstIndex(where: { !$0.isEmpty }) {
            out[first] = capitalizedFirst(out[first])
        }
        return out
    }

    private static func capitalizedFirst(_ s: String) -> String {
        guard let c = s.first else { return s }
        return c.uppercased() + s.dropFirst()
    }

    /// 32pt / 250, tracking -0.025em; answer pieces 500. Non-current rows dim to g3.
    func text(dim: Bool) -> Text {
        var attr = AttributedString()
        for (i, piece) in pieces.enumerated() where !piece.isEmpty {
            var run = AttributedString(piece)
            run.font = .display(size: 32, wght: i % 2 == 1 ? 500 : 250)
            attr.append(run)
        }
        return Text(attr)
            .tracking(-0.8)
            .foregroundColor(dim ? AppColor.g3 : AppColor.ink)
    }

    #if DEBUG
    static func _selfTest() {
        func ex(_ prompt: String, _ answer: [String]) -> Exercise {
            Exercise(id: "t", elementID: "e", type: .fillBlank, prompt: prompt, cue: nil,
                     answerTokens: answer, tokenBank: answer, inputMode: .multipleChoice,
                     explanation: "")
        }
        assert(pieces(for: ex("Complète : « ___ suis ici. »", ["je"])) == ["", "Je", " suis ici."])
        assert(pieces(for: ex("Complète : « Je ___ partir. » (aller)", ["vais"])) == ["Je ", "vais", " partir."])
        assert(pieces(for: ex("Complète : « ___ eau est froide. »", ["l'"])) == ["", "L'", "eau est froide."])
        assert(pieces(for: ex("Construis : « I am here. »", ["je", "suis", "ici", "."])) == ["Je suis ici."])
    }
    #endif
}

// MARK: - Element row (with custom swipe-to-demote on graduated elements)

/// One element row (02 `.els`): label · right-aligned bucket label, g4 hairline below.
/// À-venir rows read g3. A graduated element (maîtrisé / fragile) reveals a
/// "Remettre en cours" action on a leftward swipe — hand-rolled (no system List).
/// En-cours / à-venir rows don't swipe (nothing to un-graduate).
struct ModuleElementRows: View {
    let module: CourseModule
    @ObservedObject var viewModel: BookViewModel
    var onDemote: ((GrammarElement) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(module.elements.sorted { $0.sortOrder < $1.sortOrder }) { element in
                ElementRow(element: element, bucket: viewModel.bucket(for: element),
                           onDemote: {
                    if let onDemote { onDemote(element) }
                    else { viewModel.demoteElement(element.id) }
                })
            }
        }
    }
}

struct ElementRow: View {
    let element: GrammarElement
    let bucket: BookViewModel.ElementBucket
    let onDemote: () -> Void

    /// True only for graduated elements — the ones the swipe action applies to.
    private var canDemote: Bool {
        bucket == .mastered || bucket == .fragile
    }

    /// Width of the revealed action panel.
    private let actionWidth: CGFloat = 150
    /// Current horizontal offset of the row content (≤ 0; -actionWidth = fully open).
    @State private var offset: CGFloat = 0
    /// The row's rest offset captured at the START of the active drag, so a drag that
    /// begins from the OPEN position continues from there (and can close). `DragGesture`
    /// has no "began" callback, so `isDragging` marks the first change of each drag.
    @State private var dragStart: CGFloat = 0
    @State private var isDragging = false

    var body: some View {
        ZStack(alignment: .trailing) {
            // Revealed action sits BEHIND the row, exposed as the content slides left.
            if canDemote {
                demoteAction
            }
            rowContent
                .background(AppColor.paper)   // opaque so the action only peeks when open
                .offset(x: offset)
                .gesture(canDemote ? swipe : nil)
                // Tap an open row to close it — a dismiss path that doesn't fight the
                // screen's rightward `swipeToGoBack`. No-op when closed.
                .onTapGesture { if offset != 0 { close() } }
                .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.86), value: offset)
        }
        .clipped()
        .overlay(alignment: .bottom) { Rectangle().fill(AppColor.hairline).frame(height: 1) }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if canDemote {
                Button("Remettre en cours") { onDemote() }
            }
        }
    }

    // MARK: Row content

    private var rowContent: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(element.label)
                .font(.display(size: 15, wght: 400))
                .foregroundColor(bucket == .aVenir ? AppColor.g3 : AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            bucketLabel
        }
        .padding(.vertical, 9)
        .contentShape(Rectangle())
    }

    // MARK: Bucket label (state by form: ink / dashed underline / g2)

    @ViewBuilder
    private var bucketLabel: some View {
        switch bucket {
        case .mastered:
            Text("Maîtrisé").uppercaseLabel(AppColor.ink)
        case .fragile:
            Text("Fragile")
                .uppercaseLabel(AppColor.ink)
                .padding(.bottom, 2)
                .overlay(alignment: .bottom) {
                    Line()
                        .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .frame(height: 1)
                }
        case .enCours:
            Text("En cours").uppercaseLabel()
        case .aVenir:
            Text("À venir").uppercaseLabel()
        }
    }

    // MARK: Swipe action

    private var demoteAction: some View {
        HStack {
            Spacer()
            Button {
                onDemote()
                close()
            } label: {
                Text("Remettre en cours")
                    .uppercaseLabel(AppColor.paper)
                    .multilineTextAlignment(.center)
                    .frame(width: actionWidth)
                    .frame(maxHeight: .infinity)
                    .background(AppColor.buttonDark)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remettre \(element.label) en cours")
        }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { value in
                // Horizontally-dominant drags only, so vertical scroll still works.
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                // Engage ONLY on a leftward pull (demote direction) or when the row is
                // already open (so it can be dragged closed). A rightward drag on a
                // closed row is left alone — it must pass through to the screen's
                // swipe-to-go-back and to the ScrollView, never get eaten here.
                if !isDragging {
                    guard value.translation.width < 0 || offset != 0 else { return }
                    isDragging = true
                    dragStart = offset
                }
                // Clamp between [-actionWidth, 0] with a little rightward rubber-band.
                let raw = dragStart + value.translation.width
                offset = min(0, max(-actionWidth - 24, raw))
            }
            .onEnded { _ in
                isDragging = false
                // Snap from the RESULTING offset: past the half-open mark → open,
                // otherwise close. Works from either start state (open row drags closed).
                if offset < -actionWidth * 0.5 { open() } else { close() }
            }
    }

    private func open() {
        offset = -actionWidth
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func close() {
        offset = 0
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ModuleDetailView(module: .sample, viewModel: BookViewModel())
    }
}
