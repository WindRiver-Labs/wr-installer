# Copyright (C) 2013 Unknow User <unknow@user.org>
# Released under the MIT license (see COPYING.MIT for the terms)

DESCRIPTION = "Tools for certain user account management tasks"
HOMEPAGE = "https://fedorahosted.org/usermode/"
LICENSE = "GPLv2+"
DEPENDS = "libuser libpam gtk+"
PR = "r0"

inherit autotools gettext

SRC_URI = "http://pkgs.fedoraproject.org/lookaside/pkgs/usermode/usermode-1.108.tar.xz/bef795b757defb9fd27cfbd48ef79861/usermode-1.108.tar.xz"
SRC_URI[md5sum] = "bef795b757defb9fd27cfbd48ef79861"
SRC_URI[sha256sum] = "a25d61e5121d03503879660e386e980837f6f8d7a1a60abed911f0d4646383cd"

LIC_FILES_CHKSUM = "file://COPYING;md5=59530bdf33659b29e73d4adb9f9f6552"

do_install() {
    oe_runmake install DESTDIR=${D} INSTALL='install -p'
}
