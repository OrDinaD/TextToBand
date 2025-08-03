import Foundation
import UserNotifications
import OSLog

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var pendingNotificationsCount: Int = 0
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TextToBand", category: "NotificationManager")
    private let maxNotificationsPerBatch = 64 // iOS system limit
    
    private init() {}
    
    func initialize() async {
        await updateAuthorizationStatus()
        await updatePendingNotificationsCount()
    }
    
    func requestPermission() async -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .provisional, .criticalAlert]
        
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
            await updateAuthorizationStatus()
            
            if granted {
                logger.info("Notification permission granted")
            } else {
                logger.warning("Notification permission denied")
            }
            
            return granted
        } catch {
            logger.error("Failed to request notification permission: \(error.localizedDescription)")
            return false
        }
    }
    
    func scheduleNotification(item: NotificationItem, at date: Date) async -> String? {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            logger.warning("Cannot schedule notification: not authorized")
            return nil
        }
        
        let content = createNotificationContent(for: item)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        return await scheduleNotificationRequest(content: content, trigger: trigger)
    }
    
    func scheduleNotification(item: NotificationItem, afterSeconds interval: TimeInterval) async -> String? {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            logger.warning("Cannot schedule notification: not authorized")
            return nil
        }
        
        let content = createNotificationContent(for: item)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, interval), repeats: false)
        
        return await scheduleNotificationRequest(content: content, trigger: trigger)
    }
    
    func scheduleNotifications(items: [NotificationItem], startingAt startDate: Date, interval: TimeInterval) async -> [String] {
        guard !items.isEmpty else { return [] }
        
        // Check system limits
        let availableSlots = maxNotificationsPerBatch - pendingNotificationsCount
        if availableSlots <= 0 {
            logger.warning("Cannot schedule notifications: system limit reached")
            return []
        }
        
        let itemsToSchedule = Array(items.prefix(availableSlots))
        var scheduledIdentifiers: [String] = []
        
        for (index, item) in itemsToSchedule.enumerated() {
            let notificationDate = startDate.addingTimeInterval(TimeInterval(index) * interval)
            
            if let identifier = await scheduleNotification(item: item, at: notificationDate) {
                scheduledIdentifiers.append(identifier)
                logger.debug("Scheduled notification \(index + 1)/\(itemsToSchedule.count)")
            } else {
                logger.error("Failed to schedule notification \(index + 1)")
                break
            }
        }
        
        await updatePendingNotificationsCount()
        logger.info("Successfully scheduled \(scheduledIdentifiers.count) notifications")
        
        return scheduledIdentifiers
    }
    
    private func createNotificationContent(for item: NotificationItem) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = item.title
        content.body = item.content
        content.sound = .default
        content.badge = NSNumber(value: pendingNotificationsCount + 1)
        
        // Add modern notification features
        content.interruptionLevel = .active
        content.relevanceScore = 0.8
        
        // Add category for actions
        content.categoryIdentifier = "TEXT_NOTIFICATION"
        
        // Add user info for tracking
        content.userInfo = [
            "notificationId": item.id.uuidString,
            "createdAt": Date().timeIntervalSince1970
        ]
        
        return content
    }
    
    private func scheduleNotificationRequest(content: UNMutableNotificationContent, trigger: UNNotificationTrigger) async -> String? {
        let identifier = UUID().uuidString
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            logger.debug("Scheduled notification with ID: \(identifier)")
            return identifier
        } catch {
            logger.error("Failed to schedule notification: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func updateAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    private func updatePendingNotificationsCount() async {
        let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
        pendingNotificationsCount = requests.count
    }
    
    func sendImmediateNotification(item: NotificationItem) async -> String? {
        return await scheduleNotification(item: item, afterSeconds: 1)
    }
    
    func cancelNotification(identifier: String) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        await updatePendingNotificationsCount()
        logger.debug("Cancelled notification with ID: \(identifier)")
    }
    
    func cancelAllNotifications() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        await updatePendingNotificationsCount()
        logger.info("Cancelled all notifications")
    }
    
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await UNUserNotificationCenter.current().pendingNotificationRequests()
    }
    
    func getDeliveredNotifications() async -> [UNNotification] {
        return await UNUserNotificationCenter.current().deliveredNotifications()
    }
    
    // MARK: - Notification Categories Setup
    func setupNotificationCategories() {
        let markAsReadAction = UNNotificationAction(
            identifier: "MARK_AS_READ",
            title: "Отметить как прочитанное",
            options: []
        )
        
        let replyAction = UNTextInputNotificationAction(
            identifier: "REPLY",
            title: "Ответить",
            options: [],
            textInputButtonTitle: "Отправить",
            textInputPlaceholder: "Введите ответ..."
        )
        
        let textCategory = UNNotificationCategory(
            identifier: "TEXT_NOTIFICATION",
            actions: [markAsReadAction, replyAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([textCategory])
        logger.debug("Notification categories configured")
    }
}

// MARK: - Extensions
extension NotificationManager {
    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional
    }
    
    var canScheduleNotifications: Bool {
        isAuthorized && pendingNotificationsCount < maxNotificationsPerBatch
    }
    
    var remainingNotificationSlots: Int {
        max(0, maxNotificationsPerBatch - pendingNotificationsCount)
    }
}