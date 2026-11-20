#!/usr/bin/env bash
# ==============================================================================
# Этап 3: Установка драйвера linuwu_sense и Div Acer Manager Max (DAMX)
# Оборудование: Acer Nitro V15-51
# Дисклеймер: Скрипт создан для личных нужд и конкретного железа (Acer Nitro V15-51).
# Автор не несёт ответственности за последствия его использования на других системах.
# ==============================================================================
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Ошибка: Запускайте скрипт от имени обычного пользователя (без sudo)."
    exit 1
fi

WORK_DAMX="/tmp/damx_install"
rm -rf "$WORK_DAMX"
mkdir -p "$WORK_DAMX"

cleanup() {
    rm -rf "$WORK_DAMX"
}
trap cleanup EXIT

echo "=== Поиск локального архива DAMX или загрузка с GitHub ==="
LOCAL_ARCHIVE=$(find "$HOME/Документы" "$HOME/Documents" -maxdepth 3 -name "DAMX-*.tar.xz" 2>/dev/null | head -n 1 || true)

if [[ -n "$LOCAL_ARCHIVE" && -f "$LOCAL_ARCHIVE" ]]; then
    echo "Найден локальный архив: $LOCAL_ARCHIVE"
    cp "$LOCAL_ARCHIVE" "$WORK_DAMX/damx.tar.xz"
else
    echo "Локальный архив не найден. Загружаем актуальный релиз с GitHub..."
    DOWNLOAD_URL=$(curl -fsSL "https://api.github.com/repos/PXDiv/Div-Acer-Manager-Max/releases/latest"         | grep -oE '"browser_download_url":\s*"[^"]*\.tar\.xz"'         | cut -d'"' -f4 | head -n 1)
    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo "Ошибка: Не удалось получить ссылку на релиз DAMX с GitHub."
        exit 1
    fi
    curl -fsSL "$DOWNLOAD_URL" -o "$WORK_DAMX/damx.tar.xz"
fi

echo "=== Распаковка и запуск установщика DAMX ==="
tar -xf "$WORK_DAMX/damx.tar.xz" -C "$WORK_DAMX"
INSTALL_SCRIPT=$(find "$WORK_DAMX" -maxdepth 3 -name "install.sh" -o -name "setup.sh" | head -n 1)

if [[ -z "$INSTALL_SCRIPT" ]]; then
    echo "Ошибка: Установочный скрипт внутри архива DAMX не найден."
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"
cd "$(dirname "$INSTALL_SCRIPT")"
sudo bash "$INSTALL_SCRIPT"

echo ""
echo "=============================================================================="
echo "Этап 3 (DAMX и linuwu_sense) завершён! Временные файлы очищены."
echo "=============================================================================="
