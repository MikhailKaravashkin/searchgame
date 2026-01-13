# Contributing Guide

## Методология разработки

Проект следует строгому workflow для каждой задачи.

## Workflow

```
┌─────────────────┐
│  1. Create      │
│     Issue       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  2. Write       │
│  User Stories   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  3. Write       │
│     Tests       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  4. Implement   │
│     Code        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  5. Self        │
│     Review      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  6. Verify      │
│  User Stories   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  7. Run         │
│     Tests       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  8. Merge       │
│     to main     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  9. Close       │
│     Issue       │
└─────────────────┘
```

## Детальное описание шагов

### 1. Создать GitHub Issue

```bash
gh issue create --title "Phase 1: GameScene с панорамной прокруткой" \
  --body "$(cat <<EOF
## User Stories
- [ ] Как игрок, я хочу видеть большую картинку-сцену
- [ ] Как игрок, я хочу перемещать сцену свайпом
- [ ] Как игрок, я хочу чтобы сцена не выходила за границы

## Acceptance Criteria
- [ ] Фон загружается и отображается
- [ ] Pan gesture работает плавно
- [ ] Границы сцены соблюдаются

## Technical Tasks
- [ ] Создать GameScene.swift
- [ ] Добавить UIPanGestureRecognizer
- [ ] Реализовать ограничение границ
EOF
)" \
  --label "enhancement"
```

### 2. Написать User Stories

В теле Issue описываем:
- **User Stories** — что хочет пользователь
- **Acceptance Criteria** — как проверить что сделано
- **Technical Tasks** — технические подзадачи

### 3. Создать ветку и написать тесты (TDD)

```bash
# Создать feature branch
git checkout -b feature/game-scene-mvp

# Сначала пишем falling tests
# Tests должны падать до реализации!
```

### 4. Реализовать код

- Писать код пока все тесты не пройдут
- Следовать архитектуре проекта
- Использовать существующие абстракции

### 5. Self Code Review

Чеклист для самопроверки:
- [ ] Код соответствует стилю проекта
- [ ] Нет хардкода (магических чисел, строк)
- [ ] Есть комментарии для сложной логики
- [ ] Нет закомментированного кода
- [ ] Нет print/debugPrint в продакшн коде
- [ ] Правильные access modifiers (private где нужно)

### 6. Проверить User Stories

Пройти по каждой User Story в Issue и отметить:
- Запустить приложение
- Проверить каждый сценарий руками
- Отметить выполненные чекбоксы

### 7. Запустить все тесты

```bash
# Unit тесты
xcodebuild test \
  -scheme SearchGame \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:SearchGameTests

# UI тесты (если есть)
xcodebuild test \
  -scheme SearchGame \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:SearchGameUITests
```

### 8. Merge в main

```bash
# Убедиться что main актуален
git checkout main
git pull origin main

# Merge feature branch
git merge feature/game-scene-mvp

# Push
git push origin main
```

### 9. Закрыть Issue

```bash
gh issue close <issue-number> --comment "✅ Implemented and tested. All acceptance criteria met."
```

## Принципы

| Принцип | Описание |
|---------|----------|
| **TDD** | Сначала тесты, потом код |
| **Atomic commits** | Один коммит = одно логическое изменение |
| **No broken main** | В main всегда рабочий код |
| **Self-review** | Обязательная проверка своего кода |
| **Issue tracking** | Каждая фича привязана к Issue |

## Commit Messages

Формат: `type(scope): description`

Типы:
- `feat` — новая функциональность
- `fix` — исправление бага
- `refactor` — рефакторинг
- `test` — добавление тестов
- `docs` — документация
- `chore` — прочее (настройки, зависимости)

Примеры:
```
feat(scene): add pan gesture to GameScene
fix(sound): prevent crash on missing audio file
test(level): add unit tests for LevelGenerator
docs(readme): update architecture diagram
```

## Branch Naming

Формат: `type/short-description`

Примеры:
```
feature/game-scene-mvp
feature/particle-effects
fix/sound-manager-crash
refactor/level-loading
```
