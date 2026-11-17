#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/Slemen/Fedora.git"
WORK_DIR="/tmp/fedora-kde-setup"

clear
echo "========================================================================"
echo "  УСТАНОВКА И НАСТРОЙКА FEDORA KDE SPIN (ACER NITRO V 15)"
echo "========================================================================"
echo ""
echo "Загрузка актуальных скриптов из репозитория GitHub..."

if ! command -v git >/dev/null 2>&1; then
    echo "Установка git..."
    sudo dnf install -y git
fi

rm -rf "$WORK_DIR"
git clone --depth 1 "$REPO_URL" "$WORK_DIR" >/dev/null 2>&1
chmod +x "$WORK_DIR"/*.sh

echo "[OK] Скрипты успешно загружены во временную папку."
echo ""
echo "Выберите этап для запуска:"
echo "  1) Этап 1: Оптимизация DNF, обновление ядра, Timeshift и драйвер NVIDIA"
echo "  2) Этап 2: Кодеки, Steam, GameMode, Flatpak, Fish, lf и bat"
echo "  3) Этап 3: Полная самодиагностика системы (проверка GPU, служб и софта)"
echo "  4) Этап 4: Установка и патч Div Acer Manager Max (DAMX)"
echo "  0) Выход"
echo ""
read -rp "Введите номер этапа [1-4]: " CHOICE

case "$CHOICE" in
    1)
        exec "$WORK_DIR/01_base_and_nvidia.sh"
        ;;
    2)
        exec "$WORK_DIR/02_software_and_env.sh"
        ;;
    3)
        exec "$WORK_DIR/03_verify_setup.sh"
        ;;
    4)
        exec "$WORK_DIR/04_install_damx.sh"
        ;;
    0)
        echo "Выход."
        exit 0
        ;;
    *)
        echo "[ОШИБКА] Неверный выбор. Запустите скрипт снова и введите цифру от 1 до 4."
        exit 1
        ;;
esac
