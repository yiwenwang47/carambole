import AVFoundation

/// DEBUG-only audio session log for phone-only bugs (other apps' music paused,
/// skipped or not ducked around a clip — the simulator does not arbitrate
/// audio between apps). Appends one line per session step to
/// `Documents/audio_diag.txt`; pull it from the phone with
/// `xcrun devicectl device copy from --domain-type appDataContainer
///  --domain-identifier wen.carambole --source Documents/audio_diag.txt …`.
/// Release builds compile every call to nothing.
enum AudioDiag {
    #if DEBUG
    private static let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("audio_diag.txt")
    private static let queue = DispatchQueue(label: "cb.audiodiag")
    private static var observing = false
    private static let stamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
    #endif

    /// One line: the step, then the session as it is now.
    static func log(_ step: String) {
        #if DEBUG
        let s = AVAudioSession.sharedInstance()
        let line = "\(stamp.string(from: Date())) \(step) | cat=\(s.category.rawValue.replacingOccurrences(of: "AVAudioSessionCategory", with: "")) "
            + "mode=\(s.mode.rawValue.replacingOccurrences(of: "AVAudioSessionMode", with: "")) opts=\(s.categoryOptions.rawValue) "
            + "otherPlaying=\(s.isOtherAudioPlaying) silenceHint=\(s.secondaryAudioShouldBeSilencedHint)\n"
        queue.async {
            if let h = try? FileHandle(forWritingTo: url) {
                h.seekToEndOfFile()
                h.write(Data(line.utf8))
                try? h.close()
            } else {
                try? Data(line.utf8).write(to: url)
            }
        }
        #endif
    }

    /// A step that can throw: logs success or the error code.
    static func attempt(_ step: String, _ body: () throws -> Void) {
        do {
            try body()
            log(step + " ok")
        } catch {
            log(step + " ERR \((error as NSError).code)")
        }
    }

    /// Logs what iOS tells the app: interruptions, the "other app's audio
    /// started/stopped" hint, route changes. Called once at launch.
    static func startObserving() {
        #if DEBUG
        guard !observing else { return }
        observing = true
        let nc = NotificationCenter.default
        nc.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { n in
            let type = n.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let opts = n.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt
            log("NOTE interruption type=\(type.map(String.init) ?? "-") opts=\(opts.map(String.init) ?? "-")")
        }
        nc.addObserver(forName: AVAudioSession.silenceSecondaryAudioHintNotification, object: nil, queue: .main) { n in
            let type = n.userInfo?[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt
            log("NOTE silenceHint type=\(type.map(String.init) ?? "-")")
        }
        nc.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { n in
            let reason = n.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            log("NOTE routeChange reason=\(reason.map(String.init) ?? "-")")
        }
        log("---- launch")
        #endif
    }
}
