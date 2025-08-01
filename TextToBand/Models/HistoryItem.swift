import Foundation

struct HistoryItem: Identifiable, Codable {
    var id = UUID()
    let originalText: String
    let createdDate: Date
    var sentDate: Date?
    let totalNotifications: Int
    var status: HistoryStatus
    
    enum HistoryStatus: String, CaseIterable, Codable {
        case draft = "draft"
        case sending = "sending" 
        case sent = "sent"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .draft:
                return "Черновик"
            case .sending:
                return "Отправляется"
            case .sent:
                return "Отправлено"
            case .cancelled:
                return "Отменено"
            }
        }
        
        var color: String {
            switch self {
            case .draft:
                return "gray"
            case .sending:
                return "orange"
            case .sent:
                return "green"
            case .cancelled:
                return "red"
            }
        }
    }
}

class HistoryManager: ObservableObject {
    @Published var historyItems: [HistoryItem] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "TextToBandHistory"
    
    init() {
        loadHistory()
    }
    
    func addHistoryItem(text: String, notificationCount: Int) -> HistoryItem {
        let historyItem = HistoryItem(
            originalText: text,
            createdDate: Date(),
            totalNotifications: notificationCount,
            status: .pending
        )
        historyItems.insert(historyItem, at: 0)
        saveHistory()
        return historyItem
    }
    
    func updateHistoryItem(_ item: HistoryItem, status: HistoryItem.HistoryStatus, sentDate: Date? = nil) {
        if let index = historyItems.firstIndex(where: { $0.id == item.id }) {
            var updatedItem = item
            updatedItem.status = status
            if let sentDate = sentDate {
                updatedItem.sentDate = sentDate
            }
            historyItems[index] = updatedItem
            saveHistory()
        }
    }
    
    func deleteHistoryItem(_ item: HistoryItem) {
        historyItems.removeAll { $0.id == item.id }
        saveHistory()
    }
    
    func clearHistory() {
        historyItems.removeAll()
        saveHistory()
    }
    
    private func loadHistory() {
        guard let data = userDefaults.data(forKey: historyKey),
              let items = try? JSONDecoder().decode([HistoryItem].self, from: data) else {
            return
        }
        historyItems = items
    }
    
    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(historyItems) else { return }
        userDefaults.set(data, forKey: historyKey)
    }
}
