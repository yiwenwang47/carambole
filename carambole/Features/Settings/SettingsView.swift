//
//  SettingsView.swift
//  carambole
//
//  "Réglages" — study pacing settings. Two editorial steppers backed by the
//  SHARED `StudySettingsStore` (single source of truth): the `newPerDay` HARD
//  cap and the `reviewTarget` SOFT goal. Writes go through the store, which
//  clamps and persists immediately.
//  Built entirely from the "Le Cahier" design system.
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
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    newPerDaySection
                    divider
                    reviewTargetSection
                    divider
                    backupSection

                    Spacer(minLength: Spacing.lg)

                    Button("Fermer") { dismiss() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal, Spacing.screenH)
                .padding(.top, 72)
                .padding(.bottom, Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(item: $shareItem) { item in
            ActivityView(activityItems: [item.url])
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionLabel("Settings")
            Text("Réglages")
                .font(.appTitle)
                .foregroundColor(AppColor.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - New cards per day (hard cap)

    private var newPerDaySection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Stepper(
                value: $store.settings.newPerDay,
                in: StudySettings.newPerDayRange
            ) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("Éléments / jour")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Text("\(store.settings.newPerDay)")
                        .font(.appPrompt)
                        .foregroundColor(AppColor.saffronDeep)
                }
            }
            .tint(AppColor.saffronDeep)

            Text("New grammar elements per day — a hard cap.")
                .font(.appExplain)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Daily review target (soft goal)

    private var reviewTargetSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Stepper(
                value: $store.settings.reviewTarget,
                in: StudySettings.reviewTargetRange,
                step: StudySettings.reviewTargetStep
            ) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("Objectif de révision")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Text("\(store.settings.reviewTarget)")
                        .font(.appPrompt)
                        .foregroundColor(AppColor.saffronDeep)
                }
            }
            .tint(AppColor.saffronDeep)

            Text("Daily review goal — you can exceed it.")
                .font(.appExplain)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Backup / export

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                if let url = DataManager.shared.exportSnapshot() {
                    shareItem = ShareItem(url: url)
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    Text("Exporter ma progression")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(AppColor.saffronDeep)
                }
            }

            Text("Save a backup of your learning progress (the SQLite file) before a risky rebuild.")
                .font(.appExplain)
                .foregroundColor(AppColor.graphite)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(AppColor.hairline)
            .frame(height: 1)
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
