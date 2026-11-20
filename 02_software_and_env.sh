#!/usr/bin/env bash
# ==============================================================================
# Этап 2: Кодеки, Steam, оптимизация служб, враппер nvgame (10 ГБ кэш), Fish и Starship
# Оборудование: Acer Nitro V15-51
# Дисклеймер: Скрипт создан для личных нужд и конкретного железа (Acer Nitro V15-51).
# Автор не несёт ответственности за последствия его использования на других системах.
# ==============================================================================
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Ошибка: Запускайте скрипт от имени обычного пользователя (без sudo)."
    exit 1
fi

echo "=== [1/6] Установка мультимедиа-кодеков ==="
sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing
sudo dnf install -y     gstreamer1-plugins-bad-free     gstreamer1-plugins-ugly     gstreamer1-plugin-openh264     gstreamer1-libav     lame\* --exclude=lame-devel

echo "=== [2/6] Установка Steam и системных утилит ==="
sudo dnf install -y     steam     system76-scheduler     earlyoom     fish     starship     fastfetch     btop     nano

echo "=== [3/6] Включение фоновых служб оптимизации ==="
sudo systemctl enable --now system76-scheduler.service
sudo systemctl enable --now earlyoom.service
sudo systemctl enable --now btrfs-scrub@-.timer || true

echo "=== [4/6] Настройка PipeWire, Wayland и враппера nvgame ==="
mkdir -p "$HOME/.config/pipewire/pipewire.conf.d"
cat << 'EOF' > "$HOME/.config/pipewire/pipewire.conf.d/99-low-latency.conf"
context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
    default.clock.min-quantum = 1024
    default.clock.max-quantum = 2048
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

# Расширенный кэш шейдеров на NVMe (до 10 ГБ) без автоочистки
export __GL_SHADER_DISK_CACHE=1
export __GL_SHADER_DISK_CACHE_SIZE=10737418240
export __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
export __GL_SHADER_DISK_CACHE_PATH="$HOME/.cache/nvidia/GLCache"

# Оптимизация потоков OpenGL/DXVK и буфера звука
export __GL_THREADED_OPTIMIZATIONS=1
export PULSE_LATENCY_MSEC=60

# Отключение лишних фоновых слоев/оверлеев Vulkan
export DISABLE_VK_LAYER_VALVE_steam_fossilize_1=0
export VK_LOADER_LAYERS_DISABLE="~implicit~"

mkdir -p "$__GL_SHADER_DISK_CACHE_PATH"
exec gamemoderun "$@"
EOF
sudo chmod +x /usr/local/bin/nvgame

echo "=== [5/6] Настройка оболочки Fish, промпта Starship и редактора Nano ==="
mkdir -p "$HOME/.config/fish"
cat << 'EOF' > "$HOME/.config/fish/config.fish"
if status is-interactive
    set -g fish_greeting ""
    alias gpuinfo='nvidia-smi'
    alias upd='sudo dnf upgrade --refresh -y'
    alias clean='sudo dnf clean all && sudo journalctl --vacuum-time=3d'

    function fish_prompt
        set -l last_status $status
        set -l dur ""
        if test -n "$CMD_DURATION" -a "$CMD_DURATION" -ge 2000
            set -l s (math -s1 "$CMD_DURATION / 1000")
            set dur (set_color --bold yellow)" время: "$s"с"(set_color normal)
        end
        set -l stat_color (set_color green)
        if test $last_status -ne 0
            set stat_color (set_color red)
        end
        echo -n -s (set_color cyan) (prompt_pwd) (set_color normal) $dur " " $stat_color "❯ " (set_color normal)
    end
end
EOF

cat << 'EOF' > "$HOME/.config/starship.toml"
add_newline = false
[cmd_duration]
disabled = true
EOF

cat << 'EOF' > "$HOME/.nanorc"
set linenumbers
set autoindent
set tabsize 4
set tabstospaces
set mouse
set softwrap
EOF

echo "=== [6/6] Настройка профиля Konsole (тема Newbl1nk и оболочка Fish) ==="
mkdir -p "$HOME/.local/share/konsole"
cat << 'EOF' > "$HOME/.local/share/konsole/Newbl1nk.colorscheme"
[Background]
Color=18,20,24

[BackgroundIntense]
Color=24,27,32

[Color0]
Color=30,34,42

[Color0Intense]
Color=92,99,112

[Color1]
Color=224,108,117

[Color1Intense]
Color=235,130,138

[Color2]
Color=152,195,121

[Color2Intense]
Color=172,212,144

[Color3]
Color=229,192,123

[Color3Intense]
Color=240,208,145

[Color4]
Color=97,175,239

[Color4Intense]
Color=125,192,247

[Color5]
Color=198,120,221

[Color5Intense]
Color=214,148,235

[Color6]
Color=86,182,194

[Color6Intense]
Color=112,202,214

[Color7]
Color=171,178,191

[Color7Intense]
Color=220,223,228

[Foreground]
Color=205,211,222

[ForegroundIntense]
Color=255,255,255

[General]
Description=Newbl1nk
Opacity=0.95
EOF

cat << 'EOF' > "$HOME/.local/share/konsole/Fish.profile"
[Appearance]
ColorScheme=Newbl1nk
Font=JetBrains Mono,11,-1,5,50,0,0,0,0,0

[General]
Command=/usr/bin/fish
Name=Fish
Parent=FALLBACK/
EOF

if command -v kwriteconfig6 &>/dev/null; then
    kwriteconfig6 --file "$HOME/.config/konsolerc" --group "Desktop Entry" --key "DefaultProfile" "Fish.profile"
fi

if ! grep -q "DefaultProfile=Fish.profile" "$HOME/.config/konsolerc" 2>/dev/null; then
    printf "
[Desktop Entry]
DefaultProfile=Fish.profile
" >> "$HOME/.config/konsolerc"
fi

echo ""
echo "=============================================================================="
echo "Этап 2 завершён! Рекомендуется перезагрузить ноутбук перед запуском Этапа 3."
echo "=============================================================================="
