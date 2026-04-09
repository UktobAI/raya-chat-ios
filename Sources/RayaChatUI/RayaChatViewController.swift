#if canImport(UIKit)
import UIKit
import SwiftUI
import RayaChatCore

/// Mode 2: UIKit bridge — wraps `RayaChatView` in a `UIHostingController`.
///
/// ```swift
/// let vc = RayaChatViewController(
///     token: "your-bot-token",
///     onSessionEnd: { sessionId, messages in /* POST to your API */ },
///     onClose: { navigationController?.popViewController(animated: true) }
/// )
/// navigationController?.pushViewController(vc, animated: true)
/// ```
///
/// Works in UINavigationController, UITabBarController, Storyboard segues, modal presentation,
/// and container view embedding — everywhere a UIViewController fits.
public final class RayaChatViewController: UIHostingController<AnyView> {

    /// Creates the chat widget as a UIViewController.
    ///
    /// - Parameters:
    ///   - token: Bot token from the Teammates.ai dashboard.
    ///   - locale: Language — `"en"` or `"ar"`. Default: `"en"`.
    ///   - imagePickerAdapter: Adapter for image selection. Built-in PHPicker used if omitted.
    ///   - audioRecorderAdapter: Adapter for voice recording.
    ///   - onSessionStart: Called with session ID when WebSocket connects.
    ///   - onSessionEnd: Called when session ends — passes (sessionId, messages) with remote attachment URLs.
    ///   - onError: Called on errors.
    ///   - onClose: Called when user closes the widget.
    public convenience init(
        token: String,
        locale: String = "en",
        imagePickerAdapter: (any ImagePickerAdapter)? = nil,
        audioRecorderAdapter: (any AudioRecorderAdapter)? = nil,
        onSessionStart: ((String) -> Void)? = nil,
        onSessionEnd: ((String, [TypeMessage]) -> Void)? = nil,
        onError: ((String) -> Void)? = nil,
        onClose: (() -> Void)? = nil
    ) {
        let view = RayaChatView(
            token: token,
            locale: locale,
            imagePickerAdapter: imagePickerAdapter,
            audioRecorderAdapter: audioRecorderAdapter,
            onSessionStart: onSessionStart,
            onSessionEnd: onSessionEnd,
            onError: onError,
            onClose: onClose
        )
        self.init(rootView: AnyView(view))
    }
}
#endif
