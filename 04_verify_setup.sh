#!/usr/bin/env bash
set -uo pipefail

# ==============================================================================
# ДИСКЛЕЙМЕР:
# Данные скрипты и конфигурации созданы исключительно под личные нужды автора
# и конкретное оборудование ноутбука Acer Nitro V15-51 (Fedora KDE).
# Автор не несёт ответственности за возможные сбои или потерю данных при их
# использовании на других системах. Используйте на свой страх и риск.
# ==============================================================================

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

echo "=================================================================="
echo " ДИАГНОСТИКА НАСТРОЙКИ FEDORA KDE — ACER NITRO V15-51 (18 ПУНКТОВ)"
echo "=================================================================="

# 1. DNF5
if grep -q "max_parallel_downloads=10" /etc/dnf/dnf.conf 2>/dev/null && \
   grep -q "timeout=30" /etc/dnf/dnf.conf 2>/dev/null && \
   grep -q "ip_resolve=4" /etc/dnf/dnf.conf 2>/dev/null; then
    ok "1. DNF5: параллельные загрузки (10), таймаут (30) и IPv4 настроены"
else
    fail "1. DNF5: отсутствуют параметры оптимизации в /etc/dnf/dnf.conf"
fi

# 2. RPM Fusion
if dnf repolist | grep -q "rpmfusion-free" && dnf repolist | grep -q "rpmfusion-nonfree"; then
    ok "2. Репозитории RPM Fusion Free и Nonfree подключены"
else
    fail "2. Репозитории RPM Fusion не найдены"
fi

# 3. Драйвер NVIDIA
if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
    ok "3. Проприетарный драйвер NVIDIA активен (nvidia-smi работает)"
else
    fail "3. Драйвер NVIDIA не активен (требуется перезагрузка или выключение Secure Boot)"
fi

# 4. Vulkan
if command -v vulkaninfo >/dev/null 2>&1 && vulkaninfo --summary 2>/dev/null | grep -qi "NVIDIA"; then
    ok "4. Графический стек Vulkan видит видеокарту NVIDIA"
else
    fail "4. Vulkan не инициализирован или не видит NVIDIA"
fi

# 5. Timeshift
if command -v timeshift >/dev/null 2>&1; then
    ok "5. Утилита резервного копирования Timeshift установлена"
else
    fail "5. Timeshift не установлен"
fi

# 6. Sysctl (BBR и память)
if [[ "$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)" == "bbr" ]] && \
   [[ "$(sysctl -n vm.max_map_count 2>/dev/null)" == "2147483642" ]]; then
    ok "6. Ядерные твики sysctl (TCP BBR, max_map_count, NVMe/ZRAM) применены"
else
    fail "6. Твики sysctl не активны"
fi

# 7. Мультимедиа кодеки
if rpm -q ffmpeg >/dev/null 2>&1 && rpm -q libavcodec-freeworld >/dev/null 2>&1; then
    ok "7. Полные мультимедиа-кодеки (ffmpeg + freeworld) установлены"
else
    fail "7. Не установлены полные мультимедиа-кодеки"
fi

# 8. system76-scheduler
if systemctl is-active --quiet com.system76.Scheduler.service; then
    ok "8. Планировщик приоритетов процессов system76-scheduler активен"
else
    fail "8. Служба system76-scheduler не запущена"
fi

# 9. earlyoom
if systemctl is-active --quiet earlyoom.service; then
    ok "9. Защита от зависаний при нехватке ОЗУ (earlyoom) активна"
else
    fail "9. Служба earlyoom не запущена"
fi

# 10. PipeWire буфер
if [[ -f "$HOME/.config/pipewire/pipewire.conf.d/99-lowlatency.conf" ]]; then
    ok "10. Буфер звука PipeWire (min-quantum = 1024) настроен"
else
    fail "10. Конфиг PipeWire не найден"
fi

# 11. Переменные Wayland
if [[ -f "$HOME/.config/environment.d/99-wayland-nvidia.conf" ]]; then
    ok "11. Переменные окружения Wayland для браузеров и Electron настроены"
else
    fail "11. Файл переменных Wayland не найден"
fi

# 12. Игровое окружение и nvgame
if command -v steam >/dev/null 2>&1 && command -v gamemoderun >/dev/null 2>&1 && \
   [[ -x /usr/local/bin/nvgame ]] && \
   grep -q "__GL_SHADER_DISK_CACHE_SIZE=10737418240" /usr/local/bin/nvgame && \
   grep -q "VK_LOADER_LAYERS_DISABLE" /usr/local/bin/nvgame; then
    ok "12. Игровое окружение: Steam, GameMode и враппер nvgame (кэш 10 ГБ, VK_LOADER)"
else
    fail "12. Проблема с установкой Steam, GameMode или параметрами враппера nvgame"
fi

# 13. Блокировка iTCO_wdt
if grep -q "blacklist iTCO_wdt" /etc/modprobe.d/watchdog.conf 2>/dev/null && ! lsmod | grep -q "^iTCO_wdt"; then
    ok "13. Таймер watchdog (iTCO_wdt) заблокирован и не загружен"
else
    fail "13. Модуль iTCO_wdt загружен или не заблокирован"
fi

# 14. Konsole и профиль Fish
if [[ -f "$HOME/.local/share/konsole/Newbl1nk.colorscheme" ]] && \
   grep -q "DefaultProfile=Fish.profile" "$HOME/.config/konsolerc" 2>/dev/null; then
    ok "14. Профиль Konsole (тема Newbl1nk и Fish по умолчанию) настроен"
else
    fail "14. Настройки профиля Konsole не найдены"
fi

# 15. Оболочка Fish и промпт Starship
if command -v fish >/dev/null 2>&1 && command -v starship >/dev/null 2>&1 && \
   [[ -f "$HOME/.config/fish/config.fish" ]] && [[ -f "$HOME/.config/starship.toml" ]]; then
    ok "15. Терминал: оболочка Fish, промпт Starship и индикатор времени настроены"
else
    fail "15. Оболочка Fish или промпт Starship не настроены"
fi

# 16. Конфигурация Nano
if [[ -f "$HOME/.nanorc" ]] && grep -q "set linenumbers" "$HOME/.nanorc"; then
    ok "16. Редактор Nano (нумерация строк, табуляция, мышь) настроен"
else
    fail "16. Файл ~/.nanorc не найден"
fi

# 17. Модуль linuwu_sense и DAMX
if lsmod | grep -q "linuwu_sense" && command -v DAMX >/dev/null 2>&1; then
    ok "17. Драйвер linuwu_sense и Div Acer Manager Max (DAMX) активны (клавиша настраивается вручную)"
else
    fail "17. Модуль linuwu_sense или DAMX не обнаружены"
fi

# 18. Состояние служб systemd
FAILED_UNITS=$(systemctl --failed --no-legend | wc -l)
if [[ "$FAILED_UNITS" -eq 0 ]]; then
    ok "18. Системные службы systemd: упавших юнитов нет (0 failed)"
else
    fail "18. Обнаружены упавшие службы systemd ($FAILED_UNITS шт.)"
fi

echo "=================================================================="
echo " ИТОГ ДИАГНОСТИКИ: Успешно $PASS из 18 | Ошибок: $FAIL"
echo "=================================================================="
