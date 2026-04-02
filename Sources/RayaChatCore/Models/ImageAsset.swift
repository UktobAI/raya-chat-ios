import Foundation

/// Image selected by the user for upload.
public struct ImageAsset: Sendable {
    public let uri: String
    public let name: String
    public let type: String
    public let base64: String

    public init(uri: String, name: String, type: String, base64: String = "") {
        self.uri = uri
        self.name = name
        self.type = type
        self.base64 = base64
    }
}
