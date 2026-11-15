################################################################################
#
# gsoc-gui
#
################################################################################

GSOC_GUI_VERSION = 7d1aadadba0d85e21fadbbedc3575b73841894cc
GSOC_GUI_SITE = https://github.com/cjlawson02/OpenX6X00.git
GSOC_GUI_SITE_METHOD = git
GSOC_GUI_GIT_SUBMODULES = YES
GSOC_GUI_LICENSE = LGPL-2.1+, GPL-3.0+ (JS8/WSPR/JTTY code, js8core, wsprd, Mercury)
GSOC_GUI_LICENSE_FILES = LICENSE third-party/js8core/LICENSE third-party/mercury/LICENSE
GSOC_GUI_DEPENDENCIES = libg90 libpng libsndfile dbus-glib sqlite alsa-lib pulseaudio liquid-dsp libdrm fftw-single boost ft8lib libxkbcommon \
	jpeg network-manager udev \
	$(if $(BR2_PACKAGE_GPSD),gpsd)
GSOC_GUI_CONF_OPTS = -DHW_BACKEND=g90 -DBOARD_GSOC=ON -DLIBG90_USE_INSTALLED=ON

# OpenX6X00's rootfs starts the boot animation and the GUI its own way; GSOC has
# its own for both in board/GSOC/linux/rootfs-overlay (S13gsoc-bootanim,
# S60gsoc-gui).  Its DATA partition (S00adata) and settings backup
# (S04restore_backup_config) stay.  Every file must be there (so a layout
# change upstream fails the build) before removal.
GSOC_GUI_OTHER_BOARD_INIT = S00bootanim S49bootanim S95gui

define GSOC_GUI_REMOVE_OTHER_BOARD_INIT
	for f in $(GSOC_GUI_OTHER_BOARD_INIT); do \
		test -e $(TARGET_DIR)/etc/init.d/$$f || { \
			echo "gsoc-gui: expected init script $$f is missing" >&2; exit 1; }; \
		rm -f $(TARGET_DIR)/etc/init.d/$$f; \
	done
endef
GSOC_GUI_POST_INSTALL_TARGET_HOOKS += GSOC_GUI_REMOVE_OTHER_BOARD_INIT

# The GUI's updater (x6100-update) would install another radio's bundles from
# Guru-RF/OpenX6X00.  No GSOC channel yet: no default repository, so a check
# finds nothing.
define GSOC_GUI_NO_UPDATES
	grep -q '"X6100_UPDATE_REPO", "Guru-RF/OpenX6X00"' \
		$(TARGET_DIR)/usr/sbin/x6100-update || { \
		echo "gsoc-gui: x6100-update default repo string not found" >&2; exit 1; }
	$(SED) 's|"X6100_UPDATE_REPO", "Guru-RF/OpenX6X00"|"X6100_UPDATE_REPO", ""|' \
		$(TARGET_DIR)/usr/sbin/x6100-update
	! grep -q 'Guru-RF/OpenX6X00' $(TARGET_DIR)/usr/sbin/x6100-update
endef
GSOC_GUI_POST_INSTALL_TARGET_HOOKS += GSOC_GUI_NO_UPDATES

$(eval $(cmake-package))
