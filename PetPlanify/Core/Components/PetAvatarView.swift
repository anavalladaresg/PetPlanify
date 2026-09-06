import SwiftUI

struct PetAvatarView: View {
    var size: CGFloat = 44
    var photoURL: URL?
    var imageData: Data?
    @State private var storedData: Data?
    var body: some View {
        ZStack {
            Circle().fill(AppTheme.greenSoft)
            if let image = platformImage {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "dog.fill")
                    .font(.system(size: size * 0.46, weight: .medium))
                    .foregroundStyle(AppTheme.green)
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
        .accessibilityHidden(true)
        .task(id: photoURL) {
            guard let photoURL else { storedData = nil; return }
            storedData = await Task.detached(priority: .utility) { try? Data(contentsOf: photoURL) }.value
        }
    }
    private var platformImage: Image? {
        guard let data = imageData ?? storedData else { return nil }
        #if os(macOS)
        return NSImage(data: data).map { Image(nsImage: $0) }
        #else
        return UIImage(data: data).map { Image(uiImage: $0) }
        #endif
    }
}
