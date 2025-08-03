import SwiftUI
import OSLog

struct ContentView: View {
    @StateObject private var viewModel = TextToBandViewModel()
    @EnvironmentObject private var appState: AppStateManager
    @State private var showDatePicker = false
    @State private var selectedTab = 0
    @FocusState private var isTextFieldFocused: Bool
    
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TextToBand", category: "ContentView")
    
    var body: some View {
        TabView(selection: $selectedTab) {
            mainContentView
                .tabItem {
                    Label("Главная", systemImage: "text.bubble")
                }
                .tag(0)
            
            HistoryView(historyManager: viewModel.getHistoryManager())
                .tabItem {
                    Label("История", systemImage: "clock")
                }
                .tag(1)
            
            TemplatesView(templateManager: viewModel.getTemplateManager()) { template in
                // Handle template selection
                viewModel.inputText = template.content
            }
                .tabItem {
                    Label("Шаблоны", systemImage: "doc.text")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gear")
                }
                .tag(3)
        }
        .tint(.accentColor)
        .task {
            if !appState.isInitialized {
                await appState.initialize()
            }
        }
        .alert("Внимание", isPresented: $viewModel.showAlert) {
            Button("OK") { }
        } message: {
            Text(viewModel.alertMessage)
        }
        .sheet(isPresented: $showDatePicker) {
            datePickerSheet
        }
        .sensoryFeedback(.success, trigger: viewModel.notifications.count)
    }
    
    private var mainContentView: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 24) {
                    inputSection
                    actionSection
                    notificationsSection
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .navigationTitle("TextToBand")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Очистить всё", role: .destructive) {
                            Task {
                                await viewModel.clearAllNotifications()
                            }
                        }
                        
                        if !viewModel.inputText.isEmpty {
                            Button("Очистить текст") {
                                withAnimation(.easeInOut) {
                                    viewModel.inputText = ""
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Введите текст")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.inputText.isEmpty {
                    HStack(spacing: 4) {
                        Image(systemName: "character.cursor.ibeam")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        
                        Text("\(viewModel.totalCharacters)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            }
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray6))
                    .stroke(isTextFieldFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                
                TextEditor(text: $viewModel.inputText)
                    .focused($isTextFieldFocused)
                    .font(.body)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(16)
                    .onSubmit {
                        if !viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            viewModel.splitTextIntoNotifications()
                        }
                    }
                
                if viewModel.inputText.isEmpty {
                    Text("Введите текст для разбивки на уведомления...")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(20)
                        .allowsHitTesting(false)
                }
            }
            
            HStack {
                if viewModel.estimatedNotifications > 0 {
                    Label {
                        Text("\(viewModel.estimatedNotifications) уведомлений")
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "bell.badge")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                }
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        viewModel.splitTextIntoNotifications()
                    }
                } label: {
                    Label("Разбить текст", systemImage: "scissors")
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: viewModel.inputText.isEmpty)
    }
    
    private var actionSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        await viewModel.sendNotificationsImmediately()
                    }
                } label: {
                    Label("Отправить сейчас", systemImage: "paperplane.fill")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSendNotifications || viewModel.isProcessing)
                
                Button {
                    showDatePicker = true
                } label: {
                    Label("Запланировать", systemImage: "clock")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(!viewModel.canSendNotifications || viewModel.isProcessing)
            }
            
            if viewModel.canSendNotifications {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "clock.badge")
                            .foregroundStyle(.secondary)
                        
                        Text("Запланировано на \(viewModel.selectedDate, style: .time)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button("Очистить всё", role: .destructive) {
                            Task {
                                await viewModel.clearAllNotifications()
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                    }
                    
                    if !appState.hasNotificationPermission {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text("Нет разрешения на уведомления")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            
                            Spacer()
                            
                            Button("Настройки") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !viewModel.notifications.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Уведомления")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Text("\(viewModel.notifications.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
                            .foregroundStyle(.tint)
                    }
                    
                    LazyVStack(spacing: 16) {
                        ForEach(Array(viewModel.notifications.enumerated()), id: \.element.id) { index, notification in
                            NotificationCard(
                                notification: notification,
                                onEdit: { newContent in
                                    viewModel.updateNotificationContent(at: index, newContent: newContent)
                                },
                                onCancel: {
                                    Task {
                                        await viewModel.cancelNotification(at: index)
                                    }
                                },
                                onRemove: {
                                    Task {
                                        await viewModel.removeNotification(at: index)
                                    }
                                }
                            )
                            .transition(.asymmetric(
                                insertion: .scale.combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            ))
                        }
                    }
                }
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
            } else if !viewModel.inputText.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.tertiary)
                    
                    Text("Нет уведомлений")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Разбейте текст на уведомления, чтобы начать")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.regularMaterial)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                }
            }
        }
    }
    
    private var datePickerSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Text("Выберите время отправки")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("Уведомления будут отправлены с интервалом \(Int(viewModel.selectedInterval)) секунд")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                DatePicker(
                    "Время отправки",
                    selection: $viewModel.selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)
                
                VStack(spacing: 12) {
                    Text("Интервал между уведомлениями")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Picker("Интервал", selection: $viewModel.selectedInterval) {
                        ForEach(viewModel.availableIntervals, id: \.self) { interval in
                            Text("\(Int(interval)) сек")
                                .tag(interval)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)
                
                Button {
                    Task {
                        await viewModel.scheduleNotifications()
                    }
                    showDatePicker = false
                } label: {
                    Label("Запланировать отправку", systemImage: "calendar.badge.plus")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(viewModel.isProcessing)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Планирование")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Отмена") {
                        showDatePicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    ContentView()
}
