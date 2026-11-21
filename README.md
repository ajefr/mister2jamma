# MiSTer2JAMMA for MiSTer

Support for the **MiSTer2JAMMA** board (4 players JAMMA controls, volume/balance, mono/stereo) on a
**standard MiSTer installation**: no custom kernel, no custom U-Boot.

The driver is a small kernel module (`mister2jamma.ko`) loaded at boot. It is distributed through a
[MiSTer Downloader](https://github.com/MiSTer-devel/Downloader_MiSTer) database, so it is updated
together with everything else when you run `update_all` or `downloader`.

## Installation

> Until the driver is installed, the JAMMA controls do not work. Both methods below are designed for that:
> no keyboard or controller is needed with method 1.

### Method 1: SD card prepared on a PC (easiest, no keyboard needed)

1. **Install MiSTer** on the SD card with the official tool ([Mr. Fusion](https://github.com/MiSTer-devel/mr-fusion)),
   put it in the MiSTer and let it finish until the MiSTer menu shows up. Then power off.
2. **Put the SD card in your PC**, download
   [`mister2jamma_sdcard.zip`](https://github.com/ajefr/mister2jamma/raw/main/sdcard/mister2jamma_sdcard.zip)
   and **extract it at the root of the SD card**, replacing existing files. It contains:
   - `linux/user-startup.sh` : loads the driver at every boot (it **replaces** your `user-startup.sh`:
     if you added your own commands to it, use method 2 instead)
   - `Scripts/.config/mister2jamma/` : the driver and its start script (hidden folder)
   - `downloader_mister2jamma.ini` : adds the MiSTer2JAMMA database to the downloader (no need to edit `downloader.ini`)
3. **Connect the MiSTer to the network** with an Ethernet cable (for WiFi, put your `wpa_supplicant.conf`
   on the SD card as explained in the Mr. Fusion instructions).
4. **Power on and wait.** If the MiSTer is not up to date yet (Mr. Fusion installs an older release), the first
   boot updates it automatically in the background, then reboots by itself. This can take several minutes.
   After that, the four players, the volume and the balance work from the JAMMA connector.

From now on, just run `update_all` (or `downloader`) as usual: when the official MiSTer Linux kernel changes,
a new module is built automatically and delivered by the database. If a boot finds no module for the running
kernel, it runs the downloader once more in the background to fetch it (log in
`Scripts/.config/mister2jamma/auto_update.log`).

### Method 2: existing MiSTer installation (keeps your `user-startup.sh`)

1. **Add the MiSTer2JAMMA database**: copy `downloader_mister2jamma.ini` (from the zip above) to the root of the
   SD card, or add these two lines at the end of `downloader.ini`:

   ```ini
   [mister2jamma]
   db_url = https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/db.json.zip
   ```
2. **Run `update_all`** (or `downloader`) from the Scripts menu. It installs the driver in
   `Scripts/.config/mister2jamma/` and the one-time setup script `Scripts/mister2jamma_install.sh`.
3. **Run `mister2jamma_install`** from the Scripts menu, **once**. It adds the driver to
   `linux/user-startup.sh` so that it is loaded at every boot, then loads it immediately.
   If you used the old MiSTer2JAMMA `user-startup.sh`, it is replaced (a copy is kept as
   `user-startup.sh.mister2jamma_old`).

Without working controls, do these steps with a temporary USB keyboard (`F12` opens the menu), or over SSH:
connect the MiSTer with an Ethernet cable, find its IP address on your router, log in with `ssh root@<ip>`
(password `1`) and run:

```sh
printf '[mister2jamma]\ndb_url = https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/db.json.zip\n' > /media/fat/downloader_mister2jamma.ini
/media/fat/Scripts/update_all.sh      # or: /media/fat/Scripts/downloader.sh
bash /media/fat/Scripts/mister2jamma_install.sh
reboot
```

### Checking that the driver is loaded

Over SSH (user `root`, password `1`):

```sh
lsmod | grep mister2jamma
dmesg | grep -i mister2jamma
```

`dmesg` should show `carte MiSTer2JAMMA prete` (board ready).

### Options

The input scan period defaults to 1 ms. It can be changed at runtime, for instance:

```sh
echo 2 > /sys/module/mister2jamma/parameters/scan_ms
```

### Troubleshooting

- **Controls stopped working right after a MiSTer Linux update**: the module for the new kernel may not be
  published yet (it is built within 24 hours). Each boot retries automatically: reboot the MiSTer later.
  `uname -r` shows your kernel version; the matching file is `Scripts/.config/mister2jamma/mister2jamma-<version>.ko`.
- **Nothing happens at boot**: check that `/media/fat/linux/user-startup.sh` contains the line
  `[ -f /media/fat/Scripts/.config/mister2jamma/start.sh ] && sh /media/fat/Scripts/.config/mister2jamma/start.sh`
  and was not saved with Windows line endings. Running `mister2jamma_install` again fixes both.
- **Uninstall**: first remove the line above from `linux/user-startup.sh`, then delete `downloader_mister2jamma.ini`
  (and the `[mister2jamma]` section of `downloader.ini` if you added it there), and run `update_all`.

## How it works

On load, the module releases the LTC header pins from the official `i2c-gpio` bus, switches them to the
hardware I2C1 controller (what the old custom U-Boot did), enables I2C1 at 400 kHz with a device tree overlay
(including the RTC chips that used the same pins), then probes the board. If no MiSTer2JAMMA board answers,
everything is restored and the module refuses to load.

The module is rebuilt by the GitHub workflow in `.github/workflows/build-module.yml`, which checks the official
distribution every day. The database is generated by `tools/make_db.py`.

---

## Legacy method (old custom kernel)

> **Warning:** the old method below installs a custom **5.15** kernel and U-Boot at every boot. It does not boot
> on current MiSTer releases (Linux 6.18 and later). It is kept only for boards still running an old MiSTer
> release. **If you update your MiSTer, switch to the installation above**: `mister2jamma_install` replaces the
> old `user-startup.sh` automatically.

Old instructions: put the [`user-startup.sh`](user-startup.sh) file directly on your MiSTer SD card in the
`/linux` directory (use the raw file, not the web page):
https://raw.githubusercontent.com/ajefr/mister2jamma/refs/heads/main/user-startup.sh
