FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

PRINC = "1"

SRC_URI += "file://libxml2-python.patch"

PYTHON-DEP = "python"
PYTHON-OECONF = "--with-python=${STAGING_INCDIR}/../ --with-catalog"
PYTHON-PACKAGES = "python-libxml2-dbg python-libxml2-dev python-libxml2-staticdev python-libxml2"

PYTHON-DEP_virtclass-native = ""
PYTHON-DEP_virtclass-nativesdk = ""
PYTHON-OECONF_virtclass-native = ""
PYTHON-OECONF_virtclass-nativesdk = ""
PYTHON-PACKAGES_virtclass-native = ""
PYTHON-PACKAGES_virtclass-nativesdk = ""

DEPENDS =+ "${PYTHON-DEP}"

EXTRA_OECONF += "${PYTHON-OECONF}"

PACKAGES =+ "${PYTHON-PACKAGES}"

FILES_python-libxml2 = "${libdir}/python${PYTHON_BASEVERSION}/site-packages"
FILES_python-libxml2-dev = " \
	${libdir}/python${PYTHON_BASEVERSION}/site-packages/libxml2mod.la \
"
FILES_python-libxml2-staticdev = " \
	${libdir}/python${PYTHON_BASEVERSION}/site-packages/libxml2mod.a \
"
FILES_python-libxml2-dbg = "${libdir}/python${PYTHON_BASEVERSION}/site-packages/.debug"
