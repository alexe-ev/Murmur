# Plan: Audit Remediation

**Date**: 2026-03-05  
**Source audit**: `todo/audit-2026-03-05.md`
**Goal**: закрыть найденные риски без регрессий, итерационно, через небольшие PR.

---

## 1. Strategy

Работа выполняется **итерациями**, не одним PR.

Причины:
- часть фиксов архитектурно связаны и могут ломать друг друга;
- есть блокеры релиза, которые нужно закрыть отдельно и быстро;
- маленькие PR проще ревьюить, откатывать и проверять.

Рекомендуемый формат:
- 1 PR = 1 логический блок (или 2 тесно связанных);
- каждый PR должен быть проверяем независимо;
- после каждого PR: `xcodebuild` + ручной smoke check критического флоу.

---

## 2. Dependency Map

### Сильные зависимости
- `H-01` (единый state записи) <-> `H-02` (MainActor boundary): делать вместе.
- `M-01` (enum-типизация настроек) влияет на `AppDelegate`, `SettingsView`, `TranslationConfig`.
- `M-02` (убрать implicit singleton coupling) зависит от того, как пройдет `M-01`.

### Слабые зависимости
- `C-03` (cleanup temp audio) влияет на обработку ошибок, но можно делать до архитектурных рефакторов.
- `H-03` (clipboard restore) влияет на paste pipeline и тайминги, лучше после стабилизации core flow.

---

## 3. PR Plan

## PR-1: Release blockers (C-01, C-02, C-03)

### Scope
- Добавить privacy usage string для микрофона.
- Привести entitlements в соответствие API-режиму.
- Гарантировать удаление временного аудио при успехе/ошибке/cancel.

### Target files (expected)
- `Murmur/App/Info.plist`
- `Murmur/App/Murmur.entitlements`
- `Murmur/App/AppDelegate.swift`
- `Murmur/Core/AudioRecorder.swift`
- `Murmur/Transcription/LocalWhisperService.swift`
- `Murmur/Transcription/OpenAIWhisperService.swift`

### Done criteria
- запись не остается в temp при любом исходе;
- API backend работает в sandbox режиме;
- permission flow по микрофону проходит корректно.

---

## PR-2: Runtime stability (H-01, H-02, M-03)

### Scope
- единый источник truth для recording state;
- явный переход на `MainActor` из hotkey callback path;
- единая валидация API key (`hasValidAPIKey`).

### Target files (expected)
- `Murmur/Core/HotkeyManager.swift`
- `Murmur/App/AppDelegate.swift`
- `Murmur/Settings/KeychainManager.swift`
- `Murmur/UI/SettingsView.swift`

### Done criteria
- нет рассинхрона между hotkey и фактическим состоянием записи;
- нет неявных actor/thread переходов;
- UI и runtime одинаково интерпретируют "валидный API key".

---

## PR-3: Privacy/Security hardening (H-03, L-02)

### Scope
- режим восстановления буфера обмена после paste;
- явная keychain accessibility policy.

### Target files (expected)
- `Murmur/Core/PasteController.swift`
- `Murmur/Settings/SettingsModel.swift` (если добавляется настройка)
- `Murmur/UI/SettingsView.swift` (если добавляется toggle)
- `Murmur/Settings/KeychainManager.swift`

### Done criteria
- пользовательский clipboard не теряется (по выбранной политике);
- keychain-поведение явно зафиксировано в коде.

---

## PR-4: Type-safety foundation (M-01)

### Scope
- заменить строковые backend/model/language на типы (`enum`).

### Target files (expected)
- `Murmur/Settings/SettingsModel.swift`
- `Murmur/App/AppDelegate.swift`
- `Murmur/Translation/TranslationConfig.swift`
- `Murmur/UI/SettingsView.swift`
- `Murmur/UI/MenuBarController.swift`

### Done criteria
- убраны stringly-typed свитчи по backend/model/language;
- есть безопасная миграция старых значений из `UserDefaults`.

---

## PR-5: Decoupling and readability (M-02, L-01)

### Scope
- убрать hidden coupling сервиса к `TranslationConfig.shared`;
- декомпозировать `AppDelegate` на координирующие компоненты.

### Target files (expected)
- `Murmur/App/AppDelegate.swift`
- `Murmur/Transcription/OpenAIWhisperService.swift`
- возможно новые файлы coordinator/service в `Murmur/App` или `Murmur/Core`

### Done criteria
- сервисы принимают все необходимые параметры явно;
- `AppDelegate` короче и выполняет только orchestration.

---

## PR-6: Quality gates and process (H-05, H-06, H-07, M-05, M-06, L-03)

### Scope
- добавить минимальный автотест-контур;
- закрыть оставшиеся testing tasks в `todo`;
- начать вести `bugs.md` по правилам;
- согласовать toolchain/docs;
- убрать ambiguity по архитектурам сборки;
- обновить устаревшие формулировки статуса проекта.

### Target files (expected)
- `todo/roadmap.md`
- `todo/bugs.md`
- `todo/need-manual-testing.md`
- `ARCHITECTURE.md`
- `CLAUDE.md`
- `Murmur.xcodeproj/project.pbxproj`
- + тестовые файлы/target

### Done criteria
- есть автоматический smoke regression path;
- roadmap/test statuses консистентны факту;
- сборка/документация не противоречат друг другу.

---

## 4. Agent Execution Instructions (for future implementation turns)

Перед началом каждого PR агент обязан:
1. `git checkout main && git pull`.
2. Создать новую ветку `codex/<short-topic>` от актуального `main`.
3. Прочитать:
- `todo/audit-2026-03-05.md`
- этот файл (`todo/audit-remediation-plan.md`)
- связанные epic/task файлы в `todo/`.
4. Подтвердить scope PR (какие именно пункты закрываются).

Во время реализации:
1. Не смешивать unrelated changes.
2. Не трогать служебные артефакты (`.DS_Store`, `.derivedData`, `xcuserdata`).
3. Если правка меняет поведение core flow:
- добавить/обновить тест или минимум детальный manual checklist.
4. Если найден новый баг:
- сразу добавлять запись в `todo/bugs.md`.

Проверка перед коммитом:
1. `xcodebuild -project Murmur.xcodeproj -scheme Murmur -configuration Debug -sdk macosx build`
2. Если добавлены тесты: запустить соответствующий test target.
3. Проверить `git status` и убедиться, что в commit только файлы текущего scope.

Оформление PR:
1. Заголовок: `<type>: <short summary>`.
2. В описании PR указать:
- какие пункты аудита закрыты (`C-..`, `H-..`, ...);
- что осталось открытым и почему;
- какие ручные проверки обязательны.
3. После merge: синхронизировать `main`, удалить ветку.

---

## 5. Risk Controls

Чтобы минимизировать cross-impact:
- любые изменения в `AppDelegate` и `HotkeyManager` проверять сценарием:
  `idle -> recording -> processing -> idle`;
- любые изменения в `PasteController` проверять на сохранность clipboard;
- любые изменения в `SettingsModel` проверять на миграцию уже сохраненных значений;
- любые изменения в `OpenAIWhisperService` проверять для двух кейсов:
  `targetLanguage = en` и `targetLanguage != en`.

---

## 6. Exit Criteria (program-level)

План считается выполненным, когда:
- все пункты из `todo/audit-2026-03-05.md` либо закрыты, либо имеют явно обоснованный defer;
- нет критичных/высоких открытых рисков без владельца и срока;
- roadmap, bug log, manual testing и фактическое состояние проекта совпадают.

