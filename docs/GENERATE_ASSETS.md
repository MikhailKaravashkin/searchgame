# Генерация ассетов

## Быстрый старт (через .env)

1. Положи ключ в `.env`:

```bash
cd /Users/miguel/searchgame
echo "OPENAI_API_KEY=sk-..." > .env
```

2. Установи зависимости (один раз):

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

3. Запусти генерацию:

```bash
python scripts/generate_assets.py
```

Файлы появятся в `SearchGame/Resources/Generated/`:
- `bg_farm_day.png` 
- `duck.png`

## Через MCP (из Cursor)

MCP сервер тоже читает `.env`, поэтому после шага 1 можно просто вызвать tool `generate_assets` в Cursor Chat.
