import Foundation
#if canImport(AVFAudio) && os(iOS)
import AVFoundation

/// Single owner for AVAudioSession activation across the SDK's recorder and player adapters.
///
/// Saves the host app's prior session category before the SDK activates its own,
/// and restores it on `exit()`. This prevents disrupting other audio (music apps, games)
/// that may have configured the session before the chat widget was opened.
final class AudioSessionCoordinator: @unchecked Sendable {
    static let shared = AudioSessionCoordinator()

    enum Mode {
        case idle
        case recording
        case playing
    }

    private let lock = NSLock()
    private var currentMode: Mode = .idle
    private var savedCategory: AVAudioSession.Category?
    private var savedMode: AVAudioSession.Mode?
    private var savedOptions: AVAudioSession.CategoryOptions = []

    private init() {}

    /// Activate the session for recording. Saves host app settings on first entry.
    func enterRecording() throws {
        lock.lock(); defer { lock.unlock() }
        let session = AVAudioSession.sharedInstance()
        if currentMode == .idle {
            savedCategory = session.category
            savedMode = session.mode
            savedOptions = session.categoryOptions
        }
        try session.setCategory(
            .playAndRecord,
            mode: .default,
            options: [.allowBluetooth, .defaultToSpeaker]
        )
        try session.setActive(true)
        currentMode = .recording
    }

    /// Activate the session for playback. Saves host app settings on first entry.
    func enterPlaying() throws {
        lock.lock(); defer { lock.unlock() }
        let session = AVAudioSession.sharedInstance()
        if currentMode == .idle {
            savedCategory = session.category
            savedMode = session.mode
            savedOptions = session.categoryOptions
        }
        try session.setCategory(.playback, mode: .default, options: [])
        try session.setActive(true)
        currentMode = .playing
    }

    /// Restore the host app's prior session category and deactivate.
    /// Idempotent — safe to call multiple times.
    func exit() {
        lock.lock(); defer { lock.unlock() }
        guard currentMode != .idle else { return }
        let session = AVAudioSession.sharedInstance()
        if let savedCategory {
            try? session.setCategory(savedCategory, mode: savedMode ?? .default, options: savedOptions)
        }
        try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        currentMode = .idle
        savedCategory = nil
        savedMode = nil
        savedOptions = []
    }
}
#endif
