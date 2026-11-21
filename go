#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# БЫСТРЫЙ ЗАГРУЗЧИК УСТАНОВЩИКА FEDORA KDE ДЛЯ ACER NITRO V15-51
# Запуск: curl -fsSL slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
# ==============================================================================

TARGET="/tmp/slemen_fedora_install.sh"
URL="https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh"

trap 'rm -f "$TARGET"' EXIT

curl -fsSL "$URL" -o "$TARGET"
chmod +x "$TARGET"
bash "$TARGET" </dev/tty
