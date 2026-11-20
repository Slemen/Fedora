# Настройка Fedora KDE для Acer Nitro V15-51 (v51)

> **Дисклеймер:** Данные скрипты и конфигурации созданы исключительно под личные нужды автора и конкретное оборудование ноутбука **Acer Nitro V15-51**. Автор не несёт ответственности за возможные сбои или потерю данных при их использовании на других системах.

## Быстрый запуск на чистой системе

Выполните в терминале (предварительно выключив **Secure Boot** в BIOS):

```bash
curl -fsSL slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
```

Резервная прямая команда с GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

## Порядок выполнения этапов

1. **`01_base_and_nvidia.sh`** — Ускорение `DNF5` (5 параметров), подключение `RPM Fusion`, установка `Timeshift`, проприетарного драйвера `NVIDIA` + `CUDA` + `Vulkan`, ядерные твики `sysctl` (`TCP BBR`, `NVMe`, `ZRAM`, `max_map_count`) и блокировка `iTCO_wdt`. **После этапа обязательна перезагрузка.**
2. **`02_software_and_env.sh`** — Мультимедиа-кодеки (`ffmpeg`, `freeworld`), `Steam`, службы `system76-scheduler`, `earlyoom` и `btrfs-scrub`, настройка `PipeWire` и `Wayland`, враппер `/usr/local/bin/nvgame` (кэш шейдеров NVIDIA 10 ГБ без автоочистки + отключение неявных слоёв Vulkan), оболочка `Fish` с индикатором времени выполнения команд справа, промпт `Starship`, тема Konsole `Newbl1nk` и конфиг `Nano`. **После этапа обязательна перезагрузка.**
3. **`03_install_damx.sh`** — Компиляция модуля ядра `linuwu_sense` и установка `Div Acer Manager Max (DAMX)`. Привязку кнопки **Nitro** к команде `DAMX` настройте вручную в *Параметры системы → Клавиатура → Комбинации клавиш*.
4. **`04_verify_setup.sh`** — Автоматическая проверка всех 18 пунктов настройки.
