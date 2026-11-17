# fedora-kde-script-install

Автоматическая установка и настройка Fedora KDE Spin BTRFS для Acer Nitro V 15.

## Быстрый запуск прямо с GitHub (одной командой)

Откройте терминал на чистой системе и выполните:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh)
```

Скрипт автоматически скачает актуальную версию нужного этапа во временную папку `/tmp` и запустит его.

## Порядок этапов установки

1. **01_base_and_nvidia.sh** — ускорение DNF5, подключение RPM Fusion, обновление ядра, Timeshift и установка драйвера NVIDIA (с последующей перезагрузкой).
2. **02_software_and_env.sh** — мультимедиа-кодеки, Steam, GameMode, ProtonUp-Qt, Protontricks, оболочка Fish с алиасом `gpuinfo`, `lf` и `bat` (с последующей перезагрузкой).
3. **03_install_damx.sh** — установка и патч модуля управления вентиляторами и лимитом заряда батареи Div Acer Manager Max (ищет локальный архив `DAMX-*.tar.xz` в `~/Документы` или сам скачивает свежий релиз с GitHub).
4. **04_verify_setup.sh** — финальная комплексная самодиагностика драйверов, служб, игрового окружения и модуля `linuwu_sense`.
