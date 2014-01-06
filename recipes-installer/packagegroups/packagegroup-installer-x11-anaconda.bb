#
# Copyright (C) 2013 Wind River Systems Inc.
#
# This package matches a PACKAGE_GROUP_packagegroup-installer-x11-anaconda definition in
# wrlinux-image.bbclass that may be used to customize an image by
# adding "x11-anaconda" to IMAGE_FEATURES.
#

DESCRIPTION = "Tasks for desktop X11 applications"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/LICENSE;md5=3f40d7994397109285ec7b81fdeb3b58 \
                    file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
PR = "r35"

PACKAGES = "\
    packagegroup-installer-x11-anaconda \
    packagegroup-installer-x11-anaconda-dbg \
    packagegroup-installer-x11-anaconda-dev \
    "

PACKAGE_ARCH = "${MACHINE_ARCH}"

XSERVER ?= "xserver-kdrive-fbdev"

ALLOW_EMPTY_${PN} = "1"

# pcmanfm doesn't work on mips/powerpc
FILEMANAGER ?= "pcmanfm"
FILEMANAGER_mips ?= ""

# xserver-common, x11-common
VIRTUAL-RUNTIME_xserver_common ?= "x11-common"

# xserver-nodm-init, anaconda-init
VIRTUAL-RUNTIME_graphical_init_manager ?= "anaconda-init"

#    yum \
#    yum-utils \
#

RDEPENDS_packagegroup-installer-x11-anaconda = "\
    dbus \
    pointercal \
    ${XSERVER} \
    ${VIRTUAL-RUNTIME_xserver_common} \
    ${VIRTUAL-RUNTIME_graphical_init_manager} \
    liberation-fonts \
    ttf-lohit-assamese \
    ttf-lohit-bengali \
    ttf-lohit-devanagari \
    ttf-lohit-gujarati \
    ttf-lohit-kannada \
    ttf-lohit-malayalam \
    ttf-lohit-marathi \
    ttf-lohit-nepali \
    ttf-lohit-oriya \
    ttf-lohit-punjabi \
    ttf-lohit-tamil \
    ttf-lohit-tamil-classical \
    ttf-lohit-telugu \
    ttf-wqy-zenhei \
    ttf-dejavu-sans \
    ttf-dejavu-sans-mono \
    ttf-dejavu-sans-condensed \
    ttf-dejavu-serif \
    ttf-dejavu-serif-condensed \
    ttf-sazanami-gothic \
    ttf-sazanami-mincho \
    ttf-sinhala-lklug \
    xauth \
    xhost \
    xset \
    leafpad \
    ${FILEMANAGER} \
    settings-daemon \
    xcursor-transparent-theme \
    xrandr \
    x11vnc \
    libsdl \
    anaconda \
    createrepo"

