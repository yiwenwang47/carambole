//
//  StudySessionView.swift
//  carambole
//
//  Picks the drill loop for the selected book: *Fondations* drills example
//  sentences (`DrillSessionView`), *En situation* drills dialogues
//  (`SituationSessionView`). Every session entry point (book home, module list,
//  module page) goes through here, so the book's own settings store and
//  content always reach the session.
//

import SwiftUI

struct StudySessionView: View {
    @ObservedObject var viewModel: BookViewModel
    let title: String
    let ruleNote: String
    let elements: [GrammarElement]
    let mode: SessionMode
    var moduleNumber: Int? = nil
    var module: CourseModule? = nil
    var canStart: Bool = true
    let onFinish: () -> Void

    var body: some View {
        switch viewModel.book.kind {
        case .grammar:
            DrillSessionView(title: title, ruleNote: ruleNote, elements: elements, mode: mode,
                             moduleNumber: moduleNumber, module: module, viewModel: viewModel,
                             canStart: canStart, autoSpeak: viewModel.settingsStore.autoSpeak,
                             onFinish: onFinish)
        case .situation:
            SituationSessionView(book: viewModel.book, title: title, ruleNote: ruleNote,
                                 elements: elements, mode: mode, module: module, canStart: canStart,
                                 autoSpeak: viewModel.settingsStore.autoSpeak, onFinish: onFinish)
        }
    }
}
