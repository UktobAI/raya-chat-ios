import SwiftUI
import RayaChatCore

/// Image preview grid above the composer — dynamic sizing capped at 80dp, matches RN SDK.
struct ImagePickerPreview: View {
    let images: [ImageAsset]
    let onRemove: (Int) -> Void

    var body: some View {
        if images.isEmpty { return AnyView(EmptyView()) }

        return AnyView(
            GeometryReader { geo in
                let count = images.count
                let gap: CGFloat = 8
                let padding: CGFloat = 32
                let available = geo.size.width - padding
                let calculated = (available - gap * CGFloat(count - 1)) / CGFloat(count)
                let thumbSize = min(calculated, 80)

                HStack(spacing: gap) {
                    ForEach(Array(images.enumerated()), id: \.offset) { index, img in
                        ZStack(alignment: .topTrailing) {
                            // Thumbnail
                            AsyncImage(url: URL(string: img.uri)) { image in
                                image.resizable().scaledToFill()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: 0xF4F4F5))
                            }
                            .frame(width: thumbSize, height: thumbSize)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                            // X close button — white circle with dark border
                            Button(action: { onRemove(index) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(Color(hex: 0x333333))
                                    .frame(width: 22, height: 22)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color(hex: 0x333333), lineWidth: 1.5))
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }
                            .offset(x: 6, y: -6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
            }
            .frame(height: 100)
        )
    }
}
