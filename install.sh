#!/usr/bin/env bash
# ==============================================================================
# Интерактивное меню автоустановки и настройки Fedora KDE для Acer Nitro V15-51
# Репозиторий: https://github.com/Slemen/Fedora
# Дисклеймер: Скрипт создан для личных нужд и конкретного железа (Acer Nitro V15-51).
# Автор не несёт ответственности за последствия его использования на других системах.
# ==============================================================================
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Ошибка: Запускайте меню от имени обычного пользователя (без sudo)."
    exit 1
fi

REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_WORK="/tmp/fedora_slemen_post"

cleanup() {
    rm -rf "$TMP_WORK"
}
trap cleanup EXIT

run_step() {
    local script_name="$1"
    if [[ -f "$SCRIPT_DIR/$script_name" ]]; then
        echo "Запуск локального скрипта: $SCRIPT_DIR/$script_name"
        bash "$SCRIPT_DIR/$script_name"
    else
        mkdir -p "$TMP_WORK"
        echo "Загрузка $script_name с GitHub..."
        curl -fsSL "$REPO_RAW/$script_name" -o "$TMP_WORK/$script_name"
        chmod +x "$TMP_WORK/$script_name"
        bash "$TMP_WORK/$script_name"
        rm -rf "$TMP_WORK"
    fi
}

while true; do
    clear
    echo "=============================================================================="
    echo "      Автоустановка и настройка Fedora KDE для Acer Nitro V15-51 (v51)"
    echo "=============================================================================="
    echo "  1) Этап 1: Базовая настройка DNF5, RPM Fusion, драйвер NVIDIA и sysctl"
    echo "  2) Этап 2: Кодеки, Steam, службы, nvgame (кэш 10 ГБ), Fish и Starship"
    echo "  3) Этап 3: Установка драйвера linuwu_sense и Div Acer Manager Max (DAMX)"
    echo "  4) Этап 4: Комплексная диагностика системы (18 пунктов)"
    echo "  5) Перезагрузить ноутбук сейчас"
    echo "  0) Выход (с очисткой временных файлов)"
    echo "=============================================================================="
    read -rp "Выберите пункт меню [0-5]: " choice </dev/tty

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
