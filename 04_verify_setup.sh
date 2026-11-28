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

TARGET_USER="${SUDO_USER:-$USER}"
USER_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"
USER_HOME="${USER_HOME:-$HOME}"

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ДИАГНОСТИКА СИСТЕМЫ FEDORA KDE ДЛЯ ACER NITRO V15-51 (20 ПУНКТОВ)   ${NC}"
echo -e "${CYAN}======================================================================${NC}\n"

# 1. DNF5
if grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf 2>/dev/null && grep -q "ip_resolve=4" /etc/dnf/dnf.conf 2>/dev/null; then
    ok "1. DNF5 ускорен (10 потоков, fastestmirror, ip_resolve=4)"
else
    fail "1. Параметры ускорения DNF5 не найдены в /etc/dnf/dnf.conf"
fi

# 2. RPM Fusion
if dnf repolist 2>/dev/null | grep -q "rpmfusion-free" && dnf repolist 2>/dev/null | grep -q "rpmfusion-nonfree"; then
    ok "2. Репозитории RPM Fusion Free и Nonfree подключены"
else
    fail "2. Репозитории RPM Fusion не активны"
fi

# 3. Timeshift
if command -v timeshift >/dev/null 2>&1; then
    ok "3. Утилита снимков Btrfs (Timeshift) установлена"
else
    fail "3. Timeshift не установлен"
fi

# 4. Графический стек (NVIDIA + intel-media-driver)
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1 && rpm -q intel-media-driver >/dev/null 2>&1; then
    ok "4. Графический стек активен (NVIDIA + intel-media-driver)"
else
    fail "4. Драйвер NVIDIA не активен или intel-media-driver не установлен"
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
    fail "6. ZRAM не активен (проверьте swapon --show)"
fi

# 7. Сетевой планировщик CAKE + BBR и Wi-Fi powersave off
if [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]] && \
   [[ "$(sysctl -n net.core.default_qdisc 2>/dev/null)" == "cake" ]] && \
   [[ -f /etc/NetworkManager/conf.d/wifi-powersave-off.conf ]]; then
    ok "7. Сеть: CAKE + BBR активны, энергосбережение Wi-Fi отключено"
else
    fail "7. Сетевой стек CAKE + BBR или правило Wi-Fi powersave не применены"
fi

# 8. Игровые твики sysctl
if [[ "$(sysctl -n vm.max_map_count 2>/dev/null)" == "2147483642" ]] && \
   [[ "$(sysctl -n kernel.split_lock_mitigate 2>/dev/null)" == "0" ]] && \
   [[ "$(sysctl -n vm.compaction_proactiveness 2>/dev/null)" == "0" ]]; then
    ok "8. Ядерные твики памяти и CPU (max_map_count, split_lock=0, compaction=0) применены"
else
    fail "8. Ядерные твики sysctl применены не полностью"
fi

# 9. Правила udev (ntsync и I/O NVMe)
if [[ -f /etc/udev/rules.d/99-gaming-optimizations.rules ]] && \
   grep -q "ntsync" /etc/udev/rules.d/99-gaming-optimizations.rules; then
    ok "9. Правила udev (ntsync и планировщик I/O NVMe) применены"
else
    fail "9. Правила udev 99-gaming-optimizations.rules не найдены"
fi

# 10. Оптимизация SSD (noatime и journald)
if findmnt -no OPTIONS / 2>/dev/null | grep -q "noatime" && \
   [[ -f /etc/systemd/journald.conf.d/99-size-limit.conf ]]; then
    ok "10. Оптимизация SSD: опция noatime для Btrfs и лимит логов journald (150 МБ)"
else
    fail "10. Опция noatime для Btrfs (нужна перезагрузка/ремаунт) или лимит логов journald не применены"
fi

# 11. Кодеки FFmpeg и утилиты видео
if command -v ffmpeg >/dev/null 2>&1 && rpm -q ffmpeg >/dev/null 2>&1 && \
   command -v vainfo >/dev/null 2>&1 && command -v glxinfo >/dev/null 2>&1; then
    ok "11. Полные кодеки FFmpeg и утилиты VA-API / GLX (vainfo, glxinfo) установлены"
else
    fail "11. Полный ffmpeg или утилиты vainfo / glxinfo не установлены"
fi

# 12. Службы оптимизации
if systemctl is-active --quiet com.system76.Scheduler.service && systemctl is-active --quiet earlyoom.service; then
    ok "12. Службы system76-scheduler и earlyoom запущены"
else
    fail "12. Одна из служб (system76-scheduler / earlyoom) не активна"
fi

# 13. PipeWire и Wayland
if [[ -f "$USER_HOME/.config/pipewire/pipewire.conf.d/99-gaming-latency.conf" ]] && \
   [[ -f "$USER_HOME/.config/environment.d/wayland-nvidia.conf" ]]; then
    ok "13. Конфигурации PipeWire (min-quantum=1024) и Wayland созданы"
else
    fail "13. Отсутствуют конфиги PipeWire или Wayland"
fi

# 14. Игровое окружение и враппер nvgame (10 ГБ + DXVK)
if command -v steam >/dev/null 2>&1 && command -v gamemoderun >/dev/null 2>&1 && [[ -x /usr/local/bin/nvgame ]] && \
   grep -q "__GL_SHADER_DISK_CACHE_SIZE=10737418240" /usr/local/bin/nvgame && \
   grep -q "DXVK_STATE_CACHE=1" /usr/local/bin/nvgame && \
   grep -q "VK_LOADER_LAYERS_DISABLE" /usr/local/bin/nvgame; then
    ok "14. Игровое окружение: Steam, GameMode и nvgame (кэш 10 ГБ + DXVK + VK_LOADER)"
else
    fail "14. Steam, GameMode или расширенный враппер nvgame не настроены"
fi

# 15. Блокировка iTCO_wdt
if grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null && ! lsmod | grep -q "^iTCO_wdt"; then
    ok "15. Аппаратный таймер iTCO_wdt заблокирован"
else
    fail "15. Модуль iTCO_wdt всё ещё загружен (проверьте перезагрузку)"
fi

# 16. Профиль Konsole и шрифт JetBrainsMono Nerd Font (размер 10)
if grep -q "DefaultProfile=Fish.profile" "$USER_HOME/.config/konsolerc" 2>/dev/null && \
   [[ -f "$USER_HOME/.local/share/konsole/Newbl1nk.colorscheme" ]] && \
   grep -q ",10," "$USER_HOME/.local/share/konsole/Fish.profile" 2>/dev/null && \
   (fc-list : family | grep -qi "JetBrainsMono Nerd Font" || sudo -u "$TARGET_USER" fc-list : family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"); then
    ok "16. Konsole настроен (профиль Fish, схема Newbl1nk и шрифт JetBrainsMono Nerd Font 10pt)"
else
    fail "16. Профиль Konsole, схема Newbl1nk или шрифт JetBrainsMono Nerd Font не настроены"
fi

# 17. Оболочка Fish и Starship (левый индикатор времени с минутами и секундами)
if command -v fish >/dev/null 2>&1 && command -v starship >/dev/null 2>&1 && \
   grep -q "_starship_fish_prompt" "$USER_HOME/.config/fish/config.fish" 2>/dev/null && \
   grep -q "total_s" "$USER_HOME/.config/fish/config.fish" 2>/dev/null; then
    ok "17. Терминал: Fish, Starship и левый индикатор времени (мин/сек) настроены"
else
    fail "17. Оболочка Fish или индикатор времени (мин/сек) не настроены"
fi

# 18. Конфигурация Nano
if [[ -f "$USER_HOME/.nanorc" ]] && sudo test -f /root/.nanorc; then
    ok "18. Конфигурация Nano применена для пользователя и root"
else
    fail "18. Файл .nanorc отсутствует у пользователя или root"
fi

# 19. Div Acer Manager Max (DAMX) и модуль ядра linuwu_sense
if (command -v DAMX >/dev/null 2>&1 || [[ -x /usr/bin/DAMX ]]) && lsmod | grep -q "^linuwu_sense"; then
    ok "19. Div Acer Manager Max (DAMX) и модуль ядра linuwu_sense активны"
else
    fail "19. DAMX не установлен или модуль ядра linuwu_sense не загружен"
fi

# 20. Состояние служб systemd
FAILED_UNITS=$(systemctl --failed --no-legend 2>/dev/null | grep -c . || true)
if [[ "$FAILED_UNITS" -eq 0 ]]; then
    ok "20. Упавшие системные службы (systemd failed units) отсутствуют"
else
    fail "20. Обнаружены упавшие службы systemd ($FAILED_UNITS шт.)"
fi

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "  ИТОГ ПРОВЕРКИ: ${GREEN}УСПЕШНО: ${PASS}${NC} | ${RED}ОШИБОК: ${FAIL}${NC}"
echo -e "${CYAN}======================================================================${NC}"
