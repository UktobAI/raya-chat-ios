import SwiftUI

/// Toast notification overlay for connection errors and status messages.
struct ToastView: View {
    let message: String
    let isError: Bool

    var body: some View {
        Text(message)
            .font(RayaTypography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isError ? Color(hex: 0xEF4444) : Color(hex: 0x3F3F46))
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }
}

/// Toast state manager.
class ToastState: ObservableObject {
    @Published var message: String?
    @Published var isError: Bool = false

    func show(_ text: String, isError: Bool = false, duration: TimeInterval = 3) {
        self.message = text
        self.isError = isError

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            if self?.message == text {
                self?.message = nil
            }
        }
    }
}
