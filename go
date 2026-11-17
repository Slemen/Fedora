#!/usr/bin/env bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Slemen/Fedora/main"
WORK_DIR="/tmp/fedora_nitro_setup"

mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "========================================================================"
echo "  УСТАНОВКА И НАСТРОЙКА FEDORA KDE (ACER NITRO V 15)"
echo "========================================================================"
echo "Выберите этап установки:"
echo "  1) Этап 1: База, обновление ядра, Timeshift и драйвер NVIDIA (01_base_and_nvidia.sh)"
echo "  2) Этап 2: Кодеки, Steam, GameMode, Fish, lf и bat (02_software_and_env.sh)"
echo "  3) Этап 3: Управление вентиляторами и батареей DAMX (03_install_damx.sh)"
echo "  4) Этап 4: Финальная самодиагностика всей системы (04_verify_setup.sh)"
echo "  0) Выход"
echo "========================================================================"
read -rp "Введите номер этапа [1-4]: " CHOICE

case "$CHOICE" in
    1) SCRIPT="01_base_and_nvidia.sh" ;;
    2) SCRIPT="02_software_and_env.sh" ;;
    3) SCRIPT="03_install_damx.sh" ;;
    4) SCRIPT="04_verify_setup.sh" ;;
    0) echo "Выход."; exit 0 ;;
    *) echo "[ОШИБКА] Неверный выбор."; exit 1 ;;
esac

echo "Загрузка актуальной версии ${SCRIPT} с GitHub..."
curl -fsSL "${REPO_RAW}/${SCRIPT}" -o "${WORK_DIR}/${SCRIPT}"
chmod +x "${WORK_DIR}/${SCRIPT}"
exec "${WORK_DIR}/${SCRIPT}"
