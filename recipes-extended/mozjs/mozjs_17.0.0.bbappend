FILESEXTRAPATHS_prepend_wrlinux-installer := "${THISDIR}/${PN}:"

SRC_URI_append_wrlinux-installer = " file://mozjs-fix-unsafe-conf.patch"

EXTRA_OEMAKE_append_wrlinux-installer = ' NSPR_CFLAGS="-I${STAGING_INCDIR}/nspr4"'

do_configure_prepend_wrlinux-installer() {
	set -x
}

