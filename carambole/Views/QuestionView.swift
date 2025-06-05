import SwiftUI
import Foundation

struct QuestionView: View {
    @Binding var question: QuestionItem
    var onAnswer: (Bool) -> Void

    @State private var selectedOption: String?
    @State private var isAnswered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(question.prompt ?? "")
                .font(.title2)
                .padding(.bottom)

            ForEach(question.options ?? [], id: \.self) { option in
                Button(action: {
                    guard !isAnswered else { return }
                    selectedOption = option
                    isAnswered = true
                    let isCorrect = (option == question.correctAnswer)
                    onAnswer(isCorrect)
                }) {
                    HStack {
                        Text(option)
                            .foregroundColor(.primary)
                        if isAnswered && option == question.correctAnswer {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if isAnswered && option == selectedOption {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isAnswered
                                ? (option == question.correctAnswer ? Color.green : (option == selectedOption ? Color.red : Color.gray))
                                : Color.blue,
                                lineWidth: 2
                            )
                    )
                }
                .disabled(isAnswered)
            }
        }
        .padding()
    }
}

struct QuestionSessionView: View {
    @StateObject private var vm: QuestionSessionViewModel

    init(wordIDs: [String]) {
        _vm = StateObject(wrappedValue: QuestionSessionViewModel(wordIDs: wordIDs))
    }

    var body: some View {
        VStack {
            if let question = vm.currentQuestion {
                QuestionView(question: Binding(
                    get: { question },
                    set: { _ in }
                ), onAnswer: vm.handleAnswer)
                .animation(.easeInOut, value: vm.currentIndex)
                Text("\(vm.currentIndex + 1)/\(vm.totalQuestions) Questions")
                    .font(.footnote)
                    .padding()
            } else {
                Text("Quiz Complete! Score: \(vm.correctCount)/\(vm.totalQuestions)")
                    .font(.title2)
                    .padding()
                Button("Back to Home") {
                    vm.isSessionCompleted = true
                }
            }
        }
        .fullScreenCover(isPresented: $vm.isSessionCompleted) {
            // Dismiss to HomeView
        }
    }
}

final class QuestionSessionViewModel: ObservableObject {
    @Published var questions: [QuestionItem] = []
    @Published var currentIndex: Int = 0
    @Published var isSessionCompleted = false
    @Published var correctCount = 0

    var totalQuestions: Int { questions.count }
    var currentQuestion: QuestionItem? {
        guard currentIndex < questions.count else { return nil }
        return questions[currentIndex]
    }

    init(wordIDs: [String]) {
        // Fetch all questions for given wordIDs
        questions = DataManager.shared.fetchQuestions(for: wordIDs)
        questions.shuffle()
    }

    func handleAnswer(_ isCorrect: Bool) {
        if isCorrect { correctCount += 1 }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) {
            self.currentIndex += 1
            if self.currentIndex >= self.questions.count {
                self.isSessionCompleted = true
            }
        }
    }
}