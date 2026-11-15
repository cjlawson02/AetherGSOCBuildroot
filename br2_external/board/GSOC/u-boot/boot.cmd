# Loaded by U-Boot's distro boot from GSOC-BOOT (mmc 0 is the SD card); works
# under the self-built mainline U-Boot and under the stock Xiegu one.
setenv bootargs console=tty0 console=ttyS0,115200 root=/dev/mmcblk0p2 rootwait rw panic=10 clk_ignore_unused
fatload mmc 0:1 0x42000000 zImage
fatload mmc 0:1 0x43000000 sun7i-a20-xiegu-gsoc.dtb
bootz 0x42000000 - 0x43000000
