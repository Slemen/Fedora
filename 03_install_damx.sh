#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# ЭТАП 3: УСТАНОВКА DIV ACER MANAGER MAX (DAMX) ДЛЯ ACER NITRO V15-51
# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V15-51). Автор не несёт ответственности за последствия его использования.
# ==============================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

STEP="подготовка"
FINISHED=0
SUDO_PID=""
PARENT_PID=$$
WORK_DAMX="/tmp/damx_install"
ORIG_DIR="$(pwd)"

on_exit() {
    local rc=$?
    cd "$ORIG_DIR" 2>/dev/null || cd /tmp
    if [[ -n "$SUDO_PID" ]]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
    rm -rf "$WORK_DAMX"
    if [[ $FINISHED -eq 0 && $rc -ne 0 ]]; then
        echo -e "\n${RED}[ОШИБКА] Скрипт остановлен на шаге: ${STEP}. Исправьте причину выше и запустите снова.${NC}" >&2
    fi
}
trap on_exit EXIT

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Ошибка: не запускайте скрипт от имени root (без sudo).${NC}" >&2
    exit 1
fi

if pgrep -x "dnf" >/dev/null 2>&1 || pgrep -x "dnf5" >/dev/null 2>&1; then
    echo -e "${RED}Ошибка: пакетный менеджер DNF сейчас занят другим процессом. Дождитесь завершения и повторите.${NC}" >&2
    exit 1
fi

LATEST_INSTALLED_KERNEL=$(rpm -q --last kernel-core 2>/dev/null | head -n 1 | awk '{print $1}' | sed 's/^kernel-core-//' || true)
RUNNING_KERNEL=$(uname -r)
if [[ -n "$LATEST_INSTALLED_KERNEL" && "$LATEST_INSTALLED_KERNEL" != "$RUNNING_KERNEL" ]]; then
    echo -e "${RED}Ошибка: система работает на старом ядре (${RUNNING_KERNEL}), но установлено новое (${LATEST_INSTALLED_KERNEL}).${NC}" >&2
    echo -e "${YELLOW}Сначала перезагрузите ноутбук (пункт 5 в меню), чтобы загрузилось новое ядро, и запустите Этап 3 снова.${NC}" >&2
    exit 1
fi

sudo -v
( while kill -0 "$PARENT_PID" 2>/dev/null; do sleep 50; sudo -n true 2>/dev/null || exit 0; done ) >/dev/null 2>&1 &
SUDO_PID=$!

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ЭТАП 3: УСТАНОВКА DIV ACER MANAGER MAX (DAMX) (ACER NITRO V15-51)   ${NC}"
echo -e "${CYAN}======================================================================${NC}"

STEP="установка сборочных зависимостей DKMS"
echo -e "\n${YELLOW}[1/3] Установка зависимостей для сборки модуля ядра linuwu_sense (${RUNNING_KERNEL})...${NC}"
sudo dnf install -y dkms "kernel-devel-${RUNNING_KERNEL}" kernel-headers gcc make git tar xz

STEP="поиск локального архива DAMX"
echo -e "\n${YELLOW}[2/3] Поиск архива DAMX-*.tar.xz в папке Документы...${NC}"
rm -rf "$WORK_DAMX"
mkdir -p "$WORK_DAMX"

ARCHIVE_STORE="$HOME/Документы/damx-archives"
LOCAL_ARCHIVE=$(find "$HOME/Документы" "$HOME/Documents" -maxdepth 3 -name "DAMX-*.tar.xz" ! -path "$ARCHIVE_STORE/*" 2>/dev/null | head -n 1 || true)

if [[ -z "$LOCAL_ARCHIVE" || ! -f "$LOCAL_ARCHIVE" ]]; then
    LOCAL_ARCHIVE=$(find "$ARCHIVE_STORE" -maxdepth 2 -name "DAMX-*.tar.xz" 2>/dev/null | head -n 1 || true)
fi

if [[ -z "$LOCAL_ARCHIVE" || ! -f "$LOCAL_ARCHIVE" ]]; then
    echo -e "${RED}Архив DAMX-*.tar.xz не найден в ~/Документы (или ~/Documents).${NC}" >&2
    echo -e "${YELLOW}Скачайте архив вручную из официального репозитория PXDiv / Div-Acer-Manager-Max (раздел Releases на GitHub).${NC}" >&2
    echo -e "${YELLOW}Положите скачанный файл в папку ~/Документы и запустите Этап 3 снова.${NC}" >&2
    exit 1
fi

echo -e "${GREEN}Найден локальный архив: ${LOCAL_ARCHIVE}${NC}"
cp "$LOCAL_ARCHIVE" "$WORK_DAMX/damx.tar.xz"

if ! xz -t "$WORK_DAMX/damx.tar.xz" >/dev/null 2>&1; then
    echo -e "${RED}Файл ${LOCAL_ARCHIVE} повреждён или не является корректным архивом .tar.xz.${NC}" >&2
    exit 1
fi

STEP="распаковка, очистка старого DKMS и запуск установщика DAMX"
echo -e "\n${YELLOW}[3/3] Распаковка и установка Div Acer Manager Max...${NC}"
tar -xJf "$WORK_DAMX/damx.tar.xz" -C "$WORK_DAMX"

if command -v dkms >/dev/null 2>&1; then
    for old_ver in $(dkms status 2>/dev/null | awk -F'[,:/]' '/linuwu_sense/ {gsub(/ /, "", $2); print $2}' | sort -u); do
        sudo dkms remove "linuwu_sense/${old_ver}" --all 2>/dev/null || true
    done
fi

# Патч совместимости с ядрами, где strncpy удалён/заменён на strscpy
if grep -rq "strscpy(" "/lib/modules/${RUNNING_KERNEL}/build/include/linux/string.h" 2>/dev/null; then
    find "$WORK_DAMX" -name "linuwu_sense.c" -exec sed -i 's/\bstrncpy(/strscpy(/g' {} +
fi

INSTALL_SCRIPT=$(find "$WORK_DAMX" -maxdepth 3 -name "setup.sh" | head -n 1 || true)
if [[ -z "$INSTALL_SCRIPT" ]]; then
    INSTALL_SCRIPT=$(find "$WORK_DAMX" -maxdepth 3 -name "install.sh" | head -n 1 || true)
fi

if [[ -z "$INSTALL_SCRIPT" ]]; then
    echo -e "${RED}Не найден внутренний скрипт setup.sh/install.sh внутри архива DAMX.${NC}" >&2
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"
cd "$(dirname "$INSTALL_SCRIPT")"
sudo ./"$(basename "$INSTALL_SCRIPT")" </dev/tty

mkdir -p "$ARCHIVE_STORE"
if [[ "$(dirname "$LOCAL_ARCHIVE")" != "$ARCHIVE_STORE" ]]; then
    mv -f "$LOCAL_ARCHIVE" "$ARCHIVE_STORE/"
    echo -e "${CYAN}Архив перемещён в ${ARCHIVE_STORE} для последующей пересборки при обновлении ядра.${NC}"
fi

FINISHED=1
echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}  DIV ACER MANAGER MAX (DAMX) УСПЕШНО УСТАНОВЛЕН!                     ${NC}"
echo -e "${CYAN}  Подсказка: клавишу Nitro для запуска команды DAMX назначьте сами в  ${NC}"
echo -e "${CYAN}  Параметры системы KDE -> Клавиатура -> Комбинации клавиш.           ${NC}"
echo -e "${GREEN}======================================================================${NC}"
