import SwiftUI

struct PetAvatarView: View {
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.greenSoft)
            Image(systemName: "dog.fill")
                .font(.system(size: size * 0.46, weight: .medium))
                .foregroundStyle(AppTheme.green)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

