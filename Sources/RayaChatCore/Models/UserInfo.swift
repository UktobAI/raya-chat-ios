import Foundation

/// User information collected from the form screen.
public struct UserInfo: Codable, Equatable, Sendable {
    public let fullName: String
    public let email: String
    public let phone: String

    public init(fullName: String = "", email: String = "", phone: String = "") {
        self.fullName = fullName
        self.email = email
        self.phone = phone
    }
}
