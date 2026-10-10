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
//  `closeSession` (full-screen drill), `nextPalette`.
//

#if DEBUG
import Foundation

enum DemoRemote {
    enum Action: String, CaseIterable {
        case openBook, closeBook, openModules, closeModules, openToday, closeToday
        case openSettings, closeSettings, startReview, closeSession, nextPalette
        var notification: Notification.Name { Notification.Name("cb.demo.\(rawValue)") }
    }

    private static var started = false

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
