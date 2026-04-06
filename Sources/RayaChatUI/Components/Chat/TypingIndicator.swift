import SwiftUI

/// Three animated dots in a bot bubble — matches Android 800ms keyframe cycle.
/// Each dot bounces up (-6pt) then back down, staggered by 150ms.
struct TypingIndicator: View {
    let botIcon: String?

    @Environment(\.rayaTheme) private var theme

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // Bot avatar
            if let url = botIcon.flatMap({ $0.isEmpty ? nil : $0 }), let imageUrl = URL(string: url) {
                AsyncImage(url: imageUrl) { image in
                    image.resizable().scaledToFit()
                } placeholder: {
                    Circle().fill(theme.botBubble)
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            }

            // Dots bubble — TimelineView drives 800ms keyframe cycle
            TimelineView(.animation) { timeline in
                let phase = timeline.date.timeIntervalSinceReferenceDate
                    .truncatingRemainder(dividingBy: 0.8)
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .fill(theme.mutedForeground)
                            .frame(width: 6, height: 6)
                            .offset(y: Self.dotOffset(phase: phase, stagger: Double(index) * 0.15))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(theme.botBubble)
            .clipShape(RoundedCorner(tl: 16, tr: 16, bl: 4, br: 16))

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    /// Matches Android keyframe: bounce up (-6) in 200ms, back down in 200ms, idle rest of cycle.
    private static func dotOffset(phase: Double, stagger: Double) -> CGFloat {
        let local = phase - stagger
        guard local > 0, local < 0.4 else { return 0 }
        let t = local < 0.2 ? (local / 0.2) : (1.0 - (local - 0.2) / 0.2)
        let eased = (1.0 - cos(t * .pi)) / 2.0
        return CGFloat(-6.0 * eased)
    }
}

/// Custom rounded corner shape for asymmetric bubbles.
struct RoundedCorner: Shape {
    var tl: CGFloat = 0
    var tr: CGFloat = 0
    var bl: CGFloat = 0
    var br: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width, h = rect.height

        path.move(to: CGPoint(x: tl, y: 0))
        path.addLine(to: CGPoint(x: w - tr, y: 0))
        path.addArc(tangent1End: CGPoint(x: w, y: 0), tangent2End: CGPoint(x: w, y: tr), radius: tr)
        path.addLine(to: CGPoint(x: w, y: h - br))
        path.addArc(tangent1End: CGPoint(x: w, y: h), tangent2End: CGPoint(x: w - br, y: h), radius: br)
        path.addLine(to: CGPoint(x: bl, y: h))
        path.addArc(tangent1End: CGPoint(x: 0, y: h), tangent2End: CGPoint(x: 0, y: h - bl), radius: bl)
        path.addLine(to: CGPoint(x: 0, y: tl))
        path.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: tl, y: 0), radius: tl)

        return path
    }
}
