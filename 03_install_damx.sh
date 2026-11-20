#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ДИСКЛЕЙМЕР:
# Данные скрипты и конфигурации созданы исключительно под личные нужды автора
# и конкретное оборудование ноутбука Acer Nitro V15-51 (Fedora KDE).
# Автор не несёт ответственности за возможные сбои или потерю данных при их
# использовании на других системах. Используйте на свой страх и риск.
# ==============================================================================

if [[ $EUID -eq 0 ]]; then
    echo "ОШИБКА: Запускайте скрипт от имени обычного пользователя (без sudo)!"
    exit 1
fi

echo "=================================================================="
echo " ЭТАП 3: Установка Div Acer Manager Max (DAMX) и linuwu_sense"
echo "=================================================================="

WORK_DAMX="/tmp/damx_install"
trap 'rm -rf "$WORK_DAMX"' EXIT
rm -rf "$WORK_DAMX"
mkdir -p "$WORK_DAMX"

echo "[1/3] Установка зависимостей для сборки модуля ядра (DKMS)..."
sudo dnf install -y dkms kernel-devel kernel-headers gcc make tar xz curl jq

echo "[2/3] Поиск локального архива DAMX или загрузка последнего релиза с GitHub..."
LOCAL_ARCHIVE=$(find "$HOME/Документы" "$HOME/Documents" -maxdepth 3 -name "DAMX-*.tar.xz" 2>/dev/null | head -n 1 || true)

if [[ -n "$LOCAL_ARCHIVE" && -f "$LOCAL_ARCHIVE" ]]; then
    echo "Найден локальный архив: $LOCAL_ARCHIVE"
    cp "$LOCAL_ARCHIVE" "$WORK_DAMX/damx.tar.xz"
else
    echo "Загрузка актуального релиза PXDiv/Div-Acer-Manager-Max с GitHub..."
    ASSET_URL=$(curl -fsSL https://api.github.com/repos/PXDiv/Div-Acer-Manager-Max/releases/latest | \
        grep -oE '"browser_download_url":\s*"[^"]+\.tar\.xz"' | head -n 1 | cut -d'"' -f4)
    if [[ -z "$ASSET_URL" ]]; then
        echo "ОШИБКА: Не удалось получить ссылку на архив DAMX с GitHub."
        exit 1
    fi
    curl -fsSL "$ASSET_URL" -o "$WORK_DAMX/damx.tar.xz"
fi

echo "[3/3] Распаковка и запуск установщика DAMX..."
tar -xf "$WORK_DAMX/damx.tar.xz" -C "$WORK_DAMX"
INSTALL_BIN=$(find "$WORK_DAMX" -maxdepth 3 -type f \( -name "setup.sh" -o -name "install.sh" \) | head -n 1 || true)

if [[ -n "$INSTALL_BIN" ]]; then
    chmod +x "$INSTALL_BIN"
    (cd "$(dirname "$INSTALL_BIN")" && sudo bash "$(basename "$INSTALL_BIN")")
else
    echo "ОШИБКА: Установочный скрипт внутри архива DAMX не найден."
    exit 1
fi

echo ""
echo "=================================================================="
echo " ЭТАП 3 ЗАВЕРШЁН!"
echo " Привяжите кнопку Nitro к команде 'DAMX' вручную:"
echo " Параметры системы -> Клавиатура -> Комбинации клавиш -> Добавить."
echo "=================================================================="
