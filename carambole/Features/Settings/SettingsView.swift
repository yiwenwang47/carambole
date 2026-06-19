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

struct SettingsView: View {
    /// The shared settings store — NOT created here. Editing `store.settings`
    /// persists (clamped) on write via the store's `didSet`.
    @ObservedObject var store: StudySettingsStore

    @Environment(\.dismiss) private var dismiss

    /// Step granularity for the review target — moves in chunks of 20.
    private let reviewTargetStep = 20
    /// A sensible review-target band; clamps further in `StudySettings.init`.
    private let reviewTargetRange = 40...600

    var body: some View {
        ZStack {
            AppColor.paper.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    newPerDaySection
                    divider
                    reviewTargetSection

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
                    Text("Cartes / jour")
                        .font(.system(size: 18, weight: .regular, design: .serif))
                        .foregroundColor(AppColor.ink)
                    Spacer()
                    Text("\(store.settings.newPerDay)")
                        .font(.appPrompt)
                        .foregroundColor(AppColor.saffronDeep)
                }
            }
            .tint(AppColor.saffronDeep)

            Text("New cards per day — a hard cap.")
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
                in: reviewTargetRange,
                step: reviewTargetStep
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

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(AppColor.hairline)
            .frame(height: 1)
    }
}

// MARK: - Preview

#Preview {
    SettingsView(store: StudySettingsStore())
}
