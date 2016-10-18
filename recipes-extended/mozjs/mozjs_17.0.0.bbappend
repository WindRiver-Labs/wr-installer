FILESEXTRAPATHS_prepend := "${THISDIR}/${PN}:"

SRC_URI += "file://mozjs-fix-unsafe-conf.patch"

EXTRA_OEMAKE += 'NSPR_CFLAGS="-I${STAGING_INCDIR}/nspr4"'

do_configure_prepend() {
	set -x
}

