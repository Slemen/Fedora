#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
  echo "ОШИБКА: Запускайте этот скрипт от имени обычного пользователя (без sudo)!"
  exit 1
fi

confirm() {
  echo ""
  echo "======================================================================"
  echo "ШАГ: $1"
  echo "======================================================================"
  read -r -p "Выполнить этот шаг? [y/N]: " response
  case "$response" in
    [yY][eE][sS]|[yY]|[дД]) return 0 ;;
    *) echo "-> Шаг пропущен."; return 1 ;;
  esac
}

echo "=== ЭТАП 1: ПОДГОТОВКА БАЗЫ, ОБНОВЛЕНИЕ ЯДРА И УСТАНОВКА NVIDIA ==="
sudo -v

if confirm "1. Оптимизация DNF5, обновление системы и подключение RPM Fusion"; then
  echo "Настройка /etc/dnf/dnf.conf..."
  for param in "max_parallel_downloads=10" "fastestmirror=True" "defaultyes=True" "timeout=5" "country=UA,PL,DE,NL,CZ"; do
    key="${param%%=*}"
    if ! grep -q "^${key}=" /etc/dnf/dnf.conf 2>/dev/null; then
      echo "$param" | sudo tee -a /etc/dnf/dnf.conf > /dev/null
    fi
  done

  echo "Обновление системы (включая ядро)..."
  sudo dnf upgrade --refresh -y

  echo "Подключение RPM Fusion (Free и Non-Free) и метаданных..."
  sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
  sudo dnf install -y rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
  sudo dnf group upgrade -y core
  echo "[OK] База обновлена, RPM Fusion подключен."
fi

if confirm "2. Установка Timeshift (BTRFS) и включение таймера fstrim"; then
  sudo dnf install -y timeshift
  sudo systemctl enable --now fstrim.timer
  echo "[OK] Timeshift установлен, fstrim.timer включен."
  echo "СОВЕТ: После перезагрузки откройте Timeshift и создайте первый снимок чистой базы!"
fi

if confirm "3. Установка драйверов NVIDIA, настройка KMS, сна GPU и GTK 4 (GSK_RENDERER=gl)"; then
  sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda vdpauinfo glx-utils

  echo "Настройка запрета приложениям GTK 4 будить дискретную NVIDIA..."
  mkdir -p "$HOME/.config/environment.d"
  echo "GSK_RENDERER=gl" > "$HOME/.config/environment.d/gtk.conf"

  echo "Настройка параметров ядра (modeset=1 и черный список nouveau,nova_core)..."
  sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1 modprobe.blacklist=nouveau,nova_core"

  echo "Настройка сохранения видеопамяти при засыпании и экономичного режима P8..."
  echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" | sudo tee /etc/modprobe.d/nvidia-power-management.conf > /dev/null
  sudo dracut --force
  sudo systemctl disable --now nvidia-persistenced 2>/dev/null || true
  sudo systemctl enable nvidia-suspend nvidia-hibernate nvidia-resume

  echo "Ожидание фоновой компиляции модуля ядра NVIDIA (akmods)..."
  for i in {1..30}; do
    if modinfo -F version nvidia >/dev/null 2>&1; then
      echo "[OK] Модуль ядра NVIDIA успешно собран (версия: $(modinfo -F version nvidia))!"
      break
    fi
    echo "Сборка модуля еще идет... ожидание 10 сек ($i/30)"
    sleep 10
  done

  if ! modinfo -F version nvidia >/dev/null 2>&1; then
    echo "[ВНИМАНИЕ] Модуль еще собирается. Подождите 2-3 минуты и проверьте: modinfo -F version nvidia"
  fi
fi

echo ""
echo "======================================================================"
echo "ЭТАП 1 ЗАВЕРШЕН!"
echo "Теперь обязательно перезагрузите ноутбук (sudo reboot), чтобы загрузилось"
echo "новое ядро и драйвер NVIDIA. После перезагрузки запустите ./02_software_and_env.sh"
echo "======================================================================"
