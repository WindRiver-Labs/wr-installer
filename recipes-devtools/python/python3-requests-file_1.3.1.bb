SUMMARY = "File transport adapter for Requests"
HOMEPAGE = "http://github.com/dashea/requests-file"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://LICENSE;md5=9cc728d6087e43796227b0a31422de6b"

SRC_URI[md5sum] = "35c06e4bbd64556adc102680d1ffb007"
SRC_URI[sha256sum] = "b62bb8920dcf7d50aa28d8c1e4502917db58c50b8ed3ce9a262fadb1571070d4"

inherit pypi setuptools3

RDEPENDS_${PN} += " \
    python3-requests \
"

