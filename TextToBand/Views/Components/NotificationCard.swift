import SwiftUI

struct NotificationCard: View {
    let notification: NotificationItem
    let onEdit: (String) -> Void
    let onCancel: () -> Void
    let onRemove: () -> Void
    
    @State private var isExpanded = false
    @State private var isEditing = false
    @State private var editedContent = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            
            if isExpanded {
                contentSection
                actionsSection
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(notification.status.color.opacity(0.3), lineWidth: 1)
                }
        }
        .onAppear {
            editedContent = notification.content
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isExpanded)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isEditing)
    }
    
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(notification.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    statusBadge
                }
                
                if let scheduledDate = notification.scheduledDate {
                    Label {
                        Text(scheduledDate, style: .relative)
                            .monospacedDigit()
                    } icon: {
                        Image(systemName: "clock")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                if !isExpanded {
                    Text(notification.content)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
            }
            
            Button {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(notification.status.color)
                .frame(width: 6, height: 6)
            
            Text(notification.status.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(notification.status.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
        .foregroundStyle(notification.status.color)
    }
                        private var contentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isEditing {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Редактирование содержимого")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $editedContent)
                        .focused($isTextFieldFocused)
                        .font(.body)
                        .frame(minHeight: 80)
                        .padding(12)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isTextFieldFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                        }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Содержимое")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    
                    Text(notification.content)
                        .font(.body)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .textSelection(.enabled)
                }
            }
        }
    }
    
    private var actionsSection: some View {
        HStack(spacing: 12) {
            if isEditing {
                Button("Отмена") {
                    withAnimation {
                        isEditing = false
                        editedContent = notification.content
                        isTextFieldFocused = false
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Сохранить") {
                    withAnimation {
                        onEdit(editedContent)
                        isEditing = false
                        isTextFieldFocused = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            } else {
                if notification.status == .scheduled || notification.status == .pending {
                    Button {
                        startEditing()
                    } label: {
                        Label("Редактировать", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button {
                        onCancel()
                    } label: {
                        Label("Отменить", systemImage: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    
                    Button(role: .destructive) {
                        onRemove()
                    } label: {
                        Label("Удалить", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            Spacer()
            
            if !isEditing {
                Text("\(notification.content.count) символов")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
    }
    
    private func startEditing() {
        withAnimation {
            isEditing = true
            editedContent = notification.content
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
    }
}
