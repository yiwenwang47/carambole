//
//  DemoRemote.swift
//  carambole
//
//  DEBUG only. Simulator taps cannot be automated here, so visual checks drive
//  navigation with Darwin notifications from the host:
//
//      xcrun simctl spawn <sim> notifyutil -p cb.demo.openBook
//
//  Actions: `openBook` / `closeBook` (library ⇄ book), `openModules` /
//  `closeModules` and `openToday` / `closeToday` (push / pop a page over the
//  book), `openSettings` / `closeSettings` (sheet), `startReview` /
//  `closeSession` (full-screen drill), `nextPalette`, `openSituationBook`
//  (push *En situation*), `startLearn` (Apprendre on the open book),
//  `openHistory` / `closeHistory` (push / pop History over Aujourd'hui).
//

#if DEBUG
import Foundation

enum DemoRemote {
    enum Action: String, CaseIterable {
        case openBook, closeBook, openModules, closeModules, openToday, closeToday
        case openSettings, closeSettings, startReview, closeSession, nextPalette
        /// Book 2: push *En situation* from the shelf; start an Apprendre session.
        case openSituationBook, startLearn
        /// Push / pop History over Aujourd'hui (`openToday` first).
        case openHistory, closeHistory
        var notification: Notification.Name { Notification.Name("cb.demo.\(rawValue)") }
    }

    private static var started = false
    private static var launchStartTaken = false

    /// Launch flags `CB_OPEN_BOOK=<book id>` (push that book from the shelf) and
    /// `CB_START=learn|review` (open a session once it has loaded). True once,
    /// for the book that `CB_OPEN_BOOK` names (default *Fondations*).
    static func takeLaunchStart(bookID: String) -> Bool {
        let env = ProcessInfo.processInfo.environment
        guard env["CB_START"] != nil, !launchStartTaken,
              (env["CB_OPEN_BOOK"] ?? BookCatalog.fondations.id) == bookID else { return false }
        launchStartTaken = true
        return true
    }

    /// Forwards each Darwin notification to the in-process `NotificationCenter`
    /// on the main queue, where the views listen.
    static func start() {
        guard !started else { return }
        started = true
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        for action in Action.allCases {
            CFNotificationCenterAddObserver(center, nil, { _, _, name, _, _ in
                guard let raw = name?.rawValue as String? else { return }
                DispatchQueue.main.async {
                    if raw == Action.nextPalette.notification.rawValue {
                        let all = AppPalette.allCases
                        let current = AppPalette(stored: UserDefaults.standard.string(forKey: AppPalette.storageKey)
                                                 ?? AppPalette.fallback.rawValue)
                        let next = all[((all.firstIndex(of: current) ?? 0) + 1) % all.count]
                        UserDefaults.standard.set(next.rawValue, forKey: AppPalette.storageKey)
                    }
                    NotificationCenter.default.post(name: Notification.Name(raw), object: nil)
                }
            }, action.notification.rawValue as CFString, nil, .deliverImmediately)
        }
    }
}
#endif
