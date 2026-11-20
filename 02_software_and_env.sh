#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ДИСКЛЕЙМЕР:
# Данные скрипты и конфигурации созданы исключительно под личные нужды автора
# и конкретное оборудование ноутбука Acer Nitro V15-51 (Fedora KDE).
# Автор не несёт ответственности за возможные сбои или потерю данных при их
# использовании на других системах. Используйте на свой страх и риск.
# ==============================================================================

if [[ $EUID -eq 0 ]]; then
    echo "ОШИБКА: Запускайте скрипт от имени обычного пользователя (без sudo)!"
    exit 1
fi

echo "=================================================================="
echo " ЭТАП 2: Софт, Steam, кодеки, оптимизация и терминал (v51)"
echo "=================================================================="

echo "[1/6] Установка полных мультимедиа-кодеков (RPM Fusion)..."
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf install -y gstreamer1-plugins-bad-freeworld gstreamer1-plugins-ugly libavcodec-freeworld

echo "[2/6] Установка Steam и утилит терминала (Fish, Starship)..."
sudo dnf install -y steam fish util-linux-user
if ! command -v starship >/dev/null 2>&1; then
    sudo dnf copr enable -y atim/starship && sudo dnf install -y starship || \
    curl -sS https://starship.rs/install.sh | sudo sh -s -- -y
fi

echo "[3/6] Включение служб оптимизации (system76-scheduler, earlyoom, btrfs-scrub)..."
sudo dnf copr enable -y kylegospo/system76-scheduler
sudo dnf install -y system76-scheduler earlyoom
sudo systemctl enable --now com.system76.Scheduler.service
sudo systemctl enable --now earlyoom.service
sudo systemctl enable --now btrfs-scrub@-.timer || true

echo "[4/6] Настройка PipeWire, Wayland и враппера nvgame (кэш шейдеров 10 ГБ)..."
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat << 'EOF' > "$HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf"
context.properties = {
    default.clock.min-quantum = 1024
}
EOF

mkdir -p "$HOME/.config/environment.d"
cat << 'EOF' > "$HOME/.config/environment.d/99-wayland-nvidia.conf"
MOZ_ENABLE_WAYLAND=1
ELECTRON_OZONE_PLATFORM_HINT=auto
EOF

sudo tee /usr/local/bin/nvgame > /dev/null << 'EOF'
#!/usr/bin/env bash
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# Расширенный кэш шейдеров NVIDIA на NVMe (до 10 ГБ) без автоочистки
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=10737418240
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia/GLCache"

# Многопоточная оптимизация и стабильный буфер звука
export __GL_THREADED_OPTIMIZATIONS=1
export PULSE_LATENCY_MSEC=60

# Отключение лишних фоновых слоев Vulkan
export DISABLE_VK_LAYER_VALVE_steam_fossilize_1=0
export VK_LOADER_LAYERS_DISABLE="~implicit~"

mkdir -p "$__GL_SHADER_DISK_CACHE_PATH"
exec gamemoderun "$@"
EOF
sudo chmod +x /usr/local/bin/nvgame

echo "[5/6] Настройка оболочки Fish, промпта Starship и редактора Nano..."
mkdir -p "$HOME/.config/fish"
cat << 'EOF' > "$HOME/.config/fish/config.fish"
set -g fish_greeting ""

# Полезные алиасы
alias upd="sudo dnf upgrade --refresh -y"
alias clean="sudo dnf autoremove -y && sudo dnf clean all"
alias gpuinfo="nvidia-smi"

# Русский индикатор времени выполнения команды справа
function fish_right_prompt
    set -l d $CMD_DURATION
    if test -n "$d" -a "$d" -ge 2000
        set -l s (math -s1 "$d / 1000")
        set_color --bold yellow
        echo -n "время: $sс"
        set_color normal
    end
end

if status is-interactive
    starship init fish | source
end
EOF

cat << 'EOF' > "$HOME/.config/starship.toml"
add_newline = false

[cmd_duration]
disabled = true

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
EOF

cat << 'EOF' > "$HOME/.nanorc"
set linenumbers
set tabsize 4
set tabstospaces
set autoindent
set mouse
EOF

echo "[6/6] Настройка профиля Konsole (Newbl1nk + Fish)..."
mkdir -p "$HOME/.local/share/konsole"
cat << 'EOF' > "$HOME/.local/share/konsole/Newbl1nk.colorscheme"
[Background]
Color=18,18,24

[Foreground]
Color=220,224,232

[General]
Description=Newbl1nk
Opacity=0.95
EOF

cat << 'EOF' > "$HOME/.local/share/konsole/Fish.profile"
[Appearance]
ColorScheme=Newbl1nk
Font=Hack,11,-1,5,50,0,0,0,0,0

[General]
Command=/usr/bin/fish
Name=Fish
Parent=FALLBACK/
EOF

if command -v kwriteconfig6 >/dev/null 2>&1; then
    kwriteconfig6 --file "$HOME/.config/konsolerc" --group "Desktop Entry" --key "DefaultProfile" "Fish.profile"
fi
if ! grep -q "DefaultProfile=Fish.profile" "$HOME/.config/konsolerc" 2>/dev/null; then
    printf "\n[Desktop Entry]\nDefaultProfile=Fish.profile\n" >> "$HOME/.config/konsolerc"
fi

echo ""
echo "=================================================================="
echo " ЭТАП 2 ЗАВЕРШЁН!"
echo " Перезагрузите ноутбук перед установкой DAMX (Этап 3)."
echo "=================================================================="
