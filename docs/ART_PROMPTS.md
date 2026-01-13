# Промпты для генерации артов

Арты генерируются через ChatGPT DALL-E 3.

## Быстрая генерация ассетов в этом репозитории (автоматически)

В репозитории есть скрипт `scripts/generate_assets.py`, который генерирует и кладёт файлы прямо в bundle:

- `SearchGame/Resources/Generated/bg_farm_day.png`
- `SearchGame/Resources/Generated/duck.png`

Дальше игра автоматически подхватит эти файлы (и перестанет показывать процедурный фон/утку).

### Как запустить (macOS, из Cursor)

```bash
cd /Users/miguel/searchgame
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
# открой .env и вставь OPENAI_API_KEY
python scripts/generate_assets.py
```

## Имена файлов (важно)

- Фон дневной сцены: **bg_farm_day.png**
- Спрайт утки: **duck.png** (желательно PNG с прозрачностью)

## Фоновые изображения

### Светлая сцена (детская ферма)

```
Cute kawaii farm scene, panoramic wide illustration, pastel colors, 
cats and pandas playing together, windmill in background, red barn, 
pond with lily pads, flower gardens, detailed but not cluttered, 
game background art style, soft warm lighting, 
no text no watermarks, high detail, aspect ratio 16:9
```

### Тёмная сцена (ночной лагерь)

```
Cozy forest campsite at night, panoramic wide illustration,
warm orange campfire glow in center, hanging lanterns in trees, 
canvas tent, wooden picnic table with food, waterfall in background,
fireflies floating, magical relaxing atmosphere, detailed game art,
no text no watermarks, high detail, aspect ratio 16:9
```

### Подводный мир (будущее)

```
Magical underwater scene, panoramic illustration, coral reef,
colorful tropical fish, sunlight rays through water, treasure chest,
sea plants swaying, bubbles rising, game art style, 
relaxing peaceful mood, no text, aspect ratio 16:9
```

## Искомые предметы

### Утка (rubber duck)

```
Single cute rubber duck, game asset sprite, side view profile,
classic yellow color with orange beak, soft studio lighting,
isolated on pure white background for easy removal,
kawaii style, clean simple design, 512x512 pixels
```

### Звёздочка

```
Single golden star, game asset sprite, front view,
shiny metallic gold with subtle glow, soft lighting,
isolated on pure white background,
cartoon style, clean design, 512x512 pixels
```

### Цветок

```
Single cute flower, game asset sprite, front view,
pink petals with yellow center, cartoon style,
isolated on pure white background,
kawaii aesthetic, clean simple design, 512x512 pixels
```

## Интерактивные объекты

### Свинка

```
Single cute cartoon pig, game asset sprite, front view,
pink color, happy smiling expression, small curly tail,
isolated on pure white background,
kawaii style, soft lighting, 512x512 pixels
```

### Кот

```
Single cute cartoon cat, game asset sprite, sitting pose,
orange tabby with white chest, happy expression,
isolated on pure white background,
kawaii style, clean design, 512x512 pixels
```

### Панда

```
Single cute cartoon panda, game asset sprite, front view,
classic black and white, round body, happy face,
isolated on pure white background,
kawaii style, soft lighting, 512x512 pixels
```

## Обработка изображений

### Удаление фона

1. Открыть [remove.bg](https://remove.bg)
2. Загрузить изображение
3. Скачать PNG с прозрачностью

### Масштабирование (macOS)

```bash
# Используя sips (встроенная утилита macOS)
sips -z 256 256 duck.png --out duck_256.png

# Или через Preview:
# 1. Открыть изображение
# 2. Tools → Adjust Size
# 3. Установить нужный размер
# 4. Export as PNG
```

### Добавление в проект

1. Открыть `Assets.xcassets` в Xcode
2. Перетащить PNG файл
3. Настроить 1x/2x/3x версии при необходимости

## Рекомендуемые размеры

| Тип | Размер | Примечание |
|-----|--------|------------|
| Фон | 4096x2304 | 16:9, панорамный |
| Предмет | 128-256 px | Зависит от детализации |
| Иконка | 512x512 | Для UI |

## Стиль

Весь арт должен соответствовать:
- **Kawaii** — милый, округлый стиль
- **Пастельные цвета** — мягкие, не кричащие
- **Консистентность** — все элементы в одном стиле
- **Для взрослых** — стильно, не детсадовски
