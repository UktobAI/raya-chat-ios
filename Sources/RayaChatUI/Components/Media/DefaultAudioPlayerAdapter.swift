import Foundation
import RayaChatCore
#if canImport(AVFAudio) && os(iOS)
import AVFoundation

/// Errors surfaced by `DefaultAudioPlayerAdapter`.
public enum AudioPlayerError: LocalizedError, Sendable {
    case invalidURL(String)
    case downloadFailed(Error)
    case loadFailed(Error)
    case playbackNotReady
    case sessionActivationFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let s): return "Invalid audio URL: \(s)"
        case .downloadFailed(let e): return "Audio download failed: \(e.localizedDescription)"
        case .loadFailed(let e): return "Audio load failed: \(e.localizedDescription)"
        case .playbackNotReady: return "Audio is not ready for playback."
        case .sessionActivationFailed(let e): return "Audio session activation failed: \(e.localizedDescription)"
        }
    }
}

/// Built-in audio player using AVAudioPlayer.
///
/// Loads remote audio (`https://...`) or local data URIs (`data:audio/mp4;base64,...`)
/// and plays through `AVAudioPlayer`. Coordinates with `AudioSessionCoordinator`
/// so playback pauses cleanly when a recording starts and the host app's prior
/// audio session is restored on cleanup.
///
/// Each instance plays one file at a time. If `loadAudio` is called again on
/// the same instance, the previous player is stopped and replaced.
public final class DefaultAudioPlayerAdapter: NSObject, AudioPlayerAdapter, @unchecked Sendable {

    public static func make() -> DefaultAudioPlayerAdapter {
        DefaultAudioPlayerAdapter()
    }

    private var player: AVAudioPlayer?
    private var cachedFileURL: URL?

    public override init() {
        super.init()
    }

    deinit {
        try? cachedFileURL.map { try FileManager.default.removeItem(at: $0) }
    }

    // MARK: - AudioPlayerAdapter

    public func loadAudio(uri: String) async throws -> AudioInfo {
        // Stop any previous playback
        player?.stop()
        player = nil
        if let cached = cachedFileURL {
            try? FileManager.default.removeItem(at: cached)
            cachedFileURL = nil
        }

        let data: Data
        if uri.hasPrefix("data:") {
            // Local data URI — strip prefix, decode base64
            guard let commaIdx = uri.firstIndex(of: ","),
                  let decoded = Data(base64Encoded: String(uri[uri.index(after: commaIdx)...])) else {
                throw AudioPlayerError.invalidURL(uri)
            }
            data = decoded
        } else {
            guard let url = URL(string: uri) else {
                throw AudioPlayerError.invalidURL(uri)
            }
            do {
                let (downloaded, _) = try await URLSession.shared.data(from: url)
                data = downloaded
            } catch {
                throw AudioPlayerError.downloadFailed(error)
            }
        }

        let cachesDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let cacheURL = cachesDir.appendingPathComponent("raya-playback-\(UUID().uuidString).m4a")
        do {
            try data.write(to: cacheURL)
        } catch {
            throw AudioPlayerError.loadFailed(error)
        }
        cachedFileURL = cacheURL

        do {
            let p = try AVAudioPlayer(contentsOf: cacheURL)
            p.prepareToPlay()
            self.player = p
            return AudioInfo(durationMs: Int64(p.duration * 1000))
        } catch {
            try? FileManager.default.removeItem(at: cacheURL)
            cachedFileURL = nil
            throw AudioPlayerError.loadFailed(error)
        }
    }

    public func play() async throws {
        guard let player else { throw AudioPlayerError.playbackNotReady }
        do {
            try AudioSessionCoordinator.shared.enterPlaying()
        } catch {
            throw AudioPlayerError.sessionActivationFailed(error)
        }
        player.play()
    }

    public func pause() async throws {
        player?.pause()
    }

    public func seekTo(positionMs: Int64) async throws {
        guard let player else { throw AudioPlayerError.playbackNotReady }
        player.currentTime = max(0, min(player.duration, Double(positionMs) / 1000.0))
    }

    public func getPosition() async -> Int64 {
        guard let player else { return 0 }
        return Int64(player.currentTime * 1000)
    }

    public func cleanup() async {
        player?.stop()
        player = nil
        if let cached = cachedFileURL {
            try? FileManager.default.removeItem(at: cached)
            cachedFileURL = nil
        }
        AudioSessionCoordinator.shared.exit()
    }
}
#endif
