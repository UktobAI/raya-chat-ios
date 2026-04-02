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
}
