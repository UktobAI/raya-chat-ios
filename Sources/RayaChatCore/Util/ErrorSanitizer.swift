import Foundation

private let htmlTagRegex = try! NSRegularExpression(pattern: "<[^>]*>")
private let jsProtocolRegex = try! NSRegularExpression(pattern: "javascript:", options: .caseInsensitive)
private let eventHandlerRegex = try! NSRegularExpression(pattern: "on\\w+=", options: .caseInsensitive)
private let maxErrorLength = 200
private let defaultError = "An unexpected error occurred. Please try again."

private let sensitivePatterns = [
    "api_key", "password", "token", "secret",
    "authorization", "bearer", "credential",
]

/// Sanitizes error messages for safe display to users.
/// Strips HTML, JavaScript, event handlers, sensitive data, and truncates.
public func sanitizeErrorMessage(_ input: String?) -> String {
    guard let input = input, !input.isEmpty else {
        return defaultError
    }

    var sanitized = input
    let range = NSRange(sanitized.startIndex..., in: sanitized)

    // Strip HTML tags
    sanitized = htmlTagRegex.stringByReplacingMatches(in: sanitized, range: range, withTemplate: "")

    // Strip javascript: protocol
    let range2 = NSRange(sanitized.startIndex..., in: sanitized)
    sanitized = jsProtocolRegex.stringByReplacingMatches(in: sanitized, range: range2, withTemplate: "")

    // Strip event handlers
    let range3 = NSRange(sanitized.startIndex..., in: sanitized)
    sanitized = eventHandlerRegex.stringByReplacingMatches(in: sanitized, range: range3, withTemplate: "")

    // Check for sensitive patterns
    let lower = sanitized.lowercased()
    for pattern in sensitivePatterns {
        if lower.contains(pattern) {
            return defaultError
        }
    }

    // Truncate
    if sanitized.count > maxErrorLength {
        sanitized = String(sanitized.prefix(maxErrorLength)) + "..."
    }

    return sanitized.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultError : sanitized
}
