import Foundation
import RayaChatCore
#if canImport(AVFAudio) && os(iOS)
import AVFoundation
import UIKit

/// Errors surfaced by `DefaultAudioRecorderAdapter`.
public enum AudioRecorderError: LocalizedError, Sendable {
    case missingMicrophoneUsageDescription
    case permissionDenied
    case sessionActivationFailed(Error)
    case recordingStartFailed
    case recordingNotActive
    case fileTooSmall
    case fileTooLarge
    case fileReadFailed

    public var errorDescription: String? {
        switch self {
        case .missingMicrophoneUsageDescription:
            return "NSMicrophoneUsageDescription is missing from Info.plist."
        case .permissionDenied:
            return "Microphone permission was denied."
        case .sessionActivationFailed:
            return "Failed to activate the audio session."
        case .recordingStartFailed:
            return "Audio recording could not start."
        case .recordingNotActive:
            return "No active recording to stop."
        case .fileTooSmall:
            return "Recording was too short or empty."
        case .fileTooLarge:
            return "Recording exceeded the maximum allowed size."
        case .fileReadFailed:
            return "Failed to read the recorded audio file."
        }
    }
}

/// Built-in audio recorder using AVAudioRecorder.
///
/// Records 44.1 kHz mono AAC into an M4A container at ~64 kbps. Returns a data
/// URI (`data:audio/mp4;base64,...`) sized for direct WebSocket forwarding.
///
/// **Info.plist requirement:** the host app must declare `NSMicrophoneUsageDescription`.
/// Use `makeIfAvailable()` to construct safely — it returns nil when the key is
/// absent, and the SDK auto-hides the mic button so no crash occurs.
///
/// Behavior notes:
/// - Permission flow uses `AVAudioApplication` on iOS 17+, falls back to `AVAudioSession.requestRecordPermission` otherwise.
/// - Auto-stops at `Constants.maxAudioDurationSeconds` (5 min).
/// - Phone-call / Siri interruptions pause the recording; user must explicitly tap pause/resume to continue (matches the planned UX).
/// - Coordinates the audio session via `AudioSessionCoordinator`, restoring the host app's prior category on cleanup.
public final class DefaultAudioRecorderAdapter: NSObject, AudioRecorderAdapter, @unchecked Sendable {

    /// Constructs an adapter only if the host app has declared `NSMicrophoneUsageDescription`.
    /// Returns nil otherwise — the packaged UI uses this to keep the mic button hidden,
    /// preventing iOS hard-crash on first record attempt.
    public static func makeIfAvailable() -> DefaultAudioRecorderAdapter? {
        guard let description = Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String,
              !description.isEmpty else {
            print("[RayaChat] NSMicrophoneUsageDescription is missing from Info.plist — voice notes will be disabled. Add the key to your app's Info.plist to enable.")
            return nil
        }
        return DefaultAudioRecorderAdapter()
    }

    private var recorder: AVAudioRecorder?
    private var fileURL: URL?
    private var maxDurationTask: Task<Void, Never>?

    public override init() {
        super.init()
        registerInterruptionObserver()
        purgeOrphanedRecordings()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - AudioRecorderAdapter

    public func startRecording() async throws {
        let granted = await requestPermission()
        guard granted else {
            throw AudioRecorderError.permissionDenied
        }

        do {
            try AudioSessionCoordinator.shared.enterRecording()
        } catch {
            throw AudioRecorderError.sessionActivationFailed(error)
        }

        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let url = cachesDir.appendingPathComponent("raya-recording-\(UUID().uuidString).m4a")
        self.fileURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 64_000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]

        do {
            let r = try AVAudioRecorder(url: url, settings: settings)
            r.isMeteringEnabled = true
            guard r.record() else {
                AudioSessionCoordinator.shared.exit()
                throw AudioRecorderError.recordingStartFailed
            }
            self.recorder = r
            startMaxDurationGuard()
        } catch let error as AudioRecorderError {
            throw error
        } catch {
            AudioSessionCoordinator.shared.exit()
            throw AudioRecorderError.recordingStartFailed
        }
    }

    public func stopRecording() async throws -> AudioResult {
        maxDurationTask?.cancel()
        maxDurationTask = nil

        guard let recorder, let fileURL else {
            AudioSessionCoordinator.shared.exit()
            throw AudioRecorderError.recordingNotActive
        }
        recorder.stop()
        self.recorder = nil

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            try? FileManager.default.removeItem(at: fileURL)
            self.fileURL = nil
            AudioSessionCoordinator.shared.exit()
            throw AudioRecorderError.fileReadFailed
        }

        guard data.count > Constants.minAudioPayloadBytes else {
            try? FileManager.default.removeItem(at: fileURL)
            self.fileURL = nil
            AudioSessionCoordinator.shared.exit()
            throw AudioRecorderError.fileTooSmall
        }
        guard data.count < Constants.maxAudioPayloadBytes else {
            try? FileManager.default.removeItem(at: fileURL)
            self.fileURL = nil
            AudioSessionCoordinator.shared.exit()
            throw AudioRecorderError.fileTooLarge
        }

        let dataUri = "data:audio/mp4;base64,\(data.base64EncodedString())"
        let result = AudioResult(uri: fileURL.absoluteString, base64: dataUri)

        try? FileManager.default.removeItem(at: fileURL)
        self.fileURL = nil
        AudioSessionCoordinator.shared.exit()

        return result
    }

    public func pauseRecording() async throws {
        recorder?.pause()
    }

    public func resumeRecording() async throws {
        guard let recorder else {
            throw AudioRecorderError.recordingNotActive
        }
        guard recorder.record() else {
            throw AudioRecorderError.recordingStartFailed
        }
    }

    public func getAmplitude() async -> Float {
        guard let recorder, recorder.isRecording else { return 0 }
        recorder.updateMeters()
        let db = recorder.averagePower(forChannel: 0)
        // Convert dB (-160 to 0) to 0..1 normalized linear amplitude
        let normalized = pow(10, db / 20)
        return Float(min(max(normalized, 0), 1))
    }

    public func cleanup() async {
        maxDurationTask?.cancel()
        maxDurationTask = nil
        recorder?.stop()
        recorder = nil
        if let fileURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
        fileURL = nil
        AudioSessionCoordinator.shared.exit()
    }

    // MARK: - Private

    private func requestPermission() async -> Bool {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted: return true
            case .denied: return false
            case .undetermined:
                return await withCheckedContinuation { cont in
                    AVAudioApplication.requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            @unknown default: return false
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted: return true
            case .denied: return false
            case .undetermined:
                return await withCheckedContinuation { cont in
                    AVAudioSession.sharedInstance().requestRecordPermission { granted in
                        cont.resume(returning: granted)
                    }
                }
            @unknown default: return false
            }
        }
    }

    private func startMaxDurationGuard() {
        let durationNanos = UInt64(Constants.maxAudioDurationSeconds) * 1_000_000_000
        maxDurationTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: durationNanos)
            guard !Task.isCancelled else { return }
            // Hard-stop at the cap. The user can still tap Send to dispatch the
            // already-recorded buffer; the recorder is just no longer active.
            await self?.hardStopAtCap()
        }
    }

    private func hardStopAtCap() async {
        recorder?.stop()
    }

    /// Removes any leftover .m4a files from previous sessions in the caches directory.
    /// Defends against accumulated disk usage if the app was force-killed mid-recording.
    private func purgeOrphanedRecordings() {
        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: cachesDir.path) else { return }
        for entry in entries where entry.hasPrefix("raya-recording-") && entry.hasSuffix(".m4a") {
            try? FileManager.default.removeItem(at: cachesDir.appendingPathComponent(entry))
        }
    }

    private func registerInterruptionObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        switch type {
        case .began:
            recorder?.pause()
        case .ended:
            // User decision: stay paused. Caller must explicitly resume.
            break
        @unknown default:
            break
        }
    }
}
#endif
