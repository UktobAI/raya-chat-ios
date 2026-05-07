import SwiftUI
import RayaChatCore

/// Audio recording UI matching the web widget layout:
///
/// `[ (X) cancel ]  [ ● rec ]  [ MM:SS ]  [ waveform ]  [ (||) pause ]  [ (□) stop ]`
struct AudioRecorderUI: View {
    let adapter: any AudioRecorderAdapter
    var onComplete: (AudioResult, [Float]) -> Void
    var onCancel: () -> Void

    @State private var isRecording = false
    @State private var isPaused = false
    @State private var amplitudes: [Float] = []
    @State private var elapsedSeconds: Int = 0
    @State private var recordingTask: Task<Void, Never>?
    @State private var elapsedTask: Task<Void, Never>?
    @Environment(\.rayaTheme) private var theme

    private var elapsedLabel: String {
        let s = elapsedSeconds % 60
        let m = (elapsedSeconds / 60) % 60
        let h = elapsedSeconds / 3600
        return String(format: "%02d:%02d:%02d", h, m, s)
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
            .accessibilityLabel("Cancel recording")

            // Red recording dot — visible while actively recording (not paused)
            Circle()
                .fill(Color(hex: 0xEF4444))
                .frame(width: 8, height: 8)
                .opacity(isPaused ? 0.3 : 1.0)

            // Elapsed timer
            Text(elapsedLabel)
                .font(.system(size: 13, weight: .regular, design: .monospaced))
                .foregroundColor(theme.foreground)
                .frame(minWidth: 64, alignment: .leading)

            // Waveform — sized to available space, never pushes the composer wider
            GeometryReader { geo in
                let barWidth: CGFloat = 2
                let spacing: CGFloat = 2
                let maxBars = max(1, Int((geo.size.width + spacing) / (barWidth + spacing)))
                let visible = Array(amplitudes.suffix(maxBars).enumerated())
                HStack(spacing: spacing) {
                    ForEach(visible, id: \.offset) { _, amp in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.foreground)
                            .frame(width: barWidth, height: max(3, CGFloat(amp) * 28))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: geo.size.height, alignment: .center)
            }
            .frame(height: 28)
            .clipped()

            // Pause / Resume — outlined circle
            Button(action: pauseResumeTapped) {
                Image(isPaused ? "CirclePlayIcon" : "CirclePauseIcon", bundle: .rayaChatUI)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.mutedForeground)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel(isPaused ? "Resume recording" : "Pause recording")

            // Stop & send — outlined circle square
            Button(action: stopAndSendTapped) {
                Image("CircleStopIcon", bundle: .rayaChatUI)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(theme.mutedForeground)
                    .frame(width: 28, height: 28)
            }
            .accessibilityLabel("Send recording")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(theme.composerBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.composerBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .onAppear { startRecording() }
        .onDisappear {
            recordingTask?.cancel()
            elapsedTask?.cancel()
        }
    }

    // MARK: - Actions

    private func cancelTapped() {
        recordingTask?.cancel()
        elapsedTask?.cancel()
        Task { await adapter.cleanup() }
        onCancel()
    }

    private func pauseResumeTapped() {
        Task {
            do {
                if isPaused {
                    try await adapter.resumeRecording()
                } else {
                    try await adapter.pauseRecording()
                }
                await MainActor.run { isPaused.toggle() }
            } catch {
                await MainActor.run { onCancel() }
            }
        }
    }

    private func stopAndSendTapped() {
        recordingTask?.cancel()
        elapsedTask?.cancel()
        let captured = amplitudes
        Task {
            isRecording = false
            do {
                let result = try await adapter.stopRecording()
                await MainActor.run { onComplete(result, captured) }
            } catch {
                await MainActor.run { onCancel() }
            }
        }
    }

    // MARK: - Recording Lifecycle

    private func startRecording() {
        recordingTask = Task {
            do {
                try await adapter.startRecording()
                await MainActor.run { isRecording = true }
                startElapsedTimer()
                while isRecording && !Task.isCancelled {
                    if !isPaused {
                        let amp = await adapter.getAmplitude()
                        await MainActor.run { amplitudes.append(amp) }
                    }
                    try await Task.sleep(nanoseconds: 100_000_000)
                }
            } catch {
                await MainActor.run { onCancel() }
            }
        }
    }

    private func startElapsedTimer() {
        elapsedTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                if !isPaused {
                    await MainActor.run { elapsedSeconds += 1 }
                }
            }
        }
    }
}
