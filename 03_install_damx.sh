#!/usr/bin/env bash
set -e

echo "========================================================================"
echo "  ЭТАП 3: УСТАНОВКА DIV ACER MANAGER MAX (DAMX) ДЛЯ ACER NITRO V 15"
echo "========================================================================"

if [[ $EUID -eq 0 ]]; then
    echo "[ОШИБКА] Запустите этот скрипт от имени обычного пользователя (без sudo)!"
    exit 1
fi

echo -e "\n[1/4] Проверка заголовков ядра и инструментов сборки..."
CURRENT_KERNEL=$(uname -r)
if ! rpm -q "kernel-devel-${CURRENT_KERNEL}" &>/dev/null; then
    echo "Установка пакетов сборки для ядра ${CURRENT_KERNEL}..."
    sudo dnf install -y "kernel-devel-${CURRENT_KERNEL}" "kernel-headers-${CURRENT_KERNEL}" gcc make git tar xz curl
else
    echo "  [OK] Заголовки ядра ${CURRENT_KERNEL} уже установлены."
fi

echo -e "\n[2/4] Поиск архива DAMX-*.tar.xz..."
TMP_DIR=$(mktemp -d /tmp/damx_build.XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT

ARCHIVE_PATH=""
for DOC_DIR in "$HOME/Документы" "$HOME/Documents"; do
    if [[ -d "$DOC_DIR" ]]; then
        FOUND=$(find "$DOC_DIR" -maxdepth 3 -type f -name "DAMX-*.tar.xz" 2>/dev/null | sort -V | tail -n 1)
        if [[ -n "$FOUND" ]]; then
            ARCHIVE_PATH="$FOUND"
            break
        fi
    fi
done

if [[ -n "$ARCHIVE_PATH" ]]; then
    echo "  [OK] Найден локальный архив: $ARCHIVE_PATH"
    cp "$ARCHIVE_PATH" "$TMP_DIR/damx.tar.xz"
else
    echo "  [INFO] Локальный архив в Документах не найден. Скачивание свежего релиза с GitHub..."
    DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/PXDiv/Div-Acer-Manager-Max/releases/latest \
        | grep -oE '"browser_download_url":\s*"[^"]+DAMX-[^"]+\.tar\.xz"' \
        | head -n 1 \
        | cut -d'"' -f4)

    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "  [ОШИБКА] Не удалось получить ссылку на релиз с GitHub. Скачайте DAMX-*.tar.xz вручную в ~/Документы."
        exit 1
    fi

    echo "  Загрузка: $DOWNLOAD_URL"
    curl -fL "$DOWNLOAD_URL" -o "$TMP_DIR/damx.tar.xz"
    echo "  [OK] Архив успешно загружен."
fi

echo -e "\n[3/4] Распаковка, применение патча совместимости и установка..."
tar -xf "$TMP_DIR/damx.tar.xz" -C "$TMP_DIR"
SETUP_SCRIPT=$(find "$TMP_DIR" -maxdepth 3 -type f -name "setup.sh" | head -n 1)

if [[ -z "$SETUP_SCRIPT" ]]; then
    echo "  [ОШИБКА] Файл setup.sh внутри архива не найден!"
    exit 1
fi

SRC_DIR=$(dirname "$SETUP_SCRIPT")
cd "$SRC_DIR"

# Патч совместимости strncpy -> memcpy для новых ядер Linux
find . -type f -name "linuwu_sense.c" -exec sed -i 's/strncpy(/memcpy(/g' {} +

chmod +x setup.sh
sudo ./setup.sh

echo -e "\n[4/4] Проверка статуса модуля ядра linuwu_sense..."
if lsmod | grep -q linuwu_sense; then
    echo "  [OK] Модуль ядра linuwu_sense успешно загружен!"
else
    echo "  [WARN] Модуль linuwu_sense активируется после перезагрузки системы."
fi

echo "========================================================================"
echo "  УСТАНОВКА DAMX ЗАВЕРШЕНА!"
echo "  1. Выполните перезагрузку (sudo reboot)."
echo "  2. Откройте DAMX -> Internals Manager -> выберите Nitro V4 -> Restart Drivers."
echo "  3. Включите ограничение заряда батареи 80% и запустите финальную проверку (Этап 4)."
echo "========================================================================"
