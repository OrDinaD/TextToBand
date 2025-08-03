import Foundation
import SwiftUI
import Combine
import OSLog

/// Manages global app state and provides centralized access to core services
@MainActor
final class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var isInitialized = false
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var isOnline = true
    @Published var errorMessage: String?
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TextToBand", category: "AppState")
    private var cancellables = Set<AnyCancellable>()
    
    // Core services
    lazy var notificationManager = NotificationManager.shared
    lazy var backupManager = BackupManager()
    lazy var settings = AppSettings.load()
    
    private init() {
        setupNetworkMonitoring()
        setupNotificationObservers()
    }
    
    func initialize() async {
        guard !isInitialized else { return }
        
        logger.info("Initializing app state...")
        
        // Check notification permissions
        await updateNotificationPermissionStatus()
        
        // Initialize core services
        await initializeCoreServices()
        
        isInitialized = true
        logger.info("App state initialized successfully")
    }
    
    func refreshActiveState() async {
        await updateNotificationPermissionStatus()
        // Refresh any data that might have changed while app was in background
    }
    
    func saveState() async {
        // Save any pending state changes
        logger.debug("Saving app state...")
    }
    
    private func updateNotificationPermissionStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationPermissionStatus = settings.authorizationStatus
    }
    
    private func initializeCoreServices() async {
        // Initialize notification manager
        await notificationManager.initialize()
        
        // Create default templates if needed
        if !UserDefaults.standard.bool(forKey: "hasCreatedDefaultTemplates") {
            // Create default templates logic here
            UserDefaults.standard.set(true, forKey: "hasCreatedDefaultTemplates")
        }
    }
    
    private func setupNetworkMonitoring() {
        // Monitor network connectivity for backup/sync features
        // This is a simplified implementation - in production, you'd use Network.framework
        
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                // Check connectivity periodically
                self.isOnline = true // Simplified for demo
            }
            .store(in: &cancellables)
    }
    
    private func setupNotificationObservers() {
        // Listen for app lifecycle notifications
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { _ in
                Task { @MainActor in
                    await self.refreshActiveState()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { _ in
                Task {
                    await self.saveState()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Helper Extensions
extension AppStateManager {
    var hasNotificationPermission: Bool {
        notificationPermissionStatus == .authorized || notificationPermissionStatus == .provisional
    }
    
    var canSendNotifications: Bool {
        hasNotificationPermission && isOnline
    }
}
