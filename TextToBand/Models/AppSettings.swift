import Foundation

struct AppSettings: Codable {
    var maxCharactersPerNotification: Int = 100
    var defaultDelayBetweenNotifications: TimeInterval = 60
    var notificationTitlePrefix: String = "Уведомление"
    
    static let shared = AppSettings()
    
    private static let userDefaults = UserDefaults.standard
    private static let settingsKey = "AppSettings"
    
    static func load() -> AppSettings {
        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings.shared
        }
        return settings
    }
    
    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        AppSettings.userDefaults.set(data, forKey: AppSettings.settingsKey)
    }
}
