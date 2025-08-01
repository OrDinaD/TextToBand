# 🤝 Contributing to TextToBand

Спасибо за интерес к улучшению TextToBand! Мы приветствуем вклад от сообщества.

## 🚀 Как внести вклад

### 1. Подготовка среды

```bash
# Fork репозитория на GitHub
# Клонируйте ваш fork
git clone https://github.com/yourusername/TextToBand.git
cd TextToBand

# Добавьте upstream remote
git remote add upstream https://github.com/originalowner/TextToBand.git
```

### 2. Создание ветки

```bash
# Создайте ветку для новой функции
git checkout -b feature/your-feature-name

# Или для исправления бага
git checkout -b bugfix/issue-description
```

### 3. Разработка

- Следуйте стилю кода проекта
- Добавляйте тесты для новой функциональности
- Обновляйте документацию при необходимости
- Проверяйте сборку перед отправкой

```bash
# Проверка сборки
xcodebuild -scheme TextToBand -destination 'platform=iOS Simulator,name=iPhone 16' build

# Запуск тестов
xcodebuild -scheme TextToBand -destination 'platform=iOS Simulator,name=iPhone 16' test
```

### 4. Commit и Push

```bash
# Коммит изменений
git add .
git commit -m "feat: add new amazing feature"

# Push в ваш fork
git push origin feature/your-feature-name
```

### 5. Pull Request

- Создайте Pull Request в основной репозиторий
- Опишите изменения подробно
- Укажите связанные issue (если есть)
- Дождитесь review

## 📝 Стиль кода

### Swift Style Guide

- Используйте 4 пробела для отступов
- Максимальная длина строки: 120 символов
- Следуйте [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)

```swift
// ✅ Хорошо
func processNotification(with content: String, delay: TimeInterval) {
    // implementation
}

// ❌ Плохо
func processNotification(content:String,delay:TimeInterval){
    // implementation
}
```

### SwiftUI Conventions

- Используйте `@StateObject` для создания объектов
- Используйте `@ObservedObject` для передачи объектов
- Разделяйте View на логические computed properties

```swift
// ✅ Хорошо
private var headerSection: some View {
    VStack {
        // содержимое
    }
}

// ❌ Плохо - всё в одном body
var body: some View {
    VStack {
        // много кода
    }
}
```

## 🧪 Тестирование

### Требования к тестам

- Покрывайте новую функциональность unit-тестами
- Добавляйте UI тесты для новых экранов
- Все тесты должны проходить

### Структура тестов

```swift
class YourFeatureTests: XCTestCase {
    var sut: YourFeature!
    
    override func setUp() {
        super.setUp()
        sut = YourFeature()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    func testYourFeature_WhenCondition_ShouldBehavior() {
        // Given
        // When
        // Then
    }
}
```

## 📋 Типы вкладов

### 🐛 Исправление багов
- Опишите проблему
- Добавьте тест, воспроизводящий баг
- Исправьте проблему
- Убедитесь, что тест проходит

### ✨ Новые функции
- Обсудите идею в issue
- Спроектируйте API
- Реализуйте функцию
- Добавьте тесты и документацию

### 📚 Документация
- README.md улучшения
- Комментарии в коде
- Примеры использования

### 🌍 Локализация
- Добавление новых языков
- Улучшение существующих переводов

## 🔍 Code Review

### Что мы проверяем

- Функциональность работает корректно
- Код следует стилю проекта
- Есть тесты для новой функциональности
- Документация обновлена
- Нет breaking changes

### Процесс review

1. Автоматические проверки (CI)
2. Manual code review
3. Тестирование функциональности
4. Merge после одобрения

## 🚨 Сообщение об ошибках

### Template для bug report

```markdown
**Описание бага**
Краткое описание проблемы.

**Шаги воспроизведения**
1. Перейти к '...'
2. Нажать на '....'
3. Прокрутить вниз до '....'
4. Увидеть ошибку

**Ожидаемое поведение**
Что должно было произойти.

**Скриншоты**
Если применимо, добавьте скриншоты.

**Устройство:**
 - Device: [e.g. iPhone 15]
 - OS: [e.g. iOS 18.5]
 - Version [e.g. 1.0]
```

## 💡 Feature Request

### Template для предложений

```markdown
**Описание функции**
Краткое описание желаемой функции.

**Проблема**
Какую проблему это решает?

**Предлагаемое решение**
Как это должно работать?

**Альтернативы**
Рассматривали ли другие варианты?

**Дополнительный контекст**
Любая дополнительная информация.
```

## 📞 Связь

- **Issues** - для багов и предложений
- **Discussions** - для общих вопросов
- **Email** - для приватных вопросов

## 🙏 Спасибо

Каждый вклад ценен! Спасибо за помощь в улучшении TextToBand.

---

Happy coding! 🚀
