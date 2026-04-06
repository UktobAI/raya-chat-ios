#if canImport(UIKit)
import UIKit
import SwiftUI
import RayaChatCore

/// Mode 2: UIKit bridge — wraps `RayaChatView` in a `UIHostingController`.
///
/// ```swift
/// let vc = RayaChatViewController(token: "your-bot-token")
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
    public convenience init(
        token: String,
        locale: String = "en",
        imagePickerAdapter: (any ImagePickerAdapter)? = nil,
        audioRecorderAdapter: (any AudioRecorderAdapter)? = nil
    ) {
        let view = RayaChatView(
            token: token,
            locale: locale,
            imagePickerAdapter: imagePickerAdapter,
            audioRecorderAdapter: audioRecorderAdapter,
            onClose: nil // Set via property after init
        )
        self.init(rootView: AnyView(view))
    }

    /// Called when the user closes the widget. Set this before presenting.
    public var onClose: (() -> Void)?

    /// Called with session ID when WebSocket connects.
    public var onSessionStart: ((String) -> Void)?

    /// Called when session ends.
    public var onSessionEnd: (() -> Void)?

    /// Called on errors.
    public var onError: ((String) -> Void)?
}
#endif
