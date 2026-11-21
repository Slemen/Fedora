#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# ЭТАП 4: КОМПЛЕКСНАЯ ПРОВЕРКА НАСТРОЙКИ FEDORA KDE (ACER NITRO V15-51)
# ==============================================================================

GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

ok()   { echo -e "${GREEN}[ OK ]${NC} $1"; ((++PASS)); }
fail() { echo -e "${RED}[FAIL]${NC} $1"; ((++FAIL)); }

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ДИАГНОСТИКА СИСТЕМЫ FEDORA KDE ДЛЯ ACER NITRO V15-51 (18 ПУНКТОВ)   ${NC}"
echo -e "${CYAN}======================================================================${NC}\n"

# 1. DNF5
if grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf && grep -q "ip_resolve=4" /etc/dnf/dnf.conf; then
    ok "1. DNF5 ускорен (10 потоков, fastestmirror, ip_resolve=4)"
else
    fail "1. Параметры ускорения DNF5 не найдены"
fi

# 2. RPM Fusion
if dnf repolist 2>/dev/null | grep -q "rpmfusion-free" && dnf repolist 2>/dev/null | grep -q "rpmfusion-nonfree"; then
    ok "2. Репозитории RPM Fusion Free и Nonfree подключены"
else
    fail "2. Репозитории RPM Fusion не активны"
fi

# 3. Timeshift & Btrfs-Assistant
if command -v timeshift >/dev/null 2>&1 && command -v btrfs-assistant >/dev/null 2>&1; then
    ok "3. Утилиты снимков Btrfs (Timeshift и Btrfs-Assistant) установлены"
else
    fail "3. Timeshift или Btrfs-Assistant не установлены"
fi

# 4. Драйвер NVIDIA
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    ok "4. Проприетарный драйвер NVIDIA активен (nvidia-smi работает)"
else
    fail "4. Драйвер NVIDIA не загружен или требует перезагрузки"
fi

# 5. Vulkan
if command -v vulkaninfo >/dev/null 2>&1; then
    ok "5. Поддержка Vulkan (vulkan-tools) установлена"
else
    fail "5. Утилиты Vulkan не найдены"
fi

# 6. ZRAM
if swapon --show 2>/dev/null | grep -q "zram"; then
    ok "6. Сжатая память ZRAM активна"
else
    fail "6. ZRAM не активен"
fi

# 7. Сетевой планировщик CAKE + BBR
if [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]] && \
   [[ "$(sysctl -n net.core.default_qdisc 2>/dev/null)" == "cake" ]]; then
    ok "7. Сетевой стек CAKE + BBR активен"
else
    fail "7. Сетевой стек CAKE + BBR не применён"
fi

# 8. Игровые твики sysctl (max_map_count, split_lock_mitigate, compaction_proactiveness)
if [[ "$(sysctl -n vm.max_map_count 2>/dev/null)" == "2147483642" ]] && \
   [[ "$(sysctl -n kernel.split_lock_mitigate 2>/dev/null)" == "0" ]] && \
   [[ "$(sysctl -n vm.compaction_proactiveness 2>/dev/null)" == "0" ]]; then
    ok "8. Ядерные твики памяти и CPU (max_map_count, split_lock=0, compaction=0) применены"
else
    fail "8. Ядерные твики sysctl применены не полностью"
fi

# 9. Кодеки FFmpeg
if rpm -q ffmpeg >/dev/null 2>&1 && ! rpm -q ffmpeg-free >/dev/null 2>&1; then
    ok "9. Полный пакет мультимедиа-кодеков FFmpeg установлен"
else
    fail "9. Используется урезанный ffmpeg-free вместо полного ffmpeg"
fi

# 10. Службы оптимизации
if systemctl is-active --quiet com.system76.Scheduler.service && systemctl is-active --quiet earlyoom.service; then
    ok "10. Службы system76-scheduler и earlyoom запущены"
else
    fail "10. Одна из служб (system76-scheduler / earlyoom) не активна"
fi

# 11. PipeWire и Wayland
if [[ -f "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-latency.conf" ]] && \
   [[ -f "$HOME/.config/environment.d/wayland-nvidia.conf" ]]; then
    ok "11. Конфигурации PipeWire (min-quantum=1024) и Wayland созданы"
else
    fail "11. Отсутствуют конфиги PipeWire или Wayland"
fi

# 12. Игровое окружение и враппер nvgame (10 ГБ + DXVK)
if command -v steam >/dev/null 2>&1 && command -v gamemoderun >/dev/null 2>&1 && [[ -x /usr/local/bin/nvgame ]] && \
   grep -q "__GL_SHADER_DISK_CACHE_SIZE=10737418240" /usr/local/bin/nvgame && \
   grep -q "DXVK_STATE_CACHE=1" /usr/local/bin/nvgame && \
   grep -q "VK_LOADER_LAYERS_DISABLE" /usr/local/bin/nvgame; then
    ok "12. Игровое окружение: Steam, GameMode и nvgame (кэш 10 ГБ + DXVK + VK_LOADER)"
else
    fail "12. Steam, GameMode или расширенный враппер nvgame не настроены"
fi

# 13. Блокировка iTCO_wdt
if grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null && ! lsmod | grep -q "^iTCO_wdt"; then
    ok "13. Аппаратный таймер iTCO_wdt заблокирован"
else
    fail "13. Модуль iTCO_wdt всё ещё загружен (проверьте перезагрузку)"
fi

# 14. Профиль Konsole и шрифт JetBrains Mono
if grep -q "DefaultProfile=Fish.profile" "$HOME/.config/konsolerc" 2>/dev/null && \
   [[ -f "$HOME/.local/share/konsole/Newbl1nk.colorscheme" ]] && \
   fc-list | grep -qi "JetBrains Mono"; then
    ok "14. Konsole настроен (профиль Fish, схема Newbl1nk и шрифт JetBrains Mono)"
else
    fail "14. Профиль Konsole, схема Newbl1nk или шрифт JetBrains Mono не настроены"
fi

# 15. Оболочка Fish и Starship
if command -v fish >/dev/null 2>&1 && command -v starship >/dev/null 2>&1 && \
   grep -q "fish_right_prompt" "$HOME/.config/fish/config.fish" 2>/dev/null; then
    ok "15. Терминал: оболочка Fish, промпт Starship и индикатор времени настроены"
else
    fail "15. Оболочка Fish или Starship не настроены"
fi

# 16. Конфигурация Nano
if [[ -f "$HOME/.nanorc" ]] && sudo test -f /root/.nanorc; then
    ok "16. Конфигурация Nano применена для пользователя и root"
else
    fail "16. Файл .nanorc отсутствует у пользователя или root"
fi

# 17. Div Acer Manager Max (DAMX)
if command -v DAMX >/dev/null 2>&1 || [[ -x /usr/bin/DAMX ]] || systemctl list-unit-files | grep -qi "damx"; then
    ok "17. Div Acer Manager Max (DAMX) установлен (клавиша настраивается вручную)"
else
    fail "17. Div Acer Manager Max (DAMX) не обнаружен"
fi

# 18. Состояние служб systemd
FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
if [[ "$FAILED_UNITS" -eq 0 ]]; then
    ok "18. Упавшие системные службы (systemd failed units) отсутствуют"
else
    fail "18. Обнаружены упавшие службы systemd ($FAILED_UNITS шт.)"
fi

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "  ИТОГ ПРОВЕРКИ: ${GREEN}УСПЕШНО: ${PASS}${NC} | ${RED}ОШИБОК: ${FAIL}${NC}"
echo -e "${CYAN}======================================================================${NC}"
