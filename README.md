# MiSTer2JAMMA for MiSTer

Support for the **MiSTer2JAMMA** board (4 players JAMMA controls, volume/balance, mono/stereo) on a
**standard MiSTer installation**: no custom kernel, no custom U-Boot.

The driver is a small kernel module (`mister2jamma.ko`) loaded at boot. It is distributed through a
[MiSTer Downloader](https://github.com/MiSTer-devel/Downloader_MiSTer) database, so it is updated
together with everything else when you run `update_all` or `downloader`.

## Installation (recommended)

> Until the driver is installed, the JAMMA controls do not work. If you cannot reach the Scripts menu,
> see [First setup without any working controls](#first-setup-without-any-working-controls) below.

1. **Update your MiSTer** to the latest official release (run `update_all` or `downloader` once).
2. **Add the MiSTer2JAMMA database.** Open `downloader.ini` at the root of the SD card
   (`/media/fat/downloader.ini`) with a text editor and add these two lines at the end:

   ```ini
   [mister2jamma]
   db_url = https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/db.json.zip
   ```
3. **Run `update_all`** (or `downloader`) from the Scripts menu. It installs:
   - `Scripts/.config/mister2jamma/` : the driver module and its start script (hidden folder)
   - `Scripts/mister2jamma_install.sh` : the one-time setup script
4. **Run `mister2jamma_install`** from the Scripts menu, **once**. It adds the driver to
   `linux/user-startup.sh` so that it is loaded at every boot, then loads it immediately.
   If you used the old MiSTer2JAMMA `user-startup.sh`, it is replaced (a copy is kept as
   `user-startup.sh.mister2jamma_old`).
5. Reboot. The four players, the volume and the balance now work from the JAMMA connector.

From now on, just run `update_all` as usual: when the official MiSTer Linux kernel changes, a new
module is built automatically and delivered by the database.

### First setup without any working controls

Before the driver is installed, the JAMMA controls do not work, so the Scripts menu may not be reachable.
Use one of these methods for the first setup only:

**A. Temporary USB keyboard or USB controller (easiest).** Plug it into the MiSTer, follow steps 1 to 5 above
(on a keyboard: `F12` opens the menu, arrows and `Enter` to navigate), then unplug it.

**B. Over the network with SSH (no USB device needed).** Connect the MiSTer with an Ethernet cable, find its IP
address on your router, and log in with `ssh root@<ip>` (password `1`). Then run:

```sh
# 1. add the MiSTer2JAMMA database
printf '\n[mister2jamma]\ndb_url = https://raw.githubusercontent.com/ajefr/mister2jamma/main/db/db.json.zip\n' >> /media/fat/downloader.ini
# 2. update the MiSTer and download the driver
/media/fat/Scripts/update_all.sh      # or: /media/fat/Scripts/downloader.sh
# 3. enable the driver at boot, then reboot
bash /media/fat/Scripts/mister2jamma_install.sh
reboot
```

**C. Prepare the SD card on a PC.** Only if the SD card already holds an up-to-date MiSTer (Linux 6.18 or
later). With the SD card in your PC:
1. Add the two `[mister2jamma]` lines to `downloader.ini` (step 2 above).
2. Create the folder `Scripts/.config/mister2jamma/` and copy into it `start.sh` and the `mister2jamma-*.ko` files from
   [`db/files/Scripts/.config/mister2jamma/`](db/files/Scripts/.config/mister2jamma/).
3. If `linux/user-startup.sh` does not exist, or if it is the old MiSTer2JAMMA one (second line
   `#MISTER2JAMMA Version, aje_fr`), copy [`extras/sdcard/linux/user-startup.sh`](extras/sdcard/linux/user-startup.sh)
   over it. Otherwise, add this line before any `exit` line (or at the end), with an editor that keeps Unix (LF)
   line endings (Notepad++, VS Code...):
   `[ -f /media/fat/Scripts/.config/mister2jamma/start.sh ] && sh /media/fat/Scripts/.config/mister2jamma/start.sh`
4. Put the SD card back and boot: the controls work right away. Run `update_all` as usual afterwards.

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
  published yet (it is built within 24 hours). Run `update_all` again later, with a keyboard or USB controller.
  `uname -r` shows your kernel version; the matching file is `Scripts/.config/mister2jamma/mister2jamma-<version>.ko`.
- **Nothing happens at boot**: check that `/media/fat/linux/user-startup.sh` contains the line
  `[ -f /media/fat/Scripts/.config/mister2jamma/start.sh ] && sh /media/fat/Scripts/.config/mister2jamma/start.sh`
  and was not saved with Windows line endings. Running `mister2jamma_install` again fixes both.
- **Uninstall**: remove the `[mister2jamma]` section from `downloader.ini`, remove the line above from
  `linux/user-startup.sh`, and run `update_all`.

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
