import Foundation
import Network
import Combine

/// Monitors device network connectivity via NWPathMonitor.
/// Publishes `isOnline` as a Combine subject.
final class NetworkMonitor: @unchecked Sendable {

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ai.teammates.rayachat.network")

    private let _isOnline = CurrentValueSubject<Bool, Never>(true)
    var isOnline: AnyPublisher<Bool, Never> { _isOnline.eraseToAnyPublisher() }
    var isOnlineValue: Bool { _isOnline.value }

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let online = path.status == .satisfied
            self?._isOnline.send(online)
        }
        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
    }
}
