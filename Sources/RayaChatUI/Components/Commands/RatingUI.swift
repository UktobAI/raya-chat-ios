import SwiftUI
import RayaChatCore

/// 5 rating face icons in a bot bubble — matches Android RatingUI.kt exactly.
/// Drawn faces (circle + eyes + mouth), NOT emoji.
struct RatingUI: View {
    let message: String
    let options: [AnyCodable]
    let botIcon: String?
    let locale: String
    var onRate: (Int) -> Void

    @State private var selected: Int = 0
    @Environment(\.rayaTheme) private var theme

    private struct RatingItem {
        let value: Int; let label: String; let labelAr: String; let color: Color
    }

    private let ratings: [RatingItem] = [
        RatingItem(value: 1, label: "Very Bad", labelAr: "سيء جدًا", color: Color(hex: 0xEF4444)),
        RatingItem(value: 2, label: "Bad", labelAr: "سيء", color: Color(hex: 0xF97316)),
        RatingItem(value: 3, label: "Okay", labelAr: "مقبول", color: Color(hex: 0xEAB308)),
        RatingItem(value: 4, label: "Good", labelAr: "جيد", color: Color(hex: 0x84CC16)),
        RatingItem(value: 5, label: "Excellent", labelAr: "ممتاز", color: Color(hex: 0x22C55E)),
    ]

    var body: some View {
        BotBubbleWrapper(botIcon: botIcon) {
            if !message.isEmpty {
                Text(message)
                    .font(RayaTypography.body)
                    .foregroundColor(theme.botBubbleForeground)
                    .padding(.bottom, 12)
            }

            // Filter ratings by option values (matches Android's value-based filtering)
            let isAr = locale.hasPrefix("ar")
            let filteredRatings = ratings.filter { r in
                options.contains { ($0.value as? Int) == r.value }
            }
            HStack(spacing: 0) {
                ForEach(filteredRatings, id: \.value) { item in
                    let isSelected = selected == item.value

                    Button {
                        selected = item.value
                        onRate(item.value)
                    } label: {
                        VStack(spacing: 4) {
                            FaceIcon(rating: item.value, color: item.color, isSelected: isSelected)
                                .frame(width: 32, height: 32)

                            if isSelected {
                                Text(isAr ? item.labelAr : item.label)
                                    .font(.system(size: 9, weight: .regular))
                                    .foregroundColor(item.color)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(isSelected ? item.color.opacity(0.1) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
    }
}

/// Drawn face icon matching Android's Canvas-drawn faces.
private struct FaceIcon: View {
    let rating: Int // 1-5
    let color: Color
    let isSelected: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2

            // Circle outline
            let circlePath = Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ))
            context.stroke(circlePath, with: .color(isSelected ? color : Color.gray.opacity(0.4)), lineWidth: 1.5)

            // Eyes — two small circles
            let eyeY = center.y - radius * 0.15
            let eyeSpacing = radius * 0.35
            let eyeRadius: CGFloat = 1.5

            let leftEye = Path(ellipseIn: CGRect(
                x: center.x - eyeSpacing - eyeRadius, y: eyeY - eyeRadius,
                width: eyeRadius * 2, height: eyeRadius * 2
            ))
            let rightEye = Path(ellipseIn: CGRect(
                x: center.x + eyeSpacing - eyeRadius, y: eyeY - eyeRadius,
                width: eyeRadius * 2, height: eyeRadius * 2
            ))
            let eyeColor: Color = isSelected ? color : .gray.opacity(0.5)
            context.fill(leftEye, with: .color(eyeColor))
            context.fill(rightEye, with: .color(eyeColor))

            // Mouth — varies by rating
            let mouthY = center.y + radius * 0.25
            let mouthWidth = radius * 0.5
            var mouthPath = Path()

            switch rating {
            case 1: // Strong frown
                mouthPath.addArc(center: CGPoint(x: center.x, y: mouthY + 6),
                    radius: mouthWidth, startAngle: .degrees(210), endAngle: .degrees(330), clockwise: false)
            case 2: // Slight frown
                mouthPath.addArc(center: CGPoint(x: center.x, y: mouthY + 4),
                    radius: mouthWidth * 0.8, startAngle: .degrees(215), endAngle: .degrees(325), clockwise: false)
            case 3: // Straight line
                mouthPath.move(to: CGPoint(x: center.x - mouthWidth * 0.6, y: mouthY))
                mouthPath.addLine(to: CGPoint(x: center.x + mouthWidth * 0.6, y: mouthY))
            case 4: // Slight smile
                mouthPath.addArc(center: CGPoint(x: center.x, y: mouthY - 4),
                    radius: mouthWidth * 0.8, startAngle: .degrees(35), endAngle: .degrees(145), clockwise: false)
            case 5: // Big smile
                mouthPath.addArc(center: CGPoint(x: center.x, y: mouthY - 6),
                    radius: mouthWidth, startAngle: .degrees(30), endAngle: .degrees(150), clockwise: false)
            default:
                break
            }
            context.stroke(mouthPath, with: .color(eyeColor), lineWidth: 1.5)
        }
    }
}
