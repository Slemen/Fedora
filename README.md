# Автоустановка и настройка Fedora KDE для Acer Nitro V15-51 (v52)

> **ВНИМАНИЕ:** Скрипты созданы автором под собственные нужды и конкретное железо (**Acer Nitro V15-51**). Автор не несёт ответственности за последствия их использования на других конфигурациях.

## Быстрый запуск на чистой системе Fedora KDE

Откройте терминал (**Konsole**) и выполните короткую команду (работает в `bash` и `fish`):

```bash
curl -fsSL slemen.github.io/Fedora/go -o /tmp/go && bash /tmp/go
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
   * Установка **Timeshift** и **Btrfs-Assistant** для управления снимками Btrfs.
   * Установка проприетарного драйвера **NVIDIA**, CUDA и Vulkan.
   * Ядерные твики `sysctl` (CachyOS / SteamOS / Nobara: сетевой стек **CAKE + BBR**, `kernel.split_lock_mitigate = 0`, `vm.compaction_proactiveness = 0`, `vm.max_map_count`, ZRAM) и надёжная блокировка таймера `iTCO_wdt`.
2. **`02_software_and_env.sh` (Этап 2):**
   * Полные мультимедиа-кодеки (`ffmpeg`, `gstreamer1-plugins-bad-freeworld`, `gstreamer1-plugins-ugly`, `libva-nvidia-driver`).
   * Чистый **Steam** (без лишнего софта и Flatpak), службы `system76-scheduler`, `earlyoom` и `btrfs-scrub.timer`.
   * Исключение каталога `~/.local/share/Steam` из индексатора файлов KDE **Baloo**.
   * Буфер звука PipeWire (`min-quantum = 1024`), переменные Wayland и расширенный враппер **`nvgame`** (дискретная NVIDIA + `gamemoderun` + кэш шейдеров NVIDIA и DXVK на **10 ГБ** без автоочистки + отключение неявных слоёв Vulkan).
   * Оболочка **Fish** (алиасы `upd`, `clean`, `gpuinfo` и русский индикатор времени выполнения команд в `fish_right_prompt`), промпт **Starship**, автоустановка шрифта **JetBrainsMono Nerd Font**, тема Konsole **Newbl1nk** и конфиг **Nano**.
3. **`03_install_damx.sh` (Этап 3):**
   * Установка драйвера `linuwu_sense` (с точной привязкой `kernel-devel-$(uname -r)`) и **Div Acer Manager Max (DAMX)** (управление профилями питания, вентиляторами и ограничением заряда батареи 80%). Привязка кнопки Nitro настраивается вручную в *Параметры системы KDE → Клавиатура → Комбинации клавиш*.
4. **`04_verify_setup.sh` (Этап 4):**
   * Автоматическая диагностика всех **18 пунктов** конфигурации.
