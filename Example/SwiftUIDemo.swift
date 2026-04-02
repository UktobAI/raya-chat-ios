import SwiftUI
import RayaChatUI

/// Mode 1 demo — SwiftUI View. Simplest integration — 3 lines.
struct SwiftUIDemo: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RayaChatView(
            token: sampleToken,
            locale: "en",
            onSessionStart: { id in print("[Mode1] Session started: \(id)") },
            onSessionEnd: { print("[Mode1] Session ended") },
            onError: { err in print("[Mode1] Error: \(err)") },
            onClose: { dismiss() }
        )
        .navigationBarHidden(true)
    }
}
