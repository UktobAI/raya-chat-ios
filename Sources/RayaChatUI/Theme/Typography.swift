import SwiftUI

/// Typography tokens matching the RN SDK.
public enum RayaTypography {
    public static let heading = Font.system(size: 24, weight: .semibold)
    public static let subheading = Font.system(size: 16, weight: .semibold)
    public static let body = Font.system(size: 14, weight: .regular)
    public static let bodyBold = Font.system(size: 14, weight: .semibold)
    public static let caption = Font.system(size: 12, weight: .regular)
    public static let captionBold = Font.system(size: 12, weight: .semibold)
    public static let input = Font.system(size: 15, weight: .regular)
    public static let buttonSmall = Font.system(size: 13, weight: .medium)
    public static let tiny = Font.system(size: 10, weight: .regular)
}
