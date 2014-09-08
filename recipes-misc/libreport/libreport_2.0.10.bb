DESCRIPTION = "Libraries providing API for reporting different problems in applications \
to different bug targets like Bugzilla, ftp, trac, etc..."
HOMEPAGE = "https://fedorahosted.org/abrt/"
LICENSE = "GPLv2+"
DEPENDS = "automake flex xmlrpc-c \
        libgnome-keyring json-c libtar libnewt gtk+ nss libproxy"

RDEPENDS_${PN} = "libproxy"

LIC_FILES_CHKSUM = "file://COPYING;md5=751419260aa954499f7abaabaa882bbe"


SRC_URI = "http://pkgs.fedoraproject.org/repo/pkgs/libreport/libreport-2.0.10.tar.gz/84d564e3acf0039eacb0e139cbe1a642/libreport-2.0.10.tar.gz"
SRC_URI += "file://0001-Add-cgroup-information-filename.patch \
            file://0001-fixed-memory-leak-in-comment-dup.patch \
            file://0001-rhbz795548-opt-out-smolt.patch \
            file://0001-rhbz-820985-bz-4.2-doesn-t-have-bug_id-member-it-s-i.patch \
            file://0002-bugzilla-query-bz-version-and-for-4.2-use-id-element.patch \
            file://configure.patch \
            file://Makefile.am-remove-doc.patch \
            file://configure.ac-remove-prog-test-of-xmlto-and-asciidoc.patch \
            file://without-build-plugins.patch"

SRC_URI[md5sum] = "84d564e3acf0039eacb0e139cbe1a642"
SRC_URI[sha256sum] = "ab8f2bb2eeb93719b6a946b8a810527cec653815fd59c3fb03efca88e6e80408"

inherit gettext autotools pythonnative python-dir

PACKAGES += "${PN}-python"
FILES_${PN}-dbg += "${PYTHON_SITEPACKAGES_DIR}/*/.debug"
FILES_${PN}-python = "${PYTHON_SITEPACKAGES_DIR}/*"

