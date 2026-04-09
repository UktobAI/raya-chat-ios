import SwiftUI
import RayaChatUI

/// Mode 3 demo — Sheet presentation. Chat slides up from the bottom.
struct SheetDemo: View {
    @State private var showChat = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: 0x0F0F14).ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 48))
                    .foregroundColor(Color(hex: 0xF59E0B))

                Text("Sheet Demo")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                Text("Chat appears as a bottom sheet overlay")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x71717A))

                Button(action: { showChat = true }) {
                    Text("Open Chat Sheet")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(hex: 0xF59E0B))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)

                Spacer()

                Button(action: { dismiss() }) {
                    Text("← Back to Menu")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: 0x71717A))
                }
                .padding(.bottom, 32)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showChat) {
            RayaChatView(
                token: sampleToken,
                locale: "en",
                onSessionStart: { id in print("[Mode3] Session started: \(id)") },
                onSessionEnd: { sessionId, messages in print("[Mode3] Session ended — id: \(sessionId), \(messages.count) messages") },
                onError: { err in print("[Mode3] Error: \(err)") },
                onClose: { showChat = false }
            )
            .presentationDetents([.large])
        }
    }
}
