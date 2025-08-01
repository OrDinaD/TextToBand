import XCTest
@testable import TextToBand

final class BackupManagerTests: XCTestCase {
    var backupManager: BackupManager!
    
    override func setUp() {
        super.setUp()
        backupManager = BackupManager()
    }
    
    override func tearDown() {
        backupManager = nil
        super.tearDown()
    }
    
    func testExportData() {
        let history = [
            HistoryItem(originalText: "Тест 1", splitTexts: ["Тест 1"]),
            HistoryItem(originalText: "Тест 2", splitTexts: ["Тест 2"])
        ]
        
        let templates = [
            TextTemplate(name: "Шаблон 1", content: "Контент 1"),
            TextTemplate(name: "Шаблон 2", content: "Контент 2")
        ]
        
        let settings = AppSettings(
            maxChunkSize: 200,
            notificationInterval: 5.0,
            soundEnabled: false,
            preferSentenceBoundary: true
        )
        
        let result = backupManager.exportData(
            history: history,
            templates: templates,
            settings: settings
        )
        
        switch result {
        case .success(let url):
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            // Удаляем тестовый файл
            try? FileManager.default.removeItem(at: url)
        case .failure(let error):
            XCTFail("Export failed: \(error)")
        }
    }
    
    func testImportData() {
        // Сначала создаем экспорт
        let history = [HistoryItem(originalText: "Тест", splitTexts: ["Тест"])]
        let templates = [TextTemplate(name: "Шаблон", content: "Контент")]
        let settings = AppSettings()
        
        let exportResult = backupManager.exportData(
            history: history,
            templates: templates,
            settings: settings
        )
        
        guard case .success(let exportURL) = exportResult else {
            XCTFail("Export failed")
            return
        }
        
        // Теперь импортируем
        let importResult = backupManager.importData(from: exportURL)
        
        switch importResult {
        case .success(let data):
            XCTAssertEqual(data.history.count, 1)
            XCTAssertEqual(data.templates.count, 1)
            XCTAssertEqual(data.history.first?.originalText, "Тест")
            XCTAssertEqual(data.templates.first?.name, "Шаблон")
        case .failure(let error):
            XCTFail("Import failed: \(error)")
        }
        
        // Удаляем тестовый файл
        try? FileManager.default.removeItem(at: exportURL)
    }
    
    func testImportInvalidData() {
        // Создаем файл с невалидными данными
        let invalidData = "invalid json".data(using: .utf8)!
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("invalid_backup.json")
        
        do {
            try invalidData.write(to: tempURL)
            
            let result = backupManager.importData(from: tempURL)
            
            switch result {
            case .success:
                XCTFail("Import should have failed")
            case .failure:
                // Ожидаем ошибку
                XCTAssertTrue(true)
            }
            
            // Удаляем тестовый файл
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            XCTFail("Failed to create test file: \(error)")
        }
    }
    
    func testValidateBackupData() {
        let validData = BackupData(
            history: [HistoryItem(originalText: "Тест", splitTexts: ["Тест"])],
            templates: [TextTemplate(name: "Шаблон", content: "Контент")],
            settings: AppSettings()
        )
        
        XCTAssertTrue(backupManager.validateBackupData(validData))
        
        // Тест с пустыми данными (должны быть валидными)
        let emptyData = BackupData(history: [], templates: [], settings: AppSettings())
        XCTAssertTrue(backupManager.validateBackupData(emptyData))
    }
}
