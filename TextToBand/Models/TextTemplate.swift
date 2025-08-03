import Foundation

struct TextTemplate: Identifiable, Codable {
    var id = UUID()
    var name: String
    var content: String
    let createdDate: Date
    var usageCount: Int
    
    init(name: String, content: String) {
        self.name = name
        self.content = content
        self.createdDate = Date()
        self.usageCount = 0
    }
}

class TemplateManager: ObservableObject {
    @Published var templates: [TextTemplate] = []
    
    private let userDefaults = UserDefaults.standard
    private let templatesKey = "TextToBandTemplates"
    private let hasCreatedDefaultsKey = "TextToBandHasCreatedDefaultTemplates"
    
    init() {
        loadTemplates()
        createDefaultTemplatesIfNeeded()
    }
    
    func addTemplate(name: String, content: String) {
        let template = TextTemplate(name: name, content: content)
        templates.append(template)
        saveTemplates()
    }
    
    func updateTemplate(_ template: TextTemplate, name: String, content: String) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].name = name
            templates[index].content = content
            saveTemplates()
        }
    }
    
    func deleteTemplate(_ template: TextTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    func useTemplate(_ template: TextTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index].usageCount += 1
            saveTemplates()
        }
    }
    
    private func createDefaultTemplatesIfNeeded() {
        // Создаем шаблоны по умолчанию только если они никогда не создавались
        let hasCreatedDefaults = userDefaults.bool(forKey: hasCreatedDefaultsKey)
        
        if !hasCreatedDefaults && templates.isEmpty {
            let defaultTemplates = [
                TextTemplate(name: "Встреча", content: "Напоминание о встрече в [время] по адресу [адрес]. Не забудьте взять с собой документы."),
                TextTemplate(name: "Лекарство", content: "Время принять лекарство [название]. Дозировка: [дозировка]. Следующий прием через [время]."),
                TextTemplate(name: "Тренировка", content: "Время тренировки! Сегодня в программе: [упражнения]. Не забудьте взять воду и полотенце."),
                TextTemplate(name: "Покупки", content: "Список покупок: [список]. Не забудьте проверить скидки и акции в магазине.")
            ]
            
            templates = defaultTemplates
            saveTemplates()
            userDefaults.set(true, forKey: hasCreatedDefaultsKey)
        }
    }
    
    private func loadTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey),
              let templates = try? JSONDecoder().decode([TextTemplate].self, from: data) else {
            return
        }
        self.templates = templates
    }
    
    private func saveTemplates() {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        userDefaults.set(data, forKey: templatesKey)
    }
}
