import SwiftUI

struct TemplatesView: View {
    @ObservedObject var templateManager: TemplateManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddTemplate = false
    
    var onTemplateSelected: (TextTemplate) -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                if templateManager.templates.isEmpty {
                    EmptyTemplatesView()
                } else {
                    List {
                        ForEach(templateManager.templates) { template in
                            TemplateRow(
                                template: template,
                                templateManager: templateManager,
                                onSelect: {
                                    onTemplateSelected(template)
                                    dismiss()
                                }
                            )
                        }
                        .onDelete(perform: deleteTemplates)
                    }
                }
            }
            .navigationTitle("Шаблоны")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTemplate = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplateView(templateManager: templateManager)
            }
        }
    }
    
    private func deleteTemplates(offsets: IndexSet) {
        for index in offsets {
            templateManager.deleteTemplate(templateManager.templates[index])
        }
    }
}

struct TemplateRow: View {
    let template: TextTemplate
    let templateManager: TemplateManager
    let onSelect: () -> Void
    @State private var showingEditTemplate = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text("Использований: \(template.usageCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(template.createdDate, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button("Редактировать") {
                    showingEditTemplate = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            
            Text(template.content.count > 150 ? 
                 String(template.content.prefix(150)) + "..." : 
                 template.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
        .sheet(isPresented: $showingEditTemplate) {
            EditTemplateView(template: template, templateManager: templateManager)
        }
    }
}

struct AddTemplateView: View {
    @ObservedObject var templateManager: TemplateManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var content = ""
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Название")
                        .font(.headline)
                    
                    TextField("Введите название шаблона", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Содержимое")
                        .font(.headline)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                Text("Используйте [переменные] для создания настраиваемых шаблонов")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Новый шаблон")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        templateManager.addTemplate(name: name, content: content)
                        dismiss()
                    }
                    .disabled(name.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

struct EditTemplateView: View {
    let template: TextTemplate
    @ObservedObject var templateManager: TemplateManager
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var content: String
    
    init(template: TextTemplate, templateManager: TemplateManager) {
        self.template = template
        self.templateManager = templateManager
        _name = State(initialValue: template.name)
        _content = State(initialValue: template.content)
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Название")
                        .font(.headline)
                    
                    TextField("Введите название шаблона", text: $name)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Содержимое")
                        .font(.headline)
                    
                    TextEditor(text: $content)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                HStack {
                    Text("Использований: \(template.usageCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("Создан: \(template.createdDate, style: .date)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Редактировать")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Сохранить") {
                        templateManager.updateTemplate(template, name: name, content: content)
                        dismiss()
                    }
                    .disabled(name.isEmpty || content.isEmpty)
                }
            }
        }
    }
}

struct EmptyTemplatesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("Нет шаблонов")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Создавайте шаблоны для быстрого доступа к часто используемым текстам")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
