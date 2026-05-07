import Foundation

/// Info returned after loading audio.
public struct AudioInfo: Sendable {
    public let durationMs: Int64

    public init(durationMs: Int64) {
        self.durationMs = durationMs
    }
}

/// Pluggable adapter for audio playback.
public protocol AudioPlayerAdapter: AnyObject {
    func loadAudio(uri: String) async throws -> AudioInfo
    func play() async throws
    func pause() async throws
    func seekTo(positionMs: Int64) async throws
    func getPosition() async -> Int64
    func cleanup() async

    /// Returns peak amplitude (0..1) for each of `sampleCount` time-buckets across the loaded audio,
    /// for waveform visualization. Returns nil if the adapter cannot extract amplitude data.
    /// Default implementation returns nil — adapters that can read the underlying audio (e.g., the
    /// built-in `DefaultAudioPlayerAdapter`) override this.
    func getAmplitudes(sampleCount: Int) async -> [Float]?
}

public extension AudioPlayerAdapter {
    func getAmplitudes(sampleCount: Int) async -> [Float]? { nil }
}
