import Foundation

/// Pure, deterministic FSRS-6 memory-strength core.
///
/// FSRS (Free Spaced Repetition Scheduler) models each element's memory as two
/// numbers — **stability** `S` (days; the interval at which predicted recall has
/// decayed to the desired-retention sweet spot) and **difficulty** `D` (1–10; how
/// hard the item is to retain). A binary drill outcome maps to an FSRS rating
/// (see the design doc) and `next(_:elapsedDays:rating:)` advances `(S, D)`.
///
/// This type is the T1 algorithm core ONLY: no persistence, no UI, and — crucially
/// for determinism — **no `Date()` / `Calendar.current` anywhere**. All time enters
/// as `elapsedDays: Double` (the day-gap since the last review), so the same inputs
/// always yield the same state. Later tasks (T2–T5) wire it into `DataManager`,
/// grading, and the bar; they live elsewhere.
///
/// ## Algorithm source (anchored, NOT transcribed from memory)
/// Formulas + the default 21-weight vector are ported from the canonical reference
/// implementation **`open-spaced-repetition/py-fsrs` v6.3.1** (`fsrs/scheduler.py`,
/// the published FSRS-6 algorithm). Every formula below was cross-checked
/// numerically against that library's private methods over a `(S, D, t, rating)`
/// grid — **max abs difference 0.0**. The reference values asserted in `_selfTest()`
/// were computed from the same library. See that test for the exact anchors.
///
/// Conventions carried over verbatim from py-fsrs:
/// - `DECAY = -w[20]` (a NEGATIVE exponent); `FACTOR = 0.9^(1/DECAY) − 1`. Chosen so
///   the forgetting curve passes through `R(S, S) = 0.90` for any `S`.
/// - Ratings are 1…4 = Again / Hard / Good / Easy.
/// - Stability is clamped to `≥ stabilityMin`; difficulty to `[1, 10]`.
/// - Intervals/fuzz are NOT part of this core (the app computes its own review
///   timing from `intervalDays`); `next()` returns only the updated `(S, D)`.
enum FSRS {

    // MARK: Ratings

    /// FSRS rating (1–4). Carambole maps a drill outcome onto these: wrong →
    /// `.again`, right after a second try or a missed tap → `.hard`, right first
    /// time → `.good`, "Trop facile" + correct → `.easy`.
    enum Rating: Int {
        case again = 1
        case hard  = 2
        case good  = 3
        case easy  = 4
    }

    // MARK: State

    /// Per-element memory state. `stability` in days, `difficulty` in 1–10.
    struct State: Equatable {
        var stability: Double
        var difficulty: Double
    }

    // MARK: Default parameters (FSRS-6, py-fsrs v6.3.1 `DEFAULT_PARAMETERS`)

    /// Published FSRS-6 default weight vector (21 weights). Ships pre-tuned so the
    /// model works on day one with zero per-user training. `defaultParams[20]` is the
    /// trainable forgetting-curve decay (here the FSRS_DEFAULT_DECAY 0.1542).
    static let defaultParams: [Double] = [
        0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001,
        1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014,
        1.8729, 0.5425, 0.0912, 0.0658, 0.1542,
    ]

    // MARK: Derived curve constants

    /// `DECAY = -w[20]` — the power-forgetting-curve exponent (negative).
    static let decay: Double = -defaultParams[20]
    /// `FACTOR = 0.9^(1/DECAY) − 1`. Makes `R(S, S) == 0.90` for any stability.
    static let factor: Double = pow(0.9, 1.0 / decay) - 1.0

    /// Floor for stability (mirrors py-fsrs `STABILITY_MIN`); never let `S` hit 0.
    static let stabilityMin: Double = 0.001
    private static let minDifficulty: Double = 1.0
    private static let maxDifficulty: Double = 10.0

    // MARK: Tunable constants (consumed by later tasks — see the design doc)

    /// Review an element when predicted recall `R(now)` decays to this. FSRS computes
    /// the interval from `S` so that `R == desiredRetention` at the due date.
    static let desiredRetention: Double = 0.90
    /// Stability bar (days) for sticky "maîtrisé": an element graduates once a
    /// successful review pushes `S` past this. ~3 weeks of survived spacing.
    static let graduationStability: Double = 21.0
    /// A graduated element whose `R(now)` drops below this is flagged "fragile".
    static let fragileRecall: Double = 0.80
    /// Stability (days) a demoted element is knocked down to ("remettre en cours").
    /// Comfortably below `graduationStability`, so an un-graduated element genuinely
    /// lands in en-cours and must re-earn graduation across spaced reviews. Capped by
    /// the element's current `S` (never raise it) and floored at `stabilityMin`.
    static let relearnStability: Double = 7.0

    // MARK: Forgetting curve & interval

    /// FSRS-6 power forgetting curve: predicted probability of recall after
    /// `elapsedDays` with the given `stability`.
    /// `R(t, S) = (1 + FACTOR · t/S)^DECAY` ∈ (0, 1]; `R(0,S)=1`, `R(S,S)=0.9`,
    /// monotonically decreasing in `t`.
    static func retrievability(stability: Double, elapsedDays: Double) -> Double {
        let s = max(stability, stabilityMin)
        let t = max(0.0, elapsedDays)
        return pow(1.0 + factor * t / s, decay)
    }

    /// Inverse of `retrievability` in `t`: the interval (days) at which predicted
    /// recall equals `desiredRetention`.
    /// `I(R, S) = (S / FACTOR) · (R^(1/DECAY) − 1)`. With `R = 0.90` this returns `S`.
    static func intervalDays(stability: Double, desiredRetention: Double = FSRS.desiredRetention) -> Double {
        let s = max(stability, stabilityMin)
        return (s / factor) * (pow(desiredRetention, 1.0 / decay) - 1.0)
    }

    // MARK: First review (no prior state)

    /// Seed `(S, D)` for an element's first-ever review.
    /// Initial stability `S₀(G) = w[G−1]` (clamped ≥ `stabilityMin`).
    /// Initial difficulty `D₀(G) = w[4] − e^(w[5]·(G−1)) + 1` (clamped `[1,10]`).
    static func initialState(rating: Rating) -> State {
        State(stability: initialStability(rating: rating),
                  difficulty: initialDifficulty(rating: rating, clamp: true))
    }

    // MARK: Subsequent review

    /// Advance `(S, D)` for a review of an element that already has state, given the
    /// `elapsedDays` gap since its last review and the `rating`.
    /// - `again` → stability collapses (lapse path); difficulty drifts up.
    /// - `hard`/`good`/`easy` → stability grows (more on a longer well-timed gap,
    ///   i.e. lower recall at review time); `easy` largest, `hard` smallest.
    /// - difficulty drifts up on `again`, down on `easy`, with mean-reversion toward
    ///   the easy baseline.
    static func next(_ state: State, elapsedDays: Double, rating: Rating) -> State {
        let r = retrievability(stability: state.stability, elapsedDays: elapsedDays)
        let newStability: Double
        if rating == .again {
            newStability = nextForgetStability(difficulty: state.difficulty,
                                               stability: state.stability,
                                               retrievability: r)
        } else {
            newStability = nextRecallStability(difficulty: state.difficulty,
                                               stability: state.stability,
                                               retrievability: r,
                                               rating: rating)
        }
        return State(stability: clampStability(newStability),
                         difficulty: nextDifficulty(difficulty: state.difficulty, rating: rating))
    }

    // MARK: - Private formula pieces (1:1 with py-fsrs v6.3.1)

    private static func w(_ i: Int) -> Double { defaultParams[i] }

    private static func clampStability(_ s: Double) -> Double { max(s, stabilityMin) }
    private static func clampDifficulty(_ d: Double) -> Double { min(max(d, minDifficulty), maxDifficulty) }

    private static func initialStability(rating: Rating) -> Double {
        clampStability(w(rating.rawValue - 1))
    }

    /// `D₀(G) = w[4] − e^(w[5]·(G−1)) + 1`. `clamp:false` is used to compute the
    /// mean-reversion anchor `D₀(Easy)` exactly as py-fsrs does.
    private static func initialDifficulty(rating: Rating, clamp: Bool) -> Double {
        let d = w(4) - exp(w(5) * (Double(rating.rawValue) - 1.0)) + 1.0
        return clamp ? clampDifficulty(d) : d
    }

    /// Difficulty update: linear-damping step then mean-reversion to `D₀(Easy)`.
    /// `ΔD = −w[6]·(G−3)`; `D' = D + (10−D)·ΔD/9`; `D'' = w[7]·D₀(4) + (1−w[7])·D'`.
    private static func nextDifficulty(difficulty d: Double, rating: Rating) -> Double {
        let deltaD = -(w(6) * (Double(rating.rawValue) - 3.0))
        let damped = d + (10.0 - d) * deltaD / 9.0            // linear damping
        let anchor = initialDifficulty(rating: .easy, clamp: false)
        let reverted = w(7) * anchor + (1.0 - w(7)) * damped  // mean reversion
        return clampDifficulty(reverted)
    }

    /// Stability after a successful recall (`hard`/`good`/`easy`).
    /// `S' = S · (1 + e^w[8]·(11−D)·S^(−w[9])·(e^((1−R)·w[10]) − 1)·hard·easy)`.
    private static func nextRecallStability(difficulty d: Double, stability s: Double,
                                            retrievability r: Double, rating: Rating) -> Double {
        let hardPenalty = (rating == .hard) ? w(15) : 1.0
        let easyBonus   = (rating == .easy) ? w(16) : 1.0
        let increase = exp(w(8))
            * (11.0 - d)
            * pow(s, -w(9))
            * (exp((1.0 - r) * w(10)) - 1.0)
            * hardPenalty
            * easyBonus
        return s * (1.0 + increase)
    }

    /// Stability after a lapse (`again`). The long-term estimate, capped by the
    /// short-term term so a same-day miss can't inflate stability.
    /// `S'_long = w[11]·D^(−w[12])·((S+1)^w[13] − 1)·e^((1−R)·w[14])`,
    /// `S'_short = S / e^(w[17]·w[18])`, `S'_f = min(S'_long, S'_short)`.
    private static func nextForgetStability(difficulty d: Double, stability s: Double,
                                            retrievability r: Double) -> Double {
        let longTerm = w(11)
            * pow(d, -w(12))
            * (pow(s + 1.0, w(13)) - 1.0)
            * exp((1.0 - r) * w(14))
        let shortTerm = s / exp(w(17) * w(18))
        return min(longTerm, shortTerm)
    }
}

// MARK: - Self-test
//
// Reference values anchored to `open-spaced-repetition/py-fsrs` v6.3.1 with the
// FSRS-6 `DEFAULT_PARAMETERS` (the vector above). Every numeric constant below was
// produced by that library / its formulas and the whole Swift port was verified to
// match its private `_next_stability` / `_next_difficulty` over a grid (diff 0.0).
// Tolerance `eps` absorbs only floating-point rounding, not algorithmic slack.

#if DEBUG
extension FSRS {
    static func _selfTest() {
        let eps = 1e-4
        func close(_ a: Double, _ b: Double, _ msg: String) {
            assert(abs(a - b) < eps, "\(msg): got \(a), expected \(b)")
        }

        // --- Curve constants (py-fsrs: DECAY = -w20, FACTOR = 0.9^(1/DECAY)-1) ---
        close(decay, -0.1542, "decay = -w20")
        close(factor, 0.9803464944134797, "factor")

        // --- Forgetting curve: R(0,S)=1, R(S,S)=0.9 (any S), decreasing, in (0,1] ---
        close(retrievability(stability: 10, elapsedDays: 0), 1.0, "R(0,S)=1")
        close(retrievability(stability: 10, elapsedDays: 10), 0.9, "R(S,S)=0.9 (S=10)")
        close(retrievability(stability: 42, elapsedDays: 42), 0.9, "R(S,S)=0.9 (S=42)")
        close(retrievability(stability: 10, elapsedDays: 5),  0.9403442888929227, "R(5,10)")
        close(retrievability(stability: 10, elapsedDays: 20), 0.8458846451494336, "R(20,10)")
        let rNear = retrievability(stability: 10, elapsedDays: 1)
        let rFar  = retrievability(stability: 10, elapsedDays: 40)
        assert(rFar < rNear, "R decreases as elapsed grows")
        assert(rNear <= 1.0 && rFar > 0.0, "R in (0,1]")

        // --- Interval is the inverse of retrievability at the desired retention ---
        // intervalDays(S, 0.90) == S exactly; round-trips back to 0.90.
        close(intervalDays(stability: 10), 10.0, "interval(S=10, 0.90)=10")
        close(intervalDays(stability: 21), 21.0, "interval(S=21, 0.90)=21")
        let s0 = 17.3
        let iv = intervalDays(stability: s0) // R should be ~0.90 at this t
        close(retrievability(stability: s0, elapsedDays: iv), desiredRetention, "interval inverts retrievability")
        // Lower desired retention → longer interval (py-fsrs reference value).
        close(intervalDays(stability: 10, desiredRetention: 0.8), 33.159597862309816, "interval(S=10,0.80)")
        assert(intervalDays(stability: 10, desiredRetention: 0.8) > intervalDays(stability: 10), "lower R → longer interval")

        // --- Initial state per rating (S0=w[G-1]; D0=w4-e^(w5*(G-1))+1, clamped) ---
        close(initialState(rating: .again).stability, 0.212,  "S0 again")
        close(initialState(rating: .hard ).stability, 1.2931, "S0 hard")
        close(initialState(rating: .good ).stability, 2.3065, "S0 good")
        close(initialState(rating: .easy ).stability, 8.2956, "S0 easy")
        close(initialState(rating: .again).difficulty, 6.4133,            "D0 again")
        close(initialState(rating: .good ).difficulty, 2.118103970459016, "D0 good")
        close(initialState(rating: .easy ).difficulty, 1.0,               "D0 easy (clamped to 1)")
        // S0 monotonic in rating; D0 decreasing in rating.
        let s0s = [Rating.again, .hard, .good, .easy].map { initialState(rating: $0).stability }
        assert(s0s[0] < s0s[1] && s0s[1] < s0s[2] && s0s[2] < s0s[3], "S0 increases again<hard<good<easy")
        let d0s = [Rating.again, .good, .easy].map { initialState(rating: $0).difficulty }
        assert(d0s[0] > d0s[1] && d0s[1] > d0s[2], "D0 decreases again>good>easy")

        // --- A known multi-review trajectory (values from py-fsrs reference) ---
        // Start: first Good → S=2.3065, D=2.118104.
        var st = initialState(rating: .good)
        close(st.stability, 2.3065, "traj S after initial Good")
        close(st.difficulty, 2.118103970459016, "traj D after initial Good")
        // +3 days, Good.
        st = next(st, elapsedDays: 3, rating: .good)
        close(st.stability, 13.826904, "traj S after +3d Good")
        close(st.difficulty, 2.111214, "traj D after +3d Good")
        // +8 days, Good.
        st = next(st, elapsedDays: 8, rating: .good)
        close(st.stability, 42.062960, "traj S after +8d Good")
        close(st.difficulty, 2.104331, "traj D after +8d Good")
        // +5 days, Again (lapse) → stability collapses, difficulty jumps up.
        let beforeMiss = st
        st = next(st, elapsedDays: 5, rating: .again)
        close(st.stability, 2.461312, "traj S after +5d Again")
        close(st.difficulty, 7.389976, "traj D after +5d Again")
        assert(st.stability < beforeMiss.stability, "Again collapses stability")
        assert(st.difficulty > beforeMiss.difficulty, "Again raises difficulty")

        // --- Monotonicity / sanity at a fixed pre-state (S=2.3065, D=D0(good)) ---
        let base = State(stability: 2.3065, difficulty: initialDifficulty(rating: .good, clamp: true))
        let again = next(base, elapsedDays: 1, rating: .again)
        let good  = next(base, elapsedDays: 1, rating: .good)
        let easy  = next(base, elapsedDays: 1, rating: .easy)
        assert(again.stability < good.stability, "again lowers S vs good")
        assert(good.stability < easy.stability,  "good < easy stability")
        assert(again.difficulty > good.difficulty, "again raises D vs good")
        assert(easy.difficulty <= good.difficulty, "easy does not raise D vs good")
        close(again.stability, 0.571299, "again S reference")
        close(good.stability,  7.315301, "good S reference")
        close(easy.stability, 11.687483, "easy S reference")

        // --- A longer well-timed gap yields larger post-review stability (success) ---
        let bigS = State(stability: 10, difficulty: 5)
        let shortGap = next(bigS, elapsedDays: 1, rating: .good)
        let longGap  = next(bigS, elapsedDays: 9, rating: .good)
        assert(longGap.stability > shortGap.stability, "longer well-timed gap → larger post-review S")
        close(shortGap.stability, 13.047176, "good gap=1 S reference")
        close(longGap.stability,  30.410352, "good gap=9 S reference")

        // --- Same-session massing can't graduate: repeated same-day (gap 0) Good
        //     keeps S well below the 21-day bar (kills accidental massing). ---
        var massed = initialState(rating: .good)
        massed = next(massed, elapsedDays: 0, rating: .good)
        massed = next(massed, elapsedDays: 0, rating: .good)
        assert(massed.stability < graduationStability, "3 same-day Goods stay below graduation bar")
    }
}
#endif
