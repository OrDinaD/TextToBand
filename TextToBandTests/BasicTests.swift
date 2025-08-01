import XCTest

// Простой тест для проверки что все компилируется
final class BasicTests: XCTestCase {
    
    func testExample() {
        // Простейший тест
        XCTAssertTrue(true)
    }
    
    func testStringOperations() {
        let text = "Тестовый текст"
        XCTAssertEqual(text.count, 14)
        XCTAssertTrue(text.contains("Тест"))
    }
    
    func testArrayOperations() {
        let array = ["один", "два", "три"]
        XCTAssertEqual(array.count, 3)
        XCTAssertEqual(array.first, "один")
        XCTAssertEqual(array.last, "три")
    }
}
