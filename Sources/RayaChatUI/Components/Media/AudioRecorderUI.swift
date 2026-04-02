import SwiftUI
import RayaChatCore

/// Audio recording UI with waveform visualization and controls.
struct AudioRecorderUI: View {
    let adapter: any AudioRecorderAdapter
    var onComplete: (AudioResult) -> Void
    var onCancel: () -> Void

    @State private var isRecording = false
    @State private var isPaused = false
    @State private var amplitudes: [Float] = []
    @State private var recordingTask: Task<Void, Never>?
    @Environment(\.rayaTheme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            // Cancel
            Button(action: {
                recordingTask?.cancel()
                Task { await adapter.cleanup() }
                onCancel()
            }) {
                RayaIcons.trash
                    .font(.system(size: 18))
                    .foregroundColor(theme.destructive)
                    .frame(width: 36, height: 36)
            }

            // Waveform
            HStack(spacing: 2) {
                ForEach(amplitudes.suffix(30), id: \.self) { amp in
                    RoundedRectangle(cornerRadius: 1)
                        .fill(theme.gradientColor)
                        .frame(width: 3, height: max(4, CGFloat(amp) * 30))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 30)

            // Pause/Resume
            Button(action: {
                Task {
                    if isPaused {
                        try? await adapter.resumeRecording()
                    } else {
                        try? await adapter.pauseRecording()
                    }
                    isPaused.toggle()
                }
            }) {
                (isPaused ? RayaIcons.play : RayaIcons.pause)
                    .font(.system(size: 16))
                    .foregroundColor(theme.foreground)
                    .frame(width: 36, height: 36)
            }

            // Stop & Send
            Button(action: {
                Task {
                    isRecording = false
                    do {
                        let result = try await adapter.stopRecording()
                        await adapter.cleanup()
                        onComplete(result)
                    } catch {
                        onCancel()
                    }
                }
            }) {
                RayaIcons.send
                    .font(.system(size: 16))
                    .foregroundColor(theme.gradientForeground)
                    .frame(width: 36, height: 36)
                    .background(theme.gradientColor)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(theme.composerBg)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.composerBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .onAppear { startRecording() }
        .onDisappear { recordingTask?.cancel() }
    }

    private func startRecording() {
        recordingTask = Task {
            do {
                try await adapter.startRecording()
                isRecording = true
                while isRecording && !Task.isCancelled {
                    let amp = await adapter.getAmplitude()
                    await MainActor.run { amplitudes.append(amp) }
                    try await Task.sleep(for: .milliseconds(100))
                }
            } catch {
                onCancel()
            }
        }
    }
}
