# TextToBand - Development Guide

## 🚀 Быстрый старт

### Требования
- macOS 13.0+
- Xcode 15.0+
- iOS 16.0+ SDK
- Git 2.30+

### Установка
```bash
# Клонируем репозиторий
git clone https://github.com/OrDinaD/TextToBand.git
cd TextToBand

# Открываем проект в Xcode
open TextToBand.xcodeproj

# Или используем Xcode из командной строки
xed .
```

### Первый запуск
1. Выберите симулятор или подключенное устройство
2. Нажмите ⌘+R для запуска
3. Разрешите уведомления в симуляторе/устройстве

## 🏗 Архитектура проекта

```
TextToBand/
├── Models/           # Модели данных (Codable)
│   ├── HistoryItem.swift
│   ├── Template.swift
│   ├── NotificationSettings.swift
│   └── ExportData.swift
├── Services/         # Сервисы и бизнес-логика
│   ├── NotificationService.swift
│   ├── BackupService.swift
│   └── SettingsService.swift
├── ViewModels/       # MVVM ViewModels
│   └── MainViewModel.swift
├── Views/            # SwiftUI Views
│   ├── ContentView.swift
│   ├── SettingsView.swift
│   ├── HistoryView.swift
│   └── TemplatesView.swift
└── Components/       # Переиспользуемые компоненты
    └── CardView.swift
```

## 📝 Соглашения кодирования

### Swift Style Guide
- Следуем [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Используем 4 пробела для отступов
- Максимальная длина строки: 120 символов
- Используем `// MARK:` для разделения секций

### Комментарии
```swift
// MARK: - Properties
private let notificationService = NotificationService()

// MARK: - Lifecycle
override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
}

// MARK: - Private Methods
private func setupUI() {
    // Implementation
}
```

### Conventional Commits
Используем формат: `type(scope): description`

**Типы коммитов:**
- `feat`: новая функциональность
- `fix`: исправление бага
- `docs`: изменения в документации
- `style`: форматирование, отсутствующие точки с запятой и т.д.
- `refactor`: рефакторинг кода
- `test`: добавление тестов
- `chore`: обновление сборки, зависимостей и т.д.

**Примеры:**
```bash
feat(notifications): add interval settings
fix(ui): resolve navigation bar color issue
docs(readme): update installation instructions
```

## 🧪 Тестирование

### Запуск тестов
```bash
# Все тесты
xcodebuild test -project TextToBand.xcodeproj -scheme TextToBand -destination 'platform=iOS Simulator,name=iPhone 15'

# Только unit тесты
xcodebuild test -project TextToBand.xcodeproj -scheme TextToBand -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:TextToBandTests

# Только UI тесты
xcodebuild test -project TextToBand.xcodeproj -scheme TextToBand -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:TextToBandUITests
```

### Написание тестов
- Unit тесты для ViewModels и Services
- UI тесты для критических пользовательских сценариев
- Минимум 80% покрытие кода

## 🔧 Сборка и развертывание

### Debug сборка
```bash
xcodebuild -project TextToBand.xcodeproj -scheme TextToBand -configuration Debug
```

### Release сборка
```bash
xcodebuild -project TextToBand.xcodeproj -scheme TextToBand -configuration Release
```

### Автоматические релизы
1. Создайте тег: `git tag v1.1.0`
2. Отправьте тег: `git push origin v1.1.0`
3. GitHub Actions автоматически создаст релиз

## 🐛 Отладка

### Общие проблемы

**Уведомления не работают:**
1. Проверьте разрешения в настройках симулятора
2. Убедитесь, что фоновый режим включен
3. Проверьте консоль на ошибки UNUserNotificationCenter

**Настройки не сохраняются:**
1. Проверьте UserDefaults в отладчике
2. Убедитесь в корректности ключей
3. Проверьте JSON сериализацию

### Полезные команды отладки
```bash
# Очистка DerivedData
rm -rf ~/Library/Developer/Xcode/DerivedData

# Сброс симулятора
xcrun simctl erase all

# Просмотр логов симулятора
xcrun simctl spawn booted log stream --predicate 'subsystem contains "TextToBand"'
```

## 📱 Совместимость устройств

### Поддерживаемые устройства
- iPhone 8 и новее
- iPad (6-го поколения) и новее
- iOS 16.0+

### Тестирование на устройствах
- iPhone SE (3rd generation) - минимальный экран
- iPhone 15 Pro Max - максимальный экран
- iPad Pro 12.9" - планшет

## 🔄 Git Workflow

### Ветки
- `main` - стабильная версия
- `develop` - разработка новых функций
- `feature/feature-name` - отдельные функции
- `fix/bug-description` - исправления багов

### Pull Request процесс
1. Создайте ветку от `develop`
2. Внесите изменения
3. Напишите тесты
4. Создайте PR с детальным описанием
5. Дождитесь ревью и прохождения CI

## 📚 Полезные ресурсы

### Apple Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [UserNotifications Framework](https://developer.apple.com/documentation/usernotifications)
- [Settings Bundle](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/UserDefaults/Preferences/Preferences.html)

### External Resources
- [Mi Band Protocol](https://github.com/vshymanskyy/miband-js)
- [iOS Notification Best Practices](https://developer.apple.com/design/human-interface-guidelines/notifications)

## 🆘 Получение помощи

1. **Документация:** Проверьте README.md и комментарии в коде
2. **Issues:** Поищите существующие проблемы в GitHub Issues
3. **Discussions:** Используйте GitHub Discussions для вопросов
4. **Code Review:** Создайте draft PR для получения раннего feedback

## 🎯 Roadmap

### v1.1.0 (планируется)
- [ ] Поддержка Apple Watch
- [ ] Виджеты для быстрого доступа
- [ ] Синхронизация через iCloud

### v1.2.0 (планируется)
- [ ] Интеграция с Shortcuts
- [ ] Групповые шаблоны
- [ ] Расширенная аналитика

### v2.0.0 (планируется)
- [ ] Прямая интеграция с Mi Band через Bluetooth
- [ ] Кроссплатформенная синхронизация
- [ ] Premium функции
