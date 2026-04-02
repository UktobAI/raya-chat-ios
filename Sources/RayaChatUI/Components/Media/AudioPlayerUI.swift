import SwiftUI
import RayaChatCore

/// Audio playback UI with progress bar and play/pause button.
struct AudioPlayerUI: View {
    let uri: String
    let adapter: any AudioPlayerAdapter

    @State private var isPlaying = false
    @State private var durationMs: Int64 = 0
    @State private var positionMs: Int64 = 0
    @State private var loaded = false
    @State private var updateTask: Task<Void, Never>?
    @Environment(\.rayaTheme) private var theme

    private var progress: Double {
        durationMs > 0 ? Double(positionMs) / Double(durationMs) : 0
    }

    private var timeLabel: String {
        let totalSec = durationMs / 1000
        let currentSec = positionMs / 1000
        return "\(formatTime(currentSec)) / \(formatTime(totalSec))"
    }

    var body: some View {
        HStack(spacing: 10) {
            // Play/Pause
            Button(action: togglePlayback) {
                (isPlaying ? RayaIcons.pause : RayaIcons.play)
                    .font(.system(size: 16))
                    .foregroundColor(theme.gradientForeground)
                    .frame(width: 32, height: 32)
                    .background(theme.gradientColor)
                    .clipShape(Circle())
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.border)
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.gradientColor)
                        .frame(width: geo.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            // Time
            Text(timeLabel)
                .font(RayaTypography.tiny)
                .foregroundColor(theme.mutedForeground)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.botBubble)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .task {
            do {
                let info = try await adapter.loadAudio(uri: uri)
                durationMs = info.durationMs
                loaded = true
            } catch {}
        }
        .onDisappear {
            updateTask?.cancel()
            Task { await adapter.cleanup() }
        }
    }

    private func togglePlayback() {
        guard loaded else { return }
        Task {
            if isPlaying {
                try? await adapter.pause()
                isPlaying = false
                updateTask?.cancel()
            } else {
                try? await adapter.play()
                isPlaying = true
                updateTask = Task {
                    while isPlaying && !Task.isCancelled {
                        let pos = await adapter.getPosition()
                        await MainActor.run { positionMs = pos }
                        if pos >= durationMs {
                            await MainActor.run { isPlaying = false; positionMs = 0 }
                            break
                        }
                        try? await Task.sleep(nanoseconds: 200_000_000)
                    }
                }
            }
        }
    }

    private func formatTime(_ seconds: Int64) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
