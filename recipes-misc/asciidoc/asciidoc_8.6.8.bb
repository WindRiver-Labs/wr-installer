
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://COPYING;md5=8ca43cbc842c2336e835926c2166c28b \
                    file://COPYRIGHT;md5=029ad5428ba5efa20176b396222d4069"

SRC_URI = "http://downloads.sourceforge.net/project/asciidoc/asciidoc/${PV}/asciidoc-${PV}.tar.gz \
           file://fix_install_vim.patch"

SRC_URI[md5sum] = "6ffff1ab211f30481741ce4d1e4b12bf"
SRC_URI[sha256sum] = "ffb67f59dccaf6f15db72fcd04fdf21a2f9b703d31f94fcd0c49a424a9fcfbc4"

inherit autotools

BBCLASSEXTEND = "native"
