import SwiftUI

struct NotificationCard: View {
    let notification: NotificationItem
    let onEdit: (String) -> Void
    let onCancel: () -> Void
    let onRemove: () -> Void
    
    @State private var isExpanded = false
    @State private var isEditing = false
    @State private var editedContent = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Circle()
                            .fill(Color(notification.status.color))
                            .frame(width: 8, height: 8)
                        
                        Text(notification.status.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if let scheduledDate = notification.scheduledDate {
                            Text("• \(scheduledDate, style: .time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: { isExpanded.toggle() }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.accentColor)
                    }
                    
                    if notification.status == .scheduled || notification.status == .pending {
                        Menu {
                            Button("Редактировать", action: startEditing)
                            Button("Отменить", action: onCancel)
                            Button("Удалить", role: .destructive, action: onRemove)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(.accentColor)
                        }
                    } else if notification.status == .sent || notification.status == .cancelled {
                        Button("Удалить", role: .destructive) {
                            onRemove()
                        }
                    }
                }
            }
            
            if isExpanded {
                Divider()
                
                if isEditing {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Редактирование:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextEditor(text: $editedContent)
                            .frame(minHeight: 60)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        
                        HStack {
                            Button("Отмена") {
                                isEditing = false
                                editedContent = notification.content
                            }
                            .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Сохранить") {
                                onEdit(editedContent)
                                isEditing = false
                            }
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                        }
                    }
                } else {
                    Text(notification.content)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(nil)
                }
            } else {
                Text(notification.preview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            editedContent = notification.content
        }
    }
    
    private func startEditing() {
        editedContent = notification.content
        isEditing = true
        isExpanded = true
    }
}
