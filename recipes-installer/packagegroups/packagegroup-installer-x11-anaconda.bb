#
# Copyright (C) 2013 Wind River Systems Inc.
#

DESCRIPTION = "Tasks for desktop X11 applications"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

PACKAGES = "\
    packagegroup-installer-x11-anaconda \
    packagegroup-installer-x11-anaconda-dbg \
    packagegroup-installer-x11-anaconda-dev \
    "

PACKAGE_ARCH = "${MACHINE_ARCH}"

XSERVER ?= ""

ALLOW_EMPTY_${PN} = "1"

# pcmanfm doesn't work on mips/powerpc
FILEMANAGER ?= "pcmanfm"
FILEMANAGER_mips ?= ""

# xserver-nodm-init, anaconda-init
VIRTUAL-RUNTIME_graphical_init_manager ?= "anaconda-init"

RDEPENDS_packagegroup-installer-x11-anaconda = "\
    dbus \
    xinput-calibrator \
    ${XSERVER} \
    xserver-nodm-init \
    liberation-fonts \
    xauth \
    xhost \
    xset \
    ${FILEMANAGER} \
    settings-daemon \
    xrandr \
    libsdl \
    metacity \
    gnome-themes \
    adwaita-icon-theme \
    pango \
    pango-modules \
    createrepo-c"

