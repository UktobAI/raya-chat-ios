#if canImport(UIKit)
import UIKit
import PhotosUI
import RayaChatCore

/// Built-in image picker using PHPickerViewController.
/// Converts picked images to JPEG base64 (max 1024px, 70% quality) — matches Android sample adapter.
final class DefaultImagePickerAdapter: NSObject, ImagePickerAdapter, PHPickerViewControllerDelegate {
    private var continuation: CheckedContinuation<[ImageAsset], Error>?

    func pickImages(maxCount: Int) async throws -> [ImageAsset] {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont

            var config = PHPickerConfiguration()
            config.selectionLimit = maxCount
            config.filter = .images

            let picker = PHPickerViewController(configuration: config)
            picker.delegate = self

            DispatchQueue.main.async {
                guard let vc = Self.topViewController() else {
                    cont.resume(returning: [])
                    return
                }
                vc.present(picker, animated: true)
            }
        }
    }

    // MARK: - PHPickerViewControllerDelegate

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let cont = continuation else { return }
        continuation = nil

        if results.isEmpty {
            cont.resume(returning: [])
            return
        }

        Task {
            var assets: [ImageAsset] = []
            for result in results {
                if let asset = await processResult(result) {
                    assets.append(asset)
                }
            }
            cont.resume(returning: assets)
        }
    }

    // MARK: - Private

    private func processResult(_ result: PHPickerResult) async -> ImageAsset? {
        let provider = result.itemProvider
        guard provider.canLoadObject(ofClass: UIImage.self) else { return nil }

        return await withCheckedContinuation { cont in
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                guard let image = object as? UIImage else {
                    cont.resume(returning: nil)
                    return
                }

                let resized = Self.resize(image, maxDimension: 1024)
                guard let data = resized.jpegData(compressionQuality: 0.7) else {
                    cont.resume(returning: nil)
                    return
                }

                let rawBase64 = data.base64EncodedString()
                let dataUri = "data:image/jpeg;base64,\(rawBase64)"
                let name = provider.suggestedName ?? "image_\(UUID().uuidString.prefix(8)).jpg"

                // base64 = full data URI (matches Android convention)
                cont.resume(returning: ImageAsset(
                    uri: dataUri, name: name, type: "image/jpeg", base64: dataUri
                ))
            }
        }
    }

    private static func resize(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        let maxSide = max(size.width, size.height)
        if maxSide <= maxDimension { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resized = UIGraphicsGetImageFromCurrentImageContext() ?? image
        UIGraphicsEndImageContext()
        return resized
    }

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0 is UIWindowScene }) as? UIWindowScene,
              let window = scene.windows.first(where: \.isKeyWindow) else { return nil }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController { vc = presented }
        return vc
    }
}
#endif
