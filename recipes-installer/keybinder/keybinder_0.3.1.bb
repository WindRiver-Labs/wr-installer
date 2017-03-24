DESCRIPTION = "keybinder is a library for registering global key bindings, for gtk-based applications."
HOMEPAGE = "https://github.com/engla/keybinder"
LICENSE = "GPLv2"
SECTION = "devel/lib"
DEPENDS = "gtk+3 gobject-introspection-native \
           gtk+ \
"

LIC_FILES_CHKSUM = "file://COPYING;md5=94d55d512a9ba36caa9b7df079bae19f"

S = "${WORKDIR}/git"
B = "${S}"

SRCREV = "f8bdb0f48ba455088a401313829bae4f59842d17"
PV = "0.3.1+git${SRCPV}"
SRC_URI = "git://github.com/engla/keybinder.git;branch=keybinder-legacy \
"

RDEPENDS_${PN} = "gtk+"

inherit autotools gtk-doc gobject-introspection
EXTRA_OECONF += "--disable-python"
do_configure_prepend() {
	touch ${S}/ChangeLog
}
