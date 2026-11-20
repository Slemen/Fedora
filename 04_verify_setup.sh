#!/usr/bin/env bash
# ==============================================================================
# Этап 4: Комплексная диагностика системы (18 пунктов проверки)
# Оборудование: Acer Nitro V15-51
# Дисклеймер: Скрипт создан для личных нужд и конкретного железа (Acer Nitro V15-51).
# Автор не несёт ответственности за последствия его использования на других системах.
# ==============================================================================
set -uo pipefail

PASS=0
FAIL=0

ok() {
    echo -e "\e[32m[ OK ]\e[0m $1"
    ((PASS++))
}

fail() {
    echo -e "\e[31m[FAIL]\e[0m $1"
    ((FAIL++))
}

echo "=============================================================================="
echo "         Диагностика настройки Fedora KDE — Acer Nitro V15-51 (v51)"
echo "=============================================================================="

# 1. DNF5 config
if grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf 2>/dev/null &&    grep -q "timeout=30" /etc/dnf/dnf.conf 2>/dev/null &&    grep -q "ip_resolve=4" /etc/dnf/dnf.conf 2>/dev/null; then
    ok "1. Конфигурация DNF5 (параллельные загрузки, timeout=30, ip_resolve=4)"
else
    fail "1. Конфигурация DNF5 неполная"
fi

# 2. RPM Fusion
if dnf repolist | grep -q "rpmfusion-free" && dnf repolist | grep -q "rpmfusion-nonfree"; then
    ok "2. Репозитории RPM Fusion Free и Nonfree подключены"
else
    fail "2. Репозитории RPM Fusion не найдены"
fi

# 3. NVIDIA Driver
if command -v nvidia-smi &>/dev/null && nvidia-smi &>/dev/null; then
    ok "3. Проприетарный драйвер NVIDIA активен ($(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1))"
else
    fail "3. Драйвер NVIDIA не загружен или не работает"
fi

# 4. Vulkan
if command -v vulkaninfo &>/dev/null && vulkaninfo --summary 2>/dev/null | grep -qi "NVIDIA"; then
    ok "4. Поддержка Vulkan на видеокарте NVIDIA активна"
else
    fail "4. Vulkan для NVIDIA не обнаружен"
fi

# 5. Timeshift
if command -v timeshift &>/dev/null; then
    ok "5. Утилита резервного копирования Timeshift установлена"
else
    fail "5. Timeshift не установлен"
fi

# 6. Sysctl NVMe/ZRAM
if [[ "$(sysctl -n vm.swappiness 2>/dev/null)" == "100" ]] && [[ "$(sysctl -n vm.max_map_count 2>/dev/null)" == "2147483642" ]]; then
    ok "6. Ядерные твики sysctl (swappiness=100, max_map_count) применены"
else
    fail "6. Ядерные твики sysctl не применены"
fi

# 7. BBR
if [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]]; then
    ok "7. Сетевой алгоритм TCP BBR активен"
else
    fail "7. TCP BBR не активен"
fi

# 8. Мультимедиа кодеки
if rpm -q ffmpeg &>/dev/null; then
    ok "8. Полный пакет мультимедиа-кодеков ffmpeg установлен"
else
    fail "8. Полный пакет ffmpeg не установлен"
fi

# 9. System76 Scheduler
if systemctl is-active --quiet system76-scheduler.service; then
    ok "9. Планировщик приоритетов system76-scheduler активен"
else
    fail "9. Служба system76-scheduler не запущена"
fi

# 10. EarlyOOM
if systemctl is-active --quiet earlyoom.service; then
    ok "10. Защита от зависаний памяти earlyoom активна"
else
    fail "10. Служба earlyoom не запущена"
fi

# 11. PipeWire config
if [[ -f "$HOME/.config/pipewire/pipewire.conf.d/99-low-latency.conf" ]]; then
    ok "11. Конфигурация буфера звука PipeWire (1024) установлена"
else
    fail "11. Конфигурация PipeWire не найдена"
fi

# 12. Gaming env (Steam, GameMode, nvgame 10GB cache & VK_LOADER)
if command -v steam &>/dev/null &&    command -v gamemoderun &>/dev/null &&    [[ -x /usr/local/bin/nvgame ]] &&    grep -q "__GL_SHADER_DISK_CACHE_SIZE=10737418240" /usr/local/bin/nvgame 2>/dev/null &&    grep -q "VK_LOADER_LAYERS_DISABLE" /usr/local/bin/nvgame 2>/dev/null; then
    ok "12. Игровое окружение: Steam, GameMode и враппер nvgame (кэш 10 ГБ, VK_LOADER)"
else
    fail "12. Враппер nvgame не найден или отсутствуют настройки кэша шейдеров (10 ГБ)"
fi

# 13. Watchdog iTCO_wdt
if grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null && ! lsmod | grep -q "iTCO_wdt"; then
    ok "13. Таймер iTCO_wdt заблокирован и не загружен"
else
    fail "13. Модуль iTCO_wdt всё ещё активен или не добавлен в blacklist"
fi

# 14. Konsole profile
if grep -q "DefaultProfile=Fish.profile" "$HOME/.config/konsolerc" 2>/dev/null && [[ -f "$HOME/.local/share/konsole/Fish.profile" ]]; then
    ok "14. Профиль Konsole (Fish + тема Newbl1nk) настроен"
else
    fail "14. Профиль Konsole не настроен"
fi

# 15. Fish & Starship
if [[ -f "$HOME/.config/fish/config.fish" ]] && [[ -f "$HOME/.config/starship.toml" ]]; then
    ok "15. Конфигурация оболочки Fish и Starship установлена"
else
    fail "15. Конфиги Fish или Starship отсутствуют"
fi

# 16. Nano config
if [[ -f "$HOME/.nanorc" ]]; then
    ok "16. Конфигурация редактора Nano (.nanorc) установлена"
else
    fail "16. Конфигурация Nano отсутствует"
fi

# 17. DAMX / linuwu_sense
if lsmod | grep -q "linuwu_sense" || command -v damx &>/dev/null || [[ -d /opt/damx ]]; then
    ok "17. Управление ноутбуком Acer (DAMX / linuwu_sense) обнаружено"
else
    fail "17. Модуль linuwu_sense или DAMX не обнаружены"
fi

# 18. Failed systemd units
FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
if [[ "$FAILED_UNITS" -eq 0 ]]; then
    ok "18. Упавшие системные службы systemd отсутствуют (0 failed)"
else
    fail "18. Обнаружены упавшие службы systemd ($FAILED_UNITS шт.)"
fi

echo "=============================================================================="
echo "Итог проверки: Успешно — $PASS из 18 | Ошибок — $FAIL"
echo "=============================================================================="
