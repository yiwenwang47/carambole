import AVFoundation

/// Reads French model sentences aloud. Prefers the pre-generated, high-quality
/// Google Neural2 audio bundled with the app (`<audioKey>.mp3`); falls back to the
/// on-device `AVSpeechSynthesizer` for any sentence without a bundled file (offline
/// safety net — e.g. content added after the last audio batch).
///
/// A singleton so playback keeps going across a view transition (e.g. the
/// auto-advance that follows a correct answer) instead of being cut off when the
/// `DrillView` is torn down. The `AVAudioPlayer` is held strongly here for the same
/// reason — a local player would be deallocated mid-sentence.
final class Speaker {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private init() {}

    /// Speaks `text` in French. If `key` is given and a bundled `<key>.mp3` exists,
    /// plays that file; otherwise synthesizes `text` on-device. Cancels anything
    /// already in flight. No-op for an empty string.
    func speak(_ text: String, key: String? = nil, language: String = "fr-FR") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        configureSessionIfNeeded()

        if let key, let url = Speaker.bundledAudioURL(key: key) {
            synth.stopSpeaking(at: .immediate)
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                player = p          // hold strong so it isn't deallocated mid-playback
                p.play()
                return
            } catch {
                // Corrupt/unreadable file → fall through to the synthesizer.
            }
        }

        // Fallback: on-device synthesizer. Rate a touch under default so learners follow.
        player?.stop()
        synth.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = 0.42
        synth.speak(utterance)
    }

    /// Locates a bundled audio file. Xcode 16's `PBXFileSystemSynchronizedRootGroup`
    /// flattens `Resources/Audio/*` to the bundle root at build time, so try the root
    /// first, then the `Audio/` subdirectory as a fallback. Filenames are unique
    /// content hashes, so either layout resolves correctly.
    static func bundledAudioURL(key: String) -> URL? {
        Bundle.main.url(forResource: key, withExtension: "mp3")
            ?? Bundle.main.url(forResource: key, withExtension: "mp3", subdirectory: "Audio")
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
