DESCRIPTION = "C-based metadata parser to quickly parse xml metadata into sqlite databases."
HOMEPAGE = "http://linux.duke.edu/projects/yum/download.ptml"
SECTION = "devel/python"
PRIORITY = "optional"
DEPENDS = "python sqlite3 glib-2.0 libxml2"
LICENSE = "GPLv2"
LIC_FILES_CHKSUM = "file://yum-metadata-parser.spec;md5=178f752a213b65e17fffa56c9eab8f2b"

SRC_URI = "http://linux.duke.edu/projects/yum/download/yum-metadata-parser/yum-metadata-parser-${PV}.tar.gz"
S = "${WORKDIR}/yum-metadata-parser-${PV}"

TARGET_CFLAGS += "-I${STAGING_LIBDIR}/glib-2.0"

inherit distutils

SRC_URI[md5sum] = "13df226ef004ea78eebc59022720b536"
SRC_URI[sha256sum] = "48b87110c3c46ad04209b358fded534eca3bfdc91b396d2549390dd51048be9f"
