import AuthenticationServices
import SwiftUI
import UIKit

struct AppRootView: View {
    @Environment(AppDependencies.self) private var dependencies

    var body: some View {
        if dependencies.session.isAuthenticated {
            MainTabView()
        } else {
            AuthenticationView()
        }
    }
}

struct MainTabView: View {
    @Environment(AppDependencies.self) private var dependencies

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
        UITabBar.appearance().itemPositioning = .automatic
        UITabBar.appearance().itemWidth = 72
        UITabBar.appearance().itemSpacing = 10
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        @Bindable var router = dependencies.router
        TabView(selection: $router.selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack(path: router.path(for: tab)) {
                    tabRoot(tab)
                        .navigationDestination(for: AppRoute.self, destination: destination)
                }
                .tabItem { Label(tab.title, systemImage: tab.symbol) }
                .tag(tab)
            }
        }
        .sheet(item: $router.sheet, content: sheet)
        .onOpenURL { router.handle($0) }
    }

    @ViewBuilder
    private func tabRoot(_ tab: AppTab) -> some View {
        switch tab {
        case .home: FeedView()
        case .chats: ChatListView()
        case .notifications: NotificationsView()
        case .profile:
            if let user = dependencies.session.currentUser {
                ProfileView(user: user)
            } else {
                EmptyStateView(symbol: "person.crop.circle", title: "profile_empty_title", message: "profile_empty_message")
            }
        }
    }

    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .post(let id): PostDetailView(postID: id)
        case .profile(let user): ProfileView(user: user)
        case .chat(let id): ConversationView(chatID: id)
        case .settings: SettingsView()
        case .stories(let id): StoryViewer(storyID: id)
        case .live: LiveHubView()
        case .browser(let url): BrowserView(url: url)
        case .admin: AdminView()
        case .notifications: NotificationsView()
        case .moderation(let id): ModerationDetailView(reportID: id)
        case .call(let chatID, let video): CallView(chatID: chatID, isVideo: video)
        case .botPlatform: BotPlatformView()
        }
    }

    @ViewBuilder
    private func sheet(_ sheet: AppSheet) -> some View {
        switch sheet {
        case .composer: ComposerView()
        case .newMessage: NewMessageView()
        case .editProfile: EditProfileView()
        case .share(let url): ShareView(url: url)
        case .report(let targetID, let targetType): ReportView(targetID: targetID, targetType: targetType)
        case .createStory: StoryComposerView()
        case .adminAccess: AdminAccessView()
        }
    }
}

struct AuthenticationView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.openURL) private var openURL
    @FocusState private var focusedField: Field?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isRegistering = true
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var showGoogleInfo = false

    private enum Field { case firstName, lastName, email, password }

    var body: some View {
        ZStack {
            authBackdrop
            VStack(spacing: 18) {
                Spacer(minLength: 10)
                header
                card
                Spacer(minLength: 8)
                Text(String(localized: "auth_footer"))
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.64))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 18)
        }
        .ignoresSafeArea()
        .alert("auth_error_title", isPresented: Binding(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .alert("auth_google_title", isPresented: $showGoogleInfo) {
            Button("ОК", role: .cancel) {}
        } message: {
            Text(String(localized: "auth_google_message"))
        }
    }

    private var authBackdrop: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.48, blue: 1.0),
                    Color(red: 0.34, green: 0.09, blue: 0.64),
                    .black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: 120, y: -260)
            Circle()
                .fill(.black.opacity(0.32))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: -120, y: 260)
        }
    }

    private var header: some View {
        VStack(spacing: 22) {
            Image(systemName: "o.circle.fill")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)
            Text("OnlyPipe")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            VStack(spacing: 10) {
                Text(isRegistering ? "Регистрация аккаунта" : "Вход в аккаунт")
                    .font(.system(size: 33, weight: .medium, design: .rounded))
                    .foregroundStyle(.white)
                Text("Введите личные данные, чтобы создать аккаунт.")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.82))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 8)
        }
        .padding(.top, 24)
    }

    private var card: some View {
        VStack(spacing: 20) {
            HStack(spacing: 14) {
                socialButton(title: "Google", systemImage: "g.circle.fill", action: startGoogleSignIn)
                socialButton(title: "Github", systemImage: "chevron.left.slash.chevron.right") {}
            }

            divider

            if isRegistering {
                HStack(spacing: 12) {
                    field(title: "Имя", placeholder: "eg. John", text: $firstName, field: .firstName)
                    field(title: "Фамилия", placeholder: "eg. Francisco", text: $lastName, field: .lastName)
                }
            }

            field(title: "Почта", placeholder: "name@example.com", text: $email, field: .email, keyboard: .emailAddress, contentType: .username)
            field(title: "Пароль", placeholder: "••••••••", text: $password, field: .password, isSecure: true, contentType: isRegistering ? .newPassword : .password)

            Button(action: submitEmail) {
                Text(isRegistering ? String(localized: "auth_create_account") : String(localized: "auth_continue_email"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
            }
            .foregroundStyle(.black)
            .background(
                LinearGradient(colors: [.white, .white.opacity(0.92)], startPoint: .top, endPoint: .bottom),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .disabled(isLoading)
            .opacity(isLoading ? 0.75 : 1)

            Button {
                isRegistering.toggle()
            } label: {
                Text(isRegistering ? String(localized: "auth_switch_to_signin") : String(localized: "auth_switch_to_create"))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.86))
            }
            .padding(.top, 2)
        }
        .padding(22)
        .background(
            LinearGradient(colors: [.black.opacity(0.92), .black.opacity(0.72)], startPoint: .top, endPoint: .bottom),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(.white.opacity(0.14), lineWidth: 0.8)
        }
        .shadow(color: .black.opacity(0.45), radius: 28, y: 14)
    }

    private var divider: some View {
        HStack(spacing: 14) {
            Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
            Text("Or")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.78))
            Rectangle().fill(.white.opacity(0.16)).frame(height: 1)
        }
    }

    private func socialButton(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 17, weight: .semibold))
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .foregroundStyle(.white)
            .background(.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(.white.opacity(0.16), lineWidth: 1))
        }
    }

    private func field(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        keyboard: UIKeyboardType = .default,
        isSecure: Bool = false,
        contentType: UITextContentType? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Group {
                if isSecure {
                    SecureField(placeholder, text: text)
                } else {
                    TextField(placeholder, text: text)
                }
            }
            .textInputAutocapitalization(.never)
            .keyboardType(keyboard)
            .textContentType(contentType)
            .focused($focusedField, equals: field)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(.white.opacity(0.12), lineWidth: 1))
        }
    }

    private func submitEmail() {
        isLoading = true
        Task {
            let name = [firstName, lastName].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            await dependencies.session.signInEmail(email: email, password: password, displayName: name.isEmpty ? nil : name)
            isLoading = false
            alertMessage = dependencies.session.errorMessage
        }
    }

    private func startGoogleSignIn() {
        if let baseURL = ServerConfiguration.current.apiBaseURL {
            openURL(baseURL.appendingPathComponent("auth/google/start"))
        } else {
            showGoogleInfo = true
        }
    }
}
