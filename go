#!/usr/bin/env bash
# ==============================================================================
# Быстрый загрузчик интерактивного меню настройки Fedora KDE (Acer Nitro V15-51)
# Использование: curl -fsSL slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
# ==============================================================================
set -euo pipefail

TARGET="/tmp/slemen_fedora_install.sh"
URL="https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh"

echo "Загрузка актуального меню установки для Acer Nitro V15-51..."
curl -fsSL "$URL" -o "$TARGET"
chmod +x "$TARGET"
exec bash "$TARGET" </dev/tty
