import Foundation

/// Result from stopping a recording.
public struct AudioResult: Sendable {
    public let uri: String
    public let base64: String?

    public init(uri: String, base64: String? = nil) {
        self.uri = uri
        self.base64 = base64
    }
}

/// Pluggable adapter for audio recording. Mic button hidden if not provided.
public protocol AudioRecorderAdapter: AnyObject {
    func startRecording() async throws
    func stopRecording() async throws -> AudioResult
    func pauseRecording() async throws
    func resumeRecording() async throws
    /// Returns amplitude normalized to 0...1 for waveform visualization.
    func getAmplitude() async -> Float
    func cleanup() async
}
