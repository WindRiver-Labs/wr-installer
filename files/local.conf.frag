CONF_VERSION = "1"

#### Static configuration block
PKGDATA_DIR = "${BASE_PKGDATADIR}/${MULTIMACH_TARGET_SYS}"

SANITY_REQUIRED_UTILITIES = ""

TCLIBC = "libc"

ASSUME_PROVIDED += "quilt-native ${TCLIBC} ncurses"
ASSUME_PROVIDED += "rpm-native rpmresolve-native python-smartpm-native opkg-native createrepo-native"
ASSUME_PROVIDED += "virtual/fakeroot-native sed-native makedevs-native ldconfig-native"
ASSUME_PROVIDED += "virtual/update-alternatives-native update-rc.d-native gzip-native"

TOOLCHAIN_HOST_TASK = ""
TOOLCHAIN_TARGET_TASK = ""

PACKAGE_CLASSES = "package_rpm"

# Since we're doing a live install, don't package it up!
IMAGE_FSTYPES = ""
IMAGE_LINK_NAME = ""

INHERIT += "${PACKAGE_CLASSES} sstate multilib_global"

MACHINE = "no_machine"
TUNE_ARCH = "${TARGET_ARCH}"

NO32LIBS = '1'

PACKAGE_ARCHS="all any noarch ${PACKAGE_EXTRA_ARCHS} ${MACHINE_ARCH}"
TUNE_ARCH = "${TUNE_ARCH_tune-${DEFAULTTUNE}}"
TUNE_PKGARCH = "${TUNE_PKGARCH_tune-${DEFAULTTUNE}}"

SKIP_UPDATE_INDEX = '1'

#### Image setup
IMAGE_INSTALL ?= ""
IMAGE_FEATURES ?= ""
LINGUAS_INSTALL ?= ""
