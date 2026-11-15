#!/bin/sh
set -eu

# Buildroot calls this as: post-image.sh $(BINARIES_DIR) $(BR2_ROOTFS_POST_SCRIPT_ARGS)
# with the working directory at the top of the Buildroot tree, so the stock
# support/scripts/genimage.sh is found relative to it.  The genimage config
# arrives as "-c <cfg>" in BR2_ROOTFS_POST_SCRIPT_ARGS (see GSOC_defconfig).
[ "$#" -ge 2 ] || { echo "usage: $0 BINARIES_DIR -c GENIMAGE_CFG" >&2; exit 1; }
shift

rootfs="$BINARIES_DIR/rootfs.ext4"

# host-uboot-tools creates boot.scr from boot.cmd; this check keeps the
# boundary obvious when this script is used outside Buildroot's normal flow.
test -f "$BINARIES_DIR/boot.scr"
test -f "$BINARIES_DIR/zImage"
test -f "$BINARIES_DIR/sun7i-a20-xiegu-gsoc.dtb"
test -s "$rootfs"
rootfs_cksum=$(cksum "$rootfs")

# Buildroot creates rootfs.ext4 from TARGET_DIR before this hook. Do not put it
# in genimage.cfg: genimage gets an empty root path and would replace the
# populated artifact. Check integrity and representative installed paths first.
debugfs="$HOST_DIR/sbin/debugfs"
[ -x "$debugfs" ] || debugfs="$HOST_DIR/bin/debugfs"
test -x "$debugfs"
"$HOST_DIR/sbin/e2fsck" -fn "$rootfs"
"$debugfs" -R 'stat /etc' "$rootfs" | grep -q 'Inode'
"$debugfs" -R 'stat /bin/busybox' "$rootfs" | grep -q 'Inode'
"$debugfs" -R 'stat /usr/sbin/x6100_gui' "$rootfs" | grep -q 'Inode'

uboot="$BINARIES_DIR/u-boot-sunxi-with-spl.bin"
test -s "$uboot"

support/scripts/genimage.sh "$@"

# sdcard.img: this U-Boot at 8 KiB, GSOC-BOOT at LBA 2048 (1 MiB), the rootfs
# at LBA 67584 (33 MiB) and 1 GiB long, as on the cards install-payload.sh
# writes.  MBR fields are little-endian, read on a little-endian host.
img="$BINARIES_DIR/sdcard.img"
test -s "$img"
cmp -s -n "$(($(wc -c <"$uboot")))" "$uboot" "$img" 0 8192
mbr_u32() { od -An -tu4 -j "$1" -N4 "$img" | tr -d ' '; }
test "$(mbr_u32 454)" = 2048
test "$(mbr_u32 470)" = 67584
test "$(mbr_u32 474)" = 2097152
test -s "$BINARIES_DIR/boot.vfat"
test -s "$rootfs"
test "$(cksum "$rootfs")" = "$rootfs_cksum"
"$debugfs" -R 'stat /usr/sbin/x6100_gui' "$rootfs" | grep -q 'Inode'
