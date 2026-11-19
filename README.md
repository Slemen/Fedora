# fedora-kde-script-install

Автоматическая установка и настройка Fedora KDE Spin BTRFS для Acer Nitro V 15 (версия **v51**).

> [!WARNING]
> **Отказ от ответственности (Disclaimer):** Данные установочные скрипты написаны исключительно под личные задачи автора и конкретную аппаратную конфигурацию ноутбука **Acer Nitro V 15** (связка Intel + NVIDIA). Автор не несёт никакой ответственности за возможные сбои, потерю данных или некорректную работу при запуске этих скриптов на других устройствах. Используйте на свой страх и риск и обязательно делайте резервные копии перед запуском.

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

1. **01_base_and_nvidia.sh** — ускорение DNF5, подключение RPM Fusion, обновление ядра (`--refresh`), Timeshift, установка драйвера NVIDIA (`akmod-nvidia`), ядерные оптимизации `sysctl` (CachyOS) и блокировка `iTCO_wdt` (с последующей перезагрузкой).
2. **02_software_and_env.sh** — мультимедиа-кодеки, Steam, GameMode, Protontricks, `system76-scheduler`, `earlyoom`, `btrfsmaintenance` (`btrfs-scrub.timer`), игровой звук PipeWire, нативный Wayland, враппер `nvgame`, тема Konsole `Newbl1nk`, оболочка Fish с алиасами (`gpuinfo`, `upd`, `clean`), Starship с русским индикатором времени, `lf`, `bat` и `.nanorc` (с последующей перезагрузкой).
3. **03_install_damx.sh** — установка модуля управления вентиляторами и лимитом заряда батареи Div Acer Manager Max (`linuwu_sense`, ищет локальный архив `DAMX-*.tar.xz` в `~/Документы` или сам скачивает свежий релиз с GitHub).
4. **04_verify_setup.sh** — финальная комплексная самодиагностика по 18 пунктам (драйверы, службы, оптимизации, терминал, модуль `linuwu_sense` и `systemctl --failed`).
