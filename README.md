# Search Game 🔍

Расслабляющая iOS игра с поиском скрытых предметов на красивых панорамных сценах.

## Особенности

- Панорамные сцены с прокруткой
- Атмосферные анимации (огонь, вода, светлячки)
- Расслабляющие звуки окружения
- Процедурная генерация размещения предметов
- Несколько тематических уровней

## Технологии

- **Платформа**: iOS 15.0+
- **Язык**: Swift 5.9+
- **Фреймворк**: SpriteKit
- **IDE**: Xcode 15+

## Архитектура

```
SearchGame/
├── App/                    # Точка входа
├── Scenes/                 # SpriteKit сцены
│   ├── GameScene.swift
│   ├── MenuScene.swift
│   └── VictoryScene.swift
├── Nodes/                  # Кастомные ноды
│   ├── SearchableItemNode.swift
│   └── InteractiveNode.swift
├── Managers/               # Синглтоны
│   ├── SoundManager.swift
│   ├── LevelManager.swift
│   └── ParticleFactory.swift
├── Models/                 # Модели данных
│   └── Level.swift
└── Resources/              # Ассеты
    ├── Assets.xcassets/
    ├── Levels/             # JSON конфиги
    ├── Sounds/
    └── Particles/
```

## План разработки

### Phase 1: MVP - Базовая механика
- [ ] GameScene с панорамной прокруткой
- [ ] SearchableItemNode с анимацией
- [ ] HUD со счётчиком

### Phase 2: Анимации
- [ ] Система частиц (огонь, дым, светлячки)
- [ ] Программные анимации (трава, вода)

### Phase 3: Звук
- [ ] SoundManager
- [ ] Фоновая музыка и эффекты

### Phase 4: Уровни
- [ ] JSON конфигурация уровней
- [ ] Процедурная генерация

### Phase 5: Полировка
- [ ] Главное меню
- [ ] Экран победы
- [ ] Несколько сцен

## Генерация артов

Арты генерируются через ChatGPT DALL-E.

**Быстрый старт:**
```bash
echo "OPENAI_API_KEY=sk-..." > .env
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
python scripts/generate_assets.py
```

Подробнее: [docs/GENERATE_ASSETS.md](docs/GENERATE_ASSETS.md), промпты: [docs/ART_PROMPTS.md](docs/ART_PROMPTS.md).

## Разработка

См. [CONTRIBUTING.md](CONTRIBUTING.md) для описания workflow.

```bash
# Клонирование
git clone https://github.com/MikhailKaravashkin/searchgame.git
cd searchgame

# Открыть в Xcode
open SearchGame.xcodeproj

# Билд из командной строки
xcodebuild -scheme SearchGame -destination 'platform=iOS Simulator,name=iPhone 15' build

# Тесты
xcodebuild test -scheme SearchGame -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Лицензия

MIT
