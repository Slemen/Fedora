#!/usr/bin/env bash

# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ФИНАЛЬНАЯ КОМПЛЕКСНАЯ ДИАГНОСТИКА СИСТЕМЫ (18 ПУНКТОВ)${NC}"
echo -e "${CYAN}======================================================================${NC}"

# 1. Драйвер NVIDIA
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 1. Драйвер NVIDIA активен и отвечает через nvidia-smi"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 1. Драйвер NVIDIA не активен"
    ((FAIL++))
fi

# 2. Ускорение DNF5
if grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf 2>/dev/null && grep -q "ip_resolve=4" /etc/dnf/dnf.conf 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 2. Параллельная загрузка и сетевые лимиты DNF5 настроены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 2. Оптимизация DNF5 не найдена или неполная"
    ((FAIL++))
fi

# 3. Timeshift
if command -v timeshift >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 3. Утилита резервного копирования Timeshift установлена"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 3. Timeshift не установлен"
    ((FAIL++))
fi

# 4. Лимиты кэша NVMe и лимиты памяти для игр
DIRTY=$(sysctl -n vm.dirty_bytes 2>/dev/null)
DIRTY_BG=$(sysctl -n vm.dirty_background_bytes 2>/dev/null)
MAP_CNT=$(sysctl -n vm.max_map_count 2>/dev/null)
if [[ "$DIRTY" == "268435456" && "$DIRTY_BG" == "67108864" && "$MAP_CNT" == "2147483642" ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 4. Лимиты NVMe (dirty_bytes=$DIRTY) и vm.max_map_count=$MAP_CNT активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 4. Лимиты NVMe или vm.max_map_count не применились"
    ((FAIL++))
fi

# 5. ZRAM page-cluster и nmi_watchdog
PAGE_CL=$(sysctl -n vm.page-cluster 2>/dev/null)
NMI=$(sysctl -n kernel.nmi_watchdog 2>/dev/null)
if [[ "$PAGE_CL" == "0" && "$NMI" == "0" ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 5. Параметры ZRAM page-cluster=0 и nmi_watchdog=0 активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 5. Ошибка параметров page-cluster или nmi_watchdog"
    ((FAIL++))
fi

# 6. Сетевые буферы CachyOS и BBR
RMEM=$(sysctl -n net.core.rmem_max 2>/dev/null)
WMEM=$(sysctl -n net.core.wmem_max 2>/dev/null)
CC=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
if [[ "$RMEM" == "16777216" && "$WMEM" == "16777216" && "$CC" == "bbr" ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 6. Сетевой стек BBR и буферы CachyOS (16 МБ) активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 6. Сетевые буферы или BBR не применились"
    ((FAIL++))
fi

# 7. Служба system76-scheduler
if systemctl is-active --quiet com.system76.Scheduler.service; then
    echo -e "[ ${GREEN}OK${NC} ] 7. Динамический планировщик system76-scheduler запущен"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 7. Служба com.system76.Scheduler.service не активна"
    ((FAIL++))
fi

# 8. Служба earlyoom
if systemctl is-active --quiet earlyoom.service; then
    echo -e "[ ${GREEN}OK${NC} ] 8. Защита от зависаний памяти earlyoom активна"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 8. Служба earlyoom не активна"
    ((FAIL++))
fi

# 9. Таймер обслуживания Btrfs (btrfsmaintenance)
if systemctl is-enabled --quiet btrfs-scrub.timer 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 9. Таймер обслуживания Btrfs (btrfs-scrub.timer) включён"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 9. Таймер btrfs-scrub.timer не включён"
    ((FAIL++))
fi

# 10. Конфиг PipeWire
if grep -q "default.clock.min-quantum = 1024" "$HOME/.config/pipewire/pipewire.conf.d/99-gaming-audio.conf" 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 10. Конфигурация игрового звука PipeWire (min-quantum=1024) создана"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 10. Файл конфигурации звука PipeWire не найден"
    ((FAIL++))
fi

# 11. Переменные окружения Wayland
if grep -q "ELECTRON_OZONE_PLATFORM_HINT=auto" "$HOME/.config/environment.d/wayland.conf" 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 11. Переменные нативного Wayland настроены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 11. Файл ~/.config/environment.d/wayland.conf не найден"
    ((FAIL++))
fi

# 12. Игровой враппер nvgame, Steam и системный GameMode
if [[ -x "/usr/local/bin/nvgame" ]] && command -v steam >/dev/null 2>&1 && command -v gamemoderun >/dev/null 2>&1; then
    echo -e "[ ${GREEN}OK${NC} ] 12. Steam, враппер nvgame и системный gamemode готовы"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 12. Отсутствуют враппер nvgame, Steam или gamemoderun"
    ((FAIL++))
fi

# 13. Блокировка Intel Watchdog (iTCO_wdt)
if grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null && ! lsmod | grep -q "iTCO_wdt"; then
    echo -e "[ ${GREEN}OK${NC} ] 13. Модуль Intel Watchdog (iTCO_wdt) заблокирован и не загружен"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 13. Модуль iTCO_wdt всё ещё загружен (проверьте watchdog.conf и перезагрузку)"
    ((FAIL++))
fi

# 14. Тема Konsole Newbl1nk и профиль Fish
if [[ -f "$HOME/.local/share/konsole/Newbl1nk.colorscheme" && -f "$HOME/.local/share/konsole/Fish.profile" ]] && grep -Eq "DefaultProfile[[:space:]]*=[[:space:]]*Fish\.profile" "$HOME/.config/konsolerc" 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 14. Цветовая схема Konsole Newbl1nk и профиль Fish.profile активны"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 14. Профиль Konsole Fish.profile или тема Newbl1nk не настроены"
    ((FAIL++))
fi

# 15. Оболочка Fish и промпт Starship
if command -v fish >/dev/null 2>&1 && command -v starship >/dev/null 2>&1 && grep -q "starship init fish" "$HOME/.config/fish/config.fish" 2>/dev/null && grep -q 'read_only_style = "cyan"' "$HOME/.config/starship.toml" 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 15. Оболочка Fish и промпт Starship настроены"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 15. Ошибка в установке или конфигах Fish / Starship"
    ((FAIL++))
fi

# 16. Конфиги редактора nano (~/.nanorc и /root/.nanorc)
if [[ -f "$HOME/.nanorc" ]] && sudo test -f /root/.nanorc && grep -q 'include "/usr/share/nano/\*.nanorc"' "$HOME/.nanorc" 2>/dev/null; then
    echo -e "[ ${GREEN}OK${NC} ] 16. Конфигурация редактора nano (~/.nanorc и /root/.nanorc) настроена"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 16. Конфигурация .nanorc отсутствует"
    ((FAIL++))
fi

# 17. Модуль ядра Acer (linuwu_sense / DAMX)
if lsmod | grep -q "linuwu_sense"; then
    echo -e "[ ${GREEN}OK${NC} ] 17. Модуль управления питанием и кулерами linuwu_sense (DAMX) загружен"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 17. Модуль linuwu_sense не загружен (проверьте этап 03_install_damx.sh)"
    ((FAIL++))
fi

# 18. Проверка отсутствия упавших служб systemd
FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
if [[ "$FAILED_UNITS" -eq 0 ]]; then
    echo -e "[ ${GREEN}OK${NC} ] 18. Упавшие системные службы отсутствуют (systemctl --failed: 0)"
    ((PASS++))
else
    echo -e "[ ${RED}FAIL${NC} ] 18. Обнаружены упавшие службы systemd ($FAILED_UNITS):"
    systemctl --failed --no-legend
    ((FAIL++))
fi

echo -e "${CYAN}----------------------------------------------------------------------${NC}"
if [[ $FAIL -eq 0 ]]; then
    echo -e "[ ${GREEN}OK${NC} ] ИТОГ: Все проверки пройдены ($PASS/18)!"
else
    echo -e "[ ${RED}FAIL${NC} ] ИТОГ: Пройдено $PASS/18, ошибок: $FAIL."
fi
echo -e "${CYAN}======================================================================${NC}"
