import XCTest
@testable import TextToBand
import UserNotifications

@MainActor
final class TextToBandViewModelTests: XCTestCase {
    var viewModel: TextToBandViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TextToBandViewModel()
        // Очищаем историю перед каждым тестом
        viewModel.history.removeAll()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Text Splitting Tests
    
    func testTextSplittingWithShortText() {
        let shortText = "Короткий текст"
        let result = viewModel.splitText(shortText)
        
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first, shortText)
    }
    
    func testTextSplittingWithLongText() {
        let longText = String(repeating: "А", count: 300)
        let result = viewModel.splitText(longText)
        
        XCTAssertGreaterThan(result.count, 1)
        XCTAssertTrue(result.allSatisfy { $0.count <= 240 })
    }
    
    func testTextSplittingRespectsSentenceBoundaries() {
        let text = "Первое предложение. Второе предложение. Третье предложение."
        let result = viewModel.splitText(text)
        
        // Проверяем что разбивка уважает границы предложений
        result.forEach { chunk in
            if chunk.contains(".") && !chunk.hasSuffix(".") {
                XCTFail("Chunk should not break in the middle of sentence: \(chunk)")
            }
        }
    }
    
    // MARK: - History Tests
    
    func testAddToHistory() {
        let testText = "Тестовый текст"
        let historyItem = HistoryItem(originalText: testText, splitTexts: [testText])
        
        viewModel.addToHistory(historyItem)
        
        XCTAssertEqual(viewModel.history.count, 1)
        XCTAssertEqual(viewModel.history.first?.originalText, testText)
    }
    
    func testDeleteFromHistory() {
        let historyItem = HistoryItem(originalText: "Тест", splitTexts: ["Тест"])
        viewModel.addToHistory(historyItem)
        
        XCTAssertEqual(viewModel.history.count, 1)
        
        viewModel.deleteFromHistory(historyItem.id)
        
        XCTAssertEqual(viewModel.history.count, 0)
    }
    
    func testClearHistory() {
        viewModel.addToHistory(HistoryItem(originalText: "Тест1", splitTexts: ["Тест1"]))
        viewModel.addToHistory(HistoryItem(originalText: "Тест2", splitTexts: ["Тест2"]))
        
        XCTAssertEqual(viewModel.history.count, 2)
        
        viewModel.clearHistory()
        
        XCTAssertEqual(viewModel.history.count, 0)
    }
    
    // MARK: - Templates Tests
    
    func testAddTemplate() {
        let template = TextTemplate(name: "Тестовый шаблон", content: "Тестовый контент")
        
        viewModel.addTemplate(template)
        
        XCTAssertEqual(viewModel.templates.count, 1)
        XCTAssertEqual(viewModel.templates.first?.name, "Тестовый шаблон")
    }
    
    func testDeleteTemplate() {
        let template = TextTemplate(name: "Тест", content: "Контент")
        viewModel.addTemplate(template)
        
        XCTAssertEqual(viewModel.templates.count, 1)
        
        viewModel.deleteTemplate(template.id)
        
        XCTAssertEqual(viewModel.templates.count, 0)
    }
    
    func testUpdateTemplate() {
        let template = TextTemplate(name: "Старое имя", content: "Старый контент")
        viewModel.addTemplate(template)
        
        let updatedTemplate = TextTemplate(
            id: template.id,
            name: "Новое имя",
            content: "Новый контент"
        )
        
        viewModel.updateTemplate(updatedTemplate)
        
        XCTAssertEqual(viewModel.templates.count, 1)
        XCTAssertEqual(viewModel.templates.first?.name, "Новое имя")
        XCTAssertEqual(viewModel.templates.first?.content, "Новый контент")
    }
    
    // MARK: - Settings Tests
    
    func testDefaultSettings() {
        XCTAssertEqual(viewModel.settings.maxChunkSize, 240)
        XCTAssertEqual(viewModel.settings.notificationInterval, 3.0)
        XCTAssertTrue(viewModel.settings.soundEnabled)
    }
    
    func testUpdateSettings() {
        let newSettings = AppSettings(
            maxChunkSize: 200,
            notificationInterval: 5.0,
            soundEnabled: false,
            preferSentenceBoundary: false
        )
        
        viewModel.updateSettings(newSettings)
        
        XCTAssertEqual(viewModel.settings.maxChunkSize, 200)
        XCTAssertEqual(viewModel.settings.notificationInterval, 5.0)
        XCTAssertFalse(viewModel.settings.soundEnabled)
    }
    
    // MARK: - Notification Tests
    
    func testCreateNotificationItems() {
        let texts = ["Первый", "Второй", "Третий"]
        let items = viewModel.createNotificationItems(from: texts)
        
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].content, "Первый")
        XCTAssertEqual(items[1].content, "Второй")
        XCTAssertEqual(items[2].content, "Третий")
        
        // Проверяем что времена отправки увеличиваются
        XCTAssertLessThan(items[0].scheduledTime, items[1].scheduledTime)
        XCTAssertLessThan(items[1].scheduledTime, items[2].scheduledTime)
    }
    
    // MARK: - Data Persistence Tests
    
    func testSaveAndLoadHistory() {
        let historyItem = HistoryItem(originalText: "Тест", splitTexts: ["Тест"])
        viewModel.addToHistory(historyItem)
        
        viewModel.saveHistory()
        
        // Создаем новую viewModel для проверки загрузки
        let newViewModel = TextToBandViewModel()
        XCTAssertEqual(newViewModel.history.count, 1)
        XCTAssertEqual(newViewModel.history.first?.originalText, "Тест")
    }
    
    func testSaveAndLoadTemplates() {
        let template = TextTemplate(name: "Тест", content: "Контент")
        viewModel.addTemplate(template)
        
        viewModel.saveTemplates()
        
        // Создаем новую viewModel для проверки загрузки
        let newViewModel = TextToBandViewModel()
        XCTAssertEqual(newViewModel.templates.count, 1)
        XCTAssertEqual(newViewModel.templates.first?.name, "Тест")
    }
}
