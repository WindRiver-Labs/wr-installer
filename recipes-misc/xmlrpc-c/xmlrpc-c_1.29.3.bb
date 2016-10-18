PR = "r1"

LICENSE = "BSD & MIT"
LIC_FILES_CHKSUM = "file://doc/COPYING;md5=aefbf81ba0750f02176b6f86752ea951"

SRC_URI = "file://xmlrpc-c-1.29.3.tar.gz \
           file://xmlrpc-c-cmake.patch \
	   file://xmlrpc-c-longlong.patch \
	   file://xmlrpc-c-include-string_int.h.patch"

DEPENDS = "curl libxml2"
RDEPENDS_${PN} = "curl"

S = "${WORKDIR}/01.29.03/"

inherit cmake

EXTRA_OECMAKE = "-D_lib:STRING=${baselib}"

do_configure_prepend() {
	rm -f GNUmakefile
}
