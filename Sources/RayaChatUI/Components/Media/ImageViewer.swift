import SwiftUI

/// Full-screen image viewer overlay with close button.
struct ImageViewer: View {
    let imageUri: String?
    var onClose: () -> Void

    var body: some View {
        if let uri = imageUri, let url = URL(string: uri) {
            ZStack(alignment: .topTrailing) {
                Color.black.ignoresSafeArea()

                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                    default:
                        ProgressView()
                            .tint(.white)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Close button
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                .padding(.top, 60)
                .padding(.trailing, 20)
            }
            .transition(.opacity)
        }
    }
}
