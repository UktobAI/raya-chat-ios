import Foundation

/// Determines if a hex color is "dark" using the luminance formula.
/// Used to decide foreground text color on gradient backgrounds.
///
/// Formula: luminance = (0.299 * R + 0.587 * G + 0.114 * B) / 255
/// If luminance < 0.5 → dark color → use white foreground.
public func isDarkColor(_ hex: String) -> Bool {
    guard let rgb = parseHexColor(hex) else { return true }
    let r = Double((rgb >> 16) & 0xFF)
    let g = Double((rgb >> 8) & 0xFF)
    let b = Double(rgb & 0xFF)
    let luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
    return luminance < 0.5
}

/// Returns white (#FFFFFF) for dark backgrounds, dark (#1A1A1A) for light.
public func getContrastColor(_ hex: String) -> String {
    isDarkColor(hex) ? "#FFFFFF" : "#1A1A1A"
}

/// Parse a hex color string (#RGB, #RRGGBB, or RRGGBB) into an Int, or nil if invalid.
public func parseHexColor(_ hex: String) -> Int? {
    let cleaned = hex.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "#", with: "")
    switch cleaned.count {
    case 3:
        // Expand #RGB to #RRGGBB
        let chars = Array(cleaned)
        let expanded = "\(chars[0])\(chars[0])\(chars[1])\(chars[1])\(chars[2])\(chars[2])"
        return Int(expanded, radix: 16)
    case 6:
        return Int(cleaned, radix: 16)
    default:
        return nil
    }
}
