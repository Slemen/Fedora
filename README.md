# Автоустановка и настройка Fedora KDE для Acer Nitro V15-51 (v57)

> **ВНИМАНИЕ:** Скрипты созданы автором под собственные нужды и конкретное железо (**Acer Nitro V15-51**). Автор не несёт ответственности за последствия их использования на других конфигурациях.

## Быстрый запуск на чистой системе Fedora KDE

Откройте терминал (**Konsole**) и выполните короткую команду (работает в `bash` и `fish`):

```bash
curl -fsSL https://slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
```

**Резервная прямая команда с GitHub:**

```bash
curl -fsSL https://raw.githubusercontent.com/Slemen/Fedora/main/install.sh -o /tmp/install.sh && bash /tmp/install.sh
```

---

## Состав этапов установки

1. **`01_base_and_nvidia.sh` (Этап 1):**
   * Ускорение DNF5 (`max_parallel_downloads=10`, `fastestmirror=True`, `defaultyes=True`, `timeout=30`, `ip_resolve=4`).
   * Подключение **RPM Fusion** (Free & Nonfree) и обновление системы.
   * Установка **Timeshift** для управления снимками Btrfs.
   * Установка графического стека: драйвер **NVIDIA**, CUDA, Vulkan, **`intel-media-driver`** и службы сохранения видеопамяти при выходе из сна (`nvidia-suspend`, `nvidia-hibernate`, `nvidia-resume`).
   * Ядерные твики `sysctl` (сетевой стек **CAKE + BBR**, `kernel.split_lock_mitigate = 0`, `vm.compaction_proactiveness = 0`, `vm.max_map_count`, ZRAM), отключение энергосбережения **Wi-Fi** (`wifi.powersave = 2` для стабильного пинга в играх), правила `udev` (`ntsync` и планировщик I/O `none` для NVMe), оптимизация SSD (**`noatime`** для Btrfs в `/etc/fstab` + лимит логов `journald` 150 МБ) и надёжная блокировка таймера `iTCO_wdt`.
2. **`02_software_and_env.sh` (Этап 2):**
   * Полные мультимедиа-кодеки (`ffmpeg`, `gstreamer1-plugins-bad-freeworld`, `gstreamer1-plugins-ugly`, `libva-nvidia-driver`) и утилиты диагностики графики (`libva-utils`, `vdpauinfo`, `glx-utils`).
   * Чистый **Steam**, **GameMode** (с добавлением пользователя в группу `gamemode`), службы `system76-scheduler`, `earlyoom`, `btrfs-scrub.timer`, словари проверки орфографии (`aspell` и `hunspell` RU/EN).
   * Исключение каталога `~/.local/share/Steam` из индексатора файлов KDE **Baloo** с перезапуском индексатора.
   * Буфер звука PipeWire (`min-quantum = 1024`), переменные Wayland (`NVD_BACKEND=direct`) и расширенный враппер **`nvgame`** (дискретная NVIDIA + `gamemoderun` + кэш шейдеров NVIDIA и DXVK на **10 ГБ** без автоочистки + отключение неявных слоёв Vulkan).
   * Оболочка **Fish** (алиасы `upd`, `clean`, `gpuinfo` и русский индикатор времени выполнения команд в минутах и секундах **слева** перед промптом), промпт **Starship**, установка шрифта **JetBrainsMono Nerd Font** (10pt), тема Konsole **Newbl1nk** и конфиг **Nano**.
3. **`03_install_damx.sh` (Этап 3):**
   * Проверка совпадения загруженного ядра с последним установленным, очистка устаревших записей DKMS, установка `kernel-devel-$(uname -r)` и компиляция драйвера `linuwu_sense` (с патчем `strscpy` для свежих ядер) + **Div Acer Manager Max (DAMX)** из локального архива в `~/Документы`. Привязка кнопки Nitro настраивается вручную в *Параметры системы KDE → Клавиатура → Комбинации клавиш*.
4. **`04_verify_setup.sh` (Этап 4):**
   * Автоматическая диагностика всех **20 пунктов** конфигурации (включая проверку загруженного модуля `linuwu_sense` и шрифта `JetBrainsMono Nerd Font`).
