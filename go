#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# БЫСТРЫЙ ЗАГРУЗЧИК УСТАНОВЩИКА FEDORA KDE ДЛЯ ACER NITRO V15-51
# Запуск: curl -fsSL https://slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
# ==============================================================================

TARGET="/tmp/slemen_fedora_install.sh"
URL="https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh?t=$(date +%s)"

cleanup() {
    rm -f "$TARGET"
    [[ "${BASH_SOURCE[0]}" == /tmp/* ]] && rm -f "${BASH_SOURCE[0]}"
}
trap cleanup EXIT

curl -fsSL --retry 3 --retry-delay 2 "$URL" -o "$TARGET"
chmod +x "$TARGET"
bash "$TARGET" </dev/tty
