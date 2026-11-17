# fedora-kde-script-install

Автоматическая установка и настройка Fedora KDE Spin BTRFS для Acer Nitro V 15.

## Быстрый запуск прямо с GitHub (одной командой)

Откройте терминал на чистой системе и выполните:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh)
```

Скрипт автоматически скачает актуальную версию файлов во временную папку `/tmp` и откроет интерактивное меню выбора этапа установки (1–4).

## Состав репозитория

* **`install.sh`** — единый скрипт-диспетчер с меню выбора этапа установки.
* **`01_base_and_nvidia.sh`** — ускорение DNF5, обновление ядра, Timeshift и установка драйвера NVIDIA.
* **`02_software_and_env.sh`** — мультимедиа-кодеки, Steam, GameMode, ProtonUp-Qt, Protontricks, оболочка Fish, `lf` и `bat`.
* **`03_verify_setup.sh`** — комплексная самодиагностика драйверов, служб и окружения.
* **`04_install_damx.sh`** — установка и патч модуля вентиляторов Div Acer Manager Max (DAMX).
