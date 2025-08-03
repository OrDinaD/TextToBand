import Foundation
import SwiftUI

struct BackupData: Codable {
    let settings: AppSettings
    let templates: [TextTemplate]
    let historyItems: [HistoryItem]
    let exportDate: Date
    let appVersion: String
    
    init(settings: AppSettings, templates: [TextTemplate], historyItems: [HistoryItem]) {
        self.settings = settings
        self.templates = templates
        self.historyItems = historyItems
        self.exportDate = Date()
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
}

class BackupManager: ObservableObject {
    @Published var isExporting = false
    @Published var isImporting = false
    @Published var showShareSheet = false
    @Published var backupFileURL: URL?
    
    @MainActor
    func exportBackup(settings: AppSettings, templates: [TextTemplate], historyItems: [HistoryItem]) async -> URL? {
        isExporting = true
        
        let backupData = BackupData(
            settings: settings,
            templates: templates,
            historyItems: historyItems
        )
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(backupData)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileName = "TextToBand_Backup_\(DateFormatter.backupFormatter.string(from: Date())).json"
            let fileURL = documentsPath.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            
            self.backupFileURL = fileURL
            self.isExporting = false
            return fileURL
        } catch {
            print("Ошибка экспорта: \(error)")
            isExporting = false
            return nil
        }
    }
    
    func importBackup(from url: URL) -> BackupData? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let backupData = try decoder.decode(BackupData.self, from: data)
            return backupData
        } catch {
            print("Ошибка импорта: \(error)")
            return nil
        }
    }
    
    func validateBackup(_ backup: BackupData) -> Bool {
        // Проверяем версию приложения
        guard let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            print("Не удалось получить текущую версию приложения")
            return false
        }
        
        // Проверяем совместимость версий (можно импортировать из той же или более старой версии)
        let backupVersionComponents = backup.appVersion.components(separatedBy: ".").compactMap { Int($0) }
        let currentVersionComponents = currentVersion.components(separatedBy: ".").compactMap { Int($0) }
        
        if backupVersionComponents.count >= 2 && currentVersionComponents.count >= 2 {
            let backupMajor = backupVersionComponents[0]
            let backupMinor = backupVersionComponents[1]
            let currentMajor = currentVersionComponents[0]
            let currentMinor = currentVersionComponents[1]
            
            // Проверяем, что major версия не больше текущей
            if backupMajor > currentMajor {
                print("Резервная копия создана в более новой версии приложения")
                return false
            }
        }
        
        // Проверяем структуру данных
        if backup.templates.isEmpty && backup.historyItems.isEmpty {
            print("Резервная копия не содержит данных")
            return false
        }
        
        // Проверяем целостность шаблонов
        for template in backup.templates {
            if template.name.isEmpty || template.content.isEmpty {
                print("Найден некорректный шаблон в резервной копии")
                return false
            }
        }
        
        // Проверяем целостность истории
        for item in backup.historyItems {
            if item.originalText.isEmpty {
                print("Найден некорректный элемент истории в резервной копии")
                return false
            }
        }
        
        // Проверяем дату экспорта (не должна быть в будущем)
        if backup.exportDate > Date() {
            print("Некорректная дата экспорта в резервной копии")
            return false
        }
        
        return true
    }
}

extension DateFormatter {
    static let backupFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter
    }()
}
