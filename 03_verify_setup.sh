#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0

ok() { echo -e "  [${GREEN}OK${NC}]   $1"; ((PASS++)); }
fail() { echo -e "  [${RED}FAIL${NC}] $1"; ((FAIL++)); }
warn() { echo -e "  [${YELLOW}WARN${NC}] $1"; ((WARN++)); }

echo "========================================================================"
echo "  ДИАГНОСТИКА СИСТЕМЫ FEDORA KDE (ACER NITRO V 15 - v49)"
echo "========================================================================"

echo ""
echo "[1/5] Проверка графики NVIDIA и параметров ядра:"
if lsmod | grep -q "^nvidia "; then
  ok "Модуль ядра NVIDIA загружен (версия: $(modinfo -F version nvidia 2>/dev/null))"
else
  fail "Модуль ядра NVIDIA НЕ загружен!"
fi

if [ "$(sudo cat /sys/module/nvidia_drm/parameters/modeset 2>/dev/null)" = "Y" ]; then
  ok "Режим NVIDIA DRM KMS активен (modeset=Y)"
else
  fail "Режим NVIDIA DRM KMS выключен или недоступен"
fi

if sudo grubby --info=DEFAULT | grep -q "modprobe.blacklist=nouveau,nova_core"; then
  ok "Драйверы nouveau и nova_core заблокированы в ядре"
else
  warn "В параметрах загрузки ядра не найдена блокировка nouveau,nova_core"
fi

if grep -q "PreserveVideoMemoryAllocations: 1" /proc/driver/nvidia/params 2>/dev/null; then
  ok "Сохранение видеопамяти в спящем режиме включено (PreserveVideoMemoryAllocations=1)"
else
  fail "PreserveVideoMemoryAllocations не равно 1"
fi

if systemctl is-enabled nvidia-suspend nvidia-hibernate nvidia-resume >/dev/null 2>&1; then
  ok "Службы сна NVIDIA (suspend, hibernate, resume) включены"
else
  fail "Службы сна NVIDIA не включены"
fi

echo ""
echo "[2/5] Проверка энергосбережения и профиля простоя GPU:"
if grep -q "GSK_RENDERER=gl" "$HOME/.config/environment.d/gtk.conf" 2>/dev/null; then
  ok "Запрет GTK 4 будить NVIDIA настроен (GSK_RENDERER=gl)"
else
  fail "Файл ~/.config/environment.d/gtk.conf не найден"
fi

if command -v nvidia-smi >/dev/null 2>&1; then
  PSTATE=$(nvidia-smi --query-gpu=pstate --format=csv,noheader 2>/dev/null | xargs)
  POWER=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader 2>/dev/null | xargs)
  TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader 2>/dev/null | xargs)
  if [ "$PSTATE" = "P8" ]; then
    ok "Видеокарта NVIDIA находится в экономичном профиле простоя P8 (${POWER}, ${TEMP}°C)"
  else
    warn "Видеокарта сейчас в профиле ${PSTATE} (${POWER}, ${TEMP}°C). В простое ожидается P8"
  fi
fi

echo ""
echo "[3/5] Проверка мультимедиа и ускорения видео:"
if rpm -q ffmpeg >/dev/null 2>&1; then
  ok "Установлен полноценный пакет FFmpeg"
else
  fail "Полноценный пакет FFmpeg не установлен"
fi

if rpm -q intel-media-driver >/dev/null 2>&1; then
  ok "Установлен полноценный видеодрайвер Intel (intel-media-driver)"
else
  fail "Пакет intel-media-driver не установлен"
fi

if rpm -q mozilla-openh264 >/dev/null 2>&1; then
  ok "Кодеки OpenH264 для браузера установлены"
else
  warn "Кодек mozilla-openh264 не установлен"
fi

echo ""
echo "[4/5] Проверка Steam, GameMode и системных служб:"
if [ -f /etc/tmpfiles.d/intel-rapl.conf ]; then
  ok "Правило прав доступа к Intel RAPL настроено (/etc/tmpfiles.d/intel-rapl.conf)"
else
  fail "Отсутствует /etc/tmpfiles.d/intel-rapl.conf"
fi

if gamemoded -t >/dev/null 2>&1; then
  ok "GameMode установлен и проходит все тесты (All Tests Passed!)"
else
  warn "GameMode установлен, но gamemoded -t вернул предупреждения (проверьте права группы после перезагрузки)"
fi

if systemctl is-active fstrim.timer >/dev/null 2>&1; then
  ok "Таймер фоновой очистки SSD (fstrim.timer) активен"
else
  fail "Таймер fstrim.timer не активен"
fi

if ! systemctl is-enabled NetworkManager-wait-online.service >/dev/null 2>&1; then
  ok "Служба ожидания сети при загрузке отключена (быстрый старт)"
else
  warn "NetworkManager-wait-online.service все еще включена"
fi

echo ""
echo "[5/5] Проверка терминала Fish, lf и модулей Acer Nitro:"
if [ "$SHELL" = "/usr/bin/fish" ] && command -v fish >/dev/null 2>&1; then
  ok "Оболочка Fish установлена и выбрана по умолчанию"
else
  warn "Оболочка по умолчанию: $SHELL (ожидается /usr/bin/fish)"
fi

if command -v lf >/dev/null 2>&1 && command -v bat >/dev/null 2>&1 && [ -f "$HOME/.config/fish/functions/lfcd.fish" ]; then
  ok "Файловый менеджер lf, bat и функция lfcd настроены"
else
  fail "Не все компоненты lf/bat/lfcd найдены"
fi

if grep -q "alias gpuinfo=" "$HOME/.config/fish/config.fish" 2>/dev/null; then
  ok "Алиас мониторинга видеокарты gpuinfo добавлен в config.fish"
else
  warn "Алиас gpuinfo не найден в ~/.config/fish/config.fish"
fi

if lsmod | grep -q "linuwu_sense"; then
  ok "Модуль управления вентиляторами DAMX (linuwu_sense) загружен в ядро"
else
  echo -e "  [INFO] Модуль DAMX (linuwu_sense) не установлен (опциональный компонент)"
fi

echo ""
echo "========================================================================"
echo -e "  ИТОГ ПРОВЕРКИ: ${GREEN}Успешно: $PASS${NC} | ${YELLOW}Предупреждений: $WARN${NC} | ${RED}Ошибок: $FAIL${NC}"
echo "========================================================================"
