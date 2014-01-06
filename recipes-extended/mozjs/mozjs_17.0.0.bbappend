FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://mozjs-fix-unsafe-conf.patch"

EXTRA_OEMAKE += 'NSPR_CFLAGS="-I${STAGING_INCDIR}/nspr4"'

do_configure_prepend() {
	set -x
}

do_install_append() {
	if [ ${prefix}/lib != ${libdir} ]; then
		mv ${D}${prefix}/lib ${D}${libdir}
	fi
}
