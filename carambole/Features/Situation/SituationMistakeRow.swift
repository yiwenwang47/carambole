//
//  SituationMistakeRow.swift
//  carambole
//
//  One wrong attempt in *En situation*: the drill's name, what the learner
//  gave and the right answer, then (unless compact) the reason. Shared by the
//  finished dialogue ("Vos erreurs"), the session summary and the book's
//  History page, so a mistake reads the same everywhere.
//

import SwiftUI

struct SituationMistakeRow: View {
    /// Drill name as shown ("Corriger", or a standalone label).
    let title: String
    let given: String
    let expected: String
    let why: String?
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            (Text(title.uppercased() + "  ").font(.label(size: 11)).foregroundColor(AppColor.g2)
             + Text("Vous : " + given).font(.display(size: 14, wght: 400)).foregroundColor(AppColor.graphite)
             + Text("  →  " + expected).font(.display(size: 14, wght: 500)).foregroundColor(AppColor.ink))
            if !compact, let why, !why.isEmpty {
                Text(why).font(.display(size: 13, wght: 400)).foregroundColor(AppColor.graphite)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        var parts = ["\(title). Vous : \(given). Réponse : \(expected)."]
        if !compact, let why, !why.isEmpty { parts.append(why) }
        return parts.joined(separator: " ")
    }
}
