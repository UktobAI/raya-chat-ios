import SwiftUI
import RayaChatCore

/// Audio playback view used inside chat bubbles. Matches the web widget layout:
///
/// `[ HH:MM:SS / HH:MM:SS ]   [ ▏▎▍ played-bars · · · · · · · · · · ]   [ ▷ play ]`
///
/// Played portion shows real waveform-style bars. Unplayed portion is a thin dotted line.
/// Designed to render flat in a chat row — no bubble background, no card padding.
struct AudioPlayerUI: View {
    let uri: String
    let adapter: any AudioPlayerAdapter

    @State private var isPlaying = false
    @State private var durationMs: Int64 = 0
    @State private var positionMs: Int64 = 0
    @State private var loaded = false
    @State private var amplitudes: [Float] = []
    @State private var updateTask: Task<Void, Never>?
    @Environment(\.rayaTheme) private var theme

    /// Bars below this normalized amplitude don't render — the dashed line shows through,
    /// matching the web widget's "speech vs silence" visual distinction.
    private let silenceThreshold: Float = 0.05

    private var progress: Double {
        durationMs > 0 ? min(1, Double(positionMs) / Double(durationMs)) : 0
    }

    private var elapsedLabel: String {
        let cur = Int(positionMs / 1000)
        let total = Int(durationMs / 1000)
        return "\(formatTime(cur)) / \(formatTime(total))"
    }

    var body: some View {
        HStack(spacing: 12) {
            // Time label on the LEFT
            Text(elapsedLabel)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(theme.foreground)
                .fixedSize()

            // Waveform: dashed line under everything, bars drawn only where amplitude > threshold,
            // played portion in foreground color, unplayed portion in muted opacity.
            GeometryReader { geo in
                let barWidth: CGFloat = 2
                let spacing: CGFloat = 2
                let maxBars = max(1, Int((geo.size.width + spacing) / (barWidth + spacing)))
                let display = AudioPlayerUI.downsample(amplitudes, to: maxBars)
                let playedCount = Int(Double(display.count) * progress)
                // Normalize against this recording's loudest moment so bars fill the height
                // even for quiet recordings. Apply a sqrt curve so quieter parts stay visible
                // alongside the loudest peaks.
                let peak = max(0.05, display.max() ?? 1.0)

                ZStack(alignment: .leading) {
                    // Background dashed line, full width, vertically centered
                    Path { p in
                        let y = geo.size.height / 2
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    .stroke(theme.mutedForeground.opacity(0.6),
                            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [2, 4]))

                    HStack(spacing: spacing) {
                        ForEach(Array(display.enumerated()), id: \.offset) { idx, amp in
                            if amp >= silenceThreshold {
                                let played = idx < playedCount
                                let normalized = min(1.0, amp / peak)
                                let curved = CGFloat(sqrt(normalized))
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(played ? theme.foreground : theme.foreground.opacity(0.4))
                                    .frame(width: barWidth, height: max(4, curved * 22))
                            } else {
                                Color.clear.frame(width: barWidth)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 24)
            .clipped()

            // Play / Pause — outlined glyph, no circle
            Button(action: togglePlayback) {
                Image(isPlaying ? "PauseIcon" : "PlayIcon", bundle: .rayaChatUI)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.foreground)
                    .frame(width: 22, height: 22)
            }
            .accessibilityLabel(isPlaying ? "Pause audio" : "Play audio")
        }
        .task {
            do {
                let info = try await adapter.loadAudio(uri: uri)
                await MainActor.run {
                    durationMs = info.durationMs
                    loaded = true
                }
                // Extract real amplitudes after load — the dashed line shows immediately,
                // bars fade in once decoded.
                if let amps = await adapter.getAmplitudes(sampleCount: 60) {
                    await MainActor.run { amplitudes = amps }
                }
            } catch {}
        }
        .onDisappear {
            updateTask?.cancel()
            Task { await adapter.cleanup() }
        }
    }

    // MARK: - Playback

    private func togglePlayback() {
        guard loaded else { return }
        Task {
            if isPlaying {
                try? await adapter.pause()
                await MainActor.run { isPlaying = false }
                updateTask?.cancel()
            } else {
                if positionMs >= durationMs {
                    try? await adapter.seekTo(positionMs: 0)
                    await MainActor.run { positionMs = 0 }
                }
                try? await adapter.play()
                await MainActor.run { isPlaying = true }
                startProgressTask()
            }
        }
    }

    private func startProgressTask() {
        updateTask?.cancel()
        updateTask = Task {
            // End-of-playback heuristics — see AudioPreviewUI.startProgressTask for rationale.
            var lastPos: Int64 = -1
            var stagnantTicks = 0
            while !Task.isCancelled {
                let pos = await adapter.getPosition()
                await MainActor.run { positionMs = pos }

                let nearEnd = pos >= durationMs - 200
                if pos == lastPos { stagnantTicks += 1 } else { stagnantTicks = 0; lastPos = pos }
                let stalled = stagnantTicks >= 3

                if nearEnd || stalled {
                    await MainActor.run {
                        isPlaying = false
                        if nearEnd { positionMs = durationMs }
                    }
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let s = seconds % 60
        let m = (seconds / 60) % 60
        let h = seconds / 3600
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// Downsample real amplitudes to fit `count` buckets, taking the peak per bucket.
    static func downsample(_ amps: [Float], to count: Int) -> [Float] {
        guard count > 0 else { return [] }
        guard amps.count > count else {
            // Pad with zeros so layout matches expected bar count
            return amps + Array(repeating: 0, count: max(0, count - amps.count))
        }
        let bucket = Double(amps.count) / Double(count)
        var result: [Float] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let start = Int(Double(i) * bucket)
            let end = min(amps.count, Int(Double(i + 1) * bucket))
            guard start < end else { result.append(0); continue }
            let slice = amps[start..<end]
            result.append(slice.max() ?? 0)
        }
        return result
    }
}
