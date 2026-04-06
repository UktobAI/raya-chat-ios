import SwiftUI

/// SDK icons — uses SF Symbols where possible, custom shapes where needed.
public enum RayaIcons {
    public static let send = Image(systemName: "paperplane.fill")
    public static let paperclip = Image(systemName: "paperclip")
    public static let mic = Image(systemName: "mic.fill")
    public static let smile = Image(systemName: "face.smiling")
    public static let close = Image(systemName: "xmark")
    public static let chevronLeft = Image(systemName: "chevron.left")
    public static let chevronDown = Image(systemName: "chevron.down")
    public static let user = Image(systemName: "person.fill")
    public static let play = Image(systemName: "play.fill")
    public static let pause = Image(systemName: "pause.fill")
    public static let trash = Image(systemName: "trash")
    public static let photo = Image(systemName: "photo")
    public static let arrowDown = Image(systemName: "arrow.down")
    public static let exclamation = Image(systemName: "exclamationmark.triangle")
}

/// Lucide Send icon with fold line — matches Android RayaIcons.send.
/// Uses even-odd fill: outer quad + inner parallelogram cutout for the fold.
struct LucideSendIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24
        let sy = rect.height / 24
        var p = Path()

        // Outer paper airplane: (22,2)→(15,22)→(11,13)→(2,9)
        p.move(to: CGPoint(x: 22 * sx, y: 2 * sy))
        p.addLine(to: CGPoint(x: 15 * sx, y: 22 * sy))
        p.addLine(to: CGPoint(x: 11 * sx, y: 13 * sy))
        p.addLine(to: CGPoint(x: 2 * sx, y: 9 * sy))
        p.closeSubpath()

        // Fold cutout — thin parallelogram from tip (22,2) to center (11,13)
        let g: CGFloat = 0.55
        let n = g / CGFloat(2).squareRoot() // perpendicular offset
        p.move(to: CGPoint(x: (22 + n) * sx, y: (2 + n) * sy))
        p.addLine(to: CGPoint(x: (11 + n) * sx, y: (13 + n) * sy))
        p.addLine(to: CGPoint(x: (11 - n) * sx, y: (13 - n) * sy))
        p.addLine(to: CGPoint(x: (22 - n) * sx, y: (2 - n) * sy))
        p.closeSubpath()

        return p
    }
}
