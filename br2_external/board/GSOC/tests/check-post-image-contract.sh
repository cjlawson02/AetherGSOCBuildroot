#!/bin/sh
# Exercise post-image's artifact contract with stub host utilities. This never
# builds a filesystem or a real SD image: it proves boot.vfat is separate, the
# Buildroot-produced rootfs.ext4 is retained, sdcard.img is checked for the
# U-Boot at 8 KiB and the card layout, and post-build refuses a U-Boot that
# this tree did not build.
set -eu

board_dir=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
tree_dir=$(CDPATH= cd -- "$board_dir/../../.." && pwd)
tmp_dir=$(mktemp -d "${TMPDIR:-/tmp}/gsoc-post-image.XXXXXX")
trap 'rm -rf "$tmp_dir"' EXIT

bin_dir="$tmp_dir/bin"
host_dir="$tmp_dir/host"
images_dir="$tmp_dir/images"
mkdir -p "$bin_dir" "$host_dir/sbin" "$images_dir"
printf 'populated-rootfs-sentinel\n' >"$images_dir/rootfs.ext4"
printf 'zImage\n' >"$images_dir/zImage"
printf 'dtb\n' >"$images_dir/sun7i-a20-xiegu-gsoc.dtb"
printf 'boot script\n' >"$images_dir/boot.scr"
printf 'self-built u-boot\n' >"$images_dir/u-boot-sunxi-with-spl.bin"

printf '%s\n' '#!/bin/sh' 'test -s "$2"' >"$host_dir/sbin/e2fsck"
printf '%s\n' '#!/bin/sh' \
  'case "$2" in' \
  "  'stat /etc'|'stat /bin/busybox'|'stat /usr/sbin/x6100_gui') test -s \"\$3\" ;;" \
  '  *) exit 1 ;;' 'esac' 'printf "Inode: 2\\n"' >"$host_dir/sbin/debugfs"
# genimage stub: boot.vfat, and sdcard.img with U-Boot at 8 KiB and the MBR
# start/size fields of p1 (LBA 2048) and p2 (LBA 67584, 2097152 sectors).
# GSOC_STUB_UBOOT swaps in another blob for the negative case.
cat >"$bin_dir/genimage" <<'STUB'
#!/bin/sh
output= input=
while [ "$#" -gt 0 ]; do
  case "$1" in
    --outputpath) output=$2; shift 2 ;;
    --inputpath) input=$2; shift 2 ;;
    *) shift ;;
  esac
done
test -n "$output" && test -n "$input"
printf "boot payload\n" >"$output/boot.vfat"
img="$output/sdcard.img"
: >"$img"
dd if="${GSOC_STUB_UBOOT:-$input/u-boot-sunxi-with-spl.bin}" of="$img" bs=1024 seek=8 conv=notrunc 2>/dev/null
printf '\000\010\000\000' | dd of="$img" bs=1 seek=454 conv=notrunc 2>/dev/null
printf '\000\010\001\000\000\000\040\000' | dd of="$img" bs=1 seek=470 conv=notrunc 2>/dev/null
STUB
printf '%s\n' '#!/bin/sh' 'for last; do :; done' \
  'printf "%s\\n" "-c '\''$last'\'' --"' >"$bin_dir/getopt"
chmod 0755 "$host_dir/sbin/e2fsck" "$host_dir/sbin/debugfs" "$bin_dir/genimage" "$bin_dir/getopt"

! grep -q '^image rootfs\.ext4' "$board_dir/genimage.cfg"
grep -q '^image sdcard\.img' "$board_dir/genimage.cfg"

# Like Buildroot: cwd is the top of the Buildroot tree; arguments are
# BINARIES_DIR followed by BR2_ROOTFS_POST_SCRIPT_ARGS.
printf 'BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE="2026.10"\n' >"$tmp_dir/.config"

post_image() (
  cd "$tree_dir/buildroot"
  PATH="$bin_dir:$PATH" BR2_CONFIG="$tmp_dir/.config" \
  BR2_EXTERNAL_GSOC_PATH="$tree_dir/br2_external" \
  BINARIES_DIR="$images_dir" HOST_DIR="$host_dir" BUILD_DIR="$tmp_dir/build" \
  "$board_dir/post-image.sh" "$images_dir" -c "$board_dir/genimage.cfg"
)

post_image
test -s "$images_dir/boot.vfat"
test -s "$images_dir/sdcard.img"
test "$(cat "$images_dir/rootfs.ext4")" = 'populated-rootfs-sentinel'

# Another blob at 8 KiB (say the stock U-Boot) fails the sdcard.img check.
printf 'other u-boot\n' >"$tmp_dir/other-u-boot.bin"
! GSOC_STUB_UBOOT="$tmp_dir/other-u-boot.bin" post_image >/dev/null 2>&1

# post-build: a U-Boot artifact identical to Buildroot's build is accepted,
# any other is refused.
mkdir -p "$tmp_dir/build/uboot-2026.10" "$tmp_dir/target/etc/init.d"
cp "$images_dir/u-boot-sunxi-with-spl.bin" "$tmp_dir/build/uboot-2026.10/"
post_build() {
  BR2_CONFIG="$tmp_dir/.config" BINARIES_DIR="$images_dir" \
  BUILD_DIR="$tmp_dir/build" TARGET_DIR="$tmp_dir/target" \
  "$board_dir/post-build.sh" "$tmp_dir/target"
}
post_build
cp "$tmp_dir/other-u-boot.bin" "$images_dir/u-boot.bin"
! post_build 2>/dev/null
echo "post-image/post-build contract OK"
