import SwiftUI

/// Экран входа по Email в стиле Apple 2026.
/// Использует стандарты ios-dev-plugin: Liquid Glass UI и декомпозицию View.
@available(iOS 17.0, *)
struct EmailLoginView: View {
    // MARK: - Environment
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @Namespace private var glassNamespace
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HeaderSection(dismiss: dismiss)
                    .padding(.bottom, 40)
                
                InputSection(email: $email, password: $password, isPasswordVisible: $isPasswordVisible)
                    .padding(.bottom, 24)
                
                ForgotPasswordSection()
                    .padding(.bottom, 40)
                
                SignInButtonSection(action: handleSignIn)
                    .padding(.bottom, 48)
                
                SocialSection(namespace: glassNamespace)
                
                Spacer()
                
                FooterSection()
            }
            .padding(.horizontal, 28)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Actions
    private func handleSignIn() {
        Task {
            await dependencies.session.signInEmail(email: email, password: password)
        }
    }
}

// MARK: - Subviews

@available(iOS 17.0, *)
private struct HeaderSection: View {
    let dismiss: DismissAction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome back")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Sign in to continue")
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 20)
    }
}

@available(iOS 17.0, *)
private struct InputSection: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isPasswordVisible: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            InputField(title: "Email", text: $email, icon: "envelope", isSecure: false, isVisible: .constant(true))
            InputField(title: "Password", text: $password, icon: "lock", isSecure: true, isVisible: $isPasswordVisible)
        }
    }
}

@available(iOS 17.0, *)
private struct InputField: View {
    let title: String
    @Binding var text: String
    let icon: String
    let isSecure: Bool
    @Binding var isVisible: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
            
            HStack {
                if isSecure && !isVisible {
                    SecureField("name@example.com", text: $text)
                } else {
                    TextField("name@example.com", text: $text)
                }
                
                Spacer()
                
                if isSecure {
                    Button(action: { isVisible.toggle() }) {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                            .foregroundColor(.gray)
                    }
                } else {
                    Image(systemName: "mail")
                        .foregroundColor(.gray)
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color(white: 0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(white: 0.15), lineWidth: 1)
            )
        }
    }
}

@available(iOS 17.0, *)
private struct ForgotPasswordSection: View {
    var body: some View {
        HStack {
            Spacer()
            Button("Forgot password?") { }
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
    }
}

@available(iOS 17.0, *)
private struct SignInButtonSection: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("Sign in")
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
                Image(systemName: "arrow.right")
            }
            .foregroundColor(.black)
            .padding(.horizontal, 24)
            .frame(height: 52)
            .background(Color.white)
            .cornerRadius(12)
        }
    }
}

@available(iOS 17.0, *)
private struct SocialSection: View {
    let namespace: Namespace.ID
    
    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Rectangle().fill(Color(white: 0.15)).frame(height: 0.5)
                Text("or continue with").font(.system(size: 14)).foregroundColor(.gray).padding(.horizontal, 8)
                Rectangle().fill(Color(white: 0.15)).frame(height: 0.5)
            }
            
            HStack(spacing: 20) {
                SocialCircleButton(icon: .github)
                SocialCircleButton(icon: .google)
                SocialCircleButton(icon: .apple)
            }
        }
    }
}

enum SocialBrand {
    case google, github, apple
}

@available(iOS 17.0, *)
private struct SocialCircleButton: View {
    let icon: SocialBrand
    
    var body: some View {
        Button(action: {}) {
            BrandIcon(brand: icon)
                .frame(width: 24, height: 24)
                .frame(width: 54, height: 54)
                .background(Color(white: 0.1))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(white: 0.2), lineWidth: 0.5))
        }
    }
}

@available(iOS 17.0, *)
private struct BrandIcon: View {
    let brand: SocialBrand
    
    var body: some View {
        Group {
            switch brand {
            case .google:
                SVGRemoteView(url: Bundle.main.url(forResource: "google_logo", withExtension: "svg")!)
            case .github:
                SVGRemoteView(url: Bundle.main.url(forResource: "github_logo", withExtension: "svg")!)
            case .apple:
                SVGRemoteView(url: Bundle.main.url(forResource: "apple_logo", withExtension: "svg")!)
            }
        }
    }
}

@available(iOS 17.0, *)
private struct FooterSection: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("No account?")
                .foregroundColor(.gray)
            Button("Sign up") { }
                .foregroundColor(.white)
                .fontWeight(.semibold)
        }
        .font(.system(size: 14))
        .padding(.bottom, 32)
    }
}
