################################################################################
#
# libg90
#
################################################################################

LIBG90_VERSION = 4eefd6e9fa43c554c1de502c2b3d2ed6b08d6f39
LIBG90_SITE = https://github.com/cjlawson02/libg90.git
LIBG90_SITE_METHOD = git
LIBG90_LICENSE = MIT
LIBG90_LICENSE_FILES = LICENSE
LIBG90_INSTALL_STAGING = YES
LIBG90_CONF_OPTS = -DLIBG90_BUILD_TESTS=OFF -DLIBG90_BUILD_CLI=OFF

$(eval $(cmake-package))
