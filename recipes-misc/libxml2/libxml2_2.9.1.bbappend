inherit python-dir

DEPENDS += "python"
PR = "r500"

EXTRA_OECONF = "--with-python=${STAGING_DIR_HOST}${exec_prefix} --without-debug --without-legacy --with-catalog --without-docbook --with-c14n --without-lzma --with-fexceptions PYTHON=${PYTHON} baselib=${baselib} \
 PYTHON_SITE_PACKAGES=${PYTHON_SITEPACKAGES_DIR}"
EXTRA_OECONF_virtclass-native = "--with-python=${PYTHON} --without-legacy --with-catalog --without-docbook --with-c14n --without-lzma"
EXTRA_OECONF_virtclass-nativesdk = "--with-python=${PYTHON} --without-legacy --with-catalog --without-docbook --with-c14n --without-lzma"

PACKAGES += "${PN}-python ${PN}-python-dbg"

FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/*py ${PYTHON_SITEPACKAGES_DIR}/libxml2mod.so"
FILES_${PN}-python-dbg = "${PYTHON_SITEPACKAGES_DIR}/.debug"
FILES_${PN}-staticdev += "${PYTHON_SITEPACKAGES_DIR}/libxml2mod.a"
FILES_${PN}-dev += "${PYTHON_SITEPACKAGES_DIR}/libxml2mod.la"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

SRC_URI += "file://autoconf_python.patch"
