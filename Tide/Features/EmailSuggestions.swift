import Foundation

/// Логика автодополнения популярных email доменов
enum EmailSuggestions {
    static let popularDomains = [
        "gmail.com",
        "yahoo.com",
        "outlook.com",
        "icloud.com",
        "mail.com",
        "protonmail.com",
        "tutanota.com",
        "yandex.ru",
        "mail.ru",
        "bk.ru"
    ]
    
    /// Генерирует список предложений email на основе введённого текста
    static func suggestions(for input: String) -> [String] {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Если уже содержит @, не предлагаем
        if trimmed.contains("@") {
            return []
        }
        
        // Если пусто, не предлагаем
        if trimmed.isEmpty {
            return []
        }
        
        // Предлагаем все популярные домены с введённым именем
        return popularDomains.map { "\(trimmed)@\($0)" }
    }
    
    /// Проверяет, является ли строка валидным email
    static func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: email)
    }
}
