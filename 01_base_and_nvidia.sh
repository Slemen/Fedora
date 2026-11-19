#!/usr/bin/env bash
set -e

# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Запускайте скрипт от обычного пользователя (sudo запросится автоматически).${NC}"
    exit 1
fi

echo -e "${CYAN}Для настройки базовой системы и драйверов NVIDIA требуются права администратора.${NC}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ЭТАП 1: DNF5, RPM FUSION, ОБНОВЛЕНИЕ СИСТЕМЫ, NVIDIA И SYSCTL${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/6] Ускорение пакетного менеджера DNF5...${NC}"
if ! grep -q "max_parallel_downloads" /etc/dnf/dnf.conf; then
    sudo tee -a /etc/dnf/dnf.conf > /dev/null << 'EOF'
max_parallel_downloads=10
fastestmirror=True
defaultyes=True
EOF
fi
echo -e "${GREEN}✔ DNF5 настроен.${NC}"

echo -e "${YELLOW}[2/6] Подключение репозиториев RPM Fusion (Free и Nonfree)...${NC}"
sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
echo -e "${GREEN}✔ RPM Fusion подключён.${NC}"

echo -e "${YELLOW}[3/6] Полное обновление системы и ядра (--refresh)...${NC}"
sudo dnf upgrade --refresh -y
echo -e "${GREEN}✔ Система обновлена.${NC}"

echo -e "${YELLOW}[4/6] Установка Timeshift, заголовков ядра и драйвера NVIDIA...${NC}"
sudo dnf install -y timeshift kernel-devel kernel-headers akmod-nvidia xorg-x11-drv-nvidia-cuda vulkan
echo -e "${GREEN}✔ Пакеты NVIDIA и Timeshift установлены.${NC}"

echo -e "${YELLOW}[5/6] Применение ядерных оптимизаций sysctl (CachyOS) и блокировка iTCO_wdt...${NC}"
sudo tee /etc/sysctl.d/99-cachyos-tweaks.conf > /dev/null << 'EOF'
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.dirty_writeback_centisecs = 1500
vm.page-cluster = 0
vm.vfs_cache_pressure = 50
kernel.nmi_watchdog = 0
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 16384
EOF
sudo sysctl --system > /dev/null

sudo tee /etc/modprobe.d/watchdog.conf > /dev/null << 'EOF'
blacklist iTCO_vendor_support
blacklist iTCO_wdt
EOF
echo -e "${GREEN}✔ Параметры sysctl и watchdog.conf применены.${NC}"

echo -e "${YELLOW}[6/6] Ожидание завершения фоновой сборки модуля ядра NVIDIA (akmods)...${NC}"
sudo akmods --force
echo -e "${GREEN}✔ Модуль ядра NVIDIA готов.${NC}"

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Этап 1 завершён! Рекомендуется перезагрузить ноутбук (sudo reboot).${NC}"
echo -e "${GREEN}======================================================================${NC}"
