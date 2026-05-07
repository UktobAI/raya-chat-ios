import SwiftUI
import RayaChatCore

/// Shown after the user stops recording, before sending. Lets them play back
/// their voice note and either send or discard. Matches the web widget layout:
///
/// `[ (X) cancel ]  [ static waveform with playback progress ]  [ (▶) play ]  [ ✈ send ]`
struct AudioPreviewUI: View {
    let audioResult: AudioResult
    let amplitudes: [Float]
    var onSend: () -> Void
    var onCancel: () -> Void

    #if canImport(AVFAudio) && os(iOS)
    @State private var adapter: DefaultAudioPlayerAdapter = .init()
    #endif

    @State private var isPlaying = false
    @State private var loaded = false
    @State private var positionMs: Int64 = 0
    @State private var durationMs: Int64 = 1
    @State private var updateTask: Task<Void, Never>?
    @Environment(\.rayaTheme) private var theme

    private var progress: Double {
        guard durationMs > 0 else { return 0 }
        return min(1, Double(positionMs) / Double(durationMs))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Cancel — outlined circle X
            Button(action: cancelTapped) {
                Image("CircleXIcon", bundle: .rayaChatUI)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.mutedForeground)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Discard recording")

            // Static waveform of the WHOLE recording, downsampled to fit available width.
            GeometryReader { geo in
                let barWidth: CGFloat = 2
                let spacing: CGFloat = 2
                let maxBars = max(1, Int((geo.size.width + spacing) / (barWidth + spacing)))
                let downsampled = Self.downsample(amplitudes, to: maxBars)
                HStack(spacing: spacing) {
                    ForEach(Array(downsampled.enumerated()), id: \.offset) { idx, amp in
                        let played = Double(idx) / Double(max(downsampled.count, 1)) <= progress
                        RoundedRectangle(cornerRadius: 1)
                            .fill(played ? theme.foreground : theme.foreground.opacity(0.3))
                            .frame(width: barWidth, height: max(3, CGFloat(amp) * 28))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: geo.size.height, alignment: .center)
            }
            .frame(height: 28)
            .clipped()

            // Play / Pause — outlined circle
            Button(action: togglePlay) {
                Image(isPlaying ? "CirclePauseIcon" : "CirclePlayIcon", bundle: .rayaChatUI)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.mutedForeground)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(isPlaying ? "Pause preview" : "Play preview")

            // Send — paper-plane in filled gradient circle (matches composer Send)
            Button(action: sendTapped) {
                Image("SendIcon", bundle: .rayaChatUI)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.gradientForeground)
                    .frame(width: 16, height: 16)
                    .frame(width: 36, height: 36)
                    .background(theme.gradientColor)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Send recording")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.composerBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.composerBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .task { await loadPreview() }
        .onDisappear { teardown() }
    }

    // MARK: - Actions

    private func cancelTapped() {
        teardown()
        onCancel()
    }

    private func sendTapped() {
        teardown()
        onSend()
    }

    private func togglePlay() {
        guard loaded else { return }
        Task {
            #if canImport(AVFAudio) && os(iOS)
            if isPlaying {
                try? await adapter.pause()
                await MainActor.run { isPlaying = false }
                updateTask?.cancel()
            } else {
                // Restart from beginning if at end
                if positionMs >= durationMs {
                    try? await adapter.seekTo(positionMs: 0)
                    await MainActor.run { positionMs = 0 }
                }
                try? await adapter.play()
                await MainActor.run { isPlaying = true }
                startProgressTask()
            }
            #endif
        }
    }

    private func startProgressTask() {
        updateTask?.cancel()
        updateTask = Task {
            #if canImport(AVFAudio) && os(iOS)
            // End-of-playback heuristics: AVAudioPlayer.currentTime returns slightly less
            // than duration on natural finish, so an exact `>= durationMs` check rarely
            // fires. Use a tolerance + position-stagnation fallback.
            var lastPos: Int64 = -1
            var stagnantTicks = 0
            while !Task.isCancelled {
                let pos = await adapter.getPosition()
                await MainActor.run { positionMs = pos }

                let nearEnd = pos >= durationMs - 200       // 200ms tolerance
                if pos == lastPos { stagnantTicks += 1 } else { stagnantTicks = 0; lastPos = pos }
                let stalled = stagnantTicks >= 3            // ~300ms of no progress

                if nearEnd || stalled {
                    await MainActor.run {
                        isPlaying = false
                        if nearEnd { positionMs = durationMs }
                    }
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            #endif
        }
    }

    private func loadPreview() async {
        #if canImport(AVFAudio) && os(iOS)
        // The recorder stashes the playable data URI in `uri` (the temp file is deleted
        // immediately after stopRecording). `base64` holds the raw bytes for the WebSocket.
        do {
            let info = try await adapter.loadAudio(uri: audioResult.uri)
            await MainActor.run {
                durationMs = max(1, info.durationMs)
                loaded = true
            }
        } catch {
            // If the recorded audio can't be loaded, leave loaded=false; user can still send.
        }
        #endif
    }

    private func teardown() {
        updateTask?.cancel()
        updateTask = nil
        #if canImport(AVFAudio) && os(iOS)
        Task { await adapter.cleanup() }
        #endif
    }

    /// Downsample the recorded amplitudes into `count` buckets, taking the peak
    /// per bucket so loud bursts remain visible. If we have fewer samples than
    /// buckets, returns the original array unchanged.
    private static func downsample(_ amps: [Float], to count: Int) -> [Float] {
        guard amps.count > count, count > 0 else { return amps }
        let bucketSize = Double(amps.count) / Double(count)
        var result: [Float] = []
        result.reserveCapacity(count)
        for i in 0..<count {
            let start = Int(Double(i) * bucketSize)
            let end = min(amps.count, Int(Double(i + 1) * bucketSize))
            guard start < end else { result.append(0); continue }
            let slice = amps[start..<end]
            result.append(slice.max() ?? 0)
        }
        return result
    }
}
