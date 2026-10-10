//
//  BookView.swift
//  carambole
//
//  The book home — design/motion.html "01 · Objet". A chrome carambole star turns
//  in the middle of the screen with the book's progress as a ring orbiting it
//  (`StarLoopView`); small type sits at the edges (after IMG_0943):
//
//    ‹ Fondations                      Réglages
//    41 %                                   Fin
//    128 / 312 maîtrisés               ~22 déc.
//    3 fragiles · à réviser
//                  (star + orbit ring)
//    fait : 3 appris · 12 révisés →
//    ───────────────────────────────────────────
//    8                                       14
//    Apprendre →                      ← Réviser
//                  25 modules →
//
//  Tapping the bottom line (only) opens the module list (`ModuleListView`);
//  a row there opens the same Leçon introduction as Apprendre.
//  Positions are motion.html's 360×760 px read as points: the top block hangs
//  from the safe area (prototype status bar = 50 px), the bottom block from the
//  screen bottom.
//

import SwiftUI

/// A daily / module study session, captured fresh at present-time so the cover
/// renders a current element list. A new `id` each time forces a rebuild.
private struct ElementSession: Identifiable {
    let id = UUID()
    let title: String
    let ruleNote: String
    let elements: [GrammarElement]
    let mode: DrillSessionView.Mode
    var moduleNumber: Int? = nil
    var module: CourseModule? = nil
}

struct BookView: View {
    /// Shown with a back affordance when pushed from the library shelf.
    var showBack: Bool = false

    @StateObject private var viewModel = BookViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var session: ElementSession?
    @State private var showingSettings = false
    @State private var showingModules = false
    @State private var showingToday = false
    /// The star loop plays only while the home is on screen: under a pushed
    /// page or a drill it pauses (the view stays mounted, so coming back is
    /// instant).
    @State private var starLive = true
    @AppStorage(AppPalette.storageKey) private var paletteID = AppPalette.fallback.rawValue
    @State private var revealed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppColor.paper.ignoresSafeArea()

                StarLoopView(mastered: masteredFraction, inProgress: inProgressFraction,
                             palette: AppPalette(stored: paletteID), active: starLive)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    topBlock
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 16)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    bottomBlock
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.bottom, 31)
                .ignoresSafeArea(edges: .bottom)
            }
            .opacity(revealed ? 1 : 0)
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .onAppear {
            viewModel.load()
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.45)) { revealed = true }
        }
        .fullScreenCover(item: $session, onDismiss: { viewModel.refresh() }) { s in
            DrillSessionView(title: s.title, ruleNote: s.ruleNote, elements: s.elements, mode: s.mode,
                             moduleNumber: s.moduleNumber, module: s.module, viewModel: viewModel) {
                session = nil
            }
        }
        .navigationDestination(isPresented: $showingModules) {
            ModuleListView(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showingToday) {
            TodayView(viewModel: viewModel, startLearn: startLearn, startReview: startReview)
        }
        .onChange(of: showingToday) { _, shown in
            if !shown { starLive = true }
        }
        .onChange(of: showingModules) { _, shown in
            if !shown { starLive = true }
        }
        .onChange(of: session == nil) { _, closed in
            starLive = closed
        }
        .sheet(isPresented: $showingSettings, onDismiss: { viewModel.refresh() }) {
            SettingsView(store: viewModel.settingsStore)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        #if DEBUG
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openModules.notification)) { _ in
            starLive = false
            showingModules = true
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeModules.notification)) { _ in
            showingModules = false
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openToday.notification)) { _ in
            starLive = false
            showingToday = true
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeToday.notification)) { _ in
            showingToday = false
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.openSettings.notification)) { _ in
            showingSettings = true
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeSettings.notification)) { _ in
            showingSettings = false
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.startReview.notification)) { _ in
            startReview()
        }
        .onReceive(NotificationCenter.default.publisher(for: DemoRemote.Action.closeSession.notification)) { _ in
            session = nil
        }
        #endif
    }

    // MARK: - Derived

    private var est: ProgressEstimate { viewModel.estimate }

    private var masteredFraction: Double {
        est.total > 0 ? Double(est.masteredCount) / Double(est.total) : 0
    }

    private var inProgressFraction: Double {
        est.total > 0 ? Double(est.inProgressCount) / Double(est.total) : 0
    }

    /// "Français — Fondations" → "Fondations".
    private var shortTitle: String {
        let t = viewModel.book.title
        if let r = t.range(of: "— ") { return String(t[r.upperBound...]) }
        return t
    }

    // MARK: - Top block (back, settings, %, estimate, fragile)

    private var topBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                if showBack {
                    Button { dismiss() } label: {
                        Text("‹ \(shortTitle)").uppercaseLabel(AppColor.ink)
                            .padding(.vertical, 8).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, -8)
                    .accessibilityLabel("Bibliothèque")
                }
                Spacer()
                Button { showingSettings = true } label: {
                    Text("Réglages").uppercaseLabel()
                        .padding(.vertical, 8).contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.vertical, -8)
            }

            if est.total > 0 {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        numeral("\(est.percentComplete) %")
                        Text("\(est.masteredCount) / \(est.total) maîtrisés")
                            .uppercaseLabel()
                            .padding(.top, 6)
                        fragileChip
                            .padding(.top, 12)
                    }
                    .accessibilityElement(children: .contain)
                    Spacer()
                    estimateBlock
                }
                .padding(.top, 25)
            }
        }
    }

    /// The 44/200 edge numeral (motion.html `.c1 .num`: line-height 1).
    private func numeral(_ s: String) -> some View {
        Text(s)
            .font(.display(size: 44, wght: 200))
            .tracking(-1.76)
            .foregroundColor(AppColor.ink)
            .frame(height: 44)
            .fixedSize()
    }

    /// Fragile maîtrisés (`R < 0.80`). Shown only when > 0; tapping starts a
    /// Réviser round (ordered fragiles-first). Dashed underline = fragile form.
    @ViewBuilder
    private var fragileChip: some View {
        let n = est.fragileCount
        if n > 0 {
            Button(action: startReview) {
                Text("\(n) \(n == 1 ? "fragile" : "fragiles") · à réviser")
                    .uppercaseLabel(AppColor.ink)
                    .padding(.bottom, 4)
                    .overlay(alignment: .bottom) {
                        Line()
                            .stroke(AppColor.ink, style: StrokeStyle(lineWidth: 1, dash: [3, 2.5]))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -6)
            .accessibilityLabel("\(n) \(n == 1 ? "élément fragile" : "éléments fragiles") à réviser")
        }
    }

    /// Top-right estimate, 3 states: done / `Fin ~22 déc.` / early `Fin —`.
    private var estimateBlock: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("Fin").uppercaseLabel()
            Text(estimateValue)
                .font(.display(size: 15, wght: 400))
                .foregroundColor(AppColor.ink)
        }
        .multilineTextAlignment(.trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(estimateAccessibility)
    }

    private var estimateValue: String {
        if est.isComplete { return "Terminé" }
        if let finish = est.projectedFinish { return "~\(shortDate(finish))" }
        return "—"
    }

    private var estimateAccessibility: String {
        if est.isComplete { return "Livre terminé" }
        if let days = est.daysRemaining, let pace = est.pacePerDay, let finish = est.projectedFinish {
            return "Fin prévue vers le \(longDate(finish)) · \(daysText(days)) restants · rythme \(paceText(pace)) par jour"
        }
        return "Continue quelques jours pour estimer la durée."
    }

    // MARK: - Bottom block (fait, divider, Apprendre / Réviser, modules)

    private var bottomBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                starLive = false
                showingToday = true
            } label: {
                Text("fait : \(viewModel.learnedToday) appris · \(viewModel.reviewedToday) révisés →")
                    .font(.label(size: 14, wght: 650))   // inner font wins over uppercaseLabel's
                    .uppercaseLabel(AppColor.ink)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Aujourd'hui : \(viewModel.learnedToday) appris, \(viewModel.reviewedToday) révisés")

            Rectangle().fill(AppColor.g3).frame(height: 1)
                .padding(.top, 4)

            HStack(alignment: .top) {
                Button(action: startLearn) {
                    VStack(alignment: .leading, spacing: 4) {
                        numeral("\(viewModel.newAvailableToday)")
                        Text("Apprendre →").uppercaseLabel(AppColor.ink)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(viewModel.newestUnlockedModule() == nil)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Apprendre, \(viewModel.newAvailableToday) nouveaux")
                .accessibilityAddTraits(.isButton)

                Spacer()

                Button(action: startReview) {
                    VStack(alignment: .trailing, spacing: 4) {
                        numeral("\(viewModel.dueCount)")
                        Text("← Réviser").uppercaseLabel(AppColor.ink)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Réviser, \(viewModel.dueCount) à revoir")
                .accessibilityAddTraits(.isButton)
            }
            .padding(.top, 15)
            .frame(height: 100 + 15, alignment: .top)

            Button { openModules() } label: {
                Text("\(viewModel.book.modules.count) modules  →")
                    .font(.display(size: 17, wght: 400))
                    .tracking(-0.2)
                    .foregroundColor(AppColor.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.vertical, -10)
            .accessibilityLabel("Sommaire, \(viewModel.book.modules.count) modules")
        }
    }

    // MARK: - Actions

    private func startLearn() {
        guard let m = viewModel.newestUnlockedModule() else { return }
        session = ElementSession(title: m.title, ruleNote: m.ruleNote,
                                 elements: viewModel.moduleLearnElements(m), mode: .learn,
                                 moduleNumber: m.sortOrder, module: m)
    }

    private func startReview() {
        session = ElementSession(title: "Réviser", ruleNote: "",
                                 elements: viewModel.reviewSessionElements(), mode: .review)
    }

    private func openModules() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        starLive = false
        showingModules = true
    }

    // MARK: - Gesture: edge swipe → back

    /// From the left edge, a rightward swipe goes back to the library (iOS
    /// back-swipe direction).
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 6, coordinateSpace: .global)
            .onEnded { v in
                let h = v.translation.width
                if showBack, v.startLocation.x < 24, h > 60, abs(h) > abs(v.translation.height) {
                    dismiss()
                }
            }
    }

    // MARK: - Estimate formatting (French)

    /// `< 90` → "≈ N j"; `>= 90` → "≈ N mois" (rounded from days/30).
    private func daysText(_ n: Int) -> String {
        if n < 90 { return "≈ \(n) j" }
        return "≈ \(Int((Double(n) / 30).rounded())) mois"
    }

    /// "22 déc." — French is for DISPLAY only; the date itself was computed with
    /// the device calendar (the learner's own day boundaries).
    private func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).locale(Locale(identifier: "fr_FR")))
    }

    /// "22 décembre" for VoiceOver.
    private func longDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "fr_FR")))
    }

    /// One-decimal pace with a French comma, e.g. "8,5".
    private func paceText(_ pace: Double) -> String {
        pace.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "fr_FR")))
    }
}

// MARK: - Preview

#Preview {
    NavigationStack { BookView(showBack: true) }
}
