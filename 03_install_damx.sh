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
WORK_DAMX="/tmp/damx_install"

on_exit() {
    local rc=$?
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
    echo -e "${RED}Ошибка: не запускайте скрипт от имени root (без sudo).${NC}"
    exit 1
fi

sudo -v
( while sleep 50; do sudo -n true 2>/dev/null || exit 0; done ) >/dev/null 2>&1 &
SUDO_PID=$!

echo -e "${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ЭТАП 3: УСТАНОВКА DIV ACER MANAGER MAX (DAMX) (ACER NITRO V15-51)   ${NC}"
echo -e "${CYAN}======================================================================${NC}"

STEP="установка сборочных зависимостей DKMS"
echo -e "\n${YELLOW}[1/3] Установка зависимостей для сборки модуля ядра linuwu_sense ($(uname -r))...${NC}"
sudo dnf install -y dkms "kernel-devel-$(uname -r)" kernel-headers gcc make git curl tar xz

STEP="поиск или загрузка архива DAMX"
echo -e "\n${YELLOW}[2/3] Поиск локального архива DAMX или загрузка последнего релиза с GitHub...${NC}"
rm -rf "$WORK_DAMX"
mkdir -p "$WORK_DAMX"

LOCAL_ARCHIVE=$(find "$HOME/Документы" "$HOME/Documents" "$HOME/Загрузки" "$HOME/Downloads" -maxdepth 3 -name "DAMX-*.tar.xz" 2>/dev/null | head -n 1 || true)

if [[ -n "$LOCAL_ARCHIVE" && -f "$LOCAL_ARCHIVE" ]]; then
    echo -e "${GREEN}Найден локальный архив: ${LOCAL_ARCHIVE}${NC}"
    cp "$LOCAL_ARCHIVE" "$WORK_DAMX/damx.tar.xz"
else
    echo -e "${CYAN}Локальный архив не найден, скачиваю последний релиз с GitHub...${NC}"
    REL_PATH=$(curl -fsSL "https://github.com" 2>/dev/null \
        | grep -oE '/PXDiv/Div-Acer-Manager-Max/releases/download/[^"]+DAMX-[^"]+\.tar\.xz' \

        | head -n 1 || true)

    if [[ -n "$REL_PATH" ]]; then
        DIRECT_URL="https://github.com${REL_PATH}"
    else
        DIRECT_URL="https://github.com"
    fi

    echo -e "${CYAN}Загрузка: ${DIRECT_URL}${NC}"
    if ! curl -fL --progress-bar "$DIRECT_URL" -o "$WORK_DAMX/damx.tar.xz"; then
        echo -e "${RED}Не удалось скачать архив DAMX.${NC}"
        exit 1
    fi
fi

STEP="распаковка и запуск установщика DAMX"
echo -e "\n${YELLOW}[3/3] Распаковка и установка Div Acer Manager Max...${NC}"
tar -xJf "$WORK_DAMX/damx.tar.xz" -C "$WORK_DAMX"
INSTALL_SCRIPT=$(find "$WORK_DAMX" -maxdepth 3 \( -name "setup.sh" -o -name "install.sh" \) | head -n 1)

if [[ -z "$INSTALL_SCRIPT" ]]; then
    echo -e "${RED}Не найден внутренний скрипт setup.sh внутри архива DAMX.${NC}"
    exit 1
fi

chmod +x "$INSTALL_SCRIPT"
cd "$(dirname "$INSTALL_SCRIPT")"
sudo ./"$(basename "$INSTALL_SCRIPT")" </dev/tty

FINISHED=1
echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}  DIV ACER MANAGER MAX (DAMX) УСПЕШНО УСТАНОВЛЕН!                     ${NC}"
echo -e "${CYAN}  Подсказка: клавишу Nitro для запуска команды DAMX назначьте сами в  ${NC}"
echo -e "${CYAN}  Параметры системы KDE -> Клавиатура -> Комбинации клавиш.           ${NC}"
echo -e "${GREEN}======================================================================${NC}"
