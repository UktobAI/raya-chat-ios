import Foundation

/// Simple logger for the SDK. Uses print() for maximum compatibility.
/// Tag prefix: RayaChat.* (same pattern as Android SDK).
enum Log {
    static func d(_ tag: String, _ message: String) {
        #if DEBUG
        print("[RayaChat.\(tag)] \(message)")
        #endif
    }

    static func i(_ tag: String, _ message: String) {
        print("[RayaChat.\(tag)] \(message)")
    }

    static func w(_ tag: String, _ message: String) {
        print("[RayaChat.\(tag)] ⚠️ \(message)")
    }

    static func e(_ tag: String, _ message: String) {
        print("[RayaChat.\(tag)] ❌ \(message)")
    }
}
