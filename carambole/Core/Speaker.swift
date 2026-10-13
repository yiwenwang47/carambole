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
final class Speaker: NSObject, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    static let shared = Speaker()
    private let synth = AVSpeechSynthesizer()
    private var player: AVAudioPlayer?
    private override init() {
        super.init()
        synth.delegate = self
    }

    /// Speaks `text` in French. If `key` is given and a bundled `<key>.mp3` exists,
    /// plays that file; otherwise synthesizes `text` on-device. Cancels anything
    /// already in flight. No-op for an empty string.
    func speak(_ text: String, key: String? = nil, language: String = "fr-FR") {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activateSession()

        if let key, let url = Speaker.bundledAudioURL(key: key) {
            // Rapid replay restarts cleanly: the old clip stops before the new one.
            halt()
            do {
                let p = try AVAudioPlayer(contentsOf: url)
                p.delegate = self
                player = p          // hold strong so it isn't deallocated mid-playback
                p.play()
                return
            } catch {
                // Corrupt/unreadable file → fall through to the synthesizer.
            }
        }

        // Fallback: use only a female French voice. If none is installed, stay
        // silent rather than speaking with an unspecified or male voice.
        halt()
        guard let voice = AVSpeechSynthesisVoice.speechVoices()
            .filter({ $0.language == language && $0.gender == .female })
            .sorted(by: { $0.quality.rawValue > $1.quality.rawValue })
            .first else { deactivateSession(); return }
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = voice
        utterance.rate = 0.42
        synth.speak(utterance)
    }

    /// Stops any clip or synthesized speech in flight (exit, next card) and
    /// gives other apps' audio back its full volume.
    func stop() {
        halt()
        deactivateSession()
    }

    /// Stops playback but keeps the session, for a clip that replaces another.
    private func halt() {
        player?.stop()
        player = nil
        synth.stopSpeaking(at: .immediate)
    }

    /// Plays a bundled clip only; does nothing when the file is missing (no
    /// synthesized fallback). Used for *En situation* word audio, where a wrong
    /// fallback voice would teach a wrong sound.
    func playBundled(key: String) {
        guard let url = Speaker.bundledAudioURL(key: key) else { return }
        activateSession()
        halt()
        if let p = try? AVAudioPlayer(contentsOf: url) {
            p.delegate = self
            player = p
            p.play()
        } else {
            deactivateSession()
        }
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
    /// Routes speech to `.playback` so a deliberate "écouter" tap is audible
    /// even when other audio is playing; `.duckOthers` lowers background audio
    /// only while a clip plays. The session is released when the clip ends or
    /// is stopped, so music comes back to full volume.
    private func activateSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        if !sessionConfigured {
            sessionConfigured = true
            try? session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        }
        try? session.setActive(true)
        #endif
    }

    private func deactivateSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }

    // MARK: - Playback finished

    func audioPlayerDidFinishPlaying(_ finished: AVAudioPlayer, successfully flag: Bool) {
        // A replacement clip may already be playing; only the current one releases.
        guard finished === player else { return }
        player = nil
        if !synth.isSpeaking { deactivateSession() }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        if player == nil, !synthesizer.isSpeaking { deactivateSession() }
    }
}
