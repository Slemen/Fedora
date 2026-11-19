#!/usr/bin/env bash
set -e

# ВНИМАНИЕ: Скрипт создан автором под собственные нужды и конкретное железо
# (Acer Nitro V 15). Автор не несёт ответственности за последствия его использования.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}Запускайте скрипт от обычного пользователя (sudo запросится автоматически).${NC}"
    exit 1
fi

echo -e "${CYAN}Для установки модуля Div Acer Manager Max (DAMX) требуются права администратора.${NC}"
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

echo -e "\n${CYAN}======================================================================${NC}"
echo -e "${CYAN}  ЭТАП 3: УСТАНОВКА DIV ACER MANAGER MAX (DAMX / LINUWU_SENSE)${NC}"
echo -e "${CYAN}======================================================================${NC}"

echo -e "\n${YELLOW}[1/3] Установка зависимостей сборки (jq, dkms, make, gcc)...${NC}"
sudo dnf install -y jq dkms make gcc kernel-devel
echo -e "${GREEN}✔ Зависимости установлены.${NC}"

WORK_DAMX="/tmp/damx_install"
rm -rf "$WORK_DAMX"
mkdir -p "$WORK_DAMX"

LOCAL_ARCHIVE=$(find "$HOME/Документы" "$HOME/Documents" -maxdepth 2 -name "DAMX-*.tar.xz" 2>/dev/null | head -n 1 || true)

if [[ -n "$LOCAL_ARCHIVE" && -f "$LOCAL_ARCHIVE" ]]; then
    echo -e "${YELLOW}[2/3] Найден локальный архив: $LOCAL_ARCHIVE${NC}"
    cp "$LOCAL_ARCHIVE" "$WORK_DAMX/DAMX.tar.xz"
else
    echo -e "${YELLOW}[2/3] Загрузка свежего релиза DAMX с GitHub...${NC}"
    DOWNLOAD_URL=$(curl -fsSL https://api.github.com/repos/PXDiv/Div-Acer-Manager-Max/releases/latest \
        | jq -r '.assets[] | select(.name | endswith(".tar.xz")) | .browser_download_url' \
        | head -n 1)
    if [[ -z "$DOWNLOAD_URL" ]]; then
        echo -e "${RED}Не удалось получить ссылку на релиз DAMX с GitHub.${NC}"
        exit 1
    fi
    curl -fL "$DOWNLOAD_URL" -o "$WORK_DAMX/DAMX.tar.xz"
fi

echo -e "${YELLOW}[3/3] Распаковка и запуск установщика DAMX...${NC}"
tar -xf "$WORK_DAMX/DAMX.tar.xz" -C "$WORK_DAMX"
INSTALL_SCRIPT=$(find "$WORK_DAMX" -name "install.sh" | head -n 1)
if [[ -z "$INSTALL_SCRIPT" ]]; then
    echo -e "${RED}Не найден install.sh внутри архива DAMX.${NC}"
    exit 1
fi
chmod +x "$INSTALL_SCRIPT"
sudo bash "$INSTALL_SCRIPT"

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}Установка DAMX завершена!${NC}"
echo -e "${GREEN}======================================================================${NC}"
