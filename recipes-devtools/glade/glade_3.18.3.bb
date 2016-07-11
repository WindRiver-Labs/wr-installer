SUMMARY = "Glade - A User Interface Designer"
HOMEPAGE = "http://www.gnu.org/software/gnash"
LICENSE = "GPLv2 & LGPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=aabe87591cb8ae0f3c68be6977bb5522 \
                    file://COPYING.GPL;md5=9ac2e7cff1ddaf48b6eab6028f23ef88 \
                    file://COPYING.LGPL;md5=252890d9eee26aab7b432e8b8a616475"
DEPENDS = "gtk+ gtk+3 glib-2.0 libxml2"


inherit autotools pkgconfig pythonnative gnomebase gobject-introspection

SRC_URI = "http://ftp.gnome.org/pub/GNOME/sources/glade/3.18/glade-3.18.3.tar.xz \
           file://remove-yelp-help-rules-var.patch \
          "
SRC_URI[md5sum] = "6852d6286683728e0ea40ca9b5d2416f"
SRC_URI[sha256sum] = "ecdbce46e7fbfecd463be840b94fbf54d83723b3ebe075414cfd225ddab66452"

EXTRA_OECONF += "--disable-man-pages"

FILES_${PN} += "${datadir}/* ${libdir}/glade/modules/libgladegtk.so"
FILES_${PN}-dev += "${libdir}/glade/modules/libgladegtk.la"
FILES_${PN}-dbg += "${libdir}/glade/modules/.debug/libgladegtk.so"

PYTHON_PN = "python"

