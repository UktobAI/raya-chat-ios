import SwiftUI

/// Returns text alignment based on RTL state.
func textAlign(_ isRTL: Bool) -> TextAlignment {
    isRTL ? .trailing : .leading
}

/// Returns horizontal alignment based on RTL state.
func horizontalAlign(_ isRTL: Bool) -> HorizontalAlignment {
    isRTL ? .trailing : .leading
}

/// Returns layout direction for the environment.
func layoutDirection(_ isRTL: Bool) -> LayoutDirection {
    isRTL ? .rightToLeft : .leftToRight
}
