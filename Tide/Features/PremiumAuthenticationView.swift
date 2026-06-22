import AuthenticationServices
import SwiftUI

struct PremiumAuthenticationView: View {
    @Environment(AppDependencies.self) private var dependencies
    @FocusState private var focusedField: Field?
    @State private var stage: AuthStage = .landing
    @State private var identifier = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var showProviderSheet = false

    private enum AuthStage { case landing, username, email }
    private enum Field { case identifier, email }

    var body: some View {
        ZStack {
            AuthBlackBackdrop()

            Group {
                switch stage {
                case .landing: landingScreen
                case .username: usernameScreen
                case .email: emailScreen
                }
            }
            .padding(.horizontal, 28)
            .animation(.easeInOut(duration: 0.25), value: stage)
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .alert("Вход", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showProviderSheet) {
            providerSheet
                .presentationDetents([.height(420)])
                .presentationDragIndicator(.visible)
                .presentationBackground(.black)
                .preferredColorScheme(.dark)
        }
    }

    private var landingScreen: some View {
        VStack(spacing: 0) {
            topBackButton
                .opacity(0.9)
                .padding(.top, 56)

            Spacer(minLength: 190)

            AuthChromeLogo(size: 78)
                .padding(.bottom, 26)

            Text("Создать аккаунт")
                .font(.system(size: 39, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
                .multilineTextAlignment(.center)

            Spacer(minLength: 126)

            HStack(spacing: 28) {
                AuthSocialGlassButton(kind: .google, imageName: "GoogleLogo", shape: .circle) {
                    showProviderSheet = true
                }
                AppleAuthGlassButton(shape: .circle) { result in
                    handleAppleSignIn(result)
                }
                AuthCircleIconButton(systemImage: "envelope") { showEmail() }
            }

            AuthDivider(title: "или")
                .padding(.top, 28)

            Button {
                setPlaceholder("Вход по телефону пока работает как заглушка.")
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "phone")
                        .font(.system(size: 20, weight: .heavy))
                    Text("Создать аккаунт по номеру телефона")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.82)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 66)
                .padding(.horizontal, 8)
                .background(.white, in: Capsule())
            }
            .padding(.top, 22)

            Text("Продолжая, ты соглашаешься с нашими\nУсловиями, Политикой конфиденциальности и\nПолитикой использования файлов cookie.")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 24)

            Button { showUsername() } label: {
                Text("Войти с именем пользователя")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.44))
            }
            .padding(.top, 18)
            .padding(.bottom, 22)
        }
    }

    private var usernameScreen: some View {
        VStack(spacing: 0) {
            authTopBar(trailing: "Утеряно имя пользователя")
                .padding(.top, 56)

            VStack(alignment: .leading, spacing: 32) {
                Text("Введи имя\nпользователя")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(7)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("@")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    TextField("имя пользователя", text: $identifier)
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tint(.white)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .identifier)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 76)

            Spacer()

            primaryAuthButton(title: "Продолжить", enabled: canContinueUsername, action: submitUsername)
                .padding(.bottom, 42)
        }
    }

    private var emailScreen: some View {
        VStack(spacing: 0) {
            authTopBar(trailing: "Указать номер телефона")
                .padding(.top, 56)

            VStack(alignment: .leading, spacing: 20) {
                Text("Укажите свой\nадрес эл. почты")
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .lineSpacing(7)
                Text("Мы отправим тебе код подтверждения")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.42))
                TextField("tom@example.com", text: $email)
                    .font(.system(size: 33, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .tint(.white)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focusedField, equals: .email)
                    .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 76)

            Spacer()

            primaryAuthButton(title: "Продолжить", enabled: canContinueEmail, action: submitEmail)

            Text("Продолжая, ты соглашаешься получать\nслужебные уведомления об аккаунте.")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(.white.opacity(0.42))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 22)
                .padding(.bottom, 42)
        }
    }

    private var providerSheet: some View {
        VStack(spacing: 18) {
            Text("Войди в свою учётную запись")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 28)

            AuthProviderPill(imageName: "GoogleLogo", title: "Продолжить с Google") {
                setPlaceholder("Вход через Google пока работает как заглушка.")
            }
            AuthProviderPill(systemImage: "apple.logo", title: "Продолжить с Apple") {
                showProviderSheet = false
                alertMessage = "Нажми кнопку Apple на главном экране."
            }
            AuthProviderPill(systemImage: "envelope", title: "Продолжить с электронной почтой") {
                showProviderSheet = false
                showEmail()
            }
            AuthProviderPill(systemImage: "phone", title: "Продолжить с телефоном") {
                setPlaceholder("Вход по телефону пока работает как заглушка.")
            }

            Spacer()
        }
        .padding(.horizontal, 34)
        .background(Color.black.ignoresSafeArea())
    }

    private var topBackButton: some View {
        HStack {
            Button {
                setPlaceholder("Вернуться назад сейчас некуда.")
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private func authTopBar(trailing: String) -> some View {
        HStack(alignment: .top) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) { stage = .landing }
            } label: {
                Image(systemName: "arrow.left")
                    .font(.system(size: 31, weight: .bold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                setPlaceholder("Восстановление аккаунта появится позже.")
            } label: {
                Text(trailing)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    private func primaryAuthButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 23, weight: .black, design: .rounded))
                .foregroundStyle(enabled ? .black : .white.opacity(0.34))
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .background(enabled ? .white : .white.opacity(0.14), in: Capsule())
        }
        .disabled(!enabled || isLoading)
    }

    private var canContinueUsername: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canContinueEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    private func showUsername() {
        withAnimation(.easeInOut(duration: 0.25)) { stage = .username }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            focusedField = .identifier
        }
    }

    private func showEmail() {
        withAnimation(.easeInOut(duration: 0.25)) { stage = .email }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            focusedField = .email
        }
    }

    private func submitUsername() {
        guard canContinueUsername else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            await dependencies.session.signInIdentifier(identifier, password: "Sy3uki90.")
        }
    }

    private func submitEmail() {
        guard canContinueEmail else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            await dependencies.session.signInEmail(email: email, password: "TidePreview2026", createsAccount: true)
        }
    }

    private func setPlaceholder(_ message: String) {
        alertMessage = message
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        Task {
            switch result {
            case .success(let authorization):
                guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                    alertMessage = "Apple не вернул данные аккаунта."
                    return
                }
                let fallbackEmail = credential.email ?? "\(credential.user)@apple.local"
                let name = [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " ")
                await dependencies.session.signInApple(
                    userIdentifier: credential.user,
                    email: fallbackEmail,
                    displayName: name.isEmpty ? nil : name
                )
            case .failure(let error):
                alertMessage = error.localizedDescription
            }
        }
    }
}

struct AuthProfileSetupView: View {
    @Environment(AppDependencies.self) private var dependencies
    @FocusState private var focusedField: Field?
    @State private var step: Step = .name
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var username = ""

    private enum Step { case name, username }
    private enum Field { case firstName, lastName, username }

    var body: some View {
        ZStack {
            AuthBlackBackdrop()

            VStack(spacing: 0) {
                Spacer()

                AuthChromeLogo(size: 92)
                    .padding(.bottom, 28)

                VStack(spacing: 8) {
                    Text(step == .name ? "Заполни имя" : "Выбери имя пользователя")
                        .font(.system(size: 29, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text(step == .name ? "Так тебя увидят в приложении." : "По нему тебя будут находить.")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.48))
                }
                .padding(.bottom, 30)

                if step == .name {
                    VStack(spacing: 14) {
                        AuthInputField(placeholder: "Имя", text: $firstName, icon: "person", isSecure: false, isVisible: .constant(true))
                            .focused($focusedField, equals: .firstName)
                        AuthInputField(placeholder: "Фамилия", text: $lastName, icon: "person.text.rectangle", isSecure: false, isVisible: .constant(true))
                            .focused($focusedField, equals: .lastName)
                    }
                } else {
                    AuthInputField(placeholder: "Имя пользователя", text: $username, icon: "at", isSecure: false, isVisible: .constant(true))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .username)
                }

                Button(action: continueSetup) {
                    Text(step == .name ? "Продолжить" : "Войти в приложение")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(width: 154, height: 48)
                        .background(.white, in: Capsule())
                        .shadow(color: .white.opacity(0.18), radius: 18, y: 8)
                }
                .padding(.top, 28)

                Spacer()

                if dependencies.session.currentUser?.isVerified == true {
                    HStack(spacing: 8) {
                        TideBrandLogoView(size: 18, style: .circle)
                        Text("аккаунт верифицирован")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundStyle(.white.opacity(0.48))
                    .padding(.bottom, 34)
                }
            }
            .padding(.horizontal, 28)
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea()
        .onAppear {
            let user = dependencies.session.currentUser
            let parts = (user?.name ?? "").split(separator: " ", maxSplits: 1).map(String.init)
            firstName = parts.first ?? ""
            lastName = parts.dropFirst().first ?? ""
            username = user?.username ?? ""
            focusedField = .firstName
        }
    }

    private func continueSetup() {
        switch step {
        case .name:
            withAnimation(.easeInOut(duration: 0.25)) {
                step = .username
                focusedField = .username
            }
        case .username:
            let fullName = [firstName, lastName]
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            dependencies.session.completeProfileSetup(name: fullName, username: username)
            dependencies.router.selectedTab = .chats
        }
    }
}

struct AuthBlackBackdrop: View {
    var body: some View {
        ZStack {
            Color.black
            LinearGradient(
                colors: [.black, .white.opacity(0.05), .black, .white.opacity(0.03)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 30)
            .opacity(0.9)
        }
    }
}

struct AuthChromeLogo: View {
    let size: CGFloat

    var body: some View {
        Image("TideBubbleLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(color: .white.opacity(0.18), radius: 24, y: 4)
            .accessibilityLabel("Tide")
    }
}

struct AuthDivider: View {
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(.white.opacity(0.13)).frame(height: 0.7)
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.38))
            Rectangle().fill(.white.opacity(0.13)).frame(height: 0.7)
        }
    }
}

struct AuthInputField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let isSecure: Bool
    @Binding var isVisible: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if isSecure && !isVisible {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(.white)
            .tint(.white)

            Button {
                if isSecure { isVisible.toggle() }
            } label: {
                Image(systemName: isSecure ? (isVisible ? "eye.slash" : icon) : icon)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.44))
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .disabled(!isSecure)
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background(AuthGlassBackground(cornerRadius: 18, interactive: true))
    }
}

struct AuthSocialGlassButton: View {
    enum Kind { case github, google }
    enum ShapeMode { case roundedSquare, circle }

    let kind: Kind
    let imageName: String
    var shape: ShapeMode = .roundedSquare
    let action: () -> Void

    private var size: CGFloat { shape == .circle ? 58 : 54 }
    private var cornerRadius: CGFloat { shape == .circle ? 29 : 17 }

    var body: some View {
        Button(action: action) {
            ZStack {
                AuthGlassBackground(cornerRadius: cornerRadius, interactive: true)
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size * 0.4, height: size * 0.4)
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

struct AppleAuthGlassButton: View {
    enum ShapeMode { case roundedSquare, circle }

    var shape: ShapeMode = .roundedSquare
    let completion: (Result<ASAuthorization, Error>) -> Void

    private var size: CGFloat { shape == .circle ? 58 : 54 }
    private var cornerRadius: CGFloat { shape == .circle ? 29 : 17 }

    var body: some View {
        Group {
            if shape == .circle {
                content.contentShape(Circle())
            } else {
                content.contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
        }
        .buttonStyle(.plain)
    }

    private var content: some View {
        ZStack {
            AuthGlassBackground(cornerRadius: cornerRadius, interactive: true)
            Image(systemName: "apple.logo")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                completion(result)
            }
            .opacity(0.001)
            .allowsHitTesting(true)
        }
    }
}

struct AuthCircleIconButton: View {
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                AuthGlassBackground(cornerRadius: 29, interactive: true)
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
            }
            .frame(width: 58, height: 58)
        }
        .buttonStyle(.plain)
    }
}

struct AuthProviderPill: View {
    let imageName: String?
    let systemImage: String?
    let title: String
    let action: () -> Void

    init(imageName: String? = nil, systemImage: String? = nil, title: String, action: @escaping () -> Void) {
        self.imageName = imageName
        self.systemImage = systemImage
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 21, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(AuthGlassBackground(cornerRadius: 20, interactive: true))
        }
        .buttonStyle(.plain)
    }
}

struct AuthGlassBackground: View {
    let cornerRadius: CGFloat
    let interactive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.white.opacity(interactive ? 0.08 : 0.06))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(.white.opacity(interactive ? 0.16 : 0.12), lineWidth: 1)
            }
            .shadow(color: .black.opacity(interactive ? 0.35 : 0.22), radius: 24, y: 10)
    }
}
