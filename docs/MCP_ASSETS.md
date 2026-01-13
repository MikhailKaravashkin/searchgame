# MCP: генерация ассетов одной кнопкой (без хранения ключа в репозитории)

Цель: генерировать фон и спрайты прямо из Cursor через MCP tool, при этом **OPENAI_API_KEY хранится в macOS Keychain**, а не в файлах проекта.

## 1) Сохранить OPENAI_API_KEY в Keychain (один раз)

В терминале:

```bash
export OPENAI_API_KEY="...твой_ключ..."
cd /Users/miguel/searchgame
./scripts/store_openai_key_in_keychain.sh
```

Проверка:

```bash
security find-generic-password -s searchgame-openai -a OPENAI_API_KEY -w
```

## 2) Подключить MCP сервер в Cursor

Cursor хранит конфиг MCP локально. Мы не коммитим этот файл.

- Скопируй пример конфигурации:

```bash
cd /Users/miguel/searchgame
cp .cursor-mcp.json.example .cursor/mcp.json
```

Если папки `.cursor/` нет — создай её.

## 3) Использование

В Cursor Chat можно вызвать tool:

- `generate_assets`

Он запустит `scripts/generate_assets.py` и положит файлы в:

- `SearchGame/Resources/Generated/bg_farm_day.png`
- `SearchGame/Resources/Generated/duck.png`

Дальше при запуске приложения игра автоматически подхватит эти ассеты.

## Безопасность

- Ключ **не хранится** в репозитории.
- Ключ **не хранится** в `.cursor/mcp.json`.
- Ключ хранится в macOS Keychain и подхватывается рантаймом через `security find-generic-password`.

## Troubleshooting

- Если MCP сервер не стартует: запусти вручную

```bash
cd /Users/miguel/searchgame
bash scripts/run_asset_mcp.sh
```

- Если `OPENAI_API_KEY not found in Keychain`: повтори шаг 1.
