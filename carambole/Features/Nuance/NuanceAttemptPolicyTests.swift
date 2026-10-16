#if NUANCE_RULE_TESTS
import Foundation

@main
struct NuanceAttemptPolicyTests {
    static func main() {
        precondition(NuanceAttemptPolicy.exactOutcome(priorMisses: 0) == .good)
        precondition(NuanceAttemptPolicy.exactOutcome(priorMisses: 1) == .hard)
        precondition(NuanceAttemptPolicy.mismatch(priorMisses: 0, typed: false) == .retry)
        precondition(NuanceAttemptPolicy.mismatch(priorMisses: 1, typed: false) == .again)
        precondition(NuanceAttemptPolicy.mismatch(priorMisses: 0, typed: true) == .reviewParaphrase)
        precondition(NuanceAttemptPolicy.mismatch(priorMisses: 1, typed: true) == .reviewParaphrase)
        precondition(NuanceAttemptPolicy.canArmTooEasy(priorMisses: 0))
        precondition(!NuanceAttemptPolicy.canArmTooEasy(priorMisses: 1))
        precondition(NuanceAttemptPolicy.presentationKey(cardID: "b3_01_a", times: 0)
                     != NuanceAttemptPolicy.presentationKey(cardID: "b3_01_a", times: 1))
        print("Nuance attempt policy passed")
    }
}
#endif
