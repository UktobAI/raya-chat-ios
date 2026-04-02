import Foundation

/// Returns true if the locale uses RTL (right-to-left) layout.
public func isRTLLocale(_ locale: String) -> Bool {
    let lower = locale.lowercased()
    return lower.hasPrefix("ar") ||
           lower.hasPrefix("he") ||
           lower.hasPrefix("fa") ||
           lower.hasPrefix("ur")
}

/// Returns true if the text contains RTL characters (Arabic, Hebrew, etc.).
public func isRTLText(_ text: String) -> Bool {
    for scalar in text.unicodeScalars {
        let value = scalar.value
        // Arabic: 0x0600-0x06FF, Arabic Supplement: 0x0750-0x077F
        // Arabic Extended-A: 0x08A0-0x08FF, Arabic Presentation Forms: 0xFB50-0xFDFF, 0xFE70-0xFEFF
        if (0x0600...0x06FF).contains(value) ||
           (0x0750...0x077F).contains(value) ||
           (0x08A0...0x08FF).contains(value) ||
           (0xFB50...0xFDFF).contains(value) ||
           (0xFE70...0xFEFF).contains(value) ||
           // Hebrew: 0x0590-0x05FF
           (0x0590...0x05FF).contains(value) {
            return true
        }
    }
    return false
}
