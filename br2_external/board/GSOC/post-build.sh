#!/bin/sh
set -eu

# A stock Xiegu U-Boot binary must never enter the output directory: every
# U-Boot/SPL artifact there must be the one Buildroot built from source here.
uboot_ver=$(sed -n 's/^BR2_TARGET_UBOOT_CUSTOM_VERSION_VALUE="\(.*\)"$/\1/p' "$BR2_CONFIG")
for f in $(find "$BINARIES_DIR" -maxdepth 1 -type f \( -name 'u-boot*' -o -name 'SPL*' -o -name 'sunxi-spl*' \)); do
  if [ -z "$uboot_ver" ] || ! cmp -s "$f" "$BUILD_DIR/uboot-$uboot_ver/${f##*/}"; then
    echo "refusing U-Boot artifact not built by this tree: $f" >&2
    exit 1
  fi
done

# initscripts' S11modules loads modules-load.d like S11gsoc-modules, and rmmods
# them all at shutdown, panel_simple too: unbinding the panel under sun4i-drm
# oopses (NEEDS-HARDWARE G18).  S11gsoc-modules only loads.
rm -f "$TARGET_DIR/etc/init.d/S11modules"
