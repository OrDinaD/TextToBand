import SwiftUI
import UserNotifications
import OSLog

@main
struct TextToBandApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TextToBand", category: "App")
    
    init() {
        setupAppConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(AppStateManager.shared)
                .task {
                    await setupApp()
                }
                .onChange(of: scenePhase) { _, newPhase in
                    handleScenePhaseChange(newPhase)
                }
        }
    }
    
    private func setupAppConfiguration() {
        // Configure app-wide settings
        configureAppearance()
        configureDefaultSettings()
    }
    
    private func configureAppearance() {
        // Modern iOS appearance configuration
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor.systemBackground
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().compactAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func configureDefaultSettings() {
        UserDefaults.standard.register(defaults: [
            "maxCharactersPerNotification": 100,
            "defaultDelayBetweenNotifications": 60.0,
            "notificationTitlePrefix": "Уведомление",
            "version": "2.0.0",
            "enableHapticFeedback": true,
            "enableSmartSplitting": true,
            "preferredTheme": "system"
        ])
    }
    
    @MainActor
    private func setupApp() async {
        logger.info("Setting up app...")
        
        do {
            // Request notification permissions
            try await requestNotificationPermissions()
            
            // Initialize app state
            await AppStateManager.shared.initialize()
            
            logger.info("App setup completed successfully")
        } catch {
            logger.error("Failed to setup app: \(error.localizedDescription)")
        }
    }
    
    private func requestNotificationPermissions() async throws {
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional, .criticalAlert]
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: options)
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            logger.debug("App became active")
            Task { @MainActor in
                await AppStateManager.shared.refreshActiveState()
            }
        case .inactive:
            logger.debug("App became inactive")
        case .background:
            logger.debug("App entered background")
            Task {
                await AppStateManager.shared.saveState()
            }
        @unknown default:
            break
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
