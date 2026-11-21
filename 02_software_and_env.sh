#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ЭТАП 2: МУЛЬТИМЕДИА, STEAM, GAMEMODE, NVGAME, PIPEWIRE И ТЕРМИНАЛ
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
echo -e "${CYAN}  ЭТАП 2: КОДЕКИ, STEAM, GAMEMODE, NVGAME И ТЕРМИНАЛ (NITRO V15-51)   ${NC}"
echo -e "${CYAN}======================================================================${NC}"

STEP="установка мультимедиа-кодеков и утилит видео"
echo -e "\n${YELLOW}[1/6] Установка полных кодеков FFmpeg, GStreamer и утилит VA-API/GLX...${NC}"
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf install -y gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly libva-nvidia-driver libva-utils vdpauinfo glx-utils

STEP="установка Steam, GameMode, планировщиков и словарей"
echo -e "\n${YELLOW}[2/6] Установка Steam, GameMode, system76-scheduler, earlyoom и словарей...${NC}"
sudo dnf copr enable -y eliasofwaffle/system76-scheduler
sudo dnf install -y steam gamemode system76-scheduler earlyoom fish nano-default-editor unzip kate git gh aspell aspell-en aspell-ru hunspell hunspell-en hunspell-ru
sudo usermod -aG gamemode "$USER" 2>/dev/null || true

STEP="включение системных служб оптимизации"
echo -e "\n${YELLOW}[3/6] Активация system76-scheduler, earlyoom и btrfs-scrub.timer...${NC}"
sudo systemctl enable --now com.system76.Scheduler.service
sudo systemctl enable --now earlyoom.service
ROOT_DEV=$(findmnt -n -o SOURCE / | sed 's/\[.*\]//')
if [[ -n "$ROOT_DEV" ]]; then
    UNIT_ESC=$(systemd-escape -p "$ROOT_DEV")
    sudo systemctl enable --now "btrfs-scrub@${UNIT_ESC}.timer" 2>/dev/null || true
fi

STEP="настройка звука PipeWire, Wayland и враппера nvgame"
echo -e "\n${YELLOW}[4/6] Настройка PipeWire, Wayland, исключения Steam в Baloo и nvgame...${NC}"
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d" "$HOME/.config/environment.d" "$HOME/.local/share/Steam" "$HOME/.cache/nvidia/GLCache"

cat << 'EOF' > "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-latency.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.min-quantum = 1024
}
EOF

cat << 'EOF' > "$HOME/.config/environment.d/wayland-nvidia.conf"
ELECTRON_OZONE_PLATFORM_HINT=auto
MOZ_ENABLE_WAYLAND=1
NVD_BACKEND=direct
EOF

# Исключение каталога Steam из индексации файлов KDE Baloo (защита от фоновых фризов)
if command -v balooctl6 >/dev/null 2>&1; then
    balooctl6 config add excludeFolders "$HOME/.local/share/Steam" 2>/dev/null || true
fi

sudo tee /usr/local/bin/nvgame > /dev/null << 'EOF'
#!/usr/bin/env bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# Расширенный кэш шейдеров NVIDIA и DXVK на NVMe (10 ГБ) без автоочистки
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=10737418240
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia/GLCache"
export DXVK_STATE_CACHE=1
export DXVK_STATE_CACHE_PATH="$HOME/.cache/nvidia"

# Оптимизация потоков OpenGL/DXVK и буфера звука
export __GL_THREADED_OPTIMIZATIONS=1
export PULSE_LATENCY_MSEC=60

# Отключение лишних фоновых слоёв Vulkan
export VK_LOADER_LAYERS_DISABLE="~implicit~"

mkdir -p "$__GL_SHADER_DISK_CACHE_PATH" "$DXVK_STATE_CACHE_PATH"
exec gamemoderun "$@"
EOF
sudo chmod +x /usr/local/bin/nvgame

STEP="установка Starship, шрифта JetBrainsMono Nerd Font и настройка Fish / Konsole / Nano"
echo -e "\n${YELLOW}[5/6] Установка Starship, JetBrainsMono Nerd Font и настройка Fish + Konsole...${NC}"
if ! command -v starship >/dev/null 2>&1; then
    sudo dnf copr enable -y atim/starship
    sudo dnf install -y starship
fi

sudo dnf install -y jetbrains-mono-fonts-all
mkdir -p "$HOME/.local/share/fonts/JetBrainsMonoNerd"
if ! fc-list : family | grep -i "JetBrainsMono Nerd Font" >/dev/null 2>&1; then
    curl -fsSL --retry 3 "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip" -o /tmp/JetBrainsMonoNerd.zip || true
    if [[ -f /tmp/JetBrainsMonoNerd.zip ]]; then
        unzip -oq /tmp/JetBrainsMonoNerd.zip -d "$HOME/.local/share/fonts/JetBrainsMonoNerd" "*.ttf" 2>/dev/null || true
        rm -f /tmp/JetBrainsMonoNerd.zip
    fi
fi
fc-cache -f >/dev/null 2>&1 || true

FONT_NAME="JetBrains Mono"
if fc-list : family | grep -i "JetBrainsMono Nerd Font" >/dev/null 2>&1; then
    FONT_NAME="JetBrainsMono Nerd Font"
fi

mkdir -p "$HOME/.config/fish/functions" "$HOME/.local/share/konsole"

cat << 'EOF' > "$HOME/.config/starship.toml"
add_newline = false

[character]
success_symbol = "[·❯❯](bold green)"
error_symbol = "[✗](bold red)[❯](bold yellow)[❯](bold green)"

[cmd_duration]
disabled = true

[directory]
read_only = " 🔒"
read_only_style = "cyan"

[git_branch]
symbol = "[ ](bold green)"
truncation_length = 6
truncation_symbol = ""
EOF

cat << 'EOF' > "$HOME/.config/fish/config.fish"
set -g -x fish_greeting ''

alias upd='sudo dnf upgrade -y --refresh'
alias clean='sudo dnf autoremove -y && sudo dnf clean all'
alias gpuinfo='nvidia-smi'

if status is-interactive
    starship init fish | source

    functions -c fish_prompt _starship_fish_prompt
    function fish_prompt
        if set -q CMD_DURATION; and test $CMD_DURATION -gt 2000
            set -l total_s (math -s0 "$CMD_DURATION / 1000")
            set -l m (math -s0 "$total_s / 60")
            set -l s (math "$total_s % 60")
            if test $m -gt 0
                echo -n (set_color --bold yellow)"[время: "$m"м "$s"с] "(set_color normal)
            else
                set -l s_dec (math -s1 "$CMD_DURATION / 1000")
                echo -n (set_color --bold yellow)"[время: "$s_dec"с] "(set_color normal)
            end
        end
        _starship_fish_prompt
    end
end
EOF

cat << 'EOF' > "$HOME/.local/share/konsole/Newbl1nk.colorscheme"
[Background]
Color=27,35,44

[BackgroundFaint]
Color=18,18,18

[BackgroundIntense]
Color=18,18,18

[Color0]
Color=27,29,30

[Color0Faint]
Color=27,29,30

[Color0Intense]
Color=80,83,84

[Color1]
Color=249,38,114

[Color1Faint]
Color=249,38,114

[Color1Intense]
Color=255,0,0

[Color2]
Color=130,180,20

[Color2Faint]
Color=130,180,20

[Color2Intense]
Color=125,214,66

[Color3]
Color=253,151,31

[Color3Faint]
Color=253,151,31

[Color3Intense]
Color=254,237,108

[Color4]
Color=78,130,170

[Color4Faint]
Color=78,130,170

[Color4Intense]
Color=12,115,194

[Color5]
Color=140,84,254

[Color5Faint]
Color=140,84,254

[Color5Intense]
Color=158,111,254

[Color6]
Color=108,130,134

[Color6Faint]
Color=70,84,87

[Color6Intense]
Color=137,156,161

[Color7]
Color=204,204,198

[Color7Faint]
Color=204,204,198

[Color7Intense]
Color=248,248,242

[Foreground]
Color=204,204,198

[ForegroundFaint]
Color=160,160,160

[ForegroundIntense]
Color=255,255,255

[General]
Blur=false
ColorRandomization=false
Description=New bl1nk
Opacity=1
Wallpaper=
EOF

cat << EOF > "$HOME/.local/share/konsole/Fish.profile"
[Appearance]
ColorScheme=Newbl1nk
Font=${FONT_NAME},10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1

[General]
Command=/usr/bin/fish
Name=Fish
Parent=FALLBACK/
EOF

kwriteconfig6 --file "$HOME/.config/konsolerc" --group "Desktop Entry" --key "DefaultProfile" "Fish.profile" 2>/dev/null || true
if ! grep -q "DefaultProfile=Fish.profile" "$HOME/.config/konsolerc" 2>/dev/null; then
    printf "\n[Desktop Entry]\nDefaultProfile=Fish.profile\n" >> "$HOME/.config/konsolerc"
fi

cat << 'EOF' > "$HOME/.nanorc"
set historylog
set linenumbers
set titlecolor bold,lightwhite,blue
set statuscolor bold,green
set errorcolor bold,lightwhite,red
set stripecolor ,yellow
set numbercolor bold,cyan
set keycolor bold,green
bind ^S savefile main
include "/usr/share/nano/*.nanorc"
EOF
sudo cp "$HOME/.nanorc" /root/.nanorc

STEP="смена оболочки пользователя на Fish"
echo -e "\n${YELLOW}[6/6] Назначение Fish оболочкой по умолчанию для пользователя ${USER}...${NC}"
sudo usermod -s /usr/bin/fish "$USER"

FINISHED=1
echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}  ЭТАП 2 ЗАВЕРШЁН! Выполните перезагрузку перед запуском Этапа 3.     ${NC}"
echo -e "${GREEN}======================================================================${NC}"
