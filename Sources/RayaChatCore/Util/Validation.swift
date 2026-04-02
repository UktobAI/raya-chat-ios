import Foundation

private let emailRegex = try! NSRegularExpression(
    pattern: "^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$"
)

private let phoneRegex = try! NSRegularExpression(
    pattern: "^[+]?[0-9\\s\\-()]{7,20}$"
)

/// Validates an email address format.
public func validateEmail(_ email: String) -> Bool {
    let range = NSRange(email.startIndex..., in: email)
    return emailRegex.firstMatch(in: email, range: range) != nil
}

/// Validates a phone number format.
public func validatePhone(_ phone: String) -> Bool {
    let range = NSRange(phone.startIndex..., in: phone)
    return phoneRegex.firstMatch(in: phone, range: range) != nil
}
