import Foundation
import SwiftUI
import OSLog

@MainActor
class TextToBandViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var notifications: [NotificationItem] = []
    @Published var selectedDate: Date = Date().addingTimeInterval(300)
    @Published var selectedInterval: TimeInterval = 60
    @Published var isProcessing: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    @Published var currentHistoryItem: HistoryItem?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TextToBand", category: "ViewModel")
    private let notificationManager = NotificationManager.shared
    private let historyManager = HistoryManager()
    private let templateManager = TemplateManager()
    private let backupManager = BackupManager()
    private var settings = AppSettings.load()
    
    var canSendNotifications: Bool {
        !notifications.isEmpty && notifications.contains { $0.status == .pending || $0.status == .scheduled }
    }
    
    var totalCharacters: Int {
        inputText.count
    }
    
    var estimatedNotifications: Int {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return 0 }
        return max(1, Int(ceil(Double(totalCharacters) / Double(settings.maxCharactersPerNotification))))
    }
    
    var availableIntervals: [TimeInterval] {
        return settings.customIntervals.sorted()
    }
    
    func refresh() async {
        logger.debug("Refreshing view model state")
        await notificationManager.initialize()
        settings = AppSettings.load()
    }
    
    func loadTemplate(_ template: TextTemplate) {
        inputText = template.content
        templateManager.useTemplate(template)
    }
    
    func splitTextIntoNotifications() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            showAlert(message: "Введите текст для разбивки")
            return
        }
        
        let maxLength = settings.maxCharactersPerNotification
        var parts: [String] = []
        
        if trimmedText.count <= maxLength {
            parts = [trimmedText]
        } else {
            parts = smartSplitText(trimmedText, maxLength: maxLength)
        }
        
        notifications = parts.enumerated().map { index, content in
            NotificationItem(
                partNumber: index + 1,
                totalParts: parts.count,
                content: content,
                scheduledDate: nil,
                status: .pending,
                localNotificationId: nil
            )
        }
        
        if settings.enableHistoryTracking {
            currentHistoryItem = historyManager.addHistoryItem(
                text: trimmedText,
                notificationCount: parts.count
            )
        }
    }
    
    private func smartSplitText(_ text: String, maxLength: Int) -> [String] {
        var parts: [String] = []
        var currentText = text
        
        while !currentText.isEmpty {
            if currentText.count <= maxLength {
                parts.append(currentText)
                break
            }
            
            let cutIndex = currentText.index(currentText.startIndex, offsetBy: maxLength)
            var splitIndex = cutIndex
            
            let searchRange = currentText.index(currentText.startIndex, offsetBy: max(0, maxLength - 50))..<cutIndex
            
            if let lastSpaceIndex = currentText.range(of: " ", options: .backwards, range: searchRange)?.lowerBound {
                splitIndex = lastSpaceIndex
            } else if let lastPunctuationIndex = currentText.rangeOfCharacter(from: CharacterSet(charactersIn: ".,!?;:"), options: .backwards, range: searchRange)?.upperBound {
                splitIndex = lastPunctuationIndex
            }
            
            let part = String(currentText[..<splitIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !part.isEmpty {
                parts.append(part)
            }
            
            currentText = String(currentText[splitIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return parts
    }
    
    func sendNotificationsImmediately() async {
        guard await requestNotificationPermission() else { return }
        
        isProcessing = true
        updateHistoryStatus(.sending)
        
        let baseDate = Date()
        
        for i in notifications.indices {
            if notifications[i].status == .pending {
                let scheduledDate = baseDate.addingTimeInterval(TimeInterval(Double(i) * selectedInterval))
                notifications[i].scheduledDate = scheduledDate
                
                if let identifier = await notificationManager.scheduleNotification(
                    item: notifications[i],
                    at: scheduledDate
                ) {
                    notifications[i].localNotificationId = identifier
                    notifications[i].status = .scheduled
                }
            }
        }
        
        isProcessing = false
        updateHistoryStatus(.pending) // Статус "ожидает" до отправки всех уведомлений
        showAlert(message: "Уведомления запланированы!")
    }
    
    func scheduleNotifications() async {
        guard await requestNotificationPermission() else { return }
        
        isProcessing = true
        updateHistoryStatus(.sending)
        let baseDate = selectedDate
        
        for i in notifications.indices {
            if notifications[i].status == .pending {
                let scheduledDate = baseDate.addingTimeInterval(TimeInterval(i) * selectedInterval)
                
                if let identifier = await notificationManager.scheduleNotification(item: notifications[i], at: scheduledDate) {
                    notifications[i].localNotificationId = identifier
                    notifications[i].scheduledDate = scheduledDate
                    notifications[i].status = .scheduled
                }
            }
        }
        
        isProcessing = false
        updateHistoryStatus(.sent, sentDate: baseDate)
        showAlert(message: "Уведомления запланированы!")
    }
    
    func cancelNotification(at index: Int) async {
        guard index < notifications.count else { return }
        
        if let identifier = notifications[index].localNotificationId {
            await notificationManager.cancelNotification(identifier: identifier)
        }
        
        notifications[index].status = .cancelled
        notifications[index].localNotificationId = nil
        notifications[index].scheduledDate = nil
    }
    
    func removeNotification(at index: Int) async {
        guard index < notifications.count else { return }
        
        if let identifier = notifications[index].localNotificationId {
            await notificationManager.cancelNotification(identifier: identifier)
        }
        
        notifications.remove(at: index)
        updatePartNumbers()
    }
    
    private func updatePartNumbers() {
        for i in notifications.indices {
            notifications[i] = NotificationItem(
                partNumber: i + 1,
                totalParts: notifications.count,
                content: notifications[i].content,
                scheduledDate: notifications[i].scheduledDate,
                status: notifications[i].status,
                localNotificationId: notifications[i].localNotificationId
            )
        }
    }
    
    func updateNotificationContent(at index: Int, newContent: String) {
        guard index < notifications.count else { return }
        notifications[index].content = newContent
    }
    
    func clearAllNotifications() async {
        await notificationManager.cancelAllNotifications()
        notifications.removeAll()
        updateHistoryStatus(.cancelled)
    }
    
    private func updateHistoryStatus(_ status: HistoryItem.HistoryStatus, sentDate: Date? = nil) {
        guard let currentItem = currentHistoryItem else { return }
        historyManager.updateHistoryItem(currentItem, status: status, sentDate: sentDate)
    }
    
    private func requestNotificationPermission() async -> Bool {
        let granted = await notificationManager.requestPermission()
        if !granted {
            showAlert(message: "Для работы приложения необходимо разрешение на отправку уведомлений")
        }
        return granted
    }
    
    private func showAlert(message: String) {
        alertMessage = message
        showAlert = true
    }
    
    func getHistoryManager() -> HistoryManager {
        return historyManager
    }
    
    func getTemplateManager() -> TemplateManager {
        return templateManager
    }
    
    func getBackupManager() -> BackupManager {
        return backupManager
    }
    
    func exportBackup() async {
        let _ = await backupManager.exportBackup(
            settings: settings,
            templates: templateManager.templates,
            historyItems: historyManager.historyItems
        )
    }
    
    func importBackup(from url: URL) -> Bool {
        guard let backupData = backupManager.importBackup(from: url),
              backupManager.validateBackup(backupData) else {
            showAlert(message: "Ошибка импорта резервной копии")
            return false
        }
        
        settings = backupData.settings
        settings.save()
        
        templateManager.templates = backupData.templates
        historyManager.historyItems = backupData.historyItems
        
        showAlert(message: "Резервная копия успешно импортирована")
        return true
    }
}
