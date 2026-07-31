# Фото-квест

Приложение-квест: показывает текстовое задание на русском, пользователь делает фотографию,
а нейросеть (Core ML + Vision, модель MobileNetV2) проверяет, тот ли объект на снимке.
Успешные фото сохраняются в галерею достижений. Всё работает на устройстве, без интернета.

Минимальная версия iOS: **16.0**. Язык: Swift, UI: SwiftUI, хранение: CoreData.

## Структура проекта

```
PhotoQuest/
├── PhotoQuestApp.swift          — точка входа, корневой TabView
├── Info.plist                   — разрешения камеры и фотоальбома
├── Assets.xcassets/             — иконка и акцентный цвет
├── Models/
│   ├── QuestDefinition.swift    — описание задания (текст, категория, ключевые слова)
│   ├── QuestItem.swift          — CoreData: задание из очереди
│   └── CompletedQuest.swift     — CoreData: выполненное задание (путь к фото)
├── Services/
│   ├── StorageService.swift     — CoreData (модель создаётся в коде) + файлы фото
│   ├── QuestManager.swift       — логика очереди заданий (пропуск → в конец)
│   ├── CameraService.swift      — AVFoundation: сессия, разрешения, съёмка
│   ├── ObjectDetectionService.swift — VNCoreMLRequest: классификация и сравнение со словарём
│   └── ExportService.swift      — PDF со всеми фото и сохранение в системную галерею
├── ViewModels/
│   ├── HomeViewModel.swift      — главный экран (MVVM + Combine/@Published)
│   ├── CameraViewModel.swift    — камера: съёмка → детекция → успех/ошибка
│   └── GalleryViewModel.swift   — галерея: список, удаление, экспорт
├── Views/
│   ├── HomeView.swift           — задание (1/3 экрана), кнопка камеры, прогресс, миниатюры
│   ├── CameraView.swift         — видоискатель AVFoundation, затвор, оверлеи результата
│   ├── GalleryView.swift        — список достижений, свайп-удаление, экспорт
│   └── Components.swift         — карточка задания, ShareSheet, пустое состояние
└── Helpers/
    ├── Constants.swift          — константы, цвета категорий
    ├── QuestLibrary.swift       — словарь ключевых слов + 100 заданий
    └── Extensions.swift         — форматирование дат, хаптики, цвета
```

## Сборка через GitHub Actions (CI)

Проект собирается в облаке на macOS-раннере без локального Xcode:

1. Запушьте репозиторий на GitHub (внизу есть команды).
2. Вкладка **Actions** → воркфлоу **iOS Build** соберёт приложение
   (Release, generic iOS device, без подписи) и выложит **.xcarchive** как artifact
   (вкладка Actions → последний запуск → Artifacts).
3. Модель MobileNetV2 автоматически скачивается в CI (best effort):
   если ни один источник не сработал — сборка продолжается без модели,
   приложение покажет экран «модель не найдена».
4. Запуск воркфлоу вручную: Actions → iOS Build → Run workflow.

Проект `PhotoQuest.xcodeproj` **не хранится в репозитории** — он генерируется
инструментом [XcodeGen](https://github.com/yonaskolb/XcodeGen) из `project.yml`:

```bash
brew install xcodegen   # один раз
xcodegen generate       # создаёт PhotoQuest.xcodeproj
open PhotoQuest.xcodeproj
```

## Сборка в Xcode (пошагово)

1. **Создайте проект**: Xcode → File → New → Project → iOS → App.
   Имя: `PhotoQuest`, Interface: **SwiftUI**, Language: **Swift**.
   В Deployment Target выберите **iOS 16.0**.
2. **Удалите** сгенерированный `ContentView.swift` (или просто не добавляйте файлы поверх).
3. **Перетащите** папки `Models`, `Views`, `ViewModels`, `Services`, `Helpers`
   и файлы `PhotoQuestApp.swift`, `Assets.xcassets` в Xcode.
   В диалоге включите «Copy items if needed» и «Create groups».
4. **Разрешения** (если используете свой Info.plist, добавьте эти ключи во вкладке
   Info target'а):
   - `NSCameraUsageDescription` — «Приложение использует камеру, чтобы распознавать объекты для заданий фото-квеста.»
   - `NSPhotoLibraryAddUsageDescription` — «Чтобы сохранять ваши выполненные задания в фотогалерею.»
   (Либо удалите сгенерированный Info.plist и в Build Settings → Info.plist File
   укажите путь к приложенному `Info.plist`.)
5. **Подпись**: выберите свою команду в Signing & Capabilities.

## Установка модели MobileNetV2 (обязательно)

1. Скачайте `MobileNetV2.mlmodel`:
   - Apple: https://developer.apple.com/machine-learning/models/ (раздел Image Classification)
   - Зеркало на GitHub: https://github.com/hollance/MobileNet-CoreML
   - Прямая ссылка (может меняться): https://docs-assets.developer.apple.com/coreml/models/MobileNetV2.mlmodel
   Подойдёт любая версия MobileNetV2 на 1000 классов ImageNet (224×224).
2. Перетащите файл в Xcode (в корень группы проекта), включите
   **Target Membership** (галочка у вашего target).
3. Xcode автоматически скомпилирует `.mlmodel` в `.mlmodelc` при сборке —
   больше ничего делать не нужно, приложение найдёт модель по имени `MobileNetV2`.

Если модель не добавлена — при открытии камеры появится экран с кнопкой
«Открыть страницу модели», детекция будет недоступна.

## Запуск

- Запускайте на **реальном устройстве** (iPhone): в симуляторе нет камеры,
  и видоискатель не заработает.
- При первом запуске приложение попросит доступ к камере.
- Первый запуск: создаётся очередь из 100 перемешанных заданий (seed в CoreData).

## Как работает проверка фото

1. Снимок (JPEG) отправляется в `ObjectDetectionService`.
2. `VNCoreMLRequest` (MobileNetV2, imageCropAndScaleOption = .centerCrop) классифицирует фото в фоне.
3. Берётся топ-1 результат: идентификатор класса + уверенность.
4. Успех, если уверенность **≥ 0.6** и идентификатор совпал (по словам, в нижнем регистре)
   с одним из английских названий из словаря задания (`QuestKeywords`).
5. Если не совпало — алерт «Это не похоже на …» с кнопками «Переснять»
   и «Сохранить принудительно» (на случай ошибки нейросети).

## Настройка

- Порог уверенности: `Constants.minConfidence` (по умолчанию 0.6).
- Словарь соответствий и задания: `Helpers/QuestLibrary.swift`
  (добавляйте новые группы в `QuestKeywords.all`, а задания — в `QuestLibrary.quests`).
- Задания, которые тяжело распознать (например, «Сфотографируй свою тень»),
  имеют «слабые» ключевые слова — в таких случаях работает кнопка
  «Сохранить принудительно».

## Примечания

- CoreData-модель создаётся программно (без файла `.xcdatamodeld`) — код готов
  к копированию в любой проект без дополнительных настроек.
- Фото хранятся в `Documents/CompletedPhotos`, в базе — путь к файлу.
- Тёмная и светлая тема поддерживаются автоматически (системные цвета +
  `AccentColor` в ассетах).
