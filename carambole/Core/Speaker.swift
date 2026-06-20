import AVFoundation

/// Reads French model sentences aloud with the on-device `AVSpeechSynthesizer` —
/// free, offline, no API key, no network. A singleton so speech keeps playing
/// across a view transition (e.g. the auto-advance that follows a correct answer)
/// instead of being cut off when the `DrillView` is torn down.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    private init() {}

    /// Speaks `text` in French, cancelling anything already in flight. No-op for an
    /// empty string. Rate is a touch under the default so learners can follow.
    func speak(_ text: String, language: String = "fr-FR") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        configureSessionIfNeeded()
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.42
        synth.speak(utterance)
    }

    private var sessionConfigured = false
    /// Routes speech to `.playback` (once, lazily) so a deliberate "écouter" tap is
    /// audible even when other audio is playing; `.duckOthers` lowers background
    /// audio while the sentence is spoken rather than stopping it.
    private func configureSessionIfNeeded() {
        guard !sessionConfigured else { return }
        sessionConfigured = true
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? session.setActive(true)
        #endif
    }
}
