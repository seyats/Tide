import AppIntents
import Foundation

enum IntentHandoff {
    private static let key = "tide.pending.intent.url"

    static func store(_ url: URL) {
        UserDefaults.standard.set(url.absoluteString, forKey: key)
    }

    static func consume() -> URL? {
        guard let value = UserDefaults.standard.string(forKey: key) else { return nil }
        UserDefaults.standard.removeObject(forKey: key)
        return URL(string: value)
    }
}

struct OpenTideIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть Tide"
    static let description = IntentDescription("Открыть ленту Tide.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        IntentHandoff.store(URL(string: "tide://home")!)
        return .result()
    }
}

struct ComposeTidePostIntent: AppIntent {
    static let title: LocalizedStringResource = "Создать пост в Tide"
    static let description = IntentDescription("Открыть Tide сразу в редакторе поста.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        IntentHandoff.store(URL(string: "tide://compose")!)
        return .result()
    }
}

struct OpenTideChatsIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть чаты Tide"
    static let description = IntentDescription("Открыть ваши переписки в Tide.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        IntentHandoff.store(URL(string: "tide://chats")!)
        return .result()
    }
}

struct OpenTideActivityIntent: AppIntent {
    static let title: LocalizedStringResource = "Открыть активность Tide"
    static let description = IntentDescription("Открыть уведомления и социальную активность в Tide.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        IntentHandoff.store(URL(string: "tide://notifications")!)
        return .result()
    }
}

struct TideAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ComposeTidePostIntent(),
            phrases: ["Создать пост в \(.applicationName)", "Написать в \(.applicationName)"],
            shortTitle: "Новый пост",
            systemImageName: "square.and.pencil"
        )
        AppShortcut(
            intent: OpenTideChatsIntent(),
            phrases: ["Открыть чаты в \(.applicationName)", "Показать мои чаты в \(.applicationName)"],
            shortTitle: "Чаты",
            systemImageName: "bubble.left.and.bubble.right"
        )
        AppShortcut(
            intent: OpenTideActivityIntent(),
            phrases: ["Показать активность \(.applicationName)", "Открыть уведомления \(.applicationName)"],
            shortTitle: "Активность",
            systemImageName: "bell"
        )
    }
}
