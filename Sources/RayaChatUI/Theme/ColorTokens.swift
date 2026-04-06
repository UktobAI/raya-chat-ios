import SwiftUI

/// Light mode color tokens — exact hex values from the RN SDK.
public enum LightColors {
    public static let background = Color(hex: 0xFFFFFF)
    public static let foreground = Color(hex: 0x14161A)
    public static let surface = Color(hex: 0xFFFFFF)
    public static let surfaceVariant = Color(hex: 0xF5F5F5)
    public static let border = Color(hex: 0xE4E4E7)
    public static let borderWarm = Color(hex: 0xD4D4D8)
    public static let muted = Color(hex: 0xF4F4F5)
    public static let mutedForeground = Color(hex: 0x71717A)
    public static let botBubble = Color(hex: 0xF5F5F5)
    public static let botBubbleForeground = Color(hex: 0x14161A)
    public static let systemMessage = Color(hex: 0xF4F4F5)
    public static let systemMessageForeground = Color(hex: 0x71717A)
    public static let introCard = Color(hex: 0xFFFFFF)
    public static let introCardBorder = Color(hex: 0xE4E4E7)
    public static let formCardBg = Color(hex: 0xFFFFFF)
    public static let inputBorder = Color(hex: 0xD4D4D8)
    public static let inputBorderFocused = Color(hex: 0xA1A1AA)
    public static let composerBorder = Color(hex: 0xE4E4E7)
    public static let composerBorderFocused = Color(hex: 0xA1A1AA)
    public static let composerBg = Color(hex: 0xFFFFFF)
    public static let sendBtnBg = Color(hex: 0xF4F4F5)
    public static let presetBorder = Color(hex: 0xD4D4D8)
    public static let presetText = Color(hex: 0x3F3F46)
    public static let presetBg = Color.clear
    public static let footerBg = Color(hex: 0xF7F9FB)
    public static let footerText = Color(hex: 0x71717A)
    public static let onlineBadgeBg = Color(hex: 0xECFDF5)       // emerald-50
    public static let onlineBadgeBorder = Color(hex: 0xA7F3D0)   // emerald-200
    public static let onlineDot = Color(hex: 0x10B981)           // emerald-500
    public static let onlineText = Color(hex: 0x047857)          // emerald-700
    public static let errorRed = Color(hex: 0xEF4444)
    public static let destructive = Color(hex: 0xEF4444)
}

/// Dark mode color tokens — exact hex values from the RN SDK.
public enum DarkColors {
    public static let background = Color(hex: 0x14161A)
    public static let foreground = Color(hex: 0xF1F1F0)
    public static let surface = Color(hex: 0x2C2D31)
    public static let surfaceVariant = Color(hex: 0x3F3F46)
    public static let border = Color(hex: 0x3F3F46)
    public static let borderWarm = Color(hex: 0x52525B)
    public static let muted = Color(hex: 0x27272A)
    public static let mutedForeground = Color(hex: 0xA1A1AA)
    public static let botBubble = Color(hex: 0x2C2D31)
    public static let botBubbleForeground = Color(hex: 0xF1F1F0)
    public static let systemMessage = Color(hex: 0x27272A)
    public static let systemMessageForeground = Color(hex: 0xA1A1AA)
    public static let introCard = Color(hex: 0x1E1F23)
    public static let introCardBorder = Color(hex: 0x3F3F46)
    public static let formCardBg = Color(hex: 0x1E1F23)
    public static let inputBorder = Color(hex: 0x3F3F46)
    public static let inputBorderFocused = Color(hex: 0x52525B)
    public static let composerBorder = Color(hex: 0x3F3F46)
    public static let composerBorderFocused = Color(hex: 0x52525B)
    public static let composerBg = Color(hex: 0x1E1F23)
    public static let sendBtnBg = Color(hex: 0x3F3F46)
    public static let presetBorder = Color(hex: 0x3F3F46)
    public static let presetText = Color(hex: 0xD4D4D8)
    public static let presetBg = Color.clear
    public static let footerBg = Color(hex: 0x18181B)
    public static let footerText = Color(hex: 0xA1A1AA)
    public static let onlineBadgeBg = Color(hex: 0x10B981, opacity: 0.15)    // emerald-500 @ 15%
    public static let onlineBadgeBorder = Color(hex: 0x34D399, opacity: 0.30) // emerald-400 @ 30%
    public static let onlineDot = Color(hex: 0x10B981)                        // emerald-500
    public static let onlineText = Color(hex: 0xA7F3D0)                       // emerald-200
    public static let errorRed = Color(hex: 0xEF4444)
    public static let destructive = Color(hex: 0xEF4444)
}

// MARK: - Color Extension

extension Color {
    init(hex: Int, opacity: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
