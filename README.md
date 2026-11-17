# fedora-kde-script-install

Автоматическая установка и настройка Fedora KDE Spin BTRFS для Acer Nitro V 15.

## Быстрый запуск прямо с GitHub

Выберите подходящий вариант команды в зависимости от оболочки терминала:

### Вариант 1. Для чистой системы (стандартный Bash)

Откройте терминал сразу после установки Fedora KDE и выполните короткую команду:

```bash
bash <(curl -sL slemen.github.io/Fedora/go)
```

### Вариант 2. Универсальный запуск (работает и в Fish, и в Bash)

Скачивает скрипт-диспетчер во временную папку `/tmp` и запускает его:

```fish
curl -sL slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
```

*(Резервная прямая ссылка без GitHub Pages: `curl -fsSL https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh`)*

Скрипт автоматически загрузит актуальную версию нужного этапа во временную папку `/tmp` и запустит его.

## Порядок этапов установки

1. **01_base_and_nvidia.sh** — ускорение DNF5, подключение RPM Fusion, обновление ядра, Timeshift и установка драйвера NVIDIA (с последующей перезагрузкой).
2. **02_software_and_env.sh** — мультимедиа-кодеки, Steam, GameMode, ProtonUp-Qt, Protontricks, оболочка Fish с алиасом `gpuinfo`, `lf` и `bat` (с последующей перезагрузкой).
3. **03_install_damx.sh** — установка и патч модуля управления вентиляторами и лимитом заряда батареи Div Acer Manager Max (ищет локальный архив `DAMX-*.tar.xz` в `~/Документы` или сам скачивает свежий релиз с GitHub).
4. **04_verify_setup.sh** — финальная комплексная самодиагностика драйверов, служб, игрового окружения и модуля `linuwu_sense`.
