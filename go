#!/usr/bin/env bash
set -euo pipefail

# Короткий загрузчик-обёртка для Slemen/Fedora (Acer Nitro V15-51).
# Скачивает актуальный install.sh во временный файл и запускает интерактивное меню.

REPO_PAGES="https://slemen.github.io/Fedora"
REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
TARGET="/tmp/slemen_fedora_install.sh"

if ! curl -fsSL "$REPO_PAGES/install.sh" -o "$TARGET" 2>/dev/null; then
    curl -fsSL "$REPO_RAW/install.sh" -o "$TARGET"
fi

chmod +x "$TARGET"
exec bash "$TARGET" </dev/tty
