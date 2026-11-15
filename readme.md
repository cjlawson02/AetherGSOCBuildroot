# Aether GSOC

A project to build a Linux kernel and OS for the Xiegu GSOC (Allwinner A20)
from source, running the [OpenX6X00](https://github.com/cjlawson02/OpenX6X00)
GUI on its G90 backend (`libg90`). Buildroot 2025.02 LTS, kernel 6.18.

The build makes a whole SD card image with its own mainline U-Boot, and the
boot and root partition payloads on their own for cards that already boot.

## Building

### Building on Linux

To build on a Linux machine, just:

```shell
./br_config.sh
cd build
make
```

And then you'll have in `build/images`:

| File | Goes to |
|------|---------|
| `sdcard.img` | a whole SD card: U-Boot at 8 KiB, `GSOC-BOOT` at 1 MiB, the rootfs at 33 MiB (1 GiB) |
| `u-boot-sunxi-with-spl.bin` | the card's boot area, 8 KiB to 1 MiB |
| `zImage`, `sun7i-a20-xiegu-gsoc.dtb`, `boot.scr` | the SD card's first partition (FAT, `GSOC-BOOT`) |
| `boot.vfat` | the same three files as a partition image |
| `rootfs.ext4` | the second partition |

#### Buildroot dependencies

If you are indeed using Linux, check the pre-requesites of Buildroot
[here](https://buildroot.org/downloads/manual/manual.html#requirement).

### Building on other OSes

The recomended way of building this repo on other systems is using Docker
(`Dockerfile`, Debian 12).

## Configuration notes

`GSOC_defconfig` is kept as `make savedefconfig` writes it, so these notes live
here:

- Toolchain: Arm's prebuilt GNU toolchain 14.2.rel1 (GCC 14.2, glibc 2.40), the
  aarch64- or x86_64-hosted one, so no GCC/glibc build; per-package directories,
  so `make -jN` builds packages side by side.
- U-Boot is mainline 2026.10, `u-boot/xiegu_gsoc_defconfig`: Cubieboard2's
  with the GSOC's DRAM clock (432 MHz; the rest of the A20 DRAM defaults match
  the stock SPL), the stock LCD console settings (logo on the panel, HDMI
  off), no SATA, Ethernet or USB, and the environment stored nowhere. Its own
  device tree, `u-boot/sun7i-a20-xiegu-gsoc.dts`, has the SD card (card-detect
  PE0), UART0 and the PMIC only: U-Boot never sees the eMMC, and PB8 (I2S0 here,
  AHCI power on the Cubieboard2) is left alone. `boot.cmd` also works under the
  radio's stock U-Boot. `post-build.sh` refuses any U-Boot file this tree did
  not build.
- `linux-tools` perf: profiling the GUI on the board.
- Python 3 (ssl, sqlite3, zlib), CA certificates, `openssl` and Avahi: the GUI's
  Python helpers (broadcast list, POTA spots, conditions, Wavelog, Winlink,
  Tailscale, updater) use HTTPS; Avahi gives the radio its mDNS name.
- PulseAudio runs system-wide (`etc/pulse`, upstream's `system.pa` with
  `system.pa.d/gsoc-system.pa`); the CS4271 IQ card is kept out of it for the
  GUI's direct 192 kHz capture.
- The web configurator (`gsoc-webserver`) is OpenX6X00's `webserver/` at the
  GUI's commit, on ports 80 and 443 (`S96webserver`): its `.hash` changes with
  the GUI's.
- Bluetooth as on the X6100: BlueZ's deprecated tools (`hciconfig`, `rfcomm`,
  `sdptool`) for the GUI's CAT over SPP, SBC for Pulse's Bluetooth audio.
- Not carried over from the X6100 image: its hardware (R16 DTS and U-Boot
  config, panel driver, `stm32flash`, mixer state), RHVoice, the `/mnt/*.tgz` updater, the
  server NIC firmware, the default root password, and libraries nothing on
  the GSOC uses.

## Changing buildroot configurations

If you want to change the Buildroot configuration, first do this:

```shell
cd build
make menuconfig
```

### Changing the Linux kernel configuration

```sh
cd build
make linux-menuconfig
```

### Other useful recipes

If you change the `boot.cmd` file, then you have to run:

```sh
make host-uboot-tools-rebuild
make
```

[source](https://stackoverflow.com/questions/66116553/boot-scr-rebuild-in-buildroot)

## Layout

| Path | What |
|------|------|
| `br2_external/configs/GSOC_defconfig` | the image |
| `br2_external/board/GSOC/dts/` | board device tree, on mainline `sun7i-a20.dtsi` |
| `br2_external/board/GSOC/linux/` | kernel config and the rootfs overlay (init scripts, udev, Pulse) |
| `br2_external/board/GSOC/u-boot/` | U-Boot defconfig and device tree, `boot.cmd` |
| `br2_external/board/GSOC/patches/` | kernel patches (keypad handoff, CS4271 crystal wait, panel, musb, btusb) and liquid-dsp |
| `br2_external/package/` | `gsoc-gui` (OpenX6X00), `gsoc-webserver`, `libg90`, `ft8lib`, `python-bottle-sqlite` |
