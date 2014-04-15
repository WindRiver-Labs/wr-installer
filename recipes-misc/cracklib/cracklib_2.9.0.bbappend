# Override --without-python and --libdir=${base_libdir}
EXTRA_OECONF = "--with-python"

inherit python-dir pythonnative

DEPENDS += "python"
DEPENDS_class-native += "python"
RDEPENDS_${PN}-python = "python"

PACKAGES += "${PN}-python ${PN}-python-dbg ${PN}-python-staticdev"

do_install_append() {
    install -d ${D}${base_libdir}
    mv ${D}${libdir}/libcrack* ${D}${base_libdir}/
    rm -f ${D}${PYTHON_SITEPACKAGES_DIR}/*.pyo
    rm -f ${D}${PYTHON_SITEPACKAGES_DIR}/test_cracklib.py
}

FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/cracklib.py ${PYTHON_SITEPACKAGES_DIR}/_cracklib.so"
FILES_${PN}-python-dbg = "${PYTHON_SITEPACKAGES_DIR}/.debug/_cracklib.so"
FILES_${PN}-python-staticdev = "${PYTHON_SITEPACKAGES_DIR}/_cracklib.a ${PYTHON_SITEPACKAGES_DIR}/_cracklib.la"
