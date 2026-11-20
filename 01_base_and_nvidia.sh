#!/usr/bin/env bash
# ==============================================================================
# Этап 1: Базовая настройка Fedora KDE, DNF5, RPM Fusion, драйвер NVIDIA и sysctl
# Оборудование: Acer Nitro V15-51
# Дисклеймер: Скрипт создан для личных нужд и конкретного железа (Acer Nitro V15-51).
# Автор не несёт ответственности за последствия его использования на других системах.
# ==============================================================================
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Ошибка: Запускайте скрипт от имени обычного пользователя (без sudo)."
    exit 1
fi

echo "=== [1/5] Ускорение пакетного менеджера DNF5 ==="
sudo tee /etc/dnf/dnf.conf > /dev/null << 'EOF'
[main]
gpgcheck=True
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
max_parallel_downloads=10
fastestmirror=True
defaultyes=True
timeout=30
ip_resolve=4
EOF

echo "=== [2/5] Подключение RPM Fusion (Free и Nonfree) и обновление системы ==="
FEDORA_VER=$(rpm -E %fedora)
sudo dnf install -y     "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm"     "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"
sudo dnf upgrade --refresh -y

echo "=== [3/5] Установка Timeshift, драйвера NVIDIA, CUDA и инструментов сборки ==="
sudo dnf install -y     timeshift     akmod-nvidia     xorg-x11-drv-nvidia-cuda     xorg-x11-drv-nvidia-cuda-libs     vulkan-loader     vulkan-tools     kernel-devel     kernel-headers     dkms     gcc     make     git     curl     wget

echo "=== [4/5] Применение ядерных твиков sysctl (NVMe, ZRAM, BBR, память) ==="
echo "tcp_bbr" | sudo tee /etc/modules-load.d/bbr.conf > /dev/null
sudo modprobe tcp_bbr || true

sudo tee /etc/sysctl.d/99-cachyos-tweaks.conf > /dev/null << 'EOF'
vm.swappiness = 100
vm.vfs_cache_pressure = 50
vm.dirty_bytes = 268435456
vm.dirty_background_bytes = 67108864
vm.page-cluster = 0
vm.max_map_count = 2147483642
fs.file-max = 2097152
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.netdev_max_backlog = 16384
EOF
sudo sysctl --system > /dev/null

echo "=== [5/5] Блокировка аппаратного таймера iTCO_wdt ==="
sudo tee /etc/modprobe.d/watchdog.conf > /dev/null << 'EOF'
blacklist iTCO_wdt
blacklist iTCO_vendor_support
install iTCO_wdt /bin/true
install iTCO_vendor_support /bin/true
EOF

if command -v grubby &>/dev/null; then
    sudo grubby --update-kernel=ALL --args="modprobe.blacklist=iTCO_wdt,iTCO_vendor_support" || true
fi

echo ""
echo "=============================================================================="
echo "Этап 1 завершён! Обязательно перезагрузите ноутбук перед запуском Этапа 2."
echo "Примечание: Подождите 2-3 минуты перед перезагрузкой, пока akmods соберёт модуль NVIDIA."
echo "=============================================================================="
