import Foundation
import SwiftUI

@MainActor
class TextToBandViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var notifications: [NotificationItem] = []
    @Published var selectedDate: Date = Date().addingTimeInterval(300)
    @Published var isProcessing: Bool = false
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private let notificationManager = NotificationManager.shared
    private let settings = AppSettings.load()
    
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
        
        for i in notifications.indices {
            if notifications[i].status == .pending {
                if let identifier = await notificationManager.sendImmediateNotification(item: notifications[i]) {
                    notifications[i].localNotificationId = identifier
                    notifications[i].status = .sent
                }
                
                if i < notifications.count - 1 {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                }
            }
        }
        
        isProcessing = false
        showAlert(message: "Уведомления отправлены!")
    }
    
    func scheduleNotifications() async {
        guard await requestNotificationPermission() else { return }
        
        isProcessing = true
        let baseDate = selectedDate
        
        for i in notifications.indices {
            if notifications[i].status == .pending {
                let scheduledDate = baseDate.addingTimeInterval(TimeInterval(i) * settings.defaultDelayBetweenNotifications)
                
                if let identifier = await notificationManager.scheduleNotification(item: notifications[i], at: scheduledDate) {
                    notifications[i].localNotificationId = identifier
                    notifications[i].scheduledDate = scheduledDate
                    notifications[i].status = .scheduled
                }
            }
        }
        
        isProcessing = false
        showAlert(message: "Уведомления запланированы!")
    }
    
    func cancelNotification(at index: Int) {
        guard index < notifications.count else { return }
        
        if let identifier = notifications[index].localNotificationId {
            notificationManager.cancelNotification(identifier: identifier)
        }
        
        notifications[index].status = .cancelled
        notifications[index].localNotificationId = nil
        notifications[index].scheduledDate = nil
    }
    
    func removeNotification(at index: Int) {
        guard index < notifications.count else { return }
        
        if let identifier = notifications[index].localNotificationId {
            notificationManager.cancelNotification(identifier: identifier)
        }
        
        notifications.remove(at: index)
        
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
    
    func clearAllNotifications() {
        notificationManager.cancelAllNotifications()
        notifications.removeAll()
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
}
