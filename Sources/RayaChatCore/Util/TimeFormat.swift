import Foundation

/// Formats a Unix epoch timestamp (seconds) for display in message bubbles.
///
/// Returns "h:mm a" format (e.g., "2:30 PM") in the device's local timezone.
/// Returns nil if the input is invalid.
public func formatLocalTime(epochSeconds: Int64?) -> String? {
    guard let seconds = epochSeconds, seconds > 0 else { return nil }

    let date = Date(timeIntervalSince1970: TimeInterval(seconds))
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: date)
}

/// Formats a Unix epoch timestamp (seconds) for display.
/// Returns "h:mm a" or empty string if invalid.
public func formatLocalTimeOrEmpty(epochSeconds: Int64?) -> String {
    formatLocalTime(epochSeconds: epochSeconds) ?? ""
}
