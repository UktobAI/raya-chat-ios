import SwiftUI
import RayaChatUI
import RayaChatCore

/// Mode 1 demo — SwiftUI View. Simplest integration — 3 lines.
struct SwiftUIDemo: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RayaChatView(
            token: sampleToken,
            locale: "en",
            onSessionStart: { id in print("[Mode1] Session started: \(id)") },
            onSessionEnd: { sessionId, messages in print("[Mode1] Session ended — id: \(sessionId), \(messages.count) messages") },
            onMessageUpdate: { sessionId, message in
                print("[Mode1] onMessageUpdate sid=\(sessionId) id=\(message.id) sender=\(message.sender) type=\(message.type)")
                if message.type == 3, let json = message.attachmentsJson {
                    print("[Mode1]   attachmentsJson: \(json)")
                    for (i, att) in message.attachments.enumerated() {
                        print("[Mode1]   att[\(i)] id='\(att.id)' name='\(att.name)' url=\(att.url)")
                    }
                }
            },
            onError: { err in print("[Mode1] Error: \(err)") },
            onClose: { dismiss() }
        )
        .navigationBarHidden(true)
    }
}
