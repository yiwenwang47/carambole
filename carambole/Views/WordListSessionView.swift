import SwiftUI
import Foundation

struct WordListSessionView: View {
    @StateObject private var vm: WordListSessionViewModel

    init(list: WordList) {
        _vm = StateObject(wrappedValue: WordListSessionViewModel(list: list))
    }

    var body: some View {
        VStack {
            if let currentWord = vm.currentWord {
                FlashcardView(word: Binding(
                    get: { currentWord },
                    set: { _ in }
                ), onSwipe: vm.handleSwipe, onSkip: {
                    vm.handleSwipe(.learned)
                })
                .animation(.spring(), value: vm.currentWord)
            } else {
                Text("All words mastered for this list!")
                    .font(.title)
                    .padding()
                Button("Back to Lists") {
                    vm.isSessionCompleted = true
                }
            }
        }
        .fullScreenCover(isPresented: $vm.isSessionCompleted) {
            // Dismiss to previous screen
        }
    }
}

final class WordListSessionViewModel: ObservableObject {
    @Published var remainingWords: [Word] = []
    @Published var currentWord: Word?
    @Published var learningStatus: [String: Bool] = [:]
    @Published var isSessionCompleted = false

    init(list: WordList) {
        remainingWords = list.words.shuffled()
        for word in list.words {
            learningStatus[word.id] = false
        }
        currentWord = remainingWords.first
    }

    func handleSwipe(_ state: LearningState) {
        guard let word = currentWord else { return }
        if state == .learned {
            learningStatus[word.id] = true
            remainingWords.removeAll { $0.id == word.id }
        } else {
            // Move word to end if not learned
            if let index = remainingWords.firstIndex(where: { $0.id == word.id }) {
                remainingWords.remove(at: index)
                remainingWords.append(word)
            }
        }
        if remainingWords.isEmpty {
            isSessionCompleted = true
        } else {
            currentWord = remainingWords.first
        }
    }
}