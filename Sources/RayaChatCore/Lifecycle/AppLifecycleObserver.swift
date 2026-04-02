import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Observes app foreground/background transitions.
/// Heartbeat stops on background, restarts on foreground.
final class AppLifecycleObserver: @unchecked Sendable {

    var onForeground: ((TimeInterval) -> Void)?
    var onBackground: (() -> Void)?

    private var backgroundedAt: Date?
    private var isObserving = false

    func start() {
        guard !isObserving else { return }
        isObserving = true

        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        #endif
    }

    func stop() {
        isObserving = false
        NotificationCenter.default.removeObserver(self)
    }

    #if canImport(UIKit)
    @objc private func didBecomeActive() {
        let duration: TimeInterval
        if let bg = backgroundedAt {
            duration = Date().timeIntervalSince(bg)
        } else {
            duration = 0
        }
        backgroundedAt = nil
        onForeground?(duration)
    }

    @objc private func willResignActive() {
        backgroundedAt = Date()
        onBackground?()
    }
    #endif
}
