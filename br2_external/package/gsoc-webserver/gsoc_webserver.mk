################################################################################
#
# gsoc-webserver
#
################################################################################

# The GUI's own webserver/, at the GUI's commit: the pages and the GUI's
# configurator socket change together.  Update the hash with the GUI's.
GSOC_WEBSERVER_VERSION = $(GSOC_GUI_VERSION)
GSOC_WEBSERVER_SITE = $(GSOC_GUI_SITE)
GSOC_WEBSERVER_SITE_METHOD = git
GSOC_WEBSERVER_SUBDIR = webserver
GSOC_WEBSERVER_LICENSE = LGPL-2.1+
GSOC_WEBSERVER_LICENSE_FILES = webserver/LICENSE
GSOC_WEBSERVER_DEPENDENCIES = python-bottle-sqlite
GSOC_WEBSERVER_SETUP_TYPE = flit

$(eval $(python-package))
