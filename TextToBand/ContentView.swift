import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = TextToBandViewModel()
    @State private var showDatePicker = false
    @State private var showingHistory = false
    @State private var showingTemplates = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    quickActionsSection
                    inputSection
                    actionSection
                    notificationsSection
                }
                .padding()
            }
            .navigationTitle("TextToBand")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Настройки") {
                        showingSettings = true
                    }
                }
            }
            .alert("Уведомление", isPresented: $viewModel.showAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.alertMessage)
            }
            .sheet(isPresented: $showDatePicker) {
                datePickerSheet
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView()
            }
            .sheet(isPresented: $showingTemplates) {
                TemplatesView { template in
                    applyTemplate(template)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button("История") {
                showingHistory = true
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Шаблоны") {
                showingTemplates = true
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
            
            Button("Экспорт") {
                viewModel.exportBackup()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Введите текст")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.inputText.isEmpty {
                    Text("\(viewModel.totalCharacters) символов")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            TextEditor(text: $viewModel.inputText)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                if viewModel.estimatedNotifications > 0 {
                    Label("\(viewModel.estimatedNotifications) уведомлений", systemImage: "bell.badge")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Разбить текст") {
                    viewModel.splitTextIntoNotifications()
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var actionSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("Отправить сейчас") {
                    Task {
                        await viewModel.sendNotificationsImmediately()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSendNotifications || viewModel.isProcessing)
                .frame(maxWidth: .infinity)
                
                Button("Отправить через") {
                    showDatePicker = true
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canSendNotifications || viewModel.isProcessing)
                .frame(maxWidth: .infinity)
            }
            
            if viewModel.canSendNotifications {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.secondary)
                    
                    Text("Запланировано на \(viewModel.selectedDate, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Очистить все") {
                        viewModel.clearAllNotifications()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !viewModel.notifications.isEmpty {
                HStack {
                    Text("Уведомления")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(viewModel.notifications.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.2))
                        .cornerRadius(8)
                }
                
                LazyVStack(spacing: 12) {
                    ForEach(Array(viewModel.notifications.enumerated()), id: \.element.id) { index, notification in
                        NotificationCard(
                            notification: notification,
                            onEdit: { newContent in
                                viewModel.updateNotificationContent(at: index, newContent: newContent)
                            },
                            onCancel: {
                                viewModel.cancelNotification(at: index)
                            },
                            onRemove: {
                                viewModel.removeNotification(at: index)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var datePickerSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker(
                    "Время отправки",
                    selection: $viewModel.selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                
                Button("Запланировать отправку") {
                    Task {
                        await viewModel.scheduleNotifications()
                    }
                    showDatePicker = false
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(viewModel.isProcessing)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Выберите время")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Отмена") {
                    showDatePicker = false
                }
            )
        }
    
    private func applyTemplate(_ template: TextTemplate) {
        viewModel.inputText = template.content
        showingTemplates = false
    }
}

#Preview {
    ContentView()
}
