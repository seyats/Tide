import AVKit
import PhotosUI
import SwiftUI

struct StoryViewer: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    let storyID: UUID

    @State private var currentIndex = 0
    @State private var progress = 0.0
    @State private var reply = ""
    @State private var isPaused = false
    @State private var hasReacted = false
    @FocusState private var replyFocused: Bool

    private var stories: [Story] { dependencies.social.stories }
    private var story: Story? { stories[safe: currentIndex] }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let story {
                storyContent(story)
                tapZones
                storyChrome(story)
            } else {
                ContentUnavailableView("История истекла", systemImage: "clock.badge.xmark")
                    .foregroundStyle(.white)
            }
        }
        .preferredColorScheme(.dark)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            currentIndex = stories.firstIndex(where: { $0.id == storyID }) ?? 0
            dependencies.social.markStoryViewed(storyID)
        }
        .task(id: currentIndex) {
            await runProgress()
        }
    }

    private var tapZones: some View {
        HStack(spacing: 0) {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { previousStory() }
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture { nextStory() }
        }
        .padding(.top, 96)
        .padding(.bottom, 116)
        .onLongPressGesture(minimumDuration: 0.15, pressing: { isPaused = $0 }, perform: {})
    }

    private func storyChrome(_ story: Story) -> some View {
        VStack(spacing: 14) {
            progressBar
                .padding(.top, 8)

            HStack(spacing: 10) {
                AvatarView(user: story.author, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    VerifiedName(user: story.author)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text(story.createdAt.formatted(.relative(presentation: .named)))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.68))
                }
                Spacer()
                TideGlassIconButton(symbol: "xmark", tint: .white, size: 42) {
                    withAnimation(.easeInOut(duration: 0.34)) { dismiss() }
                }
            }

            Spacer()

            if !story.caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(story.caption)
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 0.7)
                    }
            }

            replyComposer(story)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(stories.indices, id: \.self) { index in
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.25))
                        Capsule()
                            .fill(.white)
                            .frame(width: proxy.size.width * segmentProgress(index))
                    }
                }
                .frame(height: 4)
            }
        }
        .animation(.linear(duration: 0.06), value: progress)
    }

    private func replyComposer(_ story: Story) -> some View {
        HStack(spacing: 10) {
            TextField("Ответить...", text: $reply, axis: .vertical)
                .focused($replyFocused)
                .lineLimit(1...3)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .tint(.white)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.14), lineWidth: 0.7))
                .onChange(of: replyFocused) { _, focused in isPaused = focused }

            TideGlassIconButton(symbol: hasReacted ? "heart.fill" : "heart", tint: hasReacted ? TidePalette.danger : .white, size: 44) {
                withAnimation(.easeInOut(duration: 0.36)) { react(to: story) }
            }

            TideGlassIconButton(symbol: "paperplane.fill", tint: .white, size: 44) {
                sendReply(to: story)
            }
            .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
    }

    @ViewBuilder
    private func storyContent(_ story: Story) -> some View {
        if let url = story.mediaURL {
            StoryMediaCanvas(url: url, kind: story.mediaKind)
        } else {
            ZStack {
                LinearGradient(colors: [.white.opacity(0.16), .black, .white.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                Image(systemName: story.symbol)
                    .font(.system(size: 110, weight: .thin))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
    }

    private func segmentProgress(_ index: Int) -> Double {
        if index < currentIndex { return 1 }
        if index > currentIndex { return 0 }
        return progress
    }

    private func runProgress() async {
        progress = 0
        guard let story else { return }
        dependencies.social.markStoryViewed(story.id)
        let duration = story.mediaKind == .video ? 8.0 : 5.2
        let tick = 0.035
        while progress < 1, !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(Int(tick * 1_000)))
            guard !isPaused else { continue }
            progress = min(1, progress + tick / duration)
        }
        guard !Task.isCancelled else { return }
        nextStory()
    }

    private func nextStory() {
        withAnimation(.easeInOut(duration: 0.28)) {
            if currentIndex < stories.count - 1 {
                currentIndex += 1
                progress = 0
                hasReacted = false
                reply = ""
            } else {
                dismiss()
            }
        }
    }

    private func previousStory() {
        withAnimation(.easeInOut(duration: 0.28)) {
            if progress > 0.18 {
                progress = 0
            } else if currentIndex > 0 {
                currentIndex -= 1
                progress = 0
                hasReacted = false
                reply = ""
            }
        }
    }

    private func sendReply(to story: Story) {
        guard let currentUser = dependencies.session.currentUser else { return }
        let cleanReply = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanReply.isEmpty else { return }
        let chatID = dependencies.messenger.createDirectChat(currentUser: currentUser, otherUser: story.author)
        reply = ""
        replyFocused = false
        Task {
            await dependencies.messenger.send("Ответ на вашу историю: \(cleanReply)", to: chatID, senderID: currentUser.id)
        }
    }

    private func react(to story: Story) {
        hasReacted.toggle()
        if hasReacted {
            dependencies.notifications.add(
                kind: .storyReply,
                title: "Реакция на историю отправлена",
                body: "Вы отреагировали на историю \(story.author.name)",
                targetID: story.id
            )
        }
    }
}

private struct StoryMediaCanvas: View {
    let url: URL
    let kind: MediaKind

    var body: some View {
        ZStack {
            background
                .ignoresSafeArea()
            foreground
                .padding(.horizontal, 0)
                .padding(.vertical, 84)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch kind {
        case .photo:
            TideMediaImage(url: url, contentMode: .fill)
                .blur(radius: 28)
                .scaleEffect(1.12)
                .overlay(.black.opacity(0.34))
        case .video:
            TideVideoThumbnailView(url: url)
                .blur(radius: 28)
                .scaleEffect(1.12)
                .overlay(.black.opacity(0.38))
        case .link:
            LinearGradient(colors: [.black, .gray.opacity(0.42)], startPoint: .top, endPoint: .bottom)
        }
    }

    @ViewBuilder
    private var foreground: some View {
        switch kind {
        case .photo:
            TideMediaImage(url: url, contentMode: .fit)
        case .video:
            StoryVideoPlayer(url: url)
        case .link:
            LinkPreviewCard(url: url)
                .padding(20)
        }
    }
}

private struct StoryVideoPlayer: View {
    let url: URL
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .background(Color.black)
            .onAppear {
                let player = AVPlayer(url: url)
                player.isMuted = true
                self.player = player
                player.play()
            }
            .onDisappear {
                player?.pause()
                player = nil
            }
    }
}

struct StoryComposerView: View {
    @Environment(AppDependencies.self) private var dependencies
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var media: ComposerMedia?
    @State private var caption = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 18) {
                    Group {
                        if let media {
                            StoryMediaCanvas(url: media.url, kind: media.kind)
                                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .stroke(.white.opacity(0.14), lineWidth: 0.8)
                                }
                        } else {
                            ContentUnavailableView("Выберите фото или видео", systemImage: "photo.on.rectangle.angled")
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 30, style: .continuous))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    TextField("Подпись", text: $caption, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .tint(.white)
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                        Label(media == nil ? "Выбрать медиа" : "Заменить медиа", systemImage: "photo.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(TideGlassButtonStyle(tint: .white.opacity(0.28), cornerRadius: 22, minHeight: 52))

                    if isLoading { ProgressView("Импорт медиа").tint(.white) }
                }
                .padding(16)
            }
            .navigationTitle("Новая история")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Отмена") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Опубликовать", action: publish).disabled(media == nil || isLoading) }
            }
            .preferredColorScheme(.dark)
            .onChange(of: selectedItem) { _, item in
                guard let item else { return }
                Task {
                    isLoading = true
                    defer { isLoading = false }
                    if let items = try? await MediaLibrary.shared.importItems([item]) { media = items.first }
                }
            }
        }
    }

    private func publish() {
        guard let user = dependencies.session.currentUser, let media else { return }
        dependencies.social.createStory(author: user, mediaURL: media.url, mediaKind: media.kind, caption: caption)
        dismiss()
    }
}
