import SwiftUI
import UserNotifications

@main
struct TextToBandApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupDefaultSettings()
                }
        }
    }
    
    private func setupDefaultSettings() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: "maxCharactersPerNotification") == nil {
            defaults.set(100, forKey: "maxCharactersPerNotification")
        }
        
        if defaults.object(forKey: "defaultDelayBetweenNotifications") == nil {
            defaults.set(60.0, forKey: "defaultDelayBetweenNotifications")
        }
        
        if defaults.object(forKey: "notificationTitlePrefix") == nil {
            defaults.set("Уведомление", forKey: "notificationTitlePrefix")
        }
        
        if defaults.object(forKey: "version") == nil {
            defaults.set("1.0", forKey: "version")
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .badge])
    }
}
