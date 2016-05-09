#
# Copyright (C) 2013 Wind River Systems Inc.
#

DESCRIPTION = "Tasks for desktop X11 applications"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=4d92cd373abda3937c2bc47fbc49d690 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
PR = "r35"

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

# xserver-common, x11-common
VIRTUAL-RUNTIME_xserver_common ?= "x11-common"

# xserver-nodm-init, anaconda-init
VIRTUAL-RUNTIME_graphical_init_manager ?= "anaconda-init"

RDEPENDS_packagegroup-installer-x11-anaconda = "\
    dbus \
    pointercal \
    ${XSERVER} \
    ${VIRTUAL-RUNTIME_xserver_common} \
    liberation-fonts \
    xauth \
    xhost \
    xset \
    leafpad \
    ${FILEMANAGER} \
    settings-daemon \
    xrandr \
    x11vnc \
    libsdl \
    metacity \
    gnome-themes \
    adwaita-icon-theme \
    pango \
    pango-modules \
    gtk-engine-clearlooks \
    gtk-theme-clearlooks \
    createrepo"

