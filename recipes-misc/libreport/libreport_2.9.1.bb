DESCRIPTION = "Libraries providing API for reporting different problems in applications \
to different bug targets like Bugzilla, ftp, trac, etc..."
HOMEPAGE = "https://fedorahosted.org/abrt/"
LICENSE = "GPLv2+"
DEPENDS = "automake flex xmlrpc-c xmlrpc-c-native \
        libgnome-keyring json-c libtar libnewt gtk+ nss libproxy rpm \
        intltool-native augeas satyr systemd gtk+3 \
"

RDEPENDS_${PN} = "libproxy"

LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"


SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/libreport/libreport-2.9.1.tar.gz/sha512/2cffb44fd8da625a9a0613f91ce3d485fe21b0a1f5932f6d6bfbdb4d41337f95c49f525556596aeef2fc3737015151d43250f287dc624f97469f087ff9213bde/libreport-2.9.1.tar.gz"
SRC_URI += "file://0001-Makefile.am-remove-doc-and-apidoc.patch \
            file://0002-configure.ac-remove-prog-test-of-xmlto-and-asciidoc.patch \
            file://0003-without-build-plugins.patch \
            file://0004-configure.ac-remove-prog-test-of-augparse.patch \
            file://0005-remove-python2-support.patch \
"

SRC_URI[md5sum] = "b3659d30d5d850006f269a19726308d2"
SRC_URI[sha256sum] = "aef08c612e4a7ecf34d4b91368a1090534424fd08a9e2b0491743cd9b4fe28f0"

inherit gettext autotools python3native pkgconfig

RDEPENDS_${PN}-python3 += "${PN}"

PACKAGES += "${PN}-python3"

FILES_${PN} += "${datadir}/*"
FILES_${PN}-dbg += "${PYTHON_SITEPACKAGES_DIR}/*/.debug"
FILES_${PN}-python3 = "${PYTHON_SITEPACKAGES_DIR}/*"

