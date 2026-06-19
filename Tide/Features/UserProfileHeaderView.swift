import SwiftUI

/// Заголовок профиля пользователя с логотипом верификации для верифицированных аккаунтов.
@available(iOS 17.0, *)
struct UserProfileHeaderView: View {
    let user: User
    let isVerified: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(user.displayName)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                
                if isVerified {
                    VerificationBadge()
                }
                
                Spacer()
            }
            
            if isVerified {
                Text("Account verified")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

@available(iOS 17.0, *)
private struct VerificationBadge: View {
    var body: some View {
        Image("verified_badge")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
            .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    @Previewable @State var previewUser = User(
        id: UUID(),
        displayName: "Pavel Durov",
        username: "durov",
        biography: "Founder of Telegram",
        avatarURL: nil,
        coverImageURL: nil,
        followerCount: 1000000,
        followingCount: 100,
        createdAt: Date()
    )
    
    UserProfileHeaderView(user: previewUser, isVerified: true)
        .background(Color.black)
}
