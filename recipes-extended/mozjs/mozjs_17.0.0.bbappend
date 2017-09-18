FILESEXTRAPATHS_prepend_installer := "${THISDIR}/${PN}:"

SRC_URI_append_installer = " file://mozjs-fix-unsafe-conf.patch"

EXTRA_OEMAKE_append_installer = ' NSPR_CFLAGS="-I${STAGING_INCDIR}/nspr4"'

do_configure_prepend_installer() {
	set -x
}

