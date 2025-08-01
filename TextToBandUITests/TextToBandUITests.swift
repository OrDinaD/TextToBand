import XCTest

final class TextToBandUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testMainScreenElements() throws {
        // Проверяем основные элементы главного экрана
        XCTAssertTrue(app.staticTexts["TextToBand"].exists)
        XCTAssertTrue(app.textViews.firstMatch.exists)
        XCTAssertTrue(app.buttons["Отправить уведомления"].exists)
        XCTAssertTrue(app.buttons["История"].exists)
        XCTAssertTrue(app.buttons["Шаблоны"].exists)
        XCTAssertTrue(app.buttons["Настройки"].exists)
    }
    
    func testTextInput() throws {
        let textView = app.textViews.firstMatch
        XCTAssertTrue(textView.exists)
        
        textView.tap()
        textView.typeText("Тестовый текст для проверки")
        
        XCTAssertTrue(textView.value as? String == "Тестовый текст для проверки")
    }
    
    func testSendNotifications() throws {
        let textView = app.textViews.firstMatch
        let sendButton = app.buttons["Отправить уведомления"]
        
        textView.tap()
        textView.typeText("Короткий тест")
        
        sendButton.tap()
        
        // После отправки должна появиться кнопка отмены
        XCTAssertTrue(app.buttons["Отменить отправку"].waitForExistence(timeout: 2))
    }
    
    func testHistoryNavigation() throws {
        let historyButton = app.buttons["История"]
        historyButton.tap()
        
        // Проверяем что открылся экран истории
        XCTAssertTrue(app.navigationBars["История"].waitForExistence(timeout: 2))
        
        // Возвращаемся назад
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testTemplatesNavigation() throws {
        let templatesButton = app.buttons["Шаблоны"]
        templatesButton.tap()
        
        // Проверяем что открылся экран шаблонов
        XCTAssertTrue(app.navigationBars["Шаблоны"].waitForExistence(timeout: 2))
        
        // Возвращаемся назад
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testSettingsNavigation() throws {
        let settingsButton = app.buttons["Настройки"]
        settingsButton.tap()
        
        // Проверяем что открылся экран настроек
        XCTAssertTrue(app.navigationBars["Настройки"].waitForExistence(timeout: 2))
        
        // Возвращаемся назад
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testCreateTemplate() throws {
        // Переходим к шаблонам
        app.buttons["Шаблоны"].tap()
        
        // Нажимаем кнопку добавления
        if app.buttons["Добавить шаблон"].exists {
            app.buttons["Добавить шаблон"].tap()
        } else {
            app.buttons["+"].tap()
        }
        
        // Заполняем форму
        let nameField = app.textFields["Название шаблона"]
        if nameField.exists {
            nameField.tap()
            nameField.typeText("UI Test Template")
        }
        
        let contentField = app.textViews["Содержимое шаблона"]
        if contentField.exists {
            contentField.tap()
            contentField.typeText("Тестовое содержимое шаблона")
        }
        
        // Сохраняем
        if app.buttons["Сохранить"].exists {
            app.buttons["Сохранить"].tap()
        }
        
        // Возвращаемся к главному экрану
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testSettingsChanges() throws {
        // Переходим к настройкам
        app.buttons["Настройки"].tap()
        
        // Проверяем наличие основных настроек
        XCTAssertTrue(app.staticTexts["Размер части"].exists)
        XCTAssertTrue(app.staticTexts["Интервал"].exists)
        XCTAssertTrue(app.staticTexts["Звук"].exists)
        
        // Возвращаемся назад
        app.navigationBars.buttons.firstMatch.tap()
    }
    
    func testCancelNotifications() throws {
        let textView = app.textViews.firstMatch
        let sendButton = app.buttons["Отправить уведомления"]
        
        // Отправляем уведомления
        textView.tap()
        textView.typeText("Тест отмены")
        sendButton.tap()
        
        // Ждем появления кнопки отмены
        let cancelButton = app.buttons["Отменить отправку"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 2))
        
        // Отменяем отправку
        cancelButton.tap()
        
        // Проверяем что кнопка отмены исчезла
        XCTAssertFalse(cancelButton.exists)
    }
}
