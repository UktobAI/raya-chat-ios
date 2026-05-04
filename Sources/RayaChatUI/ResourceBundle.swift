import Foundation

private final class RayaChatUIBundleToken {}

extension Bundle {
    static let rayaChatUI: Bundle = {
        #if SWIFT_PACKAGE
        return Bundle.module
        #else
        let baseBundle = Bundle(for: RayaChatUIBundleToken.self)
        if let url = baseBundle.url(forResource: "RayaChatUI", withExtension: "bundle"),
           let bundle = Bundle(url: url) {
            return bundle
        }
        return baseBundle
        #endif
    }()
}
