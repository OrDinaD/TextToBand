import XCTest
@testable import TextToBand

final class HistoryItemTests: XCTestCase {
    
    func testHistoryItemCreation() {
        let originalText = "Тестовый текст для истории"
        let splitTexts = ["Тестовый текст", "для истории"]
        
        let historyItem = HistoryItem(originalText: originalText, splitTexts: splitTexts)
        
        XCTAssertEqual(historyItem.originalText, originalText)
        XCTAssertEqual(historyItem.splitTexts, splitTexts)
        XCTAssertEqual(historyItem.status, .draft)
        XCTAssertNotNil(historyItem.id)
        XCTAssertNotNil(historyItem.createdAt)
    }
    
    func testHistoryItemEncoding() {
        let historyItem = HistoryItem(
            originalText: "Тест",
            splitTexts: ["Тест1", "Тест2"]
        )
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(historyItem)
        
        XCTAssertNotNil(data)
    }
    
    func testHistoryItemDecoding() {
        let historyItem = HistoryItem(
            originalText: "Тест декодирования",
            splitTexts: ["Тест", "декодирования"]
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try! encoder.encode(historyItem)
        let decodedItem = try! decoder.decode(HistoryItem.self, from: data)
        
        XCTAssertEqual(decodedItem.id, historyItem.id)
        XCTAssertEqual(decodedItem.originalText, historyItem.originalText)
        XCTAssertEqual(decodedItem.splitTexts, historyItem.splitTexts)
        XCTAssertEqual(decodedItem.status, historyItem.status)
    }
    
    func testHistoryStatusDisplayName() {
        XCTAssertEqual(HistoryItem.HistoryStatus.draft.displayName, "Черновик")
        XCTAssertEqual(HistoryItem.HistoryStatus.pending.displayName, "В очереди")
        XCTAssertEqual(HistoryItem.HistoryStatus.sending.displayName, "Отправка")
        XCTAssertEqual(HistoryItem.HistoryStatus.sent.displayName, "Отправлено")
        XCTAssertEqual(HistoryItem.HistoryStatus.cancelled.displayName, "Отменено")
    }
    
    func testHistoryStatusColors() {
        // Проверяем что у всех статусов есть цвета
        let statuses: [HistoryItem.HistoryStatus] = [.draft, .pending, .sending, .sent, .cancelled]
        
        for status in statuses {
            XCTAssertNotNil(status.color)
        }
    }
}
