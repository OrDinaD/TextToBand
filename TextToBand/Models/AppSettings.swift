import Foundation

struct AppSettings: Codable {
    var maxCharactersPerNotification: Int = 100
    var defaultDelayBetweenNotifications: TimeInterval = 60
    var notificationTitlePrefix: String = "Уведомление"
    var enableHistoryTracking: Bool = true
    var maxHistoryItems: Int = 100
    var autoDeleteOldHistory: Bool = true
    var historyRetentionDays: Int = 30
    var enableTemplates: Bool = true
    var maxTemplates: Int = 50
    var enableBackup: Bool = true
    var customIntervals: [TimeInterval] = [10, 30, 60, 120, 300]
    
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
    
    mutating func exportSettings() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    static func importSettings(from data: Data) -> AppSettings? {
        return try? JSONDecoder().decode(AppSettings.self, from: data)
    }
    
    mutating func resetToDefaults() {
        maxCharactersPerNotification = 100
        defaultDelayBetweenNotifications = 60
        notificationTitlePrefix = "Уведомление"
        enableHistoryTracking = true
        maxHistoryItems = 100
        autoDeleteOldHistory = true
        historyRetentionDays = 30
        enableTemplates = true
        maxTemplates = 50
        enableBackup = true
        save()
    }
}
