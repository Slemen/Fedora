#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ИНТЕРАКТИВНОЕ МЕНЮ УСТАНОВКИ И НАСТРОЙКИ FEDORA KDE (ACER NITRO V15-51)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия их использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="/tmp/fedora_slemen_post"

cleanup() {
    rm -rf "$WORK_DIR"
    [[ "${BASH_SOURCE[0]}" == /tmp/* ]] && rm -f "${BASH_SOURCE[0]}"
}
trap cleanup EXIT

run_step() {
    local script_name="$1"
    mkdir -p "$WORK_DIR"
    if [[ -f "${SCRIPT_DIR}/${script_name}" && "${SCRIPT_DIR}" != "/tmp" ]]; then
        echo -e "${CYAN}Запуск локального скрипта: ${script_name}${NC}"
        bash "${SCRIPT_DIR}/${script_name}" </dev/tty
    else
        echo -e "${CYAN}Загрузка с GitHub: ${script_name}${NC}"
        curl -fsSL --retry 3 --retry-delay 2 "${REPO_RAW}/${script_name}?t=$(date +%s)" -o "${WORK_DIR}/${script_name}"
        chmod +x "${WORK_DIR}/${script_name}"
        bash "${WORK_DIR}/${script_name}" </dev/tty
        rm -f "${WORK_DIR}/${script_name}"
    fi
}

while true; do
    clear
    S1="[ ]"
    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1 && [[ -f /etc/sysctl.d/99-cachyos-tweaks.conf ]]; then
        S1="${GREEN}[✓]${NC}"
    fi

    S2="[ ]"
    if [[ -x /usr/local/bin/nvgame ]] && command -v fish >/dev/null 2>&1 && systemctl is-enabled --quiet earlyoom.service 2>/dev/null; then
        S2="${GREEN}[✓]${NC}"
    fi

    S3="[ ]"
    if (command -v DAMX >/dev/null 2>&1 || [[ -x /usr/bin/DAMX ]]) && lsmod | grep -q "^linuwu_sense"; then
        S3="${GREEN}[✓]${NC}"
    fi

    echo -e "${CYAN}======================================================================${NC}"
    echo -e "${CYAN}   УСТАНОВКА И НАСТРОЙКА FEDORA KDE ДЛЯ ACER NITRO V15-51 (v57)       ${NC}"
    echo -e "${CYAN}======================================================================${NC}"
    echo -e "  ${GREEN}1)${NC} ${S1} Этап 1: База, RPM Fusion, Timeshift, NVIDIA, sysctl, Wi-Fi, SSD"
    echo -e "  ${GREEN}2)${NC} ${S2} Этап 2: Кодеки, Steam, GameMode, nvgame, PipeWire и Fish"
    echo -e "  ${GREEN}3)${NC} ${S3} Этап 3: Установка Div Acer Manager Max (DAMX — кулеры и батарея)"
    echo -e "  ${GREEN}4)${NC}     Этап 4: Полная диагностика и проверка системы (20 пунктов)"
    echo -e "  ${YELLOW}5)${NC}     Перезагрузить ноутбук (обязательно после Этапа 1 и Этапа 2)"
    echo -e "  ${RED}0)${NC}     Выход"
    echo -e "${CYAN}======================================================================${NC}"
    read -rp "Выберите пункт [0-5]: " choice </dev/tty

    case "$choice" in
        1)
            run_step "01_base_and_nvidia.sh" || true
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        2)
            run_step "02_software_and_env.sh" || true
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        3)
            run_step "03_install_damx.sh" || true
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        4)
            run_step "04_verify_setup.sh" || true
            read -rp "Нажмите Enter для возврата в меню..." </dev/tty
            ;;
        5)
            echo -e "${YELLOW}Перезагрузка системы через 3 секунды...${NC}"
            sleep 3
            sudo reboot
            ;;
        0)
            echo -e "${GREEN}Выход и очистка временных файлов.${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Неверный выбор. Введите число от 0 до 5.${NC}"
            sleep 1
            ;;
    esac
done
