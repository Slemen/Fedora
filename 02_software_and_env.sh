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

echo "=== ЭТАП 2: КОДЕКИ, ИГРЫ, GAMEMODE, FISH И ФАЙЛОВЫЙ МЕНЕДЖЕР LF ==="
sudo -v

if confirm "1. Установка полных кодеков (FFmpeg), видеодрайвера Intel (iHD) и OpenH264"; then
  sudo dnf swap -y 'ffmpeg-free' 'ffmpeg' --allowerasing
  sudo dnf group upgrade -y multimedia --setopt=install_weak_deps=False --exclude=PackageKit-gstreamer-plugin
  sudo dnf install -y libavcodec-freeworld
  sudo dnf swap -y libva-intel-media-driver intel-media-driver --allowerasing
  sudo dnf install -y libva-utils
  sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
  sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
  echo "[OK] Мультимедиа и аппаратное ускорение видео настроены."
fi

if confirm "2. Установка словарей орфографии, Kate и архиваторов (Wine/Proton)"; then
  sudo dnf install -y aspell aspell-en aspell-ru hunspell hunspell-en hunspell-ru kate icoutils cabextract p7zip p7zip-plugins unrar
  echo "[OK] Словари и архиваторы установлены."
fi

if confirm "3. Установка Steam, настройка GameMode, Flathub, ProtonUp-Qt и Protontricks"; then
  sudo dnf install -y steam gamemode
  sudo usermod -aG gamemode "$USER"

  echo "Настройка постоянных прав доступа к Intel RAPL..."
  echo "z /sys/class/powercap/intel-rapl/intel-rapl:0/energy_uj 0444 root root -" | sudo tee /etc/tmpfiles.d/intel-rapl.conf > /dev/null
  sudo systemd-tmpfiles --create

  echo "Создание /etc/gamemode.ini..."
  sudo bash -c 'cat << EOF > /etc/gamemode.ini
[general]
desiredgov=performance
softrealtime=auto
renice=10

[cpu]
park_cores=no
pin_cores=yes
EOF'

  systemctl --user enable --now gamemoded

  echo "Подключение Flathub и установка ProtonUp-Qt и Protontricks..."
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y flathub net.davidotek.pupgui2 com.github.Matoking.protontricks
  flatpak override --user --env=LC_ALL=C net.davidotek.pupgui2
  echo "[OK] Игровое окружение установлено и настроено."
fi

if confirm "4. Отключение ожидания сети на старте, настройка Fish, lf и bat"; then
  sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

  sudo dnf copr enable -y pennbauman/ports
  sudo dnf install -y fish lf bat

  mkdir -p "$HOME/.config/fish/functions"
  cat << 'EOF' > "$HOME/.config/fish/config.fish"
if status is-interactive
    set -g fish_greeting ''
    alias update='sudo dnf upgrade --refresh'
    alias nvidialog='watch -n 1 nvidia-smi'
    alias gpuinfo='nvidia-smi --query-gpu=pstate,power.draw,temperature.gpu,utilization.gpu --format=csv,noheader'
end
EOF

  cat << 'EOF' > "$HOME/.config/fish/functions/lfcd.fish"
function lfcd --wraps="lf" --description="lf with cd on exit"
    cd (command lf -print-last-dir $argv)
end
EOF

  mkdir -p "$HOME/.config/lf"
  cat << 'EOF' > "$HOME/.config/lf/lfrc"
set shell sh
set shellopts '-eu'
set ifs "
"
set scrolloff 10
set hidden true
set drawbox true
set period 1
set info size
set dircounts

cmd open ${{
    case $(file --mime-type -Lb "$f") in
        text/*) nano "$fx";;
        *) for f in $fx; do xdg-open "$f" > /dev/null 2> /dev/null & done;;
    esac
}}

cmd mkdir %mkdir "$@"
cmd mkfile %touch "$@"
map a push :mkdir<space>
map A push :mkfile<space>
map D delete
EOF

  if [ "$SHELL" != "/usr/bin/fish" ]; then
    echo "Переключение оболочки по умолчанию на Fish (потребуется пароль пользователя):"
    chsh -s /usr/bin/fish || true
  fi
  echo "[OK] Fish, lf и bat настроены."
fi

echo ""
echo "======================================================================"
echo "ЭТАП 2 ЗАВЕРШЕН!"
echo "Перезагрузите ноутбук (sudo reboot), чтобы применились права группы"
echo "gamemode, переменные среды и оболочка Fish."
echo "После перезагрузки запустите скрипт проверки: ./04_verify_setup.sh"
echo "======================================================================"
