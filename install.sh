#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ИНТЕРАКТИВНОЕ МЕНЮ ПОСТ-УСТАНОВКИ FEDORA KDE SPIN (Slemen/Fedora)
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

REPO_PAGES="https://slemen.github.io/Fedora"
REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
TMP_DIR="/tmp/fedora_slemen_post"
mkdir -p "$TMP_DIR"

if [[ $EUID -eq 0 ]]; then
echo -e "${RED}Не запускайте меню от имени root! Запустите от обычного пользователя.${NC}"
exit 1
fi

run_remote_script() {
local script_name="$1"
local target_path="$TMP_DIR/$script_name"
echo -e "\n${YELLOW}Загрузка актуального скрипта $script_name из репозитория...${NC}"
if ! curl -fsSL "$REPO_PAGES/$script_name" -o "$target_path" 2>/dev/null; then
curl -fsSL "$REPO_RAW/$script_name" -o "$target_path"
fi
chmod +x "$target_path"
"$target_path"
}

while true; do
echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  МЕНЮ ПОСТ-УСТАНОВКИ FEDORA KDE (Slemen/Fedora)${NC}"
echo -e "${CYAN}======================================================================${NC}"
echo -e "  ${GREEN}1)${NC} Этап 1: База, RPM Fusion, драйвер NVIDIA, sysctl и iTCO_wdt (01_base_and_nvidia.sh)"
echo -e "  ${GREEN}2)${NC} Этап 2: Софт, Steam, GameMode, PipeWire, Wayland, Fish и Konsole (02_software_and_env.sh)"
echo -e "  ${GREEN}3)${NC} Этап 3: Управление кулерами и зарядом DAMX / linuwu_sense (03_install_damx.sh)"
echo -e "  ${GREEN}4)${NC} Запустить диагностику системы по 18 пунктам (04_verify_setup.sh)"
echo -e "  ${GREEN}5)${NC} Перезагрузить компьютер (reboot)"
echo -e "  ${RED}0)${NC} Выход"
echo -e "${CYAN}----------------------------------------------------------------------${NC}"
read -rp "Выберите действие [0-5]: " CHOICE

case "$CHOICE" in
1)
run_remote_script "01_base_and_nvidia.sh"
;;
2)
run_remote_script "02_software_and_env.sh"
;;
3)
run_remote_script "03_install_damx.sh"
;;
4)
run_remote_script "04_verify_setup.sh"
;;
5)
read -rp "Точно перезагрузить компьютер сейчас? [y/N]: " REB
if [[ "$REB" =~ ^[Yy]$ ]]; then
sudo reboot
fi
;;
0)
echo -e "${GREEN}Выход из меню.${NC}"
rm -rf "$TMP_DIR"
exit 0
;;
*)
echo -e "${RED}Неверный выбор. Введите цифру от 0 до 5.${NC}"
;;
esac
done
