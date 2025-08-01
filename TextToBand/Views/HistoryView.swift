import SwiftUI

struct HistoryView: View {
    @ObservedObject var historyManager: HistoryManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                if historyManager.historyItems.isEmpty {
                    EmptyHistoryView()
                } else {
                    List {
                        ForEach(historyManager.historyItems) { item in
                            HistoryItemRow(item: item, historyManager: historyManager)
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
            }
            .navigationTitle("История")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Очистить") {
                        showingClearAlert = true
                    }
                    .disabled(historyManager.historyItems.isEmpty)
                }
            }
            .alert("Очистить историю", isPresented: $showingClearAlert) {
                Button("Отмена", role: .cancel) { }
                Button("Очистить", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("Это действие нельзя отменить")
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            historyManager.deleteHistoryItem(historyManager.historyItems[index])
        }
    }
}

struct HistoryItemRow: View {
    let item: HistoryItem
    let historyManager: HistoryManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Circle()
                            .fill(Color(item.status.color))
                            .frame(width: 8, height: 8)
                        
                        Text(item.status.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text(item.createdDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(item.totalNotifications) уведомлений")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let sentDate = item.sentDate {
                        Text("Отправлено: \(sentDate, style: .time)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.accentColor)
                }
            }
            
            if isExpanded {
                Divider()
                
                Text(item.originalText)
                    .font(.body)
                    .padding(.vertical, 4)
                    .textSelection(.enabled)
            } else {
                Text(item.originalText.count > 100 ? 
                     String(item.originalText.prefix(100)) + "..." : 
                     item.originalText)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("История пуста")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Отправленные тексты будут появляться здесь")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
