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

/// Lucide Send icon — matches Android RayaIcons.send path exactly.
struct LucideSendIcon: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 24
        let sy = rect.height / 24
        var p = Path()
        // Lucide Send: m22 2-7 20-4-9-9-4Z
        p.move(to: CGPoint(x: 22 * sx, y: 2 * sy))
        p.addLine(to: CGPoint(x: 15 * sx, y: 22 * sy))
        p.addLine(to: CGPoint(x: 11 * sx, y: 13 * sy))
        p.addLine(to: CGPoint(x: 2 * sx, y: 9 * sy))
        p.closeSubpath()
        return p
    }
}
