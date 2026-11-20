#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ДИСКЛЕЙМЕР:
# Данные скрипты и конфигурации созданы исключительно под личные нужды автора
# и конкретное оборудование ноутбука Acer Nitro V15-51 (Fedora KDE).
# Автор не несёт ответственности за возможные сбои или потерю данных при их
# использовании на других системах. Используйте на свой страх и риск.
# ==============================================================================

REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
TMP_DIR="/tmp/fedora_slemen_post"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

cleanup() {
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

run_step() {
    local file="$1"
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        echo ">>> Запуск локального скрипта: $file"
        bash "$SCRIPT_DIR/$file" </dev/tty
    else
        mkdir -p "$TMP_DIR"
        echo ">>> Загрузка $file с GitHub..."
        curl -fsSL "$REPO_RAW/$file" -o "$TMP_DIR/$file"
        chmod +x "$TMP_DIR/$file"
        bash "$TMP_DIR/$file" </dev/tty
        rm -f "$TMP_DIR/$file"
    fi
}

while true; do
    clear || true
    echo "=================================================================="
    echo " Автоустановка и настройка Fedora KDE для Acer Nitro V15-51 (v51)"
    echo "=================================================================="
    echo " 1) Этап 1: DNF5, RPM Fusion, драйвер NVIDIA, Timeshift, sysctl"
    echo " 2) Этап 2: Кодеки, Steam, оптимизации, nvgame (10 ГБ), Fish/Starship"
    echo " 3) Этап 3: Установка Div Acer Manager Max (DAMX) и linuwu_sense"
    echo " 4) Этап 4: Полная диагностика системы (18 проверок)"
    echo " 5) Перезагрузить ноутбук"
    echo " 0) Выход (с очисткой временных файлов)"
    echo "=================================================================="
    read -rp "Выберите пункт [0-5]: " choice </dev/tty

    case "$choice" in
        1) run_step "01_base_and_nvidia.sh"; read -rp "Нажмите Enter для возврата в меню..." </dev/tty ;;
        2) run_step "02_software_and_env.sh"; read -rp "Нажмите Enter для возврата в меню..." </dev/tty ;;
        3) run_step "03_install_damx.sh"; read -rp "Нажмите Enter для возврата в меню..." </dev/tty ;;
        4) run_step "04_verify_setup.sh"; read -rp "Нажмите Enter для возврата в меню..." </dev/tty ;;
        5) cleanup; sudo reboot ;;
        0) echo "Выход. Временные файлы очищены."; exit 0 ;;
        *) echo "Неверный выбор. Введите число от 0 до 5."; sleep 1 ;;
    esac
done
