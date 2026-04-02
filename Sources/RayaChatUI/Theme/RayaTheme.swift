import SwiftUI
import RayaChatCore

/// Resolved theme — all colors, typography, and layout direction computed from bot config.
public struct RayaTheme {
    public let isDark: Bool
    public let isRTL: Bool
    public let locale: String
    public let gradientColor: Color
    public let gradientForeground: Color

    public let background, foreground, surface, surfaceVariant: Color
    public let border, borderWarm, muted, mutedForeground: Color
    public let botBubble, botBubbleForeground: Color
    public let systemMessage, systemMessageForeground: Color
    public let introCard, introCardBorder: Color
    public let formCardBg, inputBorder, inputBorderFocused: Color
    public let composerBorder, composerBorderFocused, composerBg, sendBtnBg: Color
    public let presetBorder, presetText, presetBg: Color
    public let footerBg, footerText: Color
    public let onlineBadgeBg, onlineBadgeBorder, onlineDot, onlineText: Color
    public let errorRed, destructive: Color

    public static func create(isDark: Bool, isRTL: Bool, locale: String, gradientColor: Color, gradientForeground: Color) -> RayaTheme {
        isDark
            ? createDark(isRTL: isRTL, locale: locale, gradientColor: gradientColor, gradientForeground: gradientForeground)
            : createLight(isRTL: isRTL, locale: locale, gradientColor: gradientColor, gradientForeground: gradientForeground)
    }

    private static func createLight(isRTL: Bool, locale: String, gradientColor: Color, gradientForeground: Color) -> RayaTheme {
        RayaTheme(
            isDark: false, isRTL: isRTL, locale: locale, gradientColor: gradientColor, gradientForeground: gradientForeground,
            background: LightColors.background, foreground: LightColors.foreground,
            surface: LightColors.surface, surfaceVariant: LightColors.surfaceVariant,
            border: LightColors.border, borderWarm: LightColors.borderWarm,
            muted: LightColors.muted, mutedForeground: LightColors.mutedForeground,
            botBubble: LightColors.botBubble, botBubbleForeground: LightColors.botBubbleForeground,
            systemMessage: LightColors.systemMessage, systemMessageForeground: LightColors.systemMessageForeground,
            introCard: LightColors.introCard, introCardBorder: LightColors.introCardBorder,
            formCardBg: LightColors.formCardBg, inputBorder: LightColors.inputBorder, inputBorderFocused: LightColors.inputBorderFocused,
            composerBorder: LightColors.composerBorder, composerBorderFocused: LightColors.composerBorderFocused,
            composerBg: LightColors.composerBg, sendBtnBg: LightColors.sendBtnBg,
            presetBorder: LightColors.presetBorder, presetText: LightColors.presetText, presetBg: LightColors.presetBg,
            footerBg: LightColors.footerBg, footerText: LightColors.footerText,
            onlineBadgeBg: LightColors.onlineBadgeBg, onlineBadgeBorder: LightColors.onlineBadgeBorder,
            onlineDot: LightColors.onlineDot, onlineText: LightColors.onlineText,
            errorRed: LightColors.errorRed, destructive: LightColors.destructive
        )
    }

    private static func createDark(isRTL: Bool, locale: String, gradientColor: Color, gradientForeground: Color) -> RayaTheme {
        RayaTheme(
            isDark: true, isRTL: isRTL, locale: locale, gradientColor: gradientColor, gradientForeground: gradientForeground,
            background: DarkColors.background, foreground: DarkColors.foreground,
            surface: DarkColors.surface, surfaceVariant: DarkColors.surfaceVariant,
            border: DarkColors.border, borderWarm: DarkColors.borderWarm,
            muted: DarkColors.muted, mutedForeground: DarkColors.mutedForeground,
            botBubble: DarkColors.botBubble, botBubbleForeground: DarkColors.botBubbleForeground,
            systemMessage: DarkColors.systemMessage, systemMessageForeground: DarkColors.systemMessageForeground,
            introCard: DarkColors.introCard, introCardBorder: DarkColors.introCardBorder,
            formCardBg: DarkColors.formCardBg, inputBorder: DarkColors.inputBorder, inputBorderFocused: DarkColors.inputBorderFocused,
            composerBorder: DarkColors.composerBorder, composerBorderFocused: DarkColors.composerBorderFocused,
            composerBg: DarkColors.composerBg, sendBtnBg: DarkColors.sendBtnBg,
            presetBorder: DarkColors.presetBorder, presetText: DarkColors.presetText, presetBg: DarkColors.presetBg,
            footerBg: DarkColors.footerBg, footerText: DarkColors.footerText,
            onlineBadgeBg: DarkColors.onlineBadgeBg, onlineBadgeBorder: DarkColors.onlineBadgeBorder,
            onlineDot: DarkColors.onlineDot, onlineText: DarkColors.onlineText,
            errorRed: DarkColors.errorRed, destructive: DarkColors.destructive
        )
    }
}

// MARK: - Environment Key

struct RayaThemeKey: EnvironmentKey {
    static let defaultValue = RayaTheme.create(
        isDark: false, isRTL: false, locale: "en",
        gradientColor: Color(hex: 0x0047AF), gradientForeground: .white
    )
}

extension EnvironmentValues {
    var rayaTheme: RayaTheme {
        get { self[RayaThemeKey.self] }
        set { self[RayaThemeKey.self] = newValue }
    }
}

/// Provides the theme to all child views.
public func rayaThemeFrom(botConfig: BotConfigProps, locale: String) -> RayaTheme {
    let isDark = botConfig.theme == "dark"
    let isRTL = isRTLLocale(locale)
    let gradientHex = botConfig.chatboxGradientColor ?? "#0047AF"
    let gradientInt = parseHexColor(gradientHex) ?? 0x0047AF
    let gradientColor = Color(hex: gradientInt)
    let isGradientDark = isDarkColor(gradientHex)
    let gradientForeground: Color = isGradientDark ? .white : Color(hex: 0x1A1A1A)

    return RayaTheme.create(isDark: isDark, isRTL: isRTL, locale: locale, gradientColor: gradientColor, gradientForeground: gradientForeground)
}
