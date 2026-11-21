#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ЭТАП 1: БАЗОВАЯ НАСТРОЙКА, RPM FUSION, TIMESHIFT, NVIDIA И SYSCTL
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

STEP="подготовка"
FINISHED=0
SUDO_PID=""

on_exit() {
    local rc=$?
    if [[ -n "$SUDO_PID" ]]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
    if [[ $FINISHED -eq 0 && $rc -ne 0 ]]; then
        echo -e "\n${RED}[ОШИБКА] Скрипт остановлен на шаге: ${STEP}. Исправьте причину выше и запустите снова.${NC}" >&2
    fi
}
trap on_exit EXIT

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Ошибка: не запускайте скрипт от имени root (без sudo).${NC}"
    exit 1
fi

if pgrep -x "dnf" >/dev/null 2>&1 || pgrep -x "dnf5" >/dev/null 2>&1; then
    echo -e "${RED}Ошибка: пакетный менеджер DNF сейчас занят другим процессом. Дождитесь завершения и повторите.${NC}"
    exit 1
fi

sudo -v
( while sleep 50; do sudo -n true 2>/dev/null || exit 0; done ) >/dev/null 2>&1 &
SUDO_PID=$!

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ЭТАП 1: БАЗОВАЯ НАСТРОЙКА, NVIDIA И ЯДЕРНЫЕ ТВИКИ (ACER NITRO V15-51)${NC}"
echo -e "${CYAN}======================================================================${NC}"

STEP="оптимизация DNF5"
echo -e "\n${YELLOW}[1/6] Ускорение пакетного менеджера DNF5...${NC}"
DNF_CONF="/etc/dnf/dnf.conf"
for param in "max_parallel_downloads=10" "fastestmirror=True" "defaultyes=True" "timeout=30" "ip_resolve=4"; do
    key="${param%%=*}"
    if grep -q "^${key}=" "$DNF_CONF" 2>/dev/null; then
        sudo sed -i "s/^${key}=.*/${param}/" "$DNF_CONF"
    else
        echo "$param" | sudo tee -a "$DNF_CONF" > /dev/null
    fi
done

STEP="подключение репозиториев RPM Fusion"
echo -e "\n${YELLOW}[2/6] Подключение репозиториев RPM Fusion (Free и Nonfree)...${NC}"
FEDORA_VER=$(rpm -E %fedora)
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1 || true

STEP="обновление системы и установка Timeshift"
echo -e "\n${YELLOW}[3/6] Обновление системы и установка утилиты снимков Timeshift...${NC}"
sudo dnf upgrade -y --refresh
sudo dnf install -y timeshift

STEP="установка проприетарного драйвера NVIDIA и Vulkan"
echo -e "\n${YELLOW}[4/6] Установка проприетарного драйвера NVIDIA, CUDA и Vulkan...${NC}"
sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda vulkan-loader vulkan-tools

STEP="применение ядерных твиков sysctl и сетевого планировщика CAKE + BBR"
echo -e "\n${YELLOW}[5/6] Применение ядерных твиков sysctl (CachyOS / SteamOS / Nobara)...${NC}"
sudo tee /etc/modules-load.d/network-tuning.conf > /dev/null << 'EOF'
tcp_bbr
sch_cake
EOF
sudo modprobe tcp_bbr 2>/dev/null || true
sudo modprobe sch_cake 2>/dev/null || true

sudo tee /etc/sysctl.d/99-cachyos-tweaks.conf > /dev/null << 'EOF'
# Память, ZRAM и защита от фоновых микрофризов (CachyOS / SteamOS)
vm.swappiness = 180
vm.vfs_cache_pressure = 50
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.dirty_writeback_centisecs = 1500
vm.page-cluster = 0
vm.max_map_count = 2147483642
vm.compaction_proactiveness = 0
fs.file-max = 2097152

# Игровая отзывчивость CPU (CachyOS)
kernel.nmi_watchdog = 0
kernel.split_lock_mitigate = 0

# Сетевой стек CAKE + BBR для минимального джиттера в играх (Nobara)
net.core.default_qdisc = cake
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 16384
EOF
sudo sysctl --system > /dev/null

STEP="блокировка аппаратного таймера iTCO_wdt"
echo -e "\n${YELLOW}[6/6] Надёжная блокировка аппаратного таймера iTCO_wdt...${NC}"
sudo tee /etc/modprobe.d/watchdog.conf > /dev/null << 'EOF'
blacklist iTCO_wdt
blacklist iTCO_vendor_support
install iTCO_wdt /bin/true
install iTCO_vendor_support /bin/true
EOF
sudo grubby --update-kernel=ALL --args="modprobe.blacklist=iTCO_wdt,iTCO_vendor_support" || true

FINISHED=1
echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}  ЭТАП 1 ЗАВЕРШЁН! Подождите 2-3 минуты сборки модуля NVIDIA и         ${NC}"
echo -e "${GREEN}  обязательно ПЕРЕЗАГРУЗИТЕ ноутбук перед запуском Этапа 2.           ${NC}"
echo -e "${GREEN}======================================================================${NC}"
