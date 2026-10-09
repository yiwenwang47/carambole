//
//  TodayView.swift
//  carambole
//
//  PLACEHOLDER for the 03 Gravité "Aujourd'hui" screen (built in parallel on
//  another branch; this file is replaced at merge). Keeps the signature the book
//  home calls: the two start buttons + `Historique →`.
//

import SwiftUI

struct TodayView: View {
    @ObservedObject var viewModel: BookViewModel
    let startLearn: () -> Void
    let startReview: () -> Void

    @Environment(\.dismiss) private var dismiss

    init(viewModel: BookViewModel, startLearn: @escaping () -> Void, startReview: @escaping () -> Void) {
        self.viewModel = viewModel
        self.startLearn = startLearn
        self.startReview = startReview
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Button { dismiss() } label: { Text("‹ Aujourd’hui").uppercaseLabel(AppColor.ink) }
                    .buttonStyle(.plain)
                Spacer()
                NavigationLink { HistoryView() } label: { Text("Historique →").uppercaseLabel() }
                    .buttonStyle(.plain)
            }
            Spacer()
            Button("Apprendre \(viewModel.newAvailableToday)", action: startLearn)
                .buttonStyle(PrimaryButtonStyle())
            Button("Réviser \(viewModel.dueCount)", action: startReview)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 16)
        .padding(.bottom, 30)
        .background(AppColor.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .swipeToGoBack { dismiss() }
    }
}
