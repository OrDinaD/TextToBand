import XCTest
@testable import TextToBand

final class TextTemplateTests: XCTestCase {
    
    func testTextTemplateCreation() {
        let name = "Тестовый шаблон"
        let content = "Это тестовый контент шаблона"
        
        let template = TextTemplate(name: name, content: content)
        
        XCTAssertEqual(template.name, name)
        XCTAssertEqual(template.content, content)
        XCTAssertNotNil(template.id)
        XCTAssertNotNil(template.createdAt)
    }
    
    func testTextTemplateWithCustomId() {
        let customId = UUID()
        let template = TextTemplate(
            id: customId,
            name: "Тест",
            content: "Контент"
        )
        
        XCTAssertEqual(template.id, customId)
    }
    
    func testTextTemplateEncoding() {
        let template = TextTemplate(
            name: "Кодирование",
            content: "Тест кодирования"
        )
        
        let encoder = JSONEncoder()
        let data = try? encoder.encode(template)
        
        XCTAssertNotNil(data)
    }
    
    func testTextTemplateDecoding() {
        let template = TextTemplate(
            name: "Декодирование",
            content: "Тест декодирования"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try! encoder.encode(template)
        let decodedTemplate = try! decoder.decode(TextTemplate.self, from: data)
        
        XCTAssertEqual(decodedTemplate.id, template.id)
        XCTAssertEqual(decodedTemplate.name, template.name)
        XCTAssertEqual(decodedTemplate.content, template.content)
        XCTAssertEqual(decodedTemplate.createdAt, template.createdAt)
    }
    
    func testTextTemplateEquality() {
        let id = UUID()
        let template1 = TextTemplate(
            id: id,
            name: "Тест",
            content: "Контент"
        )
        let template2 = TextTemplate(
            id: id,
            name: "Другое имя", // Имя может отличаться
            content: "Другой контент" // Контент может отличаться
        )
        
        XCTAssertEqual(template1, template2) // Равенство по ID
    }
    
    func testTextTemplateInequality() {
        let template1 = TextTemplate(name: "Тест1", content: "Контент1")
        let template2 = TextTemplate(name: "Тест2", content: "Контент2")
        
        XCTAssertNotEqual(template1, template2) // Разные ID
    }
    
    func testEmptyTemplate() {
        let template = TextTemplate(name: "", content: "")
        
        XCTAssertEqual(template.name, "")
        XCTAssertEqual(template.content, "")
        XCTAssertNotNil(template.id)
    }
    
    func testLongContentTemplate() {
        let longContent = String(repeating: "А", count: 1000)
        let template = TextTemplate(name: "Длинный", content: longContent)
        
        XCTAssertEqual(template.content.count, 1000)
    }
}
