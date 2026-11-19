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

echo -e "${CYAN}Для установки софта, игровых оптимизаций и настройки терминала требуются права администратора.${NC}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ЭТАП 2: КОДЕКИ, ИГРЫ, ОПТИМИЗАЦИИ И ТЕРМИНАЛ (FISH + KONSOLE)${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/8] Установка мультимедиа-кодеков (FFmpeg / GStreamer)...${NC}"
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing || true
sudo dnf update -y @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin || true
echo -e "${GREEN}✔ Мультимедиа-кодеки установлены.${NC}"

echo -e "${YELLOW}[2/8] Установка Steam, GameMode, Protontricks, Fish, Starship, Nano...${NC}"
sudo dnf install -y \
    steam gamemode protontricks \
    fish starship nano lf bat \
    earlyoom btrfsmaintenance
echo -e "${GREEN}✔ Игровые и системные пакеты установлены.${NC}"

echo -e "${YELLOW}[3/8] Установка динамического планировщика system76-scheduler (COPR)...${NC}"
sudo dnf copr enable -y kylegospo/system76-scheduler
sudo dnf install -y system76-scheduler
sudo systemctl enable --now com.system76.Scheduler.service
echo -e "${GREEN}✔ Планировщик system76-scheduler активирован.${NC}"

echo -e "${YELLOW}[4/8] Активация защиты от зависаний earlyoom и таймера btrfs-scrub.timer...${NC}"
sudo systemctl enable --now earlyoom
sudo systemctl enable --now btrfs-scrub.timer
echo -e "${GREEN}✔ Службы earlyoom и btrfs-scrub.timer включены.${NC}"

echo -e "${YELLOW}[5/8] Настройка игрового буфера звука PipeWire и нативного Wayland...${NC}"
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat << 'EOF' > "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-audio.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.min-quantum = 1024
}
EOF
systemctl --user restart pipewire.service pipewire-pulse.service wireplumber.service 2>/dev/null || true

mkdir -p "$HOME/.config/environment.d"
cat << 'EOF' > "$HOME/.config/environment.d/wayland.conf"
ELECTRON_OZONE_PLATFORM_HINT=auto
MOZ_ENABLE_WAYLAND=1
EOF
echo -e "${GREEN}✔ Конфиги PipeWire и Wayland применены.${NC}"

echo -e "${YELLOW}[6/8] Создание врапперов запуска дискретной NVIDIA (nvgame)...${NC}"
sudo tee /usr/local/bin/nvgame > /dev/null << 'EOF'
#!/bin/bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
exec gamemoderun "$@"
EOF


sudo chmod +x /usr/local/bin/nvgame
echo -e "${GREEN}✔ Врапперы nvgame готовы.${NC}"

echo -e "${YELLOW}[7/8] Настройка цветовой схемы Konsole Newbl1nk и профиля Fish...${NC}"
mkdir -p "$HOME/.local/share/konsole"

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
Color=204,204,204

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

cat << 'EOF' > "$HOME/.local/share/konsole/Fish.profile"
[Appearance]
ColorScheme=Newbl1nk

[General]
Command=/usr/bin/fish
Name=Fish
Parent=FALLBACK/
EOF

if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$HOME/.config/konsolerc" --group "Desktop Entry" --key "DefaultProfile" "Fish.profile"
else
    cat << 'EOF' > "$HOME/.config/konsolerc"
[Desktop Entry]
DefaultProfile=Fish.profile
EOF
fi
echo -e "${GREEN}✔ Профиль Konsole Fish.profile и схема Newbl1nk применены.${NC}"

echo -e "${YELLOW}[8/8] Настройка Starship (с русским временем), Fish и .nanorc...${NC}"
mkdir -p "$HOME/.config/fish"

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

[git_commit]
commit_hash_length = 4
tag_symbol = "🔖 "

[git_status]
conflicted = "🏳 "
ahead = "🏎💨"
behind = "😰"
diverged = "😵"
untracked = "🤷‍"
stashed = "📦 "
modified = "📝"
staged = '[++\($count\)](green)'
renamed = "👅"
deleted = "🗑 "
EOF

cat << 'EOF' > "$HOME/.config/fish/config.fish"
if status is-interactive
    set -g fish_greeting ""
    alias gpuinfo="nvidia-smi"
    alias upd="sudo dnf upgrade --refresh -y && flatpak update -y"
    alias clean="sudo dnf autoremove -y && sudo dnf clean all && flatpak uninstall --unused -y"
    starship init fish | source

    functions -c fish_prompt _starship_prompt
    function fish_prompt
        set -l s (math -s0 "$CMD_DURATION / 1000")
        set -l t ""
        if test $s -ge 60
            set t (set_color --bold yellow)" время: "(math -s0 "$s / 60")"м "(math "$s % 60")"с"(set_color normal)
        else if test $s -ge 2
            set t (set_color --bold yellow)" время: "$s"с"(set_color normal)
        end
        set -l p (_starship_prompt)
        if test -n "$t" -a (count $p) -ge 2
            set p[1] "$p[1]$t"
        end
        printf "%s
" $p
    end
end
EOF

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
echo -e "${GREEN}✔ Конфиги Starship, Fish и .nanorc записаны.${NC}"

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Этап 2 завершён! Перезагрузите ноутбук перед установкой DAMX.${NC}"
echo -e "${GREEN}======================================================================${NC}"
