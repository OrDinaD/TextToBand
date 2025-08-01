import XCTest
@testable import TextToBand

final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    
    override func setUp() {
        super.setUp()
        notificationManager = NotificationManager()
    }
    
    override func tearDown() {
        notificationManager = nil
        super.tearDown()
    }
    
    func testRequestPermission() async {
        // Этот тест проверяет что метод не крашится
        // В реальном приложении потребуется пользовательское взаимодействие
        await notificationManager.requestPermission()
        
        // Просто проверяем что метод выполнился без ошибок
        XCTAssertTrue(true)
    }
    
    func testScheduleNotifications() async {
        let notifications = [
            NotificationItem(content: "Тест 1"),
            NotificationItem(content: "Тест 2"),
            NotificationItem(content: "Тест 3")
        ]
        
        await notificationManager.scheduleNotifications(notifications)
        
        // Проверяем что метод выполнился без ошибок
        XCTAssertTrue(true)
    }
    
    func testCancelAllNotifications() {
        notificationManager.cancelAllNotifications()
        
        // Проверяем что метод выполнился без ошибок
        XCTAssertTrue(true)
    }
    
    func testGetPendingNotifications() async {
        let pendingCount = await notificationManager.getPendingNotificationsCount()
        
        // Проверяем что метод возвращает число
        XCTAssertGreaterThanOrEqual(pendingCount, 0)
    }
}
