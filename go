#!/usr/bin/env bash
set -e

# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.

REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
WORK_DIR="/tmp/fedora_nitro_setup"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

while true; do
    clear
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${CYAN}  УСТАНОВКА И НАСТРОЙКА FEDORA KDE ДЛЯ ACER NITRO V 15 (v51)${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo "1) 01_base_and_nvidia.sh — База, RPM Fusion, ядро, Timeshift, драйвер NVIDIA и sysctl"
    echo "2) 02_software_and_env.sh — Софт, Steam, GameMode, Gamescope, PipeWire, Fish, Konsole"
    echo "3) 03_install_damx.sh     — Модуль управления вентиляторами и батареей DAMX"
    echo "4) 04_verify_setup.sh     — Комплексная проверка всех 18 пунктов настройки"
    echo "0) Выход"
    echo -e "${CYAN}----------------------------------------------------------------------${NC}"
    read -rp "Выберите этап (0-4): " choice

    case "$choice" in
        1)
            curl -fsSL "$REPO_RAW/01_base_and_nvidia.sh" -o 01_base_and_nvidia.sh
            chmod +x 01_base_and_nvidia.sh
            ./01_base_and_nvidia.sh
            read -rp "Нажмите Enter для возврата в меню..."
            ;;
        2)
            curl -fsSL "$REPO_RAW/02_software_and_env.sh" -o 02_software_and_env.sh
            chmod +x 02_software_and_env.sh
            ./02_software_and_env.sh
            read -rp "Нажмите Enter для возврата в меню..."
            ;;
        3)
            curl -fsSL "$REPO_RAW/03_install_damx.sh" -o 03_install_damx.sh
            chmod +x 03_install_damx.sh
            ./03_install_damx.sh
            read -rp "Нажмите Enter для возврата в меню..."
            ;;
        4)
            curl -fsSL "$REPO_RAW/04_verify_setup.sh" -o 04_verify_setup.sh
            chmod +x 04_verify_setup.sh
            ./04_verify_setup.sh
            read -rp "Нажмите Enter для возврата в меню..."
            ;;
        0)
            echo "Выход."
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Попробуйте снова.${NC}"
            sleep 1
            ;;
    esac
done
