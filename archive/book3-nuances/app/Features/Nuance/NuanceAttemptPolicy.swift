import Foundation

/// The card's two-attempt answer rule, independent of SwiftUI and persistence.
enum NuanceAttemptPolicy {
    enum Outcome: Equatable { case good, hard, again }
    enum Mismatch: Equatable { case retry, reviewParaphrase, again }

    static func exactOutcome(priorMisses: Int) -> Outcome {
        priorMisses == 0 ? .good : .hard
    }

    static func mismatch(priorMisses: Int, typed: Bool) -> Mismatch {
        if typed { return .reviewParaphrase }
        return priorMisses == 0 ? .retry : .again
    }

    static func canArmTooEasy(priorMisses: Int) -> Bool {
        priorMisses == 0
    }

    static func presentationKey(cardID: String, times: Int) -> String {
        "\(cardID)#\(times)"
    }
}
