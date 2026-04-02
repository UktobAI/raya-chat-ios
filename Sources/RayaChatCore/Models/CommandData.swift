import Foundation

/// Active server command that requires user interaction.
public struct CommandData: Equatable, Sendable {
    public let content: String
    public let options: [AnyCodable]
    public let message: String
    public let optional: Bool

    public init(content: String, options: [AnyCodable] = [], message: String = "", optional: Bool = false) {
        self.content = content
        self.options = options
        self.message = message
        self.optional = optional
    }
}
