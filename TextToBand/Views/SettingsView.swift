import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingImportPicker = false
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            List {
                notificationSection
                historySection
                templatesSection
                backupSection
                aboutSection
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сбросить") {
                        viewModel.resetSettings()
                    }
                    .foregroundColor(.red)
                }
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                viewModel.handleImport(result)
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = viewModel.backupFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    
    private var notificationSection: some View {
        Section("Уведомления") {
            HStack {
                Text("Символов в уведомлении")
                Spacer()
                TextField("100", value: $viewModel.maxCharacters, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Интервал между уведомлениями")
                Picker("Интервал", selection: $viewModel.selectedInterval) {
                    ForEach(viewModel.availableIntervals, id: \.self) { interval in
                        Text(viewModel.formatInterval(interval))
                            .tag(interval)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            HStack {
                Text("Префикс заголовка")
                Spacer()
                TextField("Уведомление", text: $viewModel.titlePrefix)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 120)
            }
        }
    }
    
    private var historySection: some View {
        Section("История") {
            Toggle("Отслеживать историю", isOn: $viewModel.enableHistory)
            
            if viewModel.enableHistory {
                HStack {
                    Text("Максимум записей")
                    Spacer()
                    TextField("100", value: $viewModel.maxHistoryItems, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
                
                Toggle("Автоудаление старых записей", isOn: $viewModel.autoDeleteOldHistory)
                
                if viewModel.autoDeleteOldHistory {
                    HStack {
                        Text("Хранить дней")
                        Spacer()
                        TextField("30", value: $viewModel.historyRetentionDays, formatter: NumberFormatter())
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                    }
                }
            }
        }
    }
    
    private var templatesSection: some View {
        Section("Шаблоны") {
            Toggle("Включить шаблоны", isOn: $viewModel.enableTemplates)
            
            if viewModel.enableTemplates {
                HStack {
                    Text("Максимум шаблонов")
                    Spacer()
                    TextField("50", value: $viewModel.maxTemplates, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                }
            }
        }
    }
    
    private var backupSection: some View {
        Section("Резервные копии") {
            Toggle("Включить резервное копирование", isOn: $viewModel.enableBackup)
            
            if viewModel.enableBackup {
                Button("Экспортировать настройки") {
                    Task {
                        await viewModel.exportSettings()
                        if viewModel.backupFileURL != nil {
                            showingShareSheet = true
                        }
                    }
                }
                .disabled(viewModel.isExporting)
                
                Button("Импортировать настройки") {
                    showingImportPicker = true
                }
                .foregroundColor(.accentColor)
            }
        }
    }
    
    private var aboutSection: some View {
        Section("О приложении") {
            HStack {
                Text("Версия")
                Spacer()
                Text(viewModel.appVersion)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("Размер данных")
                Spacer()
                Text(viewModel.dataSize)
                    .foregroundColor(.secondary)
            }
            
            Button("Очистить все данные") {
                viewModel.clearAllData()
            }
            .foregroundColor(.red)
        }
    }
}

class SettingsViewModel: ObservableObject {
    @Published var maxCharacters: Int = 100
    @Published var selectedInterval: TimeInterval = 60
    @Published var titlePrefix: String = "Уведомление"
    @Published var enableHistory: Bool = true
    @Published var maxHistoryItems: Int = 100
    @Published var autoDeleteOldHistory: Bool = true
    @Published var historyRetentionDays: Int = 30
    @Published var enableTemplates: Bool = true
    @Published var maxTemplates: Int = 50
    @Published var enableBackup: Bool = true
    @Published var backupFileURL: URL?
    @Published var isExporting: Bool = false
    
    private var settings = AppSettings.load()
    private let backupManager = BackupManager()
    
    let availableIntervals: [TimeInterval] = [10, 30, 60, 120, 300, 600]
    
    var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    var dataSize: String {
        let bytes = calculateDataSize()
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        maxCharacters = settings.maxCharactersPerNotification
        selectedInterval = settings.defaultDelayBetweenNotifications
        titlePrefix = settings.notificationTitlePrefix
        enableHistory = settings.enableHistoryTracking
        maxHistoryItems = settings.maxHistoryItems
        autoDeleteOldHistory = settings.autoDeleteOldHistory
        historyRetentionDays = settings.historyRetentionDays
        enableTemplates = settings.enableTemplates
        maxTemplates = settings.maxTemplates
        enableBackup = settings.enableBackup
    }
    
    private func saveSettings() {
        settings.maxCharactersPerNotification = maxCharacters
        settings.defaultDelayBetweenNotifications = selectedInterval
        settings.notificationTitlePrefix = titlePrefix
        settings.enableHistoryTracking = enableHistory
        settings.maxHistoryItems = maxHistoryItems
        settings.autoDeleteOldHistory = autoDeleteOldHistory
        settings.historyRetentionDays = historyRetentionDays
        settings.enableTemplates = enableTemplates
        settings.maxTemplates = maxTemplates
        settings.enableBackup = enableBackup
        settings.save()
    }
    
    func formatInterval(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "\(Int(interval))с"
        } else if interval < 3600 {
            return "\(Int(interval / 60))м"
        } else {
            return "\(Int(interval / 3600))ч"
        }
    }
    
    func exportSettings() async {
        saveSettings()
        isExporting = true
        
        let historyManager = HistoryManager()
        let templateManager = TemplateManager()
        
        if let fileURL = await backupManager.exportBackup(
            settings: settings,
            templates: templateManager.templates,
            historyItems: historyManager.historyItems
        ) {
            self.backupFileURL = fileURL
        }
        
        isExporting = false
    }
    
    func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            
            if let backupData = backupManager.importBackup(from: url),
               backupManager.validateBackup(backupData) {
                
                settings = backupData.settings
                settings.save()
                loadSettings()
                
                let historyManager = HistoryManager()
                let templateManager = TemplateManager()
                
                historyManager.historyItems = backupData.historyItems
                templateManager.templates = backupData.templates
            }
            
        case .failure(let error):
            print("Ошибка импорта: \(error)")
        }
    }
    
    func resetSettings() {
        settings.resetToDefaults()
        loadSettings()
    }
    
    func clearAllData() {
        let historyManager = HistoryManager()
        let templateManager = TemplateManager()
        
        historyManager.clearHistory()
        templateManager.templates.removeAll()
        settings.resetToDefaults()
        loadSettings()
    }
    
    private func calculateDataSize() -> Int {
        var size = 0
        
        let historyData = UserDefaults.standard.data(forKey: "TextToBandHistory")
        size += historyData?.count ?? 0
        
        let templatesData = UserDefaults.standard.data(forKey: "TextToBandTemplates")
        size += templatesData?.count ?? 0
        
        let settingsData = UserDefaults.standard.data(forKey: "AppSettings")
        size += settingsData?.count ?? 0
        
        return size
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
