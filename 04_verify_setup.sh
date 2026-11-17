#!/usr/bin/env bash

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

OK_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

print_ok()   { echo -e "  ${GREEN}[OK]${NC}   $1"; ((OK_COUNT++)); }
print_warn() { echo -e "  ${YELLOW}[WARN]${NC} $1"; ((WARN_COUNT++)); }
print_fail() { echo -e "  ${RED}[FAIL]${NC} $1"; ((FAIL_COUNT++)); }

echo "========================================================================"
echo "  ФИНАЛЬНАЯ ДИАГНОСТИКА СИСТЕМЫ FEDORA KDE (ACER NITRO V 15)"
echo "========================================================================"

echo -e "\n[1/5] Проверка графики NVIDIA и параметров ядра:"
if lsmod | grep -q "^nvidia "; then
    NV_VER=$(modinfo -F version nvidia 2>/dev/null || echo "неизвестно")
    print_ok "Модуль ядра NVIDIA загружен (версия: ${NV_VER})"
else
    print_fail "Модуль ядра NVIDIA НЕ загружен"
fi

if [[ "$(cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null)" == "Y" ]]; then
    print_ok "Режим NVIDIA DRM KMS активен (modeset=Y)"
else
    print_fail "Режим NVIDIA DRM KMS не активен"
fi

if grep -q "nouveau" /proc/cmdline && grep -q "nova_core" /proc/cmdline; then
    print_ok "Драйверы nouveau и nova_core заблокированы в ядре"
else
    print_warn "Не найдена полная блокировка nouveau/nova_core в параметрах ядра"
fi

if grep -q "PreserveVideoMemoryAllocations=1" /etc/modprobe.d/nvidia-power-management.conf 2>/dev/null; then
    print_ok "Сохранение видеопамяти в спящем режиме включено"
else
    print_warn "Не найден конфиг сохранения видеопамяти NVIDIA"
fi

if systemctl is-enabled nvidia-suspend.service nvidia-resume.service &>/dev/null; then
    print_ok "Службы сна NVIDIA (suspend, resume) включены"
else
    print_fail "Службы сна NVIDIA не включены"
fi

echo -e "\n[2/5] Проверка энергосбережения и профилей GPU:"
if grep -q "GSK_RENDERER=gl" ~/.config/environment.d/gtk.conf 2>/dev/null; then
    print_ok "Запрет GTK 4 будить NVIDIA настроен (GSK_RENDERER=gl)"
else
    print_warn "Переменная GSK_RENDERER=gl не найдена в ~/.config/environment.d/gtk.conf"
fi

PSTATE=$(nvidia-smi --query-gpu=pstate --format=csv,noheader 2>/dev/null | tr -d ' ')
if [[ "$PSTATE" == "P8" ]]; then
    print_ok "Видеокарта NVIDIA в экономичном режиме простоя (${PSTATE})"
elif [[ -n "$PSTATE" ]]; then
    print_warn "Видеокарта в активном режиме (${PSTATE}). Закройте тяжелые окна для перехода в P8"
else
    print_fail "Не удалось опросить состояние видеокарты через nvidia-smi"
fi

echo -e "\n[3/5] Проверка мультимедиа и ускорения видео:"
if rpm -q ffmpeg &>/dev/null; then
    print_ok "Установлен полноценный пакет FFmpeg"
else
    print_fail "Полноценный пакет FFmpeg не установлен"
fi

if rpm -q intel-media-driver &>/dev/null; then
    print_ok "Установлен полноценный видеодрайвер Intel (intel-media-driver)"
else
    print_fail "Пакет intel-media-driver не установлен"
fi

if rpm -q mozilla-openh264 &>/dev/null; then
    print_ok "Кодеки OpenH264 для браузера установлены"
else
    print_warn "Кодеки OpenH264 не установлены"
fi

echo -e "\n[4/5] Проверка Steam, GameMode и системных служб:"
if [[ -f /etc/tmpfiles.d/intel-rapl.conf ]]; then
    print_ok "Правило прав доступа к Intel RAPL настроено (/etc/tmpfiles.d/intel-rapl.conf)"
else
    print_fail "Отсутствует правило /etc/tmpfiles.d/intel-rapl.conf"
fi

if gamemoded -t &>/dev/null; then
    print_ok "GameMode прошёл все тесты (All Tests Passed!)"
else
    print_warn "GameMode установлен, но gamemoded -t вернул предупреждения"
fi

if systemctl is-enabled fstrim.timer &>/dev/null; then
    print_ok "Таймер фоновой очистки SSD (fstrim.timer) активен"
else
    print_warn "Таймер fstrim.timer не активен"
fi

echo -e "\n[5/5] Проверка терминала Fish, lf и модулей Acer Nitro:"
if [[ "$SHELL" == *"fish"* ]]; then
    print_ok "Оболочка Fish установлена и выбрана по умолчанию"
else
    print_warn "Оболочка Fish не выбрана по умолчанию"
fi

if command -v lf &>/dev/null && command -v bat &>/dev/null && grep -q "gpuinfo" ~/.config/fish/config.fish 2>/dev/null; then
    print_ok "Файловый менеджер lf, bat и алиас gpuinfo настроены"
else
    print_warn "Не все компоненты терминала (lf, bat, gpuinfo) найдены"
fi

if lsmod | grep -q linuwu_sense; then
    print_ok "Модуль вентиляторов и батареи DAMX (linuwu_sense) загружен и активен"
else
    print_warn "Модуль DAMX (linuwu_sense) не загружен (установите через ./03_install_damx.sh или перезагрузите ПК)"
fi

echo "========================================================================"
echo -e "  ИТОГ ПРОВЕРКИ: ${GREEN}Успешно: ${OK_COUNT}${NC} | ${YELLOW}Предупреждений: ${WARN_COUNT}${NC} | ${RED}Ошибок: ${FAIL_COUNT}${NC}"
echo "========================================================================"
