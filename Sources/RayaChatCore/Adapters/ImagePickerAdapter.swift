import Foundation

/// Pluggable adapter for image selection. Image/paperclip button hidden if not provided.
public protocol ImagePickerAdapter: AnyObject {
    func pickImages(maxCount: Int) async throws -> [ImageAsset]
}
