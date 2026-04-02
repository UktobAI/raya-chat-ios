import SwiftUI
#if canImport(UIKit)
import UIKit
import RayaChatUI

/// Mode 2 demo — UIKit ViewController wrapped in SwiftUI for the example app.
struct UIKitDemoWrapper: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        UIKitDemoRepresentable(onClose: { dismiss() })
            .ignoresSafeArea()
            .navigationBarHidden(true)
    }
}

struct UIKitDemoRepresentable: UIViewControllerRepresentable {
    let onClose: () -> Void

    func makeUIViewController(context: Context) -> UINavigationController {
        let chatVC = RayaChatViewController(token: sampleToken, locale: "en")
        chatVC.onSessionStart = { id in print("[Mode2] Session started: \(id)") }
        chatVC.onError = { err in print("[Mode2] Error: \(err)") }
        chatVC.onClose = onClose

        let nav = UINavigationController(rootViewController: chatVC)
        nav.isNavigationBarHidden = true
        return nav
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
#else
struct UIKitDemoWrapper: View {
    var body: some View {
        Text("UIKit demo requires iOS")
    }
}
#endif
