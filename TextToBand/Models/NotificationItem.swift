import Foundation

struct NotificationItem: Identifiable, Codable {
    var id = UUID()
    let partNumber: Int
    let totalParts: Int
    var content: String
    var scheduledDate: Date?
    var status: NotificationStatus
    var localNotificationId: String?
    
    var title: String {
        return "Уведомление \(partNumber)/\(totalParts)"
    }
    
    var preview: String {
        if content.count <= 50 {
            return content
        }
        let index = content.index(content.startIndex, offsetBy: 47)
        return String(content[..<index]) + "..."
    }
}

enum NotificationStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case scheduled = "scheduled"
    case sent = "sent"
    case cancelled = "cancelled"
    
    var displayName: String {
        switch self {
        case .pending:
            return "Готов к отправке"
        case .scheduled:
            return "Запланирован"
        case .sent:
            return "Отправлен"
        case .cancelled:
            return "Отменен"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "blue"
        case .scheduled:
            return "orange"
        case .sent:
            return "green"
        case .cancelled:
            return "gray"
        }
    }
}
