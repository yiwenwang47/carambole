//
//  BookView.swift
//  carambole
//
//  The book home — the app's root screen. A numbered editorial table of contents
//  of the book's modules, with the daily "Aujourd'hui · X new · Y due" panel and
//  the Apprendre / Réviser actions living INSIDE the book. Built from "Le Cahier".
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
}

struct BookView: View {
    /// Shown with a back affordance when pushed from the library shelf.
    var showBack: Bool = false

    @StateObject private var viewModel = BookViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var session: ElementSession?
    @State private var showingSettings = false
    @State private var revealed = false

    private var modules: [CourseModule] {
        viewModel.book.modules.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    header
                    bookProgress
                    todayPanel
                    divider
                    moduleList
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 72)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .onAppear {
            viewModel.load()
            withAnimation(.easeOut(duration: 0.45)) { revealed = true }
        }
        .fullScreenCover(item: $session, onDismiss: { viewModel.refresh() }) { s in
            DrillSessionView(title: s.title, ruleNote: s.ruleNote, elements: s.elements, mode: s.mode) {
                session = nil
            }
        }
        .sheet(isPresented: $showingSettings, onDismiss: { viewModel.refresh() }) {
            SettingsView(store: viewModel.settingsStore)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack(enabled: showBack) { dismiss() }
    }

    // MARK: - Header (book title)

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            if showBack {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.graphite)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, Spacing.sm)
                .accessibilityLabel("Bibliothèque")
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                SectionLabel("Grammaire")
                Text(viewModel.book.title)
                    .font(.appTitle)
                    .foregroundColor(AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(AppColor.graphite)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Réglages")
        }
        .padding(.bottom, Spacing.sm)
    }

    // MARK: - Book-completion bar + time-to-finish estimate

    /// Lingvist-style segmented book bar (maîtrisé · en cours · à venir), a % and a
    /// time-to-finish estimate. Hidden until the book is loaded (`total == 0`).
    @ViewBuilder
    private var bookProgress: some View {
        let est = viewModel.estimate
        if est.total > 0 {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .center, spacing: Spacing.md) {
                    GeometryReader { geo in
                        let w = geo.size.width
                        // total is already > 0 inside this branch; max(1,…) is a
                        // belt-and-braces div-by-zero guard for the segment widths.
                        let t = max(1, est.total)
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(AppColor.saffron)
                                .frame(width: CGFloat(est.masteredCount) / CGFloat(t) * w)
                            Rectangle()
                                .fill(AppColor.saffron.opacity(0.28))
                                .frame(width: CGFloat(est.inProgressCount) / CGFloat(t) * w)
                            Rectangle()
                                .fill(AppColor.hairline)
                                .frame(width: CGFloat(est.toComeCount) / CGFloat(t) * w)
                        }
                        .clipShape(Capsule())
                    }
                    .frame(height: 12)

                    Text("\(est.percentComplete) %")
                        .font(.appLabel)
                        .tracking(1)
                        .foregroundColor(AppColor.saffronDeep)
                        .fixedSize()
                }

                legend

                Text("\(est.masteredCount) / \(est.total) maîtrisés")
                    .font(.appExplain)
                    .foregroundColor(AppColor.graphite)

                fragileChip

                estimateLine
                    .font(.appExplain)
                    .foregroundColor(AppColor.graphite)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(progressAccessibilityLabel)
        }
    }

    /// At-risk band: maîtrisés whose memory has decayed below the fragile floor
    /// (`R < 0.80`). Shown ONLY when > 0; tapping it starts a Réviser round (which is
    /// ordered fragiles-first, so these surface immediately). Singular/plural French.
    @ViewBuilder
    private var fragileChip: some View {
        let n = viewModel.estimate.fragileCount
        if n > 0 {
            Button {
                session = ElementSession(title: "Réviser", ruleNote: "",
                                         elements: viewModel.reviewSessionElements(), mode: .review)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                    // House label treatment (uppercase + tracking) but recolored to
                    // `error` — `uppercaseLabel()` would force `graphite`, so apply the
                    // pieces inline and let the HStack's `foregroundColor` win.
                    Text("\(n) \(n == 1 ? "fragile" : "fragiles") · à réviser")
                        .font(.appLabel)
                        .tracking(2)
                        .textCase(.uppercase)
                }
                .foregroundColor(AppColor.error)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, 5)
                .background(
                    Capsule().fill(AppColor.error.opacity(0.10))
                )
                .contentShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("\(n) \(n == 1 ? "élément fragile" : "éléments fragiles") à réviser")
        }
    }

    /// Three colored dots + bucket names.
    private var legend: some View {
        HStack(spacing: Spacing.md) {
            legendItem(color: AppColor.saffron, label: "maîtrisé")
            legendItem(color: AppColor.saffron.opacity(0.28), label: "en cours")
            legendItem(color: AppColor.hairline, label: "à venir")
        }
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text(label).uppercaseLabel()
        }
    }

    /// Stat line 2: done / estimate / early-state, per `ProgressEstimate`.
    @ViewBuilder
    private var estimateLine: some View {
        let est = viewModel.estimate
        if est.isComplete {
            Text("Terminé ! 🎉")
        } else if est.hasEstimate, let days = est.daysRemaining,
                  let pace = est.pacePerDay, let finish = est.projectedFinish {
            Text("\(daysText(days)) restants · finir ~\(dateText(finish)) · rythme \(paceText(pace))/j")
        } else {
            Text("Continue quelques jours pour estimer la durée.")
        }
    }

    /// "{percent} % du livre maîtrisé[, environ {n} jours restants]".
    private var progressAccessibilityLabel: String {
        let est = viewModel.estimate
        var label = "\(est.percentComplete) % du livre maîtrisé"
        if !est.isComplete, let days = est.daysRemaining {
            label += ", environ \(days) jours restants"
        }
        return label
    }

    // MARK: Estimate formatting (French)

    /// `< 90` → "≈ N j"; `>= 90` → "≈ N mois" (rounded from days/30).
    private func daysText(_ n: Int) -> String {
        if n < 90 { return "≈ \(n) j" }
        return "≈ \(Int((Double(n) / 30).rounded())) mois"
    }

    /// Wide French month + day, e.g. "15 août". French is for DISPLAY only — the
    /// projected date itself was computed with the device calendar/timezone (so the
    /// learner's own day boundaries drive the estimate); don't force a UTC calendar
    /// here just to match the locale, or the day math would shift under the user.
    private func dateText(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.wide).locale(Locale(identifier: "fr_FR")))
    }

    /// One-decimal pace with a French comma, e.g. "8,5".
    private func paceText(_ pace: Double) -> String {
        pace.formatted(.number.precision(.fractionLength(1)).locale(Locale(identifier: "fr_FR")))
    }

    // MARK: - "Aujourd'hui" panel (lives inside the book)

    private var todayPanel: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionLabel("Aujourd'hui")

            progressLine

            HStack(spacing: Spacing.md) {
                Button(viewModel.newAvailableToday > 0 ? "Apprendre · \(viewModel.newAvailableToday)" : "Apprendre") {
                    guard let m = viewModel.newestUnlockedModule() else { return }
                    session = ElementSession(title: m.title, ruleNote: m.ruleNote,
                                             elements: viewModel.moduleLearnElements(m), mode: .learn)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button(viewModel.dueCount > 0 ? "Réviser · \(viewModel.dueCount)" : "Réviser") {
                    session = ElementSession(title: "Réviser", ruleNote: "",
                                             elements: viewModel.reviewSessionElements(), mode: .review)
                }
                .buttonStyle(PrimaryButtonStyle())
            }

            RoundSizeSelector(store: viewModel.settingsStore)
        }
    }

    /// Today's done-work, scoped to this book; taps through to the full history.
    private var progressLine: some View {
        NavigationLink {
            HistoryView()
        } label: {
            HStack(spacing: Spacing.sm) {
                Text("fait : \(viewModel.learnedToday) appris · \(viewModel.reviewedToday) révisés")
                    .uppercaseLabel()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(AppColor.graphite)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Historique de progression")
    }

    // MARK: - Module list

    private var moduleList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(modules.enumerated()), id: \.element.id) { index, module in
                let state = viewModel.state(for: module)
                let unlocked = state != .locked

                Button {
                    guard unlocked else { return }
                    session = ElementSession(title: module.title, ruleNote: module.ruleNote,
                                             elements: viewModel.moduleLearnElements(module), mode: .learn)
                } label: {
                    ModuleRow(number: index + 1,
                              title: module.title,
                              mastered: viewModel.masteredCount(in: module),
                              total: module.elements.count,
                              state: state)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(!unlocked)
                .opacity(revealed ? 1 : 0)
                .offset(y: revealed ? 0 : 12)
                .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.06), value: revealed)

                if index < modules.count - 1 {
                    Rectangle().fill(AppColor.hairline).frame(height: 1)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(AppColor.hairline).frame(height: 1)
    }
}

// MARK: - Réviser round-size selector

/// Inline segmented control for how many problems one Réviser tap presents
/// (`StudySettings.reviewRoundSizeOptions`). Writes straight to the settings store.
private struct RoundSizeSelector: View {
    @ObservedObject var store: StudySettingsStore

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Text("Révision par tour").uppercaseLabel()
            Spacer()
            HStack(spacing: 0) {
                ForEach(StudySettings.reviewRoundSizeOptions, id: \.self) { n in
                    let selected = store.settings.reviewRoundSize == n
                    Button { select(n) } label: {
                        Text("\(n)")
                            .font(.appLabel)
                            .tracking(1)
                            .foregroundColor(selected ? AppColor.paper : AppColor.graphite)
                            .frame(minWidth: 38)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(selected ? AppColor.ink : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(n) révisions par tour")
                    .accessibilityAddTraits(selected ? [.isSelected] : [])
                }
            }
            .padding(3)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(AppColor.hairline.opacity(0.5))
            )
        }
    }

    private func select(_ n: Int) {
        let s = store.settings
        store.settings = StudySettings(newPerDay: s.newPerDay,
                                       reviewTarget: s.reviewTarget,
                                       reviewRoundSize: n)
    }
}

// MARK: - Module row

private struct ModuleRow: View {
    let number: Int
    let title: String
    let mastered: Int
    let total: Int
    let state: ModuleState

    private var isLocked: Bool { state == .locked }

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            Text(String(format: "%02d", number))
                .font(.system(size: 15, weight: .regular, design: .monospaced))
                .foregroundColor(isLocked ? AppColor.hairline : AppColor.graphite)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.appTitle)
                    .foregroundColor(isLocked ? AppColor.graphite : AppColor.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !isLocked {
                    Text("\(mastered)/\(total) maîtrisés")
                        .uppercaseLabel()
                }
            }

            glyph
        }
        .padding(.vertical, Spacing.md)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var glyph: some View {
        switch state {
        case .done:
            Image(systemName: "checkmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColor.saffron)
        case .current:
            Circle().fill(AppColor.saffron).frame(width: 10, height: 10)
        case .locked:
            Image(systemName: "lock")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColor.graphite)
        }
    }
}

// MARK: - Preview

#Preview {
    BookView()
}
