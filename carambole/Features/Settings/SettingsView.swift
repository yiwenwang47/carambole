//
//  SettingsView.swift
//  carambole
//
//  "Réglages" — study pacing settings. Two steppers backed by the SHARED
//  `StudySettingsStore` (single source of truth): the `newPerDay` HARD cap and
//  the `reviewTarget` SOFT goal. Writes go through the store, which clamps and
//  persists immediately.
//
//  Edge-type layout from design/motion.html (01 / 03 / 05 headers): tracked
//  labels pinned to the top edges, one big light heading, hairline rules, big
//  light numerals (`−  12  +` text steppers), black 54pt pill for `Fermer`.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    /// The shared settings store — NOT created here. Editing `store.settings`
    /// persists (clamped) on write via the store's `didSet`.
    @ObservedObject var store: StudySettingsStore

    @Environment(\.dismiss) private var dismiss

    /// Set when the user taps "Exporter" — drives the share sheet. Identifiable
    /// wrapper because a bare URL is not.
    @State private var shareItem: ShareItem?

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    edgeLabels
                    heading
                        .padding(.top, 22)

                    VStack(alignment: .leading, spacing: 0) {
                        rule(AppColor.ink)
                        newPerDaySection
                        rule(AppColor.hairline)
                        reviewTargetSection
                        rule(AppColor.hairline)
                        audioSection
                        rule(AppColor.hairline)
                        backupSection
                        rule(AppColor.hairline)
                    }
                    .padding(.top, 32)
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 22)
                .padding(.bottom, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .safeAreaInset(edge: .bottom) {
            Button("Fermer") { dismiss() }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(AppColor.paper.ignoresSafeArea())
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.url])
        }
    }

    // MARK: - Header

    /// motion.html `.lab` pair pinned to the top edges (01: `Réglages` sits
    /// top-right on the book — here it becomes the screen's own ink label).
    private var edgeLabels: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Réglages").uppercaseLabel(AppColor.ink)
            Spacer()
            Text("Carambole").uppercaseLabel()
        }
    }

    /// 03 `.big`: Manrope 40 / 250, −0.03em, second line in g2.
    private var heading: some View {
        // Manrope's natural line box is ~1.37em; 03 sets 1.05em → pull lines up.
        VStack(alignment: .leading, spacing: -12) {
            Text("Ton rythme")
                .foregroundColor(AppColor.ink)
            Text("d’étude.")
                .foregroundColor(AppColor.g2)
        }
        .font(.display(size: 40, wght: 250))
        .tracking(-1.2)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    // MARK: - New cards per day (hard cap)

    private var newPerDaySection: some View {
        TextStepper(
            title: "Éléments / jour",
            note: "New grammar elements per day — a hard cap.",
            value: $store.settings.newPerDay,
            range: StudySettings.newPerDayRange
        )
    }

    // MARK: - Daily review target (soft goal)

    private var reviewTargetSection: some View {
        TextStepper(
            title: "Objectif de révision",
            note: "Daily review goal — you can exceed it.",
            value: $store.settings.reviewTarget,
            range: StudySettings.reviewTargetRange,
            step: StudySettings.reviewTargetStep
        )
    }

    // MARK: - Audio (auto-play toggle)

    private var audioSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: $store.autoSpeak) {
                Text("Lecture audio automatique")
                    .font(.display(size: 17, wght: 400))
                    .tracking(-0.2)
                    .foregroundColor(AppColor.ink)
            }
            .tint(AppColor.ink)

            note("Read the sentence aloud automatically on a correct answer. The 🔊 button is always available either way.")
        }
        .padding(.vertical, 18)
    }

    // MARK: - Backup / export

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                if let url = DataManager.shared.exportSnapshot() {
                    shareItem = ShareItem(url: url)
                }
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text("Exporter ma progression")
                        .font(.display(size: 17, wght: 400))
                        .tracking(-0.2)
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Text("→")
                        .font(.display(size: 20, wght: 300))
                        .foregroundColor(AppColor.ink)
                        .accessibilityHidden(true)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            note("Save a backup of your learning progress (the SQLite file) before a risky rebuild.")
        }
        .padding(.vertical, 18)
    }

    // MARK: - Pieces

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.display(size: 13, wght: 400))
            .foregroundColor(AppColor.g2)
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func rule(_ color: Color) -> some View {
        Rectangle().fill(color).frame(height: 1)
    }
}

// MARK: - TextStepper

/// A stepper drawn as type: tracked label on top, then `−  12  +` with a big
/// light Manrope numeral (01 `.num`: 44 / 200, −0.04em). The ends grey out
/// (g3) at the range bounds. VoiceOver sees one adjustable element.
private struct TextStepper: View {
    let title: String
    let note: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var step: Int = 1

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var canDecrement: Bool { value > range.lowerBound }
    private var canIncrement: Bool { value < range.upperBound }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).uppercaseLabel(AppColor.ink)
                Spacer()
                Text("\(range.lowerBound) – \(range.upperBound)").uppercaseLabel()
            }

            HStack(alignment: .center, spacing: 0) {
                stepButton("−", enabled: canDecrement) { change(-step) }
                Text("\(value)")
                    .font(.display(size: 44, wght: 200))
                    .tracking(-1.76)
                    .monospacedDigit()
                    .foregroundColor(AppColor.ink)
                    .contentTransition(.numericText(value: Double(value)))
                    .frame(minWidth: 96)
                stepButton("+", enabled: canIncrement) { change(step) }
                Spacer(minLength: 0)
            }
            .padding(.leading, -12) // optical: align `−` glyph with the 22pt edge

            Text(note)
                .font(.display(size: 13, wght: 400))
                .foregroundColor(AppColor.g2)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 18)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue("\(value)")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: if canIncrement { change(step) }
            case .decrement: if canDecrement { change(-step) }
            @unknown default: break
            }
        }
    }

    private func stepButton(_ glyph: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(glyph)
                .font(.display(size: 30, wght: 250))
                .foregroundColor(enabled ? AppColor.ink : AppColor.g3)
                .frame(width: 44, height: 52)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func change(_ delta: Int) {
        let next = min(max(value + delta, range.lowerBound), range.upperBound)
        guard next != value else { return }
        if reduceMotion {
            value = next
        } else {
            withAnimation(.snappy(duration: 0.25)) { value = next }
        }
    }
}

/// Identifiable URL wrapper so `.sheet(item:)` can present the share sheet.
private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Thin SwiftUI bridge to `UIActivityViewController` (the system share sheet).
private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    SettingsView(store: StudySettingsStore())
}
